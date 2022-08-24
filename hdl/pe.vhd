library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.mux;

entity pe is
    generic (
        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 7;
        addr_width_iact  : positive := 3;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 7;
        addr_width_psum  : positive := 4;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 7;
        addr_width_wght  : positive := 3
    );
    port (
        clk          : in    std_logic;
        rstn         : in    std_logic;

        command      : in std_logic_vector(1 downto 0);
        command_iact : in std_logic_vector(1 downto 0);
        command_psum : in std_logic_vector(1 downto 0);
        command_wght : in std_logic_vector(1 downto 0); 

        data_in_iact : in std_logic_vector(data_width_iact - 1 downto 0);
        data_in_psum : in std_logic_vector(data_width_psum - 1 downto 0);
        data_in_wght : in std_logic_vector(data_width_wght - 1 downto 0);

        data_in_iact_valid : in std_logic;
        data_in_psum_valid : in std_logic;
        data_in_wght_valid : in std_logic;

        buffer_full_iact : out std_logic;
        buffer_full_psum : out std_logic;
        buffer_full_wght : out std_logic;

        update_offset_iact : in std_logic_vector(addr_width_iact -1 downto 0);
        update_offset_psum : in std_logic_vector(addr_width_psum -1 downto 0);
        update_offset_wght : in std_logic_vector(addr_width_wght -1 downto 0);

        read_offset_iact : in std_logic_vector(addr_width_iact -1 downto 0);
        read_offset_psum : in std_logic_vector(addr_width_psum -1 downto 0);
        read_offset_wght : in std_logic_vector(addr_width_wght -1 downto 0);

        data_out       : out std_logic_vector(data_width_psum -1 downto 0);
        data_out_valid : out std_logic
    );
end entity pe;

architecture behavioral of pe is

    component line_buffer is
        generic (
            line_length : positive := 7; --! Length of the lines in the image
            addr_width  : positive := 3; --! Address width for the ram_dp subcomponent. ceil(log2(line_length))
            data_width  : positive := 8  --! Data width for the ram_dp subcomponent - should be the width of data to be stored (8 / 16 bit?)
        );
        port (
            clk            : in    std_logic;                                 --! Clock input
            rstn           : in    std_logic;                                 --! Negated asynchronous reset
            data_in        : in    std_logic_vector(data_width - 1 downto 0); --! Input to be pushed to the FIFO
            data_in_valid  : in    std_logic;                                 --! Data only read if valid = '1'
            data_out       : out   std_logic_vector(data_width - 1 downto 0); --! Outputs the element read_offset away from the head of the FIFO
            data_out_valid : out   std_logic;
            buffer_full    : out   std_logic;
            update_val     : in    std_logic_vector(data_width - 1 downto 0);
            update_offset  : in    std_logic_vector(addr_width - 1 downto 0);
            read_offset    : in    std_logic_vector(addr_width - 1 downto 0); --! Offset from head of FIFO; Shrink FIFO by this many elements
            command        : in    std_logic_vector(1 downto 0)
        );
    end component line_buffer;

    component mult is
        generic (
            input_width  : positive := 8; -- Input width for the multiplication the mac can operate on
            output_width : positive := 16
        );
        port (
            clk          : in    std_logic;
            en           : in    std_logic;
            rstn         : in    std_logic;
            data_in_i    : in    std_logic_vector(input_width - 1 downto 0);
            data_in_w    : in    std_logic_vector(input_width - 1 downto 0);
            result       : out   std_logic_vector(output_width - 1 downto 0);
            result_valid : out   std_logic
        );
    end component mult;

    component acc is
        generic (
            input_width  : positive := 16; -- Input width for the multiplication the mac can operate on
            output_width : positive := 17
        );
        port (
            clk          : in    std_logic;
            en           : in    std_logic;
            rstn         : in    std_logic;
            data_in_a    : in    std_logic_vector(input_width - 1 downto 0);
            data_in_b    : in    std_logic_vector(input_width - 1 downto 0);
            result       : out   std_logic_vector(output_width - 1 downto 0);
            result_valid : out   std_logic
        );
    end component acc;

    signal data_iact    : std_logic_vector(data_width_iact - 1 downto 0); 
    signal data_wght    : std_logic_vector(data_width_wght - 1 downto 0);
    signal data_mult    : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in1 : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in2 : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_acc_out   : std_logic_vector(data_width_psum - 1 downto 0);
    
    signal data_acc_in2_valid : std_logic;
    signal data_acc_in1_valid : std_logic;
    signal data_acc_valid     : std_logic;
    signal data_acc_out_valid : std_logic;

    signal data_iact_valid : std_logic;
    signal data_wght_valid : std_logic;

    signal iact_wght_valid : std_logic;
    signal data_mult_valid : std_logic;

    signal sel_mult_psum : std_logic;

begin

    sel_mult_psum   <= command(0);
    data_acc_valid  <= (data_acc_in1_valid and data_acc_in2_valid) or data_acc_in2_valid;
    iact_wght_valid <= data_iact_valid and data_wght_valid;
    data_out_valid  <= data_acc_out_valid;
    data_out        <= data_acc_out;

    line_buffer_iact : component line_buffer
    generic map (
        line_length => line_length_iact,
        addr_width   => addr_width_iact,
        data_width  => data_width_iact
    )
    port map (
        clk            => clk,
        rstn           => rstn,
        data_in        => data_in_iact,
        data_in_valid  => data_in_iact_valid,
        data_out       => data_iact,
        data_out_valid => data_iact_valid,
        buffer_full    => buffer_full_iact,
        update_val     => (others=>'0'),
        update_offset  => update_offset_iact,
        read_offset    => read_offset_iact,
        command        => command_iact
    );

    line_buffer_psum : component line_buffer
    generic map (
        line_length => line_length_psum,
        addr_width   => addr_width_psum,
        data_width  => data_width_psum
    )
    port map (
        clk            => clk,
        rstn           => rstn,
        data_in        => data_in_psum,
        data_in_valid  => data_in_psum_valid,
        data_out       => data_acc_in2,
        data_out_valid => data_acc_in2_valid,
        buffer_full    => buffer_full_psum,
        update_val     => data_acc_out,
        update_offset  => update_offset_psum,
        read_offset    => read_offset_psum,
        command        => command_psum
    );

    line_buffer_wght : component line_buffer
    generic map (
        line_length => line_length_wght,
        addr_width  => addr_width_wght,
        data_width  => data_width_wght
    )
    port map (
        clk            => clk,
        rstn           => rstn,
        data_in        => data_in_wght,
        data_in_valid  => data_in_wght_valid,
        data_out       => data_wght,
        data_out_valid => data_wght_valid,
        buffer_full    => buffer_full_wght,
        update_val     => (others=>'0'),
        update_offset  => update_offset_wght,
        read_offset    => read_offset_wght,
        command        => command_wght
    );

    mult_1 : component mult
    generic map(
        input_width  => data_width_iact, -- Input width for the multiplication the mac can operate on
        output_width => data_width_psum
    )
    port map(
        clk          => clk,
        en           => iact_wght_valid,
        rstn         => rstn,
        data_in_i    => data_iact,
        data_in_w    => data_wght,
        result       => data_mult,
        result_valid => data_mult_valid
    );

    acc_1 : component acc
    generic map(
        input_width  => data_width_psum, -- Input width for the accumulation
        output_width => data_width_psum
    )
    port map(
        clk          => clk,
        en           => data_acc_valid,
        rstn         => rstn,
        data_in_a    => data_acc_in1,
        data_in_b    => data_acc_in2,
        result       => data_acc_out,
        result_valid => data_acc_out_valid
    );

    mux_psum : entity work.mux
    generic map(
        input_width   => data_width_psum,
        input_num     => 2,
        address_width => 1
    )
    port map(
        v_i(0) => data_mult,
        v_i(1) => data_in_psum,
        sel(0)    => sel_mult_psum,
        z_o    => data_acc_in1
    );

    mux_psum_valid : entity work.mux
    generic map(
        input_width   => 1,
        input_num     => 2,
        address_width => 1
    )
    port map(
        v_i(0)(0) => data_mult_valid,
        v_i(1)(0) => data_in_psum_valid,
        sel(0)    => sel_mult_psum,
        z_o(0)    => data_acc_in1_valid
    );


end architecture behavioral;

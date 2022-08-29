library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

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
        clk  : in    std_logic;
        rstn : in    std_logic;

        command      : in    command_pe_t;
        command_iact : in    command_lb_t;
        command_psum : in    command_lb_t;
        command_wght : in    command_lb_t;

        data_in_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        data_in_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
        data_in_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

        data_in_iact_valid : in    std_logic;
        data_in_psum_valid : in    std_logic;
        data_in_wght_valid : in    std_logic;

        buffer_full_iact : out   std_logic;
        buffer_full_psum : out   std_logic;
        buffer_full_wght : out   std_logic;

        buffer_full_next_iact : out std_logic;
        buffer_full_next_psum : out std_logic;
        buffer_full_next_wght : out std_logic;

        update_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        update_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        update_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        read_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        read_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        read_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        data_out       : out   std_logic_vector(data_width_psum - 1 downto 0);
        data_out_valid : out   std_logic
    );
end entity pe;

architecture behavioral of pe is

    component line_buffer is
        generic (
            line_length : positive := 7;
            addr_width  : positive := 3;
            data_width  : positive := 8
        );
        port (
            clk              : in    std_logic;
            rstn             : in    std_logic;
            data_in          : in    std_logic_vector(data_width - 1 downto 0);
            data_in_valid    : in    std_logic;
            data_out         : out   std_logic_vector(data_width - 1 downto 0);
            data_out_valid   : out   std_logic;
            buffer_full      : out   std_logic;
            buffer_full_next : out   std_logic;
            update_val       : in    std_logic_vector(data_width - 1 downto 0);
            update_offset    : in    std_logic_vector(addr_width - 1 downto 0);
            read_offset      : in    std_logic_vector(addr_width - 1 downto 0);
            command          : in    command_lb_t
        );
    end component line_buffer;

    component mult is
        generic (
            input_width  : positive := 8;
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
            input_width  : positive := 16;
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

    component mux is
        generic (
            input_width   : natural;
            input_num     : natural;
            address_width : natural
        );
        port (
            v_i : in    array_t(0 to input_num - 1)(input_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   std_logic_vector(input_width - 1 downto 0)
        );
    end component mux;

    signal data_iact    : std_logic_vector(data_width_iact - 1 downto 0);
    signal data_wght    : std_logic_vector(data_width_wght - 1 downto 0);
    signal data_mult    : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in1 : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in2 : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_acc_out : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_acc_in2_valid : std_logic;
    signal data_acc_in1_valid : std_logic;
    signal data_acc_valid     : std_logic;
    signal data_acc_out_valid : std_logic;

    signal data_iact_valid : std_logic;
    signal data_wght_valid : std_logic;

    signal iact_wght_valid : std_logic;
    signal data_mult_valid : std_logic;

    signal sel_mult_psum : std_logic;

    signal command_read_delay : std_logic;
    signal command_read       : std_logic;

begin

    sel_mult_psum   <= '0' when command = c_pe_mux_mac else
                       '1' when command = c_pe_mux_psum;
    data_acc_valid  <= (data_acc_in1_valid and data_acc_in2_valid) or data_acc_in2_valid;
    iact_wght_valid <= data_iact_valid and data_wght_valid;
    -- data_out_valid  <= data_acc_out_valid;
    -- data_out        <= data_acc_out;
    data_out <= data_acc_in2;
    -- data_out_valid <= data_acc_in2_valid;

    data_out_valid <= command_read_delay;

    output_valid : process (clk, rstn) is
    begin

        if not rstn then
            command_read <= '0';
        elsif rising_edge(clk) then
            if command_psum = c_lb_read then
                command_read <= '1';
            else
                command_read <= '0';
            end if;
        end if;

    end process output_valid;

    delays : process (clk, rstn) is
    begin

        if not rstn then
            command_read_delay <= '0';
        elsif rising_edge(clk) then
            command_read_delay <= command_read;
        end if;

    end process delays;

    line_buffer_iact : component line_buffer
        generic map (
            line_length => line_length_iact,
            addr_width  => addr_width_iact,
            data_width  => data_width_iact
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            data_in          => data_in_iact,
            data_in_valid    => data_in_iact_valid,
            data_out         => data_iact,
            data_out_valid   => data_iact_valid,
            buffer_full      => buffer_full_iact,
            buffer_full_next => buffer_full_next_iact,
            update_val       => (others=>'0'),
            update_offset    => update_offset_iact,
            read_offset      => read_offset_iact,
            command          => command_iact
        );

    line_buffer_psum : component line_buffer
        generic map (
            line_length => line_length_psum,
            addr_width  => addr_width_psum,
            data_width  => data_width_psum
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            data_in          => data_in_psum,
            data_in_valid    => data_in_psum_valid,
            data_out         => data_acc_in2,
            data_out_valid   => data_acc_in2_valid,
            buffer_full      => buffer_full_psum,
            buffer_full_next => buffer_full_next_psum,
            update_val       => data_acc_out,
            update_offset    => update_offset_psum,
            read_offset      => read_offset_psum,
            command          => command_psum
        );

    line_buffer_wght : component line_buffer
        generic map (
            line_length => line_length_wght,
            addr_width  => addr_width_wght,
            data_width  => data_width_wght
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            data_in          => data_in_wght,
            data_in_valid    => data_in_wght_valid,
            data_out         => data_wght,
            data_out_valid   => data_wght_valid,
            buffer_full      => buffer_full_wght,
            buffer_full_next => buffer_full_next_wght,
            update_val       => (others=>'0'),
            update_offset    => update_offset_wght,
            read_offset      => read_offset_wght,
            command          => command_wght
        );

    mult_1 : component mult
        generic map (
            input_width  => data_width_iact,
            output_width => data_width_psum
        )
        port map (
            clk          => clk,
            en           => iact_wght_valid,
            rstn         => rstn,
            data_in_i    => data_iact,
            data_in_w    => data_wght,
            result       => data_mult,
            result_valid => data_mult_valid
        );

    acc_1 : component acc
        generic map (
            input_width  => data_width_psum,
            output_width => data_width_psum
        )
        port map (
            clk          => clk,
            en           => data_acc_valid,
            rstn         => rstn,
            data_in_a    => data_acc_in1,
            data_in_b    => data_acc_in2,
            result       => data_acc_out,
            result_valid => data_acc_out_valid
        );

    mux_psum : component mux
        generic map (
            input_width   => data_width_psum,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0) => data_mult,
            v_i(1) => data_in_psum,
            sel(0) => sel_mult_psum,
            z_o    => data_acc_in1
        );

    mux_psum_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0)(0) => data_mult_valid,
            v_i(1)(0) => data_in_psum_valid,
            sel(0)    => sel_mult_psum,
            z_o(0)    => data_acc_in1_valid
        );

end architecture behavioral;

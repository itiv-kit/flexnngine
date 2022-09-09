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
        addr_width_wght  : positive := 3;

        pe_north : boolean := false;
        pe_south : boolean := false
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

        buffer_full_next_iact : out   std_logic;
        buffer_full_next_psum : out   std_logic;
        buffer_full_next_wght : out   std_logic;

        update_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        update_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        update_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        read_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        read_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        read_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        data_out       : out   std_logic_vector(data_width_psum - 1 downto 0);
        data_out_valid : out   std_logic;

        data_in       : in    std_logic_vector(data_width_psum - 1 downto 0);
        data_in_valid : in    std_logic;

        data_out_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
        data_out_wght : out   std_logic_vector(data_width_wght - 1 downto 0);

        data_out_iact_valid : out   std_logic;
        data_out_wght_valid : out   std_logic
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

    component demux is
        generic (
            output_width  : natural;
            output_num    : natural;
            address_width : natural
        );
        port (
            v_i : in    std_logic_vector(output_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   array_t(0 to output_num - 1)(output_width - 1 downto 0)
        );
    end component demux;

    signal data_iact            : std_logic_vector(data_width_iact - 1 downto 0);
    signal data_iact_wide       : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_iact_wide_valid : std_logic;
    signal data_wght            : std_logic_vector(data_width_wght - 1 downto 0);
    signal data_psum            : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_mult            : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in1         : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_acc_in2         : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_acc_out : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_acc_in2_valid : std_logic;
    signal data_acc_in1_valid : std_logic;
    signal data_acc_valid     : std_logic;
    signal data_acc_out_valid : std_logic;

    signal data_iact_valid : std_logic;
    signal data_wght_valid : std_logic;
    signal data_psum_valid : std_logic;

    signal iact_wght_valid : std_logic;
    signal data_mult_valid : std_logic;

    signal sel_mult_psum : std_logic;
    signal sel_conv_gemm : std_logic;

    signal command_read_psum_delay : std_logic;
    signal command_read_psum       : std_logic;
    signal command_read_iact_delay : std_logic;
    signal command_read_iact       : std_logic;
    signal command_read_wght_delay : std_logic;
    signal command_read_wght       : std_logic;

    signal demux_input_iact : std_logic_vector(data_width_psum - 1 downto 0);
    signal demux_input_psum : std_logic_vector(data_width_psum - 1 downto 0);

    signal demux_input_iact_valid : std_logic;
    signal demux_input_psum_valid : std_logic;

    signal w_data_in_iact_valid : std_logic;
    signal w_data_in_iact       : std_logic_vector(data_width_iact - 1 downto 0);

    signal test : array_t(0 to 2 - 1)(1 - 1 downto 0);

begin

    data_acc_in2       <= data_psum;
    data_acc_in2_valid <= data_psum_valid;

    sel_signals : process (clk, rstn) is
    begin

        if not rstn then
            sel_mult_psum <= '0';
            sel_conv_gemm <= '0';
        elsif rising_edge(clk) then
            if command = c_pe_conv_mult or command = c_pe_gemm_mult then
                sel_mult_psum <= '0';
            else
                sel_mult_psum <= '1';
            end if;

            if command = c_pe_conv_mult or command = c_pe_conv_psum then
                sel_conv_gemm <= '0';
            else
                sel_conv_gemm <= '1';
            end if;
        end if;

    end process sel_signals;

    /*sel_mult_psum <= '0' when (command = c_pe_conv_mult or command = c_pe_gemm_mult) and rising_edge(clk) else
                     '1' when (command = c_pe_conv_psum or command = c_pe_gemm_psum) and rising_edge(clk);

    sel_conv_gemm <= '0' when (command = c_pe_conv_mult or command = c_pe_conv_psum) and rising_edge(clk) else
                     '1' when (command = c_pe_gemm_mult or command = c_pe_gemm_psum) and rising_edge(clk);*/

    data_acc_valid  <= (data_acc_in1_valid and data_acc_in2_valid) or data_acc_in2_valid;
    iact_wght_valid <= data_iact_valid and data_wght_valid;

    data_out_iact <= data_in_iact when rising_edge(clk);
    data_out_wght <= data_in_wght when rising_edge(clk);

    data_out_iact_valid <= data_in_iact_valid when rising_edge(clk);
    data_out_wght_valid <= data_in_wght_valid when rising_edge(clk);

    data_iact_wide       <= demux_input_iact when rising_edge(clk);
    data_iact_wide_valid <= demux_input_iact_valid when rising_edge(clk);

    -- data_out_valid  <= data_acc_out_valid;
    -- data_out        <= data_acc_out;
    -- data_out <= data_acc_in2;
    -- data_out_valid <= data_acc_in2_valid;

    psum_output_valid : process (clk, rstn) is
    begin

        if not rstn then
            command_read_psum <= '0';
        elsif rising_edge(clk) then
            if command_psum = c_lb_read then
                command_read_psum <= '1';
            else
                command_read_psum <= '0';
            end if;
        end if;

    end process psum_output_valid;

    iact_output_valid : process (clk, rstn) is
    begin

        if not rstn then
            command_read_iact <= '0';
        elsif rising_edge(clk) then
            if command_iact = c_lb_read then
                command_read_iact <= '1';
            else
                command_read_iact <= '0';
            end if;
        end if;

    end process iact_output_valid;

    wght_output_vaild : process (clk, rstn) is
    begin

        if not rstn then
            command_read_wght <= '0';
        elsif rising_edge(clk) then
            if command_wght = c_lb_read then
                command_read_wght <= '1';
            else
                command_read_wght <= '0';
            end if;
        end if;

    end process wght_output_vaild;

    delays : process (clk, rstn) is
    begin

        if not rstn then
            command_read_psum_delay <= '0';
            command_read_iact_delay <= '0';
            command_read_wght_delay <= '0';
        elsif rising_edge(clk) then
            command_read_psum_delay <= command_read_psum;
            command_read_iact_delay <= command_read_iact;
            command_read_wght_delay <= command_read_wght;
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
            data_in          => w_data_in_iact,
            data_in_valid    => w_data_in_iact_valid,
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
            data_out         => data_psum,
            data_out_valid   => data_psum_valid,
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
            v_i(1) => demux_input_psum,
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
            v_i(1)(0) => demux_input_psum_valid,
            sel(0)    => sel_mult_psum,
            z_o(0)    => data_acc_in1_valid
        );

    mux_iact : component mux
        generic map (
            input_width   => data_width_iact,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0) => data_in_iact,
            v_i(1) => demux_input_iact(data_width_iact - 1 downto 0),
            sel(0) => sel_conv_gemm,
            z_o    => w_data_in_iact
        );

    mux_iact_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0)(0) => data_in_iact_valid,
            v_i(1)(0) => demux_input_iact_valid,
            sel(0)    => sel_conv_gemm,
            z_o(0)    => w_data_in_iact_valid
        );

    pe_output : if pe_north = false generate

        mux_output : component mux
            generic map (
                input_width   => data_width_psum,
                input_num     => 2,
                address_width => 1
            )
            port map (
                v_i(0) => data_psum,
                v_i(1) => data_iact_wide,
                sel(0) => sel_conv_gemm,
                z_o    => data_out
            );

        mux_output_valid : component mux
            generic map (
                input_width   => 1,
                input_num     => 2,
                address_width => 1
            )
            port map (
                v_i(0)(0) => command_read_psum_delay,
                v_i(1)(0) => data_iact_wide_valid,
                sel(0)    => sel_conv_gemm,
                z_o(0)    => data_out_valid
            );

    end generate pe_output;

    pe_output_psum : if pe_north = true generate

        data_out_valid <= command_read_psum_delay;
        data_out       <= data_psum;

    end generate pe_output_psum;

    demux_input : component demux
        generic map (
            output_width  => data_width_psum,
            output_num    => 2,
            address_width => 1
        )
        port map (
            v_i    => data_in,
            sel(0) => sel_conv_gemm,
            z_o(0) => demux_input_psum,
            z_o(1) => demux_input_iact
        );

    demux_input_valid : component demux
        generic map (
            output_width  => 1,
            output_num    => 2,
            address_width => 1
        )
        port map (
            v_i(0)    => data_in_valid,
            sel(0)    => sel_conv_gemm,
            z_o(0)(0) => demux_input_psum_valid,
            z_o(1)(0) => demux_input_iact_valid
        -- z_o => test
        );

end architecture behavioral;

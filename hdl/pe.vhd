library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity pe is
    generic (
        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 32;
        addr_width_iact  : positive := 5;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 128;
        addr_width_psum  : positive := 7;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 32;
        addr_width_wght  : positive := 5;

        pe_north : boolean := false;
        pe_south : boolean := false
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_enable       : in    std_logic;
        i_command      : in    command_pe_t;
        i_command_iact : in    command_lb_t;
        i_command_psum : in    command_lb_t;
        i_command_wght : in    command_lb_t;

        i_data_in_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        i_data_in_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_data_in_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

        i_data_in_iact_valid : in    std_logic;
        i_data_in_psum_valid : in    std_logic;
        i_data_in_wght_valid : in    std_logic;

        o_buffer_full_iact : out   std_logic;
        o_buffer_full_psum : out   std_logic;
        o_buffer_full_wght : out   std_logic;

        o_buffer_full_next_iact : out   std_logic;
        o_buffer_full_next_psum : out   std_logic;
        o_buffer_full_next_wght : out   std_logic;

        i_update_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        i_update_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        i_update_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        i_read_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        i_read_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        i_read_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        o_data_out       : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_data_out_valid : out   std_logic;

        i_data_in       : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_data_in_valid : in    std_logic;

        o_data_out_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
        o_data_out_wght : out   std_logic_vector(data_width_wght - 1 downto 0);

        o_data_out_iact_valid : out   std_logic;
        o_data_out_wght_valid : out   std_logic
    );
end entity pe;

architecture behavioral of pe is

    component line_buffer is
        generic (
            line_length : positive := 7;
            addr_width  : positive := 3;
            data_width  : positive := 8;
            psum_type   : boolean  := false
        );
        port (
            clk                : in    std_logic;
            rstn               : in    std_logic;
            i_enable           : in    std_logic;
            i_data             : in    std_logic_vector(data_width - 1 downto 0);
            i_data_valid       : in    std_logic;
            o_data             : out   std_logic_vector(data_width - 1 downto 0);
            o_data_valid       : out   std_logic;
            o_buffer_full      : out   std_logic;
            o_buffer_full_next : out   std_logic;
            i_update_val       : in    std_logic_vector(data_width - 1 downto 0);
            i_update_offset    : in    std_logic_vector(addr_width - 1 downto 0);
            i_read_offset      : in    std_logic_vector(addr_width - 1 downto 0);
            i_command          : in    command_lb_t
        );
    end component line_buffer;

    component mult is
        generic (
            input_width  : positive := 8;
            output_width : positive := 16
        );
        port (
            clk            : in    std_logic;
            rstn           : in    std_logic;
            i_en           : in    std_logic;
            i_data_a       : in    std_logic_vector(input_width - 1 downto 0);
            i_data_b       : in    std_logic_vector(input_width - 1 downto 0);
            o_result       : out   std_logic_vector(output_width - 1 downto 0);
            o_result_valid : out   std_logic
        );
    end component mult;

    component acc is
        generic (
            input_width  : positive := 16;
            output_width : positive := 17
        );
        port (
            clk            : in    std_logic;
            rstn           : in    std_logic;
            i_en           : in    std_logic;
            i_data_a       : in    std_logic_vector(input_width - 1 downto 0);
            i_data_b       : in    std_logic_vector(input_width - 1 downto 0);
            o_result       : out   std_logic_vector(output_width - 1 downto 0);
            o_result_valid : out   std_logic
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

    signal w_data_iact            : std_logic_vector(data_width_iact - 1 downto 0);
    signal r_data_iact_wide       : std_logic_vector(data_width_psum - 1 downto 0);
    signal r_data_iact_wide_valid : std_logic;
    signal w_data_wght            : std_logic_vector(data_width_wght - 1 downto 0);
    signal w_data_psum            : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_mult            : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_acc_in1         : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_acc_in2         : std_logic_vector(data_width_psum - 1 downto 0);

    signal w_data_acc_out : std_logic_vector(data_width_psum - 1 downto 0);

    signal w_data_acc_in2_valid : std_logic;
    signal w_data_acc_in1_valid : std_logic;
    signal w_data_acc_valid     : std_logic;
    signal w_data_acc_out_valid : std_logic;

    signal w_data_iact_valid : std_logic;
    signal w_data_wght_valid : std_logic;
    signal w_data_psum_valid : std_logic;

    signal w_iact_wght_valid : std_logic;
    signal w_data_mult_valid : std_logic;

    signal r_sel_mult_psum  : std_logic := '0';
    signal r_sel_conv_gemm  : std_logic := '0';
    signal r_sel_iact_input : std_logic := '0';
    signal w_sel_output     : std_logic;

    signal r_command_read_psum_delay : std_logic;
    signal r_command_read_psum       : std_logic;

    signal w_demux_input_iact : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_demux_input_psum : std_logic_vector(data_width_psum - 1 downto 0);

    signal w_demux_input_iact_valid : std_logic;
    signal w_demux_input_psum_valid : std_logic;

    signal w_data_in_iact_valid : std_logic;
    signal w_data_in_iact       : std_logic_vector(data_width_iact - 1 downto 0);

    signal i_data_in_valid_chg : std_logic;
    signal r_enable            : std_logic;
    signal r_enable_d          : std_logic;
    signal r_enable_dd         : std_logic;
    signal r_enable_ddd        : std_logic;

begin

    w_data_acc_in2       <= w_data_psum;
    w_data_acc_in2_valid <= w_data_psum_valid;

    sel_signals : process (clk, rstn) is
    begin

        if not rstn then
            r_sel_mult_psum  <= '0';
            r_sel_conv_gemm  <= '0';
            r_sel_iact_input <= '0';
        elsif rising_edge(clk) then
            if i_command = c_pe_conv_mult or i_command = c_pe_gemm_mult then
                r_sel_mult_psum <= '0';
            else
                r_sel_mult_psum <= '1';
            end if;

            if i_command = c_pe_conv_mult or i_command = c_pe_conv_psum then
                r_sel_conv_gemm <= '0';
            else
                r_sel_conv_gemm <= '1';
            end if;

            if i_command = c_pe_conv_pass then
                r_sel_iact_input <= '0';
            else
                r_sel_iact_input <= '1';
            end if;
        end if;

    end process sel_signals;

    /*sel_mult_psum <= '0' when (command = c_pe_conv_mult or command = c_pe_gemm_mult) and rising_edge(clk) else
                     '1' when (command = c_pe_conv_psum or command = c_pe_gemm_psum) and rising_edge(clk);

    sel_conv_gemm <= '0' when (command = c_pe_conv_mult or command = c_pe_conv_psum) and rising_edge(clk) else
                     '1' when (command = c_pe_gemm_mult or command = c_pe_gemm_psum) and rising_edge(clk);*/

    w_data_acc_valid  <= (w_data_acc_in1_valid and w_data_acc_in2_valid);
    w_iact_wght_valid <= w_data_iact_valid and w_data_wght_valid;

    /*o_data_out_iact <= i_data_in_iact when rising_edge(clk);
    o_data_out_wght <= i_data_in_wght when rising_edge(clk);

    o_data_out_iact_valid <= i_data_in_iact_valid when rising_edge(clk);
    o_data_out_wght_valid <= i_data_in_wght_valid when rising_edge(clk);

    r_data_iact_wide       <= w_demux_input_iact when rising_edge(clk);
    r_data_iact_wide_valid <= w_demux_input_iact_valid when rising_edge(clk);*/

    -- data_out_valid  <= data_acc_out_valid;
    -- data_out        <= data_acc_out;
    -- data_out <= data_acc_in2;
    -- data_out_valid <= data_acc_in2_valid;

    psum_output_valid : process (clk, rstn) is
    begin

        if not rstn then
            r_command_read_psum <= '0';
        elsif rising_edge(clk) then
            if r_enable_d then
                if i_command_psum = c_lb_read then
                    r_command_read_psum <= '1';
                else
                    r_command_read_psum <= '0';
                end if;
            else
                r_command_read_psum <= '0';
            end if;
        end if;

    end process psum_output_valid;

    delays : process (clk, rstn) is
    begin

        if not rstn then
            r_command_read_psum_delay <= '0';
        elsif rising_edge(clk) then
            -- if i_enable then
            r_command_read_psum_delay <= r_command_read_psum;
        -- end if;
        end if;

    end process delays;

    -- r_command_read_psum_delay <= r_command_read_psum;
    -- r_command_read_iact_delay <= r_command_read_iact;
    -- r_command_read_wght_delay <= r_command_read_wght;

    data_delays : process (clk, rstn) is
    begin

        if not rstn then
            o_data_out_iact        <= (others => '0');
            o_data_out_wght        <= (others => '0');
            o_data_out_iact_valid  <= '0';
            o_data_out_wght_valid  <= '0';
            r_data_iact_wide       <= (others => '0');
            r_data_iact_wide_valid <= '0';
        elsif rising_edge(clk) then
            o_data_out_iact        <= i_data_in_iact;
            o_data_out_wght        <= i_data_in_wght;
            o_data_out_iact_valid  <= i_data_in_iact_valid;
            o_data_out_wght_valid  <= i_data_in_wght_valid;
            r_data_iact_wide       <= w_demux_input_iact;
            r_data_iact_wide_valid <= w_demux_input_iact_valid;
        end if;

    end process data_delays;

    line_buffer_iact : component line_buffer
        generic map (
            line_length => line_length_iact,
            addr_width  => addr_width_iact,
            data_width  => data_width_iact,
            psum_type   => false
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            i_enable           => i_enable,
            i_data             => w_data_in_iact,
            i_data_valid       => w_data_in_iact_valid,
            o_data             => w_data_iact,
            o_data_valid       => w_data_iact_valid,
            o_buffer_full      => o_buffer_full_iact,
            o_buffer_full_next => o_buffer_full_next_iact,
            i_update_val       => (others => '0'),
            i_update_offset    => i_update_offset_iact,
            i_read_offset      => i_read_offset_iact,
            i_command          => i_command_iact
        );

    line_buffer_psum : component line_buffer
        generic map (
            line_length => line_length_psum,
            addr_width  => addr_width_psum,
            data_width  => data_width_psum,
            psum_type   => true
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            i_enable           => i_enable,
            i_data             => i_data_in_psum,
            i_data_valid       => i_data_in_psum_valid,
            o_data             => w_data_psum,
            o_data_valid       => w_data_psum_valid,
            o_buffer_full      => o_buffer_full_psum,
            o_buffer_full_next => o_buffer_full_next_psum,
            i_update_val       => w_data_acc_out,
            i_update_offset    => i_update_offset_psum,
            i_read_offset      => i_read_offset_psum,
            i_command          => i_command_psum
        );

    line_buffer_wght : component line_buffer
        generic map (
            line_length => line_length_wght,
            addr_width  => addr_width_wght,
            data_width  => data_width_wght,
            psum_type   => false
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            i_enable           => i_enable,
            i_data             => i_data_in_wght,
            i_data_valid       => i_data_in_wght_valid,
            o_data             => w_data_wght,
            o_data_valid       => w_data_wght_valid,
            o_buffer_full      => o_buffer_full_wght,
            o_buffer_full_next => o_buffer_full_next_wght,
            i_update_val       => (others => '0'),
            i_update_offset    => i_update_offset_wght,
            i_read_offset      => i_read_offset_wght,
            i_command          => i_command_wght
        );

    mult_1 : component mult
        generic map (
            input_width  => data_width_iact,
            output_width => data_width_psum
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => w_iact_wght_valid,
            i_data_a       => w_data_iact,
            i_data_b       => w_data_wght,
            o_result       => w_data_mult,
            o_result_valid => w_data_mult_valid
        );

    acc_1 : component acc
        generic map (
            input_width  => data_width_psum,
            output_width => data_width_psum
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => w_data_acc_valid,
            i_data_a       => w_data_acc_in1,
            i_data_b       => w_data_acc_in2,
            o_result       => w_data_acc_out,
            o_result_valid => w_data_acc_out_valid
        );

    mux_psum : component mux
        generic map (
            input_width   => data_width_psum,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0) => w_data_mult,
            v_i(1) => w_demux_input_psum,
            sel(0) => r_sel_mult_psum,
            z_o    => w_data_acc_in1
        );

    mux_psum_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0)(0) => w_data_mult_valid,
            v_i(1)(0) => w_demux_input_psum_valid,
            sel(0)    => r_sel_mult_psum,
            z_o(0)    => w_data_acc_in1_valid
        );

    mux_iact : component mux
        generic map (
            input_width   => data_width_iact,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0) => i_data_in_iact,
            v_i(1) => w_demux_input_iact(data_width_iact - 1 downto 0),
            sel(0) => r_sel_conv_gemm and r_sel_iact_input,
            z_o    => w_data_in_iact
        );

    mux_iact_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0)(0) => i_data_in_iact_valid,
            v_i(1)(0) => w_demux_input_iact_valid,
            sel(0)    => r_sel_conv_gemm and r_sel_iact_input,
            z_o(0)    => w_data_in_iact_valid
        );

    pe_output_psum_sel : if pe_north = true generate
        w_sel_output <= not r_sel_iact_input;
    else generate
        w_sel_output <= r_sel_conv_gemm;
    end generate pe_output_psum_sel;

    mux_output : component mux
        generic map (
            input_width   => data_width_psum,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0) => w_data_psum,
            v_i(1) => r_data_iact_wide,
            sel(0) => w_sel_output,
            z_o    => o_data_out
        );

    mux_output_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => 2,
            address_width => 1
        )
        port map (
            v_i(0)(0) => r_command_read_psum_delay,
            v_i(1)(0) => r_data_iact_wide_valid,
            sel(0)    => w_sel_output,
            z_o(0)    => o_data_out_valid
        );

    demux_input : component demux
        generic map (
            output_width  => data_width_psum,
            output_num    => 2,
            address_width => 1
        )
        port map (
            v_i    => i_data_in,
            sel(0) => r_sel_conv_gemm,
            z_o(0) => w_demux_input_psum,
            z_o(1) => w_demux_input_iact
        );

    demux_input_valid : component demux
        generic map (
            output_width  => 1,
            output_num    => 2,
            address_width => 1
        )
        port map (
            v_i(0)    => i_data_in_valid_chg,
            sel(0)    => r_sel_conv_gemm,
            z_o(0)(0) => w_demux_input_psum_valid,
            z_o(1)(0) => w_demux_input_iact_valid
        );

    r_enable            <= i_enable when rising_edge(clk);
    r_enable_d          <= r_enable when rising_edge(clk);
    r_enable_dd         <= r_enable_d when rising_edge(clk);
    r_enable_ddd        <= r_enable_dd when rising_edge(clk);
    i_data_in_valid_chg <= '0' when r_sel_mult_psum = '1' and r_enable_ddd = '0' else
                           i_data_in_valid; -- 0 if enable off and psum path active

end architecture behavioral;

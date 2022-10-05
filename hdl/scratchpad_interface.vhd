library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity scratchpad_interface is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 32;
        addr_width_iact     : positive := 5;
        addr_width_iact_mem : positive := 15;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 127;
        addr_width_psum     : positive := 7;
        addr_width_psum_mem : positive := 15;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 32;
        addr_width_wght     : positive := 5;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_channels    : positive := 3;
        g_image_y     : positive := 14;
        g_image_x     : positive := 14;
        g_kernel_size : positive := 5
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        start  : in    std_logic;
        status : out   std_logic;

        -- Data to and from Address generator
        i_address_iact : in    array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        i_address_wght : in    array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

        i_address_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
        i_address_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

        o_fifo_iact_address_full : out   std_logic; -- to pause address generator
        o_fifo_wght_address_full : out   std_logic; -- to pause address generator

        -- Addresses to Scratchpad
        o_address_iact : out   std_logic_vector(addr_width_iact_mem - 1 downto 0);
        o_address_wght : out   std_logic_vector(addr_width_wght_mem - 1 downto 0);

        o_address_iact_valid : out   std_logic;
        o_address_wght_valid : out   std_logic;

        o_address_psum  : out   std_logic_vector(addr_width_psum_mem - 1 downto 0);
        o_write_en_psum : out   std_logic;
        o_data_psum     : out   std_logic_vector(data_width_psum - 1 downto 0);

        -- Data from Scratchpad
        i_data_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        i_data_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

        i_data_iact_valid : in    std_logic;
        i_data_wght_valid : in    std_logic;

        -- Data to PE array
        o_data_iact : out   array_t(0 to size_rows - 1)(data_width_iact - 1 downto 0);
        o_data_wght : out   array_t(0 to size_y - 1)(data_width_wght - 1 downto 0);

        o_data_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_data_wght_valid : out   std_logic_vector(size_y - 1 downto 0);

        -- Buffer full signals from PE array
        i_buffer_full_iact : in    std_logic_vector(size_rows - 1 downto 0);
        i_buffer_full_wght : in    std_logic_vector(size_y - 1 downto 0);

        -- Data from PE array
        i_psums       : in    array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        i_psums_valid : in    std_logic_vector(size_x - 1 downto 0)
    );
end entity scratchpad_interface;

architecture rtl of scratchpad_interface is

    component fifo_generator_0 is
        port (
            rst         : in    std_logic;
            wr_clk      : in    std_logic;
            rd_clk      : in    std_logic;
            din         : in    std_logic_vector(15 downto 0);
            wr_en       : in    std_logic;
            rd_en       : in    std_logic;
            dout        : out   std_logic_vector(15 downto 0);
            full        : out   std_logic;
            almost_full : out   std_logic;
            empty       : out   std_logic;
            valid       : out   std_logic
        );
    end component;

    component demux is
        generic (
            output_width  : natural := 8;
            output_num    : natural := 2;
            address_width : natural := 1
        );
        port (
            v_i : in    std_logic_vector(output_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   array_t(0 to output_num - 1)(output_width - 1 downto 0)
        );
    end component demux;

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

    component rr_arbiter is
        generic (
            arbiter_width : positive := 9
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;
            req  : in    std_logic_vector(arbiter_width - 1 downto 0);
            gnt  : out   std_logic_vector(arbiter_width - 1 downto 0)
        );
    end component rr_arbiter;

    component onehot_binary is
        generic (

            onehot_width : positive := 9;
            binary_width : positive := 4
        );
        port (
            onehot : in    std_logic_vector(onehot_width - 1 downto 0);
            binary : out   std_logic_vector(binary_width - 1 downto 0)
        );
    end component onehot_binary;

    signal sel_iact_fifo : std_logic_vector(addr_width_rows - 1 downto 0);
    signal sel_wght_fifo : std_logic_vector(addr_width_y - 1 downto 0);

    signal demux_iact_out       : array_t(0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal demux_wght_out       : array_t(0 to size_y - 1)(data_width_wght - 1 downto 0);
    signal demux_iact_out_valid : array_t(0 to size_rows - 1)(0 downto 0);
    signal demux_wght_out_valid : array_t(0 to size_y - 1)(0 downto 0);

    signal rd_en_iact_f       : std_logic_vector(size_rows - 1 downto 0);
    signal dout_iact_f        : array_t(0 to size_rows - 1)(data_width_psum - 1 downto 0);
    signal full_iact_f        : std_logic_vector(size_rows - 1 downto 0);
    signal almost_full_iact_f : std_logic_vector(size_rows - 1 downto 0);
    signal empty_iact_f       : std_logic_vector(size_rows - 1 downto 0);
    signal valid_iact_f       : std_logic_vector(size_rows - 1 downto 0);

    signal rd_en_wght_f       : std_logic_vector(size_y - 1 downto 0);
    signal dout_wght_f        : array_t(0 to size_y - 1)(data_width_psum - 1 downto 0);
    signal full_wght_f        : std_logic_vector(size_y - 1 downto 0);
    signal almost_full_wght_f : std_logic_vector(size_y - 1 downto 0);
    signal empty_wght_f       : std_logic_vector(size_y - 1 downto 0);
    signal valid_wght_f       : std_logic_vector(size_y - 1 downto 0);

    signal rd_en_iact_address_f : std_logic_vector(size_rows - 1 downto 0);
    signal dout_iact_address_f  : array_t(0 to size_rows - 1)(fifo_width - 1 downto 0);
    signal full_iact_address_f  : std_logic_vector(size_rows - 1 downto 0);
    signal empty_iact_address_f : std_logic_vector(size_rows - 1 downto 0);
    signal valid_iact_address_f : array_t(0 to size_rows - 1)(0 downto 0);

    signal rd_en_wght_address_f : std_logic_vector(size_y - 1 downto 0);
    signal dout_wght_address_f  : array_t(0 to size_y - 1)(fifo_width - 1 downto 0);
    signal full_wght_address_f  : std_logic_vector(size_y - 1 downto 0);
    signal empty_wght_address_f : std_logic_vector(size_y - 1 downto 0);
    signal valid_wght_address_f : array_t(0 to size_y - 1)(0 downto 0);

    signal gnt_iact          : std_logic_vector(size_rows - 1 downto 0);
    signal gnt_iact_binary   : std_logic_vector(addr_width_rows - 1 downto 0);
    signal gnt_iact_binary_d : std_logic_vector(addr_width_rows - 1 downto 0);

    signal gnt_wght          : std_logic_vector(size_y - 1 downto 0);
    signal gnt_wght_binary   : std_logic_vector(addr_width_y - 1 downto 0);
    signal gnt_wght_binary_d : std_logic_vector(addr_width_y - 1 downto 0);

    signal gnt_psum          : std_logic_vector(size_x - 1 downto 0);
    signal gnt_psum_binary   : std_logic_vector(addr_width_x - 1 downto 0);
    signal gnt_psum_binary_d : std_logic_vector(addr_width_x - 1 downto 0);

    signal address_iact_wide : std_logic_vector(fifo_width - 1 downto 0);
    signal address_wght_wide : std_logic_vector(fifo_width - 1 downto 0);

    signal rd_en_psum_out_f : std_logic_vector(size_x - 1 downto 0);
    signal dout_psum_out_f  : array_t(0 to size_x - 1)(fifo_width - 1 downto 0);
    signal full_psum_out_f  : std_logic_vector(size_x - 1 downto 0);
    signal empty_psum_out_f : std_logic_vector(size_x - 1 downto 0);
    signal valid_psum_out_f : std_logic_vector(size_x - 1 downto 0);
    signal valid_psum_in    : array_t(0 to size_x - 1)(0 downto 0);

    signal start_delay : std_logic_vector(fifo_width * 5 - 1 downto 0); /* TODO change start delay */

    procedure incr_iact (variable counter : inout integer) is
    begin

        if counter = size_rows - 1 then
            counter := 0;
        else
            counter := counter + 1;
        end if;

    end procedure;

    procedure incr_wght (variable counter : inout integer) is
    begin

        if counter = size_y - 1 then
            counter := 0;
        else
            counter := counter + 1;
        end if;

    end procedure;

begin

    status <= '1' when start_delay(fifo_width * 5 - 1) = '1' else
              '0'; /* TODO change start delay */

    o_address_iact <= address_iact_wide(addr_width_iact_mem - 1 downto 0);
    o_address_wght <= address_wght_wide(addr_width_wght_mem - 1 downto 0);

    o_data_iact_valid <= valid_iact_f;
    o_data_wght_valid <= valid_wght_f;

    p_start_delay : process (clk, rstn) is
    begin

        if not rstn then
            start_delay <= (others => '0');
        elsif rising_edge(clk) then
            if start then
                start_delay <= start_delay(fifo_width * 5 - 2 downto 0) & '1'; /* TODO change start delay */
            end if;
        end if;

    end process p_start_delay;

    pe_arr_iact : for i in 0 to size_rows - 1 generate

        o_data_iact(i) <= dout_iact_f(i)(data_width_iact - 1 downto 0);

        rd_en_iact_f(i) <= '1' when start = '1' and i_buffer_full_iact(i) = '0' and empty_iact_f(i) <= '0' else
                           '0';

    end generate pe_arr_iact;

    pe_arr_wght : for i in 0 to size_y - 1 generate

        o_data_wght(i) <= dout_wght_f(i)(data_width_wght - 1 downto 0);

        rd_en_wght_f(i) <= '1' when start = '1' and i_buffer_full_wght(i) = '0' and empty_wght_f(i) <= '0' else
                           '0';

    end generate pe_arr_wght;

    rd_en_iact_address_f <= gnt_iact when not empty_iact_address_f(to_integer(unsigned(gnt_iact_binary))) else -- Selected with arbiter
                            (others => '0');

    rd_en_wght_address_f <= gnt_wght when not empty_wght_address_f(to_integer(unsigned(gnt_wght_binary))) else -- Selected with arbiter
                            (others => '0');

    sel_iact_fifo <= gnt_iact_binary_d when rising_edge(clk_sp);
    sel_wght_fifo <= gnt_wght_binary_d when rising_edge(clk_sp);

    gnt_iact_binary_d <= gnt_iact_binary when rising_edge(clk_sp);
    gnt_wght_binary_d <= gnt_wght_binary when rising_edge(clk_sp);
    gnt_psum_binary_d <= gnt_psum_binary when rising_edge(clk_sp);

    o_fifo_iact_address_full <= or full_iact_address_f;
    o_fifo_wght_address_full <= or full_wght_address_f;

    mux_iact_address : component mux
        generic map (
            input_width   => fifo_width,
            input_num     => size_rows,
            address_width => addr_width_rows
        )
        port map (
            v_i => dout_iact_address_f,
            sel => gnt_iact_binary_d,
            z_o => address_iact_wide
        );

    mux_wght_address : component mux
        generic map (
            input_width   => fifo_width,
            input_num     => size_y,
            address_width => addr_width_y
        )
        port map (
            v_i => dout_wght_address_f,
            sel => gnt_wght_binary_d,
            z_o => address_wght_wide
        );

    mux_iact_address_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => size_rows,
            address_width => addr_width_rows
        )
        port map (
            v_i    => valid_iact_address_f,
            sel    => gnt_iact_binary_d,
            z_o(0) => o_address_iact_valid
        );

    mux_wght_address_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => size_y,
            address_width => addr_width_y
        )
        port map (
            v_i    => valid_wght_address_f,
            sel    => gnt_wght_binary_d,
            z_o(0) => o_address_wght_valid
        );

    rr_arbiter_iact : component rr_arbiter
        generic map (
            arbiter_width => size_rows
        )
        port map (
            clk  => clk_sp,
            rstn => rstn,
            req  => not almost_full_iact_f,
            gnt  => gnt_iact
        );

    rr_arbiter_iact_binary : component onehot_binary
        generic map (
            onehot_width => size_rows,
            binary_width => addr_width_rows
        )
        port map (
            onehot => gnt_iact,
            binary => gnt_iact_binary
        );

    rr_arbiter_wght : component rr_arbiter
        generic map (
            arbiter_width => size_y
        )
        port map (
            clk  => clk_sp,
            rstn => rstn,
            req  => not almost_full_wght_f,
            gnt  => gnt_wght
        );

    rr_arbiter_wght_binary : component onehot_binary
        generic map (
            onehot_width => size_y,
            binary_width => addr_width_y
        )
        port map (
            onehot => gnt_wght,
            binary => gnt_wght_binary
        );

    demux_iact : component demux
        generic map (
            output_width  => 8,
            output_num    => size_rows,
            address_width => addr_width_rows
        )
        port map (
            v_i => i_data_iact,
            sel => sel_iact_fifo,
            z_o => demux_iact_out
        );

    demux_iact_valid : component demux
        generic map (
            output_width  => 1,
            output_num    => size_rows,
            address_width => addr_width_rows
        )
        port map (
            v_i(0) => i_data_iact_valid,
            sel    => sel_iact_fifo,
            z_o    => demux_iact_out_valid
        );

    demux_wght : component demux
        generic map (
            output_width  => 8,
            output_num    => size_y,
            address_width => addr_width_y
        )
        port map (
            v_i => i_data_wght,
            sel => sel_wght_fifo,
            z_o => demux_wght_out
        );

    demux_wght_valid : component demux
        generic map (
            output_width  => 1,
            output_num    => size_y,
            address_width => addr_width_y
        )
        port map (
            v_i(0) => i_data_wght_valid,
            sel    => sel_wght_fifo,
            z_o    => demux_wght_out_valid
        );

    fifo_iact : for y in 0 to size_rows - 1 generate

        fifo_iact : component fifo_generator_0
            port map (
                rst         => not rstn,
                wr_clk      => clk_sp,
                rd_clk      => clk,
                din         => (data_width_psum - 1 downto data_width_iact => '0') & demux_iact_out(y),
                wr_en       => demux_iact_out_valid(y)(0),
                rd_en       => rd_en_iact_f(y),
                dout        => dout_iact_f(y),
                full        => full_iact_f(y),
                almost_full => almost_full_iact_f(y),
                empty       => empty_iact_f(y),
                valid       => valid_iact_f(y)
            );

    end generate fifo_iact;

    fifo_wght : for y in 0 to size_y - 1 generate

        fifo_wght : component fifo_generator_0
            port map (
                rst         => not rstn,
                wr_clk      => clk_sp,
                rd_clk      => clk,
                din         => (data_width_psum - 1 downto data_width_wght => '0') & demux_wght_out(y),
                wr_en       => demux_wght_out_valid(y)(0),
                rd_en       => rd_en_wght_f(y),
                dout        => dout_wght_f(y),
                full        => full_wght_f(y),
                almost_full => almost_full_wght_f(y),
                empty       => empty_wght_f(y),
                valid       => valid_wght_f(y)
            );

    end generate fifo_wght;

    fifo_iact_address : for y in 0 to size_rows - 1 generate

        fifo_iact_address : component fifo_generator_0
            port map (
                rst    => not rstn,
                wr_clk => clk,
                rd_clk => clk_sp,
                din    => (fifo_width - 1 downto addr_width_iact_mem => '0') & i_address_iact(y),
                wr_en  => i_address_iact_valid(y),
                rd_en  => rd_en_iact_address_f(y),
                dout   => dout_iact_address_f(y),
                full   => full_iact_address_f(y),
                empty  => empty_iact_address_f(y),
                valid  => valid_iact_address_f(y)(0)
            );

    end generate fifo_iact_address;

    fifo_wght_address : for y in 0 to size_y - 1 generate

        fifo_wght_address : component fifo_generator_0
            port map (
                rst    => not rstn,
                wr_clk => clk,
                rd_clk => clk_sp,
                din    => (fifo_width - 1 downto addr_width_wght_mem => '0') & i_address_wght(y),
                wr_en  => i_address_wght_valid(y),
                rd_en  => rd_en_wght_address_f(y),
                dout   => dout_wght_address_f(y),
                full   => full_wght_address_f(y),
                empty  => empty_wght_address_f(y),
                valid  => valid_wght_address_f(y)(0)
            );

    end generate fifo_wght_address;

    fifo_psum_out : for x in 0 to size_x - 1 generate

        fifo_psum_out : component fifo_generator_0
            port map (
                rst    => not rstn,
                wr_clk => clk,
                rd_clk => clk_sp,
                din    => i_psums(x),
                wr_en  => i_psums_valid(x),
                rd_en  => rd_en_psum_out_f(x),
                dout   => dout_psum_out_f(x),
                full   => full_psum_out_f(x),
                empty  => empty_psum_out_f(x),
                valid  => valid_psum_out_f(x)
            );

    end generate fifo_psum_out;

    mux_psum_out : component mux
        generic map (
            input_width   => data_width_psum,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i => i_psums,
            sel => gnt_psum_binary,
            z_o => o_data_psum
        );

    /* TODO Address generator / incrementer for psum output */
    o_address_psum <= (others => '0');

    g_psums_valid : for i in 0 to size_x - 1 generate

        valid_psum_in(i)(0) <= i_psums_valid(i);
        rd_en_psum_out_f(i) <= gnt_psum(i);

    end generate g_psums_valid;

    mux_psum_out_valid : component mux
        generic map (
            input_width   => 1,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i    => valid_psum_in,
            sel    => gnt_psum_binary,
            z_o(0) => o_write_en_psum
        );

    rr_arbiter_psum : component rr_arbiter
        generic map (
            arbiter_width => size_x
        )
        port map (
            clk  => clk_sp,
            rstn => rstn,
            req  => not empty_psum_out_f,
            gnt  => gnt_psum
        );

    rr_arbiter_psum_binary : component onehot_binary
        generic map (
            onehot_width => size_x,
            binary_width => addr_width_x
        )
        port map (
            onehot => gnt_psum,
            binary => gnt_psum_binary
        );

end architecture rtl;

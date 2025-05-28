library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity scratchpad_interface is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_x : positive := 3;

        data_width_input : positive := 8; -- width of the input data (weights, iacts)
        data_width_psum  : positive := 16;

        mem_addr_width : positive := 15;
        mem_data_width : positive := 64; -- iact word width from memory
        mem_word_count : positive := mem_data_width / data_width_input;

        mem_offset_width : positive := integer(ceil(log2(real(mem_word_count))));

        g_iact_fifo_size         : positive := 16;
        g_wght_fifo_size         : positive := 16;
        g_psum_fifo_size         : positive := 32;
        g_iact_address_fifo_size : positive := 8;
        g_wght_address_fifo_size : positive := 8
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        i_start  : in    std_logic;
        i_params : in    parameters_t;
        o_enable : out   std_logic;
        o_status : out   status_info_spadif_t;

        -- Data to and from Address generator
        i_address_iact : in    array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
        i_address_wght : in    array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
        i_address_psum : in    array_t(0 to size_x - 1)(mem_addr_width + mem_offset_width - 1 downto 0);

        i_address_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
        i_address_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

        -- to pause address generator
        o_fifo_iact_address_full : out   std_logic;
        o_fifo_wght_address_full : out   std_logic;

        -- input to create done signal
        i_addr_iact_done : in    std_logic;
        i_addr_wght_done : in    std_logic;

        -- from / to psum address generator
        i_psum_suppress     : in    std_logic_vector(size_x - 1 downto 0);
        o_req_addr_psum     : out   std_logic_vector(size_x - 1 downto 0);
        o_all_psum_finished : out   std_logic;

        -- Addresses to Scratchpad
        o_address       : out   std_logic_vector(mem_addr_width - 1 downto 0);
        o_address_valid : out   std_logic;

        o_write_en_psum : out   std_logic_vector(mem_word_count - 1 downto 0);
        o_addr_psum     : out   std_logic_vector(mem_addr_width - 1 downto 0);
        o_data_psum     : out   std_logic_vector(mem_data_width - 1 downto 0);

        -- Data from Scratchpad
        i_data       : in    std_logic_vector(mem_data_width - 1 downto 0);
        i_data_valid : in    std_logic;

        -- Data to PE array
        o_data_iact : out   array_t(0 to size_rows - 1)(data_width_input - 1 downto 0);
        o_data_wght : out   array_t(0 to size_y - 1)(data_width_input - 1 downto 0);

        o_data_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_data_wght_valid : out   std_logic_vector(size_y - 1 downto 0);

        -- Buffer full signals from PE array
        i_buffer_full_iact      : in    std_logic_vector(size_rows - 1 downto 0);
        i_buffer_full_next_iact : in    std_logic_vector(size_rows - 1 downto 0);
        i_buffer_full_wght      : in    std_logic_vector(size_y - 1 downto 0);
        i_buffer_full_next_wght : in    std_logic_vector(size_y - 1 downto 0);

        -- Data from PE array
        i_psums          : in    array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        i_psums_valid    : in    std_logic_vector(size_x - 1 downto 0);
        i_psums_last     : in    std_logic_vector(size_x - 1 downto 0);
        i_psums_halfword : in    std_logic_vector(size_x - 1 downto 0);

        -- Data from control
        i_pause_iact : in    std_logic
    );
end entity scratchpad_interface;

architecture rtl of scratchpad_interface is

    constant load_channels   : integer := size_rows + size_y;
    constant addr_width_load : integer := integer(ceil(log2(real(load_channels))));

    -- psum width can any integer. when storing raw psums to memory, round up to next power-of-two.
    -- alternatively, we could round up to the next multiple of 8 to pack raw psums more tightly.
    constant data_width_psum_raw_mem : integer := integer(2 ** ceil(log2(real(data_width_psum))));
    constant raw_psums_per_mem_word  : integer := mem_data_width / data_width_psum_raw_mem;
    constant bytes_per_raw_psum      : integer := integer(ceil(real(data_width_psum) / 8.0));
    constant bytes_per_raw_psum_mem  : integer := mem_data_width / raw_psums_per_mem_word / 8;

    -- merged load address vectors for unified scratchpad access
    signal w_arb_req_load         : std_logic_vector(load_channels - 1 downto 0);
    signal w_load_address_f       : array_t(0 to load_channels - 1)(mem_addr_width - 1 downto 0);
    signal w_gnt_load             : std_logic_vector(load_channels - 1 downto 0);
    signal w_gnt_load_idx         : std_logic_vector(addr_width_load - 1 downto 0);
    signal r_gnt_load_idx_d       : std_logic_vector(addr_width_load - 1 downto 0);
    signal w_valid_load_address_f : array_t(0 to load_channels - 1)(0 downto 0);
    signal r_sel_load_fifo        : std_logic_vector(addr_width_load - 1 downto 0);

    signal w_rst : std_logic;

    signal w_demux_iact_out_valid : array_t(0 to size_rows - 1)(0 downto 0);
    signal w_demux_wght_out_valid : array_t(0 to size_y - 1)(0 downto 0);
    signal w_demux_load_out_valid : array_t(0 to load_channels - 1)(0 downto 0);

    signal w_iact_serializer_ready : std_logic_vector(size_rows - 1 downto 0);
    signal w_wght_serializer_ready : std_logic_vector(size_rows - 1 downto 0);
    signal r_dout_iact_f_valid     : std_logic_vector(size_rows - 1 downto 0);
    signal r_dout_wght_f_valid     : std_logic_vector(size_rows - 1 downto 0);

    signal w_rd_en_iact_f       : std_logic_vector(size_rows - 1 downto 0);
    signal w_rd_en_iact_f_d     : std_logic_vector(size_rows - 1 downto 0);
    signal w_dout_iact_f        : array_t(0 to size_rows - 1)(mem_data_width - 1 downto 0);
    signal w_full_iact_f        : std_logic_vector(size_rows - 1 downto 0);
    signal w_almost_full_iact_f : std_logic_vector(size_rows - 1 downto 0);
    signal w_empty_iact_f       : std_logic_vector(size_rows - 1 downto 0);
    signal w_valid_iact_f       : std_logic_vector(size_rows - 1 downto 0);

    signal w_rd_en_wght_f       : std_logic_vector(size_y - 1 downto 0);
    signal w_rd_en_wght_f_d     : std_logic_vector(size_y - 1 downto 0);
    signal w_dout_wght_f        : array_t(0 to size_y - 1)(mem_data_width - 1 downto 0);
    signal w_full_wght_f        : std_logic_vector(size_y - 1 downto 0);
    signal w_almost_full_wght_f : std_logic_vector(size_y - 1 downto 0);
    signal w_empty_wght_f       : std_logic_vector(size_y - 1 downto 0);
    signal w_valid_wght_f       : std_logic_vector(size_y - 1 downto 0);

    signal w_rd_en_iact_address_f : std_logic_vector(size_rows - 1 downto 0);
    signal w_dout_iact_address_f  : array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
    signal w_full_iact_address_f  : std_logic_vector(size_rows - 1 downto 0);
    signal w_empty_iact_address_f : std_logic_vector(size_rows - 1 downto 0);
    signal w_valid_iact_address_f : array_t(0 to size_rows - 1)(0 downto 0);

    signal w_rd_en_wght_address_f : std_logic_vector(size_y - 1 downto 0);
    signal w_dout_wght_address_f  : array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
    signal w_full_wght_address_f  : std_logic_vector(size_y - 1 downto 0);
    signal w_empty_wght_address_f : std_logic_vector(size_y - 1 downto 0);
    signal w_valid_wght_address_f : array_t(0 to size_y - 1)(0 downto 0);

    signal w_arb_req_iact : std_logic_vector(size_rows - 1 downto 0);
    signal w_gnt_iact     : std_logic_vector(size_rows - 1 downto 0);

    signal w_arb_req_wght : std_logic_vector(size_y - 1 downto 0);
    signal w_gnt_wght     : std_logic_vector(size_y - 1 downto 0);

    signal w_arb_req_psum   : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum       : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum_idx   : std_logic_vector(addr_width_x - 1 downto 0);
    signal r_gnt_psum_idx_d : std_logic_vector(addr_width_x - 1 downto 0) := (others => '0');

    constant c_psum_wide_words_width : positive := positive(ceil(log2(real(mem_word_count))));
    constant c_psum_fifo_width       : integer  := mem_data_width + mem_word_count + mem_addr_width;

    signal w_psum_packed_valid         : array_t(0 to size_x - 1)(mem_word_count - 1 downto 0);
    signal w_psum_packed               : array_t(0 to size_x - 1)(mem_data_width - 1 downto 0);
    signal w_psum_packed_raw_valid     : array_t(0 to size_x - 1)(raw_psums_per_mem_word * bytes_per_raw_psum - 1 downto 0);
    signal w_psum_packed_raw           : array_t(0 to size_x - 1)(raw_psums_per_mem_word * data_width_psum - 1 downto 0);
    signal w_psum_packed_raw_pad_valid : array_t(0 to size_x - 1)(mem_word_count - 1 downto 0);
    signal w_psum_packed_raw_pad       : array_t(0 to size_x - 1)(mem_data_width - 1 downto 0);

    signal w_psum_valid_out   : std_logic;
    signal w_wen_psum         : std_logic_vector(mem_word_count - 1 downto 0);
    signal r_psums_halfword_d : std_logic_vector(size_x - 1 downto 0);

    signal w_psum_address : array_t(0 to size_x - 1)(mem_addr_width - 1 downto 0);
    signal w_psum_offset  : uns_array_t(0 to size_x - 1)(mem_offset_width - 1 downto 0);

    signal w_rd_en_psum_f : std_logic_vector(size_x - 1 downto 0);
    signal w_wr_en_psum_f : std_logic_vector(size_x - 1 downto 0);
    signal w_din_psum_f   : array_t(0 to size_x - 1)(c_psum_fifo_width - 1 downto 0);
    signal w_dout_psum_f  : array_t(0 to size_x - 1)(c_psum_fifo_width - 1 downto 0);
    signal w_full_psum_f  : std_logic_vector(size_x - 1 downto 0);
    signal w_empty_psum_f : std_logic_vector(size_x - 1 downto 0);
    signal w_valid_psum_f : std_logic_vector(size_x - 1 downto 0);
    signal w_valid_psum   : array_t(0 to size_x - 1)(0 downto 0);
    signal w_psum_out     : array_t(0 to size_x - 1)(c_psum_fifo_width - 1 downto 0);
    signal w_data_psum    : std_logic_vector(c_psum_fifo_width - 1 downto 0);

    signal r_done_iact_pipe, r_done_wght_pipe : std_logic_vector(4 downto 0); -- >= number of sync stages in iact/wght dc_fifo
    signal r_done_iact,      r_done_wght      : std_logic;

    signal r_start_delay : std_logic;
    signal r_start_sp    : std_logic;
    signal r_pause_iact  : std_logic_vector(size_rows - 1 downto 0);
    signal r_startup     : std_logic_vector(10 downto 0); -- TODO Depending on clk_sp / clk factor

    signal r_preload_fifos_done : std_logic;
    signal r_all_psum_empty     : std_logic;

begin

    w_rst <= not rstn;

    -- Delay i_pause_iact signal for to propagate through array
    r_pause_iact(size_rows - 1 downto 0) <= r_pause_iact(size_rows - 2 downto size_y - 1) & i_pause_iact & (size_y - 2 downto 0 => '0') when rising_edge(clk);

    -- Create enable signal for PEs. Enable if first values in buffer (r_preload_fifos_done) and one of three conditions fulfilled:
    -- 1. Input activations "done" and all wght FIFOs not empty
    -- 2. Weights "done" and all iact FIFOs not empty
    -- 3. All wght and iact FIFOs not empty
    p_enable : process (clk, rstn) is

        variable any_iact_fifo_empty, any_wght_fifo_empty : std_logic;

    begin

        if not rstn then
            o_enable <= '0';
        elsif rising_edge(clk) then
            if r_preload_fifos_done = '1' then
                any_iact_fifo_empty := or w_empty_iact_f(size_rows - 1 downto size_y - 1); -- only bottom FIFOs used to support alternative dataflow
                any_wght_fifo_empty := or w_empty_wght_f;

                -- if iacts are done, but there are still weights to load (none of the wght fifos not empty), enable the PE array (guess: only used for GEMM)
                if any_iact_fifo_empty and r_done_iact and not any_wght_fifo_empty then
                    o_enable <= '1';
                -- if wghts are done, but there are still iacts to load (none of the iact fifos not empty), enable the PE array (guess: only used for GEMM)
                elsif any_wght_fifo_empty and r_done_wght and not any_iact_fifo_empty then
                    o_enable <= '1';
                -- as long as iact / wght FIFOs are not drained or iact / wght is done (then it's okay for the FIFOs to drain), enable the pe array
                elsif (r_done_iact or not any_iact_fifo_empty) and (r_done_wght or not any_wght_fifo_empty) then
                    o_enable <= '1';
                else
                    o_enable <= '0';
                end if;
            elsif i_start = '0' then
                o_enable <= '0';
            end if;
        end if;

    end process p_enable;

    -- generate "done" signals for iact and wght by checking whether
    -- 1) address generator has finished, 2) address fifos are drained, 3) data fifos are drained
    -- and all conditions are valid over multiple cycles to compensate for CDC delay in dc_fifo
    p_input_done_gen : process is
    begin

        wait until rising_edge(clk);

        if not rstn or not i_start then
            r_done_iact      <= '0';
            r_done_wght      <= '0';
            r_done_iact_pipe <= (others => '0');
            r_done_wght_pipe <= (others => '0');
        else
            if not r_done_iact and i_addr_iact_done and (and w_empty_iact_address_f(size_rows - 1 downto size_y - 1)) and (and w_empty_iact_f(size_rows - 1 downto size_y - 1)) then
                r_done_iact_pipe(0) <= '1';
            end if;

            if not r_done_wght and i_addr_wght_done and (and w_empty_wght_address_f) and (and w_empty_wght_f) then
                r_done_wght_pipe(0) <= '1';
            end if;

            r_done_iact_pipe(r_done_iact_pipe'high downto 1) <= r_done_iact_pipe(r_done_iact_pipe'high - 1 downto 0);
            r_done_wght_pipe(r_done_wght_pipe'high downto 1) <= r_done_wght_pipe(r_done_wght_pipe'high - 1 downto 0);

            r_done_iact <= and r_done_iact_pipe;
            r_done_wght <= and r_done_wght_pipe;
        end if;

    end process p_input_done_gen;

    o_status.spad_iact_done     <= r_done_iact;
    o_status.spad_wght_done     <= r_done_wght;
    o_status.preload_fifos_done <= r_preload_fifos_done;

    -- Status signal indicates that the first values are in the buffers. Set to '1' once all address FIFOs not empty.
    p_startup : process (clk, rstn) is
    begin

        if not rstn then
            r_preload_fifos_done <= '0';
            r_startup            <= (others => '0');
        elsif rising_edge(clk) then
            r_startup <= r_startup(9 downto 0) & not (or w_empty_iact_f(size_rows - 1 downto size_y - 1));
            -- alternative: wait for all fifos to be mostly filled with:
            -- & and w_almost_full_iact_f(size_rows - 1 downto size_y - 1)
            if and r_startup = '1' or r_done_iact = '1' then
                r_preload_fifos_done <= '1';
            elsif i_start = '0' then
                r_preload_fifos_done <= '0';
            end if;
        end if;

    end process p_startup;

    gen_pe_arr_iact : for i in 0 to size_rows - 1 generate

        serializer_inst : entity accel.serializer
            generic map (
                in_width  => mem_data_width,
                out_width => data_width_input
            )
            port map (
                clk     => clk,
                rstn    => rstn,
                i_valid => w_valid_iact_f(i) or r_dout_iact_f_valid(i),
                i_data  => w_dout_iact_f(i),
                o_ready => w_iact_serializer_ready(i),
                i_ready => not i_buffer_full_iact(i) and not r_pause_iact(i),
                o_data  => o_data_iact(i),
                o_valid => o_data_iact_valid(i)
            );

        w_rd_en_iact_f(i) <= i_start and not w_empty_iact_f(i) and w_iact_serializer_ready(i);

    end generate gen_pe_arr_iact;

    gen_pe_arr_wght : for i in 0 to size_y - 1 generate

        serializer_inst : entity accel.serializer
            generic map (
                in_width  => mem_data_width,
                out_width => data_width_input
            )
            port map (
                clk     => clk,
                rstn    => rstn,
                i_valid => w_valid_wght_f(i) or r_dout_wght_f_valid(i),
                i_data  => w_dout_wght_f(i),
                o_ready => w_wght_serializer_ready(i),
                i_ready => not i_buffer_full_wght(i),
                o_data  => o_data_wght(i),
                o_valid => o_data_wght_valid(i)
            );

        w_rd_en_wght_f(i) <= i_start and not w_empty_wght_f(i) and w_wght_serializer_ready(i);

    end generate gen_pe_arr_wght;

    w_rd_en_iact_f_d <= w_rd_en_iact_f when rising_edge(clk);
    w_rd_en_wght_f_d <= w_rd_en_wght_f when rising_edge(clk);

    w_rd_en_iact_address_f <= w_gnt_iact and not w_empty_iact_address_f;
    w_rd_en_wght_address_f <= w_gnt_wght and not w_empty_wght_address_f;

    r_sel_load_fifo  <= r_gnt_load_idx_d when rising_edge(clk_sp);
    r_gnt_load_idx_d <= w_gnt_load_idx when rising_edge(clk_sp);
    r_gnt_psum_idx_d <= w_gnt_psum_idx when rising_edge(clk_sp);

    w_arb_req_iact <= (others => '0') when r_start_sp = '0' or r_done_iact = '1' else not w_almost_full_iact_f;
    w_arb_req_wght <= (others => '0') when r_start_sp = '0' or r_done_wght = '1' else not w_almost_full_wght_f;
    w_arb_req_psum <= (others => '0') when r_start_sp = '0' else not w_empty_psum_f;

    o_fifo_iact_address_full <= or w_full_iact_address_f;
    o_fifo_wght_address_full <= or w_full_wght_address_f;

    -- merge address & grant vectors to access to the unified scratchpad
    w_arb_req_load         <= w_arb_req_wght & w_arb_req_iact;
    w_load_address_f       <= w_dout_iact_address_f & w_dout_wght_address_f;
    w_valid_load_address_f <= w_valid_iact_address_f & w_valid_wght_address_f;

    w_demux_iact_out_valid <= w_demux_load_out_valid(0 to size_rows - 1);
    w_demux_wght_out_valid <= w_demux_load_out_valid(size_rows to size_rows + size_y - 1);

    w_gnt_iact <= w_gnt_load(size_rows - 1 downto 0);
    w_gnt_wght <= w_gnt_load(size_rows + size_y - 1 downto size_rows);

    mux_load_address : entity accel.mux
        generic map (
            input_width   => mem_addr_width,
            input_num     => load_channels,
            address_width => addr_width_load
        )
        port map (
            v_i => w_load_address_f,
            sel => r_gnt_load_idx_d,
            z_o => o_address
        );

    mux_load_address_valid : entity accel.mux
        generic map (
            input_width   => 1,
            input_num     => load_channels,
            address_width => addr_width_load
        )
        port map (
            v_i    => w_valid_load_address_f,
            sel    => r_gnt_load_idx_d,
            z_o(0) => o_address_valid
        );

    rr_arbiter_load : entity accel.rr_arbiter
        generic map (
            arbiter_width => load_channels
        )
        port map (
            clk   => clk_sp,
            rstn  => rstn,
            i_req => w_arb_req_load,
            o_gnt => w_gnt_load
        );

    rr_arbiter_load_binary : entity accel.onehot_binary
        generic map (
            onehot_width => load_channels,
            binary_width => addr_width_load
        )
        port map (
            i_onehot => w_gnt_load,
            o_binary => w_gnt_load_idx
        );

    demux_load_valid : entity accel.demux
        generic map (
            output_width  => 1,
            output_num    => load_channels,
            address_width => addr_width_load
        )
        port map (
            v_i(0) => i_data_valid,
            sel    => r_sel_load_fifo,
            z_o    => w_demux_load_out_valid
        );

    gen_fifo_iact : for y in 0 to size_rows - 1 generate

        fifo_iact : entity accel.dc_fifo
            generic map (
                mem_size    => g_iact_fifo_size,
                stages      => 3,
                use_packets => false
            )
            port map (
                rst         => not rstn,
                wr_clk      => clk_sp,
                keep        => '0',
                drop        => '0',
                rd_clk      => clk,
                din         => i_data,
                wr_en       => w_demux_iact_out_valid(y)(0),
                rd_en       => w_rd_en_iact_f(y),
                dout        => w_dout_iact_f(y),
                full        => w_full_iact_f(y),
                almost_full => w_almost_full_iact_f(y),
                empty       => w_empty_iact_f(y),
                valid       => w_valid_iact_f(y)
            );

        assert rstn = '0' or w_demux_iact_out_valid(y)(0) = '0' or w_full_iact_f(y) = '0'
            report "push to full iact fifo " & integer'image(y)
            severity warning;

        fifo_dout_valid_track : process is
        begin

            wait until rising_edge(clk);

            if w_rd_en_iact_f_d(y) or w_iact_serializer_ready(y) then
                r_dout_iact_f_valid(y) <= w_valid_iact_f(y) and not w_iact_serializer_ready(y);
            end if;

        end process fifo_dout_valid_track;

    end generate gen_fifo_iact;

    gen_fifo_wght : for y in 0 to size_y - 1 generate

        fifo_wght : entity accel.dc_fifo
            generic map (
                mem_size    => g_wght_fifo_size,
                stages      => 3,
                use_packets => false
            )
            port map (
                rst         => not rstn,
                wr_clk      => clk_sp,
                keep        => '0',
                drop        => '0',
                rd_clk      => clk,
                din         => i_data,
                wr_en       => w_demux_wght_out_valid(y)(0),
                rd_en       => w_rd_en_wght_f(y),
                dout        => w_dout_wght_f(y),
                full        => w_full_wght_f(y),
                almost_full => w_almost_full_wght_f(y),
                empty       => w_empty_wght_f(y),
                valid       => w_valid_wght_f(y)
            );

        assert rstn = '0' or w_demux_wght_out_valid(y)(0) = '0' or w_full_wght_f(y) = '0'
            report "push to full wght fifo " & integer'image(y)
            severity warning;

        fifo_dout_valid_track : process is
        begin

            wait until rising_edge(clk);

            if w_rd_en_wght_f_d(y) or w_wght_serializer_ready(y) then
                r_dout_wght_f_valid(y) <= w_valid_wght_f(y) and not w_wght_serializer_ready(y);
            end if;

        end process fifo_dout_valid_track;

    end generate gen_fifo_wght;

    gen_fifo_iact_address : for y in 0 to size_rows - 1 generate

        fifo_iact_address : entity accel.dc_fifo
            generic map (
                mem_size    => g_iact_address_fifo_size,
                stages      => 3,
                use_packets => false
            )
            port map (
                rst         => not rstn,
                wr_clk      => clk,
                keep        => '0',
                drop        => '0',
                rd_clk      => clk_sp,
                din         => i_address_iact(y),
                wr_en       => i_address_iact_valid(y),
                rd_en       => w_rd_en_iact_address_f(y),
                dout        => w_dout_iact_address_f(y),
                full        => w_full_iact_address_f(y),
                almost_full => open,
                empty       => w_empty_iact_address_f(y),
                valid       => w_valid_iact_address_f(y)(0)
            );

        assert rstn = '0' or i_address_iact_valid(y) = '0' or w_full_iact_address_f(y) = '0' or not rising_edge(clk)
            report "push to full iact address fifo " & integer'image(y)
            severity warning;

    end generate gen_fifo_iact_address;

    gen_fifo_wght_address : for y in 0 to size_y - 1 generate

        fifo_wght_address : entity accel.dc_fifo
            generic map (
                mem_size    => g_wght_address_fifo_size,
                stages      => 3,
                use_packets => false
            )
            port map (
                rst         => not rstn,
                wr_clk      => clk,
                keep        => '0',
                drop        => '0',
                rd_clk      => clk_sp,
                din         => i_address_wght(y),
                wr_en       => i_address_wght_valid(y),
                rd_en       => w_rd_en_wght_address_f(y),
                dout        => w_dout_wght_address_f(y),
                full        => w_full_wght_address_f(y),
                almost_full => open,
                empty       => w_empty_wght_address_f(y),
                valid       => w_valid_wght_address_f(y)(0)
            );

        assert rstn = '0' or i_address_wght_valid(y) = '0' or w_full_wght_address_f(y) = '0' or not rising_edge(clk)
            report "push to full wght address fifo " & integer'image(y)
            severity warning;

    end generate gen_fifo_wght_address;

    gen_fifo_psum_out : for x in 0 to size_x - 1 generate

        w_psum_address(x) <= i_address_psum(x)(mem_addr_width + mem_offset_width - 1 downto mem_offset_width);
        w_psum_offset(x)  <= unsigned(i_address_psum(x)(mem_offset_width - 1 downto 0));

        psum_parallel_requantized : entity accel.parallelizer
            port map (
                clk      => clk,
                rstn     => rstn,
                i_valid  => i_psums_valid(x) and i_psums_halfword(x),
                i_last   => i_psums_last(x),
                i_data   => i_psums(x)(data_width_input - 1 downto 0),
                i_offset => w_psum_offset(x),
                o_valid  => w_psum_packed_valid(x),
                o_data   => w_psum_packed(x)
            );

        psum_parallel_raw : entity accel.parallelizer
            port map (
                clk      => clk,
                rstn     => rstn,
                i_valid  => i_psums_valid(x) and not i_psums_halfword(x),
                i_last   => i_psums_last(x),
                i_data   => i_psums(x),
                i_offset => w_psum_offset(x),
                o_valid  => w_psum_packed_raw_valid(x),
                o_data   => w_psum_packed_raw(x)
            );

        -- zero-pad raw psums if necessary to make power-of-two words each

        -- vsg_off concurrent_006 concurrent_012

        gen_psum_raw_pad : for n in 0 to raw_psums_per_mem_word - 1 generate
            w_psum_packed_raw_pad(x)(data_width_psum_raw_mem * n + data_width_psum - 1 downto data_width_psum_raw_mem * n)
                <= w_psum_packed_raw(x)(data_width_psum * (n + 1) - 1 downto data_width_psum * n);
            w_psum_packed_raw_pad(x)(data_width_psum_raw_mem * (n + 1) - 1 downto data_width_psum_raw_mem * n + data_width_psum)
                <= (others => w_psum_packed_raw(x)(data_width_psum * (n + 1) - 1)); -- replicate sign bit on full word for valid full-size integers
            w_psum_packed_raw_pad_valid(x)(bytes_per_raw_psum_mem * n + bytes_per_raw_psum - 1 downto bytes_per_raw_psum_mem * n)
                <= w_psum_packed_raw_valid(x)(bytes_per_raw_psum * (n + 1) - 1 downto bytes_per_raw_psum * n);
            w_psum_packed_raw_pad_valid(x)(bytes_per_raw_psum_mem * (n + 1) - 1 downto bytes_per_raw_psum_mem * n + bytes_per_raw_psum)
                <= (others => or w_psum_packed_raw_valid(x)(bytes_per_raw_psum * (n + 1) - 1 downto bytes_per_raw_psum * n));
        end generate gen_psum_raw_pad;

        -- vsg_off concurrent_006 concurrent_012

        -- select correct parallelizer depending on data format (raw vs requantized), and add pipeline stage
        sel_psum_fifo_input : process is
        begin

            wait until rising_edge(clk);

            r_psums_halfword_d(x) <= i_psums_halfword(x);

            -- store wide data words & number of valid words in fifo_psum_out
            if r_psums_halfword_d(x) then
                w_wr_en_psum_f(x) <= (or w_psum_packed_valid(x)) and not i_psum_suppress(x);
                w_din_psum_f(x)   <= w_psum_packed_valid(x) & w_psum_address(x) & w_psum_packed(x);
            else
                w_wr_en_psum_f(x) <= (or w_psum_packed_raw_pad_valid(x)) and not i_psum_suppress(x);
                w_din_psum_f(x)   <= w_psum_packed_raw_pad_valid(x) & w_psum_address(x) & w_psum_packed_raw_pad(x);
            end if;

        end process sel_psum_fifo_input;

        o_req_addr_psum(x) <= or w_psum_packed_valid(x) when i_psums_halfword(x) else or w_psum_packed_raw_pad_valid(x);

        fifo_psum_out : entity accel.dc_fifo
            generic map (
                mem_size    => g_psum_fifo_size,
                stages      => 3,
                use_packets => false
            )
            port map (
                wr_clk      => clk,
                rst         => not rstn,
                wr_en       => w_wr_en_psum_f(x),
                din         => w_din_psum_f(x),
                full        => w_full_psum_f(x),
                almost_full => open,
                keep        => '0',
                drop        => '0',
                rd_clk      => clk_sp,
                rd_en       => w_rd_en_psum_f(x),
                dout        => w_dout_psum_f(x),
                valid       => w_valid_psum_f(x),
                empty       => w_empty_psum_f(x)
            );

        assert rstn = '0' or w_wr_en_psum_f(x) = '0' or w_full_psum_f(x) = '0'
            report "push to full psum fifo " & integer'image(x)
            severity warning;

    end generate gen_fifo_psum_out;

    gen_g_psums_valid : for i in 0 to size_x - 1 generate

        w_valid_psum(i)(0) <= w_valid_psum_f(i);
        w_psum_out(i)      <= w_dout_psum_f(i);
        w_rd_en_psum_f(i)  <= w_gnt_psum(i);

    end generate gen_g_psums_valid;

    mux_psum_out : entity accel.mux
        generic map (
            input_width   => c_psum_fifo_width,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i => w_psum_out,
            sel => r_gnt_psum_idx_d,
            z_o => w_data_psum
        );

    -- unpack data from psum fifo
    w_wen_psum  <= w_data_psum(c_psum_fifo_width - 1 downto mem_data_width + mem_addr_width);
    o_addr_psum <= w_data_psum(mem_data_width + mem_addr_width - 1 downto mem_data_width);
    o_data_psum <= w_data_psum(mem_data_width - 1 downto 0);

    o_write_en_psum <= w_wen_psum when w_psum_valid_out = '1' else (others => '0');

    sync_init_done : entity accel.bit_sync
        port map (
            clk     => clk_sp,
            rst     => '0',
            bit_in  => i_start,
            bit_out => r_start_sp
        );

    mux_psum_valid : entity accel.mux
        generic map (
            input_width   => 1,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i    => w_valid_psum,
            sel    => r_gnt_psum_idx_d,
            z_o(0) => w_psum_valid_out
        );

    rr_arbiter_psum : entity accel.rr_arbiter
        generic map (
            arbiter_width => size_x
        )
        port map (
            clk   => clk_sp,
            rstn  => rstn,
            i_req => w_arb_req_psum,
            o_gnt => w_gnt_psum
        );

    rr_arbiter_psum_binary : entity accel.onehot_binary
        generic map (
            onehot_width => size_x,
            binary_width => addr_width_x
        )
        port map (
            i_onehot => w_gnt_psum,
            o_binary => w_gnt_psum_idx
        );

    r_all_psum_empty <= and w_empty_psum_f when rising_edge(clk_sp);

    sync_all_psum_finished : entity accel.bit_sync
        port map (
            clk     => clk,
            rst     => w_rst,
            bit_in  => r_all_psum_empty,
            bit_out => o_all_psum_finished
        );

    p_psum_overflow : process is

        variable temp : natural;

    begin

        wait until rising_edge(clk);
        r_start_delay <= i_start;

        if rstn = '0' or (i_start = '1' and r_start_delay = '0') then
            o_status.psum_overflows <= (others => '0');
        else
            temp := 0;

            for i in w_full_psum_f'range loop

                if (w_wr_en_psum_f(i) and w_full_psum_f(i)) = '1' then
                    temp := temp + 1;
                end if;

            end loop;

            o_status.psum_overflows <= o_status.psum_overflows + temp;
        end if;

    end process p_psum_overflow;

    o_status.spad_iact_full  <= or  w_full_iact_f;  -- clk_sp domain
    o_status.spad_iact_empty <= and w_empty_iact_f; -- clk domain
    o_status.spad_wght_full  <= or  w_full_wght_f;  -- clk_sp domain
    o_status.spad_wght_empty <= and w_empty_wght_f; -- clk domain
    o_status.spad_psum_empty <= and w_empty_psum_f; -- clk_sp domain

end architecture rtl;

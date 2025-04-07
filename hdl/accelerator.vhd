library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity accelerator is
    generic (
        size_x : positive := 5;
        size_y : positive := 5;

        -- pe line buffer length per data type
        line_length_iact : positive := 64;
        line_length_wght : positive := 64;
        line_length_psum : positive := 128;

        -- internal data types
        data_width_input : positive := 8;  -- size of a iact/wght word
        data_width_psum  : positive := 16; -- size of a result word in the PE accumulator / line buffer

        -- address widths scratchpad <-> external, port_a is exposed as i/o on this module
        mem_addr_width : positive := 15; -- defines memory size in words of mem_data_width (e.g. 64 bits)
        mem_word_count : positive := 8;
        mem_data_width : positive := mem_word_count * data_width_input;

        g_iact_fifo_size : positive := 16;
        g_wght_fifo_size : positive := 16;
        g_psum_fifo_size : positive := 32;

        g_files_dir     : string  := "";
        g_init_sp       : boolean := false;
        g_dataflow      : integer := 1;
        use_float_ip    : boolean := false;
        postproc_enable : boolean := true
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        i_start  : in    std_logic;
        o_done   : out   std_logic;
        i_params : in    parameters_t;
        o_status : out   status_info_t;

        i_mem_en       : in    std_logic;
        i_mem_write_en : in    std_logic_vector(mem_word_count - 1 downto 0);
        i_mem_addr     : in    std_logic_vector(mem_addr_width - 1 downto 0);
        i_mem_din      : in    std_logic_vector(mem_data_width - 1 downto 0);
        o_mem_dout     : out   std_logic_vector(mem_data_width - 1 downto 0)
    );
end entity accelerator;

architecture rtl of accelerator is

    constant size_rows : positive := size_x + size_y - 1;

    constant psum_word_offset_width : positive := integer(ceil(log2(real(mem_word_count))));

    constant addr_width_x    : positive := positive(ceil(log2(real(size_x))));
    constant addr_width_y    : positive := positive(ceil(log2(real(size_y))));
    constant addr_width_rows : positive := positive(ceil(log2(real(size_rows))));

    constant addr_width_iact : positive := positive(ceil(log2(real(line_length_iact))));
    constant addr_width_wght : positive := positive(ceil(log2(real(line_length_wght))));
    constant addr_width_psum : positive := positive(ceil(log2(real(line_length_psum))));

    signal w_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_preload_psum_valid : std_logic;

    signal w_command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_data_iact       : array_t (0 to size_rows - 1)(data_width_input - 1 downto 0);
    signal w_data_iact_array : array_t (0 to size_rows - 1)(data_width_input - 1 downto 0);
    signal w_data_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_wght       : array_t (0 to size_y - 1)(data_width_input - 1 downto 0);

    signal w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_data_psum_valid : std_logic;
    signal w_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal w_buffer_full_iact : std_logic_vector(size_rows - 1 downto 0);
    signal w_buffer_full_psum : std_logic;
    signal w_buffer_full_wght : std_logic_vector(size_y - 1 downto 0);

    signal w_buffer_full_next_iact : std_logic_vector(size_rows - 1 downto 0);
    signal w_buffer_full_next_psum : std_logic;
    signal w_buffer_full_next_wght : std_logic_vector(size_y - 1 downto 0);

    signal w_update_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal w_update_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal w_update_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal w_read_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal w_read_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal w_read_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal w_psums          : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_valid    : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_last     : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_halfword : std_logic_vector(size_x - 1 downto 0);

    signal w_psums_raw       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_raw_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_read_adr   : std_logic_vector(mem_addr_width - 1 downto 0);
    signal w_read_en    : std_logic;
    signal w_pause_iact : std_logic;

    signal w_dout_valid : std_logic;
    signal w_dout       : std_logic_vector(mem_data_width - 1 downto 0);
    signal w_din_psum   : std_logic_vector(mem_data_width - 1 downto 0);

    signal w_write_en_psum           : std_logic_vector(mem_word_count - 1 downto 0);
    signal w_write_adr_psum          : std_logic_vector(mem_addr_width - 1 downto 0);
    signal w_write_suppress_psum     : std_logic;
    signal w_psum_word_offsets       : array_t(0 to size_x - 1)(psum_word_offset_width - 1 downto 0);
    signal w_psum_word_offsets_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_control_init_done    : std_logic;
    signal w_control_init_done_sp : std_logic;

    signal w_enable    : std_logic;
    signal w_enable_if : std_logic;
    signal w_dataflow  : std_logic;

    signal w_params_sp      : parameters_t;
    signal r_params_sp_pipe : parameters_pipe_t(2 downto 0);
    signal r_status_pipe    : status_info_pipe_t(2 downto 0);
    signal w_status_spad_if : status_info_spadif_t;
    signal w_cyclectr       : unsigned(31 downto 0);

    signal w_fifo_iact_address_full : std_logic;
    signal w_fifo_wght_address_full : std_logic;

    signal w_valid_psums_out   : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum_idx_d    : std_logic_vector(addr_width_x - 1 downto 0);
    signal w_all_psum_finished : std_logic;

    signal w_address_iact       : array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
    signal w_address_wght       : array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
    signal w_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_address_wght_valid : std_logic_vector(size_y - 1 downto 0);
    signal w_address_iact_done  : std_logic;
    signal w_address_wght_done  : std_logic;

    attribute async_reg : string;
    attribute async_reg of r_params_sp_pipe : signal is "TRUE";
    attribute async_reg of r_status_pipe    : signal is "TRUE";

begin

    w_dataflow <= '1' when g_dataflow > 0 else '0';

    -- no preload support yet
    w_preload_psum_valid <= '0';
    w_preload_psum       <= (others => '0');

    -- initial psum input unused
    w_data_psum_valid <= '0';
    w_data_psum       <= (others => '0');

    pe_array_inst : entity accel.pe_array
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            data_width_iact  => data_width_input,
            data_width_wght  => data_width_input,
            data_width_psum  => data_width_psum,
            line_length_iact => line_length_iact,
            line_length_wght => line_length_wght,
            line_length_psum => line_length_psum,
            addr_width_iact  => addr_width_iact,
            addr_width_psum  => addr_width_psum,
            addr_width_wght  => addr_width_wght
        )
        port map (
            clk                     => clk,
            rstn                    => rstn,
            i_preload_psum          => w_preload_psum,
            i_preload_psum_valid    => w_preload_psum_valid,
            i_enable                => w_enable,
            i_command               => w_command,
            i_command_iact          => w_command_iact,
            i_command_psum          => w_command_psum,
            i_command_wght          => w_command_wght,
            i_data_iact             => w_data_iact,
            i_data_psum             => w_data_psum,
            i_data_wght             => w_data_wght,
            i_data_iact_valid       => w_data_iact_valid,
            i_data_psum_valid       => w_data_psum_valid,
            i_data_wght_valid       => w_data_wght_valid,
            o_buffer_full_iact      => w_buffer_full_iact,
            o_buffer_full_psum      => w_buffer_full_psum,
            o_buffer_full_wght      => w_buffer_full_wght,
            o_buffer_full_next_iact => w_buffer_full_next_iact,
            o_buffer_full_next_psum => w_buffer_full_next_psum,
            o_buffer_full_next_wght => w_buffer_full_next_wght,
            i_update_offset_iact    => w_update_offset_iact,
            i_update_offset_psum    => w_update_offset_psum,
            i_update_offset_wght    => w_update_offset_wght,
            i_read_offset_iact      => w_read_offset_iact,
            i_read_offset_psum      => w_read_offset_psum,
            i_read_offset_wght      => w_read_offset_wght,
            o_psums                 => w_psums_raw,
            o_psums_valid           => w_psums_raw_valid
        );

    postproc_inst : entity accel.postproc
        generic map (
            size_x          => size_x,
            data_width_iact => data_width_input,
            data_width_psum => data_width_psum,
            postproc_enable => postproc_enable,
            use_float_ip    => use_float_ip
        )
        port map (
            clk             => clk,
            rstn            => rstn,
            i_params        => i_params,
            i_data          => w_psums_raw,
            i_data_valid    => w_psums_raw_valid,
            o_data          => w_psums,
            o_data_valid    => w_psums_valid,
            o_data_last     => w_psums_last,
            o_data_halfword => w_psums_halfword
        );

    control_address_generator_inst : entity accel.control_address_generator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            addr_width_iact_mem => mem_addr_width,
            addr_width_wght_mem => mem_addr_width,
            addr_width_psum_mem => mem_addr_width,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            g_dataflow          => g_dataflow
        )
        port map (
            clk                      => clk,
            rstn                     => rstn,
            i_start                  => i_start,
            i_enable_if              => w_enable_if,
            i_all_psum_finished      => w_all_psum_finished,
            o_init_done              => w_control_init_done,
            o_enable                 => w_enable,
            o_pause_iact             => w_pause_iact,
            o_done                   => o_done,
            o_cyclectr               => w_cyclectr,
            i_params                 => i_params,
            o_command                => w_command,
            o_command_iact           => w_command_iact,
            o_command_psum           => w_command_psum,
            o_command_wght           => w_command_wght,
            o_update_offset_iact     => w_update_offset_iact,
            o_update_offset_psum     => w_update_offset_psum,
            o_update_offset_wght     => w_update_offset_wght,
            o_read_offset_iact       => w_read_offset_iact,
            o_read_offset_psum       => w_read_offset_psum,
            o_read_offset_wght       => w_read_offset_wght,
            i_fifo_iact_address_full => w_fifo_iact_address_full,
            i_fifo_wght_address_full => w_fifo_wght_address_full,
            o_addr_iact_done         => w_address_iact_done,
            o_addr_wght_done         => w_address_wght_done,
            o_address_iact           => w_address_iact,
            o_address_wght           => w_address_wght,
            o_address_iact_valid     => w_address_iact_valid,
            o_address_wght_valid     => w_address_wght_valid
        );

    scratchpad_inst : entity accel.scratchpad
        generic map (
            data_width_input => data_width_input,
            data_width_psum  => data_width_psum,
            word_count       => 8,
            mem_addr_width   => mem_addr_width,
            initialize_mems  => g_init_sp,
            init_files_dir   => g_files_dir
        )
        port map (
            clk  => clk_sp,
            rstn => rstn,
            -- internal access (data load)
            read_adr   => w_read_adr,
            read_en    => w_read_en,
            dout_valid => w_dout_valid,
            dout       => w_dout,
            -- internal access (data store)
            write_adr_psum  => w_write_adr_psum,
            write_en_psum   => w_write_en_psum,
            write_supp_psum => w_write_suppress_psum,
            din_psum        => w_din_psum,
            -- external access
            ext_en       => i_mem_en,
            ext_write_en => i_mem_write_en,
            ext_addr     => i_mem_addr,
            ext_din      => i_mem_din,
            ext_dout     => o_mem_dout
        );

    scratchpad_interface_inst : entity accel.scratchpad_interface
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            addr_width_rows  => addr_width_rows,
            addr_width_y     => addr_width_y,
            addr_width_x     => addr_width_x,
            data_width_input => data_width_input,
            data_width_psum  => data_width_psum,
            mem_addr_width   => mem_addr_width,
            mem_data_width   => mem_data_width,
            mem_word_count   => mem_word_count,
            g_iact_fifo_size => g_iact_fifo_size,
            g_wght_fifo_size => g_wght_fifo_size,
            g_psum_fifo_size => g_psum_fifo_size
        )
        port map (
            clk                       => clk,
            rstn                      => rstn,
            clk_sp                    => clk_sp,
            i_start                   => w_control_init_done,
            i_params                  => i_params,
            o_enable                  => w_enable_if,
            o_status                  => w_status_spad_if,
            i_address_iact            => w_address_iact,
            i_address_wght            => w_address_wght,
            i_address_iact_valid      => w_address_iact_valid,
            i_address_wght_valid      => w_address_wght_valid,
            i_psum_word_offsets       => w_psum_word_offsets,
            i_psum_word_offsets_valid => w_psum_word_offsets_valid,
            o_fifo_iact_address_full  => w_fifo_iact_address_full,
            o_fifo_wght_address_full  => w_fifo_wght_address_full,
            i_addr_iact_done          => w_address_iact_done,
            i_addr_wght_done          => w_address_wght_done,
            o_valid_psums_out         => w_valid_psums_out,
            o_gnt_psum_idx_d          => w_gnt_psum_idx_d,
            o_all_psum_finished       => w_all_psum_finished,
            o_address                 => w_read_adr,
            o_address_valid           => w_read_en,
            o_write_en_psum           => w_write_en_psum,
            o_data_psum               => w_din_psum,
            i_data                    => w_dout,
            i_data_valid              => w_dout_valid,
            o_data_iact               => w_data_iact,
            o_data_wght               => w_data_wght,
            o_data_iact_valid         => w_data_iact_valid,
            o_data_wght_valid         => w_data_wght_valid,
            i_buffer_full_iact        => w_buffer_full_iact,
            i_buffer_full_next_iact   => w_buffer_full_next_iact,
            i_buffer_full_wght        => w_buffer_full_wght,
            i_buffer_full_next_wght   => w_buffer_full_next_wght,
            i_psums                   => w_psums,
            i_psums_valid             => w_psums_valid,
            i_psums_last              => w_psums_last,
            i_psums_halfword          => w_psums_halfword,
            i_pause_iact              => w_pause_iact
        );

    sync_init_done : entity accel.bit_sync
        port map (
            clk     => clk_sp,
            rst     => '0',
            bit_in  => w_control_init_done,
            bit_out => w_control_init_done_sp
        );

    address_generator_psum_inst : entity accel.address_generator_psum
        generic map (
            size_x         => size_x,
            size_y         => size_y,
            addr_width_x   => addr_width_x,
            mem_addr_width => mem_addr_width,
            mem_columns    => mem_word_count,
            write_size     => mem_word_count
        )
        port map (
            clk                 => clk_sp,
            rstn                => rstn,
            i_start             => w_control_init_done_sp,
            i_dataflow          => w_dataflow,
            i_params            => w_params_sp,
            i_valid_psum_out    => w_valid_psums_out,
            i_gnt_psum_idx_d    => w_gnt_psum_idx_d,
            o_address_psum      => w_write_adr_psum,
            o_suppress_out      => w_write_suppress_psum,
            o_word_offsets      => w_psum_word_offsets,
            o_word_offset_valid => w_psum_word_offsets_valid
        );

    -- construct the o_status record
    r_status_pipe(0).spadif        <= w_status_spad_if;
    r_status_pipe(0).cycle_counter <= w_cyclectr;

    -- add a pipeline to relax timing on the status record signals
    r_status_pipe(r_status_pipe'high downto 1) <= r_status_pipe(r_status_pipe'high - 1 downto 0) when rising_edge(clk);
    o_status                                   <= r_status_pipe(r_status_pipe'high);

    r_params_sp_pipe(0)                              <= i_params when rising_edge(clk_sp);
    r_params_sp_pipe(r_params_sp_pipe'high downto 1) <= r_params_sp_pipe(r_params_sp_pipe'high - 1 downto 0) when rising_edge(clk_sp);
    w_params_sp                                      <= r_params_sp_pipe(r_params_sp_pipe'high);

    assert g_dataflow = 0 or max_output_channels >= size_y
        report "Dataflow 1 requires max_output_channels to be at least size_y"
        severity failure;

end architecture rtl;

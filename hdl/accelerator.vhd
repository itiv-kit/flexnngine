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

        -- iact word size, pe line buffer length & matching offset addressing width
        data_width_iact  : positive := 8;
        line_length_iact : positive := 512;
        addr_width_iact  : positive := 9;

        -- psum word size, pe line buffer length & matching offset addressing width
        data_width_psum  : positive := 16;
        line_length_psum : positive := 1024;
        addr_width_psum  : positive := 10;

        -- wght word size, pe line buffer length & matching offset addressing width
        data_width_wght  : positive := 8;
        line_length_wght : positive := 512;
        addr_width_wght  : positive := 9;

        -- address widths scratchpad <-> pe array
        spad_addr_width_iact : positive := 15; -- word size data_width_iact
        spad_addr_width_wght : positive := 15; -- word size data_width_wght
        spad_addr_width_psum : positive := 15; -- word size data_width_psum

        -- address widths scratchpad <-> external, port_a is exposed as i/o on this module
        spad_ext_addr_width_iact : positive := 13; -- word size spad_ext_data_width_iact
        spad_ext_addr_width_wght : positive := 13; -- word size spad_ext_data_width_wght
        spad_ext_addr_width_psum : positive := 14; -- word size spad_ext_data_width_psum
        spad_ext_data_width_iact : positive := 32;
        spad_ext_data_width_wght : positive := 32;
        spad_ext_data_width_psum : positive := 32;

        fifo_width : positive := 16;

        g_iact_fifo_size : positive := 15;
        g_wght_fifo_size : positive := 15;
        g_psum_fifo_size : positive := 45;

        g_files_dir : string  := "";
        g_init_sp   : boolean := false;
        g_dataflow  : integer := 1
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        i_start  : in    std_logic;
        o_done   : out   std_logic;
        i_params : in    parameters_t;
        o_status : out   status_info_t;

        i_en_iact : in    std_logic;
        i_en_wght : in    std_logic;
        i_en_psum : in    std_logic;

        i_write_en_iact : in    std_logic_vector(spad_ext_data_width_iact / 8 - 1 downto 0);
        i_write_en_wght : in    std_logic_vector(spad_ext_data_width_wght / 8 - 1 downto 0);
        i_write_en_psum : in    std_logic_vector(spad_ext_data_width_psum / 8 - 1 downto 0);

        i_addr_iact : in    std_logic_vector(spad_ext_addr_width_iact - 1 downto 0);
        i_addr_wght : in    std_logic_vector(spad_ext_addr_width_wght - 1 downto 0);
        i_addr_psum : in    std_logic_vector(spad_ext_addr_width_psum - 1 downto 0);

        i_din_iact : in    std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
        i_din_wght : in    std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
        i_din_psum : in    std_logic_vector(spad_ext_data_width_psum - 1 downto 0);

        o_dout_iact : out   std_logic_vector(spad_ext_data_width_iact - 1 downto 0);
        o_dout_wght : out   std_logic_vector(spad_ext_data_width_wght - 1 downto 0);
        o_dout_psum : out   std_logic_vector(spad_ext_data_width_psum - 1 downto 0)
    );
end entity accelerator;

architecture rtl of accelerator is

    constant size_rows : positive := size_x + size_y - 1;

    constant addr_width_x    : positive := positive(ceil(log2(real(size_x))));
    constant addr_width_y    : positive := positive(ceil(log2(real(size_y))));
    constant addr_width_rows : positive := positive(ceil(log2(real(size_rows))));

    signal w_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_preload_psum_valid : std_logic;

    signal w_command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_data_iact       : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal w_data_iact_array : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal w_data_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_wght       : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

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

    signal w_psums       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_read_adr_iact  : std_logic_vector(spad_addr_width_iact - 1 downto 0);
    signal w_read_adr_wght  : std_logic_vector(spad_addr_width_wght - 1 downto 0);
    signal w_write_adr_psum : std_logic_vector(spad_addr_width_psum - 1 downto 0);

    signal w_dout_iact : std_logic_vector(data_width_iact - 1 downto 0);
    signal w_dout_wght : std_logic_vector(data_width_wght - 1 downto 0);
    signal w_din_psum  : std_logic_vector(data_width_psum - 1 downto 0);

    signal w_write_en_psum       : std_logic;
    signal w_write_suppress_psum : std_logic;

    signal w_read_en_iact : std_logic;
    signal w_read_en_wght : std_logic;

    signal w_pause_iact : std_logic;

    signal w_control_init_done : std_logic;

    signal w_enable    : std_logic;
    signal w_enable_if : std_logic;
    signal w_dataflow  : std_logic;

    signal w_params_sp : parameters_t;
    attribute async_reg : string;
    attribute async_reg of w_params_sp : signal is "TRUE";

    signal r_status_pipe    : status_info_pipe_t(2 downto 0);
    signal w_status_spad_if : status_info_t;

    signal w_dout_iact_valid : std_logic;
    signal w_dout_wght_valid : std_logic;

    signal w_fifo_iact_address_full : std_logic;
    signal w_fifo_wght_address_full : std_logic;

    signal w_valid_psums_out   : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum_binary_d : std_logic_vector(addr_width_x - 1 downto 0);
    signal w_empty_psum_fifo   : std_logic_vector(size_x - 1 downto 0);
    signal w_all_psum_finished : std_logic;

    signal w_address_iact       : array_t(0 to size_rows - 1)(spad_addr_width_iact - 1 downto 0);
    signal w_address_wght       : array_t(0 to size_y - 1)(spad_addr_width_wght - 1 downto 0);
    signal w_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_address_wght_valid : std_logic_vector(size_y - 1 downto 0);

begin

    w_dataflow <= '1' when g_dataflow > 0 else '0';

    pe_array_inst : entity accel.pe_array
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            data_width_iact  => data_width_iact,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            data_width_psum  => data_width_psum,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            data_width_wght  => data_width_wght,
            line_length_wght => line_length_wght,
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
            o_psums                 => w_psums,
            o_psums_valid           => w_psums_valid
        );

    control_address_generator_inst : entity accel.control_address_generator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            addr_width_iact_mem => spad_addr_width_iact,
            addr_width_wght_mem => spad_addr_width_wght,
            addr_width_psum_mem => spad_addr_width_psum,
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
            w_fifo_iact_address_full => w_fifo_iact_address_full,
            w_fifo_wght_address_full => w_fifo_wght_address_full,
            o_address_iact           => w_address_iact,
            o_address_wght           => w_address_wght,
            o_address_iact_valid     => w_address_iact_valid,
            o_address_wght_valid     => w_address_wght_valid
        );

    scratchpad_inst : entity accel.scratchpad
        generic map (
            ext_data_width_iact => spad_ext_data_width_iact,
            ext_addr_width_iact => spad_ext_addr_width_iact,
            ext_data_width_psum => spad_ext_data_width_psum,
            ext_addr_width_psum => spad_ext_addr_width_psum,
            ext_data_width_wght => spad_ext_data_width_wght,
            ext_addr_width_wght => spad_ext_addr_width_wght,
            data_width_iact     => data_width_iact,
            addr_width_iact     => spad_addr_width_iact,
            data_width_psum     => data_width_psum,
            addr_width_psum     => spad_addr_width_psum,
            data_width_wght     => data_width_wght,
            addr_width_wght     => spad_addr_width_wght,
            initialize_mems     => g_init_sp,
            g_files_dir         => g_files_dir
        )
        port map (
            clk  => clk_sp,
            rstn => rstn,
            -- internal access
            read_adr_iact   => w_read_adr_iact,
            read_adr_wght   => w_read_adr_wght,
            write_adr_psum  => w_write_adr_psum,
            read_en_iact    => w_read_en_iact,
            read_en_wght    => w_read_en_wght,
            write_en_psum   => w_write_en_psum and not w_write_suppress_psum,
            dout_iact_valid => w_dout_iact_valid,
            dout_wght_valid => w_dout_wght_valid,
            dout_iact       => w_dout_iact,
            dout_wght       => w_dout_wght,
            din_psum        => w_din_psum,
            -- external access
            ext_en_iact       => i_en_iact,
            ext_en_wght       => i_en_wght,
            ext_en_psum       => i_en_psum,
            ext_write_en_iact => i_write_en_iact,
            ext_write_en_wght => i_write_en_wght,
            ext_write_en_psum => i_write_en_psum,
            ext_addr_iact     => i_addr_iact,
            ext_addr_wght     => i_addr_wght,
            ext_addr_psum     => i_addr_psum,
            ext_din_iact      => i_din_iact,
            ext_din_wght      => i_din_wght,
            ext_din_psum      => i_din_psum,
            ext_dout_iact     => o_dout_iact,
            ext_dout_wght     => o_dout_wght,
            ext_dout_psum     => o_dout_psum
        );

    scratchpad_interface_inst : entity accel.scratchpad_interface
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            data_width_iact     => data_width_iact,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => spad_addr_width_iact,
            data_width_psum     => data_width_psum,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => spad_addr_width_psum,
            data_width_wght     => data_width_wght,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => spad_addr_width_wght,
            fifo_width          => fifo_width,
            g_iact_fifo_size    => g_iact_fifo_size,
            g_wght_fifo_size    => g_wght_fifo_size,
            g_psum_fifo_size    => g_psum_fifo_size
        )
        port map (
            clk                      => clk,
            rstn                     => rstn,
            clk_sp                   => clk_sp,
            i_start                  => w_control_init_done,
            o_enable                 => w_enable_if,
            o_status                 => w_status_spad_if,
            i_address_iact           => w_address_iact,
            i_address_wght           => w_address_wght,
            i_address_iact_valid     => w_address_iact_valid,
            i_address_wght_valid     => w_address_wght_valid,
            o_fifo_iact_address_full => w_fifo_iact_address_full,
            o_fifo_wght_address_full => w_fifo_wght_address_full,
            o_valid_psums_out        => w_valid_psums_out,
            o_gnt_psum_binary_d      => w_gnt_psum_binary_d,
            o_empty_psum_fifo        => w_empty_psum_fifo,
            o_all_psum_finished      => w_all_psum_finished,
            o_address_iact           => w_read_adr_iact,
            o_address_wght           => w_read_adr_wght,
            o_address_iact_valid     => w_read_en_iact,
            o_address_wght_valid     => w_read_en_wght,
            o_write_en_psum          => w_write_en_psum,
            o_data_psum              => w_din_psum,
            i_data_iact              => w_dout_iact,
            i_data_wght              => w_dout_wght,
            i_data_iact_valid        => w_dout_iact_valid,
            i_data_wght_valid        => w_dout_wght_valid,
            o_data_iact              => w_data_iact,
            o_data_wght              => w_data_wght,
            o_data_iact_valid        => w_data_iact_valid,
            o_data_wght_valid        => w_data_wght_valid,
            i_buffer_full_iact       => w_buffer_full_next_iact,
            i_buffer_full_wght       => w_buffer_full_next_wght,
            i_psums                  => w_psums,
            i_psums_valid            => w_psums_valid,
            i_pause_iact             => w_pause_iact
        );

    w_params_sp <= i_params when rising_edge(clk_sp);

    address_generator_psum_inst : entity accel.address_generator_psum
        generic map (
            size_x          => size_x,
            size_y          => size_y,
            addr_width_x    => addr_width_x,
            addr_width_psum => spad_addr_width_psum
        )
        port map (
            clk                 => clk_sp,
            rstn                => rstn,
            i_start             => w_control_init_done,
            i_dataflow          => w_dataflow,
            i_params            => i_params,
            i_valid_psum_out    => w_valid_psums_out,
            i_gnt_psum_binary_d => w_gnt_psum_binary_d,
            i_empty_psum_fifo   => w_empty_psum_fifo,
            o_address_psum      => w_write_adr_psum,
            o_suppress_out      => w_write_suppress_psum
        );

    -- construct the o_status record, currently consists of scratchpad interface signals only
    r_status_pipe(0) <= w_status_spad_if;

    -- add a pipeline to relax timing on the status record signals
    r_status_pipe(r_status_pipe'high downto 1) <= r_status_pipe(r_status_pipe'high - 1 downto 0) when rising_edge(clk);
    o_status                                   <= r_status_pipe(r_status_pipe'high);

end architecture rtl;

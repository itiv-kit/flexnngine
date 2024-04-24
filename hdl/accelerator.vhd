library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity accelerator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 512;
        addr_width_iact     : positive := 9;
        addr_width_iact_mem : positive := 15;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 1024;
        addr_width_psum     : positive := 10;
        addr_width_psum_mem : positive := 15;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 512;
        addr_width_wght     : positive := 9;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_iact_fifo_size : positive := 15;
        g_wght_fifo_size : positive := 15;
        g_psum_fifo_size : positive := 45;

        g_channels    : positive := 28;
        g_kernels     : positive := 10;
        g_image_y     : positive := 14;
        g_image_x     : positive := 14;
        g_kernel_size : positive := 5;

        g_files_dir : string  := "";
        g_init_sp   : boolean := false;

        g_control_init : boolean  := false;
        g_c1           : positive := 1;
        g_w1           : positive := 1;
        g_h2           : positive := 1;
        g_m0           : positive := 1;
        g_m0_last_m1   : positive := 1;
        g_rows_last_h2 : positive := 1;
        g_c0           : positive := 1;
        g_c0_last_c1   : positive := 1;
        g_c0w0         : positive := 1;
        g_c0w0_last_c1 : positive := 1;
        g_dataflow     : integer  := 1
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        i_start : in    std_logic;
        o_done  : out   std_logic;

        o_dout_psum       : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_dout_psum_valid : out   std_logic;

        i_write_en_iact : in    std_logic;
        i_write_en_wght : in    std_logic;

        i_din_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        i_din_wght : in    std_logic_vector(data_width_wght - 1 downto 0)
    );
end entity accelerator;

architecture rtl of accelerator is

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

    signal w_write_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal w_write_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal w_write_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    signal w_read_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal w_read_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal w_read_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    signal w_dout_iact : std_logic_vector(data_width_iact - 1 downto 0);
    signal w_dout_wght : std_logic_vector(data_width_wght - 1 downto 0);
    signal w_din_psum  : std_logic_vector(data_width_psum - 1 downto 0);

    signal w_write_en_psum       : std_logic;
    signal w_write_suppress_psum : std_logic;

    signal w_read_en_iact : std_logic;
    signal w_read_en_psum : std_logic;
    signal w_read_en_wght : std_logic;

    signal w_pause_iact : std_logic;

    signal w_control_init_done : std_logic;

    signal w_enable    : std_logic;
    signal w_enable_if : std_logic;

    signal w_dataflow : std_logic;

    signal w_w1 : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal w_m0 : integer range 0 to 1023;

    signal r_image_x     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal r_image_y     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal r_channels    : integer range 0 to 4095; /* TODO change range to sth. useful */
    signal r_kernels     : integer range 0 to 4095; /* TODO change range to sth. useful */
    signal r_kernel_size : integer range 0 to 32;   /* TODO change range to sth. useful */

    signal w_dout_iact_valid : std_logic;
    signal w_dout_wght_valid : std_logic;

    signal w_fifo_iact_address_full : std_logic;
    signal w_fifo_wght_address_full : std_logic;

    signal w_valid_psums_out   : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum_binary_d : std_logic_vector(addr_width_x - 1 downto 0);
    signal w_empty_psum_fifo   : std_logic_vector(size_x - 1 downto 0);

    signal w_address_iact       : array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal w_address_wght       : array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
    signal w_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_address_wght_valid : std_logic_vector(size_y - 1 downto 0);

begin

    w_dataflow <= '1' when g_dataflow > 0 else '0';

    /* TODO Debug */
    w_write_adr_iact <= (others => '0');
    w_write_adr_wght <= (others => '0');
    w_read_adr_psum  <= (others => '0');

    start_procedure : process (clk, rstn) is
    begin

        if not rstn then
            r_image_x     <= 0;
            r_image_y     <= 0;
            r_channels    <= 0;
            r_kernels     <= 0;
            r_kernel_size <= 0;
        elsif rising_edge(clk) then
            r_image_x     <= g_image_x;
            r_image_y     <= g_image_y;
            r_channels    <= g_channels;
            r_kernels     <= g_kernels;
            r_kernel_size <= g_kernel_size;
        end if;

    end process start_procedure;

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
            addr_width_iact_mem => addr_width_iact_mem,
            addr_width_wght_mem => addr_width_wght_mem,
            addr_width_psum_mem => addr_width_psum_mem,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            g_control_init      => g_control_init,
            g_c1                => g_c1,
            g_w1                => g_w1,
            g_h2                => g_h2,
            g_m0                => g_m0,
            g_m0_last_m1        => g_m0_last_m1,
            g_rows_last_h2      => g_rows_last_h2,
            g_c0                => g_c0,
            g_c0_last_c1        => g_c0_last_c1,
            g_c0w0              => g_c0w0,
            g_c0w0_last_c1      => g_c0w0_last_c1,
            g_dataflow          => g_dataflow
        )
        port map (
            clk                      => clk,
            rstn                     => rstn,
            i_start                  => i_start,
            i_enable_if              => w_enable_if,
            o_init_done              => w_control_init_done,
            o_enable                 => w_enable,
            o_pause_iact             => w_pause_iact,
            o_done                   => o_done,
            o_w1                     => w_w1,
            o_m0                     => w_m0,
            i_image_x                => r_image_x,
            i_image_y                => r_image_y,
            i_channels               => r_channels,
            i_kernels                => r_kernels,
            i_kernel_size            => r_kernel_size,
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
            data_width_iact => data_width_iact,
            addr_width_iact => addr_width_iact_mem,
            data_width_psum => data_width_psum,
            addr_width_psum => addr_width_psum_mem,
            data_width_wght => data_width_wght,
            addr_width_wght => addr_width_wght_mem,
            initialize_mems => g_init_sp,
            g_files_dir     => g_files_dir
        )
        port map (
            clk             => clk_sp,
            rstn            => rstn,
            write_adr_iact  => w_write_adr_iact,
            write_adr_psum  => w_write_adr_psum,
            write_adr_wght  => w_write_adr_wght,
            read_adr_iact   => w_read_adr_iact,
            read_adr_psum   => w_read_adr_psum,
            read_adr_wght   => w_read_adr_wght,
            write_en_iact   => i_write_en_iact,
            write_en_psum   => w_write_en_psum and not w_write_suppress_psum,
            write_en_wght   => i_write_en_wght,
            read_en_iact    => w_read_en_iact,
            read_en_psum    => w_read_en_psum,
            read_en_wght    => w_read_en_wght,
            din_iact        => i_din_iact,
            din_psum        => w_din_psum,
            din_wght        => i_din_wght,
            dout_iact       => w_dout_iact,
            dout_psum       => o_dout_psum,
            dout_wght       => w_dout_wght,
            dout_iact_valid => w_dout_iact_valid,
            dout_psum_valid => o_dout_psum_valid,
            dout_wght_valid => w_dout_wght_valid
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
            addr_width_iact_mem => addr_width_iact_mem,
            data_width_psum     => data_width_psum,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            data_width_wght     => data_width_wght,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem,
            fifo_width          => fifo_width,
            g_iact_fifo_size    => g_iact_fifo_size,
            g_wght_fifo_size    => g_wght_fifo_size,
            g_psum_fifo_size    => g_psum_fifo_size,
            g_channels          => g_channels,
            g_image_y           => g_image_y,
            g_image_x           => g_image_x,
            g_kernel_size       => g_kernel_size
        )
        port map (
            clk                      => clk,
            rstn                     => rstn,
            clk_sp                   => clk_sp,
            i_start                  => w_control_init_done,
            o_enable                 => w_enable_if,
            i_address_iact           => w_address_iact,
            i_address_wght           => w_address_wght,
            i_address_iact_valid     => w_address_iact_valid,
            i_address_wght_valid     => w_address_wght_valid,
            o_fifo_iact_address_full => w_fifo_iact_address_full,
            o_fifo_wght_address_full => w_fifo_wght_address_full,
            o_valid_psums_out        => w_valid_psums_out,
            o_gnt_psum_binary_d      => w_gnt_psum_binary_d,
            o_empty_psum_fifo        => w_empty_psum_fifo,
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

    address_generator_psum_inst : entity accel.address_generator_psum
        generic map (
            size_x          => size_x,
            size_y          => size_y,
            addr_width_x    => addr_width_x,
            addr_width_psum => addr_width_psum_mem
        )
        port map (
            clk                 => clk_sp,
            rstn                => rstn,
            i_start             => w_control_init_done,
            i_dataflow          => w_dataflow,
            i_w1                => w_w1,
            i_m0                => w_m0,
            i_kernel_size       => g_kernel_size,
            i_valid_psum_out    => w_valid_psums_out,
            i_gnt_psum_binary_d => w_gnt_psum_binary_d,
            i_empty_psum_fifo   => w_empty_psum_fifo,
            o_address_psum      => w_write_adr_psum,
            o_suppress_out      => w_write_suppress_psum
        );

end architecture rtl;

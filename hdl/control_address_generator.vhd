library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity control_address_generator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        addr_width_iact_mem : positive := 15;
        addr_width_wght_mem : positive := 15;
        addr_width_psum_mem : positive := 15;

        line_length_iact : positive := 64;
        addr_width_iact  : positive := 6;
        line_length_psum : positive := 128;
        addr_width_psum  : positive := 7;
        line_length_wght : positive := 64;
        addr_width_wght  : positive := 6;

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
        g_c0w0_last_c1 : positive := 1
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start      : in    std_logic;
        i_start_init : in    std_logic;
        i_start_adr  : in    std_logic;
        i_enable_if  : in    std_logic;

        o_status     : out   std_logic;
        o_enable     : out   std_logic;
        o_new_output : out   std_logic;
        o_pause_iact : out   std_logic;

        o_w1         : out   integer range 0 to 1023;
        o_m0         : out   integer range 0 to 1023;

        i_image_x : in    integer range 0 to 1023; --! size of input image
        i_image_y : in    integer range 0 to 1023; --! size of input image

        i_channels : in    integer range 0 to 4095; -- Number of input channels the image and kernels have
        i_kernels  : in    integer range 0 to 4095; -- Number of kernels / output channels

        i_kernel_size : in    integer range 0 to 32;

        o_command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

        o_update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        o_update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        o_update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        o_read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        o_read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        w_fifo_iact_address_full : in  std_logic;
        w_fifo_wght_address_full : in  std_logic;

        o_address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        o_address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
    );
end entity control_address_generator;

architecture rs_dataflow of control_address_generator is

    component control is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_rows : positive;
            addr_width_y    : positive;
            addr_width_x    : positive;

            line_length_iact : positive := 512;
            addr_width_iact  : positive := 9;
            line_length_psum : positive := 512;
            addr_width_psum  : positive := 9;
            line_length_wght : positive := 512;
            addr_width_wght  : positive := 9;

            g_control_init : boolean  := true;
            g_c1           : positive := 1;
            g_w1           : positive := 1;
            g_h2           : positive := 1;
            g_m0           : positive := 1;
            g_m0_last_m1   : positive := 1;
            g_rows_last_h2 : positive := 1;
            g_c0           : positive := 1;
            g_c0_last_c1   : positive := 1;
            g_c0w0         : positive := 1;
            g_c0w0_last_c1 : positive := 1
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_start      : in    std_logic;
            i_start_init : in    std_logic;

            o_enable     : out   std_logic;
            o_new_output : out   std_logic;
            o_status     : out   std_logic;
            o_pause_iact : out   std_logic;

            o_c1      : out   integer range 0 to 1023;
            o_w1      : out   integer range 0 to 1023;
            o_h2      : out   integer range 0 to 1023;
            o_m0      : out   integer range 0 to 1023;
            o_m0_dist : out   array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
            o_m0_last_m1 : out   integer range 0 to 1023;

            o_c0         : out   integer range 0 to 1023;
            o_c0_last_c1 : out   integer range 0 to 1023;

            i_image_x : in    integer range 0 to 1023;
            i_image_y : in    integer range 0 to 1023;

            i_channels : in    integer range 0 to 4095;
            i_kernels  : in    integer range 0 to 4095;

            i_kernel_size : in    integer range 0 to 32;

            o_command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

            o_update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            o_read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
        );
    end component control;

    for all : control use entity work.control (rs_dataflow ) ;

    component address_generator is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_rows : positive;
            addr_width_y    : positive;
            addr_width_x    : positive;

            line_length_iact    : positive := 512;
            addr_width_iact     : positive := 9;
            addr_width_iact_mem : positive := 15;

            line_length_psum    : positive := 512;
            addr_width_psum     : positive := 9;
            addr_width_psum_mem : positive := 15;

            line_length_wght    : positive := 512;
            addr_width_wght     : positive := 9;
            addr_width_wght_mem : positive := 15
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_start : in    std_logic;
            i_pause_iact : in    std_logic;


            i_c1      : in    integer range 0 to 1023;
            i_w1      : in    integer range 0 to 1023;
            i_h2      : in    integer range 0 to 1023;
            i_m0      : in    integer range 0 to 1023;
            i_m0_dist : in    array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
            i_m0_last_m1 : in    integer range 0 to 1023;

            i_c0         : in    integer range 0 to 1023;
            i_c0_last_c1 : in    integer range 0 to 1023;

            i_image_x     : in    integer range 0 to 1023;
            i_image_y     : in    integer range 0 to 1023;
            i_channels    : in    integer range 0 to 4095;
            i_kernel_size : in    integer range 0 to 32;

            i_fifo_full_iact : in    std_logic;
            i_fifo_full_wght : in    std_logic;

            o_address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            o_address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
            o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
        );
    end component address_generator;
    
    for all : address_generator use entity work.address_generator (rs_dataflow ) ;


    signal w_c1 : integer range 0 to 1023;
    signal w_w1 : integer range 0 to 1023;
    signal w_h2 : integer range 0 to 1023;
    signal w_m0 : integer range 0 to 1023;
    signal w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal w_m0_last_m1 : integer range 0 to 1023;
    signal w_c0 : integer range 0 to 1023;
    signal w_c0_last_c1 : integer range 0 to 1023;

begin

    o_pause_iact <= '0';

    o_w1  <= w_w1;
    o_m0  <= w_m0;

    control_inst : component control
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            addr_width_rows  => addr_width_rows,
            addr_width_y     => addr_width_y,
            addr_width_x     => addr_width_x,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght,
            g_control_init => g_control_init,
            g_c1 => g_c1,
            g_w1 => g_w1,
            g_h2 => g_h2,
            g_m0 => g_m0,
            g_m0_last_m1     => g_m0_last_m1,
            g_rows_last_h2 => g_rows_last_h2,
            g_c0 => g_c0,
            g_c0_last_c1 => g_c0_last_c1,
            g_c0w0 => g_c0w0,
            g_c0w0_last_c1 => g_c0w0_last_c1
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            o_status             => o_status,
            i_start              => i_enable_if,
            i_start_init         => i_start_init,
            o_enable             => o_enable,
            o_new_output         => o_new_output,
            o_c1                 => w_c1,
            o_w1                 => w_w1,
            o_h2                 => w_h2,
            o_m0                 => w_m0,
            o_m0_dist            => w_m0_dist,
            o_m0_last_m1         => w_m0_last_m1,
            o_c0                 => w_c0,
            o_c0_last_c1         => w_c0_last_c1,
            i_image_x            => i_image_x,
            i_image_y            => i_image_y,
            i_channels           => i_channels,
            i_kernels            => i_kernels,
            i_kernel_size        => i_kernel_size,
            o_command            => o_command,
            o_command_iact       => o_command_iact,
            o_command_psum       => o_command_psum,
            o_command_wght       => o_command_wght,
            o_update_offset_iact => o_update_offset_iact,
            o_update_offset_psum => o_update_offset_psum,
            o_update_offset_wght => o_update_offset_wght,
            o_read_offset_iact   => o_read_offset_iact,
            o_read_offset_psum   => o_read_offset_psum,
            o_read_offset_wght   => o_read_offset_wght
        );

    address_generator_inst : component address_generator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => i_start_adr,
            i_pause_iact         => '0',
            i_c1                 => w_c1,
            i_w1                 => w_w1,
            i_h2                 => w_h2,
            i_m0                 => w_m0,
            i_m0_dist            => w_m0_dist,
            i_m0_last_m1         => w_m0_last_m1,
            i_c0                 => w_c0,
            i_c0_last_c1         => w_c0_last_c1,
            i_image_x            => i_image_x,
            i_image_y            => i_image_y,
            i_channels           => i_channels,
            i_kernel_size        => i_kernel_size,
            i_fifo_full_iact     => w_fifo_iact_address_full,
            i_fifo_full_wght     => w_fifo_wght_address_full,
            o_address_iact       => o_address_iact,
            o_address_wght       => o_address_wght,
            o_address_iact_valid => o_address_iact_valid,
            o_address_wght_valid => o_address_wght_valid
        );
end architecture rs_dataflow;

architecture alternative_rs_dataflow of control_address_generator is

    component control is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_rows : positive;
            addr_width_y    : positive;
            addr_width_x    : positive;

            line_length_iact : positive := 512;
            addr_width_iact  : positive := 9;
            line_length_psum : positive := 512;
            addr_width_psum  : positive := 9;
            line_length_wght : positive := 512;
            addr_width_wght  : positive := 9;

            g_control_init : boolean := false;
            g_c1           : positive := 1;
            g_w1           : positive := 1;
            g_h2           : positive := 1;
            g_m0           : positive := 1;
            g_m0_last_m1   : positive := 1;
            g_rows_last_h2 : positive := 1;
            g_c0           : positive := 1;
            g_c0_last_c1   : positive := 1;
            g_c0w0         : positive := 1;
            g_c0w0_last_c1 : positive := 1
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            o_status     : out   std_logic;
            i_start      : in    std_logic;
            i_start_init : in    std_logic;
            o_enable     : out   std_logic;
            o_new_output : out   std_logic;
            o_pause_iact : out   std_logic;

            o_c1         : out   integer range 0 to 1023;
            o_w1         : out   integer range 0 to 1023;
            o_h2         : out   integer range 0 to 1023;
            o_m0         : out   integer range 0 to 1023;
            o_m0_dist : out   array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
            o_m0_last_m1 : out   integer range 0 to 1023;

            o_c0         : out   integer range 0 to 1023;
            o_c0_last_c1 : out   integer range 0 to 1023;

            i_image_x : in    integer range 0 to 1023;
            i_image_y : in    integer range 0 to 1023;

            i_channels : in    integer range 0 to 4095;
            i_kernels  : in    integer range 0 to 4095;

            i_kernel_size : in    integer range 0 to 32;

            o_command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

            o_update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            o_read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
        );
    end component control;

    for all : control use entity work.control (alternative_rs_dataflow ) ;

    component address_generator is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_rows : positive;
            addr_width_y    : positive;
            addr_width_x    : positive;

            line_length_iact    : positive := 512;
            addr_width_iact     : positive := 9;
            addr_width_iact_mem : positive := 15;

            line_length_psum    : positive := 512;
            addr_width_psum     : positive := 9;
            addr_width_psum_mem : positive := 15;

            line_length_wght    : positive := 512;
            addr_width_wght     : positive := 9;
            addr_width_wght_mem : positive := 15
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_start      : in    std_logic;
            i_pause_iact : in    std_logic;

            i_c1         : in    integer range 0 to 1023;
            i_w1         : in    integer range 0 to 1023;
            i_h2         : in    integer range 0 to 1023;
            i_m0         : in    integer range 0 to 1023;
            i_m0_dist : in    array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
            i_m0_last_m1 : in    integer range 0 to 1023;

            i_c0         : in    integer range 0 to 1023;
            i_c0_last_c1 : in    integer range 0 to 1023;

            i_image_x     : in    integer range 0 to 1023;
            i_image_y     : in    integer range 0 to 1023;
            i_channels    : in    integer range 0 to 4095;
            i_kernel_size : in    integer range 0 to 32;

            i_fifo_full_iact : in    std_logic;
            i_fifo_full_wght : in    std_logic;

            o_address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            o_address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
            o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
        );
    end component address_generator;

    for all : address_generator use entity work.address_generator (alternative_rs_dataflow ) ;


    signal w_c1 : integer range 0 to 1023;
    signal w_w1 : integer range 0 to 1023;
    signal w_h2 : integer range 0 to 1023;
    signal w_m0 : integer range 0 to 1023;
    signal w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal w_m0_last_m1 : integer range 0 to 1023;
    signal w_c0 : integer range 0 to 1023;
    signal w_c0_last_c1 : integer range 0 to 1023;

begin

    o_w1  <= w_w1;
    o_m0  <= w_m0;

    control_inst : component control
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            addr_width_rows  => addr_width_rows,
            addr_width_y     => addr_width_y,
            addr_width_x     => addr_width_x,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght,
            g_control_init   => g_control_init,
            g_c1             => g_c1,
            g_w1             => g_w1,
            g_h2             => g_h2,
            g_m0             => g_m0,
            g_m0_last_m1     => g_m0_last_m1,
            g_rows_last_h2   => g_rows_last_h2,
            g_c0             => g_c0,
            g_c0_last_c1     => g_c0_last_c1,
            g_c0w0           => g_c0w0,
            g_c0w0_last_c1   => g_c0w0_last_c1
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            o_status             => o_status,
            i_start              => i_enable_if,
            i_start_init         => i_start_init,
            o_enable             => o_enable,
            o_new_output         => o_new_output,
            o_pause_iact         => o_pause_iact,
            o_c1                 => w_c1,
            o_w1                 => w_w1,
            o_h2                 => w_h2,
            o_m0                 => w_m0,
            o_m0_dist            => w_m0_dist,
            o_m0_last_m1         => w_m0_last_m1,
            o_c0                 => w_c0,
            o_c0_last_c1         => w_c0_last_c1,
            i_image_x            => i_image_x,
            i_image_y            => i_image_y,
            i_channels           => i_channels,
            i_kernels            => i_kernels,
            i_kernel_size        => i_kernel_size,
            o_command            => o_command,
            o_command_iact       => o_command_iact,
            o_command_psum       => o_command_psum,
            o_command_wght       => o_command_wght,
            o_update_offset_iact => o_update_offset_iact,
            o_update_offset_psum => o_update_offset_psum,
            o_update_offset_wght => o_update_offset_wght,
            o_read_offset_iact   => o_read_offset_iact,
            o_read_offset_psum   => o_read_offset_psum,
            o_read_offset_wght   => o_read_offset_wght
        );

    address_generator_inst : component address_generator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => i_start_adr,
            i_pause_iact         => '0',
            i_c1                 => w_c1,
            i_w1                 => w_w1,
            i_h2                 => w_h2,
            i_m0                 => w_m0,
            i_m0_dist            => w_m0_dist,
            i_m0_last_m1         => w_m0_last_m1,
            i_c0                 => w_c0,
            i_c0_last_c1         => w_c0_last_c1,
            i_image_x            => i_image_x,
            i_image_y            => i_image_y,
            i_channels           => i_channels,
            i_kernel_size        => i_kernel_size,
            i_fifo_full_iact     => w_fifo_iact_address_full,
            i_fifo_full_wght     => w_fifo_wght_address_full,
            o_address_iact       => o_address_iact,
            o_address_wght       => o_address_wght,
            o_address_iact_valid => o_address_iact_valid,
            o_address_wght_valid => o_address_wght_valid
        );

end architecture alternative_rs_dataflow;

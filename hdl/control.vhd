library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity control is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        line_length_iact : positive := 512;
        addr_width_iact  : positive := 9;
        line_length_psum : positive := 512;
        addr_width_psum  : positive := 9;
        line_length_wght : positive := 512;
        addr_width_wght  : positive := 9;

        g_control_init : boolean := true
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start     : in    std_logic;
        i_enable_if : in    std_logic; -- enable signal from scratchpad interface (0 when stalling)

        o_init_done  : out   std_logic;
        o_enable     : out   std_logic;
        o_pause_iact : out   std_logic;
        o_done       : out   std_logic;

        o_c1         : out   integer range 0 to 1023;
        o_w1         : out   integer range 0 to 1023;
        o_h2         : out   integer range 0 to 1023;
        o_m0         : out   integer range 0 to 1023;
        o_m0_dist    : out   array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
        o_m0_last_m1 : out   integer range 0 to 1023;

        o_c0         : out   integer range 0 to 1023;
        o_c0_last_c1 : out   integer range 0 to 1023;

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

        -- Added ports from generics
        i_c1           : in    integer range 0 to 1023;
        i_w1           : in    integer range 0 to 1023;
        i_h2           : in    integer range 0 to 1023;
        i_m0           : in    integer range 0 to 1023;
        i_m0_last_m1   : in    integer range 0 to 1023;
        i_rows_last_h2 : in    integer range 0 to 1023;
        i_c0           : in    integer range 0 to 1023;
        i_c0_last_c1   : in    integer range 0 to 1023;
        i_c0w0         : in    integer range 0 to 1023;
        i_c0w0_last_c1 : in    integer range 0 to 1023
    );
end entity control;

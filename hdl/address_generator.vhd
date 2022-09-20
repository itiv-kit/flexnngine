library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        line_length_iact : positive := 512;
        addr_width_iact  : positive := 9;
        line_length_psum : positive := 512;
        addr_width_psum  : positive := 9;
        line_length_wght : positive := 512;
        addr_width_wght  : positive := 9
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        status     : out   std_logic;
        start      : in    std_logic;
        start_init : in    std_logic;

        tiles_c : in    integer range 0 to 1023;
        tiles_x : in    integer range 0 to 1023;
        tiles_y : in    integer range 0 to 1023;

        c_per_tile  : in    integer range 0 to 1023;
        c_last_tile : in    integer range 0 to 1023;

        image_x : in    integer range 0 to 1023; --! size of input image
        image_y : in    integer range 0 to 1023; --! size of input image

        channels : in    integer range 0 to 4095; -- Number of input channels the image and kernels have

        kernel_size : in    integer range 0 to 32;

        update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
    );
end entity address_generator;

architecture rtl of address_generator is

    type   t_state_type is (s_idle, s_processing);
    signal r_state_wght : t_state_type;
    signal r_state_iact : t_state_type;

begin

end architecture rtl;

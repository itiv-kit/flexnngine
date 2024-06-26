library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;
    use work.control;

entity control_conv_tb is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 512;
        addr_width_iact  : positive := 9;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 512;
        addr_width_psum  : positive := 9;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 25;
        addr_width_wght  : positive := 9
    );
end entity control_conv_tb;

architecture imp of control_conv_tb is

    signal clk  : std_logic := '0';
    signal rstn : std_logic;

    signal status       : std_logic;
    signal start        : std_logic;
    signal image_x      : integer;
    signal image_y      : integer;
    signal channels     : integer;
    signal kernel_size  : integer;
    signal command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

begin

    control_inst : entity work.control
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            o_status       => status,
            i_start        => start,
            i_image_x      => image_x,
            i_image_y      => image_y,
            i_channels     => channels,
            i_kernel_size  => kernel_size,
            o_command      => command,
            o_command_iact => command_iact,
            o_command_psum => command_psum,
            o_command_wght => command_wght
        );

    rstn_gen : process is
    begin

        rstn <= '0';
        wait for 100 ns;
        rstn <= '1';
        wait;

    end process rstn_gen;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

    start_config : process is
    begin

        wait until rstn = '1';
        wait until rising_edge(clk);

        start <= '0';

        image_x     <= 14;
        image_y     <= 14;
        channels    <= 5;
        kernel_size <= 5;

        wait for 50 ns;
        start <= '1';

        wait;

    end process start_config;

end architecture imp;

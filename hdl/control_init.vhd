library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity control_init is
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
        addr_width_wght  : positive := 9
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        o_c1         : out   integer range 0 to 1023;
        o_w1         : out   integer range 0 to 1023;
        o_h2         : out   integer range 0 to 1023;
        o_m0         : out   integer range 0 to 1023;
        o_m0_dist    : out   array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
        o_m0_last_m1 : out   integer range 0 to 1023;

        o_rows_last_h2 : out   integer range 0 to 1023;
        o_c0           : out   integer range 0 to 1023;
        o_c0_last_c1   : out   integer range 0 to 1023;
        o_c0w0         : out   integer range 0 to 1023;
        o_c0w0_last_c1 : out   integer range 0 to 1023;

        i_image_x     : in    integer range 0 to 1023; --! size of input image
        i_image_y     : in    integer range 0 to 1023; --! size of input image
        i_channels    : in    integer range 0 to 4095; -- Number of input channels the image and kernels have
        i_kernel_size : in    integer range 0 to 32;
        i_kernels     : in    integer range 0 to 4095; -- Number of kernels / output channels

        o_status : out   std_logic;
        i_start  : in    std_logic
    );
end entity control_init;

architecture rs_dataflow of control_init is

    signal w_startup_done : std_logic;

    signal r_c0w0         : integer range 0 to 1023; /* TODO find useful ranges for integers*/
    signal r_c0w0_last_c1 : integer range 0 to 1023;

    signal r_c0         : integer range 0 to 1023;
    signal r_c0_last_c1 : integer range 0 to 1023;

    signal r_h2           : integer range 0 to 1023;
    signal r_rows_last_h2 : integer range 0 to 1023;

    signal r_w1 : integer range 0 to 1023;
    signal r_c1 : integer range 0 to 1023;

    signal r_h2_tmp : integer range 0 to 1023;
    signal r_c1_tmp : integer range 0 to 4095;

    signal r_m0     : integer range 0 to 1023;
    signal r_m0_tmp : integer range 0 to 1023;

    signal r_init_h2_done   : std_logic;
    signal r_init_c1_done   : std_logic;
    signal r_init_c0w0_done : std_logic;
    signal r_init_m0_done   : std_logic;

    -- type t_m0 is array(natural range <>) of integer range 0 to size_y;
    signal r_m0_dist         : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal r_m0_count_idx    : integer range 0 to size_y + 1;
    signal r_m0_count_kernel : integer range 0 to size_y + 1;

    -- delay and tmp values for calculation of init value: r_commands_last_tile_c
    signal r_delay_init : integer range 0 to 15;
    signal r_tmp1       : integer range 0 to 1023;
    signal r_tmp2       : integer range 0 to 1023;
    signal r_tmp3       : integer range 0 to 1023;

begin

    o_c0_last_c1 <= r_c0_last_c1;
    o_c0         <= r_c0;

    o_c1      <= r_c1;
    o_w1      <= r_w1;
    o_h2      <= r_h2;
    o_m0      <= r_m0;
    o_m0_dist <= r_m0_dist;

    o_c0w0         <= r_c0w0;
    o_c0w0_last_c1 <= r_c0w0_last_c1;

    o_rows_last_h2 <= r_rows_last_h2;

    -- Map kernels on accelerator y dimension. 0 is no kernel, thus starting with 1.
    p_init_m0_dist : process (clk, rstn) is

        variable v_m0_count : integer range 0 to size_y + 1;

    begin

        if not rstn then
            r_m0_count_idx    <= 0;
            r_m0_count_kernel <= 0;
            v_m0_count        := 1;
            r_m0_dist         <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if i_start = '1' and r_init_m0_done = '1' then
                if r_m0_count_idx /= size_y then
                    r_m0_count_idx <= r_m0_count_idx + 1;
                    if r_m0_count_kernel /= i_kernel_size then
                        r_m0_count_kernel         <= r_m0_count_kernel + 1;
                        r_m0_dist(r_m0_count_idx) <= std_logic_vector(to_unsigned(v_m0_count, addr_width_y));
                    else
                        if r_m0_count_idx + i_kernel_size <= size_y then -- check if one more kernel can be mapped
                            r_m0_count_kernel         <= 1;
                            v_m0_count                := v_m0_count + 1;
                            r_m0_dist(r_m0_count_idx) <= std_logic_vector(to_unsigned(v_m0_count, addr_width_y));
                        end if;
                    end if;
                end if;
            end if;
        end if;

    end process p_init_m0_dist;

    p_init_m0 : process (clk, rstn) is
    begin

        if not rstn then
            r_m0           <= 0;
            r_init_m0_done <= '0';
            r_m0_tmp       <= 0;
        elsif rising_edge(clk) then
            if i_start and not r_init_m0_done then
                r_m0_tmp <= r_m0_tmp + i_kernel_size;
                if r_m0_tmp > size_y then
                    r_init_m0_done <= '1';
                    r_m0           <= r_m0 - 1;
                else
                    r_m0 <= r_m0 + 1;
                end if;
            end if;
        end if;

    end process p_init_m0;

    p_init_c0w0 : process (clk, rstn) is
    begin

        if not rstn then
            r_c0w0           <= 0;
            r_init_c0w0_done <= '0';
        elsif rising_edge(clk) then
            if i_start and not r_init_c0w0_done then
                r_c0w0 <= r_c0w0 + i_kernel_size;
                r_c0   <= r_c0 + 1;
                if r_c0w0 + 5 > line_length_wght then
                    -- Commands per tile determined
                    -- Tiling c0w0 to always have 5 values remaining in buffer (enable is only set low when r/u pipeline filled)
                    r_c0w0           <= r_c0w0 - i_kernel_size;
                    r_c0             <= r_c0 - 1;
                    r_init_c0w0_done <= '1';
                else
                end if;
            end if;
        end if;

    end process p_init_c0w0;

    p_init_c : process (clk, rstn) is
    begin

        if not rstn then
            r_c1           <= 0;
            r_c1_tmp       <= 0;
            r_c0w0_last_c1 <= 0;
            r_init_c1_done <= '0';
            r_delay_init   <= 0;
        elsif rising_edge(clk) then
            if r_init_c0w0_done and not r_init_c1_done then
                r_c1_tmp <= r_c1_tmp + r_c0w0;

                if r_c1_tmp >= i_kernel_size * i_channels then
                    -- Tiling done
                    r_delay_init   <= r_delay_init + 1;
                    r_tmp1         <= i_kernel_size * i_channels;
                    r_tmp2         <= r_c1 - 1;
                    r_tmp3         <= r_tmp2 * r_c0w0;
                    r_c0w0_last_c1 <= r_tmp1 - r_tmp3;
                    r_c0_last_c1   <= r_c0w0_last_c1 / i_kernel_size;
                    -- r_commands_last_tile_c <= kernel_size * channels - ((r_tiles_c - 1) * r_commands_per_tile);
                    if r_delay_init = 5 then
                        r_init_c1_done <= '1';
                    end if;
                else
                    r_c1 <= r_c1 + 1;
                end if;
            end if;
        end if;

    end process p_init_c;

    p_init_h2 : process (clk, rstn) is
    begin

        if not rstn then
            r_h2           <= 0;
            r_h2_tmp       <= 0;
            r_rows_last_h2 <= 0;
            r_init_h2_done <= '0';
        elsif rising_edge(clk) then
            if i_start and r_init_m0_done and not r_init_h2_done then
                r_h2_tmp <= r_h2_tmp + size_x;

                if r_h2_tmp >= (i_image_y - i_kernel_size + 1) and r_m0 = 1 then      -- one kernel vertically
                    -- Tiling done
                    r_rows_last_h2 <= r_h2_tmp - (i_image_y - 2 * i_kernel_size + 1);
                    r_init_h2_done <= '1';
                elsif r_h2_tmp >= i_image_y then                                      -- more than one kernel vertically
                    -- Tiling done
                    r_rows_last_h2 <= r_h2_tmp - (i_image_y - 2 * i_kernel_size + 1);
                    r_init_h2_done <= '1';
                else
                    r_h2 <= r_h2 + 1;
                end if;
            end if;
        end if;

    end process p_init_h2;

    w_startup_done <= '1' when r_init_c1_done and r_init_h2_done else
                      '0';

    o_status <= w_startup_done;

    p_init : process (clk, rstn) is
    begin

        if not rstn then
            r_w1 <= 0;
        elsif rising_edge(clk) then
            r_w1 <= i_image_x - i_kernel_size + 1;
        end if;

    end process p_init;

end architecture rs_dataflow;

architecture alternative_rs_dataflow of control_init is

    signal w_startup_done : std_logic;

    signal r_c0w0         : integer range 0 to 1023; /* TODO find useful ranges for integers*/
    signal r_c0w0_last_c1 : integer range 0 to 1023;

    signal r_c0         : integer range 0 to 1023;
    signal r_c0_last_c1 : integer range 0 to 1023;

    signal r_h2           : integer range 0 to 1023;
    signal r_rows_last_h2 : integer range 0 to 1023;

    signal r_w1 : integer range 0 to 1023;
    signal r_c1 : integer range 0 to 1023;

    signal r_h2_tmp : integer range 0 to 1023;
    signal r_c1_tmp : integer range 0 to 4095;

    signal r_m0     : integer range 0 to 1023;
    signal r_m1     : integer range 0 to 1023;
    signal r_m0_tmp : integer range 0 to 1023;

    signal r_init_h2_done   : std_logic;
    signal r_init_c1_done   : std_logic;
    signal r_init_c0w0_done : std_logic;
    signal r_init_m0_done   : std_logic;

    -- type t_m0 is array(natural range <>) of integer range 0 to size_y;
    signal r_m0_dist         : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal r_m0_count_idx    : integer range 0 to size_y + 1;
    signal r_m0_count_kernel : integer range 0 to 4096;
    signal r_m0_last_m1      : integer range 0 to size_y + 1;

    -- delay and tmp values for calculation of init value: r_commands_last_tile_c
    signal r_delay_init : integer range 0 to 15;
    signal r_tmp1       : integer range 0 to 1023;
    signal r_tmp2       : integer range 0 to 1023;
    signal r_tmp3       : integer range 0 to 1023;

begin

    o_c0_last_c1 <= r_c0_last_c1;
    o_c0         <= r_c0;

    o_c1         <= r_c1;
    o_w1         <= r_w1;
    o_h2         <= r_h2;
    o_m0         <= r_m0;
    o_m0_last_m1 <= r_m0_last_m1;

    o_c0w0         <= r_c0w0;
    o_c0w0_last_c1 <= r_c0w0_last_c1;

    o_rows_last_h2 <= r_rows_last_h2;

    r_m0 <= size_y;

    -- Map m0 / m1 tiling on accelerator.
    p_init_m0_dist : process (clk, rstn) is
    begin

        if not rstn then
            r_m0_count_kernel <= 0;
            r_m1              <= 0;
            r_m0_last_m1      <= 0;
            r_init_m0_done    <= '0';
        elsif rising_edge(clk) then
            if i_start = '1' and r_init_m0_done = '0' then
                if r_m0_count_kernel < i_kernels then
                    r_m0_count_kernel <= r_m0_count_kernel + size_y;
                    r_m1              <= r_m1 + 1;
                elsif r_m0_count_kernel - i_kernels = 0 then
                    r_m0_last_m1   <= size_y;
                    r_init_m0_done <= '1';
                elsif r_m1 = 1 then
                    r_m0_last_m1   <= i_kernels;
                    r_init_m0_done <= '1';
                else
                    r_m0_last_m1   <= i_kernels - (r_m0_count_kernel - size_y);
                    r_init_m0_done <= '1';
                end if;
            end if;
        end if;

    end process p_init_m0_dist;

    p_init_c0w0 : process (clk, rstn) is
    begin

        if not rstn then
            r_c0w0           <= 0;
            r_init_c0w0_done <= '0';
        elsif rising_edge(clk) then
            if i_start and not r_init_c0w0_done then
                r_c0w0 <= r_c0w0 + i_kernel_size;
                r_c0   <= r_c0 + 1;
                if r_c0w0 + 25 > line_length_wght then
                    -- Commands per tile determined
                    -- Tiling c0w0 to always have 5 values remaining in buffer (enable is only set low when r/u pipeline filled) /* TODO now set to 15 values */
                    r_c0w0           <= r_c0w0 - i_kernel_size;
                    r_c0             <= r_c0 - 1;
                    r_init_c0w0_done <= '1';
                else
                end if;
            end if;
        end if;

    end process p_init_c0w0;

    p_init_c : process (clk, rstn) is
    begin

        if not rstn then
            r_c1           <= 0;
            r_c1_tmp       <= 0;
            r_c0w0_last_c1 <= 0;
            r_init_c1_done <= '0';
            r_delay_init   <= 0;
        elsif rising_edge(clk) then
            if r_init_c0w0_done and not r_init_c1_done then
                r_c1_tmp <= r_c1_tmp + r_c0w0;

                if r_c1_tmp >= i_kernel_size * i_channels then
                    -- Tiling done
                    r_delay_init   <= r_delay_init + 1;
                    r_tmp1         <= i_kernel_size * i_channels;
                    r_tmp2         <= r_c1 - 1;
                    r_tmp3         <= r_tmp2 * r_c0w0;
                    r_c0w0_last_c1 <= r_tmp1 - r_tmp3;
                    r_c0_last_c1   <= r_c0w0_last_c1 / i_kernel_size;
                    -- r_commands_last_tile_c <= kernel_size * channels - ((r_tiles_c - 1) * r_commands_per_tile);
                    if r_delay_init = 5 then
                        r_init_c1_done <= '1';
                    end if;
                else
                    r_c1 <= r_c1 + 1;
                end if;
            end if;
        end if;

    end process p_init_c;

    p_init_h2 : process (clk, rstn) is
    begin

        if not rstn then
            r_h2           <= 0;
            r_h2_tmp       <= 0;
            r_rows_last_h2 <= 0;
            r_init_h2_done <= '0';
        elsif rising_edge(clk) then
            if i_start and not r_init_h2_done then
                r_h2_tmp <= r_h2_tmp + size_x;

                if r_h2_tmp + i_kernel_size > i_image_x then
                    r_rows_last_h2 <= size_x + i_image_x - (r_h2_tmp + i_kernel_size) + 1;
                    r_init_h2_done <= '1';
                else
                    r_h2 <= r_h2 + 1;
                end if;
            end if;
        end if;

    end process p_init_h2;

    w_startup_done <= '1' when r_init_c1_done and r_init_h2_done and r_init_m0_done else
                      '0';

    o_status <= w_startup_done;

    p_init : process (clk, rstn) is
    begin

        if not rstn then
            r_w1 <= 0;
        elsif rising_edge(clk) then
            r_w1 <= i_image_x - i_kernel_size + 1;
        end if;

    end process p_init;

end architecture alternative_rs_dataflow;

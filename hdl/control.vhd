library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity control is
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

        status : out   std_logic;
        start  : in    std_logic;

        image_x : in    integer range 0 to 1023; --! size of input image
        image_y : in    integer range 0 to 1023; --! size of input image

        channels : in    integer range 0 to 4095; -- Number of input channels the image and kernels have

        kernel_size : in    integer range 0 to 32;

        command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

        update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
    );
end entity control;

architecture rtl of control is

    signal r_startup_done : std_logic;

    signal r_command_counter     : integer range 0 to 511;
    signal r_tile_filter_counter : integer range 0 to 1023;
    signal r_tile_x_counter      : integer range 0 to 1023;
    signal r_tile_y_counter      : integer range 0 to 1023;

    signal r_commands_per_tile         : integer range 0 to 1023;
    signal r_commands_last_tile_filter : integer range 0 to 1023;

    signal r_tiles_y                : integer range 0 to 1023;
    signal r_tiles_y_last_tile_rows : integer range 0 to 1023;

    signal r_tiles_x      : integer range 0 to 1023;
    signal r_tiles_filter : integer range 0 to 1023;

    signal r_tiles_y_tmp      : integer range 0 to 1023;
    signal r_tiles_filter_tmp : integer range 0 to 4095;

    signal r_tiling_y_done          : std_logic;
    signal r_tiling_filter_done     : std_logic;
    signal r_commands_per_tile_done : std_logic;

    signal r_tile_change    : std_logic;
    signal r_tile_change_d  : std_logic;
    signal r_tile_change_dt : std_logic;

    signal r_delay_filter_tiles : std_logic;

    type   t_state_type is (s_calculate, s_output);
    signal r_state : t_state_type;

    signal r_command_iact       : command_lb_array_t(0 to size_y);
    signal r_read_offset_iact   : array_t(0 to size_y)(addr_width_iact - 1 downto 0);
    signal r_update_offset_iact : array_t(0 to size_y)(addr_width_iact - 1 downto 0);

    signal r_command_wght       : command_lb_array_t(0 to size_y);
    signal r_read_offset_wght   : array_t(0 to size_y)(addr_width_wght - 1 downto 0);
    signal r_update_offset_wght : array_t(0 to size_y)(addr_width_wght - 1 downto 0);

    signal r_command_psum_d       : command_lb_array_t(0 to size_y);
    signal r_read_offset_psum_d   : array_t(0 to size_y)(addr_width_psum - 1 downto 0);
    signal r_update_offset_psum_d : array_t(0 to size_y)(addr_width_psum - 1 downto 0);

    signal r_command_psum       : command_lb_array_t(0 to size_y);
    signal r_read_offset_psum   : array_t(0 to size_y)(addr_width_psum - 1 downto 0);
    signal r_update_offset_psum : array_t(0 to size_y)(addr_width_psum - 1 downto 0);

    signal mux_read_offset_psum   : array_t(0 to size_y)(addr_width_psum - 1 downto 0);
    signal mux_update_offset_psum : array_t(0 to size_y)(addr_width_psum - 1 downto 0);

    signal r_command : command_pe_array_t(0 to size_y);

    -- delay and tmp values for calculation of init value: r_commands_last_tile_filter
    signal r_delay_init : integer range 0 to 15;
    signal tmp1         : integer range 0 to 1023;
    signal tmp2         : integer range 0 to 1023;
    signal tmp3         : integer range 0 to 1023;

begin

    /*r_command <= (others => c_pe_conv_mult) when r_state = s_calculate else
                 (others => c_pe_conv_psum) when r_state = s_output; */

    r_tile_change_d <= r_tile_change when rising_edge(clk);

    r_tile_change_dt <= '1' when r_tile_change = '1' and r_tile_change_d = '0' else
                        '0';

    r_command_psum_d       <= r_command_psum when rising_edge(clk);
    r_read_offset_psum_d   <= r_read_offset_psum when rising_edge(clk);
    r_update_offset_psum_d <= r_update_offset_psum when rising_edge(clk);

    mux_read_offset_psum <= r_read_offset_psum_d when r_state = s_output else
                            r_read_offset_psum   when r_state = s_calculate;

    mux_update_offset_psum <= r_update_offset_psum_d when r_state = s_output else
                              r_update_offset_psum   when r_state = s_calculate;

    gen_delay_y : for y in 0 to size_y - 1 generate

        gen_delay_x : for x in 0 to size_x - 2 generate

            gen_00 : if x = 0 generate

                command(y, 0) <= r_command(y) when rising_edge(clk);

                command_iact(y, 0) <= r_command_iact(y) when rising_edge(clk);
                command_wght(y, 0) <= r_command_wght(y) when rising_edge(clk);
                command_psum(y, 0) <= r_command_psum_d(y) when rising_edge(clk);

                update_offset_iact(y, 0) <= r_update_offset_iact(y) when rising_edge(clk);
                update_offset_wght(y, 0) <= r_update_offset_wght(y) when rising_edge(clk);
                update_offset_psum(y, 0) <= mux_update_offset_psum(y) when rising_edge(clk);

                read_offset_iact(y, 0) <= r_read_offset_iact(y) when rising_edge(clk);
                read_offset_wght(y, 0) <= r_read_offset_wght(y) when rising_edge(clk);
                read_offset_psum(y, 0) <= mux_read_offset_psum(y) when rising_edge(clk);

            end generate gen_00;

            command(y, x + 1) <= command(y, x) when rising_edge(clk);

            command_iact(y, x + 1) <= command_iact(y, x) when rising_edge(clk);
            command_psum(y, x + 1) <= command_psum(y, x) when rising_edge(clk);
            command_wght(y, x + 1) <= command_wght(y, x) when rising_edge(clk);

            update_offset_iact(y, x + 1) <= update_offset_iact(y, x) when rising_edge(clk);
            update_offset_wght(y, x + 1) <= update_offset_wght(y, x) when rising_edge(clk);
            update_offset_psum(y, x + 1) <= update_offset_psum(y, x) when rising_edge(clk);

            read_offset_iact(y, x + 1) <= read_offset_iact(y, x) when rising_edge(clk);
            read_offset_wght(y, x + 1) <= read_offset_wght(y, x) when rising_edge(clk);
            read_offset_psum(y, x + 1) <= read_offset_psum(y, x) when rising_edge(clk);

        end generate gen_delay_x;

    end generate gen_delay_y;

    /*p_init : process (clk, rstn) is

        variable v_tiles_filter : integer;
        variable v_commands_per_tile : integer;
        variable v_tiles_y : integer;

    begin

        if not rstn then

            r_tiles_y <= 1;
            r_tiles_filter <= 1;
            r_startup_done <= '0';
            v_tiles_filter := 0;
            v_commands_per_tile := 0;
            v_tiles_y := 0;
            r_commands_last_tile_filter <= 0;
            r_tiles_x <= 0;
            r_tiles_y_last_tile_rows <= 0;

        elsif rising_edge(clk) then

            if start and not r_startup_done then

                r_tiles_x <= image_x - kernel_size + 1;

                v_tiles_y := integer(ceil(real((image_y - kernel_size + 1)) / real(kernel_size)));

                v_tiles_filter := integer(ceil(real((kernel_size * channels)) / real(line_length_wght)));
                
                if v_tiles_filter = 1 then
                    v_commands_per_tile := 0;
                    r_commands_last_tile_filter <= kernel_size * channels;
                else
                    v_commands_per_tile := integer(floor(real(line_length_wght)/real(kernel_size))) * kernel_size;
                    r_commands_last_tile_filter <= integer(real(kernel_size * channels) - real((v_tiles_filter - 1) * v_commands_per_tile));
                end if;

                r_tiles_filter <= v_tiles_filter;
                r_commands_per_tile <= v_commands_per_tile;
                r_tiles_y <= v_tiles_y;

                r_startup_done <= '1';

                r_tiles_y_last_tile_rows <= (image_x - size_rows - ((v_tiles_y - 2) * kernel_size));

            end if;

        end if;

    end process p_init;*/

    p_init_commands_per_tile : process (clk, rstn) is
    begin

        if not rstn then
            r_commands_per_tile      <= 0;
            r_commands_per_tile_done <= '0';
        elsif rising_edge(clk) then
            if start and not r_commands_per_tile_done then
                r_commands_per_tile <= r_commands_per_tile + kernel_size;

                if r_commands_per_tile > line_length_wght then
                    -- Commands per tile determined
                    r_commands_per_tile      <= r_commands_per_tile - kernel_size;
                    r_commands_per_tile_done <= '1';
                else
                end if;
            end if;
        end if;

    end process p_init_commands_per_tile;

    p_init_tiles_filter : process (clk, rstn) is
    begin

        if not rstn then
            r_tiles_filter              <= 0;
            r_tiles_filter_tmp          <= 0;
            r_commands_last_tile_filter <= 0;
            r_tiling_filter_done        <= '0';
            r_delay_init                <= 0;
        elsif rising_edge(clk) then
            if r_commands_per_tile_done and not r_tiling_filter_done then
                r_tiles_filter_tmp <= r_tiles_filter_tmp + r_commands_per_tile;

                if r_tiles_filter_tmp >= kernel_size * channels then
                    -- Tiling done
                    r_delay_init                <= r_delay_init + 1;
                    tmp1                        <= kernel_size * channels;
                    tmp2                        <= r_tiles_filter - 1;
                    tmp3                        <= tmp2 * r_commands_per_tile;
                    r_commands_last_tile_filter <= tmp1 - tmp3;
                    -- r_commands_last_tile_filter <= kernel_size * channels - ((r_tiles_filter - 1) * r_commands_per_tile);
                    if r_delay_init = 5 then
                        r_tiling_filter_done <= '1';
                    end if;
                else
                    r_tiles_filter <= r_tiles_filter + 1;
                end if;
            end if;
        end if;

    end process p_init_tiles_filter;

    p_init_tiles_y : process (clk, rstn) is
    begin

        if not rstn then
            r_tiles_y                <= 0;
            r_tiles_y_tmp            <= 0;
            r_tiles_y_last_tile_rows <= 0;
            r_tiling_y_done          <= '0';
        elsif rising_edge(clk) then
            if start and not r_tiling_y_done then
                r_tiles_y_tmp <= r_tiles_y_tmp + size_x;

                if r_tiles_y_tmp >= (image_y - 2 * kernel_size + 2) then
                    -- Tiling done
                    r_tiles_y_last_tile_rows <= r_tiles_y_tmp - (image_y - 2 * kernel_size + 1);
                    r_tiling_y_done          <= '1';
                else
                    r_tiles_y <= r_tiles_y + 1;
                end if;
            end if;
        end if;

    end process p_init_tiles_y;

    r_startup_done <= '1' when r_tiling_filter_done and r_tiling_y_done else
                      '0';

    p_init : process (clk, rstn) is
    begin

        if not rstn then
            r_tiles_x <= 0;
        elsif rising_edge(clk) then
            r_tiles_x <= image_x - kernel_size + 1;
        end if;

    end process p_init;

    p_command_counter : process (clk, rstn) is

    begin

        if not rstn then
            r_tile_y_counter      <= 0;
            r_tile_x_counter      <= 0;
            r_tile_filter_counter <= 0;
            r_command_counter     <= 0;
            r_delay_filter_tiles  <= '0';
            r_tile_change         <= '0';
            r_state               <= s_calculate;
        elsif rising_edge(clk) then
            if r_startup_done = '1' then
                if r_state = s_calculate then
                    r_tile_change <= '0';

                    if r_tile_y_counter /= r_tiles_y then
                        if r_tile_x_counter /= r_tiles_x then
                            if r_tile_filter_counter /= r_tiles_filter then
                                if ((r_command_counter /= r_commands_per_tile - 1) and r_tile_filter_counter /= r_tiles_filter - 1) or ((r_command_counter /= r_commands_last_tile_filter - 1) and r_tile_filter_counter = r_tiles_filter - 1) then
                                    r_command_counter <= r_command_counter + 1;
                                else
                                    if r_delay_filter_tiles = '1' or (r_tile_filter_counter = r_tiles_filter - 1) then
                                        -- Tile change for tiles_filter
                                        r_command_counter     <= 0;
                                        r_tile_filter_counter <= r_tile_filter_counter + 1;
                                        r_tile_change         <= '1';
                                        r_delay_filter_tiles  <= '0';
                                    else
                                        r_tile_change        <= '1';
                                        r_delay_filter_tiles <= '1';
                                    end if;
                                end if;
                            else
                                -- Tile change for tile_x
                                r_tile_change         <= '1';
                                r_tile_filter_counter <= 0;
                                r_tile_x_counter      <= r_tile_x_counter + 1;
                            end if;
                        else
                            -- Tile change for tile_y
                            -- Output intermediate results. Reset Psum and Iact buffer. Wait.
                            r_state <= s_output;

                            r_tile_x_counter <= 0;
                            r_tile_y_counter <= r_tile_y_counter + 1;
                        end if;
                    else
                    -- DONE for now (not tiled for PSUM Line Buffer Length)
                    end if;
                elsif r_state = s_output then
                    if r_command_counter /= size_y then
                        if r_tile_x_counter /= r_tiles_x - 1 then
                            r_tile_x_counter <= r_tile_x_counter + 1;
                        else
                            r_tile_x_counter  <= 0;
                            r_command_counter <= r_command_counter + 1;
                        end if;
                    else
                        -- Delay counter
                        if r_tile_x_counter /= r_tiles_x - 1 then
                            r_tile_x_counter <= r_tile_x_counter + 1;
                        else
                            r_tile_x_counter  <= 0;
                            r_command_counter <= 0;
                            r_state           <= s_calculate;
                        end if;
                    -- Output done, reset psum etc?
                    end if;
                end if;
            end if;
        end if;

    end process p_command_counter;

    p_command : process (clk, rstn) is
    begin

        if not rstn then
            r_command <= (others => c_pe_conv_mult);
        elsif rising_edge(clk) then
            if r_state = s_output and r_tile_x_counter = 1 then
                r_command <= (others => c_pe_conv_psum);
            elsif r_state = s_calculate then
                r_command <= (others => c_pe_conv_mult);
            end if;
        end if;

    end process p_command;

    p_iact_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_iact       <= (others => c_lb_idle);
            r_read_offset_iact   <= (others => (others => '0'));
            r_update_offset_iact <= (others => (others => '0'));
        elsif rising_edge(clk) then
            r_update_offset_iact <= (others => (others => '0'));

            if r_startup_done = '1' then
                if r_state = s_calculate then
                    if r_tile_change_dt = '1' then
                        -- Tile x change

                        r_command_iact <= (others => c_lb_shrink);

                        if r_tile_filter_counter = r_tiles_filter then
                            r_read_offset_iact <= (others => std_logic_vector(to_unsigned(channels, addr_width_iact)));
                        else
                            /* TODO FILTER TILES: IMPLEMENT AND TEST */
                            r_read_offset_iact <= ((others => (others => 'X'))); -- std_logic_vector(to_unsigned(111, addr_width_iact));
                        end if;
                    elsif r_tile_x_counter = r_tiles_x then
                        -- Tile y change

                        r_command_iact     <= (others => c_lb_idle);
                        r_read_offset_iact <= (others => (others => '0'));
                    else
                        r_command_iact     <= (others => c_lb_read);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(r_command_counter, addr_width_iact)));
                    end if;
                -- command_iact <=
                -- update_offset_iact <=
                -- read_offset_iact <=
                elsif r_state = s_output then
                    r_command_iact     <= (others => c_lb_idle);
                    r_read_offset_iact <= (others => (others => '0'));

                    if r_command_counter = size_y and r_tile_x_counter = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(kernel_size * channels - channels, addr_width_iact)));
                    end if;
                end if;
            end if;
        end if;

    end process p_iact_commands;

    p_wght_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_wght       <= (others => c_lb_idle);
            r_read_offset_wght   <= (others => (others => '0'));
            r_update_offset_wght <= (others => (others => '0'));
        elsif rising_edge(clk) then
            r_update_offset_wght <= (others => (others => '0'));

            if r_startup_done = '1'  then
                if r_state = s_calculate then
                    if r_tile_change_dt = '1' then
                        -- Tile x change

                        if r_tile_filter_counter = r_tiles_filter then
                            r_command_wght     <= (others => c_lb_idle);
                            r_read_offset_wght <= (others => std_logic_vector(to_unsigned(0, addr_width_wght)));
                        else
                            /* TODO FILTER TILES: IMPLEMENT AND TEST */
                            r_command_wght     <= (others => c_lb_shrink);
                            r_read_offset_wght <= (others => (others => 'X')); -- std_logic_vector(to_unsigned(111, addr_width_iact));
                        end if;
                    elsif r_tile_x_counter = r_tiles_x then
                        -- Tile y change

                        r_command_wght     <= (others => c_lb_idle);
                        r_read_offset_wght <= (others => (others => '0'));
                    else
                        r_command_wght     <= (others => c_lb_read);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(r_command_counter, addr_width_wght)));
                    end if;
                elsif r_state = s_output then
                    r_command_wght <= (others => c_lb_idle);
                end if;
            end if;
        end if;

    end process p_wght_commands;

    p_psum_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_psum       <= (others => c_lb_idle);
            r_read_offset_psum   <= (others => (others => '0'));
            r_update_offset_psum <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if r_startup_done = '1' then
                if r_state = s_calculate then
                    if r_tile_change_dt = '1' then
                        -- Tile x change

                        if r_tile_filter_counter = r_tiles_filter then
                            r_command_psum       <= (others => c_lb_idle);
                            r_read_offset_psum   <= (others => std_logic_vector(to_unsigned(0, addr_width_psum)));
                            r_update_offset_psum <= r_read_offset_psum;
                        else
                            /* TODO FILTER TILES: IMPLEMENT AND TEST */
                            r_command_psum     <= (others => c_lb_idle);
                            r_read_offset_psum <= (others => (others => 'X')); -- std_logic_vector(to_unsigned(111, addr_width_iact));
                        end if;
                    elsif r_tile_x_counter = r_tiles_x then
                        -- Tile y change

                        r_command_psum       <= (others => c_lb_idle);
                        r_read_offset_psum   <= (others => (others => '0'));
                        r_update_offset_psum <= (others => (others => '0'));
                    else
                        r_command_psum       <= (others => c_lb_read_update);
                        r_read_offset_psum   <= (others => std_logic_vector(to_unsigned(r_tile_x_counter, addr_width_psum)));
                        r_update_offset_psum <= r_read_offset_psum;
                    end if;
                elsif r_state = s_output then
                    r_command_psum       <= (others => c_lb_idle);
                    r_read_offset_psum   <= (others => (others => '0'));
                    r_update_offset_psum <= (others => (others => '0'));

                    if r_command_counter = size_y then
                        -- Remove all stored psums, new tile
                        if r_tile_x_counter = 0 then
                            r_command_psum     <= (others => c_lb_shrink);
                            r_read_offset_psum <= (others => std_logic_vector(to_unsigned(image_x - kernel_size + 1, addr_width_psum)));
                        end if;
                    else
                        r_command_psum(size_y - r_command_counter - 1) <= c_lb_read;

                        if r_command_counter /= size_y - 1 then
                            r_command_psum(size_y - r_command_counter - 2) <= c_lb_read_update;
                        end if;

                        r_read_offset_psum   <= (others => std_logic_vector(to_unsigned(r_tile_x_counter, addr_width_psum)));
                        r_update_offset_psum <= (others => std_logic_vector(to_unsigned(r_tile_x_counter, addr_width_psum)));
                    end if;
                end if;
            end if;
        end if;

    end process p_psum_commands;

end architecture rtl;

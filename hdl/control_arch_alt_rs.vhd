library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

architecture alternative_rs_dataflow of control is

    signal w_init_done : std_logic;

    signal r_count_c0w0 : integer range 0 to 2048; -- range 0 to 511
    signal r_count_c1   : integer range 0 to 1023;
    signal r_count_w1   : integer range 0 to 1023;
    signal r_count_h2   : integer range 0 to 1023;
    signal r_count_h1   : integer range 0 to 1023;

    signal w_c0w0         : integer range 0 to 1023;
    signal w_c0w0_last_c1 : integer range 0 to 1023;

    signal w_c0         : integer range 0 to 1023;
    signal w_c0_last_c1 : integer range 0 to 1023;

    signal w_h2           : integer range 0 to 1023;
    signal w_rows_last_h2 : integer range 0 to 1023;

    signal w_w1 : integer range 0 to 1023;
    signal w_c1 : integer range 0 to 1023;

    signal r_incr_w1 : std_logic;

    signal w_m0         : integer range 0 to 1023;
    signal w_m0_dist    : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal w_m0_last_m1 : integer range 0 to 1023;

    type   t_state is (s_calculate, s_output, s_incr_c1, s_incr_h1);
    signal r_state : t_state;

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

    signal w_mux_read_offset_psum   : array_t(0 to size_y)(addr_width_psum - 1 downto 0);
    signal w_mux_update_offset_psum : array_t(0 to size_y)(addr_width_psum - 1 downto 0);
    signal w_mux_command_psum       : command_lb_array_t(0 to size_y);

    signal w_output_sequence : int_line_t(0 to size_y - 1);

    signal r_command : command_pe_array_t(0 to size_y);

    signal w_start : std_logic;

    signal r_done : std_logic;

begin

    o_new_output <= '1' when r_count_c0w0 = 2 and r_count_w1 = 0 and r_state = s_output else
                    '0';

    r_command_psum_d       <= r_command_psum when rising_edge(clk);
    r_read_offset_psum_d   <= r_read_offset_psum when rising_edge(clk);
    r_update_offset_psum_d <= r_update_offset_psum when rising_edge(clk);

    o_status <= w_init_done;

    o_c0_last_c1 <= w_c0_last_c1;
    o_c0         <= w_c0;

    o_c1 <= w_c1;
    o_w1 <= w_w1;
    o_h2 <= w_h2;
    o_m0 <= w_m0;

    -- unused by alternative rs dataflow, so drive these with constant 0
    w_m0_dist    <= (others => (others => '0'));
    o_m0_dist    <= w_m0_dist;
    o_m0_last_m1 <= w_m0_last_m1;

    p_start : process (clk, rstn) is
    begin

        if not rstn then
            w_start <= '0';
        elsif rising_edge(clk) then
            if i_start = '1' then
                w_start <= '1';
            end if;
        end if;

    end process p_start;

    /*p_start : process(i_start) is
        begin

            if i_start = '1' then
                w_start <= '1';
            end if;

    end process p_start;*/

    -- Do not stop when filling read/update pipeline
    o_enable <= i_start when r_count_c0w0 > 1 and r_state /= s_output else
                '1' when w_start = '1' else
                '1' when r_state = s_output else
                '0';

    o_pause_iact <= '1' when r_state = s_output else
                    '0';

    gen_delay_y : for y in 0 to size_y - 1 generate

        gen_delay_x : for x in 0 to size_x - 2 generate

            gen_00 : if x = 0 generate

                o_command(y, 0) <= r_command(y) when rising_edge(clk);

                o_command_iact(y, 0) <= r_command_iact(y) when rising_edge(clk);
                o_command_wght(y, 0) <= r_command_wght(y) when rising_edge(clk);
                o_command_psum(y, 0) <= w_mux_command_psum(y) when rising_edge(clk);

                o_update_offset_iact(y, 0) <= r_update_offset_iact(y) when rising_edge(clk);
                o_update_offset_wght(y, 0) <= r_update_offset_wght(y) when rising_edge(clk);
                o_update_offset_psum(y, 0) <= w_mux_update_offset_psum(y) when rising_edge(clk);

                o_read_offset_iact(y, 0) <= r_read_offset_iact(y) when rising_edge(clk);
                o_read_offset_wght(y, 0) <= r_read_offset_wght(y) when rising_edge(clk);
                o_read_offset_psum(y, 0) <= w_mux_read_offset_psum(y) when rising_edge(clk);

            end generate gen_00;

            o_command(y, x + 1) <= o_command(y, x) when rising_edge(clk);

            o_command_iact(y, x + 1) <= o_command_iact(y, x) when rising_edge(clk);
            o_command_psum(y, x + 1) <= o_command_psum(y, x) when rising_edge(clk);
            o_command_wght(y, x + 1) <= o_command_wght(y, x) when rising_edge(clk);

            o_update_offset_iact(y, x + 1) <= o_update_offset_iact(y, x) when rising_edge(clk);
            o_update_offset_wght(y, x + 1) <= o_update_offset_wght(y, x) when rising_edge(clk);
            o_update_offset_psum(y, x + 1) <= o_update_offset_psum(y, x) when rising_edge(clk);

            o_read_offset_iact(y, x + 1) <= o_read_offset_iact(y, x) when rising_edge(clk);
            o_read_offset_wght(y, x + 1) <= o_read_offset_wght(y, x) when rising_edge(clk);
            o_read_offset_psum(y, x + 1) <= o_read_offset_psum(y, x) when rising_edge(clk);

        end generate gen_delay_x;

    end generate gen_delay_y;

    /*gen_command_delay : for y in 0 to size_y - 1 generate

        p_command_delay : process(clk, rstn) is
        begin

            if not rstn then

                o_command(y, 0) <= c_pe_conv_mult;
                o_command_iact(y, 0) <= c_lb_idle;
                o_command_wght(y, 0) <= c_lb_idle;
                o_command_psum(y, 0) <= c_lb_idle;
                o_update_offset_iact(y, 0) <= (others => '0');
                o_update_offset_wght(y, 0) <= (others => '0');
                o_update_offset_psum(y, 0) <= (others => '0');
                o_read_offset_iact(y, 0) <= (others => '0');
                o_read_offset_wght(y, 0) <= (others => '0');
                o_read_offset_psum(y, 0) <= (others => '0');

            elsif rising_edge(clk) then

                if r_state /= s_output and y /= size_y - 1 then

                    o_command(y, 0) <= o_command(y+1,0);
                    o_command_iact(y, 0) <= o_command_iact(y+1,0);
                    o_command_wght(y, 0) <= o_command_wght(y+1,0);
                    o_command_psum(y, 0) <= o_command_psum(y+1,0);
                    o_update_offset_iact(y, 0) <= o_update_offset_iact(y+1,0);
                    o_update_offset_wght(y, 0) <= o_update_offset_wght(y+1,0);
                    o_update_offset_psum(y, 0) <= o_update_offset_psum(y+1,0);
                    o_read_offset_iact(y, 0) <= o_read_offset_iact(y+1,0);
                    o_read_offset_wght(y, 0) <= o_read_offset_wght(y+1,0);
                    o_read_offset_psum(y, 0) <= o_read_offset_psum(y+1,0);

                else

                    o_command(y, 0) <= r_command(y);
                    o_command_iact(y, 0) <= r_command_iact(y);
                    o_command_wght(y, 0) <= r_command_wght(y);
                    o_command_psum(y, 0) <= w_mux_command_psum(y);
                    o_update_offset_iact(y, 0) <= r_update_offset_iact(y);
                    o_update_offset_wght(y, 0) <= r_update_offset_wght(y);
                    o_update_offset_psum(y, 0) <= w_mux_update_offset_psum(y);
                    o_read_offset_iact(y, 0) <= r_read_offset_iact(y);
                    o_read_offset_wght(y, 0) <= r_read_offset_wght(y);
                    o_read_offset_psum(y, 0) <= w_mux_read_offset_psum(y);

                end if;

            end if;

        end process p_command_delay;

    end generate gen_command_delay;*/

    switch_state : process (all) is
    begin

        case r_state is

            when s_output =>

                w_mux_read_offset_psum   <= r_read_offset_psum_d;
                w_mux_update_offset_psum <= r_update_offset_psum_d;
                w_mux_command_psum       <= r_command_psum_d;

            when s_calculate =>

                w_mux_read_offset_psum   <= r_read_offset_psum;
                w_mux_update_offset_psum <= r_update_offset_psum;
                w_mux_command_psum       <= r_command_psum_d;

            when s_incr_c1 =>

                w_mux_read_offset_psum   <= r_read_offset_psum_d;
                w_mux_update_offset_psum <= r_update_offset_psum_d;
                w_mux_command_psum       <= r_command_psum_d;

            when s_incr_h1 =>

                w_mux_read_offset_psum   <= r_read_offset_psum_d;
                w_mux_update_offset_psum <= r_update_offset_psum_d;
                w_mux_command_psum       <= r_command_psum_d;

        end case;

    end process switch_state;

    p_command_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_h2   <= 0;
            r_count_w1   <= 0;
            r_count_c1   <= 0;
            r_count_c0w0 <= 0;
            r_incr_w1    <= '0';
            r_state      <= s_calculate;
            r_done       <= '0';
        elsif rising_edge(clk) then
            if w_init_done = '1' and o_enable = '1' then
                if r_state = s_calculate then
                    r_incr_w1 <= '0';
                    if r_count_h2 /= w_h2 then
                        if r_count_h1 /= i_kernel_size then
                            if r_count_c1 /= w_c1 then
                                if r_count_w1 /= w_w1 then
                                    -- if (r_command_counter /= r_commands_per_tile - 1) or (r_command_counter /= r_commands_last_tile_c - 1) then
                                    if not((r_count_c0w0 = w_c0w0 - 1 and r_count_c1 /= w_c1 - 1) or (r_count_c0w0 = w_c0w0_last_c1 - 1 and r_count_c1 = w_c1 - 1)) then
                                        r_count_c0w0 <= r_count_c0w0 + 1;
                                        r_incr_w1    <= '0';
                                    else
                                        -- shift kernel - increment w1
                                        if r_incr_w1 = '1' then
                                            r_count_w1   <= r_count_w1 + 1;
                                            r_count_c0w0 <= 0;
                                            r_incr_w1    <= '0';
                                        else
                                            r_incr_w1 <= '1';
                                        end if;
                                    end if;
                                else
                                    -- Increment c1
                                    -- Don't reset psums, but remove values from iact & wght buffers
                                    r_count_c1 <= r_count_c1 + 1;
                                    r_count_w1 <= 0;

                                    if r_count_c1 /= w_c1 - 1 then
                                        -- Only perform iact & wght shrink if not last c1 done!
                                        r_state <= s_incr_c1;
                                    else
                                        -- Increment h1, process next kernel row
                                        r_state    <= s_incr_h1;
                                        r_count_h1 <= r_count_h1 + 1;
                                        r_count_c1 <= 0;
                                    end if;
                                end if;
                            else
                            end if;
                        else
                        -- Switch to output state done in incr_h1 state
                        end if;
                    else
                    -- DONE for now (not tiled for PSUM Line Buffer Length)
                    end if;
                elsif r_state = s_incr_c1 then
                    -- Delay counter after shrinking for new values to arrive in the buffer
                    if r_count_w1 /= 2 then
                        r_count_w1 <= r_count_w1 + 1;
                    else
                        r_count_w1   <= 0;
                        r_count_c0w0 <= 0;
                        r_state      <= s_calculate;
                    end if;
                elsif r_state = s_incr_h1 then
                    -- Delay counter after shrinking for new values to arrive in the buffer
                    if r_count_w1 /= 2 then
                        r_count_w1 <= r_count_w1 + 1;
                    elsif r_count_h1 = i_kernel_size then
                        -- Increment h2
                        -- Output intermediate results. Reset Psum and Iact buffer. Wait.
                        r_count_w1   <= 0;
                        r_count_c0w0 <= 0;
                        r_count_h1   <= 0;
                        r_count_h2   <= r_count_h2 + 1;
                        r_state      <= s_output;
                    else
                        r_count_w1   <= 0;
                        r_count_c0w0 <= 0;
                        r_state      <= s_calculate;
                    end if;
                elsif r_state = s_output then
                    -- Command counter for output commands (psum accumulation and psum read)
                    if r_count_c0w0 /= w_m0 + 4 then                                                                                                                     -- i_kernel_size + w_m0 then /* TODO Change to allow for multiple kernel data to be output */
                        if r_count_w1 /= w_w1 - 1 then
                            r_count_w1 <= r_count_w1 + 1;
                        else
                            r_count_w1   <= 0;
                            r_count_c0w0 <= r_count_c0w0 + 1;
                        end if;
                    else
                        -- Delay counter after shrinking for new values to arrive in the buffer
                        if r_count_w1 /= 2 then                                                                                                                          -- r_W1 - 1 then /* TODO changed - check! */
                            r_count_w1 <= r_count_w1 + 1;
                        elsif r_count_h2 = w_h2 then
                            -- All h2 done and output
                            r_done <= '1';
                        else
                            r_count_c1   <= 0;
                            r_count_w1   <= 0;
                            r_count_c0w0 <= 0;
                            r_state      <= s_calculate;
                        end if;
                    -- Output done, reset psum etc?
                    end if;
                end if;
            end if;
        end if;

    end process p_command_counter;

    p_iact_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_iact       <= (others => c_lb_idle);
            r_read_offset_iact   <= (others => (others => '0'));
            r_update_offset_iact <= (others => (others => '0'));
        elsif rising_edge(clk) then
            r_update_offset_iact <= (others => (others => '0'));

            if w_init_done = '1' and o_enable = '1' then
                if r_state = s_calculate then
                    if r_incr_w1 = '1' then
                        -- shift kernel - increment w1
                        if r_count_c1 /= w_c1 - 1 then
                            r_read_offset_iact <= (others => std_logic_vector(to_unsigned(w_c0, addr_width_iact)));
                        else
                            r_read_offset_iact <= (others => std_logic_vector(to_unsigned(w_c0_last_c1, addr_width_iact)));
                        end if;
                        r_command_iact <= (others => c_lb_shrink);
                    elsif r_count_w1 = w_w1 then
                        -- Tile y change

                        r_command_iact     <= (others => c_lb_idle);
                        r_read_offset_iact <= (others => (others => '0'));
                    else
                        r_command_iact     <= (others => c_lb_read);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(r_count_c0w0, addr_width_iact)));
                    end if;
                -- command_iact <=
                -- update_offset_iact <=
                -- read_offset_iact <=
                elsif r_state = s_incr_c1 then
                    r_command_iact     <= (others => c_lb_idle);
                    r_read_offset_iact <= (others => (others => '0'));

                    if r_count_w1 = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * w_c0 - w_c0, addr_width_iact)));
                    end if;
                elsif r_state = s_incr_h1 then
                    r_command_iact     <= (others => c_lb_idle);
                    r_read_offset_iact <= (others => (others => '0'));

                    if r_count_w1 = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * w_c0_last_c1 - w_c0_last_c1, addr_width_iact)));
                    end if;
                elsif r_state = s_output then
                    r_command_iact     <= (others => c_lb_idle);
                    r_read_offset_iact <= (others => (others => '0'));

                    if r_count_c0w0 = 0 and r_count_w1 = 0 then
                        if w_c1 > 1 then
                        -- r_command_iact     <= (others => c_lb_shrink);
                        -- r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * w_c0_last_c1 - w_c0_last_c1, addr_width_iact)));
                        else
                        -- r_command_iact     <= (others => c_lb_shrink);
                        -- r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * i_channels - i_channels, addr_width_iact)));
                        end if;
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

            if w_init_done = '1' and o_enable = '1' then
                if r_state = s_calculate then
                    if r_incr_w1 = '1' then
                        -- shift kernel - increment w1
                        r_command_wght     <= (others => c_lb_idle);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(0, addr_width_wght)));
                    elsif r_count_w1 = w_w1 then
                        -- Tile y change

                        r_command_wght     <= (others => c_lb_idle);
                        r_read_offset_wght <= (others => (others => '0'));
                    else
                        r_command_wght     <= (others => c_lb_read);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(r_count_c0w0, addr_width_wght)));
                    end if;
                elsif r_state = s_incr_c1 then
                    r_command_wght     <= (others => c_lb_idle);
                    r_read_offset_wght <= (others => (others => '0'));

                    if r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_kernel_size * o_c0, addr_width_wght)));
                    end if;
                elsif r_state = s_incr_h1 then
                    r_command_wght     <= (others => c_lb_idle);
                    r_read_offset_wght <= (others => (others => '0'));

                    if r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_kernel_size * o_c0_last_c1, addr_width_wght)));
                    end if;
                elsif r_state = s_output then
                    r_command_wght <= (others => c_lb_idle);

                    /*if w_c1 > 1 then
                        if r_count_c0w0 = 0 and r_count_w1 = 0 then
                            r_command_wght     <= (others => c_lb_shrink);
                            r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_kernel_size * o_c0_last_c1, addr_width_wght)));
                        end if;
                    end if;*/
                end if;
            end if;
        end if;

    end process p_wght_commands;

    g_psum_pe_commands : for i in 0 to size_y - 1 generate

        w_output_sequence(i) <= i;

        -- Commands to control dataflow within PE (psum / mult / passthrough)
        p_command : process (clk, rstn) is
        begin

            if not rstn then
                r_command(i) <= c_pe_gemm_mult;
            elsif rising_edge(clk) then
                if r_state = s_output then
                    if r_count_c0w0 = i + 2 then
                        r_command(i) <= c_pe_conv_mult;            -- c_pe_gemm_psum;
                    elsif r_count_c0w0 > size_y + 3 then
                        r_command(i) <= c_pe_gemm_mult;
                    elsif r_count_w1 = 2 and r_count_c0w0 > 1 then
                        r_command(i) <= c_pe_conv_pass;            -- c_pe_gemm_psum;
                    else
                    -- r_command(i) <= c_pe_conv_psum;
                    end if;
                elsif r_state = s_calculate then
                    r_command(i) <= c_pe_gemm_mult;
                end if;
            end if;

        end process p_command;

        -- Control PSUM commands (idle/read/read_update)
        p_psum_commands : process (clk, rstn) is
        begin

            if not rstn then
                r_command_psum(i)       <= c_lb_idle;
                r_read_offset_psum(i)   <= (others => '0');
                r_update_offset_psum(i) <= (others => '0');
            elsif rising_edge(clk) then
                if w_init_done = '1' and o_enable = '1' then
                    if r_state = s_calculate then
                        if r_incr_w1 = '1' then
                            -- shift kernel - increment w1
                            r_command_psum(i)       <= c_lb_idle;
                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(0, addr_width_psum));
                            r_update_offset_psum(i) <= r_read_offset_psum(i);
                        elsif r_count_w1 = w_w1 then
                            -- Tile y change
                            r_command_psum(i)       <= c_lb_idle;
                            r_read_offset_psum(i)   <= (others => '0');
                            r_update_offset_psum(i) <= (others => '0');
                        else
                            r_command_psum(i)       <= c_lb_read_update;
                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                            r_update_offset_psum(i) <= r_read_offset_psum(i);
                        end if;
                    elsif r_state = s_incr_c1 or r_state = s_incr_h1 then
                        r_command_psum(i)       <= c_lb_idle;
                        r_read_offset_psum(i)   <= (others => '0');
                        r_update_offset_psum(i) <= (others => '0');
                    elsif r_state = s_output then
                        if i < w_m0 * i_kernel_size then
                        end if;
                        r_command_psum(i)       <= c_lb_idle;
                        r_read_offset_psum(i)   <= (others => '0');
                        r_update_offset_psum(i) <= (others => '0');

                        if r_count_c0w0 = w_m0 + 3 then
                            -- Remove all stored psums, new tile (h1)
                            if r_count_w1 = 0 then
                                r_command_psum(i)     <= c_lb_shrink;
                                r_read_offset_psum(i) <= std_logic_vector(to_unsigned(i_image_x - i_kernel_size + 1, addr_width_psum));
                            end if;
                        else
                            -- Sum psums vertically across accelerator. Different kernels summed to their top row respectively
                            --

                            if r_count_c0w0 = i + 2 then
                                r_command_psum(i) <= c_lb_read;
                            /*elsif w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 2 and r_count_c0w0 < i_kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read_update;
                            elsif r_count_c0w0 = i_kernel_size then
                                r_command_psum(i) <= c_lb_idle;
                            elsif w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 1 + i and r_count_c0w0 >= i_kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read;*/
                            else
                                r_command_psum(i) <= c_lb_idle;
                            end if;

                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                            r_update_offset_psum(i) <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                        end if;
                    end if;
                end if;
            end if;

        end process p_psum_commands;

    end generate g_psum_pe_commands;

    control_init_inst : if g_control_init = true generate

        control_init_inst : entity accel.control_init(alternative_rs_dataflow)
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
                addr_width_wght  => addr_width_wght
            )
            port map (
                clk            => clk,
                rstn           => rstn,
                o_status       => w_init_done,
                i_start        => i_start_init,
                o_c1           => w_c1,
                o_w1           => w_w1,
                o_h2           => w_h2,
                o_m0           => w_m0,
                o_m0_last_m1   => w_m0_last_m1,
                o_rows_last_h2 => w_rows_last_h2,
                o_c0           => w_c0,
                o_c0_last_c1   => w_c0_last_c1,
                o_c0w0         => w_c0w0,
                o_c0w0_last_c1 => w_c0w0_last_c1,
                i_image_x      => i_image_x,
                i_image_y      => i_image_y,
                i_channels     => i_channels,
                i_kernels      => i_kernels,
                i_kernel_size  => i_kernel_size
            );

    else generate

        w_c1           <= g_c1;
        w_w1           <= g_w1;
        w_h2           <= g_h2;
        w_m0           <= g_m0;
        w_m0_last_m1   <= g_m0_last_m1;
        w_rows_last_h2 <= g_rows_last_h2;
        w_c0           <= g_c0;
        w_c0_last_c1   <= g_c0_last_c1;
        w_c0w0         <= g_c0w0;
        w_c0w0_last_c1 <= g_c0w0_last_c1;
        w_init_done    <= '1';

    end generate control_init_inst;

end architecture alternative_rs_dataflow;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

architecture alternative_rs_dataflow of control is

    signal r_state : t_control_state;

    signal r_count_c0w0 : integer range 0 to max_line_length_wght;
    signal r_count_c1   : integer range 0 to 1023;
    signal r_count_w1   : integer range 0 to 1023;
    signal r_count_h2   : integer range 0 to 1023;
    signal r_count_h1   : integer range 0 to 31;

    signal w_c0w0         : integer range 0 to max_line_length_wght;
    signal w_c0w0_last_c1 : integer range 0 to max_line_length_wght;

    signal w_c0         : integer range 0 to max_line_length_wght;
    signal w_c0_last_c1 : integer range 0 to max_line_length_wght;

    signal w_h2           : integer range 0 to 1023;
    signal w_rows_last_h2 : integer range 0 to max_size_x;

    signal w_w1 : integer range 0 to max_line_length_psum;
    signal w_c1 : integer range 0 to 1023;

    signal r_incr_w1 : std_logic;

    signal w_m0         : integer range 0 to max_output_channels;
    signal r_m0_dist    : uns_array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal w_m0_last_m1 : integer range 0 to max_output_channels;

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

    signal w_output_sequence : uint10_line_t(0 to size_y - 1);

    signal r_command : command_pe_array_t(0 to size_y);

    signal r_output_throttle : std_logic;
    signal r_output_counter  : integer range 0 to 255;

begin

    o_done <= '1' when r_state = s_done else '0';

    -- unused by alternative rs dataflow, so drive with constant 0
    r_m0_dist <= (others => (others => '0'));
    o_m0_dist <= r_m0_dist;

    -- Do not stop when filling read/update pipeline
    o_enable <= i_enable_if when r_state /= s_output else -- r_count_c0w0 > 1 and
                r_output_throttle when r_state = s_output else
                '0';

    o_pause_iact <= '1' when r_state = s_output else
                    '0';

    -- allow to throttle the output phase
    -- this mechanism is very simple by just pulling o_enable low
    -- a better solution would be to drive r_command_psum with some idle commands appropriately
    p_output_throttle : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' or r_state /= s_output then
            r_output_counter <= 0;
        else
            if r_output_counter = 0 then
                r_output_counter <= 255;
            else
                r_output_counter <= r_output_counter - 1;
            end if;
        end if;

        if r_output_counter < i_params.psum_throttle then
            r_output_throttle <= '0';
        else
            r_output_throttle <= '1';
        end if;

    end process p_output_throttle;

    r_command_psum_d       <= r_command_psum when rising_edge(clk);
    r_read_offset_psum_d   <= r_read_offset_psum when rising_edge(clk);
    r_update_offset_psum_d <= r_update_offset_psum when rising_edge(clk);

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

    r_update_offset_iact <= (others => (others => '0'));
    r_update_offset_wght <= (others => (others => '0'));

    switch_state : process (all) is
    begin

        case r_state is

            when s_calculate =>

                w_mux_read_offset_psum   <= r_read_offset_psum;
                w_mux_update_offset_psum <= r_update_offset_psum;

            when others =>

                w_mux_read_offset_psum   <= r_read_offset_psum_d;
                w_mux_update_offset_psum <= r_update_offset_psum_d;

        end case;

        w_mux_command_psum <= r_command_psum_d;

    end process switch_state;

    p_command_counter : process (clk, rstn) is
    begin

        if not rstn then
            o_init_done  <= '0';
            r_count_h2   <= 0;
            r_count_w1   <= 0;
            r_count_c1   <= 0;
            r_count_c0w0 <= 0;
            r_incr_w1    <= '0';
            r_state      <= s_idle;
        elsif rising_edge(clk) then

            case r_state is

                when s_idle =>

                    o_init_done <= '0';

                    if i_start = '1' then
                        r_state <= s_init;
                    end if;

                when s_init =>

                    -- no initialization necessary for alternative rs
                    o_init_done <= '1';
                    r_state     <= s_calculate;

                when s_calculate =>

                    if o_enable = '1' then
                        r_incr_w1 <= '0';
                        if r_count_h2 /= w_h2 and r_count_h1 /= i_params.kernel_size and r_count_c1 /= w_c1 then
                            if r_count_w1 /= w_w1 then
                                if not((r_count_c0w0 = w_c0w0 - 1 and r_count_c1 /= w_c1 - 1) or
                                       (r_count_c0w0 = w_c0w0_last_c1 - 1 and r_count_c1 = w_c1 - 1)) then
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
                        -- DONE for now (not tiled for PSUM Line Buffer Length)
                        end if;
                    end if;

                when s_incr_c1 =>

                    if o_enable = '1' then
                        -- Delay counter after shrinking for new values to arrive in the buffer
                        if r_count_w1 /= 2 then
                            r_count_w1 <= r_count_w1 + 1;
                        else
                            r_count_w1   <= 0;
                            r_count_c0w0 <= 0;
                            r_state      <= s_calculate;
                        end if;
                    end if;

                when s_incr_h1 =>

                    if o_enable = '1' then
                        -- Delay counter after shrinking for new values to arrive in the buffer
                        if r_count_w1 /= 2 then
                            r_count_w1 <= r_count_w1 + 1;
                        elsif r_count_h1 = i_params.kernel_size then
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
                    end if;

                when s_output =>

                    if o_enable = '1' then
                        -- Command counter for output commands (psum accumulation and psum read)
                        if r_count_c0w0 /= w_m0 + 4 then -- i_params.kernel_size + w_m0 then /* TODO Change to allow for multiple kernel data to be output */
                            if r_count_w1 /= w_w1 - 1 then
                                r_count_w1 <= r_count_w1 + 1;
                            else
                                r_count_w1   <= 0;
                                r_count_c0w0 <= r_count_c0w0 + 1;
                            end if;
                        else
                            -- Delay counter after shrinking for new values to arrive in the buffer
                            if r_count_w1 /= 2 then
                                r_count_w1 <= r_count_w1 + 1;
                            elsif r_count_h2 = w_h2 then
                                -- All h2 done and output
                                if i_all_psum_finished = '1' then
                                    r_state <= s_done;
                                end if;
                            else
                                r_count_c1   <= 0;
                                r_count_w1   <= 0;
                                r_count_c0w0 <= 0;
                                r_state      <= s_calculate;
                            end if;
                        end if;
                    end if;

                when s_done =>

                    if i_start = '0' then
                        r_state <= s_idle;
                    end if;

            end case;

        end if;

    end process p_command_counter;

    p_iact_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_iact <= (others => c_lb_idle);
        elsif rising_edge(clk) and o_enable = '1' then

            case r_state is

                when s_calculate =>

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
                        r_command_iact <= (others => c_lb_idle);
                    else
                        r_command_iact     <= (others => c_lb_read);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(r_count_c0w0, addr_width_iact)));
                    end if;

                when s_incr_c1 =>

                    r_command_iact <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0 - w_c0, addr_width_iact)));
                    end if;

                when s_incr_h1 =>

                    r_command_iact <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0_last_c1 - w_c0_last_c1, addr_width_iact)));
                    end if;

                when s_output =>

                    r_command_iact <= (others => c_lb_idle);

                when others =>

                    null;

            end case;

        end if;

    end process p_iact_commands;

    p_wght_commands : process (clk, rstn) is
    begin

        if not rstn then
            r_command_wght <= (others => c_lb_idle);
        elsif rising_edge(clk) and o_enable = '1' then

            case r_state is

                when s_calculate =>

                    r_read_offset_wght <= (others => std_logic_vector(to_unsigned(r_count_c0w0, addr_width_wght)));

                    if r_incr_w1 = '1' or r_count_w1 = w_w1 then
                        -- shift kernel - increment w1 / Tile y change
                        r_command_wght <= (others => c_lb_idle);
                    else
                        r_command_wght <= (others => c_lb_read);
                    end if;

                when s_incr_c1 =>

                    r_command_wght <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0, addr_width_wght)));
                    end if;

                when s_incr_h1 =>

                    r_command_wght <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0_last_c1, addr_width_wght)));
                    end if;

                when s_output =>

                    r_command_wght <= (others => c_lb_idle);

                when others =>

                    null;

            end case;

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
                        r_command(i) <= c_pe_conv_mult;
                    elsif r_count_c0w0 > size_y + 3 then
                        r_command(i) <= c_pe_gemm_mult;
                    elsif r_count_w1 = 2 and r_count_c0w0 > 1 then
                        r_command(i) <= c_pe_conv_pass;
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
                r_command_psum(i) <= c_lb_idle;
            elsif rising_edge(clk) and o_enable = '1' then

                case r_state is

                    when s_calculate =>

                        r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                        r_update_offset_psum(i) <= r_read_offset_psum(i);

                        if r_incr_w1 = '1' or r_count_w1 = w_w1 then
                            -- shift kernel - increment w1 / Tile y change
                            r_command_psum(i) <= c_lb_idle;
                        else
                            r_command_psum(i) <= c_lb_read_update;
                        end if;

                    when s_incr_c1 | s_incr_h1 =>

                        r_command_psum(i) <= c_lb_idle;

                    when s_output =>

                        r_command_psum(i) <= c_lb_idle;

                        if r_count_c0w0 = w_m0 + 3 then
                            -- Remove all stored psums, new tile (h1)
                            if r_count_w1 = 0 then
                                r_command_psum(i)     <= c_lb_shrink;
                                r_read_offset_psum(i) <= std_logic_vector(to_unsigned(i_params.image_x - i_params.kernel_size + 1, addr_width_psum));
                            end if;
                        else
                            -- Move psums vertically across accelerator. No accumulation required, sums are already finished
                            if r_count_c0w0 = i + 2 then
                                r_command_psum(i) <= c_lb_read;
                            end if;

                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                            r_update_offset_psum(i) <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                        end if;

                    when others =>

                        null;

                end case;

            end if;

        end process p_psum_commands;

    end generate g_psum_pe_commands;

    w_c1           <= i_params.c1;
    w_w1           <= i_params.w1;
    w_h2           <= i_params.h2;
    w_m0           <= i_params.m0;
    w_m0_last_m1   <= i_params.m0_last_m1;
    w_rows_last_h2 <= i_params.rows_last_h2;
    w_c0           <= i_params.c0;
    w_c0_last_c1   <= i_params.c0_last_c1;
    w_c0w0         <= i_params.c0w0;
    w_c0w0_last_c1 <= i_params.c0w0_last_c1;

end architecture alternative_rs_dataflow;

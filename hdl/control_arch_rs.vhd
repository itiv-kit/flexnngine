library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

architecture rs_dataflow of control is

    signal r_state     : control_state_t;
    signal r_pad_state : padding_state_t;

    signal r_count_c0w0 : integer range 0 to max_line_length_wght;
    signal r_count_c1   : integer range 0 to 1023;
    signal r_count_w1   : integer range 0 to 1023;
    signal r_count_h2   : integer range 0 to 1023;

    signal r_kernel_cols : integer range 0 to max_kernel_size - 1;
    signal r_count_pad_x : integer range 0 to max_kernel_size - 1;
    signal r_count_w0 : integer range 0 to max_kernel_size;
    signal r_count_c0 : integer range 0 to max_line_length_wght;

    signal r_extra_offset_iact : integer range 0 to max_line_length_wght;
    signal r_extra_offset_wght : integer range 0 to max_line_length_wght;

    signal w_h2 : integer range 0 to 1023;
    signal w_c1 : integer range 0 to 1023;
    signal w_c0 : integer range 0 to max_line_length_wght;
    signal w_w1 : integer range 0 to max_line_length_psum;
    signal w_m0 : integer range 0 to max_output_channels;

    signal r_incr_w1 : std_logic;

    signal r_command_iact       : command_lb_array_t(0 to size_y - 1);
    signal r_read_offset_iact   : array_t(0 to size_y - 1)(addr_width_iact - 1 downto 0);
    signal r_update_offset_iact : array_t(0 to size_y - 1)(addr_width_iact - 1 downto 0);

    signal r_command_wght       : command_lb_array_t(0 to size_y - 1);
    signal r_read_offset_wght   : array_t(0 to size_y - 1)(addr_width_wght - 1 downto 0);
    signal r_update_offset_wght : array_t(0 to size_y - 1)(addr_width_wght - 1 downto 0);

    signal r_command_psum_d       : command_lb_array_t(0 to size_y - 1);
    signal r_read_offset_psum_d   : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);
    signal r_update_offset_psum_d : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);

    signal r_command_psum       : command_lb_array_t(0 to size_y - 1);
    signal r_read_offset_psum   : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);
    signal r_update_offset_psum : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);

    signal w_mux_read_offset_psum   : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);
    signal w_mux_update_offset_psum : array_t(0 to size_y - 1)(addr_width_psum - 1 downto 0);
    signal w_mux_command_psum       : command_lb_array_t(0 to size_y - 1);

    signal r_output_sequence : uint10_line_t(0 to size_y - 1);

    signal r_command : command_pe_array_t(0 to size_y - 1);

    signal r_m0_dist         : uns_array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal r_m0_count_idx    : integer range 0 to size_y + 1;
    signal r_m0_count_kernel : integer range 0 to size_y + 1;

begin

    o_done    <= '1' when r_state = s_done else '0';
    o_m0_dist <= r_m0_dist;

    -- Generate enable signal for PE array, propagate input fifo status from scratchpad interface
    -- Do not stop when filling read/update pipeline
    o_enable <= i_enable_if when r_state = s_calculate else
                '1' when (r_state = s_output or r_state = s_incr_w1 or r_state = s_incr_c1) else
                '0';

    -- for RS dataflow, the lowest PE row does not get c_pe_conv_pass command and thus does not pass through any data
    o_pause_iact <= '0';

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
            r_count_h2   <= 0;
            r_count_w1   <= 0;
            r_count_c1   <= 0;
            r_count_c0w0 <= 0;
            r_incr_w1    <= '0';
            r_state      <= s_idle;
        elsif rising_edge(clk) then

            case r_state is

                when s_idle =>

                    if i_start = '1' then
                        r_state <= s_init;
                    end if;

                when s_init =>

                    -- start with a partial kernel if padding is requested
                    r_kernel_cols <= i_params.kernel_size - 1 - i_params.pad_x;
                    r_count_pad_x <= 0;
                    if i_params.mode_pad /= none then -- start padding on left edge
                        r_pad_state         <= s_left;
                        r_extra_offset_iact <= 0;
                        r_extra_offset_wght <= w_c0 * (i_params.kernel_size - i_params.pad_x - 1);
                    else
                        r_pad_state <= s_none;
                    end if;

                    if o_init_done = '1' then
                        r_state <= s_calculate;
                    end if;

                when s_calculate =>

                    if o_enable = '1' then
                        r_incr_w1 <= '0';
                        if r_count_h2 /= w_h2 and r_count_c1 /= w_c1 then
                            if r_count_w1 /= w_w1 then
                                r_count_c0w0 <= r_count_c0w0 + 1;
                                if r_count_c0 /= w_c0 - 1 then
                                    r_count_c0 <= r_count_c0 + 1;
                                else
                                    if r_count_w0 /= r_kernel_cols then
                                        r_count_c0 <= 0;
                                        r_count_w0 <= r_count_w0 + 1;
                                    else
                                        -- shift kernel - increment w1
                                        r_state <= s_incr_w1;
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
                                    -- Last c1 done
                                    -- Tile change for tile_y
                                    -- Output intermediate results. Reset Psum and Iact buffer. Wait.

                                    r_state    <= s_output;
                                    r_count_h2 <= r_count_h2 + 1;
                                end if;
                            end if;
                        else
                        -- DONE for now (not tiled for PSUM Line Buffer Length)
                        end if;
                    end if;

                when s_incr_w1 =>

                    -- no need to check for o_enable - if buffers are empty, we can still shrink, return to s_calculate and stall there
                    r_incr_w1 <= '0';
                    r_state   <= s_calculate;
                    if r_incr_w1 = '0' then
                        r_count_w0   <= 0;
                        r_count_c0   <= 0;
                        r_count_c0w0 <= 0;
                        r_count_w1   <= r_count_w1 + 1;

                        if r_pad_state = s_left then -- padding on left side
                            r_kernel_cols       <= r_kernel_cols + 1;
                            r_count_pad_x       <= r_count_pad_x + 1;
                            r_extra_offset_iact <= 0;
                            r_extra_offset_wght <= r_extra_offset_wght - w_c0;
                            if r_kernel_cols = i_params.kernel_size - 2 then
                                r_pad_state <= s_none;
                            end if;

                        elsif r_pad_state = s_right then -- padding on right side
                            r_extra_offset_iact <= r_extra_offset_iact + w_c0;
                            r_extra_offset_wght <= 0;
                            if r_count_w1 = w_w1 - 1 then -- prepare for next output channel, reset padding to left
                                r_pad_state         <= s_left;
                                r_extra_offset_iact <= 0;
                                r_extra_offset_wght <= w_c0 * (i_params.kernel_size - i_params.pad_x - 1);
                            else
                                r_kernel_cols <= r_kernel_cols - 1;
                                r_count_pad_x <= r_count_pad_x - 1;
                            end if;

                        else -- only shrink if not within padding columns

                            r_incr_w1           <= '1'; -- trigger buffer shrinks for iact & wght
                            r_state             <= s_incr_w1; -- stay in this state for one more cycle to clear r_incr_w1
                            r_extra_offset_iact <= 0;
                            r_extra_offset_wght <= 0;
                            if i_params.mode_pad /= none and r_count_w1 = w_w1 - i_params.pad_x - 1 then -- switch to padding on right image edge
                                r_pad_state   <= s_right;
                                r_kernel_cols <= r_kernel_cols - 1;
                                r_count_pad_x <= r_count_pad_x - 1;
                            end if;
                        end if;
                    end if;

                when s_incr_c1 =>

                    -- Delay counter after shrinking for new values to arrive in the buffer
                    if r_count_w1 /= 2 then
                        r_count_w1 <= r_count_w1 + 1;
                    else
                        r_count_w1   <= 0;
                        r_count_c0w0 <= 0;
                        r_state      <= s_calculate;
                    end if;

                -- unused in rs dataflow
                when s_incr_h1 =>

                    null;

                when s_output =>

                    -- Command counter for output commands (psum accumulation and psum read)
                    if r_count_c0w0 /= i_params.kernel_size + w_m0 + 1 then -- i_params.kernel_size + w_m0 then /* TODO Change to allow for multiple kernel data to be output */
                        if r_count_w1 /= w_w1 - 1 then
                            r_count_w1 <= r_count_w1 + 1;
                        else
                            r_count_w1   <= 0;
                            r_count_c0w0 <= r_count_c0w0 + 1;
                        end if;
                    else
                        -- Delay counter after shrinking for new values to arrive in the buffer
                        if r_count_w1 /= 2 then -- r_W1 - 1 then /* TODO changed - check! */
                            r_count_w1 <= r_count_w1 + 1;
                        elsif r_count_h2 = w_h2 then
                            if i_all_psum_finished = '1' then
                                r_state <= s_done;
                            end if;
                        else
                            r_count_c1   <= 0;
                            r_count_w1   <= 0;
                            r_count_c0w0 <= 0;
                            r_state      <= s_calculate;
                        end if;
                    -- Output done, reset psum etc?
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

                    if r_count_w1 = w_w1 then
                        -- Tile y change
                        r_command_iact <= (others => c_lb_idle);
                    else
                        r_command_iact     <= (others => c_lb_read);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(r_count_c0w0 + r_extra_offset_iact, addr_width_iact)));
                    end if;

                when s_incr_w1 =>

                    if r_incr_w1 = '1' then
                        -- shift kernel - increment w1
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned(w_c0, addr_width_iact)));
                        r_command_iact <= (others => c_lb_shrink);
                    end if;

                when s_incr_c1 =>

                    r_command_iact <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_iact     <= (others => c_lb_shrink);
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned((i_params.kernel_size - 1) * w_c0, addr_width_iact)));
                    end if;

                when s_output =>

                    r_command_iact <= (others => c_lb_idle);

                    if r_count_c0w0 = 0 and r_count_w1 = 0 then
                        r_command_iact <= (others => c_lb_shrink);
                        -- for c1 = 1, c0 must be set to inputchs (which equals c0_last_c1)
                        r_read_offset_iact <= (others => std_logic_vector(to_unsigned((i_params.kernel_size - 1) * w_c0, addr_width_iact)));
                    end if;

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

                    if r_incr_w1 = '1' or r_count_w1 = w_w1 then
                        -- Tile y change
                        r_command_wght <= (others => c_lb_idle);
                    else
                        r_command_wght     <= (others => c_lb_read);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(r_count_c0w0 + r_extra_offset_wght, addr_width_wght)));
                    end if;

                when s_incr_w1 =>

                    -- shift kernel - increment w1
                    r_command_wght <= (others => c_lb_idle);

                when s_incr_c1 =>

                    r_command_wght <= (others => c_lb_idle);

                    if r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0, addr_width_wght)));
                    end if;

                when s_output =>

                    r_command_wght <= (others => c_lb_idle);

                    if r_count_c0w0 = 0 and r_count_w1 = 0 then
                        r_command_wght     <= (others => c_lb_shrink);
                        r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_params.kernel_size * w_c0, addr_width_wght)));
                    end if;

                when others =>

                    null;

            end case;

        end if;

    end process p_wght_commands;

    g_psum_pe_commands : for i in 0 to size_y - 1 generate

        -- Commands to control dataflow within PE (psum / mult / passthrough)
        p_command : process (clk, rstn) is
        begin

            if not rstn then
                r_command(i) <= c_pe_conv_mult;
            elsif rising_edge(clk) then
                r_output_sequence(i) <= (i - (to_integer(r_m0_dist(i))) * i_params.kernel_size + i_params.kernel_size);

                case r_state is

                    when s_output =>

                        if r_count_w1 = 1 and r_count_c0w0 < i_params.kernel_size then
                            r_command(i) <= c_pe_conv_psum;
                        elsif to_integer(r_m0_dist(i)) = 0 then
                            r_command(i) <= c_pe_conv_psum;
                        elsif r_count_c0w0 > i_params.kernel_size then
                            if r_output_sequence(i) = i_params.kernel_size - r_count_c0w0 - 1 + to_integer(r_m0_dist(i)) then
                                r_command(i) <= c_pe_conv_psum;
                            elsif r_count_w1 = 2 and i /= size_y - 1 then
                                r_command(i) <= c_pe_conv_pass;
                            end if;
                        end if;

                    when s_calculate =>

                        r_command(i) <= c_pe_conv_mult;

                    when others =>

                        null;

                end case;

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

                        if r_incr_w1 = '1' or r_count_w1 = w_w1 then
                            -- shift kernel - increment w1 / Tile y change
                            r_command_psum(i) <= c_lb_idle;
                        else
                            r_command_psum(i)       <= c_lb_read_update;
                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                            r_update_offset_psum(i) <= r_read_offset_psum(i);
                        end if;

                    when s_output =>

                        r_command_psum(i) <= c_lb_idle;

                        if r_count_c0w0 = i_params.kernel_size + w_m0 then /* TODO prob. change i_params.kernel_size + w_m0*/
                            -- Remove all stored psums, new tile (h1)
                            if r_count_w1 = 0 then
                                r_command_psum(i)     <= c_lb_shrink;
                                r_read_offset_psum(i) <= std_logic_vector(to_unsigned(i_params.w1, addr_width_psum));
                            end if;
                        else
                            -- Sum psums vertically across accelerator. Different kernels summed to their top row respectively

                            if r_output_sequence(i) = i_params.kernel_size - r_count_c0w0 - 1 and r_count_c0w0 < i_params.kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read;
                            elsif r_output_sequence(i) = i_params.kernel_size - r_count_c0w0 - 2 and r_count_c0w0 < i_params.kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read_update;
                            elsif r_count_c0w0 = i_params.kernel_size then
                                r_command_psum(i) <= c_lb_idle;
                            elsif r_output_sequence(i) = i_params.kernel_size - r_count_c0w0 - 1 + to_integer(r_m0_dist(i)) and r_count_c0w0 >= i_params.kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read;
                            else
                                r_command_psum(i) <= c_lb_idle;
                            end if;

                            r_read_offset_psum(i)   <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                            r_update_offset_psum(i) <= std_logic_vector(to_unsigned(r_count_w1, addr_width_psum));
                        end if;

                    when others =>

                        r_command_psum(i) <= c_lb_idle;

                end case;

            end if;

        end process p_psum_commands;

    end generate g_psum_pe_commands;

    w_c1   <= i_params.c1;
    w_w1   <= i_params.w1;
    w_h2   <= i_params.h2;
    w_m0   <= i_params.m0;
    w_c0   <= i_params.c0_last_c1 when r_count_c1 = w_c1 - 1 else i_params.c0;

    p_init_m0_dist : process (clk, rstn) is

        variable v_m0_count : integer range 0 to size_y + 1;

    begin

        if not rstn then
            r_m0_count_idx    <= 0;
            r_m0_count_kernel <= 0;
            v_m0_count        := 1;
            r_m0_dist         <= (others => (others => '0'));
            o_init_done       <= '0';
        elsif rising_edge(clk) then
            if r_state = s_idle then
                r_m0_count_idx    <= 0;
                r_m0_count_kernel <= 0;
                v_m0_count        := 1;
                o_init_done       <= '0';
            elsif r_state = s_init then
                if r_m0_count_idx /= size_y then
                    r_m0_count_idx <= r_m0_count_idx + 1;
                    if r_m0_count_kernel /= i_params.kernel_size then
                        r_m0_count_kernel         <= r_m0_count_kernel + 1;
                        r_m0_dist(r_m0_count_idx) <= to_unsigned(v_m0_count, addr_width_y);
                    else
                        if r_m0_count_idx + i_params.kernel_size <= size_y then -- check if one more kernel can be mapped
                            r_m0_count_kernel         <= 1;
                            v_m0_count                := v_m0_count + 1;
                            r_m0_dist(r_m0_count_idx) <= to_unsigned(v_m0_count, addr_width_y);
                        end if;
                    end if;
                else
                    o_init_done <= '1';
                end if;
            end if;
        end if;

    end process p_init_m0_dist;

end architecture rs_dataflow;

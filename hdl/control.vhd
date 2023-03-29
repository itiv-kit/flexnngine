library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

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
        o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
    );
end entity control;

architecture rtl of control is

    component control_init is
        generic (
            size_x    : positive;
            size_y    : positive;
            size_rows : positive;

            addr_width_rows : positive;
            addr_width_y    : positive;
            addr_width_x    : positive;

            line_length_iact : positive;
            addr_width_iact  : positive;
            line_length_psum : positive;
            addr_width_psum  : positive;
            line_length_wght : positive;
            addr_width_wght  : positive
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            o_c1           : out   integer range 0 to 1023;
            o_w1           : out   integer range 0 to 1023;
            o_h2           : out   integer range 0 to 1023;
            o_m0           : out   integer range 0 to 1023;
            o_m0_dist      : out   array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
            o_m0_last_m1   : out   integer range 0 to 1023;
            o_rows_last_h2 : out   integer range 0 to 1023;
            o_c0           : out   integer range 0 to 1023;
            o_c0_last_c1   : out   integer range 0 to 1023;
            o_c0w0         : out   integer range 0 to 1023;
            o_c0w0_last_c1 : out   integer range 0 to 1023;

            i_image_x     : in    integer range 0 to 1023;
            i_image_y     : in    integer range 0 to 1023;
            i_channels    : in    integer range 0 to 4095;
            i_kernels     : in    integer range 0 to 4095;
            i_kernel_size : in    integer range 0 to 32;

            o_status : out   std_logic;
            i_start  : in    std_logic
        );
    end component control_init;
    
    for all : control_init use entity work.control_init (rs_dataflow ) ;

    signal w_init_done : std_logic;

    signal r_count_c0w0 : integer; -- range 0 to 511
    signal r_count_c1   : integer range 0 to 1023;
    signal r_count_w1   : integer range 0 to 1023;
    signal r_count_h2   : integer range 0 to 1023;

    signal w_c0w0         : integer range 0 to 1023;
    signal w_c0w0_last_c1 : integer range 0 to 1023;

    signal w_c0         : integer range 0 to 1023;
    signal w_c0_last_c1 : integer range 0 to 1023;

    signal w_h2           : integer range 0 to 1023;
    signal w_rows_last_h2 : integer range 0 to 1023;

    signal w_w1 : integer range 0 to 1023;
    signal w_c1 : integer range 0 to 1023;

    signal r_incr_w1 : std_logic;

    signal w_m0      : integer range 0 to 1023;
    signal w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
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

    signal i_start_d : std_logic_vector(3 downto 0);

    signal r_done : std_logic;

    signal r_m0_dist         : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);
    signal r_m0_count_idx    : integer range 0 to size_y + 1;
    signal r_m0_count_kernel : integer range 0 to size_y + 1;
    signal r_init_done       : std_logic;

begin

    o_new_output <= '1' when r_count_c0w0 = 2 and r_count_w1 = 0 and r_state = s_output else
                    '0';

    r_command_psum_d       <= r_command_psum when rising_edge(clk);
    r_read_offset_psum_d   <= r_read_offset_psum when rising_edge(clk);
    r_update_offset_psum_d <= r_update_offset_psum when rising_edge(clk);

    o_status <= w_init_done;

    o_c0_last_c1 <= w_c0_last_c1;
    o_c0         <= w_c0;

    o_c1      <= w_c1;
    o_w1      <= w_w1;
    o_h2      <= w_h2;
    o_m0      <= w_m0;
    o_m0_dist <= w_m0_dist;

    i_start_d(0) <= '1' when i_start ='1';
    -- Do not stop when filling read/update pipeline
    o_enable <= i_start when r_count_c0w0 > 1 and r_state /= s_output else
                '1' when i_start_d(0) = '1' else
                '1' when r_state = s_output else
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

            when others => 

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
                                    -- Last c1 done
                                    -- Tile change for tile_y
                                    -- Output intermediate results. Reset Psum and Iact buffer. Wait.

                                    r_state    <= s_output;
                                    r_count_h2 <= r_count_h2 + 1;
                                end if;
                            end if;
                        else
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
                elsif r_state = s_output then
                    -- Command counter for output commands (psum accumulation and psum read)
                    if r_count_c0w0 /= i_kernel_size + w_m0 + 1 then                                                                                                 -- i_kernel_size + w_m0 then /* TODO Change to allow for multiple kernel data to be output */
                        if r_count_w1 /= w_w1 - 1 then
                            r_count_w1 <= r_count_w1 + 1;
                        else
                            r_count_w1   <= 0;
                            r_count_c0w0 <= r_count_c0w0 + 1;
                        end if;
                    else
                        -- Delay counter after shrinking for new values to arrive in the buffer
                        if r_count_w1 /= 2 then                                                                                                                      -- r_W1 - 1 then /* TODO changed - check! */
                            r_count_w1 <= r_count_w1 + 1;
                        elsif r_count_h2 = w_h2 then
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
                elsif r_state = s_output then
                    r_command_iact     <= (others => c_lb_idle);
                    r_read_offset_iact <= (others => (others => '0'));

                    if r_count_c0w0 = 0 and r_count_w1 = 0 then
                        if w_c1 > 1 then
                            r_command_iact     <= (others => c_lb_shrink);
                            r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * w_c0_last_c1 - w_c0_last_c1, addr_width_iact)));
                        else
                            r_command_iact     <= (others => c_lb_shrink);
                            r_read_offset_iact <= (others => std_logic_vector(to_unsigned(i_kernel_size * i_channels - i_channels, addr_width_iact)));
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
                elsif r_state = s_output then
                    r_command_wght <= (others => c_lb_idle);

                    if w_c1 > 1 then
                        if r_count_c0w0 = 0 and r_count_w1 = 0 then
                            r_command_wght     <= (others => c_lb_shrink);
                            r_read_offset_wght <= (others => std_logic_vector(to_unsigned(i_kernel_size * o_c0_last_c1, addr_width_wght)));
                        end if;
                    end if;
                end if;
            end if;
        end if;

    end process p_wght_commands;

    g_psum_pe_commands : for i in 0 to size_y - 1 generate

        w_output_sequence(i) <= (i - (to_integer(unsigned(w_m0_dist(i)))) * i_kernel_size + i_kernel_size);

        -- Commands to control dataflow within PE (psum / mult / passthrough)
        p_command : process (clk, rstn) is
        begin

            if not rstn then
                r_command(i) <= c_pe_conv_mult;
            elsif rising_edge(clk) then
                if r_state = s_output and r_count_w1 = 1 and r_count_c0w0 < i_kernel_size then
                    r_command(i) <= c_pe_conv_psum;
                elsif r_state = s_output and to_integer(unsigned(w_m0_dist(i))) = 0 then
                    r_command(i) <= c_pe_conv_psum;
                elsif r_state = s_output and r_count_c0w0 > i_kernel_size then
                    if w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 1 + to_integer(unsigned(w_m0_dist(i))) then
                        r_command(i) <= c_pe_conv_psum;
                    elsif r_count_w1 = 2 then
                        r_command(i) <= c_pe_conv_pass;
                    else
                    -- r_command(i) <= c_pe_conv_psum;
                    end if;
                elsif r_state = s_calculate then
                    r_command(i) <= c_pe_conv_mult;
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
                    elsif r_state = s_incr_c1 then
                        r_command_psum(i)       <= c_lb_idle;
                        r_read_offset_psum(i)   <= (others => '0');
                        r_update_offset_psum(i) <= (others => '0');
                    elsif r_state = s_output then
                        if i < w_m0 * i_kernel_size then
                        end if;
                        r_command_psum(i)       <= c_lb_idle;
                        r_read_offset_psum(i)   <= (others => '0');
                        r_update_offset_psum(i) <= (others => '0');

                        if r_count_c0w0 = i_kernel_size + w_m0 then /* TODO prob. change i_kernel_size + w_m0*/
                            -- Remove all stored psums, new tile (h1)
                            if r_count_w1 = 0 then
                                r_command_psum(i)     <= c_lb_shrink;
                                r_read_offset_psum(i) <= std_logic_vector(to_unsigned(i_image_x - i_kernel_size + 1, addr_width_psum));
                            end if;
                        else
                            -- Sum psums vertically across accelerator. Different kernels summed to their top row respectively
                            --

                            if w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 1 and r_count_c0w0 < i_kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read;
                            elsif w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 2 and r_count_c0w0 < i_kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read_update;
                            elsif r_count_c0w0 = i_kernel_size then
                                r_command_psum(i) <= c_lb_idle;
                            elsif w_output_sequence(i) = i_kernel_size - r_count_c0w0 - 1 + to_integer(unsigned(w_m0_dist(i))) and r_count_c0w0 >= i_kernel_size + 1 then
                                r_command_psum(i) <= c_lb_read;
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

        control_init_inst : component control_init
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
                o_m0_dist      => w_m0_dist,
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
        w_m0_dist      <= r_m0_dist;
        w_rows_last_h2 <= g_rows_last_h2;
        w_c0           <= g_c0;
        w_c0_last_c1   <= g_c0_last_c1;
        w_c0w0         <= g_c0w0;
        w_c0w0_last_c1 <= g_c0w0_last_c1;
        w_init_done    <= r_init_done;

        p_init_m0_dist : process (clk, rstn) is

            variable v_m0_count : integer range 0 to size_y + 1;
    
        begin
    
            if not rstn then
                r_m0_count_idx    <= 0;
                r_m0_count_kernel <= 0;
                v_m0_count        := 1;
                r_m0_dist         <= (others => (others => '0'));
                r_init_done       <= '0';
            elsif rising_edge(clk) then
                if i_start_init = '1' then
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
                    else
                        r_init_done    <= '1';
                    end if;
                end if;
            end if;
    
        end process p_init_m0_dist;

    end generate control_init_inst;

end architecture rtl;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator_psum is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_x : positive := 3;

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

        i_w1         : in    integer range 0 to 1023;
        i_m0         : in    integer range 0 to 1023;
        i_h2         : in    integer range 0 to 1023;
        i_new_output : in    std_logic;

        i_valid_psum_out    : in    std_logic_vector(size_x - 1 downto 0);
        i_gnt_psum_binary_d : in    std_logic_vector(addr_width_x - 1 downto 0);
        i_command_psum      : in    command_lb_t;
        i_empty_psum_fifo   : in    std_logic_vector(size_x - 1 downto 0);
        i_psums_valid       : in    std_logic_vector(size_x - 1 downto 0);

        o_address_psum : out   std_logic_vector(addr_width_psum_mem - 1 downto 0)
    );
end entity address_generator_psum;

architecture rtl of address_generator_psum is

    component mux is
        generic (
            input_width   : natural;
            input_num     : natural;
            address_width : natural
        );
        port (
            v_i : in    array_t(0 to input_num - 1)(input_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   std_logic_vector(input_width - 1 downto 0)
        );
    end component mux;

    signal r_address_psum              : array_t(0 to size_x - 1)(addr_width_psum_mem - 1 downto 0);
    signal r_address_offsets_psum      : array_t(0 to size_x - 1)(addr_width_psum_mem - 1 downto 0);
    signal r_address_offsets_psum_done : std_logic;
    signal r_address_offsets_count_x   : integer range 0 to size_x;
    signal r_empty_fifo_d              : array_t(0 to 2)(size_x - 1 downto 0);

    signal r_count_w1 : int_line_t(0 to size_x - 1);
    signal r_start    : std_logic_vector(size_x - 1 downto 0);

    signal r_test         : std_logic_vector(size_x - 1 downto 0);
    signal r_delay_offset : std_logic_vector(10 downto 0); /* TODO depending on the clk_sp / clk factor */

    /*signal r_output_row_valid          : std_logic_row_col_t(0 to i_m0, 0 to 1023);
    signal r_address_psum_ms           : array_row_col_t(0 to size_x - 1, 0 to i_m0)(addr_width_psum_mem - 1 downto 0);
    signal r_count_m0                  : int_line_t(0 to size_x - 1);
    signal r_count_w1                   : int_line_t(0 to size_x - 1);
    signal r_count_h2                  : int_line_t(0 to size_x - 1);
    signal r_offset_m0                 : int_line_t(0 to 1023);
    signal r_count_m0_init             : integer range 0 to 1023;
    signal r_offset_m0_done            : std_logic;*/

begin

    r_empty_fifo_d <= i_empty_psum_fifo & r_empty_fifo_d(0 to 1) when rising_edge(clk);

    -- Multiplex addresses for PE colums to interface the single Psum scratchpad
    mux_psum_adr : component mux
        generic map (
            input_width   => addr_width_psum_mem,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i => r_address_psum,
            sel => i_gnt_psum_binary_d,
            z_o => o_address_psum
        );

    /*-- Create output map of valid output rows
    p_create_output_map : process(clk, rstn) is
    begin

        if not rstn then
            r_count_m0_init <= 0;
            r_offset_m0 <= (others => 0);
            r_offset_m0_done <= '0';
        elsif rising_edge(clk) then
            if r_address_offsets_psum_done = '1' and r_offset_m0_done = '0' then
                if r_count_m0_init /= i_m0 then
                    r_offset_m0(r_count_m0_init + 1) <= r_offset_m0(r_count_m0_init) + (to_integer(unsigned(r_address_offsets_psum(size_x - 1))) + i_w1) * i_h2;
                    r_count_m0_init <= r_count_m0_init + 1;
                else
                    r_offset_m0_done <= '1';
                end if;
            end if;
        end if;

    end process p_create_output_map;*/

    -- Calculate offset for PE columns / output rows
    p_calc_psum_offsets : process (clk, rstn) is
    begin

        if not rstn then
            r_address_offsets_psum      <= (others => (others => '0'));
            r_address_offsets_psum_done <= '0';
            r_address_offsets_count_x   <= 0;
            r_delay_offset              <= (others => '0');
        elsif rising_edge(clk) then
            r_delay_offset <= r_delay_offset(r_delay_offset'length - 2 downto 0) & '0';
            if i_start = '1' and r_address_offsets_psum_done = '0' then
                if r_address_offsets_count_x /= size_x - 1 then
                    r_address_offsets_psum(r_address_offsets_count_x + 1) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_offsets_psum(r_address_offsets_count_x)) + i_w1 * i_m0), addr_width_psum_mem));
                    r_address_offsets_count_x                             <= r_address_offsets_count_x + 1;
                else
                    r_address_offsets_psum_done <= '1';
                end if;
            elsif r_address_offsets_psum_done = '1' and i_new_output = '1' and (or r_delay_offset = '0') then                                                                                                           -- i_command_psum = c_lb_shrink then /* TODO MAY BE TOO LATE FOR SMALL KERNELS? */
                r_address_offsets_psum_done <= '0';                                                                                                                                                                     -- Tile h2 change
                r_address_offsets_count_x   <= 0;
                r_address_offsets_psum(0)   <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_offsets_psum(size_x - 1)) + i_w1 * i_m0), addr_width_psum_mem));
                r_delay_offset              <= r_delay_offset(r_delay_offset'length - 2 downto 0) & '1';
            end if;
        end if;

    end process p_calc_psum_offsets;

    -- Calculate address by adding '1' each time a valid output appears

    gen_counter : for x in 0 to size_x - 1 generate

        p_psum_counter : process (clk, rstn) is
        begin

            if not rstn then
                r_address_psum(x) <= (others => '0');
                r_start(x)        <= '1';
                r_count_w1(x)     <= 0;
                /*r_count_m0(x) <= 0;
                r_count_h2(x) <= 0;*/
            elsif rising_edge(clk) then
                if i_valid_psum_out(x) then
                    r_address_psum(x) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_psum(x))) + 1, addr_width_psum_mem));
                    r_count_w1(x)     <= r_count_w1(x) + 1;
                    /*if r_count_w1(x) = i_w1 - 1 then
                        r_count_w1(x) <= 0;
                        if r_count_m0(x) = i_m0 - 1 then
                            r_count_h2(x) <= r_count_h2(x) + 1;
                            r_count_m0(x) <= 0;
                        else
                            r_count_m0(x) <= r_count_m0(x) + 1;
                        end if;
                    else
                        r_count_w1(x) <= r_count_w1(x) + 1;
                    end if;*/
                elsif ((and r_empty_fifo_d(0) = '1') and
                       (and r_empty_fifo_d(1) = '1') and
                       (and r_empty_fifo_d(2) = '1') and
                       (r_count_w1(x) = i_w1 * i_m0) and i_start = '1') or
                      (i_start = '1' and r_start(x) = '1' and r_address_offsets_psum_done = '1') then /* TODO Does that always make sense? Do not load when storing psums */
                    -- "Load" address offset to start with.
                    r_address_psum(x) <= r_address_offsets_psum(x);
                    r_count_w1(x)     <= 0;
                    r_start(x)        <= '0';
                end if;
            end if;

        end process p_psum_counter;

        r_test(x) <= '1' when ((and r_empty_fifo_d(0) = '1') and
                                  (and r_empty_fifo_d(1) = '1') and
                                  (and r_empty_fifo_d(2) = '1') and
                                  (r_count_w1(x) = i_w1 * i_m0) and i_start = '1') or
                                          (i_start = '1' and r_start(x) = '1' and r_address_offsets_psum_done = '1') else
                     '0';

    end generate gen_counter;

end architecture rtl;

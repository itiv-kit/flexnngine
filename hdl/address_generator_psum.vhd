library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator_psum is
    generic (
        size_x : positive := 5;
        size_y : positive := 5;

        addr_width_x : positive := 3;

        addr_width_psum : positive := 15
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start : in    std_logic;

        i_w1          : in    integer range 0 to 1023;
        i_m0          : in    integer range 0 to 1023;
        i_kernel_size : in    integer range 0 to 32;
        i_new_output  : in    std_logic; -- currently unused

        i_valid_psum_out    : in    std_logic_vector(size_x - 1 downto 0);
        i_gnt_psum_binary_d : in    std_logic_vector(addr_width_x - 1 downto 0);
        i_empty_psum_fifo   : in    std_logic_vector(size_x - 1 downto 0); -- currently unused

        o_address_psum : out   std_logic_vector(addr_width_psum - 1 downto 0);
        o_suppress_out : out   std_logic
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

    signal r_address_psum : array_t(0 to size_x - 1)(addr_width_psum - 1 downto 0);

    signal r_count_w1 : int_line_t(0 to size_x - 1);
    signal r_count_m0 : int_line_t(0 to size_x - 1);
    signal r_count_h2 : int_line_t(0 to size_x - 1);

    signal r_start_delay  : std_logic;
    signal r_start_event  : std_logic;
    signal r_suppress_row : std_logic_vector(0 to size_x - 1);
    signal r_suppress_col : std_logic_vector(0 to size_x - 1);
    signal w_suppress_out : std_logic_vector(0 to size_x - 1);

    signal r_image_size : integer; -- output image size per channel, currently rectangular images only = w1*w1

begin

    r_start_delay <= i_start when rising_edge(clk);
    r_start_event <= i_start and not r_start_delay;

    -- Multiplex addresses for PE colums to interface the single Psum scratchpad
    mux_psum_adr : component mux
        generic map (
            input_width   => addr_width_psum,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i => r_address_psum,
            sel => i_gnt_psum_binary_d,
            z_o => o_address_psum
        );

    w_suppress_out <= r_suppress_row or r_suppress_col;
    o_suppress_out <= w_suppress_out(to_integer(unsigned(i_gnt_psum_binary_d)));

    p_address_psum_helper : process (clk, rstn) is
    begin

        if not rstn then
        elsif rising_edge(clk) then
            r_image_size <= i_w1 * i_w1;
        end if;

    end process p_address_psum_helper;

    gen_counter : for x in 0 to size_x - 1 generate

        p_psum_counter : process (clk, rstn) is

            variable v_count_w1 : integer; -- output channel counter
            variable v_count_m0 : integer; -- output width counter
            variable v_count_h2 : integer; -- output step counter (h2 = number of steps for whole image height)
            variable v_cur_row  : integer; -- current row

        begin

            v_count_w1 := r_count_w1(x);
            v_count_m0 := r_count_m0(x);
            v_count_h2 := r_count_h2(x);

            if not rstn then
                r_address_psum(x) <= (others => '0');
                r_suppress_row(x) <= '0';
                r_suppress_col(x) <= '0';

                v_count_w1 := 0;
                v_count_m0 := 0;
                v_count_h2 := 0;
            elsif rising_edge(clk) then
                -- start of a totally new result, reset all counters
                if r_start_event = '1' then
                    v_cur_row         := x;
                    r_address_psum(x) <= std_logic_vector(to_unsigned(v_cur_row * i_w1, addr_width_psum));
                    v_count_m0        := 0;
                    v_count_w1        := 0;
                    v_count_h2        := 0;
                -- common output of one pixel
                elsif i_valid_psum_out(x) then
                    if v_count_w1 = i_w1 - 1 then
                        -- one row is done
                        v_count_w1 := 0;

                        if v_count_m0 = i_m0 - 1 then
                            -- all kernels of this step done, prepare for next step
                            v_count_m0 := 0;
                            v_count_h2 := v_count_h2 + 1;
                        else
                            -- advance to the next mapped kernel, set address to next output image and advance by mapped rows difference
                            v_count_m0 := v_count_m0 + 1;
                        end if;

                        -- calculate the current row, taking m0 into account. wrap at input image size.
                        v_cur_row := v_count_h2 * size_x + v_count_m0 * i_kernel_size + x;
                        if v_cur_row >= i_w1 + i_kernel_size - 1 then
                            v_cur_row := v_cur_row - (i_w1 + i_kernel_size - 1);
                        end if;

                        r_address_psum(x) <= std_logic_vector(to_unsigned(v_count_m0 * r_image_size + v_cur_row * i_w1, addr_width_psum));

                        -- check condition to suppress the current row (when output row > output image rows = i_w1 - i_kernel_size)
                        if v_cur_row > i_w1 - 1 then
                            r_suppress_row(x) <= '1';
                        else
                            r_suppress_row(x) <= '0';
                        end if;

                        -- check condition to suppress a full column (on last step when total columns > i_w1) (unmapped PEs)
                        -- could be moved up if v_cur_row calculation is split
                        if v_count_h2 * size_x + x + 1 > i_w1 + i_kernel_size - 1 then
                            r_suppress_col(x) <= '1';
                        else
                            r_suppress_col(x) <= '0';
                        end if;
                    else
                        -- we are within a image row
                        v_count_w1        := v_count_w1 + 1;
                        r_address_psum(x) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_psum(x))) + 1, addr_width_psum));
                    end if;
                end if;
            end if;

            r_count_w1(x) <= v_count_w1;
            r_count_m0(x) <= v_count_m0;
            r_count_h2(x) <= v_count_h2;

        end process p_psum_counter;

    end generate gen_counter;

end architecture rtl;

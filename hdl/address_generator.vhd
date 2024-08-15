library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity address_generator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

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

        i_start   : in    std_logic;
        i_params  : in    parameters_t;
        i_m0_dist : in    array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);

        o_iact_done : out   std_logic;
        o_wght_done : out   std_logic;

        i_fifo_full_iact : in    std_logic;
        i_fifo_full_wght : in    std_logic;

        o_address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        o_address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
    );
end entity address_generator;

architecture rs_dataflow of address_generator is

    type   t_state_type is (s_idle, s_processing);
    signal r_state_wght : t_state_type;
    signal r_state_iact : t_state_type;

    signal r_mapped_pe_rows : integer;

    signal w_c0_iact       : integer;
    signal r_count_c0_iact : integer;

    signal w_w1            : integer;
    signal r_count_w1_iact : integer;

    signal w_c1            : integer;
    signal r_count_c1_iact : integer;

    signal w_h2            : integer;
    signal r_count_h2_iact : integer;

    signal r_index_h_iact      : integer;
    signal r_index_c_iact      : integer;
    signal r_index_c_last_iact : integer;

    signal r_offset_c_iact         : integer;
    signal r_offset_c_last_c1_iact : integer;
    signal r_offset_c_last_h2_iact : integer;

    signal r_data_valid_iact : std_logic;

    signal w_offset_mem_iact : integer;
    signal w_offset_mem_wght : integer;

    signal r_delay_iact_valid : std_logic_vector(size_rows - 1 downto 0);

    -- WGHT

    signal w_w1_wght : integer;

    signal w_c0_wght       : integer;
    signal r_count_c0_wght : integer;

    signal r_count_w1_wght : integer;

    signal r_count_c1_wght : integer;

    signal r_count_h2_wght : integer;

    signal r_index_x_wght : integer;
    signal r_index_y_wght : integer;

    signal r_index_c_wght      : integer;
    signal r_index_c_last_wght : integer;

    signal r_offset_c_wght         : integer;
    signal r_offset_c_last_c1_wght : integer;
    signal r_offset_c_last_h2_wght : integer;

    signal r_data_valid_wght : std_logic;

    signal r_iact_done : std_logic;
    signal r_wght_done : std_logic;

    signal r_delay_wght_valid : std_logic_vector(size_y - 1 downto 0);

begin

    o_iact_done <= r_iact_done;
    o_wght_done <= r_wght_done;

    w_c1      <= i_params.c1;
    w_w1      <= i_params.image_x;
    w_h2      <= i_params.h2;
    w_w1_wght <= i_params.kernel_size;

    w_c0_iact <= i_params.c0 when r_count_c1_iact /= w_c1 - 1 else
                 i_params.c0_last_c1;

    w_c0_wght <= i_params.c0 when r_count_c1_wght /= w_c1 - 1 else
                 i_params.c0_last_c1;

    w_offset_mem_iact <= r_offset_c_iact * i_params.image_x + r_count_w1_iact;
    w_offset_mem_wght <= r_offset_c_wght * i_params.kernel_size + r_count_w1_wght;

    r_mapped_pe_rows <= i_params.m0 * i_params.kernel_size when rising_edge(clk);

    iact_address_out : for i in 0 to size_rows - 1 generate

        -- o_address_iact(i)       <= std_logic_vector(to_unsigned(w_offset_mem_iact + i * i_params.image_x, addr_width_iact_mem));
        -- o_address_iact_valid(i) <= '1' when i_start = '1' and i_fifo_full_iact = '0' and r_iact_done = '0' else
        --                            '0';

        iact_address_out : process (clk, rstn) is
        begin

            if not rstn then
                o_address_iact_valid(i) <= '0';
                o_address_iact(i)       <= (others => '0');
                r_delay_iact_valid(i)   <= '0';
            elsif rising_edge(clk) then
                r_delay_iact_valid(i) <= '0';
                if i_start = '1' and i_fifo_full_iact = '0' and r_iact_done = '0' and r_delay_iact_valid(i) = '0' then
                    r_delay_iact_valid(i)   <= '1';
                    o_address_iact_valid(i) <= '1';
                    if r_index_h_iact + i < i_params.image_y then
                        o_address_iact(i) <= std_logic_vector(to_unsigned(r_count_w1_iact + i_params.image_x * (r_index_h_iact + i) + (i_params.image_x * i_params.image_x) * (r_index_c_iact), addr_width_iact_mem));
                    -- o_address_iact(i) <= std_logic_vector(to_unsigned(w_offset_mem_iact + i * i_params.image_x, addr_width_iact_mem));
                    else
                        o_address_iact(i) <= std_logic_vector(to_unsigned(r_count_w1_iact + i_params.image_x * (r_index_h_iact + i - i_params.image_x) + (i_params.image_x * i_params.image_x) * (r_index_c_iact), addr_width_iact_mem));
                    end if;
                else
                    o_address_iact_valid(i) <= '0';
                    o_address_iact(i)       <= (others => '0');
                end if;
            end if;

        end process iact_address_out;

    end generate iact_address_out;

    wght_address_out : for i in 0 to size_y - 1 generate

        -- o_address_wght(i)       <= std_logic_vector(to_unsigned(w_offset_mem_wght + i * i_params.kernel_size, addr_width_iact_mem));
        -- o_address_wght_valid(i) <= '1' when i_start = '1' and i_fifo_full_wght = '0' and r_wght_done = '0' else
        --                            '0';

        wght_address_out : process (clk, rstn) is
        begin

            if not rstn then
                o_address_wght(i)       <= (others => '0');
                o_address_wght_valid(i) <= '0';
                r_delay_wght_valid(i)   <= '0';
            elsif rising_edge(clk) then
                r_delay_wght_valid(i) <= '0';
                if i_start = '1' and i_fifo_full_wght = '0' and r_wght_done = '0' and r_delay_wght_valid(i) = '0' then
                    o_address_wght_valid(i) <= '1';
                    r_delay_wght_valid(i)   <= '1';
                    -- o_address_wght(i)       <= std_logic_vector(to_unsigned(w_offset_mem_wght + i * i_params.kernel_size, addr_width_wght_mem));
                    if i < r_mapped_pe_rows then
                        o_address_wght(i) <= std_logic_vector(to_unsigned(w_offset_mem_wght + (i - (to_integer(unsigned(i_m0_dist(i)))) * i_params.kernel_size + i_params.kernel_size) * i_params.kernel_size +
                                                                          ((to_integer(unsigned(i_m0_dist(i))) - 1) * i_params.kernel_size * i_params.kernel_size * i_params.inputchs), addr_width_wght_mem));
                    end if;
                else
                    o_address_wght_valid(i) <= '0';
                    o_address_wght(i)       <= (others => '0');
                end if;
            end if;

        end process wght_address_out;

    end generate wght_address_out;

    -- IACT

    p_iact_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_iact <= 0;
            r_count_c1_iact <= 0;
            r_count_h2_iact <= 0;
            r_count_w1_iact <= 0;
            r_index_h_iact  <= 0;

            r_offset_c_iact         <= 0;
            r_offset_c_last_c1_iact <= 0;
            r_offset_c_last_h2_iact <= 0;

            r_index_c_iact      <= 0;
            r_index_c_last_iact <= 0;

            r_data_valid_iact <= '0';

            r_iact_done <= '0';
        elsif rising_edge(clk) then
            r_data_valid_iact <= '0';

            if i_start = '1' and r_iact_done = '0' and i_fifo_full_iact = '0' and or r_delay_iact_valid = '0' then
                r_data_valid_iact <= '1';

                if r_count_c0_iact /= w_c0_iact - 1 then
                    r_count_c0_iact <= r_count_c0_iact + 1;
                    r_offset_c_iact <= r_offset_c_iact + i_params.image_x;
                    r_index_c_iact  <= r_index_c_iact + 1;
                else
                    r_count_c0_iact <= 0;
                    r_offset_c_iact <= r_offset_c_last_c1_iact;
                    r_index_c_iact  <= r_index_c_last_iact;

                    if r_count_w1_iact /= w_w1 - 1 then
                        r_count_w1_iact <= r_count_w1_iact + 1;

                        if r_count_w1_iact = w_w1 - 2 then
                            r_offset_c_last_c1_iact <= r_offset_c_iact + i_params.image_x;
                            r_index_c_last_iact     <= r_index_c_iact + 1;
                        end if;
                    else
                        r_count_w1_iact <= 0;

                        if r_count_c1_iact /= w_c1 - 1 then
                            r_count_c1_iact <= r_count_c1_iact + 1;
                        else
                            r_count_c1_iact     <= 0;
                            r_index_c_iact      <= 0;
                            r_index_c_last_iact <= 0;
                            r_offset_c_iact     <= r_offset_c_last_h2_iact + size_x;

                            if r_count_h2_iact /= w_h2 - 1 then
                                r_count_h2_iact         <= r_count_h2_iact + 1;
                                r_index_h_iact          <= r_index_h_iact + size_x;
                                r_offset_c_last_h2_iact <= r_offset_c_last_h2_iact + size_x;
                                r_offset_c_last_c1_iact <= r_offset_c_last_h2_iact + size_x;
                            else
                                r_data_valid_iact <= '0';
                                r_iact_done       <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if i_start = '0' and r_iact_done = '1' then
                -- reset when i_start is deasserted
                r_iact_done <= '0';

                r_count_c0_iact <= 0;
                r_count_c1_iact <= 0;
                r_count_h2_iact <= 0;
                r_count_w1_iact <= 0;
                r_index_h_iact  <= 0;

                r_offset_c_iact         <= 0;
                r_offset_c_last_c1_iact <= 0;
                r_offset_c_last_h2_iact <= 0;

                r_index_c_iact      <= 0;
                r_index_c_last_iact <= 0;

                r_data_valid_iact <= '0';
            end if;
        end if;

    end process p_iact_counter;

    -- WGHT

    p_wght_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_wght <= 0;
            r_count_c1_wght <= 0;
            r_count_h2_wght <= 0;
            r_count_w1_wght <= 0;

            r_offset_c_wght         <= 0;
            r_offset_c_last_c1_wght <= 0;
            r_offset_c_last_h2_wght <= 0;

            r_index_c_wght      <= 0;
            r_index_c_last_wght <= 0;

            r_data_valid_wght <= '0';

            r_wght_done <= '0';
        elsif rising_edge(clk) then
            r_data_valid_wght <= '0';

            if i_start = '1' and r_wght_done = '0' and i_fifo_full_wght = '0' and or r_delay_wght_valid = '0' then
                r_data_valid_wght <= '1';

                if r_count_c0_wght /= w_c0_wght - 1 then
                    r_count_c0_wght <= r_count_c0_wght + 1;
                    r_offset_c_wght <= r_offset_c_wght + i_params.kernel_size;
                    r_index_c_wght  <= r_index_c_wght + 1;
                else
                    r_count_c0_wght <= 0;
                    if i_params.kernel_size /= 1 then
                        r_offset_c_wght <= r_offset_c_last_c1_wght;
                    else
                        -- For kernel size 1, no w1 tiling. Just increase offset
                        r_offset_c_wght <= r_offset_c_wght + 1;
                    end if;
                    r_index_c_wght <= r_index_c_last_wght;

                    if r_count_w1_wght /= w_w1_wght - 1 then
                        r_count_w1_wght <= r_count_w1_wght + 1;

                        if r_count_w1_wght = w_w1_wght - 2 then
                            r_offset_c_last_c1_wght <= r_offset_c_wght + i_params.kernel_size;
                            r_index_c_last_wght     <= r_index_c_wght + 1;
                        end if;
                    else
                        r_count_w1_wght <= 0;

                        if r_count_c1_wght /= w_c1 - 1 then
                            r_count_c1_wght <= r_count_c1_wght + 1;
                        else
                            r_count_c1_wght     <= 0;
                            r_index_c_wght      <= 0;
                            r_index_c_last_wght <= 0;
                            r_offset_c_wght     <= 0;

                            -- H2 iteration could be omitted if wght buffers are not being
                            -- shrinked after a full w1 iteration (right before output phase).
                            -- Right now, the same weights are loaded H2 times.
                            if r_count_h2_wght /= w_h2 - 1 then
                                r_count_h2_wght         <= r_count_h2_wght + 1;
                                r_offset_c_last_c1_wght <= 0;
                            else
                                r_data_valid_wght <= '0';
                                r_wght_done       <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if i_start = '0' and r_wght_done = '1' then
                -- reset when i_start is deasserted
                r_wght_done <= '0';

                r_count_c0_wght <= 0;
                r_count_c1_wght <= 0;
                r_count_h2_wght <= 0;
                r_count_w1_wght <= 0;

                r_offset_c_wght         <= 0;
                r_offset_c_last_c1_wght <= 0;
                r_offset_c_last_h2_wght <= 0;

                r_index_c_wght      <= 0;
                r_index_c_last_wght <= 0;

                r_data_valid_wght <= '0';
            end if;
        end if;

    end process p_wght_counter;

end architecture rs_dataflow;

architecture alternative_rs_dataflow of address_generator is

    type   t_state_type is (s_idle, s_processing);
    signal r_state_wght : t_state_type;
    signal r_state_iact : t_state_type;

    signal r_mapped_pe_rows : integer;

    signal w_c0_iact       : integer;
    signal r_count_c0_iact : integer;

    signal w_w1            : integer;
    signal r_count_w1_iact : integer range 0 to 512;

    signal w_c1            : integer;
    signal r_count_c1_iact : integer range 0 to 512;

    signal w_h2            : integer;
    signal r_count_h2_iact : integer range 0 to 128;
    signal r_count_h1_iact : integer range 0 to 128;

    signal r_index_h_iact      : integer;
    signal r_index_c_iact      : integer;
    signal r_index_c_last_iact : integer;

    signal r_offset_c_iact         : integer;
    signal r_offset_c_last_c1_iact : integer;
    signal r_offset_c_last_h2_iact : integer;
    signal r_offset_c_last_h1_iact : integer;

    signal r_data_valid_iact : std_logic;

    signal w_offset_mem_iact : integer;
    signal w_offset_mem_wght : integer;

    signal r_delay_iact_valid : std_logic_vector(size_rows - 1 downto 0);

    -- WGHT

    signal w_w1_wght : integer;

    signal w_c0_wght       : integer;
    signal r_count_c0_wght : integer;

    signal r_count_w1_wght : integer range 0 to 512;

    signal r_count_c1_wght : integer range 0 to 512;

    signal r_count_h2_wght : integer range 0 to 128;
    signal r_count_h1_wght : integer range 0 to 128;

    signal r_index_x_wght : integer;
    signal r_index_y_wght : integer;

    signal r_index_c_wght      : integer;
    signal r_index_c_last_wght : integer;

    signal r_offset_c_wght         : integer;
    signal r_offset_c_last_c1_wght : integer;
    signal r_offset_c_last_h2_wght : integer;

    signal r_data_valid_wght : std_logic;

    signal r_iact_done : std_logic;
    signal r_wght_done : std_logic;

    signal r_delay_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal r_ckk  : integer;
    signal r_ckki : int_line_t(0 to size_y - 1);

begin

    o_iact_done <= r_iact_done;
    o_wght_done <= r_wght_done;

    r_mapped_pe_rows <= i_params.m0 * i_params.kernel_size when rising_edge(clk);

    w_c1      <= i_params.c1;
    w_w1      <= i_params.image_x;
    w_h2      <= i_params.h2;
    w_w1_wght <= i_params.kernel_size;

    w_c0_iact <= i_params.c0 when r_count_c1_iact /= w_c1 - 1 else
                 i_params.c0_last_c1;

    w_c0_wght <= i_params.c0 when r_count_c1_wght /= w_c1 - 1 else
                 i_params.c0_last_c1;

    w_offset_mem_iact <= r_offset_c_iact * i_params.image_x + r_count_w1_iact;
    w_offset_mem_wght <= r_offset_c_wght * i_params.kernel_size + r_count_w1_wght;

    iact_address_out : for i in 0 to size_rows - 1 generate

        -- o_address_iact(i)       <= std_logic_vector(to_unsigned(w_offset_mem_iact + i * i_params.image_x, addr_width_iact_mem));
        -- o_address_iact_valid(i) <= '1' when i_start = '1' and i_fifo_full_iact = '0' and r_iact_done = '0' else --
        --                            '0';

        iact_address_out : process (clk, rstn) is
        begin

            if not rstn then
                o_address_iact_valid(i) <= '0';
                o_address_iact(i)       <= (others => '0');
                r_delay_iact_valid(i)   <= '0';
            elsif rising_edge(clk) then
                r_delay_iact_valid(i)   <= '0';
                o_address_iact_valid(i) <= '0';
                o_address_iact(i)       <= (others => '0');
                if i >= size_y - 1 then
                    if i_start = '1' and i_fifo_full_iact = '0' and r_iact_done = '0' and r_delay_iact_valid(i) = '0' then
                        r_delay_iact_valid(i)   <= '1';
                        o_address_iact_valid(i) <= '1';
                        o_address_iact(i)       <= std_logic_vector(to_unsigned(w_offset_mem_iact + (i - size_y + 1) * i_params.image_x, addr_width_iact_mem));
                    else
                        r_delay_iact_valid(i)   <= '0';
                        o_address_iact_valid(i) <= '0';
                        o_address_iact(i)       <= (others => '0');
                    end if;
                end if;
            end if;

        end process iact_address_out;

    end generate iact_address_out;

    p_wght_address_helper : process (clk, rstn) is
    begin

        if not rstn then
            r_ckk <= 0;
        elsif rising_edge(clk) then
            r_ckk <= i_params.kernel_size * i_params.kernel_size * i_params.inputchs;
        end if;

    end process p_wght_address_helper;

    wght_address_out : for i in 0 to size_y - 1 generate

        wght_address_out : process (clk, rstn) is
        begin

            if not rstn then
                o_address_wght(i)       <= (others => '0');
                o_address_wght_valid(i) <= '0';
                r_delay_wght_valid(i)   <= '0';
                r_ckki(i)               <= 0;
            elsif rising_edge(clk) then
                r_delay_wght_valid(i) <= '0';
                r_ckki(i)             <= r_ckk * i;
                if i_start = '1' and i_fifo_full_wght = '0' and r_wght_done = '0' and r_delay_wght_valid(i) = '0' then
                    o_address_wght_valid(i) <= '1';
                    r_delay_wght_valid(i)   <= '1';
                    -- o_address_wght(i)       <= std_logic_vector(to_unsigned(w_offset_mem_wght + i * i_params.kernel_size, addr_width_wght_mem));
                    if i < r_mapped_pe_rows then
                        o_address_wght(i) <= std_logic_vector(to_unsigned(w_offset_mem_wght + r_ckki(i) + r_count_h1_wght * i_params.kernel_size, addr_width_wght_mem)); -- channel offset + kernel offset + row offset
                    end if;
                else
                    o_address_wght_valid(i) <= '0';
                    o_address_wght(i)       <= (others => '0');
                end if;
            end if;

        end process wght_address_out;

    end generate wght_address_out;

    -- IACT

    p_iact_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_iact <= 0;
            r_count_c1_iact <= 0;
            r_count_h2_iact <= 0;
            r_count_h1_iact <= 0;
            r_count_w1_iact <= 0;
            r_index_h_iact  <= 0;

            r_offset_c_iact         <= 0;
            r_offset_c_last_c1_iact <= 0;
            r_offset_c_last_h2_iact <= 0;
            r_offset_c_last_h1_iact <= 0;

            r_index_c_iact      <= 0;
            r_index_c_last_iact <= 0;

            r_data_valid_iact <= '0';

            r_iact_done <= '0';
        elsif rising_edge(clk) then
            r_data_valid_iact <= '0';

            if i_start = '1' and r_iact_done = '0' and i_fifo_full_iact = '0' and or r_delay_iact_valid = '0' then
                r_data_valid_iact <= '1';

                if r_count_c0_iact /= w_c0_iact - 1 then
                    r_count_c0_iact <= r_count_c0_iact + 1;
                    r_offset_c_iact <= r_offset_c_iact + i_params.image_x;
                    r_index_c_iact  <= r_index_c_iact + 1;
                else
                    r_count_c0_iact <= 0;
                    r_offset_c_iact <= r_offset_c_last_c1_iact;
                    r_index_c_iact  <= r_index_c_last_iact;

                    if r_count_w1_iact /= w_w1 - 1 then
                        r_count_w1_iact <= r_count_w1_iact + 1;

                        if r_count_w1_iact = w_w1 - 2 then
                            r_offset_c_last_c1_iact <= r_offset_c_iact + i_params.image_x;
                            r_index_c_last_iact     <= r_index_c_iact + 1;
                        end if;
                    else
                        r_count_w1_iact <= 0;

                        if r_count_c1_iact /= w_c1 - 1 then
                            r_count_c1_iact <= r_count_c1_iact + 1;
                        else
                            r_count_c1_iact     <= 0;
                            r_index_c_iact      <= 0;
                            r_index_c_last_iact <= 0;
                            r_offset_c_iact     <= r_offset_c_last_h2_iact + r_count_h1_iact + 1;

                            if r_count_h1_iact /= i_params.kernel_size - 1 then
                                r_count_h1_iact         <= r_count_h1_iact + 1;
                                r_offset_c_last_h1_iact <= r_offset_c_last_h1_iact + i_params.image_x;
                                r_offset_c_last_c1_iact <= r_offset_c_last_h2_iact + r_count_h1_iact + 1;
                            else
                                r_count_h1_iact         <= 0;
                                r_offset_c_last_h1_iact <= 0;

                                if r_count_h2_iact /= w_h2 - 1 then
                                    r_count_h2_iact         <= r_count_h2_iact + 1;
                                    r_index_h_iact          <= r_index_h_iact + size_x;
                                    r_offset_c_last_h2_iact <= r_offset_c_last_h2_iact + size_x;
                                    r_offset_c_last_c1_iact <= r_offset_c_last_h2_iact + size_x;
                                    r_offset_c_iact         <= r_offset_c_last_h2_iact + size_x;
                                else
                                    r_data_valid_iact <= '0';
                                    r_iact_done       <= '1';
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if i_start = '0' and r_iact_done = '1' then
                -- reset when i_start is deasserted
                r_iact_done <= '0';

                r_count_c0_iact <= 0;
                r_count_c1_iact <= 0;
                r_count_h2_iact <= 0;
                r_count_h1_iact <= 0;
                r_count_w1_iact <= 0;
                r_index_h_iact  <= 0;

                r_offset_c_iact         <= 0;
                r_offset_c_last_c1_iact <= 0;
                r_offset_c_last_h2_iact <= 0;
                r_offset_c_last_h1_iact <= 0;

                r_index_c_iact      <= 0;
                r_index_c_last_iact <= 0;

                r_data_valid_iact <= '0';
            end if;
        end if;

    end process p_iact_counter;

    -- WGHT

    p_wght_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_wght <= 0;
            r_count_c1_wght <= 0;
            r_count_h2_wght <= 0;
            r_count_h1_wght <= 0;
            r_count_w1_wght <= 0;

            r_offset_c_wght         <= 0;
            r_offset_c_last_c1_wght <= 0;
            r_offset_c_last_h2_wght <= 0;

            r_index_c_wght      <= 0;
            r_index_c_last_wght <= 0;

            r_data_valid_wght <= '0';

            r_wght_done <= '0';
        elsif rising_edge(clk) then
            r_data_valid_wght <= '0';

            if i_start = '1' and r_wght_done = '0' and i_fifo_full_wght = '0' and or r_delay_wght_valid = '0' then
                r_data_valid_wght <= '1';

                if r_count_c0_wght /= w_c0_wght - 1 then
                    r_count_c0_wght <= r_count_c0_wght + 1;
                    r_offset_c_wght <= r_offset_c_wght + i_params.kernel_size;
                    r_index_c_wght  <= r_index_c_wght + 1;
                else
                    r_count_c0_wght <= 0;
                    if i_params.kernel_size /= 1 then
                        r_offset_c_wght <= r_offset_c_last_c1_wght;
                    else
                        -- For kernel size 1, no w1 tiling. Just increase offset
                        r_offset_c_wght <= r_offset_c_wght + 1;
                    end if;
                    r_index_c_wght <= r_index_c_last_wght;

                    if r_count_w1_wght /= w_w1_wght - 1 then
                        r_count_w1_wght <= r_count_w1_wght + 1;

                        if r_count_w1_wght = w_w1_wght - 2 then
                            r_offset_c_last_c1_wght <= r_offset_c_wght + i_params.kernel_size;
                            r_index_c_last_wght     <= r_index_c_wght + 1;
                        end if;
                    else
                        r_count_w1_wght <= 0;

                        if r_count_c1_wght /= w_c1 - 1 then
                            r_count_c1_wght <= r_count_c1_wght + 1;
                        else
                            r_count_c1_wght     <= 0;
                            r_index_c_wght      <= 0;
                            r_index_c_last_wght <= 0;
                            r_offset_c_wght     <= 0;

                            if r_count_h1_wght /= i_params.kernel_size - 1 then
                                r_count_h1_wght         <= r_count_h1_wght + 1;
                                r_offset_c_last_c1_wght <= 0;
                            else
                                r_count_h1_wght <= 0;

                                -- Alt RS dataflow does filter height tiling (R) before channel tiling (C1).
                                -- After each C1 iteration, the first row of each channel is being shrinked.
                                -- Therefore when all kernel rows R are processed, wght line buffers are empty.
                                -- So just reload the all weights for each H2 iteration before finishing.
                                -- Alternatively, smaller C1 tiling could be done so that all kernel rows R fit
                                -- the line buffer. Then control just needs to change wght offsets per C1 iteration
                                -- instead of pruning the last kernel row and starting offsets from 0 again.
                                if r_count_h2_wght /= w_h2 - 1 then
                                    r_count_h2_wght         <= r_count_h2_wght + 1;
                                    r_offset_c_last_c1_wght <= 0;
                                else
                                    r_data_valid_wght <= '0';
                                    r_wght_done       <= '1';
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if i_start = '0' and r_wght_done = '1' then
                -- reset when i_start is deasserted
                r_wght_done <= '0';

                r_count_c0_wght <= 0;
                r_count_c1_wght <= 0;
                r_count_h2_wght <= 0;
                r_count_h1_wght <= 0;
                r_count_w1_wght <= 0;

                r_offset_c_wght         <= 0;
                r_offset_c_last_c1_wght <= 0;
                r_offset_c_last_h2_wght <= 0;

                r_index_c_wght      <= 0;
                r_index_c_last_wght <= 0;

                r_data_valid_wght <= '0';
            end if;
        end if;

    end process p_wght_counter;

end architecture alternative_rs_dataflow;

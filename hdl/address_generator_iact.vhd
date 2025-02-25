library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity address_generator_iact is
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
        addr_width_wght_mem : positive := 15;

        fifo_full_write_protect : boolean := true; -- pull output valid low if full is high
        read_size               : integer := 8     -- number of words per read request
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start  : in    std_logic;
        i_params : in    parameters_t;

        o_iact_done          : out   std_logic;
        i_fifo_full_iact     : in    std_logic;
        o_address_iact       : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0)
    );
end entity address_generator_iact;

architecture rs_dataflow of address_generator_iact is

    signal r_count_words    : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_words          : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_next_words     : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_addr_valid     : std_logic_vector(size_rows - 1 downto 0);
    signal r_addr           : uns_array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal r_next_valid     : std_logic;
    signal r_next_used      : std_logic_vector(0 to size_rows - 1);
    signal r_next_base      : uns_array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal r_cur_base_valid : std_logic_vector(0 to size_rows - 1);
    signal r_cur_base       : uns_array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);

    signal r_count_w1_iact : uint10_line_t(0 to size_rows - 1);
    signal r_count_c1_iact : integer;
    signal r_count_h2_iact : integer;

    signal r_next_base_last : std_logic;
    signal r_cur_base_last  : std_logic_vector(size_rows - 1 downto 0);
    signal r_done           : std_logic_vector(size_rows - 1 downto 0);

begin

    o_iact_done <= and r_done;

    iact_address_out : for i in 0 to size_rows - 1 generate

        iact_address_out : process is
        begin

            wait until rising_edge(clk);

            if not rstn then
                r_addr_valid(i) <= '0';
                r_done(i)       <= '0';

                r_cur_base_valid(i) <= '0'; -- start by requesting the next base address
                r_cur_base_last(i)  <= '0';
                r_next_used(i)      <= '0';
                r_count_words(i)    <= 0;
                r_words(i)          <= 0;
                r_count_w1_iact(i)  <= 0;
            else
                if i_start = '1' and r_done(i) = '0' and r_cur_base_valid(i) = '1' then
                    r_addr_valid(i) <= '1'; -- keep valid up in case of backpressure

                    if i_fifo_full_iact = '0' then
                        if r_count_words(i) /= r_words(i) - 1 then
                            -- loading a row, load the specified number of words to get w0 channels
                            -- TODO: for partial loads, set valid bits for first/last load
                            r_count_words(i) <= r_count_words(i) + 1;
                            r_addr(i)        <= r_addr(i) + i_params.stride_iact_hw * read_size;
                        else
                            -- reset to base address in any case. if within w1, reuse it and add w1
                            r_addr(i) <= r_cur_base(i) + r_count_w1_iact(i) + 1;

                            -- a full set of c0 channels of the current iact pixel is done, advance to next
                            if r_count_w1_iact(i) /= i_params.image_x - 1 then
                                -- we are within the current image row, go to the next iact pixel in this row
                                r_count_w1_iact(i) <= r_count_w1_iact(i) + 1;
                                r_count_words(i)   <= 0;
                            else
                                -- done with loading c0 channels for the full image row, advance to next set of c0 channels
                                r_count_w1_iact(i) <= 0;

                                -- load a new base address
                                r_cur_base_valid(i) <= '0';
                                r_addr_valid(i)     <= '0';

                                if r_cur_base_last(i) = '1' then
                                    r_done(i) <= '1';
                                end if;
                            end if;
                        end if;
                    end if;
                else
                    -- no valid output if not started, done or waiting for new base
                    r_addr_valid(i) <= '0';
                end if;

                if r_cur_base_valid(i) = '0' and r_next_valid = '1' then
                    -- one row is done, load next base address and reset row counter
                    r_words(i)     <= r_next_words(i);
                    r_addr(i)      <= r_next_base(i);
                    r_cur_base(i)  <= r_next_base(i);
                    r_next_used(i) <= '1'; -- signal that we need the next one

                    r_count_words(i)    <= 0;
                    r_cur_base_valid(i) <= '1';
                    r_cur_base_last(i)  <= r_next_base_last;

                    -- new base address is the first valid address to load
                    r_addr_valid(i) <= '1';
                end if;

                -- when a new base address is ready, clear the request field
                if r_next_used(i) = '1' and r_next_valid = '1' then
                    r_next_used(i) <= '0';
                end if;

                if i_start = '0' and r_done(i) = '1' then
                    r_done(i)          <= '0';
                    r_count_w1_iact(i) <= 0;
                end if;
            end if;

        end process iact_address_out;

        o_address_iact(i)       <= std_logic_vector(r_addr(i));
        o_address_iact_valid(i) <= '1' when r_addr_valid(i) = '1' and (not fifo_full_write_protect or i_fifo_full_iact = '0') else '0';

    end generate iact_address_out;

    -- address pattern for spad_reshape with cols=8, image h,w=8,8, channels=16, acc size 5x5
    -- channel_set 0: load one column of 8 channels from h=0 into row 0
    --                load one column of 8 channels from h=1 into row 1 (delta to row 0 = image_size_stride)
    --                ... until h=7, then wrap h back to 0:
    --                load one column of 8 channels from h=0 into row 8
    --                load one column of 8 channels from h=1 into row 9
    --                done for this set of channels
    -- channel_set 1: load 2nd column of 8 channels from h=0 into row 0 (offset image_width_stride * cols)
    -- ... until c0 / cols channel_sets are loaded

    -- identical for all rows: channel_set -> image_width_stride * cols offset calculation
    --                         and matching valid bits for channels mod channel_set in last iteration
    --                         w1 iteration offset = 1
    --                         c1 iteration offset = c0 / cols * image_size_stride
    --                         h2 iteration offset = multiples of image_width_stride * cols * array_size_x
    -- individual counters for rows: add image_size_stride * row

    p_iact_counter : process is

        variable v_row        : integer;
        variable v_row_stride : integer;
        variable v_ch_offset  : integer;
        variable v_c0         : integer;

    begin

        wait until rising_edge(clk);

        -- reset when i_start is deasserted
        if not rstn or (not i_start and r_next_base_last) then
            r_next_base_last <= '0';
            r_next_valid     <= '0';

            r_count_c1_iact <= 0;
            r_count_h2_iact <= 0;
        else
            if i_start and not r_next_base_last and not r_next_valid then
                if r_count_c1_iact /= i_params.c1 - 1 then
                    -- next set of channels
                    r_count_c1_iact <= r_count_c1_iact + 1;
                else
                    -- all channels of this row loaded, proceed to next row
                    r_count_c1_iact <= 0;

                    if r_count_h2_iact /= i_params.h2 - 1 then
                        r_count_h2_iact <= r_count_h2_iact + 1;
                    else
                        r_next_base_last <= '1';
                    end if;
                end if;

                if r_count_c1_iact = i_params.c1 - 1 then
                    v_c0 := i_params.c0_last_c1;
                else
                    v_c0 := i_params.c0;
                end if;

                for row in 0 to size_rows - 1 loop

                    -- row differs for each row, i.e. address generator instance
                    v_row := r_count_h2_iact * size_x + row;

                    v_row_stride := i_params.stride_iact_w * read_size; -- w stride is unpacked to single words on reshaped spad side

                    -- wrap at full image height
                    if v_row >= i_params.image_y then
                        v_row := v_row - i_params.image_y;
                    end if;

                    -- advance in sets of c0 channels (= something like a stride for c0 iterations)
                    v_ch_offset := r_count_c1_iact * i_params.c0 / read_size; -- TODO: if only multiples of read_size are possible for c0, get rid of division

                    -- base address for next set of c0 channels
                    r_next_base(row) <= to_unsigned(i_params.base_iact +
                                                    v_row * v_row_stride +
                                                    v_ch_offset * i_params.stride_iact_hw * read_size,
                                                    addr_width_iact_mem);

                    -- number of words to load for c0 channels
                    r_next_words(row) <= (v_c0 + read_size - 1) / read_size; -- TODO: is this efficient? read_size is power-of-two. could also move - 1 from comparison here
                -- TODO: valid bits for last word if c0 not multiple of read size

                end loop;

                r_next_valid <= '1';
            end if;

            if and r_next_used then
                r_next_valid <= '0';
            end if;
        end if;

    end process p_iact_counter;

end architecture rs_dataflow;

architecture alternative_rs_dataflow of address_generator_iact is

    type   t_state_type is (s_idle, s_processing);
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

    signal r_delay_iact_valid : std_logic_vector(size_rows - 1 downto 0);

    signal r_iact_done : std_logic;

begin

    o_iact_done <= r_iact_done;

    r_mapped_pe_rows <= i_params.m0 * i_params.kernel_size when rising_edge(clk);

    w_c1 <= i_params.c1;
    w_w1 <= i_params.image_x;
    w_h2 <= i_params.h2;

    w_c0_iact <= i_params.c0 when r_count_c1_iact /= w_c1 - 1 else
                 i_params.c0_last_c1;

    w_offset_mem_iact <= r_offset_c_iact * i_params.image_x + r_count_w1_iact;

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

end architecture alternative_rs_dataflow;

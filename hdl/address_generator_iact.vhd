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

        mem_addr_width : positive := 15;

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
        o_address_iact       : out   array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0)
    );
end entity address_generator_iact;

architecture unified of address_generator_iact is

    signal r_count_words    : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_words          : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_next_words     : uint10_line_t(0 to size_rows - 1); -- shall have range 0 to max_line_length_iact;
    signal r_addr_valid     : std_logic_vector(size_rows - 1 downto 0);
    signal r_addr           : uns_array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
    signal r_next_valid     : std_logic_vector(0 to size_rows - 1);
    signal r_next_used      : std_logic_vector(0 to size_rows - 1);
    signal r_next_base      : uns_array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
    signal r_cur_base_valid : std_logic_vector(0 to size_rows - 1);
    signal r_cur_base       : uns_array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);

    signal r_count_w1 : uint10_line_t(0 to size_rows - 1);
    signal r_count_c1 : integer;
    signal r_count_h1 : integer;
    signal r_count_h2 : integer;

    signal r_next_base_last : std_logic;
    signal r_cur_base_last  : std_logic_vector(size_rows - 1 downto 0);
    signal r_done           : std_logic_vector(size_rows - 1 downto 0);
    signal r_next_row_pad   : std_logic_vector(size_rows - 1 downto 0);
    signal r_cur_row_pad    : std_logic_vector(size_rows - 1 downto 0);

begin

    o_iact_done <= and r_done;

    iact_address_out : for i in 0 to size_rows - 1 generate

        iact_address_out : process is

            variable row_active : std_logic;
            variable next_addr  : unsigned(mem_addr_width - 1 downto 0);

        begin

            wait until rising_edge(clk);

            row_active := '1' when i_params.dataflow = 0 or i >= size_y - 1 else '0';

            if not rstn then
                r_addr_valid(i) <= '0';
                r_done(i)       <= '0';

                r_cur_base_valid(i) <= '0';        -- start by requesting the next base address
                r_cur_base_last(i)  <= '0';
                r_cur_row_pad(i)    <= '0';
                r_next_used(i)      <= '0';
                r_count_words(i)    <= 0;
                r_words(i)          <= 0;
                r_count_w1(i)       <= 0;
            else
                next_addr := r_addr(i);

                if i_start = '1' and r_done(i) = '0' and r_cur_base_valid(i) = '1' then
                    r_addr_valid(i) <= row_active; -- keep valid up in case of backpressure

                    if i_fifo_full_iact = '0' then
                        if r_count_words(i) /= r_words(i) - 1 then
                            -- loading a row, load the specified number of words to get w0 channels
                            -- TODO: if partial loads need to be supported, set valid bits for first/last load
                            r_count_words(i) <= r_count_words(i) + 1;
                            next_addr        := r_addr(i) + i_params.stride_iact_hw;
                        else
                            -- reset to base address in any case. if within w1, reuse it and add w1
                            next_addr := r_cur_base(i) + r_count_w1(i) + 1;

                            -- a full set of c0 channels of the current iact pixel is done, advance to next
                            if r_count_w1(i) /= i_params.image_x - 1 then
                                -- we are within the current image row, go to the next iact pixel in this row
                                r_count_w1(i)    <= r_count_w1(i) + 1;
                                r_count_words(i) <= 0;
                            else
                                -- done with loading c0 channels for the full image row, advance to next set of c0 channels
                                r_count_w1(i) <= 0;

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

                -- only advance the address if we are not loading padding data
                if not r_cur_row_pad(i) then
                    r_addr(i) <= next_addr;
                end if;

                if r_cur_base_valid(i) = '0' and r_next_valid(i) = '1' then
                    -- one row is done, load next base address and reset row counter
                    r_words(i)     <= r_next_words(i);
                    r_addr(i)      <= r_next_base(i);
                    r_cur_base(i)  <= r_next_base(i);
                    r_next_used(i) <= '1'; -- signal that we need the next one

                    r_count_words(i)    <= 0;
                    r_cur_base_valid(i) <= '1';
                    r_cur_base_last(i)  <= r_next_base_last;
                    r_cur_row_pad(i)    <= r_next_row_pad(i);

                    -- new base address is the first valid address to load
                    r_addr_valid(i) <= row_active;
                end if;

                -- when a new base address is ready, clear the request field
                if r_next_used(i) = '1' and or r_next_valid = '0' then
                    r_next_used(i) <= '0';
                end if;

                if i_start = '0' and r_done(i) = '1' then
                    r_done(i)     <= '0';
                    r_count_w1(i) <= 0;
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
        variable v_pad        : boolean;

    begin

        wait until rising_edge(clk);

        -- reset when i_start is deasserted
        if not rstn or (not i_start and r_next_base_last) then
            r_next_base_last <= '0';
            r_next_valid     <= (others => '0');

            r_count_c1 <= 0;
            r_count_h1 <= 0;
            r_count_h2 <= 0;
        else
            if i_start and not r_next_base_last and not (or r_next_valid) then
                -- shared counters for all PE rows
                if r_count_c1 /= i_params.c1 - 1 then
                    -- next set of channels
                    r_count_c1 <= r_count_c1 + 1;
                else
                    -- all channels of this row loaded, proceed to next row
                    r_count_c1 <= 0;

                    -- for trs dataflow, read kernel_size successive rows per PE row
                    if r_count_h1 /= i_params.kernel_size - 1 and i_params.dataflow = 1 then
                        r_count_h1 <= r_count_h1 + 1;
                    else
                        -- all kernel_size rows processed
                        r_count_h1 <= 0;

                        if r_count_h2 /= i_params.h2 - 1 then
                            r_count_h2 <= r_count_h2 + 1;
                        else
                            r_next_base_last <= '1';
                        end if;
                    end if;
                end if;

                if r_count_c1 = i_params.c1 - 1 then
                    v_c0 := i_params.c0_last_c1;
                else
                    v_c0 := i_params.c0;
                end if;

                for row in 0 to size_rows - 1 loop

                    -- row differs for each diagonal PE row, i.e. address generator instance
                    v_row := r_count_h2 * size_x + r_count_h1 + row;

                    -- trs dataflow feeds bottom rows only, row 0 starts at PE row size_y - 1
                    -- PE rows 0 .. size_y - 2 get bogus r_next_base addresses which are suppressed on the output stage
                    if i_params.dataflow = 1 and row >= size_y - 1 then
                        v_row := v_row - (size_y - 1);
                    end if;

                    -- wrap at full image height (including padding if enabled)
                    if v_row >= i_params.image_y + i_params.pad_y then
                        v_row := v_row - i_params.image_y - i_params.pad_y;
                    end if;

                    -- when padding is enabled, 0..pad_y-1 and h-pad_y..h-1 rows are skipped (TODO: or duplicated if not zero-padding)
                    if i_params.mode_pad = zero and v_row < i_params.pad_y then
                        v_pad := true;
                    else
                        v_pad := false;
                        v_row := v_row - i_params.pad_y;    -- convert "virtual" row number of padded image to physical input image row number
                    end if;

                    v_row_stride := i_params.stride_iact_w; -- w stride is unpacked to single words on reshaped spad side

                    -- advance in sets of c0 channels (= something like a stride for c0 iterations)
                    v_ch_offset := r_count_c1 * i_params.c0 / read_size; -- TODO: if only multiples of read_size are possible for c0, get rid of division

                    -- base address for next set of c0 channels
                    r_next_base(row) <= to_unsigned(i_params.base_iact +
                                                    v_row * v_row_stride +
                                                    v_ch_offset * i_params.stride_iact_hw,
                                                    mem_addr_width);

                    -- if padding data needs to be loaded, overwrite with padding data address
                    if v_pad then
                        r_next_base(row) <= to_unsigned(i_params.base_pad, mem_addr_width);
                    end if;

                    -- number of words to load for c0 channels
                    -- TODO: valid bits for last word if c0 not multiple of read size
                    r_next_words(row) <= (v_c0 + read_size - 1) / read_size; -- TODO: is this efficient? read_size is power-of-two. could also move - 1 from comparison here

                    r_next_valid(row)   <= '1';
                    r_next_row_pad(row) <= '1' when v_pad else '0';

                end loop;

            end if;

            if or r_next_valid = '1' and r_next_used = r_next_valid then
                r_next_valid <= (others => '0');
            end if;
        end if;

    end process p_iact_counter;

end architecture unified;

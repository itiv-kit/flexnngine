library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity address_generator_wght is
    generic (
        size_y    : positive := 5;
        read_size : integer  := 8; -- number of words per read request

        addr_width_y   : positive := 3;
        mem_addr_width : positive := 15;

        fifo_full_write_protect : boolean := true -- pull output valid low if full is high
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start   : in    std_logic;
        i_params  : in    parameters_t;
        i_m0_dist : in    uns_array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);

        o_wght_done          : out   std_logic;
        i_fifo_full_wght     : in    std_logic;
        o_address_wght       : out   array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
        o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
    );
end entity address_generator_wght;

architecture unified of address_generator_wght is

    signal r_count_words    : uint10_line_t(0 to size_y - 1); -- shall have range 0 to max_line_length_wght;
    signal r_words          : uint10_line_t(0 to size_y - 1); -- shall have range 0 to max_line_length_wght;
    signal r_next_words     : uint10_line_t(0 to size_y - 1); -- shall have range 0 to max_line_length_wght;
    signal r_addr_valid     : std_logic_vector(size_y - 1 downto 0);
    signal r_addr           : uns_array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
    signal r_next_valid     : std_logic;
    signal r_next_used      : std_logic_vector(0 to size_y - 1);
    signal r_next_base      : uns_array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
    signal r_cur_base_valid : std_logic_vector(0 to size_y - 1);
    signal r_cur_base       : uns_array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);

    signal r_count_s  : uint10_line_t(0 to size_y - 1); -- kernel width
    signal r_count_c1 : integer;
    signal r_count_h1 : integer;
    signal r_count_h2 : integer;
    signal r_count_m1 : integer;

    signal r_next_base_last : std_logic;
    signal r_cur_base_last  : std_logic_vector(size_y - 1 downto 0);
    signal r_done           : std_logic_vector(size_y - 1 downto 0);

begin

    o_wght_done <= and r_done;

    gen_wght_address_out : for i in 0 to size_y - 1 generate

        wght_address_out : process is
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
                r_count_s(i)        <= 0;
            else
                if i_start = '1' and r_done(i) = '0' and r_cur_base_valid(i) = '1' then
                    r_addr_valid(i) <= '1'; -- keep valid up in case of backpressure

                    if i_fifo_full_wght = '0' then
                        if r_count_words(i) /= r_words(i) - 1 then
                            -- loading a row, load the specified number of words to get c0 weights
                            -- TODO: for partial loads, set valid bits for first/last load
                            r_count_words(i) <= r_count_words(i) + 1;
                            r_addr(i)        <= r_addr(i) + i_params.stride_wght_kernel;
                        else
                            -- reset to base address in any case. if still within a kernel, reuse it and add s offset
                            r_addr(i) <= r_cur_base(i) + r_count_s(i) + 1;

                            -- a full set of c0 channels of the current wght pixel is done, advance to next
                            if r_count_s(i) /= i_params.kernel_size - 1 then
                                -- we are within the current image row, go to the next wght pixel in this row
                                r_count_s(i)     <= r_count_s(i) + 1;
                                r_count_words(i) <= 0;
                            else
                                -- done with loading c0 channels for the full image row, advance to next set of c0 channels
                                r_count_s(i) <= 0;

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
                    -- r_count_s(i)        <= 0;

                    -- new base address is the first valid address to load
                    r_addr_valid(i) <= '1';
                end if;

                -- when a new base address is ready, clear the request field
                if r_next_used(i) = '1' and r_next_valid = '1' then
                    r_next_used(i) <= '0';
                end if;

                if i_start = '0' and r_done(i) = '1' then
                    r_done(i)    <= '0';
                    r_count_s(i) <= 0;
                end if;
            end if;

        end process wght_address_out;

        o_address_wght(i)       <= std_logic_vector(r_addr(i));
        o_address_wght_valid(i) <= '1' when r_addr_valid(i) = '1' and (not fifo_full_write_protect or i_fifo_full_wght = '0') else '0';

    end generate gen_wght_address_out;

    -- address pattern for spad_reshape with cols=8, kernel r,s=3,3, channels=16, acc size 5x5, output channels m0=3
    -- channel_set 0: load one column of 8 weights from m0=0 r=0 into row 0
    --                load one column of 8 weights from m0=0 r=1 into row 1 (offset r=3)
    --                load one column of 8 weights from m0=0 r=2 into row 2
    --                load one column of 8 weights from m0=1 r=0 into row 3 (offset wght_och_stride)
    --                load one column of 8 weights from m0=1 r=1 into row 4
    --                load one column of 8 weights from m0=1 r=2 into row 5
    --                load one column of 8 weights from m0=2 r=0 into row 6 (offset 2*wght_och_stride)
    --                load one column of 8 weights from m0=2 r=1 into row 7
    --                load one column of 8 weights from m0=2 r=2 into row 8
    --                done for this set of weights
    -- channel_set 1: load 2nd column of 8 weights from m0=0 r=0 into row 0 (offset wght_kernel_stride, e.g. 9)
    -- ... until c0 / cols channel_sets are loaded

    -- identical for all rows: channel_set -> wght_kernel_stride * channel_set offset
    --                         and matching valid bits for channels mod channel_set in last iteration
    --                         w1 iteration offset = 1
    --                         c1 iteration offset = c0 / cols * image_size_stride
    -- individual static offsets for rows: wght_och_stride according to m0_dist
    --                                     r offset (row mod kernel_size)

    p_wght_counter : process is

        variable v_och_offset : natural;
        variable v_c1_offset  : natural;
        variable v_c0         : natural;
        variable v_s_offset   : natural; -- kernel row offset

    begin

        wait until rising_edge(clk);

        -- reset when i_start is deasserted
        if not rstn or (not i_start and r_next_base_last) then
            r_next_base_last <= '0';
            r_next_valid     <= '0';

            r_count_c1 <= 0;
            r_count_h1 <= 0;
            r_count_h2 <= 0;
            r_count_m1 <= 0;
        else
            if i_start and not r_next_base_last and not r_next_valid then
                if r_count_c1 /= i_params.c1 - 1 then
                    -- next set of channels
                    r_count_c1 <= r_count_c1 + 1;
                else
                    -- all channels of this row loaded, start over and load first c0 set again for next h2 iteration
                    r_count_c1 <= 0;

                    -- for trs dataflow, kernels are temporally tiled - for each row, all c1 iterations are processed first
                    if r_count_h1 /= i_params.kernel_size - 1 and i_params.dataflow = 1 then
                        r_count_h1 <= r_count_h1 + 1;
                    else
                        -- kernel fully processed
                        r_count_h1 <= 0;

                        if r_count_h2 /= i_params.h2 - 1 then
                            r_count_h2 <= r_count_h2 + 1;
                        elsif r_count_m1 /= i_params.m1 - 1 then
                            r_count_m1 <= r_count_m1 + 1;
                            r_count_h2 <= 0;
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

                for row in 0 to size_y - 1 loop

                    v_och_offset := r_count_m1 * i_params.m0;

                    if i_params.dataflow = 1 then
                        v_och_offset := v_och_offset + row;                            -- trs dataflow: row equals m0
                    else
                        v_och_offset := v_och_offset + to_integer(i_m0_dist(row) - 1); -- offset between output channel kernel sets
                    end if;

                    if i_params.dataflow = 1 then
                        v_s_offset := r_count_h1;
                    elsif i_m0_dist(row) > 0 then
                        -- this is equal to (natural(row) mod i_params.kernel_size), but hopefully more efficient
                        v_s_offset := row - i_params.kernel_size * to_integer(i_m0_dist(row) - 1);
                    else
                        v_s_offset := 0;
                    end if;

                    -- advance in sets of c0 channels (= something like a stride for c0 iterations)
                    v_c1_offset := r_count_c1 * i_params.c0 / read_size; -- TODO: is the division efficient if 2^n?

                    -- base address for next set of c0 channels
                    r_next_base(row) <= to_unsigned(i_params.base_wght +
                                                    v_och_offset * i_params.stride_wght_och +
                                                    v_c1_offset * i_params.stride_wght_kernel +
                                                    v_s_offset * i_params.kernel_size,
                                                    mem_addr_width);

                    -- number of words to load for c0 channels
                    -- TODO: valid bits for last word if c0 not multiple of read size
                    r_next_words(row) <= (v_c0 + read_size - 1) / read_size; -- TODO: is this efficient? read_size is power-of-two. could also move - 1 from comparison here

                end loop;

                r_next_valid <= '1';
            end if;

            if and r_next_used then
                r_next_valid <= '0';
            end if;
        end if;

    end process p_wght_counter;

end architecture unified;

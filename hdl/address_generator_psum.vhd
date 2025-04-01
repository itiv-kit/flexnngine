library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity address_generator_psum is
    generic (
        size_x : positive := 5;
        size_y : positive := 5;

        mem_addr_width : positive := 15;
        mem_columns    : positive := 8;

        write_size          : positive := 1;
        mem_offset_width    : integer  := integer(ceil(log2(real(write_size))));
        addr_width_bytewise : positive := mem_addr_width + mem_offset_width
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start    : in    std_logic;
        i_dataflow : in    std_logic;
        i_params   : in    parameters_t;

        i_valid_psum_out : in    std_logic_vector(size_x - 1 downto 0);

        -- this module works with byte-wise addresses
        o_address_psum : out   array_t(0 to size_x - 1)(addr_width_bytewise - 1 downto 0);
        o_suppress_out : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity address_generator_psum;

architecture rtl of address_generator_psum is

    -- consecutive output channels are placed in one column of spad_reshape each
    -- this is the columns size in bytes
    constant mem_col_offset : positive := 2 ** mem_addr_width / mem_columns * write_size;

    signal r_next_address : uns_array_t(0 to size_x - 1)(addr_width_bytewise - 1 downto 0);
    signal r_address_psum : uns_array_t(0 to size_x - 1)(addr_width_bytewise - 1 downto 0);

    signal r_next_address_valid : std_logic_vector(0 to size_x - 1);
    signal r_suppress_next_row  : std_logic_vector(0 to size_x - 1);
    signal r_suppress_next_col  : std_logic_vector(0 to size_x - 1);
    signal r_done               : std_logic_vector(0 to size_x - 1);

    signal r_count_w1 : uint10_line_t(0 to size_x - 1);
    signal r_count_m0 : uint10_line_t(0 to size_x - 1);
    signal r_count_h2 : uint10_line_t(0 to size_x - 1);

    signal r_start_delay : std_logic;
    signal r_start_event : std_logic;

    signal r_image_size : integer; -- output image size per channel, currently rectangular images only = w1*w1
    signal r_write_size : integer range 1 to write_size; -- pixels per output word (64bit/8bit for int8, 64bit/16bit for int16)

begin

    r_start_delay <= i_start when rising_edge(clk);
    r_start_event <= i_start and not r_start_delay;
    r_image_size  <= i_params.w1 * i_params.w1 when rising_edge(clk);
    r_write_size  <= write_size when i_params.requant_enab else write_size / 2 when rising_edge(clk);

    gen_counter : for x in 0 to size_x - 1 generate

        o_address_psum(x) <= std_logic_vector(r_address_psum(x));

        p_psum_counter : process is

            variable v_count_w1 : integer; -- output channel counter
            variable v_count_m0 : integer; -- output width counter
            variable v_count_h2 : integer; -- output step counter (h2 = number of steps for whole image height)
            variable v_cur_row  : integer; -- current row
            variable v_offset   : integer; -- offset of the address to full write_size memory words
            variable v_new_addr : integer;
            variable v_done     : boolean;

        begin

            wait until rising_edge(clk);

            if not rstn then
                o_suppress_out(x) <= '0';

                r_next_address_valid(x) <= '1'; -- will be reset on r_start_event
                r_suppress_next_row(x)  <= '0';
                r_suppress_next_col(x)  <= '0';

                r_count_w1(x) <= 0;
                r_count_m0(x) <= 0;
                r_count_h2(x) <= 0;
                r_done(x)     <= '0';
            else
                v_count_w1 := r_count_w1(x);
                v_count_m0 := r_count_m0(x);
                v_count_h2 := r_count_h2(x);
                v_done     := r_done(x) = '1';

                -- address output/increment and calculation of new base addresses are decoupled
                -- if timing issues occur, this can be pipelined

                if r_start_event = '1' then
                    -- start of a totally new result, reset all counters
                    v_count_m0 := 0;
                    v_count_h2 := 0;
                    v_done     := false;
                elsif not r_next_address_valid(x) then
                    if v_count_m0 = i_params.m0 - 1 then
                        if v_count_h2 = i_params.h2 - 1 then
                            -- full image processed, don't generate any more addresses
                            v_done := true;
                        else
                            -- all kernels of this step done, prepare for next step
                            v_count_m0 := 0;
                            v_count_h2 := v_count_h2 + 1;
                        end if;
                    else
                        -- advance to the next mapped kernel, set address to next output image and advance by mapped rows difference
                        v_count_m0 := v_count_m0 + 1;
                    end if;
                end if;

                -- calculate the current row, taking m0 into account for rs dataflow
                v_cur_row := v_count_h2 * size_x + x;
                if i_dataflow = '0' then
                    v_cur_row := v_cur_row + v_count_m0 * i_params.kernel_size;
                end if;

                --  wrap at input image size
                if v_cur_row >= i_params.w1 + i_params.kernel_size - 1 then
                    v_cur_row := v_cur_row - (i_params.w1 + i_params.kernel_size - 1);
                end if;

                -- start with the base address
                v_new_addr := i_params.base_psum;

                -- jump to the respective output channel column
                v_new_addr := v_new_addr + v_count_m0 mod mem_columns * mem_col_offset;

                -- if more than mem_columns output channels, put output channels after each other (with stride offset)
                v_new_addr := v_new_addr + v_count_m0 / mem_columns * i_params.stride_psum_och * write_size;

                -- finally, add the row offset
                v_new_addr := v_new_addr + v_cur_row * i_params.w1;

                if (r_next_address_valid(x) = '0' or r_start_event = '1') and not v_done then
                    r_next_address(x)       <= to_unsigned(v_new_addr, addr_width_bytewise);
                    r_next_address_valid(x) <= '1';
                end if;

                -- check condition to suppress the current row (when output row > output image rows = i_params.w1 - i_params.kernel_size)
                if v_cur_row > i_params.w1 - 1 then
                    r_suppress_next_row(x) <= '1';
                else
                    r_suppress_next_row(x) <= '0';
                end if;

                -- check condition to suppress a full column (on last step when total columns > i_params.w1) (unmapped PEs)
                -- could be moved up if v_cur_row calculation is split
                if v_count_h2 * size_x + x + 1 > i_params.w1 + i_params.kernel_size - 1 then
                    r_suppress_next_col(x) <= '1';
                else
                    r_suppress_next_col(x) <= '0';
                end if;

                if r_start_event = '1' then
                    v_count_w1 := 0;

                    r_address_psum(x)       <= to_unsigned(v_new_addr, addr_width_bytewise);
                    o_suppress_out(x)       <= '0';
                    r_next_address_valid(x) <= '0'; -- immediately trigger calculation of subsequent address
                elsif i_valid_psum_out(x) then
                    -- common output of one word (write_size pixels)
                    if v_count_w1 >= i_params.w1 - r_write_size then
                        -- one row is done
                        v_count_w1 := 0;

                        r_address_psum(x)       <= r_next_address(x);
                        r_next_address_valid(x) <= '0';

                        o_suppress_out(x) <= r_suppress_next_row(x) or r_suppress_next_col(x);
                    else
                        -- we are within a image row
                        if r_write_size > 1 and v_count_w1 = 0 then
                            v_offset   := to_integer(r_address_psum(x)(mem_offset_width - 1 downto 0));
                            v_count_w1 := r_write_size - v_offset; -- TODO: offset for raw psums?
                        else
                            v_count_w1 := v_count_w1 + r_write_size;
                        end if;
                        r_address_psum(x) <= r_address_psum(x) + write_size;
                    end if;
                end if;

                r_count_w1(x) <= v_count_w1;
                r_count_m0(x) <= v_count_m0;
                r_count_h2(x) <= v_count_h2;
                r_done(x)     <= '1' when v_done else '0';
            end if;

        end process p_psum_counter;

    end generate gen_counter;

end architecture rtl;

-- concatenate i_data words until o_data is full or i_last is asserted
-- i_offset selects the first words of o_data to be written to after i_last was asserted
-- o_valid is a byte-wise valid signal of o_data

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity parallelizer is
    generic (
        little_endian   : boolean := false;
        byte_wise_valid : boolean := true
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_valid  : in    std_logic;
        i_last   : in    std_logic;
        i_data   : in    std_logic_vector;
        i_offset : in    unsigned; -- initial offset for new rows

        o_data  : out   std_logic_vector;
        o_valid : out   std_logic_vector
    );
end entity parallelizer;

architecture behavioral of parallelizer is

    constant c_words         : integer  := integer(o_data'length / i_data'length);
    constant c_counter_width : positive := positive(ceil(log2(real(c_words))));
    signal   counter         : integer range 0 to c_words - 1;

    signal full, idle  : std_logic;
    signal shift_reg   : std_logic_vector(o_data'range);
    signal valid_words : std_logic_vector(c_words - 1 downto 0);

    -- repeat_bits("010",3) => "000111000"

    function repeat_bits (input : in std_logic_vector; times : in positive) return std_logic_vector is

        variable res : std_logic_vector(input'length * times - 1 downto 0);

    begin

        for idx in input'range loop

            for n in 0 to times - 1 loop

                res(times * idx + n) := input(idx);

            end loop;

        end loop;

        return res;

    end function repeat_bits;

begin

    proc : process is
    begin

        wait until rising_edge(clk);

        if not rstn then
            full        <= '0';
            idle        <= '1';
            counter     <= 0;
            valid_words <= (others => '0');
            o_valid     <= (o_valid'range => '0');
        else
            if idle = '1' then
                -- use uppermost bits for offset, as counter is more narrow for multi-byte i_data words
                counter <= to_integer(i_offset(i_offset'left downto i_offset'left - c_counter_width + 1));
            end if;

            if full = '1' then
                o_data <= shift_reg;

                if byte_wise_valid then
                    o_valid <= repeat_bits(valid_words, i_data'length / 8);
                else
                    o_valid <= valid_words;
                end if;

                valid_words <= (others => '0');
                full        <= '0';
            else
                o_valid <= (o_valid'range => '0');
            end if;

            if i_valid = '1' then
                idle <= '0';

                if little_endian then
                    valid_words(c_words - counter - 1) <= '1';

                    shift_reg(i_data'length * (c_words - counter) - 1 downto i_data'length * (c_words - counter - 1)) <= i_data;
                else
                    valid_words(counter) <= '1';

                    shift_reg(i_data'length * (counter + 1) - 1 downto i_data'length * counter) <= i_data;
                end if;

                if counter = c_words - 1 or i_last = '1' then
                    full <= '1';

                    if i_last = '1' then
                        idle <= '1';
                    else
                        counter <= 0;
                    end if;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;

    end process proc;

end architecture behavioral;

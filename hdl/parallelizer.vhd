/*---------------------------------------------------------------------
-- Design:      Parallelizer
-- Description: Take serial stream of words and combine them to a larger word, i.e. parallelize the words
-- Author:      Johannes Huober
------------------------------------------------------------------------*/

-- Module used to parallelize data with in_width to out_width format
-- i.e. 128 Bit <-> 16 Bit => 8 cycles
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity parallelizer is
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_valid : in    std_logic;
        i_last  : in    std_logic;
        i_data  : in    std_logic_vector;

        o_data  : out   std_logic_vector;
        -- o_valid : out   std_logic_vector;
        o_valid : out   std_logic;
        o_words : out   unsigned
    );

end parallelizer;

architecture behavioral of parallelizer is

    constant c_words       : integer := integer(o_data'length / i_data'length);
    constant c_counter_width : positive := positive(ceil(log2(real(c_words))));
    signal counter         : integer range 0 to c_words - 1;
    signal words_output    : unsigned(c_counter_width - 1 downto 0);

    signal shift_reg   : std_logic_vector(o_data'range);
    -- signal words_valid : std_logic_vector(words - 1 downto 0);

begin

    proc : process
    begin
        wait until rising_edge(clk);

        if not rstn then
            counter <= 0;
            -- words_valid <= (others => '0');

            o_valid <= '0';
            -- o_data  <= (others => '0');
        else
            if i_valid = '1' then
                shift_reg <= shift_reg(o_data'length - i_data'length - 1 downto 0) & i_data;
                if counter = c_words - 1 or i_last = '1' then
                    counter <= 0;
                    -- words_valid <= words_valid(words_valid'length - 1 downto 0) & '1';
                    words_output <= to_unsigned(counter, c_counter_width);
                else
                    counter <= counter + 1;
                end if;
            end if;

            if words_output > 0 then
                -- o_valid     <= words_valid;
                o_data  <= shift_reg;
                o_words <= words_output;
                o_valid <= '1';
                -- words_valid <= (others => '0');
                words_output <= (others => '0');
            else
                o_valid <= '0';
            end if;
        end if;
    end process proc;

end behavioral;

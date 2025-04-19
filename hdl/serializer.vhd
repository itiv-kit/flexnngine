/*---------------------------------------------------------------------
-- Design:          serializer
-- Description:     Take a single large data word and split it into a stream of smaller words, i.e. serialize
-- Original Author: Johannes Huober
------------------------------------------------------------------------*/
-- Module used to serialize data with in_width to out_width format
-- i.e. 128 Bit <-> 8 Bit => 16 cycles
-- TODO: potential optimization, get rid of one non-ready cycle per input word on initial read

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity serializer is
    generic (
        in_width   : integer := 128;  -- width of the input data in bits
        out_width  : integer := 8;    -- width of the output data in bits
        max_count  : integer := integer(in_width / out_width);
        hold_valid : boolean := false -- if true, valid will be held at 1 also when if i_ready is 0 (similar to AXI Stream)
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_valid : in    std_logic;
        i_data  : in    std_logic_vector(in_width - 1 downto 0);
        o_ready : out   std_logic;

        i_ready : in    std_logic;
        o_data  : out   std_logic_vector(out_width - 1 downto 0);
        o_valid : out   std_logic
    );
end entity serializer;

architecture behavioral of serializer is

    signal counter   : integer range 0 to max_count - 1 := 0;
    signal shift_reg : std_logic_vector(in_width - 1 downto 0);
    signal has_data  : std_logic;

begin

    serialize_proc : process is
    begin

        wait until rising_edge(clk);

        if not rstn then
            counter  <= 0;
            has_data <= '0';
            o_valid  <= '0';
        else
            if i_valid and not has_data then
                shift_reg <= i_data;
                has_data  <= '1';
                o_valid   <= '1';
                counter   <= 0;
            end if;

            if has_data and i_ready then
                shift_reg <= std_logic_vector(shift_right(unsigned(shift_reg), out_width));
                if counter = max_count - 1 then
                    counter  <= 0;
                    has_data <= '0';
                    o_valid  <= '0';
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;

    end process serialize_proc;

    o_data  <= shift_reg(out_width - 1 downto 0);
    o_ready <= not has_data;

end architecture behavioral;

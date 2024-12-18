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

entity parallelizer is 
    generic (
        in_width    : integer := 16;  -- width of the input data in bits
        out_width   : integer := 128;   -- width of the output data in bits
        max_count   : integer := integer(out_width/in_width)
    );
    port ( 
        clk     : in std_logic; 
        rstn    : in std_logic;
        en      : in std_logic;
        
        in_data     : in std_logic_vector(in_width-1 downto 0);
        out_data    : out std_logic_vector(out_width-1 downto 0);
        valid       : out std_logic
    );

end parallelizer;

architecture behavioral of parallelizer is 
    signal counter      : integer range 0 to (max_count) := 0;
    signal shift_reg    : std_logic_vector(out_width-1 downto 0);
    signal valid_flag   : std_logic := '0';
begin
    -- single process to handle serialization
    serialize_proc : process (clk,rstn)
    begin
        if not rstn then
            counter     <= 0;
            shift_reg   <= (others => '0');
            out_data    <= (others => '0');
            valid       <= '0';
        elsif rising_edge(clk) then
            valid <= '0';
            if en = '1' then
                shift_reg <= shift_reg(out_width-in_width-1 downto 0) & in_data;
                if counter = max_count - 1 then 
                    counter     <= 0;
                    valid_flag  <= '1';
                else
                    counter <= counter + 1;
                end if;
            end if;
            if valid_flag = '1' then
                valid       <= '1';
                out_data    <= shift_reg;
                valid_flag  <= '0';
            end if;
        end if;
    end process serialize_proc;
end behavioral;

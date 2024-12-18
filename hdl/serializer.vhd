/*---------------------------------------------------------------------
-- Design:      Parallelizer
-- Description: Take a single large data word and split it into a stream of smaller words, i.e. serialize
-- Author:      Johannes Huober
------------------------------------------------------------------------*/
-- Module used to serialize data with in_width to out_width format
-- i.e. 128 Bit <-> 8 Bit => 16 cycles 
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity serializer is 
    generic (
        in_width    : integer := 128;  -- width of the input data in bits
        out_width   : integer := 8;   -- width of the output data in bits
        max_count   : integer := integer(in_width/out_width)
    );
    port ( 
        clk     : in std_logic; 
        rstn    : in std_logic;
        en      : in std_logic;
        
        in_data     : in std_logic_vector(in_width-1 downto 0);
        out_data    : out std_logic_vector(out_width-1 downto 0);
        valid       : out std_logic
    );
        
end serializer;

architecture behavioral of serializer is 
    signal counter      : integer range 0 to max_count  := 0;
    signal shift_reg    : std_logic_vector(in_width-1 downto 0);
    signal start_flag   : std_logic := '0';
begin
    -- single process to handle serialization
    serialize_proc : process (clk,rstn)
    begin
        if not rstn then
            counter     <= 0;
            shift_reg   <= (others => '0');
            valid       <= '0';
        elsif rising_edge(clk) then
            if en = '1' and start_flag = '0' then 
                shift_reg   <= in_data;
                start_flag  <= '1';
                valid       <= '1';
                counter     <= counter + 1;
            end if;
            if start_flag = '1' then 
                shift_reg   <= std_logic_vector(shift_left(unsigned(shift_reg),out_width));
                if counter = max_count  then 
                    counter     <= 0;
                    start_flag  <= '0';
                    valid       <= '0';
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process serialize_proc;

    -- assign output
    out_data <= shift_reg(in_width-1 downto (in_width - out_width));
end behavioral;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

-- convert an count given as unsigned to a number of '1's
entity write_enable_gen is
    generic (
        count_width : positive := 3;
        wen_width : positive := 2 ** count_width
    );
    port (
        i_count : in    unsigned(count_width - 1 downto 0);
        o_wen   : out   std_logic_vector(wen_width - 1 downto 0)
    );
end entity write_enable_gen;

architecture rtl of write_enable_gen is

begin

    p_ones : process (i_count) is

        variable v_count : integer range 0 to wen_width;
        variable v_ones  : std_logic_vector(wen_width - 1 downto 0);

    begin

        v_count := to_integer(i_count);
        v_ones  := (others => '0');

        for i in 0 to v_count - 1 loop

            v_ones(i) := '1';

        end loop;

        o_wen <= v_ones;

    end process p_ones;

end architecture rtl;

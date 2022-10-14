library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity onehot_binary is
    generic (

        onehot_width : positive := 9;
        binary_width : positive := 4
    );
    port (
        i_onehot : in    std_logic_vector(onehot_width - 1 downto 0);
        o_binary : out   std_logic_vector(binary_width - 1 downto 0)
    );
end entity onehot_binary;

architecture rtl of onehot_binary is

begin

    p_onehot : process (i_onehot) is

        variable v_binary : std_logic_vector(binary_width - 1 downto 0);

    begin

        v_binary := (others => '0');

        for i in 0 to onehot_width - 1 loop

            if i_onehot(i) = '1' then
                v_binary := v_binary or std_logic_vector(to_unsigned(i, binary_width));
            end if;

        end loop;

        o_binary <= v_binary;

    end process p_onehot;

end architecture rtl;

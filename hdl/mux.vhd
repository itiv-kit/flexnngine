library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity mux is
    generic (
        input_width   : natural; -- Bits in each input
        input_num     : natural; -- Number of inputs
        address_width : natural  -- Number of address bits (ceil(log2(NUM)))
    );
    port (
        v_i : in    array_t(0 to input_num - 1)(input_width - 1 downto 0);
        sel : in    std_logic_vector(address_width - 1 downto 0);
        z_o : out   std_logic_vector(input_width - 1 downto 0)
    );
end entity mux;

architecture syn of mux is

begin

    z_o <= v_i(to_integer(unsigned(sel)));

end architecture syn;

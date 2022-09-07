library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity demux is
    generic (
        output_width  : natural := 8; -- Bits in each input
        output_num    : natural := 2; -- Number of inputs
        address_width : natural := 1 -- Number of address bits (ceil(log2(NUM)))
    );
    port (
        v_i : in    std_logic_vector(output_width - 1 downto 0);
        sel : in    std_logic_vector(address_width - 1 downto 0);
        z_o : out   array_t(0 to output_num - 1)(output_width - 1 downto 0)
    );
end entity demux;

architecture syns of demux is

begin

    demux : process (all) is
    begin

        z_o                            <= (others => (others => '0'));
        z_o(to_integer(unsigned(sel))) <= v_i;

    end process demux;

end architecture syns;

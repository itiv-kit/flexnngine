library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity demux_tb is
end entity demux_tb;

architecture imp of demux_tb is

    component demux is
        generic (
            output_width  : natural;
            output_num    : natural;
            address_width : natural
        );
        port (
            v_i : in    std_logic_vector(output_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   array_t(0 to output_num - 1)(output_width - 1 downto 0)
        );
    end component demux;

    signal z_o : array_t(0 to 2 - 1)(8 - 1 downto 0);
    signal sel : std_logic_vector(0 downto 0);
    signal v_i : std_logic_vector(7 downto 0);

begin

    sel <= "0", "1" after 100 ns;
    v_i <= (others => '1'), (others => '0') after 200 ns;

    demux_inst : entity work.demux
        generic map (
            output_width  => 8,
            output_num    => 2,
            address_width => 1
        )
        port map (
            v_i => v_i,
            sel => sel,
            z_o => z_o
        );

end architecture imp;

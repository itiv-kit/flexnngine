-- mixed-width ram with small port a, larger port b

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.textio.all;

library accel;
    use accel.utilities.all;

entity ram_mw is
    generic (
        addr_width_b     : positive := 16; -- address width of port B, address A is larger
        data_width_a     : positive := 8;  -- data width of port A, port B is larger
        addr_width_delta : positive := 2;  -- number of bits which address A is larger than address B.
        -- computed generics, usually no need to change them:
        words_a_per_b    : positive := 2 ** addr_width_delta;
        addr_width_a     : positive := addr_width_b + addr_width_delta;
        data_width_b     : positive := data_width_a * words_a_per_b
    );
    port (
        clka  : in    std_logic;
        clkb  : in    std_logic;
        wena  : in    std_logic;
        wenb  : in    std_logic;
        addra : in    std_logic_vector(addr_width_a - 1 downto 0);
        addrb : in    std_logic_vector(addr_width_b - 1 downto 0);
        dina  : in    std_logic_vector(data_width_a - 1 downto 0);
        dinb  : in    std_logic_vector(data_width_b - 1 downto 0);
        douta : out   std_logic_vector(data_width_a - 1 downto 0);
        doutb : out   std_logic_vector(data_width_b - 1 downto 0)
    );
end entity ram_mw;

architecture syn of ram_mw is

    signal s_wea   : std_logic_vector(words_a_per_b - 1 downto 0);
    signal s_web   : std_logic_vector(words_a_per_b - 1 downto 0);
    signal s_dina  : std_logic_vector(data_width_b - 1 downto 0);
    signal s_douta : std_logic_vector(data_width_b - 1 downto 0);

    signal s_addra_lower       : std_logic_vector(addr_width_delta - 1 downto 0);
    signal s_addra_upper       : std_logic_vector(addr_width_b - 1 downto 0);
    signal s_addra_lower_delay : std_logic_vector(addr_width_delta - 1 downto 0);
    signal s_douta_slices      : array_t(0 to words_a_per_b - 1)(data_width_a - 1 downto 0);

begin

    mem : entity accel.ram_dp_bwe
        generic map (
            size       => 2 ** addr_width_b,
            addr_width => addr_width_b,
            col_width  => data_width_a,
            nb_col     => words_a_per_b
        ) port map (
            clka => clka,
            ena => '1',
            wea => s_wea,
            addra => s_addra_upper,
            dia => s_dina,
            doa => s_douta,
            clkb => clkb,
            enb => '1',
            web => s_web,
            addrb => addrb,
            dib => dinb,
            dob => doutb
        );

    s_web <= (others => wenb);

    s_addra_upper       <= addra(addr_width_a - 1 downto addr_width_delta);
    s_addra_lower       <= addra(addr_width_delta - 1 downto 0);
    s_addra_lower_delay <= s_addra_lower when rising_edge(clka);

    douta <= s_douta_slices(to_integer(unsigned(s_addra_lower_delay)));

    p_porta : process (all) is
        variable index : integer range 0 to words_a_per_b - 1;
    begin
        index := to_integer(unsigned(s_addra_lower));

        s_wea        <= (others => '0');
        s_wea(index) <= wena;

        for i in 0 to words_a_per_b - 1 loop

            s_dina((i + 1) * data_width_a - 1 downto i * data_width_a) <= dina;

            s_douta_slices(i) <= s_douta((i + 1) * data_width_a - 1 downto i * data_width_a);

        end loop;
    end process p_porta;

end architecture syn;

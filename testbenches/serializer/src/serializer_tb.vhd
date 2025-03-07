library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use std.textio.all;
    use ieee.float_pkg.all;

library accel;
    use accel.utilities.all;

--! Testbench for the reformatter unit

entity serializer_tb is
    generic (
        in_width  : positive := 64;
        out_width : positive := 8;
        words     : positive := 5
    );
end entity serializer_tb;

architecture imp of serializer_tb is

    constant factor : integer := in_width / out_width;

    signal clk  : std_logic := '1';
    signal rstn : std_logic := '0';

    signal i_valid : std_logic;
    signal i_data  : std_logic_vector(in_width - 1 downto 0);
    signal o_ready : std_logic;

    signal i_ready : std_logic;
    signal o_data  : std_logic_vector(out_width - 1 downto 0);
    signal o_valid : std_logic;

begin

    dut : entity accel.serializer
        generic map (
            in_width  => in_width,
            out_width => out_width
        )
        port map (
            clk     => clk,
            rstn    => rstn,
            i_valid => i_valid,
            i_data  => i_data,
            o_ready => o_ready,
            i_ready => i_ready,
            o_data  => o_data,
            o_valid => o_valid
        );

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rst : process is
    begin

        wait for 50 ns;
        wait until rising_edge(clk);
        rstn <= '1';
        wait;

    end process gen_rst;

    gen_inputs : process is

        variable element : unsigned(out_width - 1 downto 0);

    begin

        i_valid <= '0';
        i_data  <= (others => '0');

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        wait for 150 ns;

        for word in 0 to words - 1 loop

            wait until rising_edge(clk) and o_ready = '1';
            i_valid <= '1';

            for i in 0 to factor - 1 loop

                element := to_unsigned(factor * word + i, out_width);

                i_data(out_width * (i + 1) - 1 downto out_width * i) <= std_logic_vector(element);

            end loop;

        end loop;

        wait until rising_edge(clk) and o_ready = '1';
        i_valid <= '0';

        wait for 200 ns;

    end process gen_inputs;

    gen_ready : process is
    begin

        i_ready <= '0';

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        wait until rising_edge(clk);
        i_ready <= '1';

        -- randomly pull ready low after some time, for two cycles
        wait for 180 ns;
        wait until rising_edge(clk);
        wait until rising_edge(clk);

    end process gen_ready;

    check_output : process is
    begin

        for n in 0 to words * factor - 1 loop

            wait until rising_edge(clk) and o_valid = '1' and i_ready = '1';

            assert o_data = std_logic_vector(to_unsigned(n, out_width))
                report "Unexpected output " & integer'image(to_integer(unsigned(o_data))) & ", expected " & integer'image(n)
                severity warning;

        end loop;

        report "Output check is finished."
            severity note;

        finish;

        wait;

    end process check_output;

end architecture imp;

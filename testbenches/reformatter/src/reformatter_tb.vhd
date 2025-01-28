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

entity reformatter_tb is
    generic (
        element_size  : positive := 8;
        element_count : positive := 4;
        output_rows   : positive := 6
    );
end entity reformatter_tb;

architecture imp of reformatter_tb is

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';

    signal o_ready : std_logic;
    signal i_valid : std_logic;
    signal i_data  : std_logic_vector(element_count * element_size - 1 downto 0);
    signal i_ready : std_logic_vector(output_rows - 1 downto 0);
    signal o_valid : std_logic_vector(output_rows - 1 downto 0);
    signal o_data  : std_logic_vector(element_count * element_size - 1 downto 0);

begin

    dut : entity accel.reformatter
        generic map (
            element_size => element_size,
            element_count => element_count,
            output_rows => output_rows
        )
        port map (
            clk             => clk,
            rst             => rst,
            o_ready         => o_ready,
            i_valid         => i_valid,
            i_data          => i_data,
            i_ready         => i_ready,
            o_valid         => o_valid,
            o_data          => o_data
        );

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rst : process is
    begin

        wait for 50 ns;
        wait until rising_edge(clk);
        rst <= '0';
        wait;

    end process gen_rst;

    gen_inputs : process is
        variable element : unsigned(element_size - 1 downto 0);
    begin

        i_valid <= '0';
        i_data  <= (others => '0');

        if rst = '0' then
            wait until rst = '0';
        end if;

        wait for 150 ns;

        for channel in 0 to element_count - 1 loop

            wait until rising_edge(clk);
            i_valid <= '1';

            for i in 0 to element_count - 1 loop
                element := to_unsigned(16 * channel + i, element_size);
                i_data(element_size * (i + 1) - 1 downto element_size * i) <= std_logic_vector(element);
            end loop;

            wait until rising_edge(clk);
            i_valid <= '0';

        end loop;

        i_valid <= '0';

        wait for 200 ns;

    end process gen_inputs;

    check_output : process is
    begin

        if rst = '0' then
            wait until rst = '1';
        end if;

        wait until rising_edge(clk);
        i_ready <= (others => '1');
        wait;

        -- for n in 0 to equations'high loop

        --     wait until rising_edge(clk) and o_data_valid = '1';
        --     eq := equations(n);
        --     tmp_out := to_integer(signed(o_data));

        --     assert eq.output = tmp_out report "Output invalid, expected " & integer'image(eq.output) & " but got " & integer'image(tmp_out)
        --         severity failure;

        -- end loop;

        -- report "Output check is finished."
        --     severity note;

        -- finish;

    end process check_output;

end architecture imp;

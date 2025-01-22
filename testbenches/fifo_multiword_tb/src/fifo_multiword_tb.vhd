library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.fifos.fifo;

entity fifo_multiword_tb is
    generic (
        in_clock_duration  : time := 2 ns;
        out_clock_duration : time := 4 ns
    );
end entity fifo_multiword_tb;

architecture tb of fifo_multiword_tb is

    signal wr_clk      : std_logic                    := '0';
    signal rst         : std_logic                    := '1';
    signal wr_en       : std_logic                    := '0';
    signal din         : std_logic_vector(7 downto 0) := (others => '0');
    signal last        : std_logic                    := '0';
    signal full        : std_logic                    := '0';
    signal almost_full : std_logic                    := '0';

    signal rd_clk       : std_logic                     := '0';
    signal rd_en        : std_logic                     := '0';
    signal dout         : std_logic_vector(63 downto 0) := (others => '0');
    signal valid        : std_logic;
    signal empty        : std_logic                     := '0';
    signal almost_empty : std_logic                     := '0';

begin

    uut : entity accel.dc_merge_fifo
        generic map (
            mem_size => 32
        )
        port map (
            wr_clk       => wr_clk,
            rst          => rst,
            wr_en        => wr_en,
            din          => din,
            last         => last,
            full         => full,
            almost_full  => almost_full,
            rd_clk       => rd_clk,
            rd_en        => rd_en,
            dout         => dout,
            valid        => valid,
            almost_empty => almost_empty,
            empty        => empty
        );

    wclk_gen : process (wr_clk) is
    begin

        wr_clk <= not wr_clk after in_clock_duration;

    end process wclk_gen;

    wrst_gen : process is
    begin

        wait for 10 ns;
        wait until rising_edge(wr_clk);
        rst <= '0';

    end process wrst_gen;

    rclk_gen : process (rd_clk) is
    begin

        rd_clk <= not rd_clk after out_clock_duration;

    end process rclk_gen;

    fifo_wr : process is
    begin

        wait for 100 ns;

        -- test init values
        wait until rising_edge(wr_clk);
        assert full = '0'
            report "not initially full";

        -- test single write
        din   <= x"00";
        wr_en <= '1';

        wait until rising_edge(wr_clk);
        wr_en <= '0';

        wait for 30 ns;                                    -- propagation to read domain
        wait until rising_edge(rd_clk);
        assert empty = '0'
            report "empty after write";
        assert almost_empty = '1'
            report "not signaling incomplete dout word";

        -- test filling up
        for n in 1 to 31 loop

            wait until rising_edge(wr_clk);
            wr_en <= '1';
            din   <= std_logic_vector(to_unsigned(n, 8));

        end loop;

        wait until rising_edge(wr_clk);
        wr_en <= '0';

        wait for 30 ns;                                    -- propagation to read domain
        wait until rising_edge(wr_clk);
        assert empty = '0'
            report "empty after write";
        assert almost_empty = '0'
            report "almost empty after many writes";
        assert full = '1'
            report "not full after 32 writes";

        -- test overwrite
        wait until rising_edge(wr_clk);
        din   <= x"FF";
        wr_en <= '1';

        wait until rising_edge(wr_clk);
        wr_en <= '0';
        assert full = '1'
            report "not full after overwrite";

        wait until rising_edge(wr_clk);
        assert full = '1'
            report "not full after overwrite";

        wait for 30 ns;                                    -- propagation to read domain
        wait until rising_edge(rd_clk);
        assert empty = '0'
            report "empty after overwrite";

        -- test concurrent read/write
        wait until rising_edge(wr_clk) and empty = '1';

        for n in 0 to 200 loop

            wait until rising_edge(wr_clk) and full = '0';
            wr_en <= '1';
            din   <= std_logic_vector(to_unsigned(n, 8));

        end loop;

        last <= '1';

        wait until rising_edge(wr_clk);
        wr_en <= '0';
        last  <= '0';

        wait;

    end process fifo_wr;

    fifo_rd : process is

        variable last_dout : std_logic_vector(15 downto 0);

    begin

        -- test reading from full fifo
        wait until rising_edge(wr_clk) and full = '1'; -- wait until full on write side
        wait until rising_edge(rd_clk);

        for nr in 0 to 15 loop

            wait until rising_edge(rd_clk) and not empty = '1';
            rd_en <= '1';
            assert dout /= x"FF"
                report "overwrite pattern stored";

        end loop;

        wait until rising_edge(rd_clk);
        rd_en <= '0';

        -- test concurrent read/write
        wait until rising_edge(rd_clk);

        for n in 0 to 200 loop

            wait until rising_edge(rd_clk) and empty = '0';
            rd_en     <= '1';
            assert dout /= x"FF"
                report "overwrite pattern stored";
            assert n < 3 or unsigned(last_dout) + 1 = unsigned(dout)
                report "dout not steadily increasing";
            assert empty = '0'
                report "empty during concurrent rw";
            last_dout := dout;

        end loop;

        wait until rising_edge(rd_clk);
        rd_en <= '0';

        wait;

    end process fifo_rd;

end architecture tb;

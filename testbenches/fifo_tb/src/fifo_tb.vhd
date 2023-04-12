library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.fifos.fifo;

entity tb_dc_fifo is
    generic (
        tx_clock_duration : time    := 2 ns;
        rx_clock_duration : time    := 3 ns;
        use_packets       : boolean := false
    );
end entity tb_dc_fifo;

architecture tb of tb_dc_fifo is

    component fifo_generator_0 is
        port (
            rst         : in    std_logic;
            wr_clk      : in    std_logic;
            rd_clk      : in    std_logic;
            din         : in    std_logic_vector(15 downto 0);
            wr_en       : in    std_logic;
            rd_en       : in    std_logic;
            dout        : out   std_logic_vector(15 downto 0);
            full        : out   std_logic;
            almost_full : out   std_logic;
            empty       : out   std_logic;
            valid       : out   std_logic
        );
    end component;

    signal wr_clk       : std_logic                     := '0';
    signal rst          : std_logic                     := '1';
    signal wr_en        : std_logic                     := '0';
    signal din          : std_logic_vector(15 downto 0) := (others => '0');
    signal full         : std_logic                     := '0';
    signal almost_full  : std_logic                     := '0';
    signal full2        : std_logic                     := '0';
    signal almost_full2 : std_logic                     := '0';
    signal keep         : std_logic                     := '0';
    signal drop         : std_logic                     := '0';

    signal rd_clk : std_logic := '0';
    -- signal rrst      : std_logic := '1';
    signal rd_en  : std_logic                     := '0';
    signal dout   : std_logic_vector(15 downto 0) := (others => '0');
    signal dout2  : std_logic_vector(15 downto 0) := (others => '0');
    signal valid  : std_logic;
    signal valid2 : std_logic;
    signal empty  : std_logic                     := '0';
    signal empty2 : std_logic                     := '0';

begin

    uut : entity work.dc_fifo
        generic map (
            mem_size => 16, use_packets => use_packets
        )
        port map (
            wr_clk      => wr_clk,
            rst         => rst,
            wr_en       => wr_en,
            din         => din,
            full        => full,
            almost_full => almost_full,
            keep        => keep,
            drop        => drop,
            rd_clk      => rd_clk,
            rd_en       => rd_en,
            dout        => dout,
            valid       => valid,
            empty       => empty
        );

    uut2 : component fifo_generator_0
        port map (
            rst         => rst,
            wr_clk      => wr_clk,
            rd_clk      => rd_clk,
            din         => din,
            wr_en       => wr_en,
            rd_en       => rd_en,
            dout        => dout2,
            full        => full2,
            almost_full => almost_full2,
            empty       => empty2,
            valid       => valid2
        );

    wclk_gen : process (wr_clk) is
    begin

        wr_clk <= not wr_clk after tx_clock_duration;

    end process wclk_gen;

    wrst_gen : process is
    begin

        wait for 10 ns;
        wait until rising_edge(wr_clk);
        rst <= '0';

    end process wrst_gen;

    rclk_gen : process (rd_clk) is
    begin

        rd_clk <= not rd_clk after rx_clock_duration;

    end process rclk_gen;

    /*rrst_gen : process begin
        wait for 10 ns;
        wait until rising_edge(rd_clk);
        rrst <= '0';
    end process;*/

    fifo_wr : process is
    begin

        wait for 100 ns;

        -- test init values
        wait until rising_edge(wr_clk);
        assert full = '0'
            report "not initially full";

        -- test single write
        din   <= x"00aa";
        wr_en <= '1';

        wait until rising_edge(wr_clk);
        -- keep <= '1';
        wr_en <= '0';

        wait until rising_edge(wr_clk);
        keep <= '0';

        wait for 30 ns;                                    -- propagation to read domain
        wait until rising_edge(rd_clk);
        assert empty = '0'
            report "empty after write";

        -- test filling up
        for n in 1 to 14 loop

            wait until rising_edge(wr_clk);
            wr_en <= '1';
            din   <= std_logic_vector(to_unsigned(n, 16));

        end loop;

        wait until rising_edge(wr_clk);
        -- keep <= '1';
        wr_en <= '0';

        wait until rising_edge(wr_clk);
        keep <= '0';

        wait until rising_edge(wr_clk);
        assert empty = '0'
            report "empty after write";
        assert full = '1'
            report "not full after 16 writes";

        -- test overwrite
        wait until rising_edge(wr_clk);
        din   <= x"00ff";
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
            -- keep <= '1';
            din <= std_logic_vector(to_unsigned(n, 16));

        end loop;

        wait until rising_edge(wr_clk);
        wr_en <= '0';
        keep  <= '0';

        wait;

    end process fifo_wr;

    fifo_rd : process is

        variable last_dout : std_logic_vector(15 downto 0);

    begin

        -- test reading from full fifo
        wait until rising_edge(wr_clk) and full = '1'; -- wait until full on write side
        wait until rising_edge(rd_clk);

        for nr in 0 to 6 loop

            wait until rising_edge(rd_clk) and not empty = '1';
            rd_en <= '1';
            assert dout /= x"00ff"
                report "overwrite pattern stored";

        end loop;

        wait until rising_edge(rd_clk);
        rd_en <= '0';

        -- test concurrent read/write
        wait until rising_edge(rd_clk);

        for n in 0 to 200 loop

            wait until rising_edge(rd_clk) and empty = '0';
            rd_en     <= '1';
            assert dout /= x"00ff"
                report "overwrite pattern stored";
            assert n<3 or unsigned(last_dout) + 1 = unsigned(dout)
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

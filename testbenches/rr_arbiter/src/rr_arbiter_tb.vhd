library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;
    use std.env.finish;
    use std.env.stop;

entity rr_arbiter_tb is
    generic (
        arbiter_width : natural  := 6;
        binary_width  : positive := 3
    );
end entity rr_arbiter_tb;

architecture imp of rr_arbiter_tb is

    constant period : time := 20 ns;

    signal clk        : std_logic := '0';
    signal rstn       : std_logic := '0';
    signal req        : std_logic_vector(arbiter_width - 1 downto 0);
    signal gnt        : std_logic_vector(arbiter_width - 1 downto 0);
    signal gnt_binary : std_logic_vector(binary_width - 1 downto 0);
    signal endsim     : boolean   := false;

    component rr_arbiter is
        generic (
            arbiter_width : natural := 4
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            -- inputs
            req : in    std_logic_vector(arbiter_width - 1 downto 0);

            -- outputs
            gnt : out   std_logic_vector(arbiter_width - 1 downto 0)
        );
    end component rr_arbiter;

    component onehot_binary is
        generic (

            onehot_width : positive := 9;
            binary_width : positive := 4
        );
        port (
            onehot : in    std_logic_vector(onehot_width - 1 downto 0);
            binary : out   std_logic_vector(binary_width - 1 downto 0)
        );
    end component onehot_binary;

begin

    clk  <= not clk after period / 2;
    rstn <= '1' after  period * 10;

    -- Main simulation process
    stimuli : process is
    begin

        req <= "000000";

        wait until (rstn = '1');
        wait until (rising_edge(clk));

        wait until (rising_edge(clk));
        req <= "000001";
        wait until rising_edge(clk);
        req <= "000011";
        wait until rising_edge(clk);
        req <= "000111";
        wait until rising_edge(clk);
        req <= "001111";
        wait until rising_edge(clk);
        req <= "011111";
        wait until rising_edge(clk);
        req <= "111111";
        wait until rising_edge(clk);

        for i in 0 to 7 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "111110";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "111111";

        for i in 0 to 8 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "000000";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "000001";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "110000";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "001100";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "110000";

        for i in 0 to 10 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "000000";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "111000";

        for i in 0 to 15 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "000000";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "100000";

        for i in 0 to 15 loop

            wait until (rising_edge(clk));

        end loop;

        req <= "000000";

        for i in 0 to 3 loop

            wait until (rising_edge(clk));

        end loop;

        endsim <= true;

    end process stimuli;

    -- End the simulation
    end_sim : process is
    begin

        if endsim then
            finish;
        end if;

        wait until (rising_edge(clk));

    end process end_sim;

    rr_arbiter_inst : component rr_arbiter
        generic map (
            arbiter_width => arbiter_width
        )
        port map (
            clk  => clk,
            rstn => rstn,

            req => req,
            gnt => gnt
        );

    onehot_binary_inst : component onehot_binary
        generic map (
            onehot_width => arbiter_width,
            binary_width => binary_width
        )
        port map (
            onehot => gnt,
            binary => gnt_binary
        );

end architecture imp;

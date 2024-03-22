-- loosely adapted from vhdl-extras (http://github.com/kevinpt/vhdl-extras)

library ieee;
    use ieee.std_logic_1164.all;

package sync is

    -- A single bit synchronizer with a configurable number of stages.
    component bit_sync is
        generic (
            stages : natural := 2
        );
        port (
            clk : in    std_logic;
            rst : in    std_logic;

            bit_in  : in    std_logic;
            bit_out : out   std_logic
        );
    end component;

    -- A handshaking synchronizer for sending an array between clock domains.
    -- This uses the four-phase handshake protocol.
    component handshake_sync is
        generic (
            stages : natural := 2
        );
        port (
            tx_clk : in    std_logic;
            tx_rst : in    std_logic;

            tx_data  : in    std_logic_vector;
            tx_start : in    std_logic;
            tx_busy  : out   std_logic;
            tx_done  : out   std_logic;

            rx_clk : in    std_logic;
            rx_rst : in    std_logic;

            rx_data : out   std_logic_vector;
            rx_new  : out   std_logic
        );
    end component;

    -- Gray code synchronizer for single-step counters
    component gray_sync is
        generic (
            stages : positive := 2
        );
        port (
            src_clk : in    std_logic;
            src_bin : in    std_logic_vector;

            dst_clk : in    std_logic;
            dst_bin : out   std_logic_vector
        );
    end component;

end package sync;

library ieee;
    use ieee.std_logic_1164.all;

entity bit_sync is
    generic (
        stages : natural := 2 -- number of register stages
    );
    port (
        clk : in    std_logic;
        rst : in    std_logic;

        bit_in  : in    std_logic;
        bit_out : out   std_logic
    );
end entity bit_sync;

architecture rtl of bit_sync is

    signal sr : std_logic_vector(1 to stages);

    -- Guard against SRL16 inference in case Reset is not being used
    attribute shreg_extract       : string;
    attribute shreg_extract of sr : signal is "no";
    attribute async_reg       : string;
    attribute async_reg of sr     : signal is "TRUE";

begin

    reg : process is
    begin

        wait until rising_edge(clk);

        if rst = '1' then
            sr <= (others => '0');
        else
            sr <= bit_in & sr(1 to sr'right-1);
        end if;

    end process reg;

    bit_out <= sr(sr'right);

end architecture rtl;

library ieee;
    use ieee.std_logic_1164.all;

library accel;
    use accel.sync.bit_sync;

entity handshake_sync is
    generic (
        stages : natural := 2 -- number of register stages
    );
    port (
        tx_clk : in    std_logic; -- sending clock
        tx_rst : in    std_logic; -- reset for sending side

        tx_data  : in    std_logic_vector; -- data to send
        tx_start : in    std_logic;        -- signal to send data
        tx_busy  : out   std_logic;        -- high while sending data
        tx_done  : out   std_logic;        -- flag when sending is done

        rx_clk : in    std_logic; -- receiving clock
        rx_rst : in    std_logic; -- reset for receiving side

        rx_data : out   std_logic_vector; -- received data
        rx_new  : out   std_logic         -- flag to indicate new data
    );
end entity handshake_sync;

architecture rtl of handshake_sync is

    signal ack_rx, ack_tx : std_logic;
    signal prev_ack       : std_logic;

    signal tx_reg_en   : std_logic;
    signal tx_data_reg : std_logic_vector(tx_data'range);

    signal req_tx, req_rx : std_logic;
    signal prev_req       : std_logic;

begin

    -----------
    -- TX logic
    -----------
    as : entity accel.bit_sync
        generic map (
            stages => stages
        )
        port map (
            clk     => tx_clk,
            rst     => tx_rst,
            bit_in  => ack_rx,
            bit_out => ack_tx
        );

    ack_change : process is
    begin

        wait until rising_edge(tx_clk);

        if tx_rst = '1' then
            prev_ack <= '0';
        else
            prev_ack <= ack_tx;
        end if;

    end process ack_change;

    tx_done <= '1' when ack_tx = '0' and prev_ack = '1' else
               '0';

    fsm : block is

        type   states is (idle, send, done);
        signal cur_state : states;

    begin

        p_fsm : process is

            variable next_state : states;

        begin

            wait until rising_edge(tx_clk);

            if tx_rst = '1' then
                cur_state <= idle;
                tx_reg_en <= '0';
                req_tx    <= '0';
                tx_busy   <= '0';
            else
                next_state := cur_state;
                tx_reg_en  <= '0';

                case cur_state is

                    when idle =>

                        if tx_start = '1' then
                            next_state := send;
                            tx_reg_en  <= '1';
                        end if;

                    when send =>                -- wait for rx side to assert ack

                        if ack_tx = '1' then
                            next_state := done;
                        end if;

                    when done =>                -- wait for rx side to deassert ack

                        if ack_tx = '0' then
                            next_state := idle;
                        end if;

                    when others =>

                        next_state := idle;

                end case;

                cur_state <= next_state;

                req_tx  <= '0';
                tx_busy <= '0';

                case next_state is

                    when idle =>

                        null;

                    when send =>

                        req_tx  <= '1';
                        tx_busy <= '1';

                    when done =>

                        tx_busy <= '1';

                    when others =>

                        null;

                end case;

            end if;

        end process p_fsm;

    end block fsm;

    tx_reg : process is
    begin

        wait until rising_edge(tx_clk);

        if tx_rst = '1' then
            tx_data_reg <= (others => '0');
        elsif tx_reg_en = '1' then
            tx_data_reg <= tx_data;
        end if;

    end process tx_reg;

    -----------
    -- RX logic
    -----------
    rs : entity accel.bit_sync
        generic map (
            stages => stages
        )
        port map (
            clk     => rx_clk,
            rst     => rx_rst,
            bit_in  => req_tx,
            bit_out => req_rx
        );

    ack_rx <= req_rx;

    req_change : process is
    begin

        wait until rising_edge(rx_clk);

        if rx_rst = '1' then
            prev_req <= '0';
            rx_data  <= (rx_data'range => '0');
            rx_new   <= '0';
        else
            prev_req <= req_rx;
            rx_new   <= '0';

            if req_rx = '1' and prev_req = '0' then -- Capture data
                rx_data <= tx_data_reg;
                rx_new  <= '1';
            end if;
        end if;

    end process req_change;

end architecture rtl;

library ieee;
    use ieee.std_logic_1164.all;

library accel;
    use accel.gray_code.all;

entity gray_sync is
    generic (
        stages : positive := 2 -- number of register stages
    );
    port (
        src_clk : in    std_logic;
        src_bin : in    std_logic_vector;

        dst_clk : in    std_logic;
        dst_bin : out   std_logic_vector
    );
end entity gray_sync;

architecture rtl of gray_sync is

    signal src_gray  : std_logic_vector(src_bin'range) := (others => '0');
    type   dst_gray_t is array(stages - 1 downto 0) of std_logic_vector(dst_bin'range);
    signal dst_gray  : dst_gray_t                      := (others => (others => '0'));
    signal dst_bin_s : std_logic_vector(dst_bin'range) := (others => '0');

    attribute async_reg : string;
    attribute async_reg of dst_gray : signal is "TRUE";

begin

    src : process is
    begin

        wait until rising_edge(src_clk);
        src_gray <= to_gray(src_bin);

    end process src;

    dst : process is
    begin

        wait until rising_edge(dst_clk);
        dst_gray(stages - 1) <= src_gray;

        for i in 0 to stages - 2 loop

            dst_gray(i) <= dst_gray(i + 1);

        end loop;

        dst_bin_s <= to_binary(dst_gray(0));

    end process dst;

    dst_bin <= dst_bin_s;

end architecture rtl;

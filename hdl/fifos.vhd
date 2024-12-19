-- loosely adapted from vhdl-extras (http://github.com/kevinpt/vhdl-extras)

library ieee;
    use ieee.std_logic_1164.all;

package fifos is

    -- single clock fifo
    component fifo is
        generic (
            mem_size : positive
        );
        port (
            clk : in    std_logic;
            rst : in    std_logic;

            wr   : in    std_logic;
            din  : in    std_logic_vector;
            full : out   std_logic;

            rd    : in    std_logic;
            dout  : out   std_logic_vector;
            empty : out   std_logic
        );
    end component fifo;

    -- dual clock fifo, optionally packet-based
    -- if USE_PACKETS is true, keep/discard must be assigned at
    -- least one cycle after the last write of the respective packet
    component dc_fifo is
        generic (
            mem_size    : positive;
            stages      : positive := 3;
            use_packets : boolean := false
        );
        port (
            wr_clk : in    std_logic;
            rst    : in    std_logic;

            wr_en       : in    std_logic;
            din         : in    std_logic_vector;
            full        : out   std_logic;
            almost_full : out   std_logic;
            keep        : in    std_logic;
            drop        : in    std_logic;

            rd_clk : in    std_logic;

            rd_en : in    std_logic;
            dout  : out   std_logic_vector;
            valid : out   std_logic;
            empty : out   std_logic
        );
    end component dc_fifo;

    -- fifo that assembles small input words to large output words
    -- valid indicates how many din words are in a word being read
    -- almost_empty is 1 if only an incomplete output word can be read
    -- component dc_merge_fifo is
    --     generic (
    --         mem_size    : positive;
    --         stages      : positive := 3
    --     );
    --     port (
    --         wr_clk : in    std_logic;
    --         rst    : in    std_logic;

    --         wr_en       : in    std_logic;
    --         din         : in    std_logic_vector;
    --         full        : out   std_logic;
    --         almost_full : out   std_logic;

    --         rd_clk : in    std_logic;

    --         rd_en        : in    std_logic;
    --         dout         : out   std_logic_vector;
    --         valid        : out   std_logic_vector;
    --         almost_empty : out   std_logic;
    --         empty        : out   std_logic
    --     );
    -- end component dc_merge_fifo;

end package fifos;

library ieee;
    use ieee.std_logic_1164.all;

entity fifo is
    generic (
        mem_size : positive -- number of words
    );
    port (
        clk : in    std_logic;
        rst : in    std_logic;

        wr   : in    std_logic;
        din  : in    std_logic_vector;
        full : out   std_logic;

        rd    : in    std_logic;
        dout  : out   std_logic_vector;
        empty : out   std_logic
    );
end entity fifo;

architecture wrap of fifo is

    type   memory_t is array(0 to mem_size - 1) of std_logic_vector(din'length-1 downto 0);
    signal memory              : memory_t;
    signal wrcnt,    rdcnt     : natural range 0 to mem_size - 1 := 0;
    signal full_loc, empty_loc : boolean;
    signal wrap                : boolean;

begin

    p_fifo : process is
    begin

        wait until rising_edge(clk);

        if rst = '1' then
            wrcnt <= 0;
            rdcnt <= 0;
            wrap  <= false;
        else
            if wr = '1' and not full_loc then
                memory(wrcnt) <= din;
                if wrcnt = mem_size - 1 then
                    wrcnt <= 0;
                    wrap  <= rdcnt = 0;
                else
                    wrcnt <= wrcnt + 1;
                    wrap  <= wrcnt + 1 = rdcnt;
                end if;
            end if;

            if rd = '1' and not empty_loc then
                dout <= memory(rdcnt);
                if rdcnt = mem_size - 1 then
                    rdcnt <= 0;
                else
                    rdcnt <= rdcnt + 1;
                end if;
                wrap <= false;
            end if;
        end if;

    end process p_fifo;

    full_loc  <= rdcnt = wrcnt + 1 or (wrap and rdcnt = wrcnt);
    empty_loc <= rdcnt = wrcnt and not wrap;

    full  <= '1' when full_loc else
             '0';
    empty <= '1' when empty_loc else
             '0';

end architecture wrap;

-- slightly less logic, but only capacity is one item smaller

architecture nowrap of fifo is

    type   memory_t is array(0 to mem_size - 1) of std_logic_vector(din'length-1 downto 0);
    signal memory              : memory_t;
    signal wrcnt,    rdcnt     : natural range 0 to mem_size - 1 := 0;
    signal full_loc, empty_loc : boolean;

begin

    p_fifo : process is
    begin

        wait until rising_edge(clk);

        if rst = '1' then
            wrcnt <= 0;
            rdcnt <= 0;
        else
            if wr = '1' and not full_loc then
                memory(wrcnt) <= din;
                if wrcnt = mem_size - 1 then
                    wrcnt <= 0;
                else
                    wrcnt <= wrcnt + 1;
                end if;
            end if;

            if rd = '1' and not empty_loc then
                dout <= memory(rdcnt);
                if rdcnt = mem_size - 1 then
                    rdcnt <= 0;
                else
                    rdcnt <= rdcnt + 1;
                end if;
            end if;
        end if;

    end process p_fifo;

    full_loc  <= rdcnt = wrcnt + 1 or (rdcnt = 0 and wrcnt = mem_size - 1);
    empty_loc <= rdcnt = wrcnt;

    full  <= '1' when full_loc else
             '0';
    empty <= '1' when empty_loc else
             '0';

end architecture nowrap;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.sync.gray_sync;

entity dc_fifo is
    generic (
        mem_size    : positive; -- number of words
        stages      : positive := 3;
        use_packets : boolean  := false
    );
    port (
        wr_clk : in    std_logic;
        rst    : in    std_logic;

        wr_en       : in    std_logic;
        din         : in    std_logic_vector;
        full        : out   std_logic;
        almost_full : out   std_logic;
        keep        : in    std_logic;
        drop        : in    std_logic;

        rd_clk : in    std_logic;

        rd_en : in    std_logic;
        dout  : out   std_logic_vector;
        valid : out   std_logic;
        empty : out   std_logic
    );
end entity dc_fifo;

architecture behav of dc_fifo is

    type   memory_t is array(0 to mem_size - 1) of std_logic_vector(din'length-1 downto 0);
    signal memory                : memory_t;
    signal wrcnt                 : natural range 0 to mem_size - 1 := 0;
    signal wrcnt_pkt             : natural range 0 to mem_size - 1 := 0;
    signal rdcnt                 : natural range 0 to mem_size - 1 := 0;
    signal wrcnt_rd,    rdcnt_wr : natural range 0 to mem_size - 1 := 0;
    signal full_loc              : boolean;
    signal empty_loc             : boolean;
    signal almost_full_loc       : boolean;

    constant cnt_width               : integer := integer(ceil(log2(real(mem_size))));
    signal   slv_wrcnt, slv_wrcnt_rd : std_logic_vector(cnt_width - 1 downto 0);
    signal   slv_rdcnt, slv_rdcnt_wr : std_logic_vector(cnt_width - 1 downto 0);

    signal r_dout : std_logic_vector(dout'range) := (dout'range => '0');

begin

    wr_proc : process is
    begin

        wait until rising_edge(wr_clk);

        if rst = '1' then
            wrcnt     <= 0;
            wrcnt_pkt <= 0;
        else
            if wr_en = '1' and not full_loc then
                memory(wrcnt) <= din;
                if wrcnt = mem_size - 1 then
                    wrcnt <= 0;
                else
                    wrcnt <= wrcnt + 1;
                end if;
            end if;

            if keep = '1' then
                wrcnt_pkt <= wrcnt;
            elsif drop = '1' then
                wrcnt <= wrcnt_pkt;
            end if;
        end if;

    end process wr_proc;

    rd_proc : process is
    begin

        wait until rising_edge(rd_clk);

        if rst = '1' then
            rdcnt <= 0;
            valid <= '0';
        else
            valid <= '0';
            if rd_en = '1' and not empty_loc then
                r_dout <= memory(rdcnt);
                valid  <= '1';
                if rdcnt = mem_size - 1 then
                    rdcnt <= 0;
                else
                    rdcnt <= rdcnt + 1;
                end if;
            end if;
        end if;

    end process rd_proc;

    dout <= r_dout;

    almost_full_loc <= rdcnt_wr = wrcnt + 2 or (rdcnt_wr = 0 and wrcnt = mem_size - 2) or (rdcnt_wr = 1 and wrcnt = mem_size - 1);
    full_loc        <= rdcnt_wr = wrcnt + 1 or (rdcnt_wr = 0 and wrcnt = mem_size - 1);
    empty_loc       <= rdcnt = wrcnt_rd;

    almost_full <= '1' when almost_full_loc or full_loc else
                   '0';
    full        <= '1' when full_loc else
                   '0';
    empty       <= '1' when empty_loc else
                   '0';

    sync_wrcnt : entity accel.gray_sync
        generic map (
            stages => stages
        )
        port map (
            src_clk => wr_clk,
            src_bin => slv_wrcnt,
            dst_clk => rd_clk,
            dst_bin => slv_wrcnt_rd
        );

    packet_fifo : if use_packets generate
        slv_wrcnt <= std_logic_vector(to_unsigned(wrcnt_pkt, cnt_width));
    end generate packet_fifo;

    normal_fifo : if not use_packets generate
        slv_wrcnt <= std_logic_vector(to_unsigned(wrcnt, cnt_width));
    end generate normal_fifo;

    wrcnt_rd <= to_integer(unsigned(slv_wrcnt_rd));

    sync_rdcnt : entity accel.gray_sync
        generic map (
            stages => stages
        )
        port map (
            src_clk => rd_clk,
            src_bin => slv_rdcnt,
            dst_clk => wr_clk,
            dst_bin => slv_rdcnt_wr
        );

    slv_rdcnt <= std_logic_vector(to_unsigned(rdcnt, cnt_width));
    rdcnt_wr  <= to_integer(unsigned(slv_rdcnt_wr));

end architecture behav;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.sync.gray_sync;

entity dc_merge_fifo is
    generic (
        mem_size    : positive; -- number of words
        stages      : positive := 3
    );
    port (
        wr_clk : in    std_logic;
        rst    : in    std_logic;

        wr_en       : in    std_logic;
        din         : in    std_logic_vector;
        last        : in    std_logic;
        full        : out   std_logic;
        almost_full : out   std_logic;

        rd_clk : in    std_logic;

        rd_en        : in    std_logic;
        dout         : out   std_logic_vector;
        valid        : out   std_logic;
        almost_empty : out   std_logic;
        empty        : out   std_logic
    );
end entity dc_merge_fifo;

-- architecture behav of dc_merge_fifo is

--     constant factor : positive := dout'length / din'length;

--     type   memory_t is array(0 to mem_size - 1) of std_logic_vector(dout'length-1 downto 0);
--     signal memory                : memory_t;
--     signal wrcnt                 : natural range 0 to mem_size - 1 := 0;
--     -- signal wrcnt_pkt             : natural range 0 to mem_size - 1 := 0;
--     signal rdcnt                 : natural range 0 to mem_size - 1 := 0;
--     signal wrcnt_rd,    rdcnt_wr : natural range 0 to mem_size - 1 := 0;
--     signal full_loc              : boolean;
--     signal empty_loc             : boolean;
--     signal almost_full_loc       : boolean;

--     constant cnt_width               : integer := integer(ceil(log2(real(mem_size))));
--     signal   slv_wrcnt, slv_wrcnt_rd : std_logic_vector((cnt_width * 4) - 1 downto 0);
--     signal   slv_rdcnt, slv_rdcnt_wr : std_logic_vector(cnt_width - 1 downto 0);

--     signal r_dout : std_logic_vector(dout'range) := (dout'range => '0');

-- begin

--     wr_proc : process is
--     begin

--         wait until rising_edge(wr_clk);

--         if rst = '1' then
--             wrcnt     <= 0;
--         else
--             if wr_en = '1' and not full_loc then
--                 memory(wrcnt) <= din;
--                 if wrcnt = mem_size - 1 then
--                     wrcnt <= 0;
--                 else
--                     wrcnt <= wrcnt + 1;
--                 end if;
--             end if;

--             if keep = '1' then
--                 wrcnt_pkt <= wrcnt;
--             elsif drop = '1' then
--                 wrcnt <= wrcnt_pkt;
--             end if;
--         end if;

--     end process wr_proc;

--     rd_proc : process is
--     begin

--         wait until rising_edge(rd_clk);

--         if rst = '1' then
--             rdcnt <= 0;
--             valid <= '0';
--         else
--             valid <= '0';
--             if rd_en = '1' and not empty_loc then
--                 r_dout <= memory(rdcnt);
--                 valid  <= '1';
--                 if rdcnt = mem_size - 1 then
--                     rdcnt <= 0;
--                 else
--                     rdcnt <= rdcnt + 1;
--                 end if;
--             end if;
--         end if;

--     end process rd_proc;

--     dout <= r_dout;

--     almost_full_loc <= rdcnt_wr = wrcnt + 2 or (rdcnt_wr = 0 and wrcnt = mem_size - 2) or (rdcnt_wr = 1 and wrcnt = mem_size - 1);
--     full_loc        <= rdcnt_wr = wrcnt + 1 or (rdcnt_wr = 0 and wrcnt = mem_size - 1);
--     empty_loc       <= rdcnt = wrcnt_rd;

--     almost_full <= '1' when almost_full_loc or full_loc else
--                    '0';
--     full        <= '1' when full_loc else
--                    '0';
--     empty       <= '1' when empty_loc else
--                    '0';

--     sync_wrcnt : entity accel.gray_sync
--         generic map (
--             stages => stages
--         )
--         port map (
--             src_clk => wr_clk,
--             src_bin => slv_wrcnt,
--             dst_clk => rd_clk,
--             dst_bin => slv_wrcnt_rd
--         );

--     packet_fifo : if use_packets generate
--         slv_wrcnt <= std_logic_vector(to_unsigned(wrcnt_pkt, cnt_width));
--     end generate packet_fifo;

--     normal_fifo : if not use_packets generate
--         slv_wrcnt <= std_logic_vector(to_unsigned(wrcnt, cnt_width));
--     end generate normal_fifo;

--     wrcnt_rd <= to_integer(unsigned(slv_wrcnt_rd));

--     sync_rdcnt : entity accel.gray_sync
--         generic map (
--             stages => stages
--         )
--         port map (
--             src_clk => rd_clk,
--             src_bin => slv_rdcnt,
--             dst_clk => wr_clk,
--             dst_bin => slv_rdcnt_wr
--         );

--     slv_rdcnt <= std_logic_vector(to_unsigned(rdcnt, cnt_width));
--     rdcnt_wr  <= to_integer(unsigned(slv_rdcnt_wr));

-- end architecture behav;

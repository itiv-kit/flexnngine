-- memory with a "standard" interface for unmodified data access
-- and a "reshaped" interface to help converting nchw data to nhwc or vice versa
--
-- example for cols=4:
--            column: 1   2   3   4
-- store ABCD,      | A | E | I | M |
-- store EFGH,   -> | B | F | J | N |
-- store IJKL,      | C | G | K | O |
-- store MNOP       | D | H | L | P |
--                    \---+---+---+---> read AEIM, BFJN, CGKO, DHLP

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity spad_reshape is
    generic (
        word_size : positive := 8; -- bits of a single word
        cols      : positive := 8; -- columns of word_size words
        -- std_words : positive := cols; -- words of the standard interface, can be multiples of cols

        addr_width : positive := 8; -- address width for standard & reshaped ports
        data_width : positive := cols * word_size;

        initialize  : boolean := false;
        file_prefix : string  := "_mem_col"
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        -- "standard" interface for non-reshaped data I/O
        std_en   : in    std_logic;
        std_wen  : in    std_logic_vector(cols - 1 downto 0);
        std_addr : in    std_logic_vector(addr_width - 1 downto 0);
        std_din  : in    std_logic_vector(data_width - 1 downto 0);
        std_dout : out   std_logic_vector(data_width - 1 downto 0);

        -- "reshaped" interface to read nchw <-> nhwc reshaped data (currently read only)
        rsh_en   : in    std_logic;
        rsh_addr : in    std_logic_vector(addr_width - 1 downto 0);
        rsh_dout : out   std_logic_vector(data_width - 1 downto 0)
    );
end entity spad_reshape;

architecture rtl of spad_reshape is

    constant col_sel_width  : integer := integer(ceil(log2(real(cols))));
    constant ram_addr_width : integer := addr_width - col_sel_width;

    signal w_std_en   : std_logic_vector(0 to cols - 1);
    signal w_std_wen  : array_t(0 to cols - 1)(cols - 1 downto 0);
    signal w_std_addr : array_t(0 to cols - 1)(ram_addr_width - 1 downto 0);
    signal w_std_din  : array_t(0 to cols - 1)(data_width - 1 downto 0);
    signal w_std_dout : array_t(0 to cols - 1)(data_width - 1 downto 0);
    signal w_rsh_en   : std_logic_vector(0 to cols - 1);
    signal w_rsh_addr : array_t(0 to cols - 1)(ram_addr_width - 1 downto 0);
    signal w_rsh_dout : array_t(0 to cols - 1)(data_width - 1 downto 0);

    signal r_std_addr_delay : std_logic_vector(addr_width - 1 downto 0);
    signal r_rsh_addr_delay : std_logic_vector(addr_width - 1 downto 0);

begin

    gen_cols : for i in 0 to cols - 1 generate

        w_std_wen(i)  <= std_wen;
        w_std_addr(i) <= std_addr(ram_addr_width - 1 downto 0);
        w_std_din(i)  <= std_din;
        w_rsh_en(i)   <= rsh_en;
        w_rsh_addr(i) <= rsh_addr(addr_width - 1 downto col_sel_width);

        ram : entity accel.ram_dp_bwe
            generic map (
                size       => 2 ** ram_addr_width,
                addr_width => ram_addr_width,
                col_width  => word_size,
                nb_col     => cols,
                initialize => initialize,
                init_file  => file_prefix & integer'image(i) & ".txt"
            )
            port map (
                clk => clk,
                -- standard access
                ena   => w_std_en(i),
                wea   => w_std_wen(i),
                addra => w_std_addr(i),
                dia   => w_std_din(i),
                doa   => w_std_dout(i),
                -- reshaped read-only access
                enb   => w_rsh_en(i),
                web   => (others => '0'),
                addrb => w_rsh_addr(i),
                dib   => (others => '0'),
                dob   => w_rsh_dout(i)
            );

    end generate gen_cols;

    addr_delay : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' then
            r_std_addr_delay <= (others => '0');
            r_rsh_addr_delay <= (others => '0');
        else
            if std_en and not (or std_wen) then
                r_std_addr_delay <= std_addr;
            end if;

            if rsh_en then
                r_rsh_addr_delay <= rsh_addr;
            end if;
        end if;

    end process addr_delay;

    std_write : process (all) is

        variable index : integer range 0 to cols - 1;

    begin

        -- from std view, memories are connected serially in the address space
        index           := to_integer(unsigned(std_addr(addr_width - 1 downto ram_addr_width)));
        w_std_en        <= (others => '0');
        w_std_en(index) <= std_en;

    end process std_write;

    std_read : process (all) is

        variable index : integer range 0 to cols - 1;

    begin

        index    := to_integer(unsigned(r_std_addr_delay(addr_width - 1 downto ram_addr_width)));
        std_dout <= w_std_dout(index);

    end process std_read;

    rsh_read : process (all) is

        variable index : integer range 0 to cols - 1;

    begin

        index := to_integer(unsigned(r_rsh_addr_delay(col_sel_width - 1 downto 0)));

        for c in 0 to cols - 1 loop

            rsh_dout((c + 1) * word_size - 1 downto c * word_size) <= w_rsh_dout(c)((index + 1) * word_size - 1 downto index * word_size);

        end loop;

    end process rsh_read;

end architecture rtl;

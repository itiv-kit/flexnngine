library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
        data_width_iact_a : positive := 32;
        addr_width_iact_a : positive := 15;

        data_width_psum_a : positive := 32;
        addr_width_psum_a : positive := 15;

        data_width_wght_a : positive := 32;
        addr_width_wght_a : positive := 15;

        data_width_iact_b : positive := 8;
        addr_width_iact_b : positive := 15;

        data_width_psum_b : positive := 16;
        addr_width_psum_b : positive := 15;

        data_width_wght_b : positive := 8;
        addr_width_wght_b : positive := 15;

        initialize_mems : boolean := false;
        g_files_dir     : string  := ""
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        write_adr_iact : in    std_logic_vector(addr_width_iact_a - 1 downto 0);
        write_adr_psum : in    std_logic_vector(addr_width_psum_b - 1 downto 0);
        write_adr_wght : in    std_logic_vector(addr_width_wght_a - 1 downto 0);

        read_adr_iact : in    std_logic_vector(addr_width_iact_b - 1 downto 0);
        read_adr_psum : in    std_logic_vector(addr_width_psum_a - 1 downto 0);
        read_adr_wght : in    std_logic_vector(addr_width_wght_b - 1 downto 0);

        write_en_iact : in    std_logic;
        write_en_psum : in    std_logic;
        write_en_wght : in    std_logic;

        read_en_iact : in    std_logic;
        read_en_psum : in    std_logic;
        read_en_wght : in    std_logic;

        din_iact : in    std_logic_vector(data_width_iact_a - 1 downto 0);
        din_psum : in    std_logic_vector(data_width_psum_b - 1 downto 0);
        din_wght : in    std_logic_vector(data_width_wght_a - 1 downto 0);

        bus_dout_iact : out   std_logic_vector(data_width_iact_a - 1 downto 0);
        bus_dout_wght : out   std_logic_vector(data_width_wght_a - 1 downto 0);

        dout_iact : out   std_logic_vector(data_width_iact_b - 1 downto 0);
        dout_psum : out   std_logic_vector(data_width_psum_a - 1 downto 0);
        dout_wght : out   std_logic_vector(data_width_wght_b - 1 downto 0);

        dout_iact_valid : out   std_logic;
        dout_psum_valid : out   std_logic;
        dout_wght_valid : out   std_logic
    );
end entity scratchpad;

architecture rtl of scratchpad is

    signal ena_iact            : std_logic                                                            := '1';
    signal enb_iact            : std_logic                                                            := '1';
    signal ena_wght            : std_logic                                                            := '1';
    signal enb_wght            : std_logic                                                            := '1';
    signal ena_psum            : std_logic                                                            := '1';
    signal enb_psum            : std_logic                                                            := '1';
    signal wea_iact            : std_logic_vector(data_width_iact_a / data_width_iact_b - 1 downto 0) := (others => '0');
    signal wea_wght            : std_logic_vector(data_width_wght_a / data_width_wght_b - 1 downto 0) := (others => '0');
    signal wea_psum            : std_logic_vector(data_width_psum_a / data_width_psum_b - 1 downto 0) := (others => '0');
    signal web_iact            : std_logic_vector(data_width_iact_a / data_width_iact_b - 1 downto 0) := (others => '0');
    signal web_wght            : std_logic_vector(data_width_wght_a / data_width_wght_b - 1 downto 0) := (others => '0');
    signal web_psum            : std_logic_vector(data_width_psum_a / data_width_psum_b - 1 downto 0) := (others => '0');
    signal addrb_iact          : std_logic_vector(addr_width_iact_a - 1 downto 0);
    signal datab_iact          : std_logic_vector(data_width_iact_a - 1 downto 0);
    signal addrb_wght          : std_logic_vector(addr_width_wght_a - 1 downto 0);
    signal datab_wght          : std_logic_vector(data_width_wght_a - 1 downto 0);
    signal addrb_psum          : std_logic_vector(addr_width_psum_a - 1 downto 0);
    signal datab_psum          : std_logic_vector(data_width_psum_a - 1 downto 0);
    signal dob_psum            : std_logic_vector(data_width_psum_a - 1 downto 0);
    signal read_adr_wght_buff  : std_logic_vector(addr_width_wght_b - 1 downto 0)                     := (others => '0');
    signal read_adr_iact_buff  : std_logic_vector(addr_width_iact_b - 1 downto 0)                     := (others => '0');
    signal write_adr_psum_buff : std_logic_vector(addr_width_psum_b - 1 downto 0)                     := (others => '0');

begin

    dout_iact_valid <= read_en_iact when rising_edge(clk);
    dout_psum_valid <= read_en_psum when rising_edge(clk);
    dout_wght_valid <= read_en_wght when rising_edge(clk);

    -- enable signals of RAM always High;
    ena_iact <= '1';
    enb_iact <= '1';
    ena_wght <= '1';
    enb_wght <= '1';
    ena_psum <= '1';
    enb_psum <= '1';

    -- addresses for portb
    addrb_iact <= read_adr_iact(addr_width_iact_b - 1 downto addr_width_iact_b - addr_width_iact_a);
    addrb_wght <= read_adr_wght(addr_width_wght_b - 1 downto addr_width_wght_b - addr_width_wght_a);
    addrb_psum <= write_adr_psum_buff(addr_width_psum_b - 1 downto addr_width_psum_b - addr_width_psum_a);

    read_adr_iact_buff <= read_adr_iact when rising_edge(clk);

    iact : process (read_adr_iact, datab_iact, din_iact, write_adr_iact, write_en_iact) is

        variable index : integer;

    begin

        index     := to_integer(unsigned(read_adr_iact_buff(addr_width_iact_b - addr_width_iact_a - 1 downto 0)));
        dout_iact <= datab_iact(data_width_iact_b * (index + 1) - 1 downto data_width_iact_b * index);

        if write_en_iact = '1' then
            wea_iact <= (others => '1');
        else
            wea_iact <= (others => '0');
        end if;

    end process iact;

    read_adr_wght_buff <= read_adr_wght when rising_edge(clk);

    wght : process (read_adr_wght, datab_wght, din_wght, write_adr_wght, write_en_wght) is

        variable index : integer;

    begin

        index     := to_integer(unsigned(read_adr_wght_buff(addr_width_wght_b - addr_width_wght_a - 1 downto 0)));
        dout_wght <= datab_wght(data_width_wght_b * (index + 1) - 1 downto data_width_wght_b * index);

        if write_en_wght = '1' then
            wea_wght <= (others => '1');
        else
            wea_wght <= (others => '0');
        end if;

    end process wght;

    psum : process (clk) is

        variable index : integer;

    begin

        index := to_integer(unsigned(write_adr_psum(addr_width_psum_b - addr_width_psum_a - 1 downto 0)));

        if rising_edge(clk) then
            web_psum <= (others => '0');
            if write_en_psum = '1' then
                -- datab_psum <= (others => '0');
                datab_psum(data_width_psum_b * (index + 1) - 1 downto data_width_psum_b * index) <= din_psum;
                web_psum(index)                                                                  <= '1';
                write_adr_psum_buff                                                              <= write_adr_psum;
            end if;
        end if;

    end process psum;

    ram_iact : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** addr_width_iact_a,
            addr_width    => addr_width_iact_a,
            col_width     => data_width_iact_b,
            nb_col        => data_width_iact_a / data_width_iact_b,
            init_file     => g_files_dir & "_mem_iact.txt",
            generate_init => initialize_mems
        )
        port map (
            clka  => clk,
            ena   => ena_iact,
            wea   => wea_iact,
            addra => write_adr_iact,
            dia   => din_iact,
            doa   => bus_dout_iact,
            clkb  => clk,
            enb   => enb_iact,
            web   => web_iact,
            addrb => addrb_iact,
            dib   => (others => '0'),
            dob   => datab_iact
        );

    ram_wght : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** addr_width_wght_a,
            addr_width    => addr_width_wght_a,
            col_width     => data_width_wght_b,
            nb_col        => data_width_wght_a / data_width_wght_b,
            init_file     => g_files_dir & "_mem_wght_stack.txt",
            generate_init => initialize_mems
        )
        port map (
            clka  => clk,
            ena   => ena_wght,
            wea   => wea_wght,
            addra => write_adr_wght,
            dia   => din_wght,
            doa   => bus_dout_wght,
            clkb  => clk,
            enb   => enb_wght,
            web   => web_wght,
            addrb => addrb_wght,
            dib   => (others => '0'),
            dob   => datab_wght
        );

    ram_psum : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** addr_width_psum_a,
            addr_width    => addr_width_psum_a,
            col_width     => data_width_psum_b,
            nb_col        => data_width_psum_a / data_width_psum_b,
            init_file     => g_files_dir & "_mem_psum.txt",
            generate_init => initialize_mems
        )
        port map (
            clka  => clk,
            ena   => ena_psum,
            wea   => wea_psum,
            addra => read_adr_psum,
            dia   => (others => '0'),
            doa   => dout_psum,
            clkb  => clk,
            enb   => enb_wght,
            web   => web_psum,
            addrb => addrb_psum,
            dib   => datab_psum,
            dob   => dob_psum
        );

end architecture rtl;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
        ext_data_width_iact : positive := 32;
        ext_addr_width_iact : positive := 15;

        ext_data_width_psum : positive := 32;
        ext_addr_width_psum : positive := 15;

        ext_data_width_wght : positive := 32;
        ext_addr_width_wght : positive := 15;

        data_width_iact : positive := 8;
        addr_width_iact : positive := 15;

        data_width_psum : positive := 16;
        addr_width_psum : positive := 15;

        data_width_wght : positive := 8;
        addr_width_wght : positive := 15;

        initialize_mems : boolean := false;
        g_files_dir     : string  := ""
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        -- internal addresses and control signals used by the pe array / address generator
        read_adr_iact  : in    std_logic_vector(addr_width_iact - 1 downto 0);
        read_adr_wght  : in    std_logic_vector(addr_width_wght - 1 downto 0);
        write_adr_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);

        read_en_iact  : in    std_logic;
        read_en_wght  : in    std_logic;
        write_en_psum : in    std_logic;

        dout_iact_valid : out   std_logic;
        dout_wght_valid : out   std_logic;

        dout_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
        dout_wght : out   std_logic_vector(data_width_wght - 1 downto 0);
        din_psum  : in    std_logic_vector(data_width_psum - 1 downto 0);

        -- external r/w access to scratchpad memories
        ext_write_en_iact : in    std_logic;
        ext_write_en_wght : in    std_logic;
        ext_write_en_psum : in    std_logic;

        ext_addr_iact : in    std_logic_vector(ext_addr_width_iact - 1 downto 0);
        ext_addr_wght : in    std_logic_vector(ext_addr_width_wght - 1 downto 0);
        ext_addr_psum : in    std_logic_vector(ext_addr_width_psum - 1 downto 0);

        ext_din_iact : in    std_logic_vector(ext_data_width_iact - 1 downto 0);
        ext_din_wght : in    std_logic_vector(ext_data_width_wght - 1 downto 0);
        ext_din_psum : in    std_logic_vector(ext_data_width_psum - 1 downto 0);

        ext_dout_iact : out   std_logic_vector(ext_data_width_iact - 1 downto 0);
        ext_dout_wght : out   std_logic_vector(ext_data_width_wght - 1 downto 0);
        ext_dout_psum : out   std_logic_vector(ext_data_width_psum - 1 downto 0)
    );
end entity scratchpad;

architecture rtl of scratchpad is

    constant cols_iact : integer := ext_data_width_iact / data_width_iact;
    constant cols_wght : integer := ext_data_width_wght / data_width_wght;
    constant cols_psum : integer := ext_data_width_psum / data_width_psum;

    signal ena_iact            : std_logic                                        := '1';
    signal enb_iact            : std_logic                                        := '1';
    signal ena_wght            : std_logic                                        := '1';
    signal enb_wght            : std_logic                                        := '1';
    signal ena_psum            : std_logic                                        := '1';
    signal enb_psum            : std_logic                                        := '1';
    signal wea_iact            : std_logic_vector(cols_iact - 1 downto 0)         := (others => '0');
    signal web_iact            : std_logic_vector(cols_iact - 1 downto 0)         := (others => '0');
    signal wea_wght            : std_logic_vector(cols_wght - 1 downto 0)         := (others => '0');
    signal web_wght            : std_logic_vector(cols_wght - 1 downto 0)         := (others => '0');
    signal wea_psum            : std_logic_vector(cols_psum - 1 downto 0)         := (others => '0');
    signal web_psum            : std_logic_vector(cols_psum - 1 downto 0)         := (others => '0');
    signal addrb_iact          : std_logic_vector(ext_addr_width_iact - 1 downto 0);
    signal datab_iact          : std_logic_vector(ext_data_width_iact - 1 downto 0);
    signal addrb_wght          : std_logic_vector(ext_addr_width_wght - 1 downto 0);
    signal datab_wght          : std_logic_vector(ext_data_width_wght - 1 downto 0);
    signal addrb_psum          : std_logic_vector(ext_addr_width_psum - 1 downto 0);
    signal datab_psum          : std_logic_vector(ext_data_width_psum - 1 downto 0);
    signal read_adr_wght_buff  : std_logic_vector(addr_width_wght - 1 downto 0) := (others => '0');
    signal read_adr_iact_buff  : std_logic_vector(addr_width_iact - 1 downto 0) := (others => '0');
    signal write_adr_psum_buff : std_logic_vector(addr_width_psum - 1 downto 0) := (others => '0');

begin

    dout_iact_valid <= read_en_iact when rising_edge(clk);
    dout_wght_valid <= read_en_wght when rising_edge(clk);

    -- enable signals of RAM always high
    ena_iact <= '1';
    enb_iact <= '1';
    ena_wght <= '1';
    enb_wght <= '1';
    ena_psum <= '1';
    enb_psum <= '1';

    -- iact & wght never written to internally
    web_iact <= (others => '0');
    web_wght <= (others => '0');

    -- addresses for portb
    addrb_iact <= read_adr_iact(addr_width_iact - 1 downto addr_width_iact - ext_addr_width_iact);
    addrb_wght <= read_adr_wght(addr_width_wght - 1 downto addr_width_wght - ext_addr_width_wght);
    addrb_psum <= write_adr_psum_buff(addr_width_psum - 1 downto addr_width_psum - ext_addr_width_psum);

    read_adr_iact_buff <= read_adr_iact when rising_edge(clk);

    iact : process (read_adr_iact_buff, datab_iact) is

        variable index : integer;

    begin

        index     := to_integer(unsigned(read_adr_iact_buff(addr_width_iact - ext_addr_width_iact - 1 downto 0)));
        dout_iact <= datab_iact(data_width_iact * (index + 1) - 1 downto data_width_iact * index);

    end process iact;

    read_adr_wght_buff <= read_adr_wght when rising_edge(clk);

    wght : process (read_adr_wght_buff, datab_wght) is

        variable index : integer;

    begin

        index     := to_integer(unsigned(read_adr_wght_buff(addr_width_wght - ext_addr_width_wght - 1 downto 0)));
        dout_wght <= datab_wght(data_width_wght * (index + 1) - 1 downto data_width_wght * index);

    end process wght;

    -- external accesses always write all words
    wea_iact <= (others => ext_write_en_iact);
    wea_wght <= (others => ext_write_en_wght);
    wea_psum <= (others => ext_write_en_psum);

    psum : process is

        variable index : integer;

    begin

        wait until rising_edge(clk);

        index := to_integer(unsigned(write_adr_psum(addr_width_psum - ext_addr_width_psum - 1 downto 0)));
        web_psum <= (others => '0');
        if write_en_psum = '1' then
            -- datab_psum <= (others => '0');
            datab_psum(data_width_psum * (index + 1) - 1 downto data_width_psum * index) <= din_psum;
            web_psum(index)                                                                  <= '1';
            write_adr_psum_buff                                                              <= write_adr_psum;
        end if;

    end process psum;

    ram_iact : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** ext_addr_width_iact,
            addr_width    => ext_addr_width_iact,
            col_width     => data_width_iact,
            nb_col        => cols_iact,
            initialize    => initialize_mems,
            init_file     => g_files_dir & "_mem_iact.txt"
        )
        port map (
            -- external access
            clka  => clk,
            ena   => ena_iact,
            wea   => wea_iact,
            addra => ext_addr_iact,
            dia   => ext_din_iact,
            doa   => ext_dout_iact,
            -- internal access
            clkb  => clk,
            enb   => enb_iact,
            web   => web_iact,
            addrb => addrb_iact,
            dib   => (others => '0'),
            dob   => datab_iact
        );

    ram_wght : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** ext_addr_width_wght,
            addr_width    => ext_addr_width_wght,
            col_width     => data_width_wght,
            nb_col        => cols_wght,
            initialize    => initialize_mems,
            init_file     => g_files_dir & "_mem_wght_stack.txt"
        )
        port map (
            -- external access
            clka  => clk,
            ena   => ena_wght,
            wea   => wea_wght,
            addra => ext_addr_wght,
            dia   => ext_din_wght,
            doa   => ext_dout_wght,
            -- internal access
            clkb  => clk,
            enb   => enb_wght,
            web   => web_wght,
            addrb => addrb_wght,
            dib   => (others => '0'),
            dob   => datab_wght
        );

    ram_psum : entity accel.bytewrite_tdp_ram_rf
        generic map (
            size          => 2 ** ext_addr_width_psum,
            addr_width    => ext_addr_width_psum,
            col_width     => data_width_psum,
            nb_col        => cols_psum,
            initialize    => false,
            init_file     => g_files_dir & "_mem_psum.txt"
        )
        port map (
            -- external access
            clka  => clk,
            ena   => ena_psum,
            wea   => wea_psum,
            addra => ext_addr_psum,
            dia   => ext_din_psum,
            doa   => ext_dout_psum,
            -- internal access
            clkb  => clk,
            enb   => enb_psum,
            web   => web_psum,
            addrb => addrb_psum,
            dib   => datab_psum,
            dob   => open
        );

end architecture rtl;

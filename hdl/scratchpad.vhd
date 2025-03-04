library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
        ext_data_width_iact : positive := 32;
        ext_addr_width_iact : positive := 13;

        ext_data_width_psum : positive := 32;
        ext_addr_width_psum : positive := 14;

        ext_data_width_wght : positive := 32;
        ext_addr_width_wght : positive := 13;

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
        clk     : in    std_logic;
        ext_clk : in    std_logic; -- clock for external spad interfaces
        rstn    : in    std_logic;

        -- internal addresses and control signals used by the pe array / address generator
        read_adr_iact  : in    std_logic_vector(addr_width_iact - 1 downto 0);
        read_adr_wght  : in    std_logic_vector(addr_width_wght - 1 downto 0);
        write_adr_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);

        read_en_iact    : in    std_logic;
        read_en_wght    : in    std_logic;
        write_en_psum   : in    std_logic;
        write_half_psum : in    std_logic;

        dout_iact_valid : out   std_logic;
        dout_wght_valid : out   std_logic;

        dout_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
        dout_wght : out   std_logic_vector(data_width_wght - 1 downto 0);
        din_psum  : in    std_logic_vector(data_width_psum - 1 downto 0);

        -- external r/w access to scratchpad memories
        ext_en_iact : in    std_logic;
        ext_en_wght : in    std_logic;
        ext_en_psum : in    std_logic;

        ext_write_en_iact : in    std_logic_vector(ext_data_width_iact / 8 - 1 downto 0);
        ext_write_en_wght : in    std_logic_vector(ext_data_width_wght / 8 - 1 downto 0);
        ext_write_en_psum : in    std_logic_vector(ext_data_width_psum / 8 - 1 downto 0);

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

    constant cols_iact : integer := ext_data_width_iact / 8;
    constant cols_wght : integer := ext_data_width_wght / 8;
    constant cols_psum : integer := ext_data_width_psum / 8;

    signal enb_iact           : std_logic                                      := '1';
    signal enb_wght           : std_logic                                      := '1';
    signal enb_psum           : std_logic                                      := '1';
    signal web_iact           : std_logic_vector(cols_iact - 1 downto 0)       := (others => '0');
    signal web_wght           : std_logic_vector(cols_wght - 1 downto 0)       := (others => '0');
    signal web_psum           : std_logic_vector(cols_psum - 1 downto 0)       := (others => '0');
    signal addrb_iact         : std_logic_vector(ext_addr_width_iact - 1 downto 0);
    signal datab_iact         : std_logic_vector(ext_data_width_iact - 1 downto 0);
    signal addrb_wght         : std_logic_vector(ext_addr_width_wght - 1 downto 0);
    signal datab_wght         : std_logic_vector(ext_data_width_wght - 1 downto 0);
    signal addrb_psum         : std_logic_vector(ext_addr_width_psum - 1 downto 0);
    signal datab_psum         : std_logic_vector(ext_data_width_psum - 1 downto 0);
    signal read_adr_wght_buff : std_logic_vector(addr_width_wght - 1 downto 0) := (others => '0');
    signal read_adr_iact_buff : std_logic_vector(addr_width_iact - 1 downto 0) := (others => '0');

begin

    enb_iact <= read_en_iact;
    enb_wght <= read_en_wght;

    -- bram/sram: data valid after one cycle
    dout_iact_valid <= read_en_iact when rising_edge(clk);
    dout_wght_valid <= read_en_wght when rising_edge(clk);

    -- iact & wght never written to internally
    web_iact <= (others => '0');
    web_wght <= (others => '0');

    -- addresses for portb
    addrb_iact <= read_adr_iact(addr_width_iact - 1 downto addr_width_iact - ext_addr_width_iact);
    addrb_wght <= read_adr_wght(addr_width_wght - 1 downto addr_width_wght - ext_addr_width_wght);

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

    psum_gen : if ext_data_width_psum = 32 generate

        psum : process is

            variable index : integer;

        begin

            wait until rising_edge(clk);

            if write_half_psum = '1' then
                index := to_integer(unsigned(write_adr_psum(addr_width_psum - ext_addr_width_psum downto 0)));

                addrb_psum <= '0' & write_adr_psum(addr_width_psum - 1 downto addr_width_psum - ext_addr_width_psum + 1);
                datab_psum <= din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0);
                enb_psum   <= write_en_psum;
                web_psum   <= (others => '0');

                if write_en_psum = '1' then
                    with index select web_psum <=
                        "1000" when 3,
                        "0100" when 2,
                        "0010" when 1,
                        "0001" when others;
                end if;
            else
                index := to_integer(unsigned(write_adr_psum(addr_width_psum - ext_addr_width_psum - 1 downto 0)));

                addrb_psum <= write_adr_psum(addr_width_psum - 1 downto addr_width_psum - ext_addr_width_psum);
                datab_psum <= din_psum & din_psum;
                enb_psum   <= write_en_psum;
                web_psum   <= (others => '0');

                -- TODO: generalize, currently fixed for 32bit spad 8bit cols 16bit psums
                if write_en_psum = '1' then
                    if index = 1 then
                        web_psum <= "1100";
                    else
                        web_psum <= "0011";
                    end if;
                -- datab_psum <= (others => '0');
                -- datab_psum(data_width_psum * (index + 1) - 1 downto data_width_psum * index) <= din_psum;
                -- web_psum(index)                                                              <= '1';
                end if;
            end if;

        end process psum;

    elsif ext_data_width_psum = 64 generate

        psum : process is

            variable index : integer;

        begin

            wait until rising_edge(clk);

            if write_half_psum = '1' then
                index := to_integer(unsigned(write_adr_psum(addr_width_psum - ext_addr_width_psum downto 0)));

                addrb_psum <= '0' & write_adr_psum(addr_width_psum - 1 downto addr_width_psum - ext_addr_width_psum + 1);
                enb_psum   <= write_en_psum;
                web_psum   <= (others => '0');

                -- concat iact data n=8 times to make full 64 bit word
                for i in 0 to ext_data_width_psum / data_width_iact - 1 loop

                    datab_psum(data_width_iact * (i + 1) - 1 downto data_width_iact * i) <= din_psum(data_width_iact - 1 downto 0);

                end loop;

                -- select subword to write to
                if write_en_psum = '1' then
                    with index select web_psum <=
                        "10000000" when 7,
                        "01000000" when 6,
                        "00100000" when 5,
                        "00010000" when 4,
                        "00001000" when 3,
                        "00000100" when 2,
                        "00000010" when 1,
                        "00000001" when others;
                end if;
            else
                index := to_integer(unsigned(write_adr_psum(addr_width_psum - ext_addr_width_psum - 1 downto 0)));

                addrb_psum <= write_adr_psum(addr_width_psum - 1 downto addr_width_psum - ext_addr_width_psum);
                datab_psum <= din_psum & din_psum & din_psum & din_psum;
                enb_psum   <= write_en_psum;
                web_psum   <= (others => '0');

                if write_en_psum = '1' then
                    with index select web_psum <=
                        "11000000" when 3,
                        "00110000" when 2,
                        "00001100" when 1,
                        "00000011" when others;
                end if;
            end if;

        end process psum;

    else generate

        psum : process is
        begin

            report "psum spad width " & integer'image(ext_addr_width_psum) & " not implemented"
                severity failure;

        end process psum;

    end generate psum_gen;

    ram_iact : entity accel.ram_dp_bwe
        generic map (
            size       => 2 ** ext_addr_width_iact,
            addr_width => ext_addr_width_iact,
            col_width  => 8,
            nb_col     => cols_iact,
            initialize => initialize_mems,
            init_file  => g_files_dir & "_mem_iact.txt"
        )
        port map (
            -- external access
            clka  => ext_clk,
            ena   => ext_en_iact,
            wea   => ext_write_en_iact,
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

    ram_wght : entity accel.ram_dp_bwe
        generic map (
            size       => 2 ** ext_addr_width_wght,
            addr_width => ext_addr_width_wght,
            col_width  => 8,
            nb_col     => cols_wght,
            initialize => initialize_mems,
            init_file  => g_files_dir & "_mem_wght_stack.txt"
        )
        port map (
            -- external access
            clka  => ext_clk,
            ena   => ext_en_wght,
            wea   => ext_write_en_wght,
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

    ram_psum : entity accel.ram_dp_bwe
        generic map (
            size       => 2 ** ext_addr_width_psum,
            addr_width => ext_addr_width_psum,
            col_width  => 8,
            nb_col     => cols_psum,
            initialize => false,
            init_file  => g_files_dir & "_mem_psum.txt"
        )
        port map (
            -- external access
            clka  => ext_clk,
            ena   => ext_en_psum,
            wea   => ext_write_en_psum,
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

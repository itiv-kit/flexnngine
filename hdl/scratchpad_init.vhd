library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity scratchpad_init is
    generic (
        data_width_iact : positive := 8;
        addr_width_iact : positive := 15;

        data_width_psum : positive := 16;
        addr_width_psum : positive := 15;

        data_width_wght : positive := 8;
        addr_width_wght : positive := 15;

        g_files_dir : string := ""
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        write_adr_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        write_adr_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        write_adr_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        read_adr_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
        read_adr_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
        read_adr_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

        write_en_iact : in    std_logic;
        write_en_psum : in    std_logic;
        write_en_wght : in    std_logic;

        read_en_iact : in    std_logic;
        read_en_psum : in    std_logic;
        read_en_wght : in    std_logic;

        din_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        din_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
        din_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

        dout_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
        dout_psum : out   std_logic_vector(data_width_psum - 1 downto 0);
        dout_wght : out   std_logic_vector(data_width_wght - 1 downto 0);

        dout_iact_valid : out   std_logic;
        dout_psum_valid : out   std_logic;
        dout_wght_valid : out   std_logic
    );
end entity scratchpad_init;

architecture rtl of scratchpad_init is

    component ram_dp_init is
        generic (
            addr_width     : positive  := 2;
            data_width     : positive  := 6;
            use_output_reg : std_logic := '0';
            init_file      : string    := "mem.txt";
            g_files_dir    : string    := ""
        );
        port (
            clk : in    std_logic;

            wena : in    std_logic;
            --! Write enable for BRAM port A. If set to '1', the value on #dina will be written to position #addra in the RAM.
            wenb : in    std_logic;
            --! Write enable for BRAM port B. If set to '1', the value on #dinb will be written to position #addrb in the RAM.
            addra : in    std_logic_vector(addr_width - 1 downto 0);
            addrb : in    std_logic_vector(addr_width - 1 downto 0);
            dina  : in    std_logic_vector(data_width - 1 downto 0);
            dinb  : in    std_logic_vector(data_width - 1 downto 0);
            douta : out   std_logic_vector(data_width - 1 downto 0);
            doutb : out   std_logic_vector(data_width - 1 downto 0)
        );
    end component ram_dp_init;

begin

    dout_iact_valid <= read_en_iact when rising_edge(clk);
    dout_psum_valid <= read_en_psum when rising_edge(clk);
    dout_wght_valid <= read_en_wght when rising_edge(clk);

    ram_dp_iact : component ram_dp_init
        generic map (
            addr_width     => addr_width_iact,
            data_width     => data_width_iact,
            use_output_reg => '0',
            init_file      => "_mem_iact.txt",
            g_files_dir    => g_files_dir
        )
        port map (
            clk   => clk,
            wena  => write_en_iact,
            wenb  => '0',
            addra => write_adr_iact,
            addrb => read_adr_iact,
            dina  => din_iact,
            dinb  => (others => '0'),
            douta => open,
            doutb => dout_iact
        );

    ram_dp_psum : component ram_dp_init
        generic map (
            addr_width     => addr_width_psum,
            data_width     => data_width_psum,
            use_output_reg => '0',
            init_file      => "_mem_psum.txt",
            g_files_dir    => g_files_dir
        )
        port map (
            clk   => clk,
            wena  => write_en_psum,
            wenb  => '0',
            addra => write_adr_psum,
            addrb => read_adr_psum,
            dina  => din_psum,
            dinb  => (others => '0'),
            douta => open,
            doutb => dout_psum
        );

    ram_dp_wght : component ram_dp_init
        generic map (
            addr_width     => addr_width_wght,
            data_width     => data_width_wght,
            use_output_reg => '0',
            init_file      => "_mem_wght_stack.txt",
            g_files_dir    => g_files_dir
        )
        port map (
            clk   => clk,
            wena  => write_en_wght,
            wenb  => '0',
            addra => write_adr_wght,
            addrb => read_adr_wght,
            dina  => din_wght,
            dinb  => (others => '0'),
            douta => open,
            doutb => dout_wght
        );

end architecture rtl;
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
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
end entity scratchpad;

architecture rtl of scratchpad is

begin

    dout_iact_valid <= read_en_iact when rising_edge(clk);
    dout_psum_valid <= read_en_psum when rising_edge(clk);
    dout_wght_valid <= read_en_wght when rising_edge(clk);

    ram_dp_iact : entity accel.ram_dp
        generic map (
            addr_width     => addr_width_iact,
            data_width     => data_width_iact,
            use_output_reg => '0',
            initialize     => initialize_mems,
            init_file      => g_files_dir & "_mem_iact.txt"
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

    ram_dp_psum : entity accel.ram_dp
        generic map (
            addr_width     => addr_width_psum,
            data_width     => data_width_psum,
            use_output_reg => '0',
            initialize     => initialize_mems,
            init_file      => g_files_dir & "_mem_psum.txt"
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

    ram_dp_wght : entity accel.ram_dp
        generic map (
            addr_width     => addr_width_wght,
            data_width     => data_width_wght,
            use_output_reg => '0',
            initialize     => initialize_mems,
            init_file      => g_files_dir & "_mem_wght_stack.txt"
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

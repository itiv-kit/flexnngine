library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
        data_width_input : positive := 8;
        word_count       : positive := 8; -- number of input words per memory word
        mem_data_width   : positive := word_count * data_width_input;
        mem_addr_width   : positive := 15;

        data_width_psum : positive := 16;
        addr_width_psum : positive := 15;

        initialize_mems : boolean := false;
        init_files_dir  : string  := ""
    );
    port (
        clk     : in    std_logic;
        ext_clk : in    std_logic; -- clock for external spad interfaces
        rstn    : in    std_logic;

        -- internal addresses and control signals used by the pe array / address generator
        read_adr   : in    std_logic_vector(mem_addr_width - 1 downto 0);
        read_en    : in    std_logic;
        dout_valid : out   std_logic;
        dout       : out   std_logic_vector(mem_data_width - 1 downto 0);

        write_adr_psum  : in    std_logic_vector(mem_addr_width - 1 downto 0);
        write_en_psum   : in    std_logic_vector(word_count - 1 downto 0);
        write_supp_psum : in    std_logic;
        din_psum        : in    std_logic_vector(mem_data_width - 1 downto 0);

        -- external r/w access to scratchpad memories
        ext_en       : in    std_logic;
        ext_write_en : in    std_logic_vector(word_count - 1 downto 0);
        ext_addr     : in    std_logic_vector(mem_addr_width - 1 downto 0);
        ext_din      : in    std_logic_vector(mem_data_width - 1 downto 0);
        ext_dout     : out   std_logic_vector(mem_data_width - 1 downto 0);

        ext_en_psum       : in    std_logic;
        ext_write_en_psum : in    std_logic_vector(word_count - 1 downto 0);
        ext_addr_psum     : in    std_logic_vector(mem_addr_width - 1 downto 0);
        ext_din_psum      : in    std_logic_vector(mem_data_width - 1 downto 0);
        ext_dout_psum     : out   std_logic_vector(mem_data_width - 1 downto 0)
    );
end entity scratchpad;

architecture rtl of scratchpad is

    constant psum_addr_width_physical : integer := mem_addr_width - 3;

    constant cols : integer := word_count; -- note: could be different from word_count, e.g. 128 bit external access but 64 bit on reshape interface

    signal web : std_logic_vector(cols - 1 downto 0) := (others => '0');

    signal enb_psum      : std_logic;
    signal web_psum      : std_logic_vector(cols - 1 downto 0);
    signal addrb_psum    : std_logic_vector(psum_addr_width_physical - 1 downto 0);
    signal datab_psum    : std_logic_vector(mem_data_width - 1 downto 0);

begin

    -- bram/sram: data valid after one cycle
    dout_valid <= read_en when rising_edge(clk);

    -- iact & wght never written internally
    web <= (others => '0');

    psum : process is
    begin

        wait until rising_edge(clk);
        -- index := to_integer(unsigned(write_adr_psum(addr_width_psum - mem_addr_width downto 0)));

        addrb_psum <= write_adr_psum(mem_addr_width - 1 downto mem_addr_width - psum_addr_width_physical);
        -- datab_psum <= din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0);
        datab_psum <= din_psum;
        enb_psum   <= or write_en_psum and not write_supp_psum;
        web_psum   <= write_en_psum;

    -- if write_half_psum = '1' then
    --     index := to_integer(unsigned(write_adr_psum(addr_width_psum - mem_addr_width downto 0)));

    --     addrb_psum <= '0' & write_adr_psum(addr_width_psum - 1 downto addr_width_psum - mem_addr_width + 1);
    --     datab_psum <= din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0) & din_psum(data_width_iact - 1 downto 0);
    --     enb_psum   <= write_en_psum and not write_supp_psum;
    --     web_psum   <= (others => '0');

    --     if write_en_psum = '1' then
    --         with index select web_psum <=
    --             "1000" when 3,
    --             "0100" when 2,
    --             "0010" when 1,
    --             "0001" when others;
    --     end if;
    -- else
    --     index := to_integer(unsigned(write_adr_psum(addr_width_psum - mem_addr_width - 1 downto 0)));

    --     addrb_psum <= write_adr_psum(addr_width_psum - 1 downto addr_width_psum - mem_addr_width);
    --     datab_psum <= din_psum & din_psum;
    --     enb_psum   <= write_en_psum and not write_supp_psum;
    --     web_psum   <= (others => '0');

    --     -- TODO: generalize, currently fixed for 32bit spad 8bit cols 16bit psums
    --     if write_en_psum = '1' then
    --         if index = 1 then
    --             web_psum <= "1100";
    --         else
    --             web_psum <= "0011";
    --         end if;
    --     -- datab_psum <= (others => '0');
    --     -- datab_psum(data_width_psum * (index + 1) - 1 downto data_width_psum * index) <= din_psum;
    --     -- web_psum(index)                                                              <= '1';
    --     end if;
    -- end if;

    end process psum;

    ram : entity accel.spad_reshape
        generic map (
            word_size   => data_width_input,
            cols        => cols,
            addr_width  => mem_addr_width,
            initialize  => initialize_mems,
            file_prefix => init_files_dir & "_mem_col"
        )
        port map (
            clk      => clk,
            rstn     => rstn,
            std_en   => ext_en,
            std_wen  => ext_write_en,
            std_addr => ext_addr,
            std_din  => ext_din,
            std_dout => ext_dout,
            rsh_en   => read_en,
            rsh_addr => read_adr,
            rsh_dout => dout
        );

    ram_psum : entity accel.ram_dp_bwe
        generic map (
            size       => 2 ** mem_addr_width,
            addr_width => psum_addr_width_physical,
            col_width  => 8,
            nb_col     => cols,
            initialize => false,
            init_file  => init_files_dir & "_mem_psum.txt"
        )
        port map (
            -- external access
            clka  => ext_clk,
            ena   => ext_en_psum,
            wea   => ext_write_en_psum,
            addra => ext_addr_psum(mem_addr_width - 1 downto mem_addr_width - psum_addr_width_physical),
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

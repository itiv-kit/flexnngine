library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity scratchpad is
    generic (
        data_width_input : positive := 8;
        data_width_psum  : positive := 16;

        word_count     : positive := 8; -- number of input words per memory word
        mem_data_width : positive := word_count * data_width_input;
        mem_addr_width : positive := 15;

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
        ext_dout     : out   std_logic_vector(mem_data_width - 1 downto 0)
    );
end entity scratchpad;

architecture rtl of scratchpad is

    -- address_generator_psum generates byte-wise addresses, we have word-wise (with word_count words) here
    constant psum_addr_width_physical : integer := mem_addr_width - integer(ceil(log2(real(word_count))));

    constant cols : integer := word_count; -- note: could be different from word_count, e.g. 128 bit external access but 64 bit on reshape interface

    signal std_en   : std_logic;
    signal std_wen  : std_logic_vector(word_count - 1 downto 0);
    signal std_addr : std_logic_vector(mem_addr_width - 1 downto 0);
    signal std_din  : std_logic_vector(mem_data_width - 1 downto 0);

begin

    -- bram/sram: data valid after one cycle
    dout_valid <= read_en when rising_edge(clk);

    std_if_arb : process (all) is

        variable psum_interface_active : std_logic;

    begin

        -- enable psum write interface if a request is present (disables external access)
        psum_interface_active := or write_en_psum and not write_supp_psum;

        if psum_interface_active then
            std_en   <= psum_interface_active;
            std_wen  <= write_en_psum;
            std_addr <= write_adr_psum;
            std_din  <= din_psum;
        else
            std_en   <= ext_en;
            std_wen  <= ext_write_en;
            std_addr <= ext_addr;
            std_din  <= ext_din;
        end if;

    end process std_if_arb;

    psum : process is
    begin

        wait until rising_edge(clk);

    -- index := to_integer(unsigned(write_adr_psum(addr_width_psum - mem_addr_width downto 0)));

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
            std_en   => std_en,
            std_wen  => std_wen,
            std_addr => std_addr,
            std_din  => std_din,
            std_dout => ext_dout,
            rsh_en   => read_en,
            rsh_addr => read_adr,
            rsh_dout => dout
        );

end architecture rtl;

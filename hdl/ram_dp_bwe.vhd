-- True-Dual-Port BRAM with Byte-wide Write Enable
-- Read First mode
--
-- ram_dp_bwe.vhd
--
-- READ_FIRST ByteWide WriteEnable Block RAM Template

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use std.textio.all;

entity ram_dp_bwe is
    generic (
        size       : integer := 1024;
        addr_width : integer := 10;
        col_width  : integer := 8;
        nb_col     : integer := 4;
        initialize : boolean := false;
        init_file  : string  := ""
    );
    port (
        clka  : in    std_logic;
        ena   : in    std_logic;
        wea   : in    std_logic_vector(nb_col - 1 downto 0);
        addra : in    std_logic_vector(addr_width - 1 downto 0);
        dia   : in    std_logic_vector(nb_col * col_width - 1 downto 0);
        doa   : out   std_logic_vector(nb_col * col_width - 1 downto 0);
        clkb  : in    std_logic;
        enb   : in    std_logic;
        web   : in    std_logic_vector(nb_col - 1 downto 0);
        addrb : in    std_logic_vector(addr_width - 1 downto 0);
        dib   : in    std_logic_vector(nb_col * col_width - 1 downto 0);
        dob   : out   std_logic_vector(nb_col * col_width - 1 downto 0)
    );
end entity ram_dp_bwe;

architecture byte_wr_ram_rf of ram_dp_bwe is

    type ram_type is array (0 to size - 1) of std_logic_vector(nb_col * col_width - 1 downto 0);

    impure function init_memory_wfile (mem_file_name : in string) return ram_type is

        file     mem_file : text open read_mode is mem_file_name;
        variable mem_line : line;
        variable temp_bv  : bit_vector(nb_col * col_width - 1 downto 0);
        variable temp_mem : ram_type;
        variable n_words  : integer;
        variable good     : boolean;

    begin

        temp_mem := (others => (others => '0'));
        n_words  := 0;

        while not endfile(mem_file) loop

            readline(mem_file, mem_line);

            loop

                read(mem_line, temp_bv, good);
                exit when not good;
                temp_mem(n_words) := to_stdlogicvector(temp_bv);
                n_words           := n_words + 1;

            end loop;

        end loop;

        report "initialized " & integer'image(n_words) & " words of memory from " & mem_file_name
            severity note;

        return temp_mem;

    end function init_memory_wfile;

    impure function init_file_or_zero (mem_file_name : in string) return ram_type is
    begin

        if initialize then
            return init_memory_wfile(mem_file_name);
        else
            return (others => (others => '0'));
        end if;

    end function init_file_or_zero;

    -- vsg_disable_next_line variable_007
    shared variable ram : ram_type := init_file_or_zero(init_file);

begin

    ------- Port A -------
    port_a : process is
    begin

        wait until rising_edge(clka);

        if ena = '1' then
            doa <= ram(conv_integer(addra));

            for i in 0 to nb_col - 1 loop

                if wea(i) = '1' then
                    ram(conv_integer(addra))((i + 1) * col_width - 1 downto i * col_width) := dia((i + 1) * col_width - 1 downto i * col_width);
                end if;

            end loop;

        end if;

    end process port_a;

    ------- Port B -------
    port_b : process is
    begin

        wait until rising_edge(clkb);

        if enb = '1' then
            dob <= ram(conv_integer(addrb));

            for i in 0 to nb_col - 1 loop

                if web(i) = '1' then
                    ram(conv_integer(addrb))((i + 1) * col_width - 1 downto i * col_width) := dib((i + 1) * col_width - 1 downto i * col_width);
                end if;

            end loop;

        end if;

    end process port_b;

end architecture byte_wr_ram_rf;

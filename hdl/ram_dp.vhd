-- Dual-Port Block RAM with Two Write Ports
-- Modelization with a Shared Variable - modification without enable ports and only one clock

-- Old XPS version describes write first implementation as done here!

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
    use axi_filter_dma_v1_00_a.all;

--! This component encapsulates a dual ported BRAM.

--! If the internal output register is used (#USE_OUTPUT_REG), the output
--! is delayed for one clock cycle.

entity ram_dp is
    generic (
        addr_width     : positive  := 2;  --! Width of the BRAM addresses
        data_width     : positive  := 6;  --! Width of the data fields in the BRAM
        use_output_reg : std_logic := '0' --! Specifies if the output is buffered in a separate register
    );
    port (
        clk : in    std_logic; --! Clock input

        wena : in    std_logic;
        --! Write enable for BRAM port A. If set to '1', the value on #dina will be written to position #addra in the RAM.
        wenb : in    std_logic;
        --! Write enable for BRAM port B. If set to '1', the value on #dinb will be written to position #addrb in the RAM.
        addra : in    std_logic_vector(addr_width - 1 downto 0); --! Address input for reading/writing through port A.
        addrb : in    std_logic_vector(addr_width - 1 downto 0); --! Address input for reading/writing through port B.
        dina  : in    std_logic_vector(data_width - 1 downto 0); --! Data to write through port A.
        dinb  : in    std_logic_vector(data_width - 1 downto 0); --! Data to write through port A.
        douta : out   std_logic_vector(data_width - 1 downto 0); --! Outputs the data in the BRAM at #addra
        doutb : out   std_logic_vector(data_width - 1 downto 0)  --! Outputs the data in the BRAM at #addrb
    );
end entity ram_dp;

architecture syn of ram_dp is

    type ram_type is array (0 to 2 ** addr_width - 1) of std_logic_vector(data_width - 1 downto 0);

    shared variable ram_instance : ram_type;

    signal douta_s : std_logic_vector(data_width - 1 downto 0);
    signal doutb_s : std_logic_vector(data_width - 1 downto 0);

begin

    port_a : process (clk) is
    begin

        if rising_edge(clk) then
            if wena = '1' then
                ram_instance(to_integer(unsigned(addra))) := dina;
                douta_s                                   <= dina;
            else
                douta_s <= ram_instance(to_integer(unsigned(addra)));
            end if;
        end if;

    end process port_a;

    port_b : process (clk) is
    begin

        if rising_edge(clk) then
            if wenb = '1' then
                ram_instance(to_integer(unsigned(addrb))) := dinb;
                doutb_s                                   <= dinb;
            else
                doutb_s <= ram_instance(to_integer(unsigned(addrb)));
            end if;
        end if;

    end process port_b;

    g0_use_output_reg_0 : if use_output_reg = '0' generate   -- directly connected with the output
        douta <= douta_s;
        doutb <= doutb_s;
    end generate g0_use_output_reg_0;

    g0_use_output_reg_1 : if use_output_reg = '1' generate   -- optional output register is being used

        output_buffer : process (clk) is
        begin

            if rising_edge(clk) then
                douta <= douta_s;
                doutb <= doutb_s;
            end if;

        end process output_buffer;

    end generate g0_use_output_reg_1;

end architecture syn;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std.unsigned;

entity mult is
    generic (
        input_width  : positive := 8; -- Input width for the multiplication the mac can operate on
        output_width : positive := 16
    );
    port (
        clk            : in    std_logic;
        rstn           : in    std_logic;
        i_en           : in    std_logic;
        i_data_a       : in    std_logic_vector(input_width - 1 downto 0);
        i_data_b       : in    std_logic_vector(input_width - 1 downto 0);
        o_result       : out   std_logic_vector(output_width - 1 downto 0);
        o_result_valid : out   std_logic
    );
end entity mult;

architecture behavioral of mult is

begin

    calc : process (clk, rstn) is
    begin

        if not rstn then
            o_result_valid <= '0';
        elsif rising_edge(clk) then
            o_result_valid <= i_en;
            if i_en then
                o_result <= std_logic_vector(resize(signed(i_data_a) * signed(i_data_b), output_width));
            end if;
        end if;

    end process calc;

end architecture behavioral;

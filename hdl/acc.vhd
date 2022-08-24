library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std.unsigned;

entity acc is
    generic (
        input_width  : positive := 16; -- Input width for the multiplication the mac can operate on
        output_width : positive := 17
    );
    port (
        clk          : in    std_logic;
        en           : in    std_logic;
        rstn         : in    std_logic;
        data_in_a    : in    std_logic_vector(input_width - 1 downto 0);
        data_in_b    : in    std_logic_vector(input_width - 1 downto 0);
        result       : out   std_logic_vector(output_width - 1 downto 0);
        result_valid : out   std_logic
    );
end entity acc;

architecture behavioral of acc is

begin

    calc : process (clk, rstn) is
    begin

        if not rstn then
            result       <= (others => '0');
            result_valid <= '0';
        elsif rising_edge(clk) then
            if en = '0' then
                result_valid <= '0';
            else
                result       <= std_logic_vector(signed(data_in_a) + signed(data_in_b));
                result_valid <= '1';
            end if;
        end if;

    end process calc;

end architecture behavioral;

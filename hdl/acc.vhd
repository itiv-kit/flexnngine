library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity acc is
    generic (
        input_width  : positive := 16;
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
end entity acc;

architecture behavioral of acc is

    signal w_data_a, w_data_b : signed(input_width downto 0); -- 1 bit larger for carry
    signal w_result           : signed(input_width downto 0);

begin

    w_data_a <= resize(signed(i_data_a), input_width + 1);
    w_data_b <= resize(signed(i_data_b), input_width + 1);
    w_result <= w_data_a + w_data_b;

    calc : process (clk, rstn) is
    begin

        if not rstn then
            o_result_valid <= '0';
        elsif rising_edge(clk) then
            o_result_valid <= i_en;
            if i_en then
                if output_width <= input_width and w_result(input_width) = '0' and or w_result(input_width - 1 downto output_width - 1) = '1' then     -- overflow positive
                    o_result <= '0' & (output_width - 2 downto 0 => '1');
                elsif output_width <= input_width and w_result(input_width) = '1' and and w_result(input_width - 1 downto output_width - 1) = '0' then -- overflow negative
                    o_result <= '1' & (output_width - 2 downto 0 => '0');
                else
                    o_result <= std_logic_vector(resize(w_result, output_width));
                end if;
            end if;
        end if;

    end process calc;

end architecture behavioral;

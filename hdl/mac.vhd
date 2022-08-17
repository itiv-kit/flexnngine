library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std.unsigned;

entity mac is
  generic (
    input_width  : positive := 8; -- Input width the mac can operate on
    output_width : positive := 16
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
end entity mac;

architecture behavioral of mac is

begin

  calc : process (clk, rstn) is
  begin

    if (rstn = '0') then
      result       <= (others => '0');
      result_valid <= '0';
    else
      result <= std_logic_vector(signed(data_in_a) * signed(data_in_b));
      if (en = '0') then
        result_valid <= '0';
      else
        result_valid <= '1';
      end if;
    end if;

  end process calc;

end architecture behavioral;

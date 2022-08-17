library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std.unsigned;

entity mac is
  generic (
    input_width  : positive := 8; -- Input width for the multiplication the mac can operate on
    acc_width    : positive := 16;
    output_width : positive := 17
  );
  port (
    clk          : in    std_logic;
    en           : in    std_logic;
    rstn         : in    std_logic;
    data_in_a    : in    std_logic_vector(input_width - 1 downto 0);
    data_in_w    : in    std_logic_vector(input_width - 1 downto 0);
    data_in_acc  : in    std_logic_vector(acc_width - 1 downto 0);
    result       : out   std_logic_vector(output_width - 1 downto 0);
    result_valid : out   std_logic
  );
end entity mac;

architecture behavioral of mac is

begin

  calc : process (clk, rstn) is

    variable mult_result_v : std_logic_vector(2 * input_width - 1 downto 0);
    variable acc_result_v : integer;

  begin

    if (rstn = '0') then
      result        <= (others => '0');
      result_valid  <= '0';
      mult_result_v := (others => '0');
      acc_result_v := 0;
    elsif (rising_edge(clk)) then
      mult_result_v := std_logic_vector(signed(data_in_a) * signed(data_in_w));
      acc_result_v := to_integer(signed(mult_result_v)) + to_integer(signed(data_in_acc));
      result <= std_logic_vector(to_signed(acc_result_v, output_width));
      if (en = '0') then
        result_valid <= '0';
      else
        result_valid <= '1';
      end if;
    end if;

  end process calc;

end architecture behavioral;

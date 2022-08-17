library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_tb is
generic(
    input_width : positive := 8
);
end entity mac_tb;

architecture rtl of mac_tb is
    signal output_width : positive := 2 * input_width;

    component mac
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
    end component;

    signal clk : std_logic := '1';
    signal rstn : std_logic;
    signal en : std_logic;
    signal result_valid : std_logic;
    signal data_in_a : std_logic_vector(input_width -1 downto 0);
    signal data_in_b : std_logic_vector(input_width -1 downto 0);
    signal result : std_logic_vector(input_width * 2 -1 downto 0);

begin

    UUT: mac
        generic map (
            input_width => input_width,
            output_width => input_width * 2
        )
        port map (
            clk => clk,
            en => en,
            rstn => rstn,
            data_in_a => data_in_a,
            data_in_b => data_in_b,
            result => result,
            result_valid => result_valid
        );  

    CLOCK : process(clk)
    begin
        clk <= not clk after 10 ns;
    end process;

    STIMULI: process
    begin
        rstn <= '0';
        en <= '0';
        data_in_a <= (others => '0');
        data_in_b <= (others => '0');

        wait for 100 ns;
        rstn <= '1';

        en <= '1';
        data_in_a <= "00000010";
        data_in_b <= "00000010";

        wait until rising_edge(clk);

        data_in_a <= "00000010";
        data_in_b <= "00000100";

        wait until rising_edge(clk);

        data_in_a <= "11101101";
        data_in_b <= "00000100";
        
        wait until rising_edge(clk);

        data_in_a <= "00010001";
        data_in_b <= "00000100";

        wait until rising_edge(clk);


        rstn <= '1';
        en <= '0';
        wait for 50 ns;

    end process;



    CHECK: process
    begin
        wait until rising_edge(result_valid);
        wait until rising_edge(clk);

        assert result = std_logic_vector(to_signed(4,output_width))
        report "first output does not match"
        severity failure;

        wait until rising_edge(clk);
        if(result_valid = '0') 
        then
            wait until rising_edge(result_valid);
        end if;
                
        assert result = std_logic_vector(to_signed(8,output_width))
        report "second output does not match"
        severity failure;

        wait until rising_edge(clk);
        if(result_valid = '0') 
        then
            wait until rising_edge(result_valid);
        end if;
        assert result = std_logic_vector(to_signed(-76, output_width))
        report "third output does not match"
        severity failure;

        wait until rising_edge(clk);
        if(result_valid = '0') 
        then
            wait until rising_edge(result_valid);
        end if;
        assert result = std_logic_vector(to_signed(1, output_width))
        report "fourth output does not match"
        severity failure;

        report "output check is finished." severity note;
    end process;

end architecture rtl;
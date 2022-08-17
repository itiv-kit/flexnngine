library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use std.env.stop;

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

    type input_type is array (natural range<>) of std_logic_vector(input_width - 1 downto 0);
    type output_type is array (natural range<>) of integer;

    constant number_tests : positive := 5;

    constant test_inputs_a : input_type(0 to number_tests - 1) := (
        "00000010",
        "00000010",
        "00000010",
        "11101101",
        "00000010"
    );
    constant test_inputs_b : input_type(0 to number_tests - 1) := (
        "00000010",
        "00000100",
        "11101101",
        "11101101",
        "00010001"
    );

    constant test_outputs : output_type (0 to number_tests - 1) := (
        4,
        8,
        -38,
        361,
        34
    );

begin

    -- Unit under test
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

    -- Clock generation
    CLOCK : process(clk)
    begin
        clk <= not clk after 10 ns;
    end process;

    -- Stimuli creation process
    STIMULI: process
    begin
        rstn <= '0';
        en <= '0';
        data_in_a <= (others => '0');
        data_in_b <= (others => '0');
        
        wait for 100 ns;
        rstn <= '1';
        wait for 50 ns;
        
        input_loop : for i in 0 to number_tests - 1 loop
            wait until rising_edge(clk);
            en <= '1';

            if(i=3) 
            then
                en <= '0';
                wait for 40 ns;
                en <= '1';
            end if; 

            data_in_a <= test_inputs_a(i);
            data_in_b <= test_inputs_b(i);
        end loop;

        wait until rising_edge(clk);
        
        rstn <= '1';
        en <= '0';
        wait for 50 ns;

    end process;


    -- Output checking process
    CHECK: process
    begin

        output_loop : for i in 0 to number_tests - 1 loop
            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if(result_valid = '0') 
            then
                wait until rising_edge(clk) and result_valid = '1'; 
            end if;
            
            assert result = std_logic_vector(to_signed(test_outputs(i), output_width))
            report "Output wrong. Result is " & integer'image(to_integer(signed(result))) & " - should be " & integer'image(test_outputs(i)) 
            severity failure;

            report "Got correct result " & integer'image(to_integer(signed(result)));

        end loop;

        wait until rising_edge(clk);

        -- Check if result valid signal is set to zero after calculations
        assert result_valid = '0'
        report "Result valid should be zero"
        severity failure;

        wait for 50 ns;

        report "Output check is finished." severity note;
        finish;
    end process;

end architecture rtl;
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;

entity mac_tb is
    generic (
        input_width  : positive := 8;
        acc_width    : positive := 16;
        output_width : positive := 17
    );
end entity mac_tb;

architecture rtl of mac_tb is

    component mac is
        generic (
            input_width  : positive := input_width;
            acc_width    : positive := acc_width;
            output_width : positive := output_width
        );
        port (
            clk            : in    std_logic;
            rstn           : in    std_logic;
            i_en           : in    std_logic;
            i_data_a       : in    std_logic_vector(input_width - 1 downto 0);
            i_data_w       : in    std_logic_vector(input_width - 1 downto 0);
            i_data_acc     : in    std_logic_vector(acc_width - 1 downto 0);
            o_result       : out   std_logic_vector(output_width - 1 downto 0);
            o_result_valid : out   std_logic
        );
    end component mac;

    signal clk          : std_logic := '1';
    signal rstn         : std_logic;
    signal en           : std_logic;
    signal result_valid : std_logic;
    signal data_in_a    : std_logic_vector(input_width - 1 downto 0);
    signal data_in_w    : std_logic_vector(input_width - 1 downto 0);
    signal data_in_acc  : std_logic_vector(acc_width - 1 downto 0);
    signal result       : std_logic_vector(output_width - 1 downto 0);

    type input_type is array (natural range<>) of std_logic_vector(input_width - 1 downto 0);

    type input_type_acc is array (natural range<>) of std_logic_vector(acc_width - 1 downto 0);

    type output_type is array (natural range<>) of integer;

    constant number_tests : positive := 6;

    --   Input a for the multiplication
    constant test_inputs_a : input_type(0 to number_tests - 1) :=
  (
    "00000010",
    "00000010",
    "00000010",
    "11101101",
    "00000010",
    "01111111"
  );
    --   Input b for the multiplication
    constant test_inputs_w : input_type(0 to number_tests - 1) :=
  (
    "00000010",
    "00000100",
    "11101101",
    "11101101",
    "00010001",
    "01111111"
  );
    --   Input for the accumulation
    constant test_inputs_acc : input_type_acc(0 to number_tests - 1) :=
  (
    "0000000000000001",
    "0000000000000000",
    "0000000000000000",
    "0000000000000000",
    "0100000000000000",
    "0111111111111111"
  );

    -- Expected outputs
    constant test_outputs : output_type (0 to number_tests - 1) :=
  (
    5,
    8,
    -38,
    361,
    16418,
    48896
  );

begin

    -- Unit under test
    uut : component mac
        generic map (
            input_width  => input_width,
            acc_width    => acc_width,
            output_width => output_width
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => en,
            i_data_a       => data_in_a,
            i_data_w       => data_in_w,
            i_data_acc     => data_in_acc,
            o_result       => result,
            o_result_valid => result_valid
        );

    -- Clock generation
    clock : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clock;

    -- Stimuli creation process
    stimuli : process is
    begin

        rstn        <= '0';
        en          <= '0';
        data_in_a   <= (others => '0');
        data_in_w   <= (others => '0');
        data_in_acc <= (others => '0');

        wait for 100 ns;
        rstn <= '1';
        wait for 50 ns;

        input_loop : for i in 0 to number_tests - 1 loop

            wait until rising_edge(clk);
            en <= '1';

            if i = 3 then
                en <= '0';
                wait for 40 ns;
                en <= '1';
            end if;

            data_in_a   <= test_inputs_a(i);
            data_in_w   <= test_inputs_w(i);
            data_in_acc <= test_inputs_acc(i);

        end loop;

        wait until rising_edge(clk);

        rstn <= '1';
        en   <= '0';
        wait for 50 ns;

    end process stimuli;

    -- Output checking process
    output_check : process is
    begin

        output_loop : for i in 0 to number_tests - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if result_valid = '0' then
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

        report "Output check is finished."
            severity note;
        finish;

    end process output_check;

end architecture rtl;

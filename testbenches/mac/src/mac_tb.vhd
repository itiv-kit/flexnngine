library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;

library accel;

entity mac_tb is
    generic (
        input_width  : positive := 8;
        acc_width    : positive := 16;
        output_width : positive := 16
    );
end entity mac_tb;

architecture rtl of mac_tb is

    signal clk          : std_logic := '1';
    signal rstn         : std_logic;
    signal en           : std_logic;
    signal result_valid : std_logic;
    signal data_in_a    : std_logic_vector(input_width - 1 downto 0);
    signal data_in_w    : std_logic_vector(input_width - 1 downto 0);
    signal data_in_acc  : std_logic_vector(acc_width - 1 downto 0);
    signal result       : std_logic_vector(output_width - 1 downto 0);

    type input_type is array (natural range<>) of signed(input_width - 1 downto 0);

    type input_type_acc is array (natural range<>) of signed(acc_width - 1 downto 0);

    type output_type is array (natural range<>) of integer;

    constant number_tests : positive := 12;

    type equation_t is record
        a      : signed(input_width - 1 downto 0);
        w      : signed(input_width - 1 downto 0);
        acc    : signed(acc_width - 1 downto 0);
        output : signed(output_width - 1 downto 0);
    end record equation_t;

    function make_equation(a : integer; w : integer; acc : integer; output : integer) return equation_t is
        variable eq : equation_t;
    begin

        eq.a      := to_signed(a,      input_width);
        eq.w      := to_signed(w,      input_width);
        eq.acc    := to_signed(acc,    acc_width);
        eq.output := to_signed(output, output_width);
        return eq;

    end function make_equation;

    type equation_arr_t is array (natural range <>) of equation_t;

    -- test values a, w, acc, output for the equation a * w + acc = output
    -- output should be clamped to min/max of output_width
    -- -> check for output_width = 16 bit, this overflows quickly
    constant equations : equation_arr_t(0 to number_tests - 1) := (
        make_equation(   2,    2,      1,      5),
        make_equation(   2,    4,      0,      8),
        make_equation(   2,  -19,      0,    -38),
        make_equation( -19,  -19,      0,    361),
        make_equation(   2,   17,  16384,  16418),
        make_equation( 127,  127,      0,  16129), -- test max mult width positive
        make_equation(-127, -127,      0,  16129), -- test max mult width inverse
        make_equation( 127, -127,      0, -16129), -- test max mult width negative
        make_equation(   8,    2, -32768, -32752), -- test maximum negative acc
        make_equation(   8,    2,  32767,  32767), -- test acc overflow (instead of actual result 32783 or overflow to -32753)
        make_equation( 127,  127,  32767,  32767), -- test mult & acc overflow (instead of actual result 48896)
        make_equation(   8,   -2, -32768, -32768)  -- test negative acc overflow (instead of actual result -32784)
    );

begin

    -- Unit under test
    uut : entity accel.mac(structural)
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

            data_in_a   <= std_logic_vector(equations(i).a);
            data_in_w   <= std_logic_vector(equations(i).w);
            data_in_acc <= std_logic_vector(equations(i).acc);

        end loop;

        wait until rising_edge(clk);

        rstn <= '1';
        en   <= '0';
        wait for 50 ns;

    end process stimuli;

    -- Output checking process
    output_check : process is
        variable expected : signed(output_width - 1 downto 0);
        variable signed_out : signed(output_width - 1 downto 0);
    begin

        output_loop : for i in 0 to number_tests - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if result_valid = '0' then
                wait until rising_edge(clk) and result_valid = '1';
            end if;

            expected   := equations(i).output;
            signed_out := signed(result);

            assert signed_out = expected
                report "Output wrong. Result is " & integer'image(to_integer(signed_out)) & " - should be " & integer'image(to_integer(expected))
                severity failure;

            report "Got correct result " & integer'image(to_integer(signed_out));

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

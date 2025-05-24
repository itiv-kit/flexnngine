library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std.unsigned;

library accel;

entity mac is
    generic (
        input_width  : positive := 8; -- Input width for the multiplication the mac can operate on
        acc_width    : positive := 16;
        output_width : positive := 16
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
end entity mac;

architecture behavioral of mac is

begin

    calc : process (clk, rstn) is

        variable v_mult_result : std_logic_vector(2 * input_width - 1 downto 0);
        variable v_acc_result  : integer;

    begin

        if not rstn then
            o_result       <= (others => '0');
            o_result_valid <= '0';
            v_mult_result  := (others => '0');
            v_acc_result   := 0;
        elsif rising_edge(clk) then
            v_mult_result := std_logic_vector(signed(i_data_a) * signed(i_data_w));
            v_acc_result  := to_integer(signed(v_mult_result)) + to_integer(signed(i_data_acc));
            o_result      <= std_logic_vector(to_signed(v_acc_result, output_width));
            if i_en = '0' then
                o_result_valid <= '0';
            else
                o_result_valid <= '1';
            end if;
        end if;

    end process calc;

end architecture behavioral;

architecture structural of mac is

    signal r_data_acc_delay : std_logic_vector(acc_width - 1 downto 0);
    signal w_mult_out       : std_logic_vector(acc_width - 1 downto 0); -- 2 * input_width - 2 downto 0 would be sufficient
    signal w_mult_out_valid : std_logic;

begin

    mult_inst : entity accel.mult
        generic map (
            input_width  => input_width,
            output_width => acc_width
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => i_en,
            i_data_a       => i_data_a,
            i_data_b       => i_data_w,
            o_result       => w_mult_out,
            o_result_valid => w_mult_out_valid
        );

    r_data_acc_delay <= i_data_acc when rising_edge(clk);

    acc_inst : entity accel.acc
        generic map (
            input_width  => acc_width,
            output_width => output_width
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => w_mult_out_valid,
            i_data_a       => w_mult_out,
            i_data_b       => r_data_acc_delay,
            o_result       => o_result,
            o_result_valid => o_result_valid
        );

end architecture structural;

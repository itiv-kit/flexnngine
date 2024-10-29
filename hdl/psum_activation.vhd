-- original draft by Alexander Keller
-- zero or one cycle latency between i_psum and o_psum_act

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity psum_activation is
    generic (
        data_width_psum : positive := 16;
        use_output_reg  : boolean  := true
    );
    port (
        clk : in    std_logic;

        i_mode : in    mode_activation_t;

        i_psum_valid : in    std_logic;
        i_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);

        o_psum_valid : out   std_logic;
        o_psum       : out   std_logic_vector(data_width_psum - 1 downto 0)
    );
end entity psum_activation;

architecture behavioral of psum_activation is

    signal w_data_in   : signed(data_width_psum - 1 downto 0);
    signal w_data_out  : signed(data_width_psum - 1 downto 0);
    signal w_data_relu : signed(data_width_psum - 1 downto 0);

begin

    w_data_in <= signed(i_psum);

    -- ReLU --
    relu_proc : process (w_data_in) is
    begin

        if w_data_in >= 0 then
            w_data_relu <= w_data_in;
        else
            w_data_relu <= (others => '0');
        end if;

    end process relu_proc;

    -- Sigmoid --

    -- Leaky ReLU --

    -- ELU --

    with i_mode select w_data_out <=
        w_data_in when passthrough,
        w_data_relu when relu,
        w_data_in when others;

    output_reg_gen : if use_output_reg generate

        o_psum_valid <= i_psum_valid when rising_edge(clk);
        o_psum       <= std_logic_vector(w_data_out) when rising_edge(clk);

    else generate

        o_psum_valid <= i_psum_valid;
        o_psum       <= std_logic_vector(w_data_out);

    end generate output_reg_gen;

end architecture behavioral;

-- original draft by Alexander Keller
-- zero or one cycle latency between i_psum and o_psum_act

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity psum_bias is
    generic (
        data_width_psum : positive := 16;
        use_output_reg  : boolean  := true
    );
    port (
        clk  : in    std_logic;

        i_params : in    parameters_t;

        i_psum_valid : in    std_logic;
        i_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);

        o_psum_valid : out   std_logic;
        o_psum       : out   std_logic_vector(data_width_psum - 1 downto 0)
    );
end entity psum_bias;

architecture behavioral of psum_bias is

    signal w_bias_in   : signed(data_width_psum - 1 downto 0);
    signal w_data_in   : signed(data_width_psum - 1 downto 0);
    signal w_data_out  : signed(data_width_psum - 1 downto 0);
    signal w_data_bias : signed(data_width_psum - 1 downto 0);

begin

    w_bias_in <= signed(i_params.bias) when rising_edge(clk);
    w_data_in <= signed(i_psum);

    relu_proc : process (all) is
    begin

        w_data_bias <= w_data_in + w_bias_in;

    end process relu_proc;

    w_data_out <= w_data_bias when i_params.bias_enab else w_data_in;

    output_reg_gen : if use_output_reg generate

        o_psum_valid <= i_psum_valid when rising_edge(clk);
        o_psum       <= std_logic_vector(w_data_out) when rising_edge(clk);

    else generate

        o_psum_valid <= i_psum_valid;
        o_psum       <= std_logic_vector(w_data_out);

    end generate output_reg_gen;

end architecture behavioral;

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
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_psum_valid : in    std_logic;
        i_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);

        o_psum_valid : out   std_logic;
        o_psum       : out   std_logic_vector(data_width_psum - 1 downto 0)
    );
end entity psum_bias;

architecture behavioral of psum_bias is

    signal w_bias_in        : signed(data_width_psum - 1 downto 0);
    signal w_data_in        : signed(data_width_psum - 1 downto 0);
    signal w_data_out       : signed(data_width_psum - 1 downto 0);
    signal r_count_w1       : integer := 0;
    signal r_output_channel : integer := 0;

begin

    p_track_channel : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' then
            r_count_w1       <= 0;
            r_output_channel <= 0;
        elsif i_psum_valid = '1' then
            r_count_w1 <= r_count_w1 + 1;
            if r_count_w1 = i_params.w1 - 1 then
                r_count_w1       <= 0;
                r_output_channel <= r_output_channel + 1;
                if r_output_channel = i_params.m0 - 1 then
                    r_output_channel <= 0;
                end if;
            end if;
        end if;

    end process p_track_channel;

    w_bias_in <= to_signed(i_params.bias(r_output_channel), 16) when rising_edge(clk);
    w_data_in <= signed(i_psum);

    p_add_bias : process (all) is
    begin

        w_data_out <= w_data_in + w_bias_in;

    end process p_add_bias;

    output_reg_gen : if use_output_reg generate

        o_psum_valid <= i_psum_valid when rising_edge(clk);
        o_psum       <= std_logic_vector(w_data_out) when rising_edge(clk);

    else generate

        o_psum_valid <= i_psum_valid;
        o_psum       <= std_logic_vector(w_data_out);

    end generate output_reg_gen;

end architecture behavioral;

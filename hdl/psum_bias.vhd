-- original draft by Alexander Keller
-- zero or one cycle latency between i_psum and o_psum_act

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity psum_bias is
    generic (
        data_width_psum : positive := 16
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_psum_valid : in    std_logic;
        i_psum_last  : in    std_logic;
        i_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_channel    : in    integer range 0 to max_size_x - 1;

        o_psum_valid : out   std_logic;
        o_psum_last  : out   std_logic;
        o_psum       : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_channel    : out   integer range 0 to max_size_x - 1
    );
end entity psum_bias;

architecture behavioral of psum_bias is

    signal w_bias_in : std_logic_vector(data_width_psum - 1 downto 0);

begin

    w_bias_in <= std_logic_vector(to_signed(i_params.bias(i_channel), data_width_psum)) when rising_edge(clk);

    o_psum_last <= i_psum_last when rising_edge(clk);
    o_channel   <= i_channel when rising_edge(clk);

    acc_1 : entity accel.acc
        generic map (
            input_width  => data_width_psum,
            output_width => data_width_psum
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            i_en           => i_psum_valid,
            i_data_a       => i_psum,
            i_data_b       => w_bias_in,
            o_result       => o_psum,
            o_result_valid => o_psum_valid
        );

end architecture behavioral;

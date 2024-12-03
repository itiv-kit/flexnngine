library ieee;
    use ieee.std_logic_1164.all;

library accel;
    use accel.utilities.all;

entity postproc is
    generic (
        size_x          : positive := 3;
        data_width_iact : positive := 8;
        data_width_psum : positive := 16;
        g_en_postproc   : boolean  := true
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_data          : in    array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        i_data_valid    : in    std_logic_vector(size_x - 1 downto 0);
        i_data_halfword : in    std_logic_vector(size_x - 1 downto 0);

        o_data          : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        o_data_valid    : out   std_logic_vector(size_x - 1 downto 0);
        o_data_halfword : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity postproc;

architecture behavioral of postproc is

    signal w_psums_bias       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_bias_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_psums_act       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_act_valid : std_logic_vector(size_x - 1 downto 0);

begin

    gen_postproc : if g_en_postproc generate

        psum_output : for i in 0 to size_x - 1 generate

            -- generate bias, activation and requantization (scaling) units
            -- TODO: bias could also be applied by preloading biases to accumulators

            bias_inst : entity accel.psum_bias
                generic map (
                    data_width_psum => data_width_psum
                )
                port map (
                    clk          => clk,
                    rstn         => rstn,
                    i_params     => i_params,
                    i_psum_valid => i_data_valid(i),
                    i_psum       => i_data(i),
                    o_psum_valid => w_psums_bias_valid(i),
                    o_psum       => w_psums_bias(i)
                );

            -- activation_inst : entity accel.psum_activation
            --     generic map (
            --         data_width_psum => data_width_psum
            --     )
            --     port map (
            --         clk          => clk,
            --         i_mode       => i_params.mode_act,
            --         i_psum_valid => w_psums_bias_valid(i),
            --         i_psum       => w_psums_bias(i),
            --         o_psum_valid => w_psums_act_valid(i),
            --         o_psum       => w_psums_act(i)
            --     );

            requantize_inst : entity accel.psum_requantize
                generic map (
                    data_width_psum => data_width_psum,
                    data_width_iact => data_width_iact
                )
                port map (
                    clk      => clk,
                    rstn     => rstn,
                    i_params => i_params,
                    -- i_data_valid    => w_psums_act_valid(i),
                    -- i_data          => w_psums_act(i),
                    i_data_valid    => w_psums_bias_valid(i),
                    i_data          => w_psums_bias(i),
                    o_data_valid    => o_data_valid(i),
                    o_data          => o_data(i),
                    o_data_halfword => o_data_halfword(i)
                );

        end generate psum_output;

    else generate

        -- if bias & activation are disabled, directly map partial sum outputs to module outputs

        psum_output : for i in 0 to size_x - 1 generate

            o_data(i)          <= i_data(i);
            o_data_valid(i)    <= i_data_valid(i);
            o_data_halfword(i) <= '0';

        end generate psum_output;

    end generate gen_postproc;

end architecture behavioral;

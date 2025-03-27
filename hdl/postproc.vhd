library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity postproc is
    generic (
        size_x          : positive := 3;
        data_width_iact : positive := 8;
        data_width_psum : positive := 16;
        use_float_ip    : boolean  := false;
        postproc_enable : boolean  := true
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_data       : in    array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        i_data_valid : in    std_logic_vector(size_x - 1 downto 0);

        o_data          : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        o_data_valid    : out   std_logic_vector(size_x - 1 downto 0);
        o_data_last     : out   std_logic_vector(size_x - 1 downto 0);
        o_data_halfword : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity postproc;

architecture behavioral of postproc is

    signal w_psums_bias       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_bias_valid : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_bias_last  : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_bias_och   : x_idx_line_t(0 to size_x - 1);

    signal w_psums_act       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_act_valid : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_act_last  : std_logic_vector(size_x - 1 downto 0);
    signal w_psums_act_och   : x_idx_line_t(0 to size_x - 1);

    signal r_count_w1        : uint10_line_t(0 to size_x - 1);
    signal r_current_channel : x_idx_line_t(0 to size_x - 1); -- the number of the output channel (0..m0-1) currently on i_data
    signal w_i_data_last     : std_logic_vector(size_x - 1 downto 0);

begin

    gen_postproc : if postproc_enable generate

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
                    i_psum_last  => w_i_data_last(i),
                    i_psum       => i_data(i),
                    i_channel    => r_current_channel(i),
                    o_psum_valid => w_psums_bias_valid(i),
                    o_psum_last  => w_psums_bias_last(i),
                    o_psum       => w_psums_bias(i),
                    o_channel    => w_psums_bias_och(i)
                );

            activation_inst : entity accel.psum_activation
                generic map (
                    data_width_psum => data_width_psum
                )
                port map (
                    clk          => clk,
                    i_mode       => i_params.mode_act,
                    i_psum_valid => w_psums_bias_valid(i),
                    i_psum_last  => w_psums_bias_last(i),
                    i_psum       => w_psums_bias(i),
                    i_channel    => w_psums_bias_och(i),
                    o_psum_valid => w_psums_act_valid(i),
                    o_psum_last  => w_psums_act_last(i),
                    o_psum       => w_psums_act(i),
                    o_channel    => w_psums_act_och(i)
                );

            requantize_inst : entity accel.psum_requantize
                generic map (
                    data_width_psum => data_width_psum,
                    data_width_iact => data_width_iact,
                    pipeline_length => 19,
                    use_float_ip    => use_float_ip
                )
                port map (
                    clk             => clk,
                    rstn            => rstn,
                    i_params        => i_params,
                    i_data_valid    => w_psums_act_valid(i),
                    i_data_last     => w_psums_act_last(i),
                    i_data          => w_psums_act(i),
                    i_channel       => w_psums_act_och(i),
                    o_data_valid    => o_data_valid(i),
                    o_data_last     => o_data_last(i),
                    o_data          => o_data(i),
                    o_data_halfword => o_data_halfword(i),
                    o_channel       => open
                );

            p_track_channel : process is
            begin

                wait until rising_edge(clk);

                if rstn = '0' then
                    r_count_w1(i)        <= 0;
                    r_current_channel(i) <= 0;
                elsif i_data_valid(i) = '1' then
                    r_count_w1(i) <= r_count_w1(i) + 1;
                    if r_count_w1(i) = i_params.w1 - 1 then
                        r_count_w1(i)        <= 0;
                        r_current_channel(i) <= r_current_channel(i) + 1;
                        if r_current_channel(i) = i_params.m0 - 1 then
                            r_current_channel(i) <= 0;
                        end if;
                    end if;
                end if;

            end process p_track_channel;

            w_i_data_last(i) <= '1' when r_count_w1(i) = i_params.w1 - 1 else '0';

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

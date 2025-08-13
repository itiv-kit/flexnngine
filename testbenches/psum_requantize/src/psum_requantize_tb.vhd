library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use std.textio.all;
    use ieee.float_pkg.all;

library accel;
    use accel.utilities.all;

--! Testbench for the psum requantization unit

entity psum_requantize_tb is
    generic (
        data_width_psum : positive := 16;
        data_width_iact : positive := 8;
        pipeline_length : positive := 19 -- latency of float ip
    );
end entity psum_requantize_tb;

architecture imp of psum_requantize_tb is

    signal clk  : std_logic := '1';
    signal rstn : std_logic := '0';

    signal i_params        : parameters_t;
    signal i_data_valid    : std_logic;
    signal i_data_last     : std_logic;
    signal i_data          : std_logic_vector(data_width_psum - 1 downto 0);
    signal o_data_valid    : std_logic;
    signal o_data          : std_logic_vector(data_width_psum - 1 downto 0);
    signal o_data_halfword : std_logic;

    type equation_t is record
        input       : integer;
        scale_fp32  : std_logic_vector(31 downto 0);
        zeropt_fp32 : std_logic_vector(31 downto 0);
        output      : integer;
    end record equation_t;

    type equation_arr_t is array (natural range <>) of equation_t;

    constant equations : equation_arr_t(0 to 3) := (
        -- 1000 * 0.09 - 26.3 = 64
        (1000, x"3DB851EC", x"C1D26666", 64),
        -- 147 * -0.0673 + 76.7941 = 67 (problem: wird 66?)
        (147, x"BD89D495", x"42999694", 67),
        -- -327 * 0.39144 + 0 = -128
        (-327, x"3EC86A79", x"00000000", -128),
        -- 1234 * 0.09724 + 7 = 127
        (1234, x"3DC7283F", x"40E00000", 127)
    );

begin

    dut : entity accel.psum_requantize
        generic map (
            data_width_psum => data_width_psum,
            data_width_iact => data_width_iact,
            pipeline_length => pipeline_length,
            use_float_ip    => true
        )
        port map (
            clk             => clk,
            rstn            => rstn,
            i_params        => i_params,
            i_channel       => 0,
            i_data_valid    => i_data_valid,
            i_data_last     => i_data_last,
            i_data          => i_data,
            o_data_valid    => o_data_valid,
            o_data          => o_data,
            o_data_halfword => o_data_halfword
        );

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rstn : process is
    begin

        wait for 50 ns;
        wait until rising_edge(clk);
        rstn <= '1';
        wait;

    end process gen_rstn;

    gen_inputs : process is

        variable eq : equation_t;

    begin

        i_params <=
        (
            scale_fp32   => (others => (others => '0')),
            zeropt_fp32  => (others => (others => '0')),
            mode_act     => passthrough,
            mode_pad     => none,
            bias         => (others => 0),
            requant_enab => true,
            others       => 0
        );

        i_data_valid <= '0';
        i_data_last  <= '0';
        i_data       <= (others => '0');

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        wait for 150 ns;

        for n in 0 to equations'high loop

            wait until rising_edge(clk);
            eq                      := equations(n);
            i_params.scale_fp32(0)  <= eq.scale_fp32;
            i_params.zeropt_fp32(0) <= eq.zeropt_fp32;

            -- assert data a cycle later than scale / zeropt, as it has latency of one cycle
            wait until rising_edge(clk);
            i_data_valid <= '1';
            i_data       <= std_logic_vector(to_signed(eq.input, data_width_psum));

            if n = equations'high then
                i_data_last <= '1';
            end if;

            for n in 0 to pipeline_length - 1 loop

                wait until rising_edge(clk);
                i_data_valid <= '0';
                i_data_last  <= '0';

            end loop;

        end loop;

        i_data_valid <= '0';
        i_data_last  <= '0';

        wait for 200 ns;

    end process gen_inputs;

    check_output : process is

        variable eq      : equation_t;
        variable tmp_out : integer;

    begin

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        for n in 0 to equations'high loop

            wait until rising_edge(clk) and o_data_valid = '1';
            eq      := equations(n);
            tmp_out := to_integer(signed(o_data));

            assert eq.output = tmp_out
                report "Output invalid, expected " & integer'image(eq.output) & " but got " & integer'image(tmp_out)
                severity failure;

        end loop;

        report "Output check is finished."
            severity note;

        finish;

    end process check_output;

end architecture imp;

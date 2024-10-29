-- original draft by Alexander Keller
-- this module requantizes the psum output (including bias & after activation)
-- back to 8 bits. it still supports a "bypass" mode to store full 16-bit psums
-- to memory.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.float_pkg.all;

library accel;
    use accel.utilities.all;

entity psum_requantize is
    generic (
        data_width_psum : positive := 16;
        data_width_iact : positive := 8;
        pipeline_length : positive := 4
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_data_valid : in    std_logic;
        i_data       : in    std_logic_vector(data_width_psum - 1 downto 0);

        o_data_valid    : out   std_logic;
        o_data          : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_data_halfword : out   std_logic
    );
end entity psum_requantize;

architecture behavioral of psum_requantize is

    type pipe_data_t is record
        valid : std_logic;
        data  : float32;
    end record pipe_data_t;

    type   pipe_t is array (0 to pipeline_length - 1) of pipe_data_t;
    signal pipe : pipe_t;

    signal scale, zeropoint : float32;

begin

    -- TODO: add support for individual scale/zeropoint per output channel (e.g. from weight memory?)
    scale     <= to_float(i_params.scale_fp32);
    zeropoint <= to_float(i_params.zeropt_fp32);

    -- construct the o_status record, currently consists of scratchpad interface signals only
    pipe(0)              <= (i_data_valid, to_float(i_data));
    pipe(1)              <= (pipe(0).valid, pipe(0).data * scale) when rising_edge(clk);
    pipe(2)              <= (pipe(1).valid, pipe(1).data + zeropoint) when rising_edge(clk);
    pipe(3 to pipe'high) <= pipe(2 to pipe'high - 1) when rising_edge(clk);

    p_output_reg : process is
    begin

        wait until rising_edge(clk);

        if i_params.requant_enab then
            o_data_valid    <= pipe(pipe'high).valid;
            o_data          <= std_logic_vector(resize(to_signed(pipe(pipe'high).data, data_width_iact), data_width_psum));
            o_data_halfword <= '1';
        else
            -- TODO: passthrough mode is a bit hacky and can leave up stuff in the pipeline
            o_data_valid    <= i_data_valid;
            o_data          <= i_data;
            o_data_halfword <= '0';
        end if;

    end process p_output_reg;

end architecture behavioral;

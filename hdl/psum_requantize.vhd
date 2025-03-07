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
        pipeline_length : positive := 12; -- needs to match float ip latency if enabled
        use_float_ip    : boolean  := false
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_params : in    parameters_t;

        i_data_valid : in    std_logic;
        i_data_last  : in    std_logic;
        i_data       : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_channel    : in    integer range 0 to max_size_x - 1;

        o_data_valid    : out   std_logic;
        o_data_last     : out   std_logic;
        o_data          : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_data_halfword : out   std_logic;
        o_channel       : out   integer range 0 to max_size_x - 1
    );
end entity psum_requantize;

architecture behavioral of psum_requantize is

    type pipe_data_t is record
        valid  : std_logic;
        last   : std_logic;
        och    : integer range 0 to max_size_x - 1;
        data   : float32;
        scale  : float32;
        zeropt : float32;
    end record pipe_data_t;

    type   pipe_t is array (0 to pipeline_length - 1) of pipe_data_t;
    signal pipe : pipe_t;

    signal scale, zeropoint : float32;

    signal w_input_valid  : std_logic;
    signal w_input_last   : std_logic;
    signal w_input        : std_logic_vector(31 downto 0);
    signal w_input_och    : integer range 0 to max_size_x - 1;
    signal w_output_valid : std_logic;
    signal w_output_last  : std_logic;
    signal w_output       : std_logic_vector(31 downto 0);
    signal w_output_och   : integer range 0 to max_size_x - 1;

    component float32_mac is
        port (
            aclk                 : in    std_logic;
            s_axis_a_tvalid      : in    std_logic;
            s_axis_a_tdata       : in    std_logic_vector(31 downto 0);
            s_axis_b_tvalid      : in    std_logic;
            s_axis_b_tdata       : in    std_logic_vector(31 downto 0);
            s_axis_c_tvalid      : in    std_logic;
            s_axis_c_tdata       : in    std_logic_vector(31 downto 0);
            m_axis_result_tvalid : out   std_logic;
            m_axis_result_tdata  : out   std_logic_vector(31 downto 0)
        );
    end component float32_mac;

begin

    w_input_valid <= i_data_valid;
    w_input_last  <= i_data_last;
    w_input       <= to_slv(to_float(signed(i_data)));
    w_input_och   <= i_channel;

    p_load_attrs : process is
    begin

        wait until rising_edge(clk);

        scale     <= to_float(i_params.scale_fp32(i_channel));
        zeropoint <= to_float(i_params.zeropt_fp32(i_channel));

    end process p_load_attrs;

    -- version 1: synthesis okay, but warning for non-constant value ?? in line pipe(1)
    -- version 2: wrap all in one process, increases latency by one: 2512 LUT, 263 REG, 154 CARRY, 2 DSP
    -- version 3: include scale + zp in pipeline regs: 2544 LUT, 295 REG, 154 CARRY, 2 DSP
    -- version 4: increase pipeline length to 19 (fully pipelined floating-point fused mac+add IP core needs this) 3523 LUT, 293 REG, 154 CARRY, 2 DSP
    -- version 5: use xilinx fused mac+add floating-point IP 1025 LUT, 1262 REG, 42 CARRY, 4 DSP

    float_proc : if use_float_ip generate

        -- fused multiply + acc floating point IP (result = a * b + c)
        -- vsg_disable_next_line instantiation_034
        float32_inst : component float32_mac
            port map (
                aclk                 => clk,
                s_axis_a_tvalid      => w_input_valid,
                s_axis_b_tvalid      => w_input_valid,
                s_axis_c_tvalid      => w_input_valid,
                s_axis_a_tdata       => w_input,
                s_axis_b_tdata       => to_slv(scale),
                s_axis_c_tdata       => to_slv(zeropoint),
                m_axis_result_tvalid => w_output_valid,
                m_axis_result_tdata  => w_output
            );

    else generate

        w_output_valid <= pipe(pipe'high).valid;
        w_output       <= to_slv(pipe(pipe'high).data);

    end generate float_proc;

    -- run the pipeline in any case, even if use_float_ip, to forward "last" and "channel" info
    w_output_last <= pipe(pipe'high).last;
    w_output_och  <= pipe(pipe'high).och;

    p_pipe : process is
    begin

        wait until rising_edge(clk);

        -- construct the o_status record, currently consists of scratchpad interface signals only
        pipe(0)              <= (w_input_valid, w_input_last, w_input_och, to_float(w_input), scale, zeropoint);
        pipe(1)              <= pipe(0);
        pipe(1).data         <= pipe(0).data * pipe(0).scale;
        pipe(2)              <= pipe(1);
        pipe(2).data         <= pipe(1).data + pipe(1).zeropt;
        pipe(3 to pipe'high) <= pipe(2 to pipe'high - 1);

    end process p_pipe;

    p_output_reg : process is
    begin

        wait until rising_edge(clk);

        if i_params.requant_enab then
            o_data_valid    <= w_output_valid;
            o_data_last     <= w_output_last;
            o_data          <= std_logic_vector(resize(to_signed(to_float(w_output), data_width_iact), data_width_psum));
            o_data_halfword <= '1';
            o_channel       <= w_output_och;
        else
            -- TODO: passthrough mode is a bit hacky and can leave up stuff in the pipeline
            o_data_valid    <= i_data_valid;
            o_data_last     <= i_data_last;
            o_data          <= i_data;
            o_data_halfword <= '0';
            o_channel       <= w_output_och;
        end if;

    end process p_output_reg;

end architecture behavioral;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

entity control_address_generator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        data_width_input : positive := 8;
        data_width_psum  : positive := 16;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        mem_addr_width   : positive := 15;
        mem_word_count   : positive := 8;
        mem_offset_width : positive := integer(ceil(log2(real(mem_word_count))));

        addr_width_iact  : positive := 6;
        addr_width_wght  : positive := 6;
        addr_width_psum  : positive := 7;
        line_length_iact : positive := 64;
        line_length_wght : positive := 64;
        line_length_psum : positive := 128;

        g_dataflow : integer := 1
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start             : in    std_logic;
        i_enable_if         : in    std_logic;
        i_all_psum_finished : in    std_logic;
        i_dataflow          : in    std_logic;

        o_init_done  : out   std_logic;
        o_enable     : out   std_logic;
        o_pause_iact : out   std_logic;
        o_done       : out   std_logic;
        o_cyclectr   : out   unsigned(31 downto 0);

        i_params : in    parameters_t;

        o_command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        o_command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

        o_update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        o_update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        o_update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        o_read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        o_read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        i_fifo_iact_address_full : in    std_logic;
        i_fifo_wght_address_full : in    std_logic;

        o_addr_iact_done : out   std_logic;
        o_addr_wght_done : out   std_logic;

        o_address_iact       : out   array_t(0 to size_rows - 1)(mem_addr_width - 1 downto 0);
        o_address_wght       : out   array_t(0 to size_y - 1)(mem_addr_width - 1 downto 0);
        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0);

        i_req_addr_psum : in    std_logic_vector(size_x - 1 downto 0);

        o_address_psum      : out   array_t(0 to size_x - 1)(mem_addr_width + mem_offset_width - 1 downto 0);
        o_psum_suppress_out : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity control_address_generator;

architecture rtl of control_address_generator is

    signal w_control_init_done : std_logic;

    signal w_m0_dist : uns_array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);

begin

    o_init_done <= w_control_init_done;

    g_control : if g_dataflow = 1 generate
    begin

        control_inst : entity accel.control(alternative_rs_dataflow)
            generic map (
                size_x           => size_x,
                size_y           => size_y,
                size_rows        => size_rows,
                addr_width_rows  => addr_width_rows,
                addr_width_y     => addr_width_y,
                addr_width_x     => addr_width_x,
                line_length_iact => line_length_iact,
                addr_width_iact  => addr_width_iact,
                line_length_psum => line_length_psum,
                addr_width_psum  => addr_width_psum,
                line_length_wght => line_length_wght,
                addr_width_wght  => addr_width_wght
            )
            port map (
                clk                  => clk,
                rstn                 => rstn,
                o_init_done          => w_control_init_done,
                i_start              => i_start,
                o_done               => o_done,
                i_enable_if          => i_enable_if,
                o_enable             => o_enable,
                o_pause_iact         => o_pause_iact,
                i_all_psum_finished  => i_all_psum_finished,
                i_params             => i_params,
                o_m0_dist            => w_m0_dist,
                o_command            => o_command,
                o_command_iact       => o_command_iact,
                o_command_psum       => o_command_psum,
                o_command_wght       => o_command_wght,
                o_update_offset_iact => o_update_offset_iact,
                o_update_offset_psum => o_update_offset_psum,
                o_update_offset_wght => o_update_offset_wght,
                o_read_offset_iact   => o_read_offset_iact,
                o_read_offset_psum   => o_read_offset_psum,
                o_read_offset_wght   => o_read_offset_wght
            );

    else generate
    begin

        control_inst : entity accel.control(rs_dataflow)
            generic map (
                size_x           => size_x,
                size_y           => size_y,
                size_rows        => size_rows,
                addr_width_rows  => addr_width_rows,
                addr_width_y     => addr_width_y,
                addr_width_x     => addr_width_x,
                line_length_iact => line_length_iact,
                addr_width_iact  => addr_width_iact,
                line_length_psum => line_length_psum,
                addr_width_psum  => addr_width_psum,
                line_length_wght => line_length_wght,
                addr_width_wght  => addr_width_wght
            )
            port map (
                clk                  => clk,
                rstn                 => rstn,
                o_init_done          => w_control_init_done,
                i_start              => i_start,
                o_done               => o_done,
                i_enable_if          => i_enable_if,
                o_enable             => o_enable,
                o_pause_iact         => o_pause_iact,
                i_all_psum_finished  => i_all_psum_finished,
                i_params             => i_params,
                o_m0_dist            => w_m0_dist,
                o_command            => o_command,
                o_command_iact       => o_command_iact,
                o_command_psum       => o_command_psum,
                o_command_wght       => o_command_wght,
                o_update_offset_iact => o_update_offset_iact,
                o_update_offset_psum => o_update_offset_psum,
                o_update_offset_wght => o_update_offset_wght,
                o_read_offset_iact   => o_read_offset_iact,
                o_read_offset_psum   => o_read_offset_psum,
                o_read_offset_wght   => o_read_offset_wght
            );

    end generate g_control;

    address_generator_iact_inst : entity accel.address_generator_iact
        generic map (
            size_x         => size_x,
            size_y         => size_y,
            size_rows      => size_rows,
            mem_addr_width => mem_addr_width,
            read_size      => mem_word_count
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => w_control_init_done,
            i_params             => i_params,
            o_iact_done          => o_addr_iact_done,
            i_fifo_full_iact     => i_fifo_iact_address_full,
            o_address_iact       => o_address_iact,
            o_address_iact_valid => o_address_iact_valid
        );

    address_generator_wght_inst : entity accel.address_generator_wght
        generic map (
            size_y         => size_y,
            addr_width_y   => addr_width_y,
            mem_addr_width => mem_addr_width,
            read_size      => mem_word_count
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => w_control_init_done,
            i_params             => i_params,
            i_m0_dist            => w_m0_dist,
            o_wght_done          => o_addr_wght_done,
            i_fifo_full_wght     => i_fifo_wght_address_full,
            o_address_wght       => o_address_wght,
            o_address_wght_valid => o_address_wght_valid
        );

    address_generator_psum_inst : entity accel.address_generator_psum
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            data_width_input => data_width_input,
            data_width_psum  => data_width_psum,
            mem_addr_width   => mem_addr_width,
            mem_columns      => mem_word_count,
            write_size       => mem_word_count
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            i_start          => w_control_init_done,
            i_dataflow       => i_dataflow,
            i_params         => i_params,
            i_valid_psum_out => i_req_addr_psum,
            o_address_psum   => o_address_psum,
            o_suppress_out   => o_psum_suppress_out
        );

    -- cycle counter from start to done
    count_cycles : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' or (i_start = '0' and o_done = '0') then
            o_cyclectr <= (others => '0');
        elsif i_start = '1' and o_done = '0' then
            o_cyclectr <= o_cyclectr + 1;
        end if;

    end process count_cycles;

end architecture rtl;

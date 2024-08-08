library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity control_address_generator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        addr_width_iact_mem : positive := 15;
        addr_width_wght_mem : positive := 15;
        addr_width_psum_mem : positive := 15;

        line_length_iact : positive := 64;
        addr_width_iact  : positive := 6;
        line_length_psum : positive := 128;
        addr_width_psum  : positive := 7;
        line_length_wght : positive := 64;
        addr_width_wght  : positive := 6;

        g_dataflow : integer := 1
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_start             : in    std_logic;
        i_enable_if         : in    std_logic;
        i_all_psum_finished : in    std_logic;

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

        w_fifo_iact_address_full : in    std_logic;
        w_fifo_wght_address_full : in    std_logic;

        o_address_iact       : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        o_address_wght       : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
        o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
    );
end entity control_address_generator;

architecture rtl of control_address_generator is

    signal w_control_init_done : std_logic;

    signal w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0);

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

    g_address_generator : if g_dataflow = 1 generate
    begin

        address_generator_inst : entity accel.address_generator(alternative_rs_dataflow)
            generic map (
                size_x              => size_x,
                size_y              => size_y,
                size_rows           => size_rows,
                addr_width_rows     => addr_width_rows,
                addr_width_y        => addr_width_y,
                addr_width_x        => addr_width_x,
                line_length_iact    => line_length_iact,
                addr_width_iact     => addr_width_iact,
                addr_width_iact_mem => addr_width_iact_mem,
                line_length_psum    => line_length_psum,
                addr_width_psum     => addr_width_psum,
                addr_width_psum_mem => addr_width_psum_mem,
                line_length_wght    => line_length_wght,
                addr_width_wght     => addr_width_wght,
                addr_width_wght_mem => addr_width_wght_mem
            )
            port map (
                clk                  => clk,
                rstn                 => rstn,
                i_start              => w_control_init_done,
                i_params             => i_params,
                i_m0_dist            => w_m0_dist,
                i_fifo_full_iact     => w_fifo_iact_address_full,
                i_fifo_full_wght     => w_fifo_wght_address_full,
                o_address_iact       => o_address_iact,
                o_address_wght       => o_address_wght,
                o_address_iact_valid => o_address_iact_valid,
                o_address_wght_valid => o_address_wght_valid
            );

    else generate
    begin

        address_generator_inst : entity accel.address_generator(rs_dataflow)
            generic map (
                size_x              => size_x,
                size_y              => size_y,
                size_rows           => size_rows,
                addr_width_rows     => addr_width_rows,
                addr_width_y        => addr_width_y,
                addr_width_x        => addr_width_x,
                line_length_iact    => line_length_iact,
                addr_width_iact     => addr_width_iact,
                addr_width_iact_mem => addr_width_iact_mem,
                line_length_psum    => line_length_psum,
                addr_width_psum     => addr_width_psum,
                addr_width_psum_mem => addr_width_psum_mem,
                line_length_wght    => line_length_wght,
                addr_width_wght     => addr_width_wght,
                addr_width_wght_mem => addr_width_wght_mem
            )
            port map (
                clk                  => clk,
                rstn                 => rstn,
                i_start              => w_control_init_done,
                i_params             => i_params,
                i_m0_dist            => w_m0_dist,
                i_fifo_full_iact     => w_fifo_iact_address_full,
                i_fifo_full_wght     => w_fifo_wght_address_full,
                o_address_iact       => o_address_iact,
                o_address_wght       => o_address_wght,
                o_address_iact_valid => o_address_iact_valid,
                o_address_wght_valid => o_address_wght_valid
            );

    end generate g_address_generator;

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

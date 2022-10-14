library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;
    use work.control;
    use work.pe_array;
    use work.address_generator;
    use std.env.finish;
    use std.env.stop;
    use ieee.math_real.ceil;
    use ieee.math_real.log2;

entity control_conv_tb is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 32;
        addr_width_iact  : positive := 5;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 127;
        addr_width_psum  : positive := 7;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 32;
        addr_width_wght  : positive := 5;

        g_channels    : positive := 28;
        g_image_y     : positive := 14;
        g_image_x     : positive := 14;
        g_kernel_size : positive := 5;

        g_tiles_y : positive := positive(integer(ceil(real(g_image_x - g_kernel_size + 1) / real(g_kernel_size)))) -- Y tiles, determined in control module, but for input data loading required here
    );
end entity control_conv_tb;

architecture imp of control_conv_tb is

    component fifo_generator_0 is
        port (
            rst    : in    std_logic;
            wr_clk : in    std_logic;
            rd_clk : in    std_logic;
            din    : in    std_logic_vector(15 downto 0);
            wr_en  : in    std_logic;
            rd_en  : in    std_logic;
            dout   : out   std_logic_vector(15 downto 0);
            full   : out   std_logic;
            empty  : out   std_logic;
            valid  : out   std_logic
        );
    end component;

    component mult_gen_0 is
        port (
            clk : in    std_logic;
            a   : in    std_logic_vector(7 downto 0);
            b   : in    std_logic_vector(7 downto 0);
            ce  : in    std_logic;
            p   : out   std_logic_vector(15 downto 0)
        );
    end component;

    signal clk  : std_logic := '0';
    signal rstn : std_logic;

    signal status       : std_logic;
    signal status_adr   : std_logic;
    signal start        : std_logic;
    signal start_init   : std_logic;
    signal image_x      : integer range 0 to 1023;
    signal image_y      : integer range 0 to 1023;
    signal channels     : integer range 0 to 4095;
    signal kernel_size  : integer range 0 to 32;
    signal command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal i_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_preload_psum_valid : std_logic;

    type delay_array_t is array (natural range <>) of array_t;

    signal i_data_iact       : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_iact_delay : delay_array_t (0 to 3)(0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_iact_array : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_data_wght       : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

    signal i_data_iact_valid       : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_iact_valid_delay : array_t(0 to 3)(size_rows - 1 downto 0);
    signal i_data_iact_valid_array : std_logic_vector(size_rows - 1 downto 0);

    signal o_buffer_full_psum : std_logic;
    signal o_buffer_full_iact : std_logic;
    signal o_buffer_full_wght : std_logic;

    signal o_buffer_full_next_iact : std_logic;
    signal o_buffer_full_next_psum : std_logic;
    signal o_buffer_full_next_wght : std_logic;

    signal update_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal update_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal update_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal read_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal read_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal read_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal o_psums       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal o_psums_valid : std_logic_vector(size_x - 1 downto 0);

    signal s_x  : integer;
    signal s_y  : integer;
    signal s_c  : integer;
    signal s_c0 : integer;

    signal s_wght_x  : integer;
    signal s_wght_y  : integer;
    signal s_wght_c  : integer;
    signal s_wght_c0 : integer;

    signal i_data_psum_valid : std_logic;
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal tiles_c : integer range 0 to 1023;
    signal tiles_x : integer range 0 to 1023;
    signal tiles_y : integer range 0 to 1023;

    signal c_per_tile  : integer range 0 to 1023;
    signal c_last_tile : integer range 0 to 1023;

    signal fifo_din   : std_logic_vector(15 downto 0);
    signal fifo_dout  : std_logic_vector(15 downto 0);
    signal fifo_wr_en : std_logic;
    signal fifo_rd_en : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_empty : std_logic;
    signal fifo_valid : std_logic;

    signal mult_out : std_logic_vector(15 downto 0);

    -- INPUT IMAGE, FILTER WEIGTHS AND EXPECTED OUTPUT

    signal s_input_image     : int_image_t(0 to size_rows - 1, 0 to g_image_x * g_channels * g_tiles_y - 1);         -- 2, because two tile_y
    signal s_input_weights   : int_image_t(0 to g_kernel_size - 1, 0 to g_kernel_size * g_channels * g_tiles_y - 1); -- not *2 because kernel stays the same across tile_y
    signal s_expected_output : int_image_t(0 to g_image_y - g_kernel_size, 0 to g_image_x - g_kernel_size);

    procedure incr (signal s_y : inout integer; signal s_x : inout integer; signal s_c : out integer; signal s_c0 : inout integer; variable s_tile_c : inout integer) is
    begin

        if s_tile_c = tiles_c - 1 and s_x = g_image_x - 1 and ((s_c0 = c_per_tile - 1 and s_tile_c /= tiles_c - 1) or (s_c0 = c_last_tile - 1 and s_tile_c = tiles_c - 1)) then
            s_c0     <= 0;
            s_x      <= 0;
            s_tile_c := 0;
            s_y      <= s_y + g_kernel_size;
        elsif s_x = g_image_x - 1 and ((s_c0 = c_per_tile - 1 and s_tile_c /= tiles_c - 1) or (s_c0 = c_last_tile - 1 and s_tile_c = tiles_c - 1)) then
            s_x      <= 0;
            s_c0     <= 0;
            s_tile_c := s_tile_c + 1;
        elsif (s_c0 = c_per_tile - 1 and s_tile_c /= tiles_c - 1) or (s_c0 = c_last_tile - 1 and s_tile_c = tiles_c - 1) then
            s_x <= s_x + 1;
        else
            s_c0 <= s_c0 + 1;
        end if;

        s_c <= s_tile_c * c_per_tile + s_c0;

    end procedure;

    procedure incr_wght (signal s_wght_y : inout integer; signal s_wght_x : inout integer; signal s_wght_c : out integer; signal s_wght_c0 : inout integer; variable s_wght_tile_c : inout integer) is
    begin

        if s_wght_tile_c = tiles_c - 1 and s_wght_x = g_kernel_size - 1 and ((s_wght_c0 = c_per_tile - 1 and s_wght_tile_c /= tiles_c - 1) or (s_wght_c0 = c_last_tile - 1 and s_wght_tile_c = tiles_c - 1)) then
            s_wght_c0     <= 0;
            s_wght_x      <= 0;
            s_wght_tile_c := 0;
            s_wght_y      <= s_wght_y + g_kernel_size;
        elsif s_wght_x = g_kernel_size - 1 and ((s_wght_c0 = c_per_tile - 1 and s_wght_tile_c /= tiles_c - 1) or (s_wght_c0 = c_last_tile - 1 and s_wght_tile_c = tiles_c - 1)) then
            s_wght_x      <= 0;
            s_wght_c0     <= 0;
            s_wght_tile_c := s_wght_tile_c + 1;
        elsif (s_wght_c0 = c_per_tile - 1 and s_wght_tile_c /= tiles_c - 1) or (s_wght_c0 = c_last_tile - 1 and s_wght_tile_c = tiles_c - 1) then
            s_wght_x <= s_wght_x + 1;
        else
            s_wght_c0 <= s_wght_c0 + 1;
        end if;

        s_wght_c <= s_wght_tile_c * c_per_tile + s_wght_c0;

    end procedure;

begin

    i_data_iact_delay(3) <= i_data_iact when rising_edge(clk);
    i_data_iact_delay(2) <= i_data_iact_delay(3) when rising_edge(clk);
    i_data_iact_delay(1) <= i_data_iact_delay(2) when rising_edge(clk);
    i_data_iact_delay(0) <= i_data_iact_delay(1) when rising_edge(clk);

    i_data_iact_array <= i_data_iact(0 to 4) & i_data_iact_delay(3)(5) & i_data_iact_delay(2)(6) & i_data_iact_delay(1)(7) & i_data_iact_delay(0)(8);

    i_data_iact_valid_delay(3) <= i_data_iact_valid when rising_edge(clk);
    i_data_iact_valid_delay(2) <= i_data_iact_valid_delay(3) when rising_edge(clk);
    i_data_iact_valid_delay(1) <= i_data_iact_valid_delay(2) when rising_edge(clk);
    i_data_iact_valid_delay(0) <= i_data_iact_valid_delay(1) when rising_edge(clk);

    i_data_iact_valid_array <= i_data_iact_valid_delay(0)(8) & i_data_iact_valid_delay(1)(7) & i_data_iact_valid_delay(2)(6) & i_data_iact_valid_delay(3)(5) & i_data_iact_valid(4 downto 0);

    fifo_din   <= (15 downto 8 => '0') & i_data_iact(0);
    fifo_wr_en <= '1';
    fifo_rd_en <= '1';

    fifo_inst : component fifo_generator_0
        port map (
            rst    => not rstn,
            wr_clk => clk,
            rd_clk => clk,
            din    => fifo_din,
            wr_en  => fifo_wr_en,
            rd_en  => fifo_rd_en,
            dout   => fifo_dout,
            full   => fifo_full,
            empty  => fifo_empty,
            valid  => fifo_valid
        );

    your_instance_name : component mult_gen_0
        port map (
            clk => clk,
            a   => i_data_iact(0),
            b   => i_data_iact(0),
            ce  => '1',
            p   => mult_out
        );

    address_generator_inst : entity work.address_generator
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            status           => status_adr,
            i_start          => status,
            start_init       => start_init,
            tiles_c          => tiles_c,
            tiles_x          => tiles_x,
            tiles_y          => tiles_y,
            c_per_tile       => c_per_tile,
            c_last_tile      => c_last_tile,
            image_x          => image_x,
            image_y          => image_y,
            channels         => channels,
            i_kernel_size    => kernel_size,
            i_fifo_full_iact => '0',
            i_fifo_full_wght => '0'
        );

    control_inst : entity work.control
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
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
            o_status             => status,
            i_start              => start,
            i_start_init         => start_init,
            o_tiles_c            => tiles_c,
            o_tiles_x            => tiles_x,
            o_tiles_y            => tiles_y,
            o_c_per_tile         => c_per_tile,
            o_c_last_tile        => c_last_tile,
            i_image_x            => image_x,
            i_image_y            => image_y,
            i_channels           => channels,
            i_kernel_size        => kernel_size,
            o_command            => command,
            o_command_iact       => command_iact,
            o_command_psum       => command_psum,
            o_command_wght       => command_wght,
            o_update_offset_iact => update_offset_iact,
            o_update_offset_psum => update_offset_psum,
            o_update_offset_wght => update_offset_wght,
            o_read_offset_iact   => read_offset_iact,
            o_read_offset_psum   => read_offset_psum,
            o_read_offset_wght   => read_offset_wght
        );

    pe_array_inst : entity work.pe_array
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            data_width_iact  => data_width_iact,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            data_width_psum  => data_width_psum,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            data_width_wght  => data_width_wght,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght
        )
        port map (
            clk                     => clk,
            rstn                    => rstn,
            i_preload_psum          => i_preload_psum,
            i_preload_psum_valid    => i_preload_psum_valid,
            i_command               => command,
            i_command_iact          => command_iact,
            i_command_psum          => command_psum,
            i_command_wght          => command_wght,
            i_data_iact             => i_data_iact_array,
            i_data_psum             => i_data_psum,
            i_data_wght             => i_data_wght,
            i_data_iact_valid       => i_data_iact_valid_array,
            i_data_psum_valid       => i_data_psum_valid,
            i_data_wght_valid       => i_data_wght_valid,
            o_buffer_full_iact      => o_buffer_full_iact,
            o_buffer_full_psum      => o_buffer_full_psum,
            o_buffer_full_wght      => o_buffer_full_wght,
            o_buffer_full_next_iact => o_buffer_full_next_iact,
            o_buffer_full_next_psum => o_buffer_full_next_psum,
            o_buffer_full_next_wght => o_buffer_full_next_wght,
            i_update_offset_iact    => update_offset_iact,
            i_update_offset_psum    => update_offset_psum,
            i_update_offset_wght    => update_offset_wght,
            i_read_offset_iact      => read_offset_iact,
            i_read_offset_psum      => read_offset_psum,
            i_read_offset_wght      => read_offset_wght,
            o_psums                 => o_psums,
            o_psums_valid           => o_psums_valid
        );

    rstn_gen : process is
    begin

        rstn <= '0';
        wait for 100 ns;
        rstn <= '1';
        wait;

    end process rstn_gen;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

    start_config : process is
    begin

        wait until rstn = '1';
        wait until rising_edge(clk);

        start      <= '0';
        start_init <= '0';

        image_x     <= g_image_x;
        image_y     <= g_image_y;
        channels    <= g_channels;
        kernel_size <= g_kernel_size;

        wait for 30 ns;
        start_init <= '1';

        wait for 50 ns;
        start <= '1';

        wait;

    end process start_config;

    /*p_read_files : process is
    begin

        s_input_image     <= read_file(file_name => "src/_image.txt", num_col => g_image_x, num_row => g_image_y, num_channels => g_channels);
        s_input_weights   <= read_file(file_name => "src/_kernel.txt", num_col => g_kernel_size, num_row => g_kernel_size, num_channels => g_channels);
        s_expected_output <= read_file(file_name => "src/_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;*/

    p_read_files : process is
    begin

        s_input_image     <= read_file(file_name => "/home/uzedl/Documents/reconfigurable-accelerator/testbenches/control_conv_adr/src/_image_reordered.txt", num_col => g_image_x * g_channels * g_tiles_y, num_row => size_rows);
        s_input_weights   <= read_file(file_name => "/home/uzedl/Documents/reconfigurable-accelerator/testbenches/control_conv_adr/src/_kernel_reordered.txt", num_col => g_kernel_size * g_channels * g_tiles_y, num_row => g_kernel_size);
        s_expected_output <= read_file(file_name => "/home/uzedl/Documents/reconfigurable-accelerator/testbenches/control_conv_adr/src/_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;

    p_constant_check : process is
    begin

        -- assert line_length_iact >= g_kernel_size * g_channels
        --     report "Line length to store input values must be greater or equal to the kernel size"
        --     severity failure;

        assert size_y >= g_kernel_size
            report "Y dimension of PE array has to be greater or equal to kernel size"
            severity failure;

        -- assert line_length_wght >= g_kernel_size * g_channels
        --     report "Length of wght buffer has to be greater or equal to kernel size, buffer has to store values of one kernel row at a time."
        --     severity failure;

        assert line_length_psum >= g_image_x - g_kernel_size
            report "Psum buffer has to hold output values of one row, must not be smaller than output row size"
            severity failure; /* TODO To be changed by splitting the task and propagating as many psums that the buffer can hold through the array at once */

        assert addr_width_iact = integer(ceil(log2(real(line_length_iact))))
            report "Check iact address width!"
            severity failure;

        assert addr_width_psum = integer(ceil(log2(real(line_length_psum))))
            report "Check psum address width!"
            severity failure;

        assert addr_width_wght = integer(ceil(log2(real(line_length_wght))))
            report "Check wght address width!"
            severity failure;

        wait;

    end process p_constant_check;

    /*stimuli_data_wght : process is
    begin

        i_data_wght       <= (others => (others => '0'));
        i_data_wght_valid <= (others => '0');

        wait until rstn = '1';
        wait until rising_edge(clk);

        i_data_wght_valid <= (others => '1');

        for i in 0 to size_x - 1 loop

            for c in 0 to g_channels - 1 loop 

                while o_buffer_full_wght = '1' loop

                    wait until rising_edge(clk);

                end loop;

                for y in 0 to size_y - 1 loop

                    -- data_in_wght <= std_logic_vector(to_signed(input_wght(i), data_width_iact_wght));
                    i_data_wght(y) <= std_logic_vector(to_signed(s_input_weights(c,y,i), data_width_wght));

                end loop;

                wait until rising_edge(clk);

            end loop;

        end loop;

        i_data_wght_valid <= (others => '0');

        wait;

    end process stimuli_data_wght;*/

    /*stimuli_data_wght : process (rstn, clk) is

        variable loop_max : integer;
        variable s_wght_tile_c : integer;
    begin

        if not rstn then
            i_data_wght       <= (others => (others => '0'));
            i_data_wght_valid <= (others => '0');
            s_wght_c          <= 0;
            s_wght_x          <= 0;
            s_wght_y          <= 0;
            s_wght_c0         <= 0;
            s_wght_tile_c     := 0;
            loop_max          := g_kernel_size;
        elsif rising_edge(clk) then
            if status then
                if s_wght_y >= g_kernel_size then
                -- Done
                elsif o_buffer_full_wght = '0' then
                    if s_wght_y + size_y > g_kernel_size then
                        loop_max := g_kernel_size - s_wght_y;
                    end if;

                    for i in 0 to loop_max - 1 loop

                        i_data_wght_valid(i) <= '1';
                        i_data_wght(i)       <= std_logic_vector(to_signed(s_input_weights(s_wght_c, i + s_wght_y), data_width_wght));

                    end loop;

                    incr_wght(s_wght_y, s_wght_x, s_wght_c, s_wght_c0, s_wght_tile_c);
                end if;
            end if;
        end if;

    end process stimuli_data_wght;*/

    stimuli_data_wght : process (rstn, clk) is

        variable loop_max      : integer;
        variable s_wght_tile_c : integer;

    begin

        if not rstn then
            i_data_wght       <= (others => (others => '0'));
            i_data_wght_valid <= (others => '0');
            s_wght_x          <= 0;
        elsif rising_edge(clk) then
            if status then
                if s_wght_x >= g_kernel_size * g_channels * g_tiles_y then
                -- Done
                elsif o_buffer_full_wght = '0' then -- o_buffer_full_wght_write then
                    i_data_wght_valid <= (others => '1');
                    i_data_wght(0)    <= std_logic_vector(to_signed(s_input_weights(0, s_wght_x), data_width_wght));
                    i_data_wght(1)    <= std_logic_vector(to_signed(s_input_weights(1, s_wght_x), data_width_wght));
                    i_data_wght(2)    <= std_logic_vector(to_signed(s_input_weights(2, s_wght_x), data_width_wght));
                    i_data_wght(3)    <= std_logic_vector(to_signed(s_input_weights(3, s_wght_x), data_width_wght));
                    i_data_wght(4)    <= std_logic_vector(to_signed(s_input_weights(4, s_wght_x), data_width_wght));

                    s_wght_x <= s_wght_x + 1;
                else
                -- i_data_wght_valid <= (others => '0');
                end if;
            end if;
        end if;

    end process stimuli_data_wght;

    stimuli_data_iact : process (rstn, clk) is

        variable loop_max : integer;
        variable s_tile_c : integer;

    begin

        if not rstn then
            i_data_iact       <= (others => (others => '0'));
            i_data_iact_valid <= (others => '0');
            s_x               <= 0;
        elsif rising_edge(clk) then
            if status then
                if s_x >= g_image_x * g_channels * g_tiles_y then
                -- Done
                elsif o_buffer_full_iact = '0' then -- o_buffer_full_iact_write then
                    i_data_iact_valid <= (others => '1');
                    i_data_iact(0)    <= std_logic_vector(to_signed(s_input_image(0, s_x), data_width_iact));
                    i_data_iact(1)    <= std_logic_vector(to_signed(s_input_image(1, s_x), data_width_iact));
                    i_data_iact(2)    <= std_logic_vector(to_signed(s_input_image(2, s_x), data_width_iact));
                    i_data_iact(3)    <= std_logic_vector(to_signed(s_input_image(3, s_x), data_width_iact));
                    i_data_iact(4)    <= std_logic_vector(to_signed(s_input_image(4, s_x), data_width_iact));
                    i_data_iact(5)    <= std_logic_vector(to_signed(s_input_image(5, s_x), data_width_iact));
                    i_data_iact(6)    <= std_logic_vector(to_signed(s_input_image(6, s_x), data_width_iact));
                    i_data_iact(7)    <= std_logic_vector(to_signed(s_input_image(7, s_x), data_width_iact));
                    i_data_iact(8)    <= std_logic_vector(to_signed(s_input_image(8, s_x), data_width_iact));

                    s_x <= s_x + 1;
                else
                -- i_data_iact_valid <= (others => '0');
                end if;
            end if;
        end if;

    end process stimuli_data_iact;

    /*stimuli_data_iact : process (rstn, clk) is

        variable loop_max : integer;
        variable s_tile_c : integer;

    begin

        if not rstn then
            i_data_iact       <= (others => (others => '0'));
            i_data_iact_valid <= (others => '0');
            s_c               <= 0;
            s_x               <= 0;
            s_y               <= 0;
            s_tile_c          := 0;
            s_c0              <= 0;
            loop_max          := size_rows;
        elsif rising_edge(clk) then
            if status then
                if s_y >= image_y then
                -- Done
                elsif o_buffer_full_iact = '0' then
                    if s_y + size_rows > image_y then
                        loop_max := image_y - s_y;
                    end if;

                    for i in 0 to loop_max - 1 loop

                        i_data_iact_valid(i) <= '1';
                        i_data_iact(i)       <= std_logic_vector(to_signed(s_input_image(s_c, i + s_y), data_width_iact));

                    end loop;

                    incr(s_y, s_x, s_c, s_c0, s_tile_c);
                end if;
            end if;
        end if;

    end process stimuli_data_iact;*/

    output_check : for p in 0 to size_x - 1 generate

        output_check_last_row : if p = size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                wait for 1000 ns;

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to tiles_y - 1 loop /* TODO Adjust range based on image size */

                    output_loop : for i in 0 to g_image_x - g_kernel_size loop

                        wait until rising_edge(clk);

                        -- If result is not valid, wait until next rising edge with valid results.
                        if o_psums_valid(p) = '0' then
                            wait until rising_edge(clk) and o_psums_valid(p) = '1';
                        end if;

                        check_rows := size_y - 1;

                        if j = 2 then
                            check_rows := size_y - 1; /* TODO Adjust based on image size */
                        end if;

                        assert o_psums(p) = std_logic_vector(to_signed(s_expected_output(p + j * g_kernel_size,i), data_width_psum))
                            report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(p)))) & " - should be "
                                   & integer'image(s_expected_output(p + j * g_kernel_size,i))
                            severity failure;

                        report "Got correct result " & integer'image(to_integer(signed(o_psums(p))));

                    end loop;

                    wait until rising_edge(clk);

                end loop;

                -- Check if result valid signal is set to zero afterwards
                assert o_psums_valid(p) = '0'
                    report "Result valid should be zero"
                    severity failure;

                report "Output check is finished."
                    severity note;
                finish;

                wait;

            end process output_check;

        end generate output_check_last_row;

        output_check_other_rows : if p /= size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                wait for 1000 ns;

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to tiles_y - 1 loop /* TODO Adjust range based on image size */

                    output_loop : for i in 0 to g_image_x - g_kernel_size loop

                        wait until rising_edge(clk);

                        -- If result is not valid, wait until next rising edge with valid results.
                        if o_psums_valid(p) = '0' then
                            wait until rising_edge(clk) and o_psums_valid(p) = '1';
                        end if;

                        check_rows := size_y - 1;

                        if j = 2 then
                            check_rows := size_y - 1; /* TODO Adjust based on image size */
                        end if;

                        assert o_psums(p) = std_logic_vector(to_signed(s_expected_output(p + j * g_kernel_size,i), data_width_psum))
                            report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(p)))) & " - should be "
                                   & integer'image(s_expected_output(p + j * g_kernel_size,i))
                            severity failure;

                        report "Got correct result " & integer'image(to_integer(signed(o_psums(p))));

                    end loop;

                    wait until rising_edge(clk);

                end loop;

                -- Check if result valid signal is set to zero afterwards
                assert o_psums_valid(p) = '0'
                    report "Result valid should be zero"
                    severity failure;

                wait;

            end process output_check;

        end generate output_check_other_rows;

    end generate output_check;

end architecture imp;

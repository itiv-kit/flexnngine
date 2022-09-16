library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;
    use work.control;
    use work.pe_array;
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
        line_length_iact : positive := 15;
        addr_width_iact  : positive := 4;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 10;
        addr_width_psum  : positive := 4;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 15;
        addr_width_wght  : positive := 4;

        g_channels    : positive := 3;
        g_image_y     : positive := 14;
        g_image_x     : positive := 14;
        g_kernel_size : positive := 5;

        g_tiles : positive := 2 -- Only for output check - internally calculated within control module !!
    );
end entity control_conv_tb;

architecture imp of control_conv_tb is

    signal clk  : std_logic := '0';
    signal rstn : std_logic;

    signal status       : std_logic;
    signal start        : std_logic;
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

    signal o_buffer_full_iact : std_logic;
    signal o_buffer_full_psum : std_logic;
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

    signal s_x    : integer;
    signal s_y    : integer;
    signal s_c    : integer;
    signal s_done : boolean;

    signal s_tile_done : boolean;

    signal i_data_psum_valid : std_logic;
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    -- INPUT IMAGE, FILTER WEIGTHS AND EXPECTED OUTPUT

    signal s_input_image     : int_image3_t(0 to g_channels - 1, 0 to g_image_y - 1, 0 to g_image_x - 1);         -- int_image_t(0 to image_y - 1, 0 to image_x - 1);
    signal s_input_weights   : int_image3_t(0 to g_channels - 1, 0 to g_kernel_size - 1, 0 to g_kernel_size - 1); -- int_image_t(0 to kernel_size - 1, 0 to kernel_size - 1);
    signal s_expected_output : int_image_t(0 to g_image_y - g_kernel_size, 0 to g_image_x - g_kernel_size);

    procedure incr (signal pointer_y : inout integer; signal pointer_x : inout integer; signal pointer_c : inout integer) is
    begin

        if pointer_x = image_x - 1 and pointer_c = channels - 1 then
            pointer_c <= 0;
            pointer_x <= 0;
            pointer_y <= pointer_y + kernel_size;
        elsif pointer_c = channels - 1 then
            pointer_c <= 0;
            pointer_x <= pointer_x + 1;
        else
            pointer_c <= pointer_c + 1;
        end if;

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
            clk                => clk,
            rstn               => rstn,
            status             => status,
            start              => start,
            image_x            => image_x,
            image_y            => image_y,
            channels           => channels,
            kernel_size        => kernel_size,
            command            => command,
            command_iact       => command_iact,
            command_psum       => command_psum,
            command_wght       => command_wght,
            update_offset_iact => update_offset_iact,
            update_offset_psum => update_offset_psum,
            update_offset_wght => update_offset_wght,
            read_offset_iact   => read_offset_iact,
            read_offset_psum   => read_offset_psum,
            read_offset_wght   => read_offset_wght
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
            command                 => command,
            command_iact            => command_iact,
            command_psum            => command_psum,
            command_wght            => command_wght,
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
            update_offset_iact      => update_offset_iact,
            update_offset_psum      => update_offset_psum,
            update_offset_wght      => update_offset_wght,
            read_offset_iact        => read_offset_iact,
            read_offset_psum        => read_offset_psum,
            read_offset_wght        => read_offset_wght,
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

        start <= '0';

        image_x     <= g_image_x;
        image_y     <= g_image_y;
        channels    <= g_channels;
        kernel_size <= g_kernel_size;

        wait for 50 ns;
        start <= '1';

        wait;

    end process start_config;

    p_read_files : process is
    begin

        s_input_image     <= read_file(file_name => "src/_image.txt", num_col => g_image_x, num_row => g_image_y, num_channels => g_channels);
        s_input_weights   <= read_file(file_name => "src/_kernel.txt", num_col => g_kernel_size, num_row => g_kernel_size, num_channels => g_channels);
        s_expected_output <= read_file(file_name => "src/_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;

    p_constant_check : process is
    begin

        assert line_length_iact >= kernel_size * channels
            report "Line length to store input values must be greater or equal to the kernel size"
            severity failure;

        assert size_y >= kernel_size
            report "Y dimension of PE array has to be greater or equal to kernel size"
            severity failure;

        assert line_length_wght >= kernel_size * channels
            report "Length of wght buffer has to be greater or equal to kernel size, buffer has to store values of one kernel row at a time."
            severity failure;

        assert line_length_psum >= image_x - kernel_size
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

    stimuli_data_wght : process is
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

    end process stimuli_data_wght;

    stimuli_data_iact : process (rstn, clk) is

        variable loop_max : integer;

    begin

        if not rstn then
            i_data_iact       <= (others => (others => '0'));
            i_data_iact_valid <= (others => '0');
            s_c               <= 0;
            s_x               <= 0;
            s_y               <= 0;
            s_done            <= false;
            loop_max          := size_rows;
        elsif rising_edge(clk) then
            if s_y >= image_y then
                s_done <= true;
            -- data_in_valid <= '0';
            elsif o_buffer_full_iact = '0' then
                if s_y + size_rows > image_y then
                    loop_max := image_y - s_y;
                end if;

                for i in 0 to loop_max - 1 loop

                    i_data_iact_valid(i) <= '1';
                    i_data_iact(i)       <= std_logic_vector(to_signed(s_input_image(s_c, i + s_y, s_x), data_width_iact));

                end loop;

                incr(s_y,s_x, s_c);
            end if;
        end if;

    end process stimuli_data_iact;

    output_check : for p in 0 to size_x - 1 generate

        output_check_last_row : if p = size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to g_tiles - 1 loop /* TODO Adjust range based on image size */

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

                    s_tile_done <= true;
                    wait until rising_edge(clk);
                    s_tile_done <= false;

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

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to g_tiles - 1 loop /* TODO Adjust range based on image size */

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

                    -- s_tile_done <= true;
                    wait until rising_edge(clk);
                -- s_tile_done <= false;

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

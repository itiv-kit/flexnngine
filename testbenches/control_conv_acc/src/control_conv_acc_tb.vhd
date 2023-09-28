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

entity control_conv_acc_tb is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 32;
        addr_width_iact     : positive := 5;
        addr_width_iact_mem : positive := 15;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 127;
        addr_width_psum     : positive := 7;
        addr_width_psum_mem : positive := 15;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 32;
        addr_width_wght     : positive := 5;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_channels    : positive := 10;
        g_image_y     : positive := 29;
        g_image_x     : positive := 29;
        g_kernel_size : positive := 5;

        g_h2 : positive := positive(integer(ceil(real(g_image_x - g_kernel_size + 1) / real(g_kernel_size)))) -- Y tiles, determined in control module, but for input data loading required here
    );
end entity control_conv_acc_tb;

architecture imp of control_conv_acc_tb is

    signal clk    : std_logic := '0';
    signal clk_sp : std_logic := '0';
    signal rstn   : std_logic;

    signal start      : std_logic;
    signal start_init : std_logic;

    signal o_psums           : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal o_psums_valid     : std_logic_vector(size_x - 1 downto 0);
    signal i_data_iact       : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_wght       : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal s_input_image     : int_image_t(0 to size_rows - 1, 0 to g_image_x * g_channels * g_h2 - 1);         -- 2, because two tile_y
    signal s_input_weights   : int_image_t(0 to g_kernel_size - 1, 0 to g_kernel_size * g_channels * g_h2 - 1); -- not *2 because kernel stays the same across tile_y
    signal s_expected_output : int_image_t(0 to g_image_y - g_kernel_size, 0 to g_image_x - g_kernel_size);

    signal dout_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal dout_psum_valid : std_logic;
    signal write_en_iact   : std_logic;
    signal write_en_wght   : std_logic;
    signal din_iact        : std_logic_vector(data_width_iact - 1 downto 0);
    signal din_wght        : std_logic_vector(data_width_wght - 1 downto 0);

begin

    o_psums           <= << signal accelerator_inst.w_psums : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0) >>;
    o_psums_valid     <= << signal accelerator_inst.w_psums_valid : std_logic_vector(size_x - 1 downto 0) >>;
    i_data_iact       <= << signal accelerator_inst.w_data_iact : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0) >>;
    i_data_iact_valid <= << signal accelerator_inst.w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0) >>;
    i_data_wght       <= << signal accelerator_inst.w_data_wght : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0) >>;
    i_data_wght_valid <= << signal accelerator_inst.w_data_wght_valid : std_logic_vector(size_y - 1 downto 0) >>;

    write_en_iact <= '0';
    write_en_wght <= '0';
    din_iact      <= (others => '0');
    din_wght      <= (others => '0');

    accelerator_inst : entity work.accelerator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            data_width_iact     => data_width_iact,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            data_width_psum     => data_width_psum,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            data_width_wght     => data_width_wght,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem,
            fifo_width          => fifo_width,
            g_channels          => g_channels,
            g_image_y           => g_image_y,
            g_image_x           => g_image_x,
            g_kernel_size       => g_kernel_size
        )
        port map (
            clk               => clk,
            rstn              => rstn,
            clk_sp            => clk_sp,
            i_start_init      => start_init,
            i_start           => start,
            o_dout_psum       => dout_psum,
            o_dout_psum_valid => dout_psum_valid,
            i_write_en_iact   => write_en_iact,
            i_write_en_wght   => write_en_wght,
            i_din_iact        => din_iact,
            i_din_wght        => din_wght
        );

    rstn_gen : process is
    begin

        rstn  <= '0';
        start <= '0';
        wait for 100 ns;
        rstn  <= '1';
        wait for 20 ns;
        start <= '1';
        wait;

    end process rstn_gen;

    clk_gen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clk_gen;

    clk_sp_gen : process (clk_sp) is
    begin

        clk_sp <= not clk_sp after 4 ns;

    end process clk_sp_gen;

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

        assert addr_width_x = integer(ceil(log2(real(size_x))))
            report "Check address width x!"
            severity failure;

        assert addr_width_y = integer(ceil(log2(real(size_y))))
            report "Check address width y!"
            severity failure;

        assert addr_width_rows = integer(ceil(log2(real(size_rows))))
            report "Check address width rows!"
            severity failure;

        wait;

    end process p_constant_check;

    p_read_files : process is
    begin

        s_input_image     <= read_file(file_name => "src/_image_reordered.txt", num_col => g_image_x * g_channels * g_h2, num_row => size_rows);
        s_input_weights   <= read_file(file_name => "src/_kernel_reordered.txt", num_col => g_kernel_size * g_channels * g_h2, num_row => g_kernel_size);
        s_expected_output <= read_file(file_name => "src/_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;

    p_check_img : for y in 0 to size_rows - 1 generate

        p_check_image_vals : process is
        begin

            for i in 0 to g_image_x * g_channels * g_h2 - 1 loop

                wait until rising_edge(clk) and i_data_iact_valid(y) = '1';

                assert i_data_iact(y) = std_logic_vector(to_signed(s_input_image(y, i), data_width_iact))
                    report "Input iact " & integer'image(i) & " wrong. Iact is " & integer'image(to_integer(signed(i_data_iact(y)))) & " - should be "
                           & integer'image(s_input_image(y, i))
                    severity failure;

                report "Got correct iact " & integer'image(to_integer(signed(i_data_iact(y)))) & " (" & integer'image(i) & ")";

            end loop;

            while true loop

                assert i_data_iact_valid(y) = '0'
                    report "Input data iact should not be valid!"
                    severity warning;

                wait until i_data_iact_valid(y)'event;

            end loop;

        end process p_check_image_vals;

    end generate p_check_img;

    p_check_wght : for y in 0 to size_y - 1 generate

        p_check_wght_vals : process is
        begin

            for i in 0 to g_kernel_size * g_channels * g_h2 - 1 loop

                wait until rising_edge(clk) and i_data_wght_valid(y) = '1';

                assert i_data_wght(y) = std_logic_vector(to_signed(s_input_weights(y, i), data_width_wght))
                    report "Input wght (" & integer'image(y) & ") wrong. Wght is " & integer'image(to_integer(signed(i_data_wght(y)))) & " - should be "
                           & integer'image(s_input_weights(y, i))
                    severity failure;

                report "Got correct (" & integer'image(y) & ") wght " & integer'image(to_integer(signed(i_data_wght(y))));

            end loop;

            while true loop

                assert i_data_wght_valid(y) = '0'
                    report "Input data wght should not be valid!"
                    severity warning;

                wait until i_data_wght_valid(y)'event;

            end loop;

        end process p_check_wght_vals;

    end generate p_check_wght;

    output_check : for p in 0 to size_x - 1 generate

        output_check_last_row : if p = size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                wait for 1000 ns;

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to g_h2 - 1 loop /* TODO Adjust range based on image size */

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

                for j in 0 to g_h2 - 1 loop /* TODO Adjust range based on image size */

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

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! Testbench for the line buffer

--! The line_buffer is filled with the input activations of a test image.
--! The testbench checks if the correct input activations appear on the output
--! at the right time according to a convolution with kernel 5.

entity line_buffer_iact_tb is
    generic (
        line_length     : positive := 7; --! Length of the lines in the test image
        number_of_lines : positive := 5; --! Number of lines in the test image
        addr_width      : positive := 3; --! Address width for the ram_dp component
        data_width      : positive := 8; --! 8 bit data being saved
        kernel_size     : positive := 5  --! 3 pixel kernel
    );
end entity line_buffer_iact_tb;

architecture imp of line_buffer_iact_tb is

    component line_buffer is
        generic (
            line_length : positive := 7;
            addr_width  : positive := 3;
            data_width  : positive := 8
        );
        port (
            clk            : in    std_logic;
            rstn           : in    std_logic;
            data_in        : in    std_logic_vector(data_width - 1 downto 0);
            data_in_valid  : in    std_logic;
            data_out       : out   std_logic_vector(data_width - 1 downto 0);
            data_out_valid : out   std_logic;
            buffer_full    : out   std_logic;
            update_val     : in    std_logic_vector(data_width - 1 downto 0);
            update_offset  : in    std_logic_vector(addr_width - 1 downto 0);
            read_offset    : in    std_logic_vector(addr_width - 1 downto 0);
            command        : in    command_lb_t
        );
    end component;

    signal clk            : std_logic := '1';
    signal rstn           : std_logic;
    signal data_in_valid  : std_logic;
    signal data_in        : std_logic_vector(data_width - 1 downto 0);
    signal data_out       : std_logic_vector(data_width - 1 downto 0);
    signal data_out_valid : std_logic;
    signal buffer_full    : std_logic;
    signal update_val     : std_logic_vector(data_width - 1 downto 0);
    signal update_offset  : std_logic_vector(addr_width - 1 downto 0);
    signal read_offset    : std_logic_vector(addr_width - 1 downto 0);
    signal command        : command_lb_t;

    type image_t is array(natural range <>, natural range <>) of integer;

    -- test data, simulates the output of classify
    constant test_image : image_t(0 to number_of_lines - 1, 0 to line_length - 1) := (
        (1,  2,  3,  4,  5,  6,  7),
        (8,  9,  10, 11, 12, 13, 14),
        (15 ,16 ,17 ,18 ,19, 20, 21),
        (22, 23, 24, 25, 26, 27, 28),
        (29, 30, 31, 32, 33, 34, 35)
    );

    -- Kernel 5 px
    constant expected_output : image_t(0 to number_of_lines - 1, 0 to (line_length - kernel_size + 1) * kernel_size - 1) := (
        (1,  2,  3,  4,  5,  2,  3,  4,  5,  6,  3,  4,  5,  6,  7),
        (8,  9,  10, 11, 12, 9,  10, 11, 12, 13, 10, 11, 12, 13, 14),
        (15, 16, 17, 18, 19, 16, 17, 18, 19, 20, 17, 18, 19, 20, 21),
        (22, 23, 24, 25, 26, 23, 24, 25, 26, 27, 24, 25, 26, 27, 28),
        (29, 30, 31, 32, 33, 30, 31, 32, 33, 34, 31, 32, 33, 34, 35)
    );

    /*
    -- Kernel 3 px
    constant expected_output : image_t(0 to number_of_lines-1, 0 to (line_length-kernel_size+1)*kernel_size-1) := (
        (1,  2,  3,  2,  3,  4,  3,  4,  5,  4,  5,  6,  5,  6,  7 ),
        (8,  9,  10, 9,  10, 11, 10, 11, 12, 11, 12, 13, 12, 13, 14),
        (15, 16, 17, 16, 17, 18, 17, 18, 19, 18, 19, 20, 19, 20, 21),
        (22, 23, 24, 23, 24, 25, 24, 25, 26, 25, 26, 27, 26, 27, 28),
        (29, 30, 31, 30, 31, 32, 31, 32, 33, 32, 33, 34, 33, 34, 35)
    );*/

begin

    line_buffer_inst : component line_buffer
        generic map (
            line_length => line_length,
            addr_width  => addr_width,
            data_width  => data_width
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            data_in        => data_in,
            data_in_valid  => data_in_valid,
            data_out       => data_out,
            data_out_valid => data_out_valid,
            buffer_full    => buffer_full,
            update_val     => update_val,
            update_offset  => update_offset,
            read_offset    => read_offset,
            command        => command
        );

    stimuli_data : process is
    begin

        rstn          <= '0';
        data_in       <= (others => '0');
        data_in_valid <= '0';

        wait for 100 ns;
        rstn          <= '1';
        wait until rising_edge(clk);
        data_in_valid <= '1';

        for y in 0 to number_of_lines - 1 loop

            for x in 0 to line_length - 1 loop

                while buffer_full = '1' loop

                    wait until rising_edge(clk);

                end loop;

                data_in <= std_logic_vector(to_signed(test_image(y, x), data_width));
                wait until rising_edge(clk);

                -- Check behavior with delays in data_in
                if x = 2 then
                    data_in_valid <= '0';
                    wait until rising_edge(clk);
                    data_in_valid <= '1';
                elsif x = 4 then
                    data_in_valid <= '0';
                    wait until rising_edge(clk);
                    wait until rising_edge(clk);
                    data_in_valid <= '1';
                end if;

            end loop;

        end loop;

        wait for 2000 ns;

    end process stimuli_data;

    stimuli_commands : process is
    begin

        wait until rstn = '1';
        read_offset <= (others => '0');

        for y in 0 to number_of_lines - 1 loop

            for x in 0 to line_length - kernel_size loop

                report "Waiting until buffer full";

                if buffer_full = '0' then
                    wait until buffer_full = '1';
                end if;

                wait until rising_edge(clk);

                report "Buffer full, start with commands";

                /*command_enum <= c_read;
                read_offset <= "000";

                wait until rising_edge(clk);

                command_enum <= c_read;
                read_offset <= "001";

                wait until rising_edge(clk);

                command_enum <= c_read;
                read_offset <= "010";

                wait until rising_edge(clk);*/

                for z in 0 to kernel_size - 1 loop -- Read data according to 1D-conv

                    command     <= c_lb_read;
                    read_offset <= std_logic_vector(to_unsigned(z, addr_width));
                    wait until rising_edge(clk);

                end loop;

                read_offset <= std_logic_vector(to_unsigned(1, addr_width));
                command     <= c_lb_shrink;

            end loop;

            wait until rising_edge(clk);

            read_offset <= std_logic_vector(to_unsigned(kernel_size - 1, addr_width));
            command     <= c_lb_shrink;

            wait until rising_edge(clk);
            /*for z in 0 to kernel_size - 1 loop -- Flush remaining pixels 

                wait until rising_edge(clk);
                command_enum <= c_shrink;

            end loop;*/

            command <= c_lb_idle;

        end loop;

    end process stimuli_commands;

    output_check : process is
    begin

        output_loop_lines : for i in 0 to number_of_lines - 1 loop

            output_loop_pixels : for j in 0 to (line_length - kernel_size + 1) * kernel_size - 1 loop

                wait until rising_edge(clk);

                -- If result is not valid, wait until next rising edge with valid results.
                if data_out_valid = '0' then
                    wait until rising_edge(clk) and data_out_valid = '1';
                end if;

                assert data_out = std_logic_vector(to_signed(expected_output(i, j), data_width))
                    report "Output wrong. Result is " & integer'image(to_integer(signed(data_out))) & " - should be "
                           & integer'image(expected_output(i, j))
                    severity failure;

                report "Got correct result " & integer'image(to_integer(signed(data_out)));

            end loop;

        end loop;

        wait until rising_edge(clk);

        -- Check if result valid signal is set to zero after calculations
        assert data_out_valid = '0'
            report "Result valid should be zero"
            severity failure;

        wait for 50 ns;

        report "Output check is finished."
            severity note;
        finish;

    end process output_check;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

end architecture imp;

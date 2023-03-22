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
        line_length_lb  : positive := 5; --! Length of line buffer
        number_of_lines : positive := 5; --! Number of lines in the test image
        addr_width      : positive := 4; --! Address width for the ram_dp component
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
            clk                : in    std_logic;
            rstn               : in    std_logic;
            i_enable           : in    std_logic;
            i_data             : in    std_logic_vector(data_width - 1 downto 0);
            i_data_valid       : in    std_logic;
            o_data             : out   std_logic_vector(data_width - 1 downto 0);
            o_data_valid       : out   std_logic;
            o_buffer_full      : out   std_logic;
            o_buffer_full_next : out   std_logic;
            i_update_val       : in    std_logic_vector(data_width - 1 downto 0);
            i_update_offset    : in    std_logic_vector(addr_width - 1 downto 0);
            i_read_offset      : in    std_logic_vector(addr_width - 1 downto 0);
            i_command          : in    command_lb_t
        );
    end component;

    signal clk              : std_logic := '1';
    signal clk_2            : std_logic := '1';
    signal rstn             : std_logic;
    signal data_in_valid    : std_logic;
    signal data_in          : std_logic_vector(data_width - 1 downto 0);
    signal data_out         : std_logic_vector(data_width - 1 downto 0);
    signal data_out_valid   : std_logic;
    signal buffer_full      : std_logic;
    signal buffer_full_next : std_logic;
    signal update_val       : std_logic_vector(data_width - 1 downto 0);
    signal update_offset    : std_logic_vector(addr_width - 1 downto 0);
    signal read_offset      : std_logic_vector(addr_width - 1 downto 0);
    signal command          : command_lb_t;
    signal s_x              : integer;
    signal s_y              : integer;
    signal s_done           : boolean;

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

    procedure incr (signal pointer_y : inout integer; signal pointer_x : inout integer) is
    begin

        if pointer_x = line_length - 1 then
            pointer_x <= 0;
            pointer_y <= pointer_y + 1;
        else
            pointer_x <= pointer_x + 1;
        end if;

    end procedure;

begin

    line_buffer_inst : component line_buffer
        generic map (
            line_length => line_length_lb,
            addr_width  => addr_width,
            data_width  => data_width
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            i_enable           => '1',
            i_data             => data_in,
            i_data_valid       => data_in_valid,
            o_data             => data_out,
            o_data_valid       => data_out_valid,
            o_buffer_full      => buffer_full,
            o_buffer_full_next => buffer_full_next,
            i_update_val       => update_val,
            i_update_offset    => update_offset,
            i_read_offset      => read_offset,
            i_command          => command
        );

    p_rstn : process is
    begin

        rstn <= '0';
        wait for 100 ns;
        rstn <= '1';
        wait for 4000 ns;

    end process p_rstn;

    clkgen_2 : process (clk_2) is
    begin

        clk_2 <= not clk_2 after 10 ns;

    end process clkgen_2;

    stimuli_data : process (rstn, clk) is
    begin

        if not rstn then
            data_in       <= (others => '0');
            data_in_valid <= '0';
            s_x           <= 0;
            s_y           <= 0;
            s_done        <= false;
        elsif rising_edge(clk) then
            if s_y = number_of_lines then
                s_done <= true;
            -- data_in_valid <= '0';
            elsif buffer_full = '0' then
                data_in_valid <= '1';
                data_in       <= std_logic_vector(to_signed(test_image(s_y, s_x), data_width));
                incr(s_y,s_x);
            end if;
        end if;

    end process stimuli_data;

    stimuli_commands : process is
    begin

        wait until rstn = '1';
        read_offset <= (others => '0');

        for y in 0 to number_of_lines - 1 loop

            wait until s_x = 5 or buffer_full = '1';

            for x in 0 to line_length - kernel_size loop

                report "Waiting until buffer full";

                /*if buffer_full = '0' then
                    wait until buffer_full = '1';
                end if;*/

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

        wait for 90 ns;

        report "Output check is finished."
            severity note;
        finish;

    end process output_check;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

end architecture imp;

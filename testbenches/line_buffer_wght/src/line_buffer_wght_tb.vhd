library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! Testbench for the line buffer

--! The line_buffer is filled with the weights of a test convolution.
--! The testbench checks if the correct weights appear on the output
--! at the right time.

entity line_buffer_wght_tb is
    generic (
        line_length    : positive := 7;  --! Length of the lines in the test image
        command_length : positive := 16; --! Number of commands in the test
        output_length  : positive := 12; --! Number of outputs expected
        addr_width     : positive := 3;  --! Address width for the ram_dp component
        data_width     : positive := 8;  --! 8 bit data being saved
        kernel_size    : positive := 5   --! 3 pixel kernel
    );
end entity line_buffer_wght_tb;

architecture imp of line_buffer_wght_tb is

    component line_buffer is
        generic (
            line_length : positive := 7;
            addr_width  : positive := 3;
            data_width  : positive := 8
        );
        port (
            clk             : in    std_logic;
            rstn            : in    std_logic;
            i_data          : in    std_logic_vector(data_width - 1 downto 0);
            i_data_valid    : in    std_logic;
            o_data          : out   std_logic_vector(data_width - 1 downto 0);
            o_data_valid    : out   std_logic;
            o_buffer_full   : out   std_logic;
            i_update_val    : in    std_logic_vector(data_width - 1 downto 0);
            i_update_offset : in    std_logic_vector(addr_width - 1 downto 0);
            i_read_offset   : in    std_logic_vector(addr_width - 1 downto 0);
            i_command       : in    command_lb_t
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

    type command_array_t is array(natural range <>) of command_lb_t;

    type integer_t is array(natural range <>) of integer;

    -- test data, simulates the output of classify
    constant command_sequence : command_array_t(0 to command_length - 1) := (
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read, c_lb_read, c_lb_read, c_lb_idle)
    );

    constant read_offset_sequence : integer_t(0 to command_length - 1) := (
        (0,1,2,0,3,4,5,3/*to shrink tree values*/,0,1,2,0,3,4,5,0)
    );

    constant expected_data_out : integer_t(0 to output_length - 1) := (
        (0,1,2,3,4,5,3,4,5,6,7,8)
    );

    constant weight_data : integer_t(0 to command_length - 1) := (
        (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
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
            clk             => clk,
            rstn            => rstn,
            i_data          => data_in,
            i_data_valid    => data_in_valid,
            o_data          => data_out,
            o_data_valid    => data_out_valid,
            o_buffer_full   => buffer_full,
            i_update_val    => update_val,
            i_update_offset => update_offset,
            i_read_offset   => read_offset,
            i_command       => command
        );

    adder : process is
    begin

        wait until rising_edge(clk);
        update_val <= std_logic_vector(to_signed(to_integer(signed(data_out)) + 1, data_width));

    end process adder;

    stimuli_data : process is
    begin

        rstn          <= '0';
        data_in       <= (others => '0');
        data_in_valid <= '0';

        wait for 100 ns;
        rstn          <= '1';
        wait until rising_edge(clk);
        data_in_valid <= '1';

        for y in 0 to command_length - 1 loop

            while buffer_full = '1' loop

                wait until rising_edge(clk);

            end loop;

            data_in <= std_logic_vector(to_signed(weight_data(y), data_width));
            wait until rising_edge(clk);

        end loop;

        wait for 2000 ns;

    end process stimuli_data;

    stimuli_commands : process is
    begin

        wait until rstn = '1';
        read_offset <= (others => '0');

        report "Waiting until buffer full";

        if buffer_full = '0' then
            wait until buffer_full = '1';
        end if;

        wait until rising_edge(clk);

        report "Buffer full, start with commands";

        for y in 0 to command_length - 1 loop

            command     <= command_sequence(y);
            read_offset <= std_logic_vector(to_signed(read_offset_sequence(y), addr_width));
            wait until rising_edge(clk);

        end loop;

    end process stimuli_commands;

    output_check : process is
    begin

        output_loop_lines : for i in 0 to output_length - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if data_out_valid = '0' then
                wait until rising_edge(clk) and data_out_valid = '1';
            end if;

            assert data_out = std_logic_vector(to_signed(expected_data_out(i), data_width))
                report "Output wrong. Result is " & integer'image(to_integer(signed(data_out))) & " - should be "
                       & integer'image(expected_data_out(i))
                severity failure;

            report "Got correct result " & integer'image(to_integer(signed(data_out)));

        end loop;

        wait until rising_edge(clk);

        -- Check if result valid signal is set to zero afterwards
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

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! This testbench can be used to test the line_buffer component.

--! The line_buffer is filled with the pixels of a test image.
--! The testbench checks if the correct pixels appear on the line_buffer output
--! at the right time.

entity line_buffer_psum_tb is
    generic (
        line_length    : positive := 7;  --! Length of the lines in the test image
        command_length : positive := 17; --! Number of commands in the test
        output_length  : positive := 12; --! Number of outputs expected
        addr_width     : positive := 3;  --! Address width for the ram_dp component
        data_width     : positive := 8;  --! 8 bit data being saved
        kernel_size    : positive := 5   --! 3 pixel kernel
    );
end entity line_buffer_psum_tb;

architecture imp of line_buffer_psum_tb is

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

    type command_array_t is array(natural range <>) of command_lb_t;

    type integer_t is array(natural range <>) of integer;

    -- test data, simulates the output of classify
    constant command_sequence : command_array_t(0 to command_length - 1) := (
        (c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update,
         c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update,
         c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update,
         c_lb_idle, c_lb_read , c_lb_read , c_lb_read, c_lb_idle)
    );

    constant read_offset_sequence : integer_t(0 to command_length - 1) := (
        (0,0,0,0,0,1,1,1,0,2,2,2,0,0,1,2,0)
    );

    constant update_offset_sequence : integer_t(0 to command_length - 1) := (
        (0,0,0,0,0,1,1,1,0,2,2,2,0,0,0,0,0)
    );

    -- Kernel 5 px
    constant expected_data_out : integer_t(0 to output_length - 1) := (
        (0,1,2,0,1,2,0,1,2,3,3,3)
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

        -- Fill buffer with zeros
        while buffer_full = '0' loop

            data_in <= std_logic_vector(to_signed(0, data_width));
            wait until rising_edge(clk);

        end loop;

        for y in 0 to line_length - 1 loop

            while buffer_full = '1' loop

                wait until rising_edge(clk);

            end loop;

            data_in <= std_logic_vector(to_signed(0, data_width));
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

            command       <= command_sequence(y);
            read_offset   <= std_logic_vector(to_signed(read_offset_sequence(y), addr_width));
            update_offset <= std_logic_vector(to_signed(update_offset_sequence(y), addr_width));
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

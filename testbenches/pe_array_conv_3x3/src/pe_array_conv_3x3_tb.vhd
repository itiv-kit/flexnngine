library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! Testbench to perform a 3x3 convolution on a 5x5 input image

--! The image as well as commands are fed into the pe_array
--! Convolution outputs are validated

entity pe_array_conv_3x3_tb is
    generic (
        size_x    : positive := 3;
        size_y    : positive := 3;
        size_rows : positive := 5;

        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 5;
        addr_width_iact  : positive := 3;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 7;
        addr_width_psum  : positive := 4;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 7;
        addr_width_wght  : positive := 3;

        image_x : positive := 5; --! size of input image
        image_y : positive := 5; --! size of input image

        output_length : positive := 12; --! Number of outputs expected

        command_length        : positive := 13;
        output_command_length : positive := 10;

        kernel_size : positive := 3 --! 3 pixel kernel
    );
end entity pe_array_conv_3x3_tb;

architecture imp of pe_array_conv_3x3_tb is

    component pe_array is
        generic (
            size_x : positive := 3;
            size_y : positive := 3;

            size_rows : positive := 5;

            data_width_iact  : positive := 8;
            line_length_iact : positive := 32;
            addr_width_iact  : positive := 5;

            data_width_psum  : positive := 16;
            line_length_psum : positive := 2048;
            addr_width_psum  : positive := 11;

            data_width_wght  : positive := 8;
            line_length_wght : positive := 32;
            addr_width_wght  : positive := 5
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_preload_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);
            i_preload_psum_valid : in    std_logic;

            command      : in    command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_iact : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_psum : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_wght : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

            i_data_iact : in    array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
            i_data_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
            i_data_wght : in    array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

            i_data_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
            i_data_psum_valid : in    std_logic;
            i_data_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

            o_buffer_full_iact : out   std_logic_vector(size_rows - 1 downto 0);
            o_buffer_full_psum : out   std_logic;
            o_buffer_full_wght : out   std_logic_vector(size_y - 1 downto 0);

            o_buffer_full_next_iact : out   std_logic_vector(size_rows - 1 downto 0);
            o_buffer_full_next_psum : out   std_logic;
            o_buffer_full_next_wght : out   std_logic_vector(size_y - 1 downto 0);

            update_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            update_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            update_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            read_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            read_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            read_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            o_psums       : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
            o_psums_valid : out   std_logic_vector(size_x - 1 downto 0)
        );
    end component pe_array;

    signal clk  : std_logic := '1';
    signal rstn : std_logic;

    signal i_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_preload_psum_valid : std_logic;

    signal command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal i_data_iact : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_psum : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_data_wght : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

    signal i_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_psum_valid : std_logic;
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal o_buffer_full_iact : std_logic_vector(size_rows - 1 downto 0);
    signal o_buffer_full_psum : std_logic;
    signal o_buffer_full_wght : std_logic_vector(size_y - 1 downto 0);

    signal o_buffer_full_next_iact : std_logic_vector(size_rows - 1 downto 0);
    signal o_buffer_full_next_psum : std_logic;
    signal o_buffer_full_next_wght : std_logic_vector(size_y - 1 downto 0);

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
    signal s_done : boolean;

    -- INPUT IMAGE, FILTER WEIGTHS AND EXPECTED OUTPUT

    constant input_image : int_image_t(0 to image_y - 1, 0 to image_x - 1) := (
        (1,2,3,4,5),
        (6,7,8,9,10),
        (11,12,13,14,15),
        (16,17,18,19,20),
        (21,22,23,24,25)
    );

    constant input_weights : int_image_t(0 to size_y - 1, 0 to size_x - 1) := (
        (1,2,1),
        (2,3,2),
        (3,4,3)
    );

    constant expected_output : int_image_t(0 to image_y - kernel_size, 0 to image_x - kernel_size) := (
        (177,198,219),
        (282,303,324),
        (387,408,429)
    );

    -- COMMANDS FOR PES AND LINE BUFFERS

    constant input_pe_command : command_pe_array_t(0 to command_length - 1) := (
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult)
    );

    constant input_command : command_lb_row_col_t(0 to 2, 0 to command_length - 1) := (
        (c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_idle),                                                          -- iact
        (c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle), -- psum
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle)                                                                 -- wght
    );

    constant input_read_offset : int_image_t(0 to 2, 0 to command_length - 1) := (
        (0,1,2,1,0,1,2,1,0,1,2,1,0), -- iact
        (0,0,0,0,0,1,1,1,0,2,2,2,0), -- psum
        (0,1,2,0,0,1,2,0,0,1,2,0,0)  -- wght
    );

    constant input_update_offset : int_image_t(0 to 2, 0 to command_length - 1) := (
        (0,0,0,0,0,0,0,0,0,0,0,0,0), -- iact
        (0,0,0,0,0,1,1,1,0,2,2,2,0), -- psum
        (0,0,0,0,0,0,0,0,0,0,0,0,0)  -- wght
    );

    constant output_command     : command_lb_row_col_t(0 to 2, 0 to output_command_length - 1) := (
        (c_lb_idle, c_lb_idle, c_lb_idle, c_lb_read_update, c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_idle),                                       -- row 0
        (c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                                  -- row 1
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle,c_lb_idle, c_lb_idle)                                                         -- row 2
    );
    constant output_pe_command  : command_pe_row_col_t(0 to 2, 0 to output_command_length - 1) := (
        (c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum ,c_pe_conv_psum,c_pe_conv_psum), -- row 0
        (c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum),  -- row 1
        (c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum)      -- row 2
    );
    constant output_read_offset : int_image_t(0 to 2, 0 to output_command_length - 1) := (
        (0,0,0,0,1,2,0,1,2,0),                                                                                                                                                -- row 0
        (0,1,2,0,1,2,0,0,0,0),                                                                                                                                                -- row 1
        (0,1,2,0,0,0,0,0,0,0)                                                                                                                                                 -- row 2
    );

    constant output_update_offset : int_image_t(0 to 2, 0 to output_command_length - 1) := (
        (0,0,0,0,1,2,0,0,0,0), -- row 0
        (0,1,2,0,0,0,0,0,0,0), -- row 1
        (0,0,0,0,0,0,0,0,0,0)  -- row 2
    );

    procedure incr (signal pointer_y : inout integer; signal pointer_x : inout integer) is
    begin

        if pointer_x = image_x - 1 then
            pointer_x <= 0;
            pointer_y <= pointer_y + 1;
        else
            pointer_x <= pointer_x + 1;
        end if;

    end procedure;

begin

    pe_array_inst : component pe_array
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
            i_data_iact             => i_data_iact,
            i_data_psum             => i_data_psum,
            i_data_wght             => i_data_wght,
            i_data_iact_valid       => i_data_iact_valid,
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
        wait for 2000 ns;

    end process rstn_gen;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

    stimuli_data_wght : process is
    begin

        i_data_wght       <= (others => (others => '0'));
        i_data_wght_valid <= (others => '0');

        wait until rstn = '1';
        wait until rising_edge(clk);

        i_data_wght_valid <= (others => '1');

        for i in 0 to size_x - 1 loop

            while or o_buffer_full_wght = '1' loop

                wait until rising_edge(clk);

            end loop;

            for y in 0 to size_y - 1 loop

                -- data_in_wght <= std_logic_vector(to_signed(input_wght(i), data_width_iact_wght));
                i_data_wght(y) <= std_logic_vector(to_signed(input_weights(y,i), data_width_wght));

            end loop;

            wait until rising_edge(clk);

        end loop;

        i_data_wght_valid <= (others => '0');

        wait for 2000 ns;

    end process stimuli_data_wght;

    stimuli_data_iact : process (rstn, clk, clk) is
    begin

        if not rstn then
            i_data_iact       <= (others => (others => '0'));
            i_data_iact_valid <= (others => '0');
            s_x               <= 0;
            s_y               <= size_rows - 1;
            s_done            <= false;
        elsif rising_edge(clk) then
            if s_y = image_y then
                s_done <= true;
            -- data_in_valid <= '0';
            elsif or o_buffer_full_iact = '0' then

                for i in 0 to size_rows - 1 loop

                    i_data_iact_valid(i) <= '1';
                    i_data_iact(i)       <= std_logic_vector(to_signed(input_image(i, s_x), data_width_iact));

                end loop;

                incr(s_y,s_x);
            end if;
        end if;

    end process stimuli_data_iact;

    stimuli_data_psum : process is
    begin

        i_data_psum       <= (others => '0');
        i_data_psum_valid <= '0';

        i_preload_psum       <= (others => '0');
        i_preload_psum_valid <= '0';

        wait until rstn = '1';
        wait until rising_edge(clk);

        i_data_psum_valid    <= '1';
        i_preload_psum_valid <= '1';

        for i in 0 to image_x - kernel_size loop

            while o_buffer_full_psum = '1' loop

                wait until rising_edge(clk);

            end loop;

            i_data_psum    <= std_logic_vector(to_signed(0, data_width_psum));
            i_preload_psum <= std_logic_vector(to_signed(0, data_width_psum));
            wait until rising_edge(clk);

        end loop;

        i_data_psum_valid    <= '0';
        i_preload_psum_valid <= '0';

        wait for 2000 ns;

    end process stimuli_data_psum;

    stimuli_commands : process is
    begin

        wait until rstn = '1';
        read_offset_iact <= (others => (others => (others => '0')));
        read_offset_psum <= (others => (others => (others => '0')));
        read_offset_wght <= (others => (others => (others => '0')));

        report "Waiting until first values in buffer";

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        report "Start with calculation of 1-D convolutions ...";

        for i in 0 to command_length - 1 loop

            for y in 0 to size_y - 1 loop

                for x in 0 to size_x - 1 loop

                    command(y,x) <= input_pe_command(i);

                    command_iact(y,x) <= input_command(0,i);
                    command_psum(y,x) <= input_command(1,i);
                    command_wght(y,x) <= input_command(2,i);

                    read_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_read_offset(0,i), addr_width_iact));
                    read_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_read_offset(1,i), addr_width_psum));
                    read_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_read_offset(2,i), addr_width_wght));

                    update_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_update_offset(0,i), addr_width_iact));
                    update_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_update_offset(1,i), addr_width_psum));
                    update_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_update_offset(2,i), addr_width_wght));

                end loop;

            end loop;

            wait until rising_edge(clk);

        end loop;

        wait for 50 ns;
        wait until rising_edge(clk);

        report "Start with partial sum accumulation and output results ...";

        for i in 0 to output_command_length - 1 loop

            for x in 0 to size_x - 1 loop

                command(0,x) <= output_pe_command(0,i);
                command(1,x) <= output_pe_command(1,i);
                command(2,x) <= output_pe_command(2,i);

                command_psum(0,x) <= output_command(0,i);
                command_psum(1,x) <= output_command(1,i);
                command_psum(2,x) <= output_command(2,i);

                read_offset_psum(0,x) <= std_logic_vector(to_unsigned(output_read_offset(0,i), addr_width_psum));
                read_offset_psum(1,x) <= std_logic_vector(to_unsigned(output_read_offset(1,i), addr_width_psum));
                read_offset_psum(2,x) <= std_logic_vector(to_unsigned(output_read_offset(2,i), addr_width_psum));

                update_offset_psum(0,x) <= std_logic_vector(to_unsigned(output_update_offset(0,i), addr_width_psum));
                update_offset_psum(1,x) <= std_logic_vector(to_unsigned(output_update_offset(1,i), addr_width_psum));
                update_offset_psum(2,x) <= std_logic_vector(to_unsigned(output_update_offset(2,i), addr_width_psum));

            end loop;

            wait until rising_edge(clk);

        end loop;

        wait for 50 ns;
        wait until rising_edge(clk);

        wait for 2000 ns;

    end process stimuli_commands;

    output_check : process is
    begin

        report "OUTPUTS -----------------------------------------------------"
            severity note;

        output_loop : for i in 0 to image_x - kernel_size loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if or o_psums_valid = '0' then
                wait until rising_edge(clk) and (or o_psums_valid= '1');
            end if;

            for y in 0 to size_y - 1 loop

                assert o_psums(y) = std_logic_vector(to_signed(expected_output(y,i), data_width_psum))
                    report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(y)))) & " - should be "
                           & integer'image(expected_output(y,i))
                    severity failure;

                report "Got correct result " & integer'image(to_integer(signed(o_psums(y))));

            end loop;

        end loop;

        wait until rising_edge(clk);

        -- Check if result valid signal is set to zero afterwards
        assert (or o_psums_valid = '0')
            report "Result valid should be zero"
            severity failure;

        report "Output check is finished."
            severity note;
        finish;

    end process output_check;

end architecture imp;

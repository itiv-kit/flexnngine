library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! Testbench to perform a 3x3 GEMM on a 3x3 input image

--! The image as well as commands are fed into the pe_array
--! Convolution outputs are validated

entity pe_array_gemm_3x6_tb is
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

        image_x : positive := 6; --! size of input image
        image_y : positive := 3; --! size of input image

        weights_x : positive := 3;
        weights_y : positive := 6;

        command_length        : positive := 8;
        output_command_length : positive := 10
    );
end entity pe_array_gemm_3x6_tb;

architecture imp of pe_array_gemm_3x6_tb is

    signal clk  : std_logic := '1';
    signal rstn : std_logic;

    signal i_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_preload_psum_valid : std_logic;

    signal i_enable     : std_logic := '1';
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
        (1,2,3,4,5,6),
        (7,8,9,10,11,12),
        (13,14,15,16,17,18)
    );

    constant input_weights : int_image_t(0 to weights_y - 1, 0 to weights_x - 1) := (
        (1,7,13),
        (2,8,14),
        (3,9,15),
        (4,10,16),
        (5,11,17),
        (6,12,18)
    );

    constant expected_output : int_image_t(0 to image_y - 1, 0 to weights_x - 1) := (
        (30,36,42),
        (66,81,96),
        (102,126,150)
    );

    -- COMMANDS FOR PES AND LINE BUFFERS

    constant input_pe_command : command_pe_array_t(0 to command_length - 1) := (
        (c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult,c_pe_gemm_mult)
    );

    constant input_command : command_lb_row_col_t(0 to 8, 0 to command_length - 1) := (
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                      -- iact
        (c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                      -- iact
        (c_lb_idle, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle),                      -- iact
        (c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle), -- psum
        (c_lb_idle, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_idle, c_lb_idle), -- psum
        (c_lb_idle, c_lb_idle, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_idle), -- psum
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                      -- wght
        (c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                      -- wght
        (c_lb_idle, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle)                       -- wght
    );

    constant input_read_offset : int_image_t(0 to 8, 0 to command_length - 1) := (
        (0,1,2,0,0,0,0,0), -- iact
        (0,0,1,2,0,0,0,0), -- iact
        (0,0,0,1,2,0,0,0), -- iact
        (0,0,0,0,0,0,0,0), -- psum
        (0,0,0,0,0,0,0,0), -- psum
        (0,0,0,0,0,0,0,0), -- psum
        (0,1,2,0,0,0,0,0), -- wght
        (0,0,1,2,0,0,0,0), -- wght
        (0,0,0,1,2,0,0,0)  -- wght
    );

    constant input_update_offset : int_image_t(0 to 8, 0 to command_length - 1) := (
        (0,0,0,0,0,0,0,0), -- iact
        (0,0,0,0,0,0,0,0), -- iact
        (0,0,0,0,0,0,0,0), -- iact
        (0,0,0,0,0,0,0,0), -- psum
        (0,0,0,0,0,0,0,0), -- psum
        (0,0,0,0,0,0,0,0), -- psum
        (0,0,0,0,0,0,0,0), -- wght
        (0,0,0,0,0,0,0,0), -- wght
        (0,0,0,0,0,0,0,0)  -- wght
    );

    constant output_command     : command_lb_row_col_t(0 to 2, 0 to output_command_length - 1) := (
        (c_lb_idle, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle),                                             -- row 0
        (c_lb_read_update, c_lb_idle, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle),                                                -- row 1
        (c_lb_read, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle, c_lb_idle)                                                        -- row 2
    );
    constant output_pe_command  : command_pe_row_col_t(0 to 2, 0 to output_command_length - 1) := (
        (c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum ,c_pe_conv_psum,c_pe_conv_psum), -- row 0
        (c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum , c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum),  -- row 1
        (c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum, c_pe_conv_psum)      -- row 2
    );
    constant output_read_offset : int_image_t(0 to 2, 0 to output_command_length - 1)          := (
        (0,0,1,2,0,0,1,2,0,0),                                                                                                                                                -- row 0
        (1,0,0,1,0,0,0,0,0,0),                                                                                                                                                -- row 1
        (0,0,0,0,0,0,0,0,0,0)                                                                                                                                                 -- row 2
    );

    constant output_update_offset : int_image_t(0 to 2, 0 to output_command_length - 1) := (
        (0,0,1,2,0,0,0,0,0,0), -- row 0
        (1,0,0,0,0,0,0,0,0,0), -- row 1
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

    end procedure incr;

begin

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
            i_enable                => i_enable,
            i_command               => command,
            i_command_iact          => command_iact,
            i_command_psum          => command_psum,
            i_command_wght          => command_wght,
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

    stimuli_data_wght : process is
    begin

        i_data_wght       <= (others => (others => '0'));
        i_data_wght_valid <= (others => '0');

        wait until rstn = '1';
        wait until rising_edge(clk);

        i_data_wght_valid <= (others => '1');

        for i in 0 to size_x - 1 loop

            while (or o_buffer_full_wght) = '1' loop

                wait until rising_edge(clk);

            end loop;

            for y in 0 to size_y - 1 loop

                -- data_in_wght <= std_logic_vector(to_signed(input_wght(i), data_width_iact_wght));
                i_data_wght(y) <= std_logic_vector(to_signed(input_weights(y,size_x - 1 - i), data_width_wght));

            end loop;

            wait until rising_edge(clk);

        end loop;

        i_data_wght_valid <= (others => '0');

        wait;

    end process stimuli_data_wght;

    stimuli_data_iact : process (rstn, clk) is
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
            else

                for i in size_y - 1 to size_rows - 1 loop

                    if o_buffer_full_iact(i) = '0' then
                        i_data_iact_valid(i) <= '1';
                        i_data_iact(i)       <= std_logic_vector(to_signed(input_image(size_y - 1 - s_x, i - size_y + 1), data_width_iact));
                    end if;

                end loop;

                incr(s_y,s_x);
            end if;
        end if;

    end process stimuli_data_iact;

    /*stimuli_data_psum : process is
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

    end process stimuli_data_psum;*/

    stimuli_commands : process is
    begin

        wait until rstn = '1';

        command <= (others => (others => c_pe_gemm_mult));

        read_offset_iact <= (others => (others => (others => '0')));
        read_offset_psum <= (others => (others => (others => '0')));
        read_offset_wght <= (others => (others => (others => '0')));

        report "Waiting until first values in buffer";

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        report "Start with calculation of 1-D convolutions ...";

        for i in 0 to command_length - 1 loop

            for y in 0 to size_y - 1 loop

                for x in 0 to size_x - 1 loop

                    command(y,x) <= input_pe_command(i);

                    command_iact(y,x) <= input_command(0 + x, i);
                    command_psum(y,x) <= input_command(3 + x, i);
                    command_wght(y,x) <= input_command(6 + x, i);

                    read_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_read_offset(0 + x, i), addr_width_iact));
                    read_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_read_offset(3 + x, i), addr_width_psum));
                    read_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_read_offset(6 + x, i), addr_width_wght));

                    update_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_update_offset(0 + x, i), addr_width_iact));
                    update_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_update_offset(3 + x, i), addr_width_psum));
                    update_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_update_offset(6 + x, i), addr_width_wght));

                end loop;

            end loop;

            wait until rising_edge(clk);

        end loop;

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

        wait;

    end process stimuli_commands;

    output_check : process is
    begin

        report "OUTPUTS -----------------------------------------------------"
            severity note;

        output_loop : for i in 0 to image_x - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if or o_psums_valid = '0' then
                wait until rising_edge(clk) and (or o_psums_valid = '1');
            end if;

            for y in 0 to size_y - 1 loop

                assert o_psums(y) = std_logic_vector(to_signed(expected_output(i,y), data_width_psum))
                    report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(y)))) & " - should be "
                           & integer'image(expected_output(i,y))
                    severity failure;

            -- report "Got correct result " & integer'image(to_integer(signed(o_psums(y))));

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

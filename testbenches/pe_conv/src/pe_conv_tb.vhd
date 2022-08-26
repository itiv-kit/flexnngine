library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;

--! This testbench can be used to test the pe component with a convolution.

--! 1-D convolution with kernel size 3 performed. Program and kernel size can be adjusted
--! Outputs are checked if they match the expected outputs

entity pe_conv_tb is
    generic (
        line_length          : positive := 7;  --! Length of the lines in the test image
        line_length_psum     : positive := 7;  --! Length of psum buffer
        output_length        : positive := 12; --! Number of outputs expected
        command_length       : positive := 21;
        addr_width_iact_wght : positive := 3;  --! Address width for the ram_dp component
        data_width_iact_wght : positive := 8;  --! 8 bit data being saved
        addr_width_psum      : positive := 4;
        data_width_psum      : positive := 16;
        kernel_size          : positive := 3   --! 3 pixel kernel
    );
end entity pe_conv_tb;

architecture imp of pe_conv_tb is

    component pe is
        generic (
            data_width_iact  : positive := 8;
            line_length_iact : positive := 7;
            addr_width_iact  : positive := 3;

            data_width_psum  : positive := 16;
            line_length_psum : positive := 7;
            addr_width_psum  : positive := 4;

            data_width_wght  : positive := 8;
            line_length_wght : positive := 7;
            addr_width_wght  : positive := 3
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            command      : in    command_pe_t;
            command_iact : in    command_lb_t;
            command_psum : in    command_lb_t;
            command_wght : in    command_lb_t;

            data_in_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
            data_in_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
            data_in_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

            data_in_iact_valid : in    std_logic;
            data_in_psum_valid : in    std_logic;
            data_in_wght_valid : in    std_logic;

            buffer_full_iact : out   std_logic;
            buffer_full_psum : out   std_logic;
            buffer_full_wght : out   std_logic;

            update_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
            update_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
            update_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

            read_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
            read_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
            read_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

            data_out       : out   std_logic_vector(data_width_psum - 1 downto 0);
            data_out_valid : out   std_logic
        );
    end component pe;

    -- Testbench signals

    signal clk  : std_logic := '1';
    signal rstn : std_logic;

    signal command      : command_pe_t;
    signal command_iact : command_lb_t;
    signal command_psum : command_lb_t;
    signal command_wght : command_lb_t;

    signal data_in_iact : std_logic_vector(data_width_iact_wght - 1 downto 0);
    signal data_in_wght : std_logic_vector(data_width_iact_wght - 1 downto 0);
    signal data_in_psum : std_logic_vector(data_width_psum - 1 downto 0);

    signal data_in_iact_valid : std_logic;
    signal data_in_psum_valid : std_logic;
    signal data_in_wght_valid : std_logic;

    signal buffer_full_iact : std_logic;
    signal buffer_full_psum : std_logic;
    signal buffer_full_wght : std_logic;

    signal update_offset_iact : std_logic_vector(addr_width_iact_wght - 1 downto 0);
    signal update_offset_psum : std_logic_vector(addr_width_psum - 1 downto 0);
    signal update_offset_wght : std_logic_vector(addr_width_iact_wght - 1 downto 0);

    signal read_offset_iact : std_logic_vector(addr_width_iact_wght - 1 downto 0);
    signal read_offset_psum : std_logic_vector(addr_width_psum - 1 downto 0);
    signal read_offset_wght : std_logic_vector(addr_width_iact_wght - 1 downto 0);

    signal data_out       : std_logic_vector(data_width_psum - 1 downto 0);
    signal data_out_valid : std_logic;

    -- Test data

    -- type command_t is (c_idle, c_read, c_read_update, c_shrink);

    type command_array_lb_t is array(natural range <>, natural range <>) of command_lb_t;

    type command_array_pe_t is array(natural range <>) of command_pe_t;

    type offset_array_t is array(natural range <>, natural range <>) of integer;

    type integer_t is array(natural range <>) of integer;

    constant input_iact : integer_t(0 to line_length - 1) := (
        (0,1,2,3,4,5,6)
    );

    constant input_wght : integer_t(0 to kernel_size - 1) := (
        (1,2,1)
    );

    constant expected_psums : integer_t(0 to (line_length - kernel_size + 1) * kernel_size - 1) := (
        --( 0,2,4,1,5,8,2,8,12,3,11,16,4,14,20)
        (0,0,2,0,1,5,0,2,8,0,3,11,0,4,14)
    );

    constant expected_output : integer_t(0 to line_length - kernel_size) := (
        (4,8,12,16,20)
    );

    constant output_idx : integer_t(0 to line_length - kernel_size) := (
        (0,1,2,3,4)
    );

    constant input_pe_command : command_array_pe_t(0 to command_length - 1) := (
        (c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac,c_pe_mux_mac)
    );

    constant input_command : command_array_lb_t(0 to 2, 0 to command_length - 1) := (
        (c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_read, c_lb_read, c_lb_read, c_lb_shrink, c_lb_idle),                                                                                                -- iact
        (c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle, c_lb_read_update, c_lb_read_update, c_lb_read_update, c_lb_idle), -- psum
        (c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_read, c_lb_read, c_lb_read, c_lb_idle, c_lb_idle)                                                                                                           -- wght
    );

    constant input_read_offset : offset_array_t(0 to 2, 0 to command_length - 1) := (
        (0,1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,0), -- iact
        (0,0,0,0,0,1,1,1,0,2,2,2,0,3,3,3,0,4,4,4,0), -- psum
        (0,1,2,0,0,1,2,0,0,1,2,0,0,1,2,0,0,1,2,0,0)  -- wght
    );

    constant input_update_offset : offset_array_t(0 to 2, 0 to command_length - 1) := (
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- iact
        (0,0,0,0,0,1,1,1,0,2,2,2,0,3,3,3,0,4,4,4,0), -- psum
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)  -- wght
    );

begin

    pe_inst : component pe
        generic map (
            data_width_iact  => 8,
            line_length_iact => 7,
            addr_width_iact  => 3,

            data_width_psum  => 16,
            line_length_psum => line_length_psum,
            addr_width_psum  => 4,

            data_width_wght  => 8,
            line_length_wght => 7,
            addr_width_wght  => 3
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            command            => command,
            command_iact       => command_iact,
            command_psum       => command_psum,
            command_wght       => command_wght,
            data_in_iact       => data_in_iact,
            data_in_psum       => data_in_psum,
            data_in_wght       => data_in_wght,
            data_in_iact_valid => data_in_iact_valid,
            data_in_psum_valid => data_in_psum_valid,
            data_in_wght_valid => data_in_wght_valid,
            buffer_full_iact   => buffer_full_iact,
            buffer_full_psum   => buffer_full_psum,
            buffer_full_wght   => buffer_full_wght,
            update_offset_iact => update_offset_iact,
            update_offset_psum => update_offset_psum,
            update_offset_wght => update_offset_wght,
            read_offset_iact   => read_offset_iact,
            read_offset_psum   => read_offset_psum,
            read_offset_wght   => read_offset_wght,
            data_out           => data_out,
            data_out_valid     => data_out_valid
        );

    rstn_gen : process is
    begin

        rstn <= '0';
        wait for 100 ns;
        rstn <= '1';
        wait for 2000 ns;

    end process rstn_gen;

    stimuli_data_wght : process is
    begin

        data_in_wght       <= (others => '0');
        data_in_wght_valid <= '0';

        wait until rstn = '1';
        wait until rising_edge(clk);

        data_in_wght_valid <= '1';

        for y in 0 to input_wght'length - 1 loop

            while buffer_full_wght = '1' loop

                wait until rising_edge(clk);

            end loop;

            data_in_wght <= std_logic_vector(to_signed(input_wght(y), data_width_iact_wght));
            wait until rising_edge(clk);

        end loop;

        data_in_wght_valid <= '0';

        wait for 2000 ns;

    end process stimuli_data_wght;

    stimuli_data_iact : process is
    begin

        data_in_iact       <= (others => '0');
        data_in_iact_valid <= '0';

        wait until rstn = '1';
        wait until rising_edge(clk);

        data_in_iact_valid <= '1';

        for y in 0 to input_iact'length - 1 loop

            while buffer_full_iact = '1' loop

                wait until rising_edge(clk);

            end loop;

            data_in_iact <= std_logic_vector(to_signed(input_iact(y), data_width_iact_wght));
            wait until rising_edge(clk);

        end loop;

        data_in_iact_valid <= '0';

        wait for 2000 ns;

    end process stimuli_data_iact;

    stimuli_data_psum : process is
    begin

        data_in_psum       <= (others => '0');
        data_in_psum_valid <= '0';

        wait until rstn = '1';
        wait until rising_edge(clk);

        data_in_psum_valid <= '1';

        for y in 0 to line_length_psum - 1 loop

            while buffer_full_iact = '1' loop

                wait until rising_edge(clk);

            end loop;

            data_in_psum <= std_logic_vector(to_signed(0, data_width_psum));
            wait until rising_edge(clk);

        end loop;

        data_in_psum_valid <= '0';

        wait for 2000 ns;

    end process stimuli_data_psum;

    stimuli_commands : process is
    begin

        wait until rstn = '1';
        read_offset_iact <= (others => '0');
        read_offset_psum <= (others => '0');
        read_offset_wght <= (others => '0');

        report "Waiting until first values in buffer";

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        report "Start with commands...";

        for y in 0 to command_length - 1 loop

            command <= input_pe_command(y);

            command_iact <= input_command(0,y);
            command_psum <= input_command(1,y);
            command_wght <= input_command(2,y);

            read_offset_iact <= std_logic_vector(to_unsigned(input_read_offset(0,y), addr_width_iact_wght));
            read_offset_psum <= std_logic_vector(to_unsigned(input_read_offset(1,y), addr_width_psum));
            read_offset_wght <= std_logic_vector(to_unsigned(input_read_offset(2,y), addr_width_iact_wght));

            update_offset_iact <= std_logic_vector(to_unsigned(input_update_offset(0,y), addr_width_iact_wght));
            update_offset_psum <= std_logic_vector(to_unsigned(input_update_offset(1,y), addr_width_psum));
            update_offset_wght <= std_logic_vector(to_unsigned(input_update_offset(2,y), addr_width_iact_wght));
            wait until rising_edge(clk);

        end loop;

        wait for 50 ns;
        wait until rising_edge(clk);

        get_outputs : for i in 0 to expected_output'length - 1 loop

            command          <= c_pe_mux_psum;
            command_psum     <= c_lb_read;
            read_offset_psum <= std_logic_vector(to_unsigned(output_idx(i), addr_width_psum));
            wait until rising_edge(clk);

        end loop;

        command_psum <= c_lb_idle;

        wait for 2000 ns;

    end process stimuli_commands;

    output_check : process is
    begin

        -- Output from read/update disabled, no PSUM output.

        /*report "PSUMS -----------------------------------------------------"
            severity note;

        psums_loop : for i in 0 to expected_psums'length - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if data_out_valid = '0' then
                wait until rising_edge(clk) and data_out_valid = '1';
            end if;

            assert data_out = std_logic_vector(to_signed(expected_psums(i), data_width_psum))
                report "Output wrong. Result is " & integer'image(to_integer(signed(data_out))) & " - should be "
                       & integer'image(expected_psums(i))
                severity failure;

            report "Got correct result " & integer'image(to_integer(signed(data_out)));

        end loop;*/

        report "OUTPUTS -----------------------------------------------------"
            severity note;

        output_loop : for i in 0 to expected_output'length - 1 loop

            wait until rising_edge(clk);

            -- If result is not valid, wait until next rising edge with valid results.
            if data_out_valid = '0' then
                wait until rising_edge(clk) and data_out_valid = '1';
            end if;

            assert data_out = std_logic_vector(to_signed(expected_output(i), data_width_psum))
                report "Output wrong. Result is " & integer'image(to_integer(signed(data_out))) & " - should be "
                       & integer'image(expected_output(i))
                severity failure;

            report "Got correct result " & integer'image(to_integer(signed(data_out)));

        end loop;

        wait until rising_edge(clk);

        -- Check if result valid signal is set to zero afterwards
        assert data_out_valid = '0'
            report "Result valid should be zero"
            severity failure;

        report "Output check is finished."
            severity note;
        finish;

    end process output_check;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

end architecture imp;

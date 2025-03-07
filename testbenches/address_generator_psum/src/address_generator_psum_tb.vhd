library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;

library accel;
    use accel.utilities.all;

--! Testbench for the psum address generator

entity address_generator_psum_tb is
    generic (
        image_width  : positive := 9;  --! output image width & height
        size_y       : positive := 10; --! accelerator height
        size_x       : positive := 7;  --! accelerator width
        size_x_width : positive := 3;  --! width for accelerator with indexing
        addr_width   : positive := 16; --! memory address width
        data_width   : positive := 16; --! psum data width
        kernel_size  : positive := 3;  --! r/s, kernel size
        kernel_count : positive := 3   --! m0, number of mapped kernels
    );
end entity address_generator_psum_tb;

architecture imp of address_generator_psum_tb is

    signal clk  : std_logic := '1';
    signal rstn : std_logic := '0';
    signal done : boolean   := false;

    signal i_start             : std_logic;
    signal i_dataflow          : std_logic;
    signal i_valid_psum_out    : std_logic_vector(size_x - 1 downto 0);
    signal i_gnt_psum_binary_d : std_logic_vector(size_x_width - 1 downto 0);
    signal i_empty_psum_fifo   : std_logic_vector(size_x - 1 downto 0);
    signal o_address_psum      : std_logic_vector(addr_width - 1 downto 0);
    signal o_suppress_out      : std_logic;

    signal i_gnt_psum_binary_d_int : integer;

    signal tb_wen : std_logic                                 := '0';
    signal wen    : std_logic                                 := '0';
    signal din    : std_logic_vector(data_width - 1 downto 0) := (others => '0');

    signal i_params : parameters_t := (
                                        kernel_size => kernel_size,
                                        w1 => image_width,
                                        m0 => kernel_count,
                                        others => 0
                                    );

    type ram_type is array (0 to 2 ** addr_width - 1) of std_logic_vector(data_width - 1 downto 0);

begin

    dut : entity accel.address_generator_psum
        generic map (
            size_x          => size_x,
            size_y          => size_y,
            addr_width_x    => size_x_width,
            addr_width_psum => addr_width
        )
        port map (
            clk                 => clk,
            rstn                => rstn,
            i_start             => i_start,
            i_dataflow          => i_dataflow,
            i_params            => i_params,
            i_valid_psum_out    => i_valid_psum_out,
            i_gnt_psum_binary_d => i_gnt_psum_binary_d,
            i_empty_psum_fifo   => i_empty_psum_fifo,
            o_address_psum      => o_address_psum,
            o_suppress_out      => o_suppress_out
        );

    mem : entity accel.ram_dp
        generic map (
            addr_width => addr_width,
            data_width => data_width
        )
        port map (
            clk   => clk,
            wena  => wen,
            wenb  => '0',
            addra => o_address_psum,
            addrb => (others => '0'),
            dina  => din,
            dinb  => (others => '0'),
            douta => open,
            doutb => open
        );

    wen                 <= tb_wen and not o_suppress_out;
    i_gnt_psum_binary_d <= std_logic_vector(to_unsigned(i_gnt_psum_binary_d_int, size_x_width));

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rstn : process is
    begin

        wait for 50 ns;
        wait until rising_edge(clk);
        rstn <= '1';
        wait;

    end process gen_rstn;

    gen_inputs : process is
    begin

        i_start           <= '0';
        i_empty_psum_fifo <= (others => '1');

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        wait for 150 ns;

        wait until rising_edge(clk);
        i_start <= '1';

        wait until done;

    end process gen_inputs;

    gen_output_data : process is

        variable start_row   : integer;
        variable current_row : integer;

    begin

        tb_wen                  <= '0';
        i_gnt_psum_binary_d_int <= 0;
        i_valid_psum_out        <= (others => '0');

        for count_dataflow in 0 to 1 loop

            done       <= false;
            i_dataflow <= '1' when count_dataflow = 1 else '0';

            wait until rstn = '1' and i_start = '1';

            wait for 150 ns;

            for step in 0 to (image_width + size_x - 1) / size_x loop

                wait for 150 ns;
                wait until rising_edge(clk);

                for m0 in 0 to kernel_count - 1 loop

                    if i_dataflow = '1' then
                        start_row := 0;
                    else
                        start_row := m0 * kernel_size;
                    end if;

                    for img_x in 0 to image_width - 1 loop

                        for pe_x in 0 to size_x - 1 loop

                            wait until rising_edge(clk);
                            tb_wen      <= '1';
                            current_row := (step * size_x + start_row + pe_x) mod (image_width + kernel_size - 1);
                            -- dummy output data is generated as 1..x for each row, up to x*x. channels are + 1000 each
                            din                     <= std_logic_vector(to_unsigned(current_row * image_width + img_x + 1000 * m0 + 10000 * count_dataflow + 1, data_width));
                            i_gnt_psum_binary_d_int <= pe_x;
                            i_valid_psum_out        <= (others => '0');
                            i_valid_psum_out(pe_x)  <= '1';

                        end loop;

                        -- one cycle delay for after each burst
                        wait until rising_edge(clk);
                        tb_wen                  <= '0';
                        i_gnt_psum_binary_d_int <= 0;
                        i_valid_psum_out        <= (others => '0');

                    end loop;

                end loop;

            end loop;

            done <= true;
            wait until rising_edge(clk);

        end loop;

        finish;

    end process gen_output_data;

    output_check : process is

        variable idx    : integer;
        variable expect : integer;
        variable ram    : ram_type;

    begin

        wait until done;

        ram := << variable mem.ram_instance : ram_type >>;

        for kernel in 0 to kernel_count - 1 loop

            for pixel in 0 to image_width * image_width - 1 loop

                idx    := kernel * image_width * image_width + pixel;
                expect := 1000 * kernel + pixel + 1;

                if i_dataflow = '1' then
                    expect := expect + 10000;
                end if;

                assert to_integer(unsigned(ram(idx))) = expect
                    report "Output wrong. Expected " & integer'image(expect) & " at address "
                           & integer'image(idx)
                    severity failure;

            -- report "Correct pixel " & integer'image(expect) & " at address " & integer'image(idx);

            end loop;

        end loop;

        report "Output is correct for dataflow " & std_logic'image(i_dataflow)
            severity note;

    end process output_check;

end architecture imp;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use std.env.finish;
    use std.env.stop;

library accel;
    use accel.utilities.all;

--! Testbench for the psum address generator

entity address_generator_psum_tb is
    generic (
        image_height : positive := 9;  --! output image height
        image_width  : positive := 9;  --! output image width
        size_y       : positive := 10; --! accelerator height
        size_x       : positive := 7;  --! accelerator width
        addr_width   : positive := 15; --! memory address width
        data_width   : positive := 16; --! psum data width
        kernel_size  : positive := 3;  --! r/s, kernel size
        kernel_count : positive := 3;  --! m0, number of mapped kernels
        write_size   : positive := 1   --! number of data_width words per write (> 1 not supported in testbench yet!)
    );
end entity address_generator_psum_tb;

architecture imp of address_generator_psum_tb is

    constant mem_width : integer := data_width * write_size;

    signal clk  : std_logic := '1';
    signal rstn : std_logic := '0';
    signal done : boolean   := false;

    signal i_start          : std_logic;
    signal i_dataflow       : std_logic;
    signal i_valid_psum_out : std_logic_vector(size_x - 1 downto 0);
    signal o_address_psum   : array_t(0 to size_x - 1)(addr_width - 1 downto 0);
    signal o_suppress_out   : std_logic_vector(size_x - 1 downto 0);

    signal tb_wen : std_logic                                := '0';
    signal wen    : std_logic                                := '0';
    signal din    : std_logic_vector(mem_width - 1 downto 0) := (others => '0');
    signal addr   : std_logic_vector(addr_width - 1 downto 0);
    signal gnt    : natural                                  := 0;

    signal i_params : parameters_t := (
                                        kernel_size => kernel_size,
                                        w1 => image_width,
                                        m0 => kernel_count,
                                        h2 => (image_width + size_x - 1) / size_x,
                                        requant_enab => true,
                                        mode_act => passthrough,
                                        bias => (others => 0),
                                        zeropt_fp32 => (others => (others => '0')),
                                        scale_fp32 => (others => (others => '0')),
                                        base_psum => 0,
                                        stride_psum_och => integer(ceil(real(image_height * image_width) / real(write_size))),
                                        others => 0
                                    );

    type ram_type is array (0 to 2 ** addr_width - 1) of std_logic_vector(mem_width - 1 downto 0);

begin

    dut : entity accel.address_generator_psum
        generic map (
            size_x         => size_x,
            size_y         => size_y,
            mem_addr_width => addr_width,
            mem_columns    => write_size,
            write_size     => write_size
        )
        port map (
            clk              => clk,
            rstn             => rstn,
            i_start          => i_start,
            i_dataflow       => i_dataflow,
            i_params         => i_params,
            i_valid_psum_out => i_valid_psum_out,
            o_address_psum   => o_address_psum,
            o_suppress_out   => o_suppress_out
        );

    mem : entity accel.ram_dp
        generic map (
            addr_width => addr_width,
            data_width => mem_width
        )
        port map (
            clk   => clk,
            wena  => wen,
            wenb  => '0',
            addra => addr,
            addrb => (others => '0'),
            dina  => din,
            dinb  => (others => '0'),
            douta => open,
            doutb => open
        );

    addr <= o_address_psum(gnt);
    wen  <= tb_wen and not o_suppress_out(gnt);

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

        i_start <= '0';

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

        tb_wen           <= '0';
        i_valid_psum_out <= (others => '0');

        for count_dataflow in 0 to 1 loop

            done       <= false;
            i_dataflow <= '1' when count_dataflow = 1 else '0';

            wait until rstn = '1' and i_start = '1';

            wait for 150 ns;

            for step in 0 to i_params.h2 - 1 loop

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
                            current_row := (step * size_x + start_row + pe_x) mod (image_height + kernel_size - 1);
                            -- dummy output data is generated as 1..x for each row, up to x*x. channels are + 1000 each
                            din(data_width - 1 downto 0) <= std_logic_vector(to_unsigned(current_row * image_width + img_x + 1000 * m0 + 10000 * count_dataflow + 1, data_width));
                            gnt                          <= pe_x;
                            i_valid_psum_out             <= (others => '0');
                            i_valid_psum_out(pe_x)       <= '1';

                        end loop;

                        -- one cycle delay for after each burst
                        wait until rising_edge(clk);
                        tb_wen           <= '0';
                        i_valid_psum_out <= (others => '0');

                    end loop;

                end loop;

            end loop;

            -- make sure the address generator stops when all addresses are generated
            wait for 200 ns;

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

            for pixel in 0 to image_height * image_width - 1 loop

                idx    := kernel * image_height * image_width + pixel;
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

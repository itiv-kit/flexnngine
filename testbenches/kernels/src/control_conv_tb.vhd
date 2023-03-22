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
    use ieee.math_real.floor;
    use ieee.math_real.log2;
    use std.textio.all;

entity control_conv_tb is
    generic (
        size_x    : positive := 7;
        size_y    : positive := 10;
        size_rows : positive := size_x + size_y - 1;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 4;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8;  -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 32; /* TODO check influence on tiling - does not work for length 32, kernel 4 and channels 10. Does not work for length 30, kernel 3 and channels 10*/
        addr_width_iact     : positive := 5;
        addr_width_iact_mem : positive := 16;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 128;
        addr_width_psum     : positive := 7;
        addr_width_psum_mem : positive := 16;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 32; /* TODO check influence on tiling - does not work for length 32, kernel 4 and channels 10. Does not work for length 30, kernel 3 and channels 10*/
        addr_width_wght     : positive := 5;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_channels    : positive := 8;
        g_image_y     : positive := 16;
        g_image_x     : positive := 16;
        g_kernel_size : positive := 5;

        g_iact_fifo_size : positive := 15;
        g_wght_fifo_size : positive := 15;
        g_psum_fifo_size : positive := 128;

        g_clk    : time := 10000 ps; -- ps
        g_clk_sp : time := 1000 ps;  -- ps

        g_files_dir : string  := "test/image_size_16_kernel_size_5_c_8/";
        g_init_sp   : boolean := true;

        -- g_h2 : positive := positive(integer(ceil(real(g_image_x - g_kernel_size + 1) / real(size_x)))); -- Y tiles, determined in control module, but for input data loading required here
        g_h2 : positive := positive(integer(ceil(real(g_image_x) / real(size_x)))); -- Y tiles, determined in control module, but for input data loading required here
        g_m0 : positive := positive(integer(floor(real(size_y) / real(g_kernel_size))))
    );
end entity control_conv_tb;

architecture imp of control_conv_tb is

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

    signal start_adr : std_logic;
    signal w_h2      : integer;
    signal w_m0      : integer;

    type ram_type is array (0 to 2 ** addr_width_psum_mem - 1) of std_logic_vector(data_width_psum - 1 downto 0);

    signal psum_ram_instance : ram_type;

    type t_state is (s_calculate, s_output, s_incr_c1);

    signal r_state : t_state;

begin

    o_psums           <= << signal accelerator_inst.w_psums : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0)>>;
    o_psums_valid     <= << signal accelerator_inst.w_psums_valid : std_logic_vector(size_x - 1 downto 0)>>;
    i_data_iact       <= << signal accelerator_inst.w_data_iact : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0)>>;
    i_data_iact_valid <= << signal accelerator_inst.w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0)>>;
    i_data_wght       <= << signal accelerator_inst.w_data_wght : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0)>>;
    i_data_wght_valid <= << signal accelerator_inst.w_data_wght_valid : std_logic_vector(size_y - 1 downto 0)>>;
    -- psum_ram_instance := << shared variable accelerator_inst.scratchpad_inst.ram_dp_psum.ram_instance : ram_type>>;

    psum_ram_instance <= << signal accelerator_inst.scratchpad_init_inst.scratchpad_inst.ram_dp_psum.r_ram_instance : ram_type >>;

    w_h2      <= << signal accelerator_inst.w_h2 : integer range 0 to 1023>>;
    w_m0      <= << signal accelerator_inst.w_m0 : integer range 0 to 1023>>;
    start_adr <= << signal accelerator_inst.address_generator_inst.i_start : std_logic>>;
    r_state   <= << signal accelerator_inst.control_inst.r_state : t_state>>;

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
            g_iact_fifo_size    => g_iact_fifo_size,
            g_wght_fifo_size    => g_wght_fifo_size,
            g_psum_fifo_size    => g_psum_fifo_size,
            g_channels          => g_channels,
            g_image_y           => g_image_y,
            g_image_x           => g_image_x,
            g_kernel_size       => g_kernel_size,
            g_files_dir         => g_files_dir,
            g_init_sp           => g_init_sp
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

        clk <= not clk after g_clk;

    end process clk_gen;

    clk_sp_gen : process (clk_sp) is
    begin

        clk_sp <= not clk_sp after g_clk_sp;

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

        s_input_image <= read_file(file_name => g_files_dir & "_image_reordered_2.txt", num_col => g_image_x * g_channels * g_h2, num_row => size_rows);
        -- s_input_weights   <= read_file(file_name => "src/_kernel_reordered.txt", num_col => g_kernel_size * g_channels * g_tiles_y, num_row => g_kernel_size);
        s_expected_output <= read_file(file_name => g_files_dir & "_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;

    p_check_img : for y in 0 to size_rows - 1 generate

        p_check_image_vals : process is
        begin

            for i in 0 to g_image_x * g_channels * g_h2 - 1 loop

                wait until rising_edge(clk) and i_data_iact_valid(y) = '1';

                if i_data_iact(y) /= std_logic_vector(to_signed(s_input_image(y, i), data_width_iact)) then
                    assert i_data_iact(y) = std_logic_vector(to_signed(s_input_image(y, i), data_width_iact))
                        report "Input iact " & integer'image(i) & " wrong. Iact is " & integer'image(to_integer(signed(i_data_iact(y)))) & " - should be "
                               & integer'image(s_input_image(y, i))
                        severity warning;
                else
                -- report "Got correct iact " & integer'image(to_integer(signed(i_data_iact(y)))) & " (" & integer'image(i) & ")";
                end if;

            end loop;

            while true loop

                assert i_data_iact_valid(y) = '0'
                    report "Input data iact should not be valid!"
                    severity warning;

                wait until i_data_iact_valid(y)'event;

            end loop;

        end process p_check_image_vals;

    end generate p_check_img;

    /*p_check_wght : for y in 0 to size_y - 1 generate

        p_check_wght_vals : process is
        begin

            for i in 0 to g_kernel_size * g_channels * g_tiles_y - 1 loop

                wait until rising_edge(clk) and i_data_wght_valid(y) = '1';

                assert i_data_wght(y) = std_logic_vector(to_signed(s_input_weights(y, i), data_width_wght))
                    report "Input wght (" & integer'image(y) & ") wrong. Wght is " & integer'image(to_integer(signed(i_data_wght(y)))) & " - should be "
                           & integer'image(s_input_weights(y, i))
                    severity warning;

                report "Got correct (" & integer'image(y) & ") wght " & integer'image(to_integer(signed(i_data_wght(y))));

            end loop;

            while true loop

                assert i_data_wght_valid(y) = '0'
                    report "Input data wght should not be valid!"
                    severity warning;

                wait until i_data_wght_valid(y)'event;

            end loop;

        end process p_check_wght_vals;

    end generate p_check_wght;*/

    write_outputs : process is

        file     outfile : text open write_mode is g_files_dir & "_output.txt";
        variable row     : line;

    begin

        wait until r_state = s_output;

        output_while : while true loop

            output_for : for j in 0 to w_m0 * w_h2 * (g_image_x - g_kernel_size + 1) loop

                wait for 100 ns;

                if r_state /= s_output then
                    exit output_for;
                end if;

            end loop output_for;

            if r_state = s_output then
                exit output_while;
            end if;

        end loop output_while;

        wait for 2000 ns;

        for i in 0 to 2 ** addr_width_psum_mem - 1 loop

            write(row, integer'image(to_integer(signed(psum_ram_instance(i)))));
            writeline(outfile, row);

        end loop;

        report "Writing outputs is finished."
            severity note;
        finish;

        wait;

    end process write_outputs;

end architecture imp;

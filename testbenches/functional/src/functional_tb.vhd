library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.ceil;
    use ieee.math_real.floor;
    use std.env.finish;
    use std.env.stop;
    use ieee.math_real.log2;
    use std.textio.all;

library accel;
    use accel.utilities.all;
    use accel.control;
    use accel.pe_array;
    use accel.address_generator;

entity functional_tb is
    generic (
        size_x    : positive := 7;
        size_y    : positive := 10;
        size_rows : positive := size_x + size_y - 1;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 4;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8;  -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 64; /* TODO check influence on tiling - does not work for length 32, kernel 4 and channels 10. Does not work for length 30, kernel 3 and channels 10*/
        addr_width_iact     : positive := 6;
        addr_width_iact_mem : positive := 16;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 128;
        addr_width_psum     : positive := 7;
        addr_width_psum_mem : positive := 16;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 64; /* TODO check influence on tiling - does not work for length 32, kernel 4 and channels 10. Does not work for length 30, kernel 3 and channels 10*/
        addr_width_wght     : positive := 6;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_channels    : positive := 30;
        g_kernels     : positive := 10;
        g_image_y     : positive := 20;
        g_image_x     : positive := 20;
        g_kernel_size : positive := 1;

        g_iact_fifo_size : positive := 15;
        g_wght_fifo_size : positive := 15;
        g_psum_fifo_size : positive := 128;

        g_clk    : time := 10 ns;
        g_clk_sp : time := 2 ns;

        g_files_dir : string  := "./";
        g_init_sp   : boolean := true;

        g_control_init : boolean  := false;
        g_c1           : positive := 1;
        g_w1           : positive := 1;
        g_h2           : positive := 1;
        g_m0           : positive := 1;
        g_m0_last_m1   : positive := 1;
        g_rows_last_h2 : positive := 1;
        g_c0           : positive := 1;
        g_c0_last_c1   : positive := 1;
        g_c0w0         : positive := 1;
        g_c0w0_last_c1 : positive := 1;
        g_dataflow     : integer  := 1
    );
end entity functional_tb;

architecture imp of functional_tb is

    signal clk    : std_logic := '0';
    signal clk_sp : std_logic := '0';
    signal rstn   : std_logic;

    signal start : std_logic;
    signal done  : std_logic;

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

    type ram_type is array (0 to 2 ** addr_width_psum_mem - 1) of std_logic_vector(data_width_psum - 1 downto 0);

    type t_state_accelerator is (s_idle, s_init_started, s_load_fifo_started, s_processing);

    signal r_iact_command     : command_lb_t;
    signal r_iact_read_offset : std_logic_vector(addr_width_iact - 1 downto 0);
    signal r_shrink_sum       : integer;

    -- Signals for evaluation
    signal r_psum_commands_tmp         : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal r_psum_commands             : command_lb_array_t(0 to size_y - 1);
    signal r_psum_commands_read        : std_logic_vector(size_y - 1 downto 0);
    signal r_psum_commands_read_update : std_logic_vector(size_y - 1 downto 0);

begin

    o_psums           <= << signal accelerator_inst.w_psums : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0)>>;
    o_psums_valid     <= << signal accelerator_inst.w_psums_valid : std_logic_vector(size_x - 1 downto 0)>>;
    i_data_iact       <= << signal accelerator_inst.w_data_iact : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0)>>;
    i_data_iact_valid <= << signal accelerator_inst.w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0)>>;
    i_data_wght       <= << signal accelerator_inst.w_data_wght : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0)>>;
    i_data_wght_valid <= << signal accelerator_inst.w_data_wght_valid : std_logic_vector(size_y - 1 downto 0)>>;

    r_iact_command     <= << signal accelerator_inst.pe_array_inst.pe_inst_y(0).pe_inst_x(0).pe_north.pe_inst.line_buffer_iact.i_command : command_lb_t >>;
    r_iact_read_offset <= << signal accelerator_inst.pe_array_inst.pe_inst_y(0).pe_inst_x(0).pe_north.pe_inst.line_buffer_iact.i_read_offset : std_logic_vector(addr_width_iact - 1 downto 0) >>;

    r_psum_commands_tmp <= << signal accelerator_inst.control_address_generator_inst.g_control.control_inst.o_command_psum : command_lb_row_col_t >>;

    g_psum_commands : for y in 0 to size_y - 1 generate
        r_psum_commands(y)             <= r_psum_commands_tmp(y,0);
        r_psum_commands_read(y)        <= '1' when r_psum_commands(y) = c_lb_read else
                                          '0';
        r_psum_commands_read_update(y) <= '1' when r_psum_commands(y) = c_lb_read_update else
                                          '0';
    end generate g_psum_commands;

    write_en_iact <= '0';
    write_en_wght <= '0';
    din_iact      <= (others => '0');
    din_wght      <= (others => '0');

    accelerator_inst : entity accel.accelerator
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
            g_kernels           => g_kernels,
            g_image_y           => g_image_y,
            g_image_x           => g_image_x,
            g_kernel_size       => g_kernel_size,
            g_files_dir         => g_files_dir,
            g_init_sp           => g_init_sp,
            g_control_init      => g_control_init,
            g_c1                => g_c1,
            g_w1                => g_w1,
            g_h2                => g_h2,
            g_m0                => g_m0,
            g_m0_last_m1        => g_m0_last_m1,
            g_rows_last_h2      => g_rows_last_h2,
            g_c0                => g_c0,
            g_c0_last_c1        => g_c0_last_c1,
            g_c0w0              => g_c0w0,
            g_c0w0_last_c1      => g_c0w0_last_c1,
            g_dataflow          => g_dataflow
        )
        port map (
            clk               => clk,
            rstn              => rstn,
            clk_sp            => clk_sp,
            i_start           => start,
            o_done            => done,
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

        wait until done = '1';
        wait for 100 ns;
        start <= '0';

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

        -- s_input_image <= read_file(file_name => g_files_dir & "_image_reordered_2.txt", num_col => g_image_x * g_channels * g_h2, num_row => size_rows);
        -- s_input_weights   <= read_file(file_name => "src/_kernel_reordered.txt", num_col => g_kernel_size * g_channels * g_tiles_y, num_row => g_kernel_size);
        -- s_expected_output <= read_file(file_name => g_files_dir & "_convolution.txt", num_col => g_image_x - g_kernel_size + 1, num_row => g_image_y - g_kernel_size + 1);
        wait;

    end process p_read_files;

    p_sum_shrink : process (clk, rstn) is
    begin

        if not rstn then
            r_shrink_sum <= 0;
        elsif rising_edge(clk) then
            if r_iact_command = c_lb_shrink then
                r_shrink_sum <= r_shrink_sum + to_integer(unsigned(r_iact_read_offset));
            end if;
        end if;

    end process p_sum_shrink;

    /*p_check_img : for y in 0 to size_rows - 1 generate

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

    end generate p_check_img;*/

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

    eval_status : process (clk, rstn) is

        file     outfile : text open write_mode is g_files_dir & "_eval_status.txt";
        variable row     : line;

        -- Signals for evaluation
        alias r_state                 is << signal accelerator_inst.control_address_generator_inst.g_control.control_inst.r_state : t_control_state >>;
        alias r_preload_fifos_started is << signal accelerator_inst.scratchpad_interface_inst.i_start : std_logic >>;
        alias r_preload_fifos_done    is << signal accelerator_inst.scratchpad_interface_inst.r_preload_fifos_done : std_logic >>;
        alias r_write_en_psum         is << signal accelerator_inst.scratchpad_interface_inst.o_write_en_psum : std_logic >>;
        alias r_empty_psum_fifo       is << signal accelerator_inst.address_generator_psum_inst.i_empty_psum_fifo : std_logic_vector(size_x - 1 downto 0) >>;
        alias r_data_iact_valid       is << signal accelerator_inst.scratchpad_interface_inst.o_data_iact_valid : std_logic_vector(size_rows - 1 downto 0) >>;
        alias r_data_wght_valid       is << signal accelerator_inst.scratchpad_interface_inst.o_data_wght_valid : std_logic_vector(size_y - 1 downto 0) >>;
        alias r_enable_pe_array       is << signal accelerator_inst.pe_array_inst.i_enable : std_logic >>;
        alias r_data_out_valid        is << signal accelerator_inst.pe_array_inst.o_psums_valid : std_logic_vector(size_x - 1 downto 0) >>;

    begin

        if not rstn then
        elsif rising_edge(clk) then
            if r_preload_fifos_started = '1' then
                -- Output and Calculate
                if r_preload_fifos_done = '1' then
                    if r_state = s_calculate or r_state = s_incr_c1 or r_state = s_incr_h1 then
                        if (r_iact_command = c_lb_shrink or r_iact_command = c_lb_idle) and r_enable_pe_array = '1' then
                            -- Idle / Shrink while PE array is enabled
                            write(row, integer'image(21));
                            write(row, string'("  "));
                        elsif r_enable_pe_array = '0' then
                            -- PE array is disabled, loading data
                            write(row, integer'image(22));
                            write(row, string'("  "));
                        elsif r_iact_command = c_lb_read then
                            -- Processing data
                            write(row, integer'image(20));
                            write(row, string'("  "));
                        else
                            assert false
                                report "What else?!"
                                severity failure;
                        end if;
                    elsif r_state = s_output and done = '0' then
                        if or r_psum_commands_read = '1' and or r_psum_commands_read_update = '0' then
                            -- Output data / Output and pass
                            write(row, integer'image(12));
                            write(row, string'("  "));
                        elsif or r_psum_commands_read_update = '1' then
                            -- Sum up partial sums
                            write(row, integer'image(11));
                            write(row, string'("  "));
                        elsif or r_data_out_valid = '1' then
                            -- Output data
                            write(row, integer'image(12));
                            write(row, string'("  "));
                        else
                            -- Idle
                            write(row, integer'image(10));
                            write(row, string'("  "));
                        end if;
                    elsif r_state = s_output and done = '1' and (and r_empty_psum_fifo = '0') then
                        -- Output done, still writing results to Spad
                        write(row, integer'image(13));
                        write(row, string'("  "));
                    else
                    -- Output done, writing results done
                    end if;
                else
                    -- Preload fifos
                    write(row, integer'image(23));
                    write(row, string'("  "));
                end if;

                -- Load data
                -- if r_data_iact_valid(size_y - 1) = '1' or r_data_wght_valid(0) = '1' then
                if or r_data_iact_valid = '1' or or r_data_wght_valid = '1' then
                    if r_preload_fifos_done /= '1' then
                        write(row, integer'image(30));
                        write(row, string'("  "));
                    elsif r_state = s_calculate and r_enable_pe_array = '1' then
                        write(row, integer'image(31));
                        write(row, string'("  "));
                    elsif r_state = s_calculate and r_enable_pe_array = '0' then
                        write(row, integer'image(32));
                        write(row, string'("  "));
                    elsif r_state = s_output then
                        write(row, integer'image(33));
                        write(row, string'("  "));
                    end if;
                end if;

                -- Load input activations
                if or r_data_iact_valid = '1' then
                    write(row, integer'image(40));
                    write(row, string'("  "));
                elsif r_state /= s_output or done = '0' or (done = '1' and (and r_empty_psum_fifo = '0')) then
                    write(row, integer'image(41));
                    write(row, string'("  "));
                end if;

                -- load input activations for all input rows
                for i in 0 to size_rows - 1 loop

                    if r_data_iact_valid(i) = '1' then
                        write(row, integer'image(100 + i));
                        write(row, string'("  "));
                    end if;

                end loop;

                -- load wgths for all rows
                for i in 0 to size_y - 1 loop

                    if r_data_wght_valid(i) = '1' then
                        write(row, integer'image(200 + i));
                        write(row, string'("  "));
                    end if;

                end loop;

                -- Load weights
                if or r_data_wght_valid = '1' then
                    write(row, integer'image(50));
                    write(row, string'("  "));
                elsif r_state /= s_output or done = '0' or (done = '1' and (and r_empty_psum_fifo = '0')) then
                    write(row, integer'image(51));
                    write(row, string'("  "));
                end if;

                -- Store output
                if r_write_en_psum = '1' then
                    write(row, integer'image(60));
                    write(row, string'("  "));
                elsif r_state /= s_output or done = '0' or (done = '1' and (and r_empty_psum_fifo = '0')) then
                    write(row, integer'image(61));
                    write(row, string'("  "));
                end if;

                /*if r_preload_fifos_done = '1' and r_enable_pe_array = '0' then

                    -- Preloading FIFOs
                    write(row, integer'image(0));
                    write(row, string'("  "));

                elsif r_enable_pe_array = '1' then


                    write(row, integer'image(1));
                    write(row, string'("  "));

                end if;*/

                writeline(outfile, row);
            end if;
        end if;

    end process eval_status;

    write_outputs : process is

        file     outfile : text open write_mode is g_files_dir & "_output.txt";
        variable outline : line;
        variable idx     : integer;

        alias ram is << variable accelerator_inst.scratchpad_inst.ram_dp_psum.ram_instance : ram_type >>;

    begin

        wait until done = '1';

        wait for 1000 ns;

        idx := 0;

        for m0 in 0 to g_m0 - 1 loop

            for row  in 0 to g_image_y - g_kernel_size loop

                for pix in 0 to g_image_x - g_kernel_size loop

                    write(outline, integer'image(to_integer(signed(ram(idx)))));
                    write(outline, string'(" "));
                    idx := idx + 1;

                end loop;

                writeline(outfile, outline);

            end loop;

        end loop;

        report "Writing outputs is finished."
            severity note;
        finish;

        wait;

    end process write_outputs;

end architecture imp;

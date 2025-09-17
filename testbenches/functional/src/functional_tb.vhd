library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use ieee.float_pkg.all;
    use std.env.finish;
    use std.env.stop;
    use std.textio.all;

library accel;
    use accel.utilities.all;

entity functional_tb is
    generic (
        size_x : positive := 7;
        size_y : positive := 10;

        data_width_input : positive := 8; -- Width of the input data (weights, iacts)
        data_width_psum  : positive := 20;

        line_length_iact : positive := 64; -- TODO check influence on tiling - does not work for length 32, kernel 4 and channels 10. Does not work for length 30, kernel 3 and channels 10
        line_length_wght : positive := 64; -- see above
        line_length_psum : positive := 128;

        mem_word_count : positive := 8;
        mem_addr_width : positive := 15; -- addressing words of mem_word_count * data_width_input bits, 256kB of shared spad

        g_inputchs    : positive := 30;
        g_outputchs   : positive := 10;
        g_image_y     : positive := 20;
        g_image_x     : positive := 20;
        g_kernel_size : positive := 1;
        g_bias        : integer  := 5;

        g_iact_fifo_size : positive := 16;
        g_wght_fifo_size : positive := 16;
        g_psum_fifo_size : positive := 32;

        g_clk    : time := 10 ns;
        g_clk_sp : time := 2 ns;

        g_files_dir  : string   := "./";
        g_init_sp    : boolean  := true;
        g_write_eval : boolean  := false;
        g_iterations : positive := 1;

        g_c1            : positive := 1;
        g_w1            : positive := 1;
        g_h2            : positive := 1;
        g_m1            : positive := 1;
        g_m0            : positive := 1;
        g_m0_last_m1    : positive := 1;
        g_rows_last_h2  : positive := 1;
        g_c0            : positive := 1;
        g_c0_last_c1    : positive := 1;
        g_c0w0          : positive := 1;
        g_c0w0_last_c1  : positive := 1;
        g_psum_throttle : integer  := 0;
        g_mode_pad      : integer  := 0;
        g_pad_x         : integer  := 0;
        g_pad_y         : integer  := 0;
        g_mode_act      : integer  := 0;
        g_requant       : integer  := 0;
        g_postproc      : integer  := 1;
        g_dataflow      : integer  := 1;

        g_stride_iact_w  : positive := 1;
        g_stride_iact_hw : positive := 1;

        g_stride_wght_krnl : positive := 1;
        g_stride_wght_och  : positive := 1;
        g_stride_psum_och  : positive := 1;

        g_iact_base_addr : integer := 0;
        g_wght_base_addr : integer := 0;
        g_psum_base_addr : integer := 0;
        g_pad_base_addr  : integer := 0
    );
end entity functional_tb;

architecture imp of functional_tb is

    constant size_rows         : positive := size_x + size_y - 1;
    constant mem_data_width    : positive := mem_word_count * data_width_input;
    constant mem_col_idx_width : positive := positive(ceil(log2(real(mem_word_count))));
    constant addr_width_iact   : positive := positive(ceil(log2(real(line_length_iact))));

    signal clk    : std_logic := '0';
    signal clk_sp : std_logic := '0';
    signal rstn   : std_logic := '0';

    signal start       : std_logic;
    signal done        : std_logic;
    signal output_done : boolean;
    signal eval_done   : boolean := false;
    signal iteration   : integer := 0;

    type string_pointer is access string;

    signal params : parameters_t;
    signal status : status_info_t;

    signal o_psums           : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal o_psums_valid     : std_logic_vector(size_x - 1 downto 0);
    signal i_data_iact       : array_t (0 to size_rows - 1)(data_width_input - 1 downto 0);
    signal i_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_wght       : array_t (0 to size_y - 1)(data_width_input - 1 downto 0);
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal s_input_image     : int_image_t(0 to size_rows - 1, 0 to g_image_x * g_inputchs * g_h2 - 1);         -- 2, because two tile_y
    signal s_input_weights   : int_image_t(0 to g_kernel_size - 1, 0 to g_kernel_size * g_inputchs * g_h2 - 1); -- not *2 because kernel stays the same across tile_y
    signal s_expected_output : int_image_t(0 to g_image_y - g_kernel_size, 0 to g_image_x - g_kernel_size);

    signal zeropt_fp32 : array_t(max_output_channels - 1 downto 0)(31 downto 0);
    signal scale_fp32  : array_t(max_output_channels - 1 downto 0)(31 downto 0);

    type   ram_type is array (0 to 2 ** mem_addr_width / mem_word_count - 1) of std_logic_vector(mem_data_width - 1 downto 0);
    type   ram_cols_type is array(0 to mem_word_count) of ram_type;
    signal ram_cols : ram_cols_type;

    signal r_iact_command     : command_lb_t;
    signal r_iact_read_offset : std_logic_vector(addr_width_iact - 1 downto 0);
    signal r_shrink_sum       : integer;

    -- Signals for evaluation
    signal r_psum_commands_tmp         : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal r_psum_commands             : command_lb_array_t(0 to size_y - 1);
    signal r_psum_commands_read        : std_logic_vector(size_y - 1 downto 0);
    signal r_psum_commands_read_update : std_logic_vector(size_y - 1 downto 0);

begin

    o_psums           <= << signal accelerator_inst.w_psums : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0) >>;
    o_psums_valid     <= << signal accelerator_inst.w_psums_valid : std_logic_vector(size_x - 1 downto 0) >>;
    i_data_iact       <= << signal accelerator_inst.w_data_iact : array_t (0 to size_rows - 1)(data_width_input - 1 downto 0) >>;
    i_data_iact_valid <= << signal accelerator_inst.w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0) >>;
    i_data_wght       <= << signal accelerator_inst.w_data_wght : array_t (0 to size_y - 1)(data_width_input - 1 downto 0) >>;
    i_data_wght_valid <= << signal accelerator_inst.w_data_wght_valid : std_logic_vector(size_y - 1 downto 0) >>;

    r_iact_command     <= << signal accelerator_inst.pe_array_inst.pe_inst_y(0).pe_inst_x(0).pe_north.pe_inst.line_buffer_iact.i_command : command_lb_t >>;
    r_iact_read_offset <= << signal accelerator_inst.pe_array_inst.pe_inst_y(0).pe_inst_x(0).pe_north.pe_inst.line_buffer_iact.i_read_offset : std_logic_vector(addr_width_iact - 1 downto 0) >>;

    r_psum_commands_tmp <= << signal accelerator_inst.control_address_generator_inst.o_command_psum : command_lb_row_col_t >>;

    g_psum_commands : for y in 0 to size_y - 1 generate
        r_psum_commands(y)             <= r_psum_commands_tmp(y,0);
        r_psum_commands_read(y)        <= '1' when r_psum_commands(y) = c_lb_read else
                                          '0';
        r_psum_commands_read_update(y) <= '1' when r_psum_commands(y) = c_lb_read_update else
                                          '0';
    end generate g_psum_commands;

    params.dataflow      <= g_dataflow;
    params.inputchs      <= g_inputchs;
    params.outputchs     <= g_outputchs;
    params.image_y       <= g_image_y;
    params.image_x       <= g_image_x;
    params.kernel_size   <= g_kernel_size;
    params.c1            <= g_c1;
    params.w1            <= g_w1;
    params.h2            <= g_h2;
    params.m1            <= g_m1;
    params.m0            <= g_m0;
    params.m0_last_m1    <= g_m0_last_m1;
    params.rows_last_h2  <= g_rows_last_h2;
    params.c0            <= g_c0;
    params.c0_last_c1    <= g_c0_last_c1;
    params.c0w0          <= g_c0w0;
    params.c0w0_last_c1  <= g_c0w0_last_c1;
    params.psum_throttle <= g_psum_throttle;
    params.mode_pad      <= mode_padding_t'val(g_mode_pad);
    params.pad_x         <= g_pad_x;
    params.pad_y         <= g_pad_y;
    params.bias          <= (others => g_bias);
    params.mode_act      <= mode_activation_t'val(g_mode_act);
    params.requant_enab  <= true when g_requant > 0 else
                            false;
    params.zeropt_fp32   <= zeropt_fp32;
    params.scale_fp32    <= scale_fp32;

    params.stride_iact_w  <= g_stride_iact_w;
    params.stride_iact_hw <= g_stride_iact_hw;

    params.stride_wght_kernel <= g_stride_wght_krnl;
    params.stride_wght_och    <= g_stride_wght_och;
    params.stride_psum_och    <= g_stride_psum_och;

    params.base_iact <= g_iact_base_addr;
    params.base_wght <= g_wght_base_addr;
    params.base_psum <= g_psum_base_addr;
    params.base_pad  <= g_pad_base_addr;

    accelerator_inst : entity accel.accelerator
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            data_width_input => data_width_input,
            data_width_psum  => data_width_psum,
            line_length_iact => line_length_iact,
            line_length_wght => line_length_wght,
            line_length_psum => line_length_psum,
            mem_addr_width   => mem_addr_width,
            mem_word_count   => mem_word_count,
            g_iact_fifo_size => g_iact_fifo_size,
            g_wght_fifo_size => g_wght_fifo_size,
            g_psum_fifo_size => g_psum_fifo_size,
            g_dataflow       => g_dataflow,
            use_float_ip     => false,
            postproc_enable  => g_postproc > 0
        )
        port map (
            clk      => clk,
            rstn     => rstn,
            clk_sp   => clk_sp,
            i_start  => start,
            o_done   => done,
            i_params => params,
            o_status => status,
            -- memory i/o not used in this testbench
            i_mem_en       => '0',
            i_mem_write_en => (others => '0'),
            i_mem_addr     => (others => '0'),
            i_mem_din      => (others => '0'),
            o_mem_dout     => open
        );

    rstn_gen : process is
    begin

        rstn  <= '0';
        start <= '0';

        wait for 100 ns;
        wait until rising_edge(clk);
        rstn <= '1';

        wait for 20 ns;

        while iteration < g_iterations loop

            wait until rising_edge(clk);
            start <= '1';

            wait until done = '1' and output_done;
            wait for 100 ns;
            wait until rising_edge(clk);
            start     <= '0';
            iteration <= iteration + 1;

            wait for 1000 ns;

        end loop;

        finish;

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

        -- assert line_length_iact >= g_kernel_size * g_inputchs
        --     report "Line length to store input values must be greater or equal to the kernel size"
        --     severity failure;

        assert size_y >= g_kernel_size
            report "Y dimension of PE array has to be greater or equal to kernel size"
            severity failure;

        -- assert line_length_wght >= g_kernel_size * g_inputchs
        --     report "Length of wght buffer has to be greater or equal to kernel size, buffer has to store values of one kernel row at a time."
        --     severity failure;

        assert line_length_psum >= g_image_x - g_kernel_size
            report "Psum buffer has to hold output values of one row, must not be smaller than output row size"
            severity failure; -- TODO To be changed by splitting the task and propagating as many psums that the buffer can hold through the array at once

        wait;

    end process p_constant_check;

    p_read_files : process is

        variable v_zeropt_scale : float32_arr2d_t(0 to max_output_channels - 1, 0 to 1);
        variable v_och_to_load  : integer;

    begin

        for g in 0 to max_output_channels - 1 loop

            zeropt_fp32(g) <= to_slv(to_float(0.0));
            scale_fp32(g)  <= to_slv(to_float(1.0));

        end loop;

        if g_requant > 0 then
            v_zeropt_scale := read_file_floats(g_files_dir & "_zeropt_scale.txt", 2, max_output_channels);
            -- report "got zeropt " & to_string(to_real(v_zeropt_scale(0,0))) & " and scale " & to_string(to_real(v_zeropt_scale(0,1)));

            -- TODO: implement scaling for an arbitrary number of output channels larger than m0
            v_och_to_load := g_outputchs;
            if v_och_to_load > max_output_channels then
                v_och_to_load := max_output_channels;
            end if;

            for g in 0 to v_och_to_load - 1 loop

                zeropt_fp32(g) <= to_slv(v_zeropt_scale(g, 0));
                scale_fp32(g)  <= to_slv(v_zeropt_scale(g, 1));

            end loop;

        end if;

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

    eval_status : process (clk, rstn) is

        file     outfile : text open write_mode is g_files_dir & "_eval_status.txt";
        variable row     : line;

        -- Signals for evaluation
        alias r_state                 is << signal accelerator_inst.control_address_generator_inst.g_control.control_inst.r_state : control_state_t >>;
        alias r_preload_fifos_started is << signal accelerator_inst.scratchpad_interface_inst.i_start : std_logic >>;
        alias r_preload_fifos_done    is << signal accelerator_inst.scratchpad_interface_inst.r_preload_fifos_done : std_logic >>;
        alias r_write_en_psum         is << signal accelerator_inst.scratchpad_interface_inst.o_write_en_psum : std_logic_vector(7 downto 0) >>;
        alias r_empty_psum_fifo       is << signal accelerator_inst.scratchpad_interface_inst.w_empty_psum_f : std_logic_vector(size_x - 1 downto 0) >>;
        alias r_data_iact_valid       is << signal accelerator_inst.scratchpad_interface_inst.o_data_iact_valid : std_logic_vector(size_rows - 1 downto 0) >>;
        alias r_data_wght_valid       is << signal accelerator_inst.scratchpad_interface_inst.o_data_wght_valid : std_logic_vector(size_y - 1 downto 0) >>;
        alias r_enable_pe_array       is << signal accelerator_inst.pe_array_inst.i_enable : std_logic >>;
        alias r_data_out_valid        is << signal accelerator_inst.pe_array_inst.o_psums_valid : std_logic_vector(size_x - 1 downto 0) >>;

    begin

        if not rstn then
        elsif rising_edge(clk) and g_write_eval then
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
                if or r_write_en_psum = '1' then
                    write(row, integer'image(60));
                    write(row, string'("  "));
                elsif r_state /= s_output or done = '0' or (done = '1' and (and r_empty_psum_fifo = '0')) then
                    write(row, integer'image(61));
                    write(row, string'("  "));
                end if;

                writeline(outfile, row);
            end if;
            if done = '1' and not eval_done then
                write(row, string'("simulation done, cycle counter: "));
                write(row, integer'image(to_integer(status.cycle_counter)));
                writeline(outfile, row);
                eval_done <= true;
            end if;
        end if;

    end process eval_status;

    -- assemble all scratchpad columns into ram_cols for easy access

    gen_ram_alias : for i in 0 to mem_word_count - 1 generate

        ram_alias : process is

            alias ram is << variable ^.accelerator_inst.scratchpad_inst.ram.gen_cols(i).ram.ram : ram_type >>;

        begin

            wait until done = '1';
            wait for 900 ns;
            ram_cols(i) <= ram;
            wait;

        end process ram_alias;

    end generate gen_ram_alias;

    write_outputs : process is

        variable file_ptr  : string_pointer;
        file     outfile   : text;
        variable outline   : line;
        variable idx       : integer;
        variable word_idx  : integer;
        variable column    : integer;
        variable base_addr : integer;
        variable data      : std_logic_vector(mem_data_width - 1 downto 0);

        variable data_width_usable  : integer; -- actual usable bits per word
        variable word_width_mem     : integer; -- data width of a single word in memory, maybe padded
        variable words_per_mem_word : integer; -- number of words per memory word

    begin

        output_done <= false;

        if g_requant > 0 then
            data_width_usable  := data_width_input;
            word_width_mem     := data_width_input;
            words_per_mem_word := mem_word_count;
        else
            data_width_usable  := data_width_psum;
            word_width_mem     := integer(2 ** ceil(log2(real(data_width_psum)))); -- round up to next power-of-two
            words_per_mem_word := mem_data_width / word_width_mem;
        end if;

        wait until done = '1';

        if iteration > 0 then
            file_ptr := new string'(g_files_dir & "_output_" & integer'image(iteration) & ".txt");
        else
            file_ptr := new string'(g_files_dir & "_output.txt");
        end if;

        wait for 1000 ns;

        file_open(outfile, file_ptr.all, write_mode);

        for och in 0 to g_outputchs - 1 loop

            column    := och mod mem_word_count;
            base_addr := g_psum_base_addr / mem_word_count + och / mem_word_count * g_stride_psum_och;
            idx       := 0;
            word_idx  := 0;

            for row in 0 to g_image_y - g_kernel_size + 2 * params.pad_y loop

                for pix in 0 to params.w1 - 1 loop

                    data                                 := (others => '0');
                    data(data_width_usable - 1 downto 0) := ram_cols(column)(base_addr + idx)(word_width_mem * word_idx + data_width_usable - 1 downto word_width_mem * word_idx);
                    write(outline, integer'image(to_integer(signed(data(data_width_usable - 1 downto 0)))));
                    write(outline, string'(" "));

                    if word_idx = words_per_mem_word - 1 then
                        word_idx := 0;
                        idx      := idx + 1;
                    else
                        word_idx := word_idx + 1;
                    end if;

                end loop;

                writeline(outfile, outline);

            end loop;

        end loop;

        report "Writing outputs is finished."
            severity note;

        file_close(outfile);
        deallocate(file_ptr);

        output_done <= true;

        wait until done = '0';

    end process write_outputs;

end architecture imp;

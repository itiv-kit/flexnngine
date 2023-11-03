onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/rstn
add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/g_h2
add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/g_m0
add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/w_m0
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/g_m0_last_m1
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_m0_count_kernel
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_m0_last_m1
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_m1
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/i_kernels
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_h2_tmp
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_rows_last_h2
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_h2
#add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/i_kernel_size

add wave -noupdate -expand -group {PE arr outputs} -radix signed /functional_tb/accelerator_inst/pe_array_inst/o_psums
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/o_psums_valid
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/r_enable(0)

add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_h2
#add wave -noupdate -expand -group Control_static -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_tiles_y_last_tile_rows
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_w1
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_c1
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_c0w0
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_c0w0_last_c1
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/g_c0
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/g_c0_last_c1
#add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_m0
#add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_rows_last_h2
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_m0
add wave -noupdate -expand -group Control_static -radix unsigned  /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_rows_last_h2


add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_enable
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(0)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(1)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(2)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(3)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(4)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(5)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(6)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(7)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(8)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command(9)(0)

add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_iact
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_wght
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(0)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(1)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(2)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(3)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(4)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(5)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(6)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(7)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(8)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_command_psum(9)(0)
add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_output_sequence
#add wave -noupdate -expand -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_m0_dist
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_c0w0
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_c1
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_w1
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_h2
#add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_h1
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_incr_w1
add wave -noupdate -expand -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_state


add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/din
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/wr_en
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/dout
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/rd_en
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/valid
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/empty
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/full
add wave -noupdate -expand -group FIFOs -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/almost_full


add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_state_accelerator
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_status_sp_interface
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_enable_pe_array
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_preload_fifos_started
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_preload_fifos_done
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_state
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_iact_command
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_data_wght_valid
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_data_iact_valid
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/o_psums_valid(0)
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_psum_commands
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_psum_commands_read
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_psum_commands_read_update
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_done_processing
add wave -noupdate -expand -group Evaluation -radix unsigned /functional_tb/r_empty_psum_fifo

add wave -noupdate -expand -group Start -radix unsigned /functional_tb/start
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/r_state
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/r_start_control
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/i_enable
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/o_status
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/o_enable
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_f
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_f
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_address_f
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_address_f
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/r_done_iact
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/r_done_wght
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_psum_d
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full_next
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/line_length
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data_valid
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_command_delay
add wave -noupdate -expand -group Start -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command


add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums_valid
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum_binary
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/o_data_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/o_write_en_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_psum_out
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_address_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/i_empty_psum_fifo
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_psum_done
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_count_x
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_psum_done
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_test
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/i_start
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_start
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_count_w1
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/w_write_adr_psum
#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_count_m0
#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_count_w1
#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_count_h2
#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/address_generator_psum_inst/r_offset_m0

add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/o_data_out_valid
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/o_data_out
add wave -noupdate -expand -group PSUMS_PASS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/o_data_out_valid


add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/ram/ram_instance

add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(3)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group PSUMS_3 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(3)/pe_south/pe_inst/line_buffer_psum/ram/ram_instance

add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHTS -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/ram/ram_instance

add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/w_pause_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/o_address_iact_valid
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/o_address_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_C0_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_c0_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_W1
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_index_h_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_w1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_C1
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_c1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_H2
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_h2_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_kernel_size
#add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_h1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_offset_mem_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_last_c1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_last_h2_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_index_c_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_index_c_last_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_data_valid_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_iact_done
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/o_address_iact_valid(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/w_buffer_full_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/w_data_iact_valid(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/w_data_iact(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_start
add wave -noupdate -expand -group ADR_iact -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_fifo_full_iact

add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_fifo_full_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_delay_wght_valid
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/o_address_wght_valid
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/o_address_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_test_wght
#add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_m0_dist
#add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/control_init_inst/r_m0_dist
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_C0_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_c0_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_W1
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_w1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_C1
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_c1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_H2
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_h2_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_kernel_size
#add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_count_h1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_last_c1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_offset_c_last_h2_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_index_c_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_index_c_last_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_data_valid_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/w_offset_mem_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_test_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_test_wght2
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/r_wght_done
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/w_buffer_full_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_inst/i_start

#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/scratchpad_inst/ram_dp_psum/ram_instance

add wave -noupdate -expand -group {PE arr outputs} -radix signed /functional_tb/accelerator_inst/pe_array_inst/o_psums
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/o_psums_valid
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/r_enable(0)


add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
#add wave -noupdate -expand -group WGHT_INPUT -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght_valid
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group WGHT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght(0)
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght_valid(0)
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_buffer_full_wght
add wave -noupdate -expand -group WGHT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght_valid

add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact
add wave -noupdate -expand -group IACT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_iact_valid(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out_valid(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/r_sel_iact_fifo
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_iact/i_req
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_iact/o_gnt
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_almost_full_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/o_data_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_buffer_full_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_buffer_full_next_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full_next
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_update_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group {iact commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_update_offset_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /functional_tb/r_shrink_sum

add wave -noupdate -expand -group {wght commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_update_offset_wght(0)

add wave -noupdate -expand -group {psum commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_update_offset_psum_d(0)

add wave -noupdate -expand -group {Outputs} -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command
add wave -noupdate -expand -group {Outputs} -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_iact
add wave -noupdate -expand -group {Outputs} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_iact
add wave -noupdate -expand -group {Outputs} -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_update_offset_psum
add wave -noupdate -expand -group {Outputs} -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_wght
add wave -noupdate -expand -group {Outputs} -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_read_offset_wght

add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/r_fill_count

add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/r_fill_count

add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(6)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(5)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(6)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(7)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(8)/pe_inst_x(6)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(9)/pe_inst_x(6)/pe_south/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts_6 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/r_pause_iact


add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/w_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/i_preload_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_enable
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_mult
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_mult_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out_valid

#
#
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_mult
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_mult_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_enable
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_valid_chg
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_command



TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {100 ns} {1000 ns}


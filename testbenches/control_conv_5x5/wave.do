onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/rstn
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/start
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/image_x
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/image_y
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/channels
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/kernel_size

add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/control_inst/r_tiles_y
add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/control_inst/r_tiles_x
add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/control_inst/r_tiles_filter
add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/control_inst/r_commands_per_tile
add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/control_inst/r_commands_last_tile_filter

add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_command_counter
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_tile_filter_counter
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_tile_x_counter
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_tile_y_counter
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_tile_change
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_tile_change_dt
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/control_inst/r_state

add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/control_inst/r_command_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/control_inst/r_read_offset_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/control_inst/r_update_offset_iact(0)

add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/control_inst/r_command_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/control_inst/r_read_offset_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/control_inst/r_update_offset_wght(0)

add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/control_inst/r_command_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/control_inst/r_read_offset_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/control_inst/r_update_offset_psum_d(0)

add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/control_inst/command
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/control_inst/command_iact
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/read_offset_iact
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/control_inst/command_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/read_offset_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/update_offset_psum

add wave -noupdate -expand -group {PE arr outputs} -radix signed /control_conv_tb/o_psums
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /control_conv_tb/o_psums_valid

add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/i_preload_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_mult
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_in_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_mult_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance


add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/fill_count



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


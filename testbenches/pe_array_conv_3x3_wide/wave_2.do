onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_3x3_wide_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_3x3_wide_tb/rstn

add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_wide_tb/i_data_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/i_data_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_wide_tb/i_data_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/i_data_iact_valid

add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_wide_tb/i_preload_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/i_preload_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/o_buffer_full_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/o_buffer_full_next_iact

add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/o_buffer_full_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_wide_tb/o_buffer_full_wght



add wave -noupdate -expand -group {Commands} -radix unsigned /pe_array_conv_3x3_wide_tb/command_psum
add wave -noupdate -expand -group {Commands} -radix unsigned /pe_array_conv_3x3_wide_tb/command_iact
add wave -noupdate -expand -group {Commands} -radix unsigned /pe_array_conv_3x3_wide_tb/read_offset_iact

add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_psum/data_out
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_psum/data_out_valid

add wave -noupdate -expand -group Pe_output -radix unsigned /pe_array_conv_3x3_wide_tb/o_psums
add wave -noupdate -expand -group Pe_output -radix unsigned /pe_array_conv_3x3_wide_tb/o_psums_valid

add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_iact/pointer_head_s
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_iact/pointer_tail_s
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_inst/line_buffer_iact/fill_count

add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_in_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/sel_conv_gemm
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/demux_input_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/o_buffer_full_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_in_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/sel_conv_gemm
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/demux_input_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /pe_array_conv_3x3_wide_tb/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_inst/line_buffer_iact/ram/ram_instance


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


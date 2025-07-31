onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /pe_conv_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /pe_conv_tb/rstn

add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_iact_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_wght
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_conv_tb/data_in_wght_valid

add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_conv_tb/command_iact
add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_conv_tb/command_psum
add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_conv_tb/command_wght

add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_iact/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_iact/o_data_valid
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_psum/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_psum/o_data_valid
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_wght/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned /pe_conv_tb/pe_inst/line_buffer_wght/o_data_valid

add wave -noupdate -expand -group Pe_output -radix unsigned /pe_conv_tb/data_out
add wave -noupdate -expand -group Pe_output -radix unsigned /pe_conv_tb/data_out_valid

add wave -noupdate -expand -group RAM_internal -radix unsigned /pe_conv_tb/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -radix unsigned /pe_conv_tb/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -radix unsigned /pe_conv_tb/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -radix unsigned /pe_conv_tb/pe_inst/line_buffer_wght/ram/ram_instance

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


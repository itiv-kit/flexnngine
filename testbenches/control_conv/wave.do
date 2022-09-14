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

add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/control_inst/command_iact
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/read_offset_iact
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/control_inst/command_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/read_offset_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/control_inst/update_offset_psum


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


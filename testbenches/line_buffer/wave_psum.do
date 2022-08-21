onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_psum_tb/ADDR_WIDTH
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_psum_tb/DATA_WIDTH
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_psum_tb/LINE_LENGTH
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_psum_tb/NUMBER_OF_LINES

add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/clk
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/rstn
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/data_in
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/data_in_valid
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/update_val
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_psum_tb/update_offset

add wave -noupdate -expand -group Line_Buffer_Output -radix unsigned /line_buffer_psum_tb/data_out
add wave -noupdate -expand -group Line_Buffer_Output -radix unsigned /line_buffer_psum_tb/data_out_valid

add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/pointer_head_s
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/pointer_tail_s
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/buffer_full
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/fifo_empty_s
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/read_command/pointer_read_v
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/read_offset
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_psum_tb/line_buffer_inst/command

add wave -noupdate -expand -group RAM_internal -radix unsigned /line_buffer_psum_tb/line_buffer_inst/ram/ram_instance

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


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_iact_tb/addr_width
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_iact_tb/data_width
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_iact_tb/line_length
add wave -noupdate -expand -group Generics -radix unsigned /line_buffer_iact_tb/number_of_lines
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/clk
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/rstn
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_enable
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_data_valid
add wave -noupdate -expand -group {Line_Buffer Input} -radix unsigned /line_buffer_iact_tb/line_buffer_inst/i_data
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_command
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_read_offset
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_update_offset
add wave -noupdate -expand -group {Line_Buffer Input} /line_buffer_iact_tb/line_buffer_inst/i_update_val
add wave -noupdate -expand -group Line_Buffer_Output /line_buffer_iact_tb/line_buffer_inst/o_buffer_full
add wave -noupdate -expand -group Line_Buffer_Output /line_buffer_iact_tb/line_buffer_inst/o_buffer_full_next
add wave -noupdate -expand -group Line_Buffer_Output /line_buffer_iact_tb/line_buffer_inst/o_data_valid
add wave -noupdate -expand -group Line_Buffer_Output -radix unsigned /line_buffer_iact_tb/line_buffer_inst/o_data
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/r_pointer_head
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/r_pointer_tail
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/r_fill_count
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/r_data_out_valid
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/r_forward_update_delay
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/buffer_full
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/w_read_offset
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/w_forward_update
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/read_command/v_pointer_read
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/line_buffer_inst/read_command/v_offset
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/s_x
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/s_y
add wave -noupdate -expand -group Line_Buffer_internal /line_buffer_iact_tb/s_done
add wave -noupdate -expand -group RAM_internal -radix unsigned /line_buffer_iact_tb/line_buffer_inst/ram/ram_instance
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


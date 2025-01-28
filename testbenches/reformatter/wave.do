onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group generics /reformatter_tb/dut/element_count
add wave -noupdate -expand -group generics /reformatter_tb/dut/element_size
add wave -noupdate -expand -group generics /reformatter_tb/dut/element_width
add wave -noupdate -expand -group generics /reformatter_tb/dut/output_rows
add wave -noupdate -expand -group generics /reformatter_tb/dut/output_steps
add wave -noupdate -expand -group I/O /reformatter_tb/dut/clk
add wave -noupdate -expand -group I/O /reformatter_tb/dut/i_data
add wave -noupdate -expand -group I/O /reformatter_tb/dut/i_ready
add wave -noupdate -expand -group I/O /reformatter_tb/dut/i_valid
add wave -noupdate -expand -group I/O /reformatter_tb/dut/o_data
add wave -noupdate -expand -group I/O /reformatter_tb/dut/o_ready
add wave -noupdate -expand -group I/O /reformatter_tb/dut/o_valid
add wave -noupdate -expand -group I/O /reformatter_tb/dut/rst
add wave -noupdate -expand -group internal /reformatter_tb/dut/w_mem_addra
add wave -noupdate -expand -group internal /reformatter_tb/dut/w_mem_addrb
add wave -noupdate -expand -group internal /reformatter_tb/dut/w_mem_din
add wave -noupdate -expand -group internal /reformatter_tb/dut/w_mem_dout
add wave -noupdate -expand -group internal /reformatter_tb/dut/w_mem_wen
add wave -noupdate -expand -group internal /reformatter_tb/dut/input_index_width
add wave -noupdate -expand -group internal /reformatter_tb/dut/mem_addr_width
add wave -noupdate -expand -group internal /reformatter_tb/dut/mem_word_count
add wave -noupdate -expand -group internal /reformatter_tb/dut/mem_write_idx
add wave -noupdate -expand -group internal /reformatter_tb/dut/output_step
add wave -noupdate -expand -group internal /reformatter_tb/dut/output_element
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1800 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 233
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
WaveRestoreZoom {0 ns} {1800 ns}

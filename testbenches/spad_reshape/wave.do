onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /spad_reshape_tb/dut/clk
add wave -noupdate /spad_reshape_tb/dut/rstn
add wave -noupdate -expand -group generics /spad_reshape_tb/dut/addr_width
add wave -noupdate -expand -group generics /spad_reshape_tb/dut/data_width
add wave -noupdate -expand -group generics /spad_reshape_tb/dut/cols
add wave -noupdate -expand -group generics /spad_reshape_tb/dut/word_size
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/std_en
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/std_write_en
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/std_addr
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/std_din
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/std_dout
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/rsh_en
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/rsh_addr
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/rsh_din
add wave -noupdate -expand -group I/O /spad_reshape_tb/dut/rsh_dout
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_std_en
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_std_write_en
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_std_addr
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_std_din
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_std_dout
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/r_std_addr_delay
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_rsh_en
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_rsh_addr
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/w_rsh_dout
add wave -noupdate -expand -group internal /spad_reshape_tb/dut/r_rsh_addr_delay
add wave -noupdate -expand -group testbench /spad_reshape_tb/read_data_inflight
add wave -noupdate -expand -group testbench -expand /spad_reshape_tb/read_data_expected
add wave -noupdate -expand -group testbench /spad_reshape_tb/rsh_dout
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {60 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 185
configure wave -valuecolwidth 143
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
WaveRestoreZoom {0 ns} {823 ns}

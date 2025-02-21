onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group I/O /serializer_tb/dut/clk
add wave -noupdate -expand -group I/O /serializer_tb/dut/rstn
add wave -noupdate -expand -group I/O /serializer_tb/dut/o_ready
add wave -noupdate -expand -group I/O /serializer_tb/dut/i_data
add wave -noupdate -expand -group I/O /serializer_tb/dut/i_valid
add wave -noupdate -expand -group I/O /serializer_tb/dut/i_ready
add wave -noupdate -expand -group I/O /serializer_tb/dut/o_data
add wave -noupdate -expand -group I/O /serializer_tb/dut/o_valid
add wave -noupdate -expand -group internal /serializer_tb/dut/counter
add wave -noupdate -expand -group internal /serializer_tb/dut/has_data
add wave -noupdate -expand -group internal /serializer_tb/dut/shift_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {274 ns} 0}
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
WaveRestoreZoom {0 ns} {900 ns}

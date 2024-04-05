onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /mac_tb/clk
add wave -noupdate /mac_tb/rstn
add wave -noupdate /mac_tb/en
add wave -noupdate /mac_tb/result_valid
add wave -radix decimal -noupdate /mac_tb/data_in_a
add wave -radix decimal -noupdate /mac_tb/data_in_w
add wave -radix decimal -noupdate /mac_tb/data_in_acc
add wave -radix decimal -noupdate /mac_tb/result


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


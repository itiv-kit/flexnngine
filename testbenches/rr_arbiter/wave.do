onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rstn
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/req
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/gnt
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rr_arbiter_inst/last_gnt
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rr_arbiter_inst/double_req
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rr_arbiter_inst/double_gnt
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rr_arbiter_inst/priority
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/gnt_binary
add wave -noupdate -expand -group Testbench -radix unsigned /rr_arbiter_tb/rr_arbiter_inst/test

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


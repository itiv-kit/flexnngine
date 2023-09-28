onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end  sim:/fifo_tb/TX_CLOCK_DURATION
add wave -position end  sim:/fifo_tb/RX_CLOCK_DURATION
add wave -position end  sim:/fifo_tb/USE_PACKETS
add wave -position end  sim:/fifo_tb/wr_clk
add wave -position end  sim:/fifo_tb/rst
add wave -position end  sim:/fifo_tb/wr_en
add wave -position end  sim:/fifo_tb/din
add wave -position end  sim:/fifo_tb/full
add wave -position end  sim:/fifo_tb/full2
add wave -position end  sim:/fifo_tb/almost_full
add wave -position end  sim:/fifo_tb/almost_full2
add wave -position end  sim:/fifo_tb/keep
add wave -position end  sim:/fifo_tb/drop
add wave -position end  sim:/fifo_tb/rd_clk
add wave -position end  sim:/fifo_tb/rd_en
add wave -position end  sim:/fifo_tb/dout
add wave -position end  sim:/fifo_tb/dout2
add wave -position end  sim:/fifo_tb/valid
add wave -position end  sim:/fifo_tb/valid2
add wave -position end  sim:/fifo_tb/empty
add wave -position end  sim:/fifo_tb/empty2

add wave -position end  sim:/fifo_tb/uut/rdcnt_wr
add wave -position end  sim:/fifo_tb/uut/wrcnt

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


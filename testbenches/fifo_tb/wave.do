onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -position end  sim:/tb_dc_fifo/TX_CLOCK_DURATION
add wave -position end  sim:/tb_dc_fifo/RX_CLOCK_DURATION
add wave -position end  sim:/tb_dc_fifo/USE_PACKETS
add wave -position end  sim:/tb_dc_fifo/wr_clk
add wave -position end  sim:/tb_dc_fifo/rst
add wave -position end  sim:/tb_dc_fifo/wr_en
add wave -position end  sim:/tb_dc_fifo/din
add wave -position end  sim:/tb_dc_fifo/full
add wave -position end  sim:/tb_dc_fifo/full2
add wave -position end  sim:/tb_dc_fifo/almost_full
add wave -position end  sim:/tb_dc_fifo/almost_full2
add wave -position end  sim:/tb_dc_fifo/keep
add wave -position end  sim:/tb_dc_fifo/drop
add wave -position end  sim:/tb_dc_fifo/rd_clk
add wave -position end  sim:/tb_dc_fifo/rd_en
add wave -position end  sim:/tb_dc_fifo/dout
add wave -position end  sim:/tb_dc_fifo/dout2
add wave -position end  sim:/tb_dc_fifo/valid
add wave -position end  sim:/tb_dc_fifo/valid2
add wave -position end  sim:/tb_dc_fifo/empty
add wave -position end  sim:/tb_dc_fifo/empty2

add wave -position end  sim:/tb_dc_fifo/uut/rdcnt_wr
add wave -position end  sim:/tb_dc_fifo/uut/wrcnt

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


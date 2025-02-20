onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /address_generator_tb/dut/clk
add wave -noupdate /address_generator_tb/dut/rstn
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/size_x
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/size_y
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/w_m0_dist
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/dut/line_length_iact
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/dut/line_length_psum
add wave -noupdate -expand -group generics -radix unsigned /address_generator_tb/dut/line_length_wght
add wave -noupdate -expand -group I/O /address_generator_tb/dut/i_start
add wave -noupdate -expand -group I/O /address_generator_tb/dut/i_fifo_full_iact
add wave -noupdate -expand -group I/O /address_generator_tb/dut/i_fifo_full_wght
add wave -noupdate -expand -group I/O -radix unsigned -childformat {{/address_generator_tb/dut/o_address_iact(0) -radix unsigned} {/address_generator_tb/dut/o_address_iact(1) -radix unsigned} {/address_generator_tb/dut/o_address_iact(2) -radix unsigned} {/address_generator_tb/dut/o_address_iact(3) -radix unsigned} {/address_generator_tb/dut/o_address_iact(4) -radix unsigned} {/address_generator_tb/dut/o_address_iact(5) -radix unsigned} {/address_generator_tb/dut/o_address_iact(6) -radix unsigned} {/address_generator_tb/dut/o_address_iact(7) -radix unsigned} {/address_generator_tb/dut/o_address_iact(8) -radix unsigned}} -expand -subitemconfig {/address_generator_tb/dut/o_address_iact(0) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(1) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(2) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(3) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(4) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(5) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(6) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(7) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_iact(8) {-height 16 -radix unsigned}} /address_generator_tb/dut/o_address_iact
add wave -noupdate -expand -group I/O -radix symbolic /address_generator_tb/dut/o_address_iact_valid
add wave -noupdate -expand -group I/O -radix unsigned -childformat {{/address_generator_tb/dut/o_address_wght(0) -radix unsigned} {/address_generator_tb/dut/o_address_wght(1) -radix unsigned} {/address_generator_tb/dut/o_address_wght(2) -radix unsigned} {/address_generator_tb/dut/o_address_wght(3) -radix unsigned} {/address_generator_tb/dut/o_address_wght(4) -radix unsigned}} -subitemconfig {/address_generator_tb/dut/o_address_wght(0) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_wght(1) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_wght(2) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_wght(3) {-height 16 -radix unsigned} /address_generator_tb/dut/o_address_wght(4) {-height 16 -radix unsigned}} /address_generator_tb/dut/o_address_wght
add wave -noupdate -expand -group I/O -radix symbolic /address_generator_tb/dut/o_address_wght_valid
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_iact_words
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_iact_count_words
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_iact_cur_base_valid
add wave -noupdate -expand -group internal -radix unsigned -childformat {{/address_generator_tb/dut/r_iact_cur_base(0) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(1) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(2) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(3) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(4) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(5) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(6) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(7) -radix unsigned} {/address_generator_tb/dut/r_iact_cur_base(8) -radix unsigned}} -subitemconfig {/address_generator_tb/dut/r_iact_cur_base(0) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(1) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(2) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(3) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(4) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(5) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(6) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(7) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_cur_base(8) {-height 16 -radix unsigned}} /address_generator_tb/dut/r_iact_cur_base
add wave -noupdate -expand -group internal -radix symbolic /address_generator_tb/dut/r_iact_next_used
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_iact_next_valid
add wave -noupdate -expand -group internal -radix unsigned -childformat {{/address_generator_tb/dut/r_iact_next_base(0) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(1) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(2) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(3) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(4) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(5) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(6) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(7) -radix unsigned} {/address_generator_tb/dut/r_iact_next_base(8) -radix unsigned}} -subitemconfig {/address_generator_tb/dut/r_iact_next_base(0) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(1) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(2) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(3) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(4) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(5) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(6) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(7) {-height 16 -radix unsigned} /address_generator_tb/dut/r_iact_next_base(8) {-height 16 -radix unsigned}} /address_generator_tb/dut/r_iact_next_base
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_iact_next_words
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_w1_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_c0_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_c1_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_h2_iact
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_data_valid_iact
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_delay_iact_valid
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_iact_done
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_index_c_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_index_c_last_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_index_h_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_last_c1_iact
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_last_h2_iact
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_wght_done
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_c0_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_c1_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_h2_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_count_w1_wght
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_data_valid_wght
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_delay_wght_valid
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_index_c_last_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_index_c_wght
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_index_x_wght
add wave -noupdate -expand -group internal /address_generator_tb/dut/r_index_y_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_last_c1_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_last_h2_wght
add wave -noupdate -expand -group internal -radix unsigned /address_generator_tb/dut/r_offset_c_wght
add wave -noupdate -expand -group {tb mem read} -radix symbolic /address_generator_tb/fifo_empty
add wave -noupdate -expand -group {tb mem read} -radix symbolic /address_generator_tb/fifo_rd
add wave -noupdate -expand -group {tb mem read} /address_generator_tb/fifo_rd_delay
add wave -noupdate -expand -group {tb mem read} -radix unsigned /address_generator_tb/fifo_dout
add wave -noupdate -expand -group {tb mem read} /address_generator_tb/mem_rsh_en
add wave -noupdate -expand -group {tb mem read} -radix unsigned /address_generator_tb/mem_rsh_addr
add wave -noupdate -expand -group {tb mem read} /address_generator_tb/mem_rsh_dout
add wave -noupdate -expand -group {tb mem read} /address_generator_tb/row_read
add wave -noupdate -expand -group verify /address_generator_tb/mem_rsh_en_delay
add wave -noupdate -expand -group verify /address_generator_tb/row_read_delay
add wave -noupdate -expand -group verify -radix unsigned -childformat {{/address_generator_tb/verify/c0_cnt(0) -radix unsigned} {/address_generator_tb/verify/c0_cnt(1) -radix unsigned} {/address_generator_tb/verify/c0_cnt(2) -radix unsigned} {/address_generator_tb/verify/c0_cnt(3) -radix unsigned} {/address_generator_tb/verify/c0_cnt(4) -radix unsigned} {/address_generator_tb/verify/c0_cnt(5) -radix unsigned} {/address_generator_tb/verify/c0_cnt(6) -radix unsigned} {/address_generator_tb/verify/c0_cnt(7) -radix unsigned} {/address_generator_tb/verify/c0_cnt(8) -radix unsigned}} -subitemconfig {/address_generator_tb/verify/c0_cnt(0) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(1) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(2) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(3) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(4) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(5) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(6) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(7) {-height 16 -radix unsigned} /address_generator_tb/verify/c0_cnt(8) {-height 16 -radix unsigned}} /address_generator_tb/verify/c0_cnt
add wave -noupdate -expand -group verify -radix unsigned /address_generator_tb/verify/expect
add wave -noupdate -expand -group verify -radix unsigned /address_generator_tb/verify/row
add wave -noupdate -expand -group verify -radix unsigned /address_generator_tb/verify/tmp
add wave -noupdate -expand -group verify -radix unsigned -childformat {{/address_generator_tb/verify/w1_cnt(0) -radix unsigned} {/address_generator_tb/verify/w1_cnt(1) -radix unsigned} {/address_generator_tb/verify/w1_cnt(2) -radix unsigned} {/address_generator_tb/verify/w1_cnt(3) -radix unsigned} {/address_generator_tb/verify/w1_cnt(4) -radix unsigned} {/address_generator_tb/verify/w1_cnt(5) -radix unsigned} {/address_generator_tb/verify/w1_cnt(6) -radix unsigned} {/address_generator_tb/verify/w1_cnt(7) -radix unsigned} {/address_generator_tb/verify/w1_cnt(8) -radix unsigned}} -expand -subitemconfig {/address_generator_tb/verify/w1_cnt(0) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(1) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(2) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(3) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(4) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(5) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(6) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(7) {-height 16 -radix unsigned} /address_generator_tb/verify/w1_cnt(8) {-height 16 -radix unsigned}} /address_generator_tb/verify/w1_cnt
add wave -noupdate -expand -group verify -radix unsigned -childformat {{/address_generator_tb/verify/row_cnt(0) -radix unsigned} {/address_generator_tb/verify/row_cnt(1) -radix unsigned} {/address_generator_tb/verify/row_cnt(2) -radix unsigned} {/address_generator_tb/verify/row_cnt(3) -radix unsigned} {/address_generator_tb/verify/row_cnt(4) -radix unsigned} {/address_generator_tb/verify/row_cnt(5) -radix unsigned} {/address_generator_tb/verify/row_cnt(6) -radix unsigned} {/address_generator_tb/verify/row_cnt(7) -radix unsigned} {/address_generator_tb/verify/row_cnt(8) -radix unsigned}} -subitemconfig {/address_generator_tb/verify/row_cnt(0) {-radix unsigned} /address_generator_tb/verify/row_cnt(1) {-radix unsigned} /address_generator_tb/verify/row_cnt(2) {-radix unsigned} /address_generator_tb/verify/row_cnt(3) {-radix unsigned} /address_generator_tb/verify/row_cnt(4) {-radix unsigned} /address_generator_tb/verify/row_cnt(5) {-radix unsigned} /address_generator_tb/verify/row_cnt(6) {-radix unsigned} /address_generator_tb/verify/row_cnt(7) {-radix unsigned} /address_generator_tb/verify/row_cnt(8) {-radix unsigned}} /address_generator_tb/verify/row_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
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
WaveRestoreZoom {0 ns} {97860 ns}

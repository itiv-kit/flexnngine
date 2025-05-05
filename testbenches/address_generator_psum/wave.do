onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/addr_width
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/data_width
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/image_width
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/kernel_count
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/kernel_size
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/size_x
add wave -noupdate -group {generics & params} -radix unsigned /address_generator_psum_tb/size_y
add wave -noupdate -group {generics & params} /address_generator_psum_tb/dut/i_params
add wave -noupdate /address_generator_psum_tb/clk
add wave -noupdate /address_generator_psum_tb/rstn
add wave -noupdate -expand -group I/O -radix unsigned /address_generator_psum_tb/dut/i_start
add wave -noupdate -expand -group I/O /address_generator_psum_tb/i_dataflow
add wave -noupdate -expand -group I/O -radix unsigned /address_generator_psum_tb/dut/i_valid_psum_out
add wave -noupdate -expand -group I/O -radix unsigned /address_generator_psum_tb/dut/o_address_psum
add wave -noupdate -expand -group I/O /address_generator_psum_tb/dut/o_suppress_out
add wave -noupdate -expand -group internal /address_generator_psum_tb/dut/r_start_delay
add wave -noupdate -expand -group internal /address_generator_psum_tb/dut/w_start_event
add wave -noupdate -expand -group internal /address_generator_psum_tb/dut/r_init
add wave -noupdate -expand -group internal -radix unsigned /address_generator_psum_tb/dut/r_count_h2
add wave -noupdate -expand -group internal -radix unsigned /address_generator_psum_tb/dut/r_count_m0
add wave -noupdate -expand -group internal -radix symbolic /address_generator_psum_tb/dut/r_done
add wave -noupdate -expand -group internal -radix unsigned -childformat {{/address_generator_psum_tb/dut/r_next_address(0) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(1) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(2) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(3) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(4) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(5) -radix unsigned} {/address_generator_psum_tb/dut/r_next_address(6) -radix unsigned}} -expand -subitemconfig {/address_generator_psum_tb/dut/r_next_address(0) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(1) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(2) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(3) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(4) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(5) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_next_address(6) {-height 16 -radix unsigned}} /address_generator_psum_tb/dut/r_next_address
add wave -noupdate -expand -group internal -radix symbolic /address_generator_psum_tb/dut/r_next_address_valid
add wave -noupdate -expand -group internal -radix unsigned /address_generator_psum_tb/dut/r_count_w1
add wave -noupdate -expand -group internal -radix unsigned -childformat {{/address_generator_psum_tb/dut/r_address_psum(0) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(1) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(2) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(3) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(4) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(5) -radix unsigned} {/address_generator_psum_tb/dut/r_address_psum(6) -radix unsigned}} -expand -subitemconfig {/address_generator_psum_tb/dut/r_address_psum(0) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(1) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(2) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(3) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(4) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(5) {-height 16 -radix unsigned} /address_generator_psum_tb/dut/r_address_psum(6) {-height 16 -radix unsigned}} /address_generator_psum_tb/dut/r_address_psum
add wave -noupdate -expand -group internal /address_generator_psum_tb/dut/r_suppress_next_col
add wave -noupdate -expand -group internal /address_generator_psum_tb/dut/r_suppress_next_row
add wave -noupdate -expand -group mem /address_generator_psum_tb/mem/wena
add wave -noupdate -expand -group mem -radix unsigned /address_generator_psum_tb/mem/addra
add wave -noupdate -expand -group mem -radix unsigned /address_generator_psum_tb/mem/dina
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
WaveRestoreZoom {0 ns} {568 ns}

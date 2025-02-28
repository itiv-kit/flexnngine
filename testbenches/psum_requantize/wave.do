onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /psum_requantize_tb/dut/clk
add wave -noupdate /psum_requantize_tb/dut/rstn
add wave -noupdate -group generics /psum_requantize_tb/dut/data_width_iact
add wave -noupdate -group generics /psum_requantize_tb/dut/data_width_psum
add wave -noupdate -group generics /psum_requantize_tb/dut/pipeline_length
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/i_params
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/i_data_valid
add wave -noupdate -expand -group I/O -radix decimal /psum_requantize_tb/dut/i_data
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/o_data_valid
add wave -noupdate -expand -group I/O -radix decimal /psum_requantize_tb/dut/o_data
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/o_data_halfword
add wave -noupdate -expand -group internal -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(0).data -radix float32}}} {/psum_requantize_tb/dut/pipe(1) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(1).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(1).data -radix float32}}} {/psum_requantize_tb/dut/pipe(2) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(2).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(2).data -radix float32}}} {/psum_requantize_tb/dut/pipe(3) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(3).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(3).data -radix float32}}}} -expand -subitemconfig {/psum_requantize_tb/dut/pipe(0) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(0).data -radix float32}} -expand} /psum_requantize_tb/dut/pipe(0).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(0).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(1) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(1).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(1).data -radix float32}} -expand} /psum_requantize_tb/dut/pipe(1).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(1).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(2) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(2).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(2).data -radix float32}} -expand} /psum_requantize_tb/dut/pipe(2).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(2).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(3) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(3).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(3).data -radix float32}} -expand} /psum_requantize_tb/dut/pipe(3).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(3).data {-height 16 -radix float32}} /psum_requantize_tb/dut/pipe
add wave -noupdate -expand -group internal -radix float32 /psum_requantize_tb/dut/scale
add wave -noupdate -expand -group internal -radix float32 /psum_requantize_tb/dut/zeropoint
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {240 ns} 0}
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

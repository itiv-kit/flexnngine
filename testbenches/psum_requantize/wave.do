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
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/i_channel
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/i_data_last
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/o_channel
add wave -noupdate -expand -group I/O /psum_requantize_tb/dut/o_data_last
add wave -noupdate -expand -group internal -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(0).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).data -radix float32} {/psum_requantize_tb/dut/pipe(0).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).zeropt -radix hexadecimal}}} {/psum_requantize_tb/dut/pipe(1) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(1).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(1).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).data -radix float32} {/psum_requantize_tb/dut/pipe(1).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).zeropt -radix hexadecimal}}} {/psum_requantize_tb/dut/pipe(2) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(2).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(2).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).data -radix float32} {/psum_requantize_tb/dut/pipe(2).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).zeropt -radix hexadecimal}}} {/psum_requantize_tb/dut/pipe(3) -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(3).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(3).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).data -radix float32} {/psum_requantize_tb/dut/pipe(3).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).zeropt -radix hexadecimal}}} {/psum_requantize_tb/dut/pipe(4) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(5) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(6) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(7) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(8) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(9) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(10) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(11) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(12) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(13) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(14) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(15) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(16) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(17) -radix hexadecimal} {/psum_requantize_tb/dut/pipe(18) -radix hexadecimal}} -subitemconfig {/psum_requantize_tb/dut/pipe(0) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(0).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(0).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).data -radix float32} {/psum_requantize_tb/dut/pipe(0).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(0).zeropt -radix hexadecimal}} -expand} /psum_requantize_tb/dut/pipe(0).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(0).last {-radix hexadecimal} /psum_requantize_tb/dut/pipe(0).och {-radix hexadecimal} /psum_requantize_tb/dut/pipe(0).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(0).scale {-radix hexadecimal} /psum_requantize_tb/dut/pipe(0).zeropt {-radix hexadecimal} /psum_requantize_tb/dut/pipe(1) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(1).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(1).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).data -radix float32} {/psum_requantize_tb/dut/pipe(1).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(1).zeropt -radix hexadecimal}} -expand} /psum_requantize_tb/dut/pipe(1).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(1).last {-radix hexadecimal} /psum_requantize_tb/dut/pipe(1).och {-radix hexadecimal} /psum_requantize_tb/dut/pipe(1).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(1).scale {-radix hexadecimal} /psum_requantize_tb/dut/pipe(1).zeropt {-radix hexadecimal} /psum_requantize_tb/dut/pipe(2) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(2).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(2).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).data -radix float32} {/psum_requantize_tb/dut/pipe(2).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(2).zeropt -radix hexadecimal}} -expand} /psum_requantize_tb/dut/pipe(2).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(2).last {-radix hexadecimal} /psum_requantize_tb/dut/pipe(2).och {-radix hexadecimal} /psum_requantize_tb/dut/pipe(2).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(2).scale {-radix hexadecimal} /psum_requantize_tb/dut/pipe(2).zeropt {-radix hexadecimal} /psum_requantize_tb/dut/pipe(3) {-height 16 -radix hexadecimal -childformat {{/psum_requantize_tb/dut/pipe(3).valid -radix symbolic} {/psum_requantize_tb/dut/pipe(3).last -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).och -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).data -radix float32} {/psum_requantize_tb/dut/pipe(3).scale -radix hexadecimal} {/psum_requantize_tb/dut/pipe(3).zeropt -radix hexadecimal}} -expand} /psum_requantize_tb/dut/pipe(3).valid {-height 16 -radix symbolic} /psum_requantize_tb/dut/pipe(3).last {-radix hexadecimal} /psum_requantize_tb/dut/pipe(3).och {-radix hexadecimal} /psum_requantize_tb/dut/pipe(3).data {-height 16 -radix float32} /psum_requantize_tb/dut/pipe(3).scale {-radix hexadecimal} /psum_requantize_tb/dut/pipe(3).zeropt {-radix hexadecimal} /psum_requantize_tb/dut/pipe(4) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(5) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(6) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(7) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(8) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(9) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(10) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(11) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(12) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(13) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(14) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(15) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(16) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(17) {-radix hexadecimal} /psum_requantize_tb/dut/pipe(18) {-radix hexadecimal}} /psum_requantize_tb/dut/pipe
add wave -noupdate -expand -group internal -radix float32 /psum_requantize_tb/dut/scale
add wave -noupdate -expand -group internal -radix float32 /psum_requantize_tb/dut/zeropoint
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_input
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_input_last
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_input_och
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_input_valid
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_output
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_output_last
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_output_och
add wave -noupdate -expand -group internal /psum_requantize_tb/dut/w_output_valid
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
WaveRestoreZoom {0 ns} {1800 ns}

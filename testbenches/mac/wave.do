onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mac_tb/clk
add wave -noupdate /mac_tb/rstn
add wave -noupdate /mac_tb/en
add wave -noupdate -radix decimal /mac_tb/data_in_a
add wave -noupdate -radix decimal /mac_tb/data_in_w
add wave -noupdate -radix decimal /mac_tb/data_in_acc
add wave -noupdate /mac_tb/result_valid
add wave -noupdate -radix decimal /mac_tb/result
add wave -noupdate -expand -group mult /mac_tb/uut/mult_inst/i_en
add wave -noupdate -expand -group mult -radix decimal /mac_tb/uut/mult_inst/i_data_a
add wave -noupdate -expand -group mult -radix decimal /mac_tb/uut/mult_inst/i_data_b
add wave -noupdate -expand -group mult -radix decimal /mac_tb/uut/mult_inst/o_result
add wave -noupdate -expand -group mult /mac_tb/uut/mult_inst/o_result_valid
add wave -noupdate -expand -group acc /mac_tb/uut/acc_inst/i_en
add wave -noupdate -expand -group acc -radix decimal /mac_tb/uut/acc_inst/i_data_a
add wave -noupdate -expand -group acc -radix decimal /mac_tb/uut/acc_inst/i_data_b
add wave -noupdate -expand -group acc -radix decimal /mac_tb/uut/acc_inst/w_result
add wave -noupdate -expand -group acc -radix decimal /mac_tb/uut/acc_inst/o_result
add wave -noupdate -expand -group acc /mac_tb/uut/acc_inst/o_result_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ns} {900 ns}

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/clk_sp
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/rstn
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/start

add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_tiles_y
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_tiles_x
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_tiles_c
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_commands_per_tile
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_commands_last_tile_c
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/c_per_tile
add wave -noupdate -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/c_last_tile

add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/fifo_full_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/address_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/address_iact_valid(0)
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_wght_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact_valid
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_iact_address_f


add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/clk
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/clk_sp
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact_valid
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_iact_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/w_buffer_full_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_buffer_full_iact
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/dout_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/valid_iact_address_f
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/gnt_iact_binary
add wave -noupdate -expand -group Address_Generator -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_iact_f


add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/fifo_full_wght
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/address_wght
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/address_wght_valid(0)
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght_valid
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/clk
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/clk_sp
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght_valid
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/dout_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/valid_wght_address_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/gnt_wght_binary
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_wght_f
add wave -noupdate -expand -group Address_Generator_wght -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_wght_f


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


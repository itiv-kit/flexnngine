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

add wave -noupdate -expand -group PE_array -radix unsigned /control_conv_tb/accelerator_inst/o_buffer_full_iact

add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_iact
add wave -noupdate -expand -group IACT_INPUT -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/data_iact_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/i_data_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/i_data_iact_valid(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/o_buffer_full_iact
add wave -noupdate -expand -group IACT_INPUT -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/fill_count


add wave -noupdate -expand -group Scratchpad -radix unsigned /control_conv_tb/accelerator_inst/dout_iact
add wave -noupdate -expand -group Scratchpad -radix unsigned /control_conv_tb/accelerator_inst/dout_iact_valid
add wave -noupdate -expand -group Scratchpad -radix unsigned /control_conv_tb/accelerator_inst/read_en_iact
add wave -noupdate -expand -group Scratchpad -radix unsigned /control_conv_tb/accelerator_inst/read_adr_iact
add wave -noupdate -expand -group Scratchpad -radix unsigned /control_conv_tb/accelerator_inst/dout_wght
#add wave -noupdate -expand -group Scratchpad -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_iact/ram_instance
#add wave -noupdate -expand -group Scratchpad -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_wght/ram_instance

add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact_valid
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/dout_iact_address_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/valid_iact_address_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_iact_address_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_address_iact
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_address_iact_valid
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/gnt_iact_binary_d
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/sel_iact_fifo
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact_valid
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_iact_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_iact_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_iact_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/dout_iact_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/valid_iact_f
add wave -noupdate -expand -group Iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_iact_address_f

add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght_valid
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_address_wght
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_address_wght_valid
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/gnt_wght_binary_d
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/sel_wght_fifo
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_wght
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_wght_valid
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_wght_f
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_wght_f
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rd_en_wght_f
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/dout_wght_f
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/valid_wght_f
add wave -noupdate -expand -group Wght_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/empty_wght_address_f


add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(1)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(2)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(3)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(4)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(5)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(6)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(7)/FIFO_iact_address/full
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/din
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/wr_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/rd_en
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/dout
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/valid
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/empty
add wave -noupdate -group IACT_ADR_FIFOS -expand -group FIFO_iact_address_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(8)/FIFO_iact_address/full

add wave -noupdate -group IACT_FIFOS -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/sel_iact_fifo
add wave -noupdate -group IACT_FIFOS -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/gnt_iact_binary
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_0 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(0)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_1 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(1)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_2 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(2)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_3 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(3)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_4 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(4)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_5 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(5)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_6 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(6)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_7 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(7)/FIFO_iact/full
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/din
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/wr_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/rd_en
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/dout
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/valid
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/empty
add wave -noupdate -group IACT_FIFOS -expand -group FIFO_iact_8 -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact(8)/FIFO_iact/full

add wave -noupdate -expand -group FIFOS_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/full_iact_address_f
add wave -noupdate -expand -group FIFOS_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_fifo_iact_address_full



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


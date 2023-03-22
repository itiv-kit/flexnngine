onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /control_conv_tb/rstn

add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/start
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/r_state
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/r_start_init_control
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/w_status_control
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/r_start_adr
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/w_status_if
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/r_start_control
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/r_done_wght
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/r_done_iact
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/i_enable
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_address_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_address_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_address_f
add wave -noupdate -expand -group Start -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_address_f

add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/control_inst/r_h2
#add wave -noupdate -expand -group Control_static -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_tiles_y_last_tile_rows
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/control_inst/r_w1
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/control_inst/r_c1
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/control_inst/r_c0w0
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/control_inst/r_c0w0_last_c1
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/w_c0
add wave -noupdate -expand -group Control_static -radix unsigned  /control_conv_tb/accelerator_inst/w_c0_last_c1

add wave -noupdate -expand -group Scratchpad -radix unsigned  /control_conv_tb/accelerator_inst/w_dout_iact
add wave -noupdate -expand -group Scratchpad -radix unsigned  /control_conv_tb/accelerator_inst/w_dout_iact_valid
add wave -noupdate -expand -group Scratchpad -radix unsigned  /control_conv_tb/accelerator_inst/w_read_en_iact
add wave -noupdate -expand -group Scratchpad -radix unsigned  /control_conv_tb/accelerator_inst/w_dout_wght
#add wave -noupdate -expand -group Scratchpad -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_iact/ram_instance
#add wave -noupdate -expand -group Scratchpad -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_wght/ram_instance

add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/din
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/dout
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/valid
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/empty
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out_valid(0)
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out(0)
add wave -noupdate -expand -group FIFO_iact -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_dout_iact_f(0)

add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/din
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/dout
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/valid
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/empty
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/FIFO_iact_address(0)/FIFO_iact_address/full
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_address_f
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_address_f
add wave -noupdate -expand -group FIFO_iact_address -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_fifo_iact_address_full

add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_iact/addra
add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_iact/addrb
add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_wght/addra
add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_wght/addrb
add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_psum/addra
add wave -noupdate -expand -group RAM_ADR -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_psum/addrb


add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_address_iact_valid
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/o_address_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_C0_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_c0_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_W1
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_w1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_C1
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_c1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_H2
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_h2_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_offset_mem_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_last_c1_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_last_h2_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_index_c_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_index_c_last_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_data_valid_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_iact_done
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_address_iact_valid(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/w_buffer_full_iact
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/w_data_iact_valid(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/w_data_iact(0)
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/i_start
add wave -noupdate -expand -group ADR_iact -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/i_fifo_full_iact

add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_C0_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_c0_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_W1
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_w1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_C1
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_c1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_H2
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_count_h2_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_last_c1_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_offset_c_last_h2_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_index_c_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_index_c_last_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_data_valid_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/r_wght_done
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/w_address_wght_valid(0)
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/w_buffer_full_wght
add wave -noupdate -expand -group ADR_wght -radix unsigned /control_conv_tb/accelerator_inst/address_generator_inst/i_start

add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_psums
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_psums_valid
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum_binary
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_empty_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_data_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_write_en_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_valid_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_valid_psum_out
add wave -noupdate -expand -group PSUM_OUTPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_psum_out_f
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/r_address_psum
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/i_empty_psum_fifo
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_psum_done
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/r_address_offsets_count_x
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/address_generator_psum_inst/i_start
add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/w_write_adr_psum
#add wave -noupdate -expand -group PSUM_OUTPUT -radix unsigned /control_conv_tb/accelerator_inst/scratchpad_inst/ram_dp_psum/ram_instance

add wave -noupdate -expand -group {PE arr outputs} -radix signed /control_conv_tb/accelerator_inst/pe_array_inst/o_psums
add wave -noupdate -expand -group {PE arr outputs} -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/o_psums_valid

add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
#add wave -noupdate -expand -group WGHT_INPUT -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght_valid
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group WGHT_INPUT -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_wght(0)
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_wght_valid(0)
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_buffer_full_wght
add wave -noupdate -expand -group WGHT_INPUT -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_wght
add wave -noupdate -expand -group WGHT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_wght_valid

add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact
add wave -noupdate -expand -group IACT_INPUT -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_data_iact_valid(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/i_data_iact_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out_valid(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/r_sel_iact_fifo
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_iact/i_req
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_iact/o_gnt
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_almost_full_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/o_data_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_f(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_buffer_full_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/w_buffer_full_next_iact(0)
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data_valid
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full_next
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_update_offset
add wave -noupdate -expand -group IACT_INPUT -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_count_c0w0
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_count_c1
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_count_w1
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_count_h2
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_incr_w1
add wave -noupdate -expand -group Control -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_state

add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_command_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_iact(0)
add wave -noupdate -expand -group {iact commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_update_offset_iact(0)

add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_command_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_wght(0)
add wave -noupdate -expand -group {wght commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_update_offset_wght(0)

add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_command_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_psum_d(0)
add wave -noupdate -expand -group {psum commands} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_update_offset_psum_d(0)

add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/accelerator_inst/control_inst/r_command
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/accelerator_inst/control_inst/r_command_iact
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_iact
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/accelerator_inst/control_inst/r_command_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_psum
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_update_offset_psum
add wave -noupdate -expand -group {Outputs} -radix symbolic /control_conv_tb/accelerator_inst/control_inst/r_command_wght
add wave -noupdate -expand -group {Outputs} -radix unsigned /control_conv_tb/accelerator_inst/control_inst/r_read_offset_wght

add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(1)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(2)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(3)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -expand -group Fill_Counts -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_read_offset

add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/w_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/i_preload_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_enable
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_mult
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_mult_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_acc_out_valid

#
#
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/i_data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_1_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_2_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_mult
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/w_data_mult_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_enable
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/i_data_in_valid_chg
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_3_0 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_4_0 -radix decimal  /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(4)/pe_inst_x(0)/pe_south/pe_inst/line_buffer_wght/i_command

add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_data_in_psum_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/r_sel_mult_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_update_offset_psum
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_out
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in1
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in2
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in1_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix unsigned /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/w_data_acc_in2_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_update_val
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_update_offset
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/i_command
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_psum/r_fill_count
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/i_data_in_iact
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_data
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_data_valid
add wave -noupdate -expand -group RAM_internal -expand -group PE_0_4 -radix decimal /control_conv_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(4)/pe_north/pe_inst/line_buffer_wght/i_command



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


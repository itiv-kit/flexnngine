delete wave *

onerror {resume}
quietly WaveActivateNextPane {} 0
quietly set size_x 7
quietly set size_y 10

add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /functional_tb/rstn
add wave -noupdate -group Testbench -radix unsigned /functional_tb/params

add wave -noupdate -group Start -radix symbolic /functional_tb/accelerator_inst/i_start
add wave -noupdate -group Start -radix symbolic /functional_tb/accelerator_inst/o_done
add wave -noupdate -group Start -radix unsigned /functional_tb/accelerator_inst/o_status
add wave -noupdate -group Start -radix symbolic -label "control i_start"               /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/i_start
add wave -noupdate -group Start -radix symbolic -label "control o_init_done"           /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_init_done
add wave -noupdate -group Start -radix symbolic -label "control i_enable_if"           /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/i_enable_if
add wave -noupdate -group Start -radix symbolic -label "control o_enable"              /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_enable
add wave -noupdate -group Start -radix symbolic -label "addrgen i_start"               /functional_tb/accelerator_inst/control_address_generator_inst/w_control_init_done
add wave -noupdate -group Start -radix symbolic -label "spadif i_start"                /functional_tb/accelerator_inst/scratchpad_interface_inst/i_start
add wave -noupdate -group Start -radix symbolic -label "spadif o_enable"               /functional_tb/accelerator_inst/scratchpad_interface_inst/o_enable
add wave -noupdate -group Start -radix symbolic -label "spadif r_preload_fifos_done"   /functional_tb/accelerator_inst/scratchpad_interface_inst/r_preload_fifos_done
add wave -noupdate -group Start -radix symbolic -label "spadif r_done_wght"            /functional_tb/accelerator_inst/scratchpad_interface_inst/r_done_wght
add wave -noupdate -group Start -radix symbolic -label "spadif r_done_iact"            /functional_tb/accelerator_inst/scratchpad_interface_inst/r_done_iact
add wave -noupdate -group Start -radix symbolic -label "spadif w_empty_iact_f"         /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_full_iact_f"          /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_empty_wght_f"         /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_full_wght_f"          /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_empty_iact_address_f" /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_address_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_full_iact_address_f"  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_address_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_empty_wght_address_f" /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_address_f
add wave -noupdate -group Start -radix symbolic -label "spadif w_full_wght_address_f"  /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_address_f

# unpacked signals of psum write data
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(63 downto 56)} din_psum_byte7
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(55 downto 48)} din_psum_byte6
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(47 downto 40)} din_psum_byte5
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(39 downto 32)} din_psum_byte4
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(31 downto 24)} din_psum_byte3
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(23 downto 16)} din_psum_byte2
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum(15 downto  8)} din_psum_byte1
quietly virtual signal -install /functional_tb/accelerator_inst/scratchpad_inst { /functional_tb/accelerator_inst/scratchpad_inst/din_psum( 7 downto  0)} din_psum_byte0

add wave -noupdate -group Scratchpad -radix symbolic    /functional_tb/accelerator_inst/scratchpad_inst/read_en
add wave -noupdate -group Scratchpad -radix unsigned    /functional_tb/accelerator_inst/scratchpad_inst/read_adr
add wave -noupdate -group Scratchpad -radix unsigned    /functional_tb/accelerator_inst/scratchpad_inst/dout_valid
add wave -noupdate -group Scratchpad -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_inst/dout
add wave -noupdate -group Scratchpad -radix symbolic    /functional_tb/accelerator_inst/scratchpad_inst/write_en_psum
add wave -noupdate -group Scratchpad -radix unsigned    /functional_tb/accelerator_inst/scratchpad_inst/write_adr_psum
add wave -noupdate -group Scratchpad -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte7
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte6
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte5
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte4
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte3
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte2
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte1
add wave -noupdate -expand -group Scratchpad -radix decimal /functional_tb/accelerator_inst/scratchpad_inst/din_psum_byte0

add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out_valid
add wave -noupdate -group FIFO_iact -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data
add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_f
add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_f
add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_f
add wave -noupdate -group FIFO_iact -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/w_dout_iact_f
add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f
add wave -noupdate -group FIFO_iact -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_almost_full_iact_f
for {set x 0} {$x < 6} {incr x} {
    set ser_path "/functional_tb/accelerator_inst/scratchpad_interface_inst/pe_arr_iact(${x})/serializer_inst"
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix symbolic    $ser_path/i_valid
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix hexadecimal $ser_path/i_data
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix symbolic    $ser_path/o_ready
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix symbolic    $ser_path/i_ready
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix decimal     $ser_path/o_data
    add wave -noupdate -group FIFO_iact -group serializer${x} -radix symbolic    $ser_path/o_valid
}
# add wave -noupdate -group FIFO_iact -label wrcnt0 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/wrcnt
# add wave -noupdate -group FIFO_iact -label rdcnt0 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(0)/fifo_iact/rdcnt
# add wave -noupdate -group FIFO_iact -label wrcnt1 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(1)/fifo_iact/wrcnt
# add wave -noupdate -group FIFO_iact -label rdcnt1 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(1)/fifo_iact/rdcnt
# add wave -noupdate -group FIFO_iact -label wrcnt2 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(2)/fifo_iact/wrcnt
# add wave -noupdate -group FIFO_iact -label rdcnt2 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(2)/fifo_iact/rdcnt
# add wave -noupdate -group FIFO_iact -label wrcnt3 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(3)/fifo_iact/wrcnt
# add wave -noupdate -group FIFO_iact -label rdcnt3 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_iact(3)/fifo_iact/rdcnt

add wave -noupdate -group FIFO_iact_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact_valid
add wave -noupdate -group FIFO_iact_address -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/i_address_iact
add wave -noupdate -group FIFO_iact_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_address_f
add wave -noupdate -group FIFO_iact_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_address_f
add wave -noupdate -group FIFO_iact_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_address_f
add wave -noupdate -group FIFO_iact_address -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_dout_iact_address_f
add wave -noupdate -group FIFO_iact_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_address_f
# add wave -noupdate -group FIFO_iact_address -label wrcnt0 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(0)/fifo_iact_address/wrcnt
# add wave -noupdate -group FIFO_iact_address -label rdcnt0 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(0)/fifo_iact_address/rdcnt
# add wave -noupdate -group FIFO_iact_address -label wrcnt1 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(1)/fifo_iact_address/wrcnt
# add wave -noupdate -group FIFO_iact_address -label rdcnt1 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(1)/fifo_iact_address/rdcnt
# add wave -noupdate -group FIFO_iact_address -label wrcnt2 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(2)/fifo_iact_address/wrcnt
# add wave -noupdate -group FIFO_iact_address -label rdcnt2 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(2)/fifo_iact_address/rdcnt
# add wave -noupdate -group FIFO_iact_address -label wrcnt3 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(3)/fifo_iact_address/wrcnt
# add wave -noupdate -group FIFO_iact_address -label rdcnt3 -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/gen_fifo_iact_address(3)/fifo_iact_address/rdcnt

add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_f
add wave -noupdate -group FIFO_wght -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data
add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_demux_wght_out_valid
add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_f
add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_wght_f
add wave -noupdate -group FIFO_wght -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/w_dout_wght_f
add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/r_sel_load_fifo
add wave -noupdate -group FIFO_wght -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/i_buffer_full_wght
for {set x 0} {$x < 6} {incr x} {
    set ser_path "/functional_tb/accelerator_inst/scratchpad_interface_inst/pe_arr_wght(${x})/serializer_inst"
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix symbolic    $ser_path/i_valid
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix hexadecimal $ser_path/i_data
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix symbolic    $ser_path/o_ready
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix symbolic    $ser_path/i_ready
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix decimal     $ser_path/o_data
    add wave -noupdate -group FIFO_wght -group serializer${x} -radix symbolic    $ser_path/o_valid
}

add wave -noupdate -group FIFO_wght_address -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght
add wave -noupdate -group FIFO_wght_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_address_wght_valid
add wave -noupdate -group FIFO_wght_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_wght_address_f
add wave -noupdate -group FIFO_wght_address -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_dout_wght_address_f
add wave -noupdate -group FIFO_wght_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_wght_address_f
add wave -noupdate -group FIFO_wght_address -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_wght_address_f

quietly set addr_gen_path "/functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_iact_inst"
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/i_start
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/i_fifo_full_iact
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/o_address_iact
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/o_address_iact_valid
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_words
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_count_words
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_cur_base_valid
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_cur_base
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_next_used
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_next_valid
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_next_base
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_next_words
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_count_w1
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_count_c1
add wave -noupdate -group ADR_iact -radix unsigned ${addr_gen_path}/r_count_h2
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_next_base_last
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_cur_base_last
add wave -noupdate -group ADR_iact -radix symbolic ${addr_gen_path}/r_done

quietly set addr_gen_path "/functional_tb/accelerator_inst/control_address_generator_inst/g_address_generator/address_generator_wght_inst"
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/i_start
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/i_fifo_full_wght
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/o_address_wght
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/o_address_wght_valid
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_words
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_count_words
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_next_words
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_next_valid
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_next_used
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_next_base
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_cur_base_valid
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_cur_base
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_count_s
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_count_c1
add wave -noupdate -group ADR_wght -radix unsigned ${addr_gen_path}/r_count_h2
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_next_base_last
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_cur_base_last
add wave -noupdate -group ADR_wght -radix symbolic ${addr_gen_path}/r_done

add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/i_start
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/i_valid_psum_out
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_start_event
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_chunk_size
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_count_w1
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_count_m0
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_count_h2
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_address_psum
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_suppress_next_row
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/r_suppress_next_col
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/o_suppress_out
add wave -noupdate -group PSUM_OUTPUT -group addrgen -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/address_generator_psum_inst/o_address_psum

add wave -noupdate -group PSUM_OUTPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums
add wave -noupdate -group PSUM_OUTPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums_valid
add wave -noupdate -group PSUM_OUTPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums_last
add wave -noupdate -group PSUM_OUTPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psums_halfword
add wave -noupdate -group PSUM_OUTPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/i_psum_suppress
add wave -noupdate -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/i_address_psum
add wave -noupdate -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_address
add wave -noupdate -group PSUM_OUTPUT -radix unsigned /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_offset

add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_wr_en_psum_f
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_wide_valid
add wave -noupdate -group PSUM_OUTPUT -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_wide_data
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_wide_valid_raw
add wave -noupdate -group PSUM_OUTPUT -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_wide_data_raw
add wave -noupdate -group PSUM_OUTPUT -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/w_din_psum_f
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_psum_f
add wave -noupdate -group PSUM_OUTPUT -radix unsigned    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum_idx
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_psum
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_psum_f
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/w_psum_valid_out
add wave -noupdate -group PSUM_OUTPUT -radix symbolic    /functional_tb/accelerator_inst/scratchpad_interface_inst/o_write_en_psum
add wave -noupdate -group PSUM_OUTPUT -radix hexadecimal /functional_tb/accelerator_inst/scratchpad_interface_inst/o_data_psum
for {set x 0} {$x < $size_x} {incr x} {
    quietly set para_path "/functional_tb/accelerator_inst/scratchpad_interface_inst/fifo_psum_out(${x})/psum_parallel_raw"
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix decimal     ${para_path}/i_data
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix binary      ${para_path}/i_last
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix binary      ${para_path}/i_valid
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix hexadecimal ${para_path}/o_data
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix binary      ${para_path}/o_valid
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix unsigned    ${para_path}/i_offset
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix unsigned    ${para_path}/counter
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix symbolic    ${para_path}/idle
    add wave -noupdate -group PSUM_OUTPUT -group "para${x}" -radix symbolic    ${para_path}/valid_words
}

add wave -noupdate -group Postprocessing -radix unsigned /functional_tb/accelerator_inst/postproc_inst/r_count_w1
add wave -noupdate -group Postprocessing -radix unsigned /functional_tb/accelerator_inst/postproc_inst/r_current_channel
add wave -noupdate -group Postprocessing -radix symbolic /functional_tb/accelerator_inst/postproc_inst/w_psums_bias_valid
add wave -noupdate -group Postprocessing -radix symbolic /functional_tb/accelerator_inst/postproc_inst/w_psums_bias_last
add wave -noupdate -group Postprocessing -radix decimal  /functional_tb/accelerator_inst/postproc_inst/w_psums_bias
add wave -noupdate -group Postprocessing -radix decimal  /functional_tb/accelerator_inst/postproc_inst/gen_postproc/psum_output(0)/bias_inst/w_bias_in
add wave -noupdate -group Postprocessing -radix symbolic /functional_tb/accelerator_inst/postproc_inst/w_psums_act_valid
add wave -noupdate -group Postprocessing -radix symbolic /functional_tb/accelerator_inst/postproc_inst/w_psums_act_last
add wave -noupdate -group Postprocessing -radix decimal  /functional_tb/accelerator_inst/postproc_inst/w_psums_act
add wave -noupdate -group Postprocessing -radix float32  /functional_tb/accelerator_inst/postproc_inst/gen_postproc/psum_output(0)/requantize_inst/scale
add wave -noupdate -group Postprocessing -radix float32  /functional_tb/accelerator_inst/postproc_inst/gen_postproc/psum_output(0)/requantize_inst/zeropoint

add wave -noupdate -group {PE arr outputs} -radix signed   /functional_tb/accelerator_inst/pe_array_inst/o_psums
add wave -noupdate -group {PE arr outputs} -radix binary   /functional_tb/accelerator_inst/pe_array_inst/o_psums_valid
add wave -noupdate -group {PE arr outputs} -radix signed   /functional_tb/accelerator_inst/pe_array_inst/w_data_out
add wave -noupdate -group {PE arr outputs} -radix binary   /functional_tb/accelerator_inst/pe_array_inst/w_data_out_valid

add wave -noupdate -group WGHT_INPUT -radix decimal -label "PE_0_0 lb wght ram" /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -group WGHT_INPUT -radix decimal -label "PE_1_0 lb wght ram" /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(1)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -group WGHT_INPUT -radix decimal -label "PE_2_0 lb wght ram" /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(2)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -group WGHT_INPUT -radix decimal -label "PE_3_0 lb wght ram" /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(3)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_wght/ram/ram_instance
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_wght_valid
add wave -noupdate -group WGHT_INPUT -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_command
add wave -noupdate -group WGHT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/i_read_offset
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght(0)
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght_valid(0)
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_buffer_full_wght
add wave -noupdate -group WGHT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_wght/r_fill_count
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght
add wave -noupdate -group WGHT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_wght_valid

add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_iact(0)
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/w_data_iact_valid(0)
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data_valid
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/i_data
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_demux_iact_out_valid(0)
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/r_sel_load_fifo
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_load/i_req
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/rr_arbiter_load/o_gnt
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_full_iact_f(0)
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_almost_full_iact_f(0)
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/o_data_iact(0)
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_f(0)
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_f(0)
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/rstn
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_almost_full_iact_f
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_gnt_iact
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_dout_iact_address_f
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/o_address
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/w_buffer_full_iact
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/w_buffer_full_next_iact
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_rd_en_iact_f
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_empty_iact_f
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/scratchpad_interface_inst/w_valid_iact_f
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/scratchpad_interface_inst/o_data_iact
add wave -noupdate -group IACT_INPUT -group lb_col0 -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -group IACT_INPUT -group lb_col0 -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data_valid
add wave -noupdate -group IACT_INPUT -group lb_col0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data
for {set y 1} {$y < 5} {incr y} {
    add wave -noupdate -group IACT_INPUT -group lb_col0 -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y($y)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/r_fill_count
    add wave -noupdate -group IACT_INPUT -group lb_col0 -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y($y)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_data_valid
    add wave -noupdate -group IACT_INPUT -group lb_col0 -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y($y)/pe_inst_x(0)/pe_middle/pe_inst/line_buffer_iact/i_data
}

add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact
add wave -noupdate -group IACT_INPUT -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/w_data_iact_valid
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/r_fill_count
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_data_valid
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/o_buffer_full_next
add wave -noupdate -group IACT_INPUT -radix symbolic /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_command
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_read_offset
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/i_update_offset
add wave -noupdate -group IACT_INPUT -radix decimal  /functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(0)/pe_inst_x(0)/pe_north/pe_inst/line_buffer_iact/ram/ram_instance

add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/i_start
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/i_enable_if
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/i_all_psum_finished
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_init_done
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_enable
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/o_pause_iact
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_state
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_c0w0
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_c1
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_w1
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_count_h2
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_incr_w1
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/w_output_sequence
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command
add wave -noupdate -group Control -radix symbolic /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_command_psum
add wave -noupdate -group Control -radix unsigned /functional_tb/accelerator_inst/control_address_generator_inst/g_control/control_inst/r_m0_dist

add wave -noupdate -group {iact commands} -radix symbolic /functional_tb/accelerator_inst/w_command_iact(0)
add wave -noupdate -group {iact commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_iact(0)
add wave -noupdate -group {iact commands} -radix unsigned /functional_tb/accelerator_inst/w_update_offset_iact(0)

add wave -noupdate -group {wght commands} -radix symbolic /functional_tb/accelerator_inst/w_command_wght(0)
add wave -noupdate -group {wght commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_wght(0)
add wave -noupdate -group {wght commands} -radix unsigned /functional_tb/accelerator_inst/w_update_offset_wght(0)

add wave -noupdate -group {psum commands} -radix symbolic /functional_tb/accelerator_inst/w_command_psum(0)
add wave -noupdate -group {psum commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_psum(0)
add wave -noupdate -group {psum commands} -radix unsigned /functional_tb/accelerator_inst/w_update_offset_psum(0)

add wave -noupdate -group {Full control commands} -radix symbolic /functional_tb/accelerator_inst/w_command
add wave -noupdate -group {Full control commands} -radix symbolic /functional_tb/accelerator_inst/w_command_iact
add wave -noupdate -group {Full control commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_iact
add wave -noupdate -group {Full control commands} -radix symbolic /functional_tb/accelerator_inst/w_command_psum
add wave -noupdate -group {Full control commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_psum
add wave -noupdate -group {Full control commands} -radix unsigned /functional_tb/accelerator_inst/w_update_offset_psum
add wave -noupdate -group {Full control commands} -radix symbolic /functional_tb/accelerator_inst/w_command_wght
add wave -noupdate -group {Full control commands} -radix unsigned /functional_tb/accelerator_inst/w_read_offset_wght

proc get_pe_path {x y} {
    global size_y
    if {$y > 0} {
        if {$y == $size_y-1} {
            set pe_name "pe_south"
        } else {
            set pe_name "pe_middle"
        }
    } else {
        set pe_name "pe_north"
    }
    return "/functional_tb/accelerator_inst/pe_array_inst/pe_inst_y(${y})/pe_inst_x(${x})/${pe_name}/pe_inst"
}

# line buffer fill counts
for {set y 0} {$y < 5} {incr y} {
    set pe_path [get_pe_path 0 $y]
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_${y}_0 iact r_fill_count"  ${pe_path}/line_buffer_iact/r_fill_count
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_${y}_0 iact i_read_offset" ${pe_path}/line_buffer_iact/i_read_offset
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_${y}_0 wght r_fill_count"  ${pe_path}/line_buffer_wght/r_fill_count
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_${y}_0 wght i_read_offset" ${pe_path}/line_buffer_wght/i_read_offset
}
for {set x 1} {$x < 5} {incr x} {
    set pe_path [get_pe_path $x 0]
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_0_${x} iact r_fill_count"  ${pe_path}/line_buffer_iact/r_fill_count
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_0_${x} iact i_read_offset" ${pe_path}/line_buffer_iact/i_read_offset
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_0_${x} wght r_fill_count"  ${pe_path}/line_buffer_wght/r_fill_count
    add wave -noupdate -group Fill_Counts -radix unsigned -label "PE_0_${x} wght i_read_offset" ${pe_path}/line_buffer_wght/i_read_offset
}

# line buffer memory i/o of individual PEs
add wave -noupdate -group PEs -radix unsigned /functional_tb/accelerator_inst/w_update_offset_psum
add wave -noupdate -group PEs -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/i_update_offset_psum
add wave -noupdate -group PEs -radix unsigned /functional_tb/accelerator_inst/pe_array_inst/i_preload_psum_valid
for {set y 0} {$y < $size_y} {incr y} {
    set group "PE_${y}_0"
    set pe_path [get_pe_path 0 $y]
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/i_command
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_mult_psum
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_conv_gemm
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_iact_input
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/i_data_in_psum_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/i_update_offset_psum
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_iact
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_wght
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_in1
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_in2
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_out
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_acc_in1_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_acc_in2_valid
    add wave -noupdate -group PEs -group $group -group lb_iact -radix symbolic ${pe_path}/i_command_iact
    add wave -noupdate -group PEs -group $group -group lb_iact -radix unsigned ${pe_path}/i_read_offset_iact
    add wave -noupdate -group PEs -group $group -group lb_iact -radix symbolic ${pe_path}/w_data_in_iact_valid
    add wave -noupdate -group PEs -group $group -group lb_iact -radix decimal  ${pe_path}/w_data_in_iact
    add wave -noupdate -group PEs -group $group -group lb_iact -radix decimal  ${pe_path}/line_buffer_iact/ram/ram_instance
    add wave -noupdate -group PEs -group $group -group lb_wght -radix symbolic ${pe_path}/i_command_wght
    add wave -noupdate -group PEs -group $group -group lb_wght -radix unsigned ${pe_path}/i_read_offset_wght
    add wave -noupdate -group PEs -group $group -group lb_wght -radix symbolic ${pe_path}/i_data_in_wght_valid
    add wave -noupdate -group PEs -group $group -group lb_wght -radix decimal  ${pe_path}/i_data_in_wght
    add wave -noupdate -group PEs -group $group -group lb_wght -radix decimal  ${pe_path}/line_buffer_wght/ram/ram_instance
    add wave -noupdate -group PEs -group $group -group lb_psum -radix symbolic ${pe_path}/i_command_psum
    add wave -noupdate -group PEs -group $group -group lb_psum -radix decimal  ${pe_path}/line_buffer_psum/i_update_val
    add wave -noupdate -group PEs -group $group -group lb_psum -radix unsigned ${pe_path}/i_update_offset_psum
    add wave -noupdate -group PEs -group $group -group lb_psum -radix unsigned ${pe_path}/line_buffer_psum/r_fill_count
    add wave -noupdate -group PEs -group $group -group lb_psum -radix decimal  ${pe_path}/line_buffer_psum/ram/ram_instance
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out_valid
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out_iact_valid
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out_iact
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out_wght_valid
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/o_data_out_wght
}

for {set y 0} {$y < $size_y} {incr y} {
    set group "PE_${y}_0"
    set pe_path [get_pe_path 0 $y]
    add wave -noupdate -group {PE outputs} -label "$group data_out_valid" -radix decimal  ${pe_path}/o_data_out_valid
    add wave -noupdate -group {PE outputs} -label "$group data_out" -radix decimal  ${pe_path}/o_data_out
}

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 220
configure wave -valuecolwidth 150
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

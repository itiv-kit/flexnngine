delete wave *

onerror {resume}
quietly WaveActivateNextPane {} 0

quietly set size_x 3
quietly set size_y 3

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
    return "/pe_array_conv_3x3_tb/pe_array_inst/pe_inst_y(${y})/pe_inst_x(${x})/${pe_name}/pe_inst"
}

add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_3x3_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_3x3_tb/rstn
add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_3x3_tb/s_done

add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_tb/i_data_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_tb/i_data_iact_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_tb/i_data_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_tb/i_data_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_tb/i_preload_psum
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_tb/i_preload_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix unsigned /pe_array_conv_3x3_tb/i_data_wght
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_3x3_tb/i_data_wght_valid

add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_array_conv_3x3_tb/command_iact
add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_array_conv_3x3_tb/command_psum
add wave -noupdate -expand -group {Line_Buffer Command in} -radix unsigned /pe_array_conv_3x3_tb/command_wght

set pe_path [get_pe_path 0 0]
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_iact/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_iact/o_data_valid
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_psum/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_psum/o_data_valid
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_wght/o_data
add wave -noupdate -expand -group {Line_Buffer Data out} -radix unsigned ${pe_path}/line_buffer_wght/o_data_valid

add wave -noupdate -expand -group Pe_output -radix unsigned /pe_array_conv_3x3_tb/o_psums
add wave -noupdate -expand -group Pe_output -radix unsigned /pe_array_conv_3x3_tb/o_psums_valid

for {set x 0} {$x < $size_x} {incr x} {
for {set y 0} {$y < $size_y} {incr y} {
    set group "PE_${y}_${x}"
    set pe_path [get_pe_path $x $y]
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/i_command
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_mult_psum
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_conv_gemm
    add wave -noupdate -group PEs -group $group -radix symbolic  ${pe_path}/r_sel_iact_input
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/i_data_in_psum_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/i_update_offset_psum
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_demux_input_psum
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_iact
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_wght
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_mult
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_in1
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_in2
    add wave -noupdate -group PEs -group $group -radix decimal  ${pe_path}/w_data_acc_out
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_acc_in1_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_acc_in2_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_acc_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_iact_wght_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_iact_valid
    add wave -noupdate -group PEs -group $group -radix unsigned ${pe_path}/w_data_wght_valid
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
}}

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 207
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
WaveRestoreZoom {0 ns} {750 ns}


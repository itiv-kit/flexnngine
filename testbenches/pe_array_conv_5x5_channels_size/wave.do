delete wave *

onerror {resume}
quietly WaveActivateNextPane {} 0

quietly set size_x 5
quietly set size_y 5
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
    return "/pe_array_conv_5x5_channels_tb/pe_array_inst/pe_inst_y(${y})/pe_inst_x(${x})/${pe_name}/pe_inst"
}

add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_5x5_channels_tb/clk
add wave -noupdate -expand -group Testbench -radix unsigned /pe_array_conv_5x5_channels_tb/rstn
add wave -noupdate -expand -group Testbench -radix decimal /pe_array_conv_5x5_channels_tb/s_input_image
add wave -noupdate -expand -group Testbench -radix decimal /pe_array_conv_5x5_channels_tb/s_expected_output

add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/i_data_iact_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix decimal  /pe_array_conv_5x5_channels_tb/i_data_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/o_buffer_full_iact
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/i_data_wght_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix decimal  /pe_array_conv_5x5_channels_tb/i_data_wght
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/o_buffer_full_wght

add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/s_x
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/s_y
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/s_done
add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/stimuli_data_iact/loop_max

add wave -noupdate -expand -group {Line_Buffer Data in} -radix symbolic /pe_array_conv_5x5_channels_tb/i_preload_psum_valid
add wave -noupdate -expand -group {Line_Buffer Data in} -radix decimal  /pe_array_conv_5x5_channels_tb/i_preload_psum

for {set y 0} {$y < 3} {incr y} {
    set label "PE_${y}_0"
    set pe_path [get_pe_path 0 $y]
    add wave -noupdate -expand -group {Commands} -radix symbolic -label "${label} i_command_iact"       ${pe_path}/i_command_iact
    add wave -noupdate -expand -group {Commands} -radix unsigned -label "${label} i_read_offset_iact"   ${pe_path}/i_read_offset_iact
    add wave -noupdate -expand -group {Commands} -radix symbolic -label "${label} i_command_psum"       ${pe_path}/i_command_psum
    add wave -noupdate -expand -group {Commands} -radix unsigned -label "${label} i_read_offset_psum"   ${pe_path}/i_read_offset_psum
    add wave -noupdate -expand -group {Commands} -radix unsigned -label "${label} i_update_offset_psum" ${pe_path}/i_update_offset_psum
}

add wave -noupdate -expand -group Pe_output -radix decimal  /pe_array_conv_5x5_channels_tb/s_tile_done
add wave -noupdate -expand -group Pe_output -radix decimal  /pe_array_conv_5x5_channels_tb/o_psums_valid
add wave -noupdate -expand -group Pe_output -radix decimal  /pe_array_conv_5x5_channels_tb/o_psums
add wave -noupdate -expand -group Pe_output -radix symbolic /pe_array_conv_5x5_channels_tb/o_buffer_full_psum

for {set y 0} {$y < $size_y} {incr y} {
    set group "PE_${y}_0"
    set pe_path [get_pe_path 0 $y]
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/i_data_in_psum_valid
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/r_sel_mult_psum
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/i_update_offset_psum
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/w_data_acc_out
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/w_data_acc_in1
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/w_data_acc_in2
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/w_data_acc_in1_valid
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/w_data_acc_in2_valid
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/line_buffer_psum/i_update_val
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/line_buffer_psum/i_update_offset
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/line_buffer_psum/ram/ram_instance
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix unsigned ${pe_path}/line_buffer_psum/r_fill_count
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/i_data_in_iact
    add wave -noupdate -expand -group RAM_internal -expand -group ${group} -radix decimal  ${pe_path}/line_buffer_iact/ram/ram_instance
}

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


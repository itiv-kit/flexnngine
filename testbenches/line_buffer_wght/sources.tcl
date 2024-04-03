# design
vcom -64 -2008 -work accel \
    "${HDL_DIR}/ram_dp.vhd" \
    "${HDL_DIR}/utilities.vhd" \
    "${HDL_DIR}/line_buffer.vhd"

# testbench
vcom -64 -2008 -work accel \
    "${TB_DIR}/src/line_buffer_wght_tb.vhd"

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "line_buffer_wght_tb"


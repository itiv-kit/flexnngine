# design
vcom -2008 -work accel ../../hdl/utilities.vhd
vcom -2008 -work accel ../../hdl/psum_requantize.vhd

# testbench
vcom -2008 -work accel src/psum_requantize_tb.vhd

set SIM_TIME "15 us"
set SIM_TOP_LEVEL "accel.psum_requantize_tb"

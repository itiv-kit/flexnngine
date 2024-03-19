# design
vcom -2008 -work accel ../../hdl/utilities.vhd
vcom -2008 -work accel ../../hdl/mux.vhd
vcom -2008 -work accel ../../hdl/ram_dp.vhd
vcom -2008 -work accel ../../hdl/address_generator_psum.vhd

# testbench
vcom -2008 -work accel src/address_generator_psum_tb.vhd

set SIM_TIME "15 us"
set SIM_TOP_LEVEL "accel.address_generator_psum_tb"

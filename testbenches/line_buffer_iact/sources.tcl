# design
vcom ../../hdl/ram_dp.vhd
vcom ../../hdl/utilities.vhd
vcom ../../hdl/line_buffer.vhd

# testbench
vcom src/line_buffer_iact_tb.vhd

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "line_buffer_iact_tb"

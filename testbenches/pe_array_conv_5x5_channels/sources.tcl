# design
vcom ../../hdl/utilities.vhd
vcom ../../hdl/ram_dp.vhd
vcom ../../hdl/line_buffer.vhd
vcom ../../hdl/mult.vhd
vcom ../../hdl/acc.vhd
vcom ../../hdl/mux.vhd
vcom ../../hdl/pe.vhd
vcom ../../hdl/pe_array.vhd

# testbench
vcom src/pe_array_conv_5x5_channels_tb.vhd

set SIM_TIME "25 us"
set SIM_TOP_LEVEL "pe_array_conv_5x5_channels_tb"


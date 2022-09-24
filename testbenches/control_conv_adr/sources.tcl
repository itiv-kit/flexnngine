# design
vcom ../../hdl/utilities.vhd
vcom ../../hdl/ram_dp.vhd
vcom ../../hdl/line_buffer.vhd
vcom ../../hdl/mult.vhd
vcom ../../hdl/acc.vhd
vcom ../../hdl/mux.vhd
vcom ../../hdl/demux.vhd
vcom ../../hdl/address_generator.vhd
vcom ../../hdl/control.vhd
vcom ../../hdl/pe.vhd
vcom ../../hdl/pe_array.vhd

# testbench
vcom src/control_conv_tb.vhd

set SIM_TIME "10 ms"
set SIM_TOP_LEVEL "control_conv_tb"


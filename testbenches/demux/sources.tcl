# design
vcom ../../hdl/utilities.vhd
vcom ../../hdl/ram_dp.vhd
vcom ../../hdl/line_buffer.vhd
vcom ../../hdl/mult.vhd
vcom ../../hdl/acc.vhd
vcom ../../hdl/mux.vhd
vcom ../../hdl/demux.vhd
vcom ../../hdl/pe.vhd

# testbench
vcom src/demux_tb.vhd

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "demux_tb"


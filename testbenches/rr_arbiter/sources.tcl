# design
vcom ../../hdl/utilities.vhd
vcom ../../hdl/ram_dp.vhd
vcom ../../hdl/line_buffer.vhd
vcom ../../hdl/mult.vhd
vcom ../../hdl/acc.vhd
vcom ../../hdl/mux.vhd
vcom ../../hdl/demux.vhd
vcom ../../hdl/pe.vhd
vcom ../../hdl/rr_arbiter.vhd
vcom ../../hdl/onehot_binary.vhd

# testbench
vcom src/rr_arbiter_tb.vhd

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "rr_arbiter_tb"


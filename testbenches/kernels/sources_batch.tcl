#ip
#vcom -64 -2008 -work xil_defaultlib  \
#"../../../../reconfigurable-accelerator/reconfigurable-accelerator.gen/sources_1/ip/fifo_generator_0/fifo_generator_0_sim_netlist.vhdl" \
#"../../../../reconfigurable-accelerator/reconfigurable-accelerator.gen/sources_1/ip/mult_gen_0/mult_gen_0_sim_netlist.vhdl" \

#design
vcom -64 -2008 -work xil_defaultlib  \
"../../../../hdl/acc.vhd" \
"../../../../hdl/utilities.vhd" \
"../../../../hdl/address_generator.vhd" \
"../../../../hdl/address_generator_psum.vhd" \
"../../../../hdl/control.vhd" \
"../../../../hdl/pe_array.vhd" \
"../../../../hdl/demux.vhd" \
"../../../../hdl/line_buffer.vhd" \
"../../../../hdl/mult.vhd" \
"../../../../hdl/mux.vhd" \
"../../../../hdl/pe.vhd" \
"../../../../hdl/gray.vhd" \
"../../../../hdl/sync.vhd" \
"../../../../hdl/fifos.vhd" \
"../../../../hdl/ram_dp.vhd" \
"../../../../hdl/accelerator.vhd" \
"../../../../hdl/scratchpad.vhd" \
"../../../../hdl/scratchpad_interface.vhd" \
"../../../../hdl/rr_arbiter.vhd" \
"../../../../hdl/onehot_binary.vhd" \


# testbench
vcom -64 -2008 -work xil_defaultlib  \
"../../src/kernels_tb.vhd" \

set SIM_TIME "10 ms"
set SIM_TOP_LEVEL "kernels_tb"


set generics $::env(generics)

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "psum_requantize_tb"
set SIM_UNIT_NAMES [list utilities psum_requantize]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

# map floating_point ip library & compile ip core (only required if use_float_ip is used)
set simlib /home/ad9150/misc/simlib_2024.2_questa_2023.4
set float32_mac_ip /home/ad9150/cecas/flexnngine-zynq/flexnngine-zynq.gen/sources_1/ip/float32_mac
vmap unisim $simlib/unisim
vmap floating_point_v7_1_19 $simlib/floating_point_v7_1_19
vcom -64 -2008 -work work $float32_mac_ip/float32_mac_sim_netlist.vhdl

source "${TB_DIR}/../common/functions.tcl"
sim_generic

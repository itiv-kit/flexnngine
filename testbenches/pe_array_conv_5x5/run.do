set SIM_TIME "10 us"
set SIM_TOP_LEVEL "pe_array_conv_5x5_tb"
set SIM_UNIT_NAMES [list utilities ram_dp line_buffer mult acc mux demux pe pe_array]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "rr_arbiter_tb"
#set SIM_UNIT_NAMES [list utilities ram_dp line_buffer mult acc mux demux pe rr_arbiter onehot_binary]
set SIM_UNIT_NAMES [list rr_arbiter onehot_binary]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

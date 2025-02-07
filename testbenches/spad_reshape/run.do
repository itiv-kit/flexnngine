set SIM_TIME "4 us"
set SIM_TOP_LEVEL "spad_reshape_tb"
set SIM_UNIT_NAMES [list utilities ram_dp_bwe spad_reshape]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

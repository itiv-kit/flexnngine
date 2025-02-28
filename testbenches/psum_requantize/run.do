set SIM_TIME "1 us"
set SIM_TOP_LEVEL "psum_requantize_tb"
set SIM_UNIT_NAMES [list utilities psum_requantize]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

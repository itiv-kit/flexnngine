set SIM_TIME "100 ns"
set SIM_TOP_LEVEL "reformatter_tb"
set SIM_UNIT_NAMES [list utilities ram_dp_bwe ram_mw mux reformatter]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

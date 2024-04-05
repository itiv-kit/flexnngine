set SIM_TIME "1000 ns"
set SIM_TOP_LEVEL "mac_tb"
set SIM_UNIT_NAMES [list mac]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

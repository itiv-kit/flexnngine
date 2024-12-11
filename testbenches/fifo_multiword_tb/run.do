set SIM_TIME "10 us"
set SIM_TOP_LEVEL "fifo_multiword_tb"
set SIM_UNIT_NAMES [list utilities gray sync fifos]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

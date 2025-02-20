set SIM_TIME "150 us"
set SIM_TOP_LEVEL "address_generator_tb"
set SIM_UNIT_NAMES [list utilities gray sync fifos ram_dp_bwe spad_reshape address_generator_iact]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

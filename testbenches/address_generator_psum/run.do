set SIM_TIME "15 us"
set SIM_TOP_LEVEL "address_generator_psum_tb"
set SIM_UNIT_NAMES [list utilities mux ram_dp address_generator_psum]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

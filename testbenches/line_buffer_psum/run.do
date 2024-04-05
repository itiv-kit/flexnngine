set SIM_TIME "10 us"
set SIM_TOP_LEVEL "line_buffer_psum_tb"
set SIM_UNIT_NAMES [list ram_dp utilities line_buffer]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

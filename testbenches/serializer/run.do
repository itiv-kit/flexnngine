set SIM_TIME "1500 ns"
set SIM_TOP_LEVEL "serializer_tb"
set SIM_UNIT_NAMES [list serializer]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

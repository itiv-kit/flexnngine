###
###
###

file mkdir "_run"
transcript file "_run/transcript.txt"
transcript on

###
### create libraries
###

vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib


###
### compile sources
###

source sources.tcl

###
### Optimize design
###

vopt -64 +acc -L xil_defaultlib -work xil_defaultlib xil_defaultlib.$SIM_TOP_LEVEL -o design_optimized

###
### initialize and run simulation
###
vsim -onfinish stop xil_defaultlib.design_optimized

#vsim -onfinish stop -voptargs="+acc" $SIM_TOP_LEVEL

#source wave.do
source wave_control_adr.do

run $SIM_TIME


#####

set SIM_TIME "10 us"
set SIM_TOP_LEVEL "control_conv_tb"
set SIM_UNIT_NAMES [list utilities ram_dp line_buffer mult acc mux demux pe pe_array]
set TB_DIR [file normalize "."]
set RUN_DIR $TB_DIR

source "${TB_DIR}/../common/functions.tcl"
sim_generic

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

source sources_batch.tcl

###
### Optimize design
###

vopt {*}$generics -64 +acc -L xil_defaultlib -L secureip -work xil_defaultlib xil_defaultlib.$SIM_TOP_LEVEL -o design_optimized

###
### initialize and run simulation
###
vsim -onfinish stop xil_defaultlib.design_optimized

#vsim -onfinish stop -voptargs="+acc" $SIM_TOP_LEVEL

#source wave.do
#source wave_control_adr.do

run $SIM_TIME

exit
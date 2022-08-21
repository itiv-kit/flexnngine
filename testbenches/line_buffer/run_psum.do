###
###
###

file mkdir "_run"
transcript file "_run/transcript.txt"
transcript on

###
###
###

set axi_filter_dma_v1_00_a _run/work

###
### create libraries
###

vlib $axi_filter_dma_v1_00_a
vmap axi_filter_dma_v1_00_a $axi_filter_dma_v1_00_a

###
### compile sources
###

source sources_psum.tcl

# initialize and run simulation
vsim -onfinish stop -voptargs="+acc" $SIM_TOP_LEVEL
source wave_psum.do

run $SIM_TIME


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

source sources.tcl

# initialize and run simulation
vsim -voptargs="+acc" $SIM_TOP_LEVEL
source wave.do

run $SIM_TIME


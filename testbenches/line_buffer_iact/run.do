set TB_DIR [file normalize "."]
set HDL_DIR [file normalize "${TB_DIR}/../../hdl"]

file mkdir "_run/work" "_run/accel"

transcript file "_run/transcript.txt"
transcript on

### create libraries
vlib _run/work
vlib _run/accel
vmap work _run/work
vmap accel _run/accel

### compile sources
source "${TB_DIR}/sources.tcl"

# initialize and run simulation
vsim -64 -onfinish stop -voptargs="+acc" accel.$SIM_TOP_LEVEL
source "${TB_DIR}/wave.do"

run $SIM_TIME

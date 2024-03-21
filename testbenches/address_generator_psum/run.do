file mkdir "_run"
transcript file "_run/transcript.txt"
transcript on

vlib _run/work
vmap work _run/work

vlib _run/accel
vmap accel _run/accel

source sources.tcl

vsim -onfinish stop -voptargs="+acc" $SIM_TOP_LEVEL
source wave.do

run -all

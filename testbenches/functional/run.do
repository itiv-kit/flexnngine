if { $::argc > 2 } {
    echo "Usage: do run.do \[wave\]"
    echo "Compile sources and run the simulation."
    echo "Load wave_<wave>.do if exists, otherwise default to wave.do"
    return
}

if { $::argc > 1 } {
    set WAVE ${1}
}

if { ! [info exists env(LAUNCH_GUI)] } {
    set GUI 1
} else {
    set GUI $env(LAUNCH_GUI)
}

if { ! [info exists env(TB_DIR)] } {
    if {[file exists "../../run.do"]} {
        set TB_DIR [file dirname [file normalize "../../run.do"]]
    } else {
        set TB_DIR [file dirname [file normalize "."]]
    }
} else {
    set TB_DIR $env(TB_DIR)
}
set HDL_DIR [file normalize "${TB_DIR}/../../hdl"]

if { [info exists env(GENERICS)] } {
    set generics $::env(GENERICS)
} else {
    set generics [list]
}

echo "using base dir ${TB_DIR}"
echo "using hdl dir ${HDL_DIR}"

file mkdir "_run/work" "_run/accel"

if { ! $GUI } {
    transcript file "_run/transcript.txt"
    transcript on
}

### create libraries
vlib _run/work
vlib _run/accel
vmap work _run/work
vmap accel _run/accel

### compile sources
source "${TB_DIR}/sources.tcl"

### Optimize design
vopt {*}$generics -64 +acc -L accel -work accel accel.$SIM_TOP_LEVEL -o design_optimized

### initialize and run simulation
vsim -onfinish stop accel.design_optimized

if { $GUI } {
    # load waveform from "wave_<NAME>.do" if it exists
    set wave_filename "${TB_DIR}/wave.do"
    if { [info exists WAVE] && [file exists ${wave_filename}]} {
        set wave_filename "${TB_DIR}/wave_${WAVE}.do"
    }
    if { ! [info exists WAVE] || $WAVE != "none" } {
        do ${wave_filename}
    }
}

set StdArithNoWarnings 1
set NumericStdNoWarnings 1

run $SIM_TIME

if { ! $GUI } {
    exit
}

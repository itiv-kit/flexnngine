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
    quietly set GUI 1
} else {
    quietly set GUI $env(LAUNCH_GUI)
}

if { [info exists env(GENERICS)] } {
    quietly set generics $::env(GENERICS)
} else {
    quietly set generics [list]
}

quietly set SIM_TIME "-all"
quietly set SIM_TOP_LEVEL "functional_tb"
quietly set RUN_DIR [file normalize "."]

if { [info exists env(TB_DIR)] } {
    set TB_DIR $env(TB_DIR)
} else {
    # set TB_DIR [file dirname [info script]]
    # since questa does not support [info script] properly, search for run.do manually
    set CANDIDATE "run.do"
    for {set i 0} {$i < 5} {incr i} {
        if {[file exists "$CANDIDATE"]} {
            set TB_DIR [file dirname [file normalize "$CANDIDATE"]]
            break
        } else {
            set CANDIDATE "../${CANDIDATE}"
        }
    }
}
source "${TB_DIR}/../common/functions.tcl"

setup_generic "$TB_DIR" "$RUN_DIR"

### compile all sources to the default library
compile_sources

### compile the testbench to the default library as well
compile_vhdl_sources $DEFAULT_LIBRARY [list "${TB_DIR}/src/${SIM_TOP_LEVEL}.vhd"]

### Optimize design
vopt {*}$generics -64 +acc $DEFAULT_LIBRARY.$SIM_TOP_LEVEL -work $DEFAULT_LIBRARY -o ${SIM_TOP_LEVEL}_optimized

### initialize and run simulation
vsim -64 -onfinish stop $DEFAULT_LIBRARY.${SIM_TOP_LEVEL}_optimized

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

quietly set StdArithNoWarnings 1
quietly set NumericStdNoWarnings 1

run $SIM_TIME

if { ! $GUI } {
    quit
}

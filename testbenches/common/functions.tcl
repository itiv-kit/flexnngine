###
### helper functions
###

proc set_default_options {} {
    global COMPILE_OPTIONS
    global SIMULATE_OPTIONS
    global DEFAULT_LIBRARY

    set COMPILE_OPTIONS "-64 -2008"
    set SIMULATE_OPTIONS "-64 -onfinish stop -voptargs=\"+acc\""
    set DEFAULT_LIBRARY "accel"
}

proc setup_libraries {lib_dir} {
    vlib "${lib_dir}/_run/work"
    vlib "${lib_dir}/_run/accel"
    vmap work "${lib_dir}/_run/work"
    vmap accel "${lib_dir}/_run/accel"
}

proc compile_vhdl_sources {library file_names} {
    global COMPILE_OPTIONS
    vcom {*}$COMPILE_OPTIONS -work $library {*}[join $file_names]
}

###
### functions to call from testbench scripts
###

proc setup_generic {tb_dir run_dir} {
    set_default_options

    set HDL_DIR [file normalize "${tb_dir}/../../hdl"]
    source "${tb_dir}/../common/file_list.tcl"

    file mkdir "${run_dir}/_run/work" "${run_dir}/_run/accel"

    # enable transcript if running headless / in batch mode

    global GUI
    if { ! [info exists GUI] || ! $GUI } {
        transcript file "${run_dir}/_run/transcript.txt"
        transcript on
    }

    # setup libraries in the run directory by default
    setup_libraries "${run_dir}"
}

proc compile_sources {{unit_names {}} {library ""}} {
    global HDL_FILE_NAMES
    global COMPILE_OPTIONS
    global DEFAULT_LIBRARY

    set file_names [list]
    if {[llength $unit_names]} {
        foreach file $HDL_FILE_NAMES {
            set unit [file rootname [file tail "$file"]]
            if {[lsearch -exact $unit_names $unit] >= 0} {
                # echo "Adding file $file"
                lappend file_names "$file"
            }
        }
    } else {
        # echo "Compiling all sources"
        set file_names $HDL_FILE_NAMES
    }

    if {$library eq ""} {
        set library $DEFAULT_LIBRARY
    }

    compile_vhdl_sources $library $file_names
}

proc run_generic {top_level sim_time {wave ""}} {
    global SIMULATE_OPTIONS
    global DEFAULT_LIBRARY

    # quietly set StdArithNoWarnings 1
    # quietly set NumericStdNoWarnings 1

    # initialize and run simulation
    vsim {*}$SIMULATE_OPTIONS ${DEFAULT_LIBRARY}.$top_level

    if { $wave != "" } {
        # "do" instead of "source" ignores errors
        do "$wave"
    }

    run $sim_time
}

proc sim_generic {} {
    global TB_DIR
    global RUN_DIR
    global SIM_UNIT_NAMES
    global DEFAULT_LIBRARY
    global SIM_TOP_LEVEL
    global SIM_TIME

    setup_generic "$TB_DIR" "$RUN_DIR"

    ### compile all sources to the default library
    compile_sources $SIM_UNIT_NAMES

    ### compile the testbench to the default library as well
    compile_vhdl_sources $DEFAULT_LIBRARY [list "${TB_DIR}/src/${SIM_TOP_LEVEL}.vhd"]

    run_generic $SIM_TOP_LEVEL $SIM_TIME "${TB_DIR}/wave.do"
}

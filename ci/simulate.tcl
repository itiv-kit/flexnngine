if {[catch {
    source run.do

    # [runStatus -full] returns three words
    # state is usually "break" on both VHDL "report ... failure" or "finish"
    # cause is then also always "simulation_stop"
    # origin is "unknown" in case of VHDL "report ... failure", "$finish" on VHDL "finish"
    # when the simulation is not stopped but ran for a fixed time without issues, "ready" is expected
    set status [runStatus -full]
    set state [lindex $status 0]
    set cause [lindex $status 1]
    set origin [lindex $status 2]
    if {$state == "ready" || $origin == "\$finish"} {
        echo "Testbench ${SIM_TOP_LEVEL} was simulated successfully!"
        exit
    } else {
        echo "Error while running testbench ${SIM_TOP_LEVEL}!"
        exit -code 30
    }
} errorid]} {
    echo "Unknown error during simulation: $errorid"
    exit -code 31
}

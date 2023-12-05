vcom -64 -2008 -work accel \
    "${HDL_DIR}/acc.vhd" \
    "${HDL_DIR}/utilities.vhd" \
    "${HDL_DIR}/address_generator.vhd" \
    "${HDL_DIR}/address_generator_psum.vhd" \
    "${HDL_DIR}/control_init.vhd" \
    "${HDL_DIR}/control.vhd" \
    "${HDL_DIR}/control_arch_rs.vhd" \
    "${HDL_DIR}/control_arch_alt_rs.vhd" \
    "${HDL_DIR}/control_address_generator.vhd" \
    "${HDL_DIR}/pe_array.vhd" \
    "${HDL_DIR}/demux.vhd" \
    "${HDL_DIR}/line_buffer.vhd" \
    "${HDL_DIR}/mult.vhd" \
    "${HDL_DIR}/mux.vhd" \
    "${HDL_DIR}/pe.vhd" \
    "${HDL_DIR}/gray.vhd" \
    "${HDL_DIR}/sync.vhd" \
    "${HDL_DIR}/fifos.vhd" \
    "${HDL_DIR}/ram_dp.vhd" \
    "${HDL_DIR}/accelerator.vhd" \
    "${HDL_DIR}/scratchpad.vhd" \
    "${HDL_DIR}/scratchpad_interface.vhd" \
    "${HDL_DIR}/rr_arbiter.vhd" \
    "${HDL_DIR}/onehot_binary.vhd"

# testbench
vcom -64 -2008 -work accel \
    "${TB_DIR}/src/functional_tb.vhd"

set SIM_TIME "10 ms"
set SIM_TOP_LEVEL "functional_tb"

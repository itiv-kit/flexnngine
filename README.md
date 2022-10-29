# Reconfigurable accelerator

## Structure

## Description

## Modules
### Line buffer

## Useful commands
**Start python podman container with home directory mapped**  
`podman run -it --name mypython -v $HOME:$HOME --security-opt label=disable python:latest bash`
`podman run -it --name mypython -v /tools/:/tools/ -v $HOME:$HOME --security-opt label=disable python:latest bash`

**Start container again**  
`podman start -ia mypython`

**Set all files to VHDL 2008 in Vivado**  
`set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]`

**Simulate Vivado IP in Modelsim**  
1. Tools -> Compile Simulation Libraries. Make sure to add Modelsim path
    - `compile_simlib -simulator questa -simulator_exec_path {/tools/cadence/mentor/2020-21/RHELx86/QUESTA-CORE-PRIME_2020.4/questasim/bin} -family all -language all -library all -dir {/home/uzedl/Documents/reconfigurable-accelerator/reconfigurable-accelerator/reconfigurable-accelerator.cache/compile_simlib/questa}`
2. Set Vivado simulator to Modelsim, only create sources checkmark
3. Simulate in Vivado
4. Simulate using created .do files or use contents for own .do file

**Start simulation from terminal**
Add generics to env variable `generics` with `-gGeneric=value`
`Exec=env LM_LICENSE_FILE=27840@ls.itiv.kit.edu generics=$generics MTI_VCO_MODE=64 /tools/cadence/mentor/2020-21/RHELx86/QUESTA-CORE-PRIME_2020.4/questasim/bin/vsim -c -do run_batch.do`
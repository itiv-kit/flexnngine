# Reconfigurable accelerator

## Usage
Start functional simulation by executing the `simulate.py` in `testbenches/functional`
Simulation sets can be appended within `simulate.py`. A simulation is started for every possible combination of settings, for example as follows:
```python
simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [10+i*10 for i in range(20)], output_channels = [3], input_bits = [4]), 
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20, 
                                iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512], 
                                clk_period = [10000], clk_sp_period = [1000], dataflow=[0,1]), start_gui=False))
```

## Useful commands
**Start python podman container with home directory mapped**  
Simple python env for simulations
`podman run -it --name mypython -v /tools/:/tools/ -v $HOME:$HOME -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --security-opt label=disable python:latest bash`
Jupyter on Server with port forwarding
`podman run --name jupyter2 --uidmap 1000:0:1 --uidmap 0:1:999 --uidmap 1001:1001:64535 -p 127.0.0.1:8314:8888/tcp -e JUPYTER_ENABLE_LAB=yes -v "$PWD":/home/jovyan:Z jupyter/minimal-notebook`

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
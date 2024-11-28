# FleXNNgine

This is the *Flexible XNN Engine* - a reconfigurable accelerator prototype for CNN processing.
Future extentions will also allow processing of other DNN types through runtime reconfiguration.

## Run the simulation
Start functional simulation by executing the `simulate.py` in `testbenches/functional`.
Simulation sets can be appended within `simulate.py`.
A simulation is started for every possible combination of settings, for example as follows:
```python
simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [10+i*10 for i in range(20)], output_channels = [3], input_bits = [4]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
                                iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
                                clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))
```

## Useful commands
**Start python podman container with home directory mapped**
Simple python env for simulations
```bash
podman run -it --name mypython -v /tools:/tools -v $HOME:$HOME -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --security-opt label=disable python:latest bash
```
To restart this container: `podman start -ia mypython`

Jupyter on server with port forwarding:
```bash
podman run --rm -u root -e NB_USER=root -e NB_UID=0 -e NB_GID=0 -p 8888:8888 -v "$PWD":/home/root/work --security-opt label=disable quay.io/jupyter/minimal-notebook:latest start-notebook.py --allow-root
```

The old command using `--uidmap +1000:0` does not work anymore due to a regression in podman.

#### Set all files to VHDL 2008 in Vivado
```tcl
set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]
```

#### Use Vivado IP in Questa
1. Make sure Questa is in your path, e.g. run `module load questa/2023.4` before launching vivado.
2. Tools -> Compile Simulation Libraries:
```tcl
compile_simlib -simulator questa -family all -language all -library all -dir {./simulation-library/reconfigurable-accelerator.cache/compile_simlib/questa}
```
3. Set Vivado simulator to Questa, only create sources checkmark
4. Simulate in Vivado
5. Simulate using created .do files or use contents for own .do file

#### Start simulation from terminal
Add generics to env variable `generics` with `-gGeneric=value`
```bash
module load questa/2023.4
generics=$generics MTI_VCO_MODE=64 vsim -c -do run_batch.do`
```

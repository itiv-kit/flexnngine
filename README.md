# FleXNNgine

This is the *Flexible XNN Engine* - a reconfigurable accelerator prototype for CNN processing.
See [our publication](https://doi.org/10.1145/3649476.3658737) for reference.
It implements the row stationary dataflow originally published by [Chen et. al.](https://doi.org/10.1109/JSSC.2016.2616357).
Future extentions will also allow processing of other DNN types through runtime reconfiguration.
Software for the FPGA prototype can be found in the [flexnngine-driver](https://github.com/itiv-kit/flexnngine-driver) repo.

![FleXNNgine architecture diagram](/docs/architecture-axi.svg)

## Run the simulation
Start functional simulation by executing the `simulate.py` in `testbenches/functional`.
By default, a 2D convolution on a 16x16 image with 64 channels, 3x3 kernels and 3 output channels is run.
These parameters can be changed on the command line or by using one of the presets defined in `simulate.py`.
For example, run `python3 simulate.py --hw 32 --rs 5 --ich 16` to use a 32x32 image, 16 channels and 5x5 kernels.
Data is generated randomly with a fixed seed.

A simulation is started for every possible combination of settings, for example running:
```python
python3 simulate.py --preset ci
```
runs a total of 32 simulations. This is equal to running
```python
python3 simulate.py --hw 32 --rs 3,5 --ich 16,128 --bias 0,5 --requantize 0,1 --dataflow 0,1
```
and results from the `ci` preset in `simulate.py`:
```python
    'ci': Setting(
                    Convolution(image_size = [32], kernel_size = [3,5], input_channels = [16,128],
                                output_channels = [3], bias = [0,5], requantize = [False,True], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),
```

## Other testbenches
For most modules, a designated testbench exits in the `testbenches` folder.
Run them with Questa:
```bash
module load questa/2023.4
cd testbenches/address_generator
vsim -do run.do
```

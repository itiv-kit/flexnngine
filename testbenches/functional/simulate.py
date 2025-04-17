from logging import exception
import numpy as np
import math
import os
import sys
from multiprocessing import Pool
from dataclasses import dataclass
from subprocess import STDOUT, CalledProcessError, check_call
import shutil
from pathlib import Path
import argparse
import itertools
from enum import IntEnum

class ActivationMode(IntEnum):
    passthrough = 0
    relu = 1

@dataclass
class Convolution:
    """Class to represent a convolution operation."""

    def __init__(
        self, image_size, kernel_size, input_channels, output_channels, bias=0, requantize=False, activation=ActivationMode.passthrough, input_bits=4
    ):
        self.image_size = image_size
        self.kernel_size = kernel_size
        self.input_channels = input_channels
        self.output_channels = output_channels
        self.input_bits = input_bits
        self.bias = bias
        self.requantize = requantize
        self.activation = activation


@dataclass
class Accelerator:
    """Class to represent an accelerator."""

    def __init__(
        self,
        size_x,
        size_y,
        line_length_iact,
        line_length_psum,
        line_length_wght,
        mem_addr_width,
        iact_fifo_size,
        wght_fifo_size,
        psum_fifo_size,
        clk_period,
        clk_sp_period,
        dataflow,
    ):
        self.size_x = size_x
        self.size_y = size_y
        self.line_length_iact = line_length_iact
        self.line_length_psum = line_length_psum
        self.line_length_wght = line_length_wght
        self.mem_addr_width = mem_addr_width
        self.iact_fifo_size = iact_fifo_size
        self.wght_fifo_size = wght_fifo_size
        self.psum_fifo_size = psum_fifo_size
        self.clk_period = clk_period
        self.clk_sp_period = clk_sp_period
        self.dataflow = dataflow
        self.spad_word_size = 8
        self.mem_size = 2 ** mem_addr_width * self.spad_word_size


@dataclass
class Setting:
    """Class to represent one setting consisting of a convolution and an accelerator."""
    def __init__(self, convolution, accelerator, start_gui=False):
        self.convolution = convolution
        self.accelerator = accelerator
        self.start_gui = start_gui
        self.name = str(self)

    def __str__(self):
        hw = self.convolution.image_size
        rs = self.convolution.kernel_size
        c = self.convolution.input_channels
        oc = self.convolution.output_channels
        df = self.accelerator.dataflow
        li = self.accelerator.line_length_iact
        lw = self.accelerator.line_length_wght
        lp = self.accelerator.line_length_psum
        fifoi = self.accelerator.iact_fifo_size
        fifow = self.accelerator.wght_fifo_size
        fifop = self.accelerator.psum_fifo_size
        clk = self.accelerator.clk_period
        clk_sp = self.accelerator.clk_sp_period
        x = self.accelerator.size_x
        y = self.accelerator.size_y
        bias = abs(self.convolution.bias) if not isinstance(self.convolution.bias, list) else 'X'
        rq = int(self.convolution.requantize) if not isinstance(self.convolution.requantize, list) else 'X'
        return f'HW_{hw}_RS_{rs}_C_{c}_Li_{li}_Lw_{lw}_Lp_{lp}_Fi_{fifoi}_Fw_{fifow}_Fp_{fifop}_Clk_{clk}_ClkSp_{clk_sp}_X_{x}_Y_{y}_Df_{df}_Bi_{bias}_Rq_{rq}'

def write_memory_file_int8(filename, image, wordsize=32):
    pixels_per_word = wordsize // 8
    pixels = image.flatten().astype(np.int8)
    num_words = math.ceil(pixels.size / pixels_per_word)
    pixels.resize(num_words * pixels_per_word)
    with open(filename, "w") as f:
        for nibble in np.split(pixels, num_words):
            f.write(''.join([np.binary_repr(x, 8) for x in reversed(nibble)])+'\n')

def align_to_add(value, divider):
    return (value + divider - 1) // divider * divider

class Test:
    def __init__(self, name, convolution, accelerator, gui=True):
        self.convolution = convolution
        self.accelerator = accelerator
        self.name = name
        self.gui = gui
        self.test_dir = None

        self.wght_base_addr = None
        self.psum_base_addr = None
        self.stride_iact_w = None
        self.stride_iact_hw = None
        self.stride_wght_kernel = None
        self.stride_wght_och = None
        self.stride_psum_och = None

    def generate_test(self, test_name, test_dir):
        print(f'Generating test: {test_name}')
        test_dir.mkdir(parents=True, exist_ok=True)
        self.test_dir = test_dir
        return self._generate_stimuli()

    def _generate_stimuli(self):
        print(f'Generating stimuli for test: {self.name}')

        # calculate accelerator parameters
        if self.accelerator.dataflow == 1:
            self.M0 = self.accelerator.size_y
            self.H1 = self.accelerator.size_x

            self.W1 = self.convolution.image_size - self.convolution.kernel_size + 1
            self.M0_last_m1 = 1 # not used yet

            self.line_length_wght_usable = self.accelerator.line_length_wght - 28

            self.H2 = math.ceil(
                (self.convolution.image_size - self.convolution.kernel_size + 1)
                / self.accelerator.size_x
            )

            self.C1 = math.ceil(self.convolution.input_channels * self.convolution.kernel_size / self.line_length_wght_usable)
            self.C0 = math.floor(self.convolution.input_channels / self.C1)

            self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
            self.rows_last_h2 = (self.convolution.image_size - self.convolution.kernel_size + 1) - (self.H2 - 1) * self.accelerator.size_x
            self.C0W0 = self.C0 * self.convolution.kernel_size
            self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            self.C1 = math.ceil(self.convolution.input_channels / self.C0)
            self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
            self.C0W0 = self.C0 * self.convolution.kernel_size
            self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            # C0W0 must not be too short to allow for disabling of PE array while reading data
            if self.C0W0_last_c1 < 6:
                self.C1 = self.C1 - 1
                self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
                self.C0W0 = self.C0 * self.convolution.kernel_size
                self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            if (self.C0W0 * (self.C1-1) + self.C0W0_last_c1) != (self.convolution.input_channels * self.convolution.kernel_size):
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                print("MISMATCH")
                return False

            if self.C0W0_last_c1 < 6:
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                return False

            if self.C0W0_last_c1 >= self.accelerator.line_length_wght:
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                return False

        else:
            self.line_length_wght_usable = self.accelerator.line_length_wght - 1

            self.M0 = math.floor(self.accelerator.size_y / self.convolution.kernel_size)
            self.H1 = self.accelerator.size_x

            self.W1 = self.convolution.image_size - self.convolution.kernel_size + 1
            self.M0_last_m1 = 1 # not used yet

            if self.M0 == 0:
                self.H2 = math.ceil(self.W1 / self.accelerator.size_x)
            else:
                self.H2 = math.ceil(self.convolution.image_size / self.accelerator.size_x)

            self.C1 = math.ceil(self.convolution.input_channels * self.convolution.kernel_size / self.line_length_wght_usable)
            # self.C0 = math.floor(self.convolution.input_channels / self.C1)
            self.C0 = math.floor(self.line_length_wght_usable / self.convolution.kernel_size / 8) * 8

            self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
            self.rows_last_h2 = 1 # not required for dataflow 0
            self.C0W0 = self.C0 * self.convolution.kernel_size
            self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            self.C1 = math.ceil(self.convolution.input_channels / self.C0)
            self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
            self.C0W0 = self.C0 * self.convolution.kernel_size
            self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            # C0W0 must not be too short to allow for disabling of PE array while reading data
            if self.C0W0_last_c1 < 6:
                self.C1 = self.C1 - 1
                self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0
                self.C0W0 = self.C0 * self.convolution.kernel_size
                self.C0W0_last_c1 = self.C0_last_c1 * self.convolution.kernel_size

            if (self.C0W0 * (self.C1-1) + self.C0W0_last_c1) != (self.convolution.input_channels * self.convolution.kernel_size):
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                print("MISMATCH")
                return False

            if self.C0W0_last_c1 < 6:
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                return False

            if self.C0W0_last_c1 >= self.accelerator.line_length_wght:
                print("H2 = ", self.H2)
                print("rows_last_h2 = ", self.rows_last_h2)
                print("C1 = ", self.C1)
                print("C0 = ", self.C0)
                print("C0_last_c1 = ", self.C0_last_c1)
                print("C0W0 = ", self.C0W0)
                print("C0W0_last_c1 = ", self.C0W0_last_c1)
                return False

        # calculate parameters for scratchpad data layout
        self.stride_iact_w = math.ceil(self.convolution.image_size / self.accelerator.spad_word_size)
        self.stride_iact_hw = math.ceil(self.convolution.image_size * self.convolution.image_size / self.accelerator.spad_word_size)

        # tightly packed kernels without padding between single kernels or output channel kernel sets
        self.stride_wght_kernel = self.convolution.kernel_size * self.convolution.kernel_size
        self.stride_wght_och = math.ceil(self.stride_wght_kernel * self.convolution.input_channels / self.accelerator.spad_word_size)

        # psum stride must be multiple of word size, still pack as tightly as possible
        self.stride_psum_och = math.ceil(self.W1 * self.W1 / self.accelerator.spad_word_size)

        # fixed random seed for reproducibility
        np.random.seed(2)

        # create kernels with random filter weights (for input_channels * output_channels (M0))
        # TODO: can M0 = 0 happen, when looking at code above? then this breaks...
        kernels = np.random.randint(
            -(2 ** (self.convolution.input_bits - 1)),
            (2 ** (self.convolution.input_bits - 1)) - 1,
            (
                self.M0,
                self.convolution.input_channels,
                self.convolution.kernel_size,
                self.convolution.kernel_size,
            ),
        )

        if args.same_kernels_ich:
            # DEBUG: just copy the first kernel this output channel
            for m0 in range(0, self.M0):
                kernels[m0] = np.broadcast_to(kernels[m0][0], (self.convolution.input_channels,) + kernels[m0][0].shape)

        if args.same_kernels_och:
            # DEBUG: just copy the first set of kernels for all output channels
            kernels = np.broadcast_to(kernels[0], (self.M0,) + kernels[0].shape)

        if args.only_first_och:
            # DEBUG: zero out all but first output channel
            kernels = np.stack([kernels[0]] + (self.M0-1) * [np.zeros(kernels[0].shape)])

        # create array with random input activations (three dimensional "image")
        image = np.random.randint(
            -(2 ** (self.convolution.input_bits - 1)),
            (2 ** (self.convolution.input_bits - 1)) - 1,
            (
                self.convolution.input_channels,
                self.convolution.image_size,
                self.convolution.image_size,
            ),
        )

        if args.linear_image:
            # DEBUG: linear sequence of input activations
            linear = np.linspace(1, self.convolution.image_size, self.convolution.image_size, dtype=np.int8)
            image = np.stack(self.convolution.input_channels * [self.convolution.image_size * [linear]])

        # create empty array for all channels of the conved image
        convolved_channels = np.zeros(
            (
                self.M0,
                self.convolution.input_channels,
                self.convolution.image_size - self.convolution.kernel_size + 1,
                self.convolution.image_size - self.convolution.kernel_size + 1,
            )
        )
        # iterate over the image and convolve each channel
        for k in range(self.M0):
            for c in range(self.convolution.input_channels):
                convolved_channels[k, c, :, :] = self._convolution2d(
                    image[c],
                    kernels[k, c]
                )

        # sum over all channels
        convolved_images = np.sum(convolved_channels, axis=1)

        # add bias to all channels
        convolved_images += self.convolution.bias

        if self.convolution.activation == ActivationMode.relu:
            convolved_images = np.maximum(convolved_images, 0)

        # if requant is enabled, find a suitable scaling value per output channel
        zeropt_scale_vals = np.zeros((self.M0, 2))
        if self.convolution.requantize:
            min_vals = np.min(convolved_images, axis=(1,2))
            max_vals = np.max(convolved_images, axis=(1,2))
            for n, (min, max) in enumerate(np.dstack([min_vals, max_vals])[0]):
                if max == min: # hack for the rare case of same-value images
                    zeropt_scale_vals[n] = [0.0, 1.0]
                else:
                    zeropt_scale_vals[n] = np.linalg.solve([[1, max], [1, min]], [127, -128])
                print(f"Scaling output channel {n} with {zeropt_scale_vals[n][1]}, zeropoint {zeropt_scale_vals[n][0]}")

            convolved_images_requant = convolved_images * zeropt_scale_vals[:, 1, None, None] + zeropt_scale_vals[:, 0, None, None]
            convolved_images = np.rint(convolved_images_requant)

        # stack image, kernels and convolved images
        # (make them 2D by unrolling all dimensions vertically except for the last one)
        image_stack = np.vstack(image)
        kernels_stack = np.reshape(kernels, (-1, kernels.shape[-1])).astype(int)
        self.convolved_images_stack = np.reshape(convolved_images, (-1, convolved_images.shape[-1]))

        # save data as txt files
        np.savetxt(self.test_dir / "_image.txt",             image_stack,                 fmt="%d", delimiter=" ")
        np.savetxt(self.test_dir / "_kernel_stack.txt",      kernels_stack,               fmt="%d", delimiter=" ")
        np.savetxt(self.test_dir / "_convolution_stack.txt", self.convolved_images_stack, fmt="%d", delimiter=" ")
        np.savetxt(self.test_dir / "_zeropt_scale.txt",      zeropt_scale_vals,           fmt="%f", delimiter=" ")

        kernels_stack_och = np.vstack(kernels) # all kernels stacked as 3D array in, kernel sets per output channel in sequence

        # assemble data per memory column and export as txt file for simulation
        for column in range(0, self.accelerator.spad_word_size):
            # TODO: pad channels to multiples of 8 (i.e. image stride)
            image_col = image[column::self.accelerator.spad_word_size].flatten()
            wght_col = kernels_stack_och[column::self.accelerator.spad_word_size].flatten()

            # pad the image such that weight data is aligned. technically, multiple of wordsize (currently 8) would suffice.
            image_pad_size = align_to_add(image_col.shape[0], 32)
            image_col_pad = np.resize(image_col, image_pad_size)
            memory_col = np.concatenate((image_col_pad, wght_col))

            if self.wght_base_addr is not None and self.wght_base_addr != image_pad_size:
                raise RuntimeError(f'weight base address differs between mem columns ({image_pad_size} / {self.wght_base_addr})')
            self.wght_base_addr = image_pad_size

            memory_col_pad_size = align_to_add(memory_col.shape[0], 32)
            if self.psum_base_addr is not None and self.psum_base_addr != memory_col_pad_size:
                raise RuntimeError(f'psum base address differs between mem columns ({memory_col_pad_size} / {self.psum_base_addr})')
            self.psum_base_addr = memory_col_pad_size

            write_memory_file_int8(self.test_dir / f"_mem_col{column}.txt", memory_col, wordsize=64)

        alloc_size_per_column = self.psum_base_addr + self.convolved_images_stack.size // 8
        if alloc_size_per_column > self.accelerator.mem_size / 8:
            raise RuntimeError(f'scratchpad memory too small (need {alloc_size_per_column * 8} bytes, got {self.accelerator.mem_size})')

        return True

    def _convolution2d(self, image, kernel):
        m, n = kernel.shape
        if m == n:
            y, x = image.shape
            y = y - m + 1
            x = x - m + 1
            new_image = np.zeros((y, x))
            for i in range(y):
                for j in range(x):
                    new_image[i][j] = np.sum(image[i : i + m, j : j + m] * kernel)
        else:
            print("Kernel size is not equal")
            print("Kernel size is:", m, n)
            print("Kernel is:", kernel)
            print("Image size is:", image.shape)
        return new_image

    def build_generics(self):
        return {
            'g_kernel_size':      self.convolution.kernel_size,
            'g_image_y':          self.convolution.image_size,
            'g_image_x':          self.convolution.image_size,
            'g_inputchs':         self.convolution.input_channels,
            'g_outputchs':        self.M0, # currently fixed to M0, TODO: make smaller count possible
            'g_bias':             self.convolution.bias,
            'line_length_wght':   self.accelerator.line_length_wght,
            'line_length_iact':   self.accelerator.line_length_iact,
            'line_length_psum':   self.accelerator.line_length_psum,
            'mem_addr_width':     self.accelerator.mem_addr_width,
            'size_x':             self.accelerator.size_x,
            'size_y':             self.accelerator.size_y,
            'g_iact_fifo_size':   self.accelerator.iact_fifo_size,
            'g_wght_fifo_size':   self.accelerator.wght_fifo_size,
            'g_psum_fifo_size':   self.accelerator.psum_fifo_size,
            'g_c1':               self.C1,
            'g_w1':               self.W1,
            'g_h2':               self.H2,
            'g_m0':               self.M0,
            'g_m0_last_m1':       self.M0_last_m1,
            'g_rows_last_h2':     self.rows_last_h2,
            'g_c0':               self.C0,
            'g_c0_last_c1':       self.C0_last_c1,
            'g_c0w0':             self.C0W0,
            'g_c0w0_last_c1':     self.C0W0_last_c1,
            'g_stride_iact_w':    self.stride_iact_w,
            'g_stride_iact_hw':   self.stride_iact_hw,
            'g_stride_wght_krnl': self.stride_wght_kernel,
            'g_stride_wght_och':  self.stride_wght_och,
            'g_stride_psum_och':  self.stride_psum_och,
            'g_wght_base_addr':   self.wght_base_addr,
            'g_psum_base_addr':   self.psum_base_addr,
            'g_clk':              self.accelerator.clk_period,
            'g_clk_sp':           self.accelerator.clk_sp_period,
            'g_mode_act':         int(self.convolution.activation),
            'g_requant':          1 if self.convolution.requantize else 0,
            'g_postproc':         1 if self.convolution.requantize or self.convolution.bias != 0 or self.convolution.activation != ActivationMode.passthrough else 0,
            'g_dataflow':         self.accelerator.dataflow,
            'g_init_sp':          True,
            'g_files_dir':        str(self.test_dir.absolute()) + '/',
        }

    def run(self):
        if os.path.exists(self.test_dir / "_success.txt") and sim.start_gui == False:
            print("Test already passed. Only re-evaluating results.")
            return self._evaluate()
        print("Running test: ", self.name)

        myenv = os.environ.copy()
        myenv["library"] = self.test_dir.absolute()
        myenv["library_name"] = self.name
        myenv["GENERICS"] = " ".join(f'-g{x}={y}' for x,y in self.build_generics().items())
        myenv["MTI_VCO_MODE"] = "64"
        myenv["LAUNCH_GUI"] = str(int(sim.start_gui))

        script_dir = Path(__file__).resolve().parent
        simulator = "vsim"
        arguments = ["-do", script_dir / "run.do"]
        if not sim.start_gui:
            arguments += ["-batch"]

        with open(self.test_dir / "_log.txt", "w+") as logfile:
            try:
                check_call([simulator] + arguments,
                    stdout=logfile,
                    stderr=STDOUT,
                    env=myenv,
                    cwd=self.test_dir,
                )
            except CalledProcessError as e:
                print(f"Simulation {self.name} failed.")
                logfile.seek(0)
                max_errors = 3 # limit number of errors to print to console
                for line in logfile:
                    if any((x in line.lower() for x in ["error", "fail"])):
                        print(line)
                        max_errors -= 1
                        if max_errors == 0:
                            break
                return False
            except FileNotFoundError as e:
                print(f'Failed to find simulator: {e}')
                return False

        return self._evaluate()

    def _evaluate(self):
        try:
            # read actual output from file ../_output.txt
            actual_output = np.loadtxt(self.test_dir / "_output.txt")
            expected_output = self.convolved_images_stack

            if expected_output.shape != actual_output.shape:
                print(f'{self.name}: shape of expected ({expected_output.shape})')

            acceptable_delta = 0
            if self.convolution.requantize:
                acceptable_delta = 1

            delta = np.abs(actual_output - expected_output)

            if np.less_equal(delta, acceptable_delta).all():
                if self.convolution.requantize:
                    print(f'{self.name}: Output matches! Maximum delta: {np.max(delta)}')
                else:
                    print(f'{self.name}: Output matches!')
            else:
                print(f'{self.name}: Output differs! Maximum delta: {np.max(delta)}')
                index = 0
                for actual_row, expected_row in zip(actual_output, expected_output):
                    if not np.less_equal(np.abs(actual_row - expected_row), acceptable_delta).all():
                        print(f'{self.name}: first incorrect row {index}')
                        print(f'{self.name}: got row {actual_row}')
                        print(f'{self.name}: expected row {expected_row}')
                        raise RuntimeError(f'row {index} is incorrect')
                    index = index + 1

            print("Success: ", self.name)
            with open((self.test_dir / '_success.txt'), 'w') as f:
                f.write('Simulated and output checked successfully!')
            return True
        except (IndexError, RuntimeError, ValueError, OSError) as e:
            print(f'Error while evaluating test: {self.name}: {e}')
            return False


def run_test(setting):
    test = Test(setting.name, setting.convolution, setting.accelerator, setting.start_gui)
    gen_test = test.generate_test(setting.name, Path("test") / setting.name)
    if gen_test:
        return test.run()
    else:
        print("Error while generating test: ", setting.name)
        return False

presets = {
    'default': Setting(
                      Convolution(image_size = [16], kernel_size = [3], input_channels = [64],
                                  output_channels = [3], bias = [5], requantize = [True], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 16,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0]), start_gui = True),

    # Test with different dataflow. Kernel_size 1,3 and medium image size 16, 10-200 channels
    'rs_df_channels_10..200': Setting(
                      Convolution(image_size = [16], kernel_size = [1,3], input_channels = [10+i*10 for i in range(20)],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    # Test with different dataflow. Kernel_size 3 and large image size 124, 3 channels
    'channels_3': Setting(
                      Convolution(image_size = [124], kernel_size = [3], input_channels = [3],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    # Test with different FIFO sizes. Kernel_size 1,3 and medium image size 16, 40 channels
    'in_fifos_5..512': Setting(
                      Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [5, 10, 15, 30, 64, 128, 512], wght_fifo_size = [5, 10, 15, 30, 64, 128, 512], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    # Test with different Line buffer sizes. Kernel_size 1,3 and medium image size 16, 40 channels, DF 0
    'rs_lb_wght_32..1024_df0': Setting(
                    Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40],
                                output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [], line_length_psum = [128], line_length_wght = [32, 48, 64, 96, 128, 256, 512, 1024],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[0])),

    'hw_rs_array_x_size': Setting(
                      Convolution(image_size = [16, 32], kernel_size = [1, 3, 5], input_channels = [40],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [5,10,15,20,25,50,100], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    'hw_rs_array_y_size': Setting(
                      Convolution(image_size = [16, 32], kernel_size = [1, 3, 5], input_channels = [40],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [10], size_y = [5,10,15,20,25,50,100], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    'rs_df_clk_sp_10x7': Setting(
                      Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [1+i for i in range(10)], dataflow=[0,1])),

    'rs_df_clk_sp_14x12': Setting(
                      Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40],
                                  output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                      Accelerator(size_x = [12], size_y = [14], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_addr_width = 15,
                                  iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                  clk_period = [10], clk_sp_period = [1+i for i in range(10)], dataflow=[0,1])),

    # Test with different Line buffer sizes. Kernel_size 1,3 and medium image size 16, 40 channels, DF 1
    'rs_lb_wght_32..1024_df1': Setting(
                    Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40],
                                output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [], line_length_psum = [128], line_length_wght = [32, 48, 64, 96, 128, 256, 512, 1024],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[1])),

    # small test - 20 simulations
    'rs_df_channels_10..13': Setting(
                    Convolution(image_size = [16], kernel_size = [1, 3], input_channels = [10+i*1 for i in range(4)],
                                output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [512], line_length_wght = [64],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),

    # the test-conv2d.cpp configuration
    'hw_defaults_minimal': Setting(
                    Convolution(image_size = [32], kernel_size = [3], input_channels = [4],
                                output_channels = [3], bias = [0], requantize = [False], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[0]), start_gui = True),

    # a configuration for continuous integration, testing the most important set of features
    'ci': Setting(
                    Convolution(image_size = [32], kernel_size = [3], input_channels = [128],
                                output_channels = [3], bias = [0,5], requantize = [False,True], activation = [ActivationMode.passthrough]),
                    Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                mem_addr_width = 15,
                                iact_fifo_size = [16], wght_fifo_size = [16], psum_fifo_size = [32],
                                clk_period = [10], clk_sp_period = [10], dataflow=[0,1])),
}

if __name__ == "__main__":
    global args
    parser = argparse.ArgumentParser(description='FleXNNgine functional simulation')
    parser.add_argument('--preset',            default='default',   help='Simulation preset(s) to use')
    parser.add_argument('--hw',                                     help='Override preset H/W (input image height/weight)')
    parser.add_argument('--rs',                                     help='Override preset R/S (kernel height/weight)')
    parser.add_argument('--ich',                                    help='Override preset input channel count')
    parser.add_argument('--och',                                    help='Override preset output channel count')
    parser.add_argument('--dataflow',                               help='Override preset dataflow')
    parser.add_argument('--lb-iact',                                help='Override preset iact line buffer length')
    parser.add_argument('--lb-wght',                                help='Override preset wght line buffer length')
    parser.add_argument('--lb-psum',                                help='Override preset psum line buffer length')
    parser.add_argument('--fifo-iact',                              help='Override preset iact input fifo size')
    parser.add_argument('--fifo-wght',                              help='Override preset wght input fifo size')
    parser.add_argument('--fifo-psum',                              help='Override preset psum output fifo size')
    parser.add_argument('--clk',                                    help='Override preset pe array clock speed')
    parser.add_argument('--clk-sp',                                 help='Override preset scratchpad clock speed')
    parser.add_argument('--size-x',                                 help='Override preset pe array x size')
    parser.add_argument('--size-y',                                 help='Override preset pe array y size')
    parser.add_argument('--bias',                                   help='Override preset bias values (same bias for all och)')
    parser.add_argument('--requantize',                             help='Override preset requantization (1/0)')
    parser.add_argument('--activation',                             help='Enable activation (0=off, 1=ReLU)')
    parser.add_argument('--gui',               action='store_true', help='Override preset to enable GUI')
    parser.add_argument('--no-gui',            action='store_true', help='Override preset to disable GUI / batch mode')
    parser.add_argument('--input-bits',        default=4, type=int, help='Set bit range for iact/wght input values')
    parser.add_argument('--pool',              default=1, type=int, help='Number of parallel simulations')
    parser.add_argument('--list-presets',      action='store_true', help='List all available simulation presets')
    parser.add_argument('--same-kernels-och',  action='store_true', help='Use the same kernels for all output channels (M0)')
    parser.add_argument('--same-kernels-ich',  action='store_true', help='Use the same kernels for all input channels (C1*C0)')
    parser.add_argument('--only-first-och',    action='store_true', help='Zero-out kernels for m0 > 0')
    parser.add_argument('--linear-image',      action='store_true', help='Generate a input image with linearly increasing pixels instead of random')
    args = parser.parse_args()

    if args.list_presets:
        print(f'{len(presets)} presets are available:')
        for name, setting in presets:
            print(f'{name}: {setting}')
        exit(0)

    configurations = []
    for preset in args.preset.split(','):
        if not preset in presets:
            print(f'Preset {preset} not found, ignoring.')
            continue
        setting = presets[preset]

        # override settings from commandline
        if args.hw:
            setting.convolution.image_size = [int(x) for x in args.hw.split(',')]
        if args.rs:
            setting.convolution.kernel_size = [int(x) for x in args.rs.split(',')]
        if args.ich:
            setting.convolution.input_channels = [int(x) for x in args.ich.split(',')]
        if args.och:
            setting.convolution.output_channels = [int(x) for x in args.och.split(',')]
        if args.dataflow:
            setting.accelerator.dataflow = [int(x) for x in args.dataflow.split(',')]
        if args.lb_iact:
            setting.accelerator.line_length_iact = [int(x) for x in args.lb_iact.split(',')]
        if args.lb_wght:
            setting.accelerator.line_length_wght = [int(x) for x in args.lb_wght.split(',')]
        if args.lb_psum:
            setting.accelerator.line_length_psum = [int(x) for x in args.lb_psum.split(',')]
        if args.fifo_iact:
            setting.accelerator.iact_fifo_size = [int(x) for x in args.fifo_iact.split(',')]
        if args.fifo_wght:
            setting.accelerator.wght_fifo_size = [int(x) for x in args.fifo_wght.split(',')]
        if args.fifo_psum:
            setting.accelerator.psum_fifo_size = [int(x) for x in args.fifo_psum.split(',')]
        if args.clk:
            setting.accelerator.clk_period = [int(x) for x in args.clk.split(',')]
        if args.clk_sp:
            setting.accelerator.clk_sp_period = [int(x) for x in args.clk_sp.split(',')]
        if args.size_x:
            setting.accelerator.size_x = [int(x) for x in args.size_x.split(',')]
        if args.size_y:
            setting.accelerator.size_y = [int(x) for x in args.size_y.split(',')]
        if args.bias:
            setting.convolution.bias = [int(x) for x in args.bias.split(',')]
        if args.requantize:
            setting.convolution.requantize = [int(x) > 0 for x in args.requantize.split(',')]
        if args.activation:
            setting.convolution.activation = [ActivationMode(int(x)) for x in args.activation.split(',')]
        if args.gui:
            setting.start_gui = True
        if args.no_gui:
            setting.start_gui = False

        configurations.append(setting)

    if len(configurations) == 0:
        print('No configurations selected! Make sure to select at least one preset.')
        exit(1)

    # generate configurations settings for all permutations
    settings = []
    for sim in configurations:
        for hw, rs, c, oc, df, li, lw, lp, fifoi, fifow, fifop, clk, clk_sp, x, y, bias, rq, act in itertools.product(
                sim.convolution.image_size,
                sim.convolution.kernel_size,
                sim.convolution.input_channels,
                sim.convolution.output_channels,
                sim.accelerator.dataflow,
                sim.accelerator.line_length_iact,
                sim.accelerator.line_length_wght,
                sim.accelerator.line_length_psum,
                sim.accelerator.iact_fifo_size,
                sim.accelerator.wght_fifo_size,
                sim.accelerator.psum_fifo_size,
                sim.accelerator.clk_period,
                sim.accelerator.clk_sp_period,
                sim.accelerator.size_x,
                sim.accelerator.size_y,
                sim.convolution.bias,
                sim.convolution.requantize,
                sim.convolution.activation,
            ):
            settings.append(
                Setting(
                    Convolution(hw, rs, c, oc, bias, rq, act, args.input_bits),
                    Accelerator(
                        x,
                        y,
                        li,
                        lp,
                        lw,
                        sim.accelerator.mem_addr_width,
                        fifoi,
                        fifow,
                        fifop,
                        clk,
                        clk_sp,
                        df,
                    ),
                    sim.start_gui
                )
            )

    if len(settings) > 4 and any((sim.start_gui for sim in settings)):
        print("Too many settings to display in GUI")
        exit(1)

    if len(settings) > 1:
        print(f'Running {len(settings)} simulations...')

    pool = Pool(args.pool)
    outputs = pool.map(run_test, settings)

    print("Outputs: ", outputs)

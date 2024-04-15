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

@dataclass
class Convolution:
    """Class to represent a convolution operation."""

    def __init__(
        self, image_size, kernel_size, input_channels, output_channels, input_bits
    ):
        self.image_size = image_size
        self.kernel_size = kernel_size
        self.input_channels = input_channels
        self.output_channels = output_channels
        self.input_bits = input_bits


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
        mem_size_iact,
        mem_size_psum,
        mem_size_wght,
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
        self.mem_size_iact = mem_size_iact
        self.mem_size_psum = mem_size_psum
        self.mem_size_wght = mem_size_wght
        self.iact_fifo_size = iact_fifo_size
        self.wght_fifo_size = wght_fifo_size
        self.psum_fifo_size = psum_fifo_size
        self.clk_period = clk_period
        self.clk_sp_period = clk_sp_period
        self.dataflow = dataflow


@dataclass
class Setting:
    """Class to represent one setting consisting of a convolution and an accelerator."""
    def __init__(self, name, convolution, accelerator, start_gui):
        self.name = name
        self.convolution = convolution
        self.accelerator = accelerator
        self.start_gui = start_gui


class Test:
    def __init__(self, name, convolution, accelerator, gui=True):
        self.convolution = convolution
        self.accelerator = accelerator
        self.name = name
        self.gui = gui
        self.test_dir = None

    def generate_test(self, test_name, test_dir):
        print("Generating test: ", test_name)
        test_dir.mkdir(parents=True, exist_ok=True)
        self.test_dir = test_dir
        return self._generate_stimuli()

    def _generate_stimuli(self):
        print("Generating stimuli for test: ", self.name)
        # Generate input activations
        # Generate weights
        # Generate expected output activations

        if self.accelerator.dataflow == 1:
            self.M0 = self.accelerator.size_y
            self.H1 = self.accelerator.size_x

            self.W1 = self.convolution.image_size - self.convolution.kernel_size + 1
            self.M0_last_m1 = 1 # not used yet

            self.line_length_wght_usable = self.accelerator.line_length_wght - 28

            size_rows = self.accelerator.size_x + self.accelerator.size_y - 1
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
            """self.W1 = self.convolution.image_size - self.convolution.kernel_size + 1
            self.M0_last_m1 = 1 # not used yet
            self.rows_last_h2 = 1
            self.C0_last_c1 = 1
            self.C0W0 = 1
            self.C0W0_last_c1 = 1

            self.M0 = math.floor(self.accelerator.size_y / self.convolution.kernel_size)
            self.H1 = self.accelerator.size_x

            size_rows = self.accelerator.size_x + self.accelerator.size_y - 1
            if self.M0 == 0:
                self.H2 = math.ceil(
                    (self.convolution.image_size - self.convolution.kernel_size + 1)
                    / self.accelerator.size_x
                )
            else:
                self.H2 = math.ceil(self.convolution.image_size / self.accelerator.size_x)

            self.C0 = math.floor(
                self.accelerator.line_length_wght / self.convolution.kernel_size
            )
            if (
                self.convolution.input_channels * self.convolution.kernel_size
                < self.accelerator.line_length_wght
            ):
                self.C0 = self.convolution.input_channels

            self.C1 = math.ceil(self.convolution.input_channels / self.C0)

            self.C0_last_c1 = self.convolution.input_channels - (self.C1 - 1) * self.C0"""
            self.line_length_wght_usable = self.accelerator.line_length_wght - 1

            self.M0 = math.floor(self.accelerator.size_y / self.convolution.kernel_size)
            self.H1 = self.accelerator.size_x

            self.W1 = self.convolution.image_size - self.convolution.kernel_size + 1
            self.M0_last_m1 = 1 # not used yet

            size_rows = self.accelerator.size_x + self.accelerator.size_y - 1
            if self.M0 == 0:
                self.H2 = math.ceil(
                    (self.convolution.image_size - self.convolution.kernel_size + 1)
                    / self.accelerator.size_x
                )
            else:
                self.H2 = math.ceil(self.convolution.image_size / self.accelerator.size_x)

            self.C1 = math.ceil(self.convolution.input_channels * self.convolution.kernel_size / self.line_length_wght_usable)
            self.C0 = math.floor(self.convolution.input_channels / self.C1)

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

        np.random.seed(2)
        st = np.random.get_state()
        # print(st)

        # state = ['MT19937', key_array, 624, 0, 0.0]

        # create array with random filter weights
        kernel = np.random.randint(
            -(2 ** (self.convolution.input_bits - 1)),
            (2 ** (self.convolution.input_bits - 1)) - 1,
            (
                self.convolution.kernel_size * self.convolution.input_channels,
                self.convolution.kernel_size,
            ),
        )

        kernels = np.zeros(
            (
                self.M0,
                self.convolution.kernel_size * self.convolution.input_channels,
                self.convolution.kernel_size,
            )
        )
        # create M0 kernels
        for k in range(self.M0):
            kernels[k] = kernel
            #kernels[k] = np.random.randint(-(2**(self.convolution.input_bits-1)), (2**(self.convolution.input_bits-1))-1, (self.convolution.kernel_size * self.convolution.input_channels, self.convolution.kernel_size))
            # TODO for debugging just copy the first kernel. Uncomment the line above to get random kernels

        # create array with random input activations ("image")
        image = np.random.randint(
            -(2 ** (self.convolution.input_bits - 1)),
            (2 ** (self.convolution.input_bits - 1)) - 1,
            (
                self.convolution.image_size * self.convolution.input_channels,
                self.convolution.image_size,
            ),
        )

        # create empty array for convolved image
        convolved_channel = np.zeros(
            (
                self.convolution.input_channels,
                self.convolution.image_size - self.convolution.kernel_size + 1,
                self.convolution.image_size - self.convolution.kernel_size + 1,
            )
        )
        convolved_channels = np.zeros(
            (
                self.M0,
                self.convolution.input_channels,
                self.convolution.image_size - self.convolution.kernel_size + 1,
                self.convolution.image_size - self.convolution.kernel_size + 1,
            )
        )

        for c in range(self.convolution.input_channels):
            # iterate over the image and convolve each channel
            image_channel = image[
                c * self.convolution.image_size : (c + 1) * self.convolution.image_size,
                :,
            ]
            kernel_channel = kernel[
                c
                * self.convolution.kernel_size : (c + 1)
                * self.convolution.kernel_size,
                :,
            ]
            # print("image_channel", image_channel)
            convolved_channel[c, :, :] = self._convolution2d(
                image_channel, kernel_channel, 0
            )
            # print("convolved_channel", convolved_channel)
            # print(convolution2d(image[c*image_size:(c+1)*image_size,:], kernel[(c*kernel_size):((c+1)*kernel_size-1),:], 0))
            for k in range(self.M0):
                convolved_channels[k, c, :, :] = self._convolution2d(
                    image_channel,
                    kernels[
                        k,
                        c
                        * self.convolution.kernel_size : (c + 1)
                        * self.convolution.kernel_size,
                        :,
                    ],
                    0,
                )

        # sum over all channels
        convolved_image = np.sum(convolved_channel, axis=0)
        convolved_images = np.sum(convolved_channels, axis=1)

        # stack the convolved images
        for k in range(self.M0):
            if k == 0:
                self.convolved_images_stack = convolved_images[k, :, :]
            else:
                self.convolved_images_stack = np.vstack(
                    (self.convolved_images_stack, convolved_images[k, :, :])
                )

        # stack the kernels
        for k in range(self.M0):
            if k == 0:
                kernels_stack = kernels[k, :, :]
            else:
                kernels_stack = np.vstack((kernels_stack, kernels[k, :, :]))
        kernels_stack = kernels_stack.astype(int)

        # print("convolved_image_shape: ", convolved_image.shape)
        # print("convolved_images_shape: ", convolved_images.shape)
        # print("convolved_images_stack_shape: ", self.convolved_images_stack.shape)

        # save data as txt files
        np.savetxt(self.test_dir / "_image.txt", image, fmt="%d", delimiter=" ")
        np.savetxt(self.test_dir / "_kernel.txt", kernel, fmt="%d", delimiter=" ")
        np.savetxt(
            self.test_dir / "_kernel_stack.txt", kernels_stack, fmt="%d", delimiter=" "
        )
        np.savetxt(
            self.test_dir / "_convolution.txt", convolved_image, fmt="%d", delimiter=" "
        )
        np.savetxt(
            self.test_dir / "_convolution_stack.txt",
            self.convolved_images_stack,
            fmt="%d",
            delimiter=" ",
        )

        # save mem files
        # save image as 8-bit binary values in _mem_iact.txt in two's complement
        with open(self.test_dir / "_mem_iact.txt", "w") as f:
            for i in range(
                self.convolution.image_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.image_size):
                    f.write("{0:08b} ".format(image[i][j] & 0xFF) + "\n")

        with open(self.test_dir / "_mem_iact_dec.txt", "w") as f:
            for i in range(
                self.convolution.image_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.image_size):
                    f.write(str(image[i][j]) + "\n")

        # print("Pixels : " + str(image.shape[0] * image.shape[1]))

        # save kernel as 8-bit binary values in _mem_wght.txt in two's complement
        with open(self.test_dir / "_mem_wght.txt", "w") as f:
            for i in range(
                self.convolution.kernel_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.kernel_size):
                    f.write("{0:08b} ".format(kernel[i][j] & 0xFF) + "\n")

        # save kernels as 8-bit binary values in _mem_wght_stack.txt in two's complement
        with open(self.test_dir / "_mem_wght_stack.txt", "w") as f:
            for i in range(
                self.convolution.kernel_size * self.convolution.input_channels * self.M0
            ):
                for j in range(self.convolution.kernel_size):
                    f.write("{0:08b} ".format(kernels_stack[i][j] & 0xFF) + "\n")

        # save empty file as _mem_psum.txt
        with open(self.test_dir / "_mem_psum.txt", "w") as f:
            pass

        # reorder image to be able to check iact input
        image_tmp = image
        image = np.zeros(
            (
                size_rows,
                self.convolution.image_size * self.convolution.input_channels * self.H2,
            )
        )
        column = 0
        # print("Reordered shape : ", image.shape)
        for tile_y in range(self.H2):
            # print("tile_y = ", tile_y)
            # print("############################")
            # print("############################")
            # print("############################")
            for tile_c in range(self.C1):
                if tile_c == self.C1 - 1:
                    c0 = self.C0_last_c1
                else:
                    c0 = self.C0
                # print(c0)
                for i in range(self.convolution.image_size):
                    for c in range(c0):
                        # print("c = ", c)
                        # print("tile_c = ", tile_c)
                        channel = c + tile_c * self.C0
                        for h in range(size_rows):
                            h_ = tile_y * self.accelerator.size_x + h
                            while h_ >= self.convolution.image_size:
                                h_ -= self.convolution.image_size
                            index = channel * self.convolution.image_size + h_
                            # print(
                            #     "Address : c=",
                            #     c,
                            #     " tile_c=",
                            #     tile_c,
                            #     " tile_y=",
                            #     tile_y,
                            #     " index=",
                            #     index,
                            #     " channel=",
                            #     channel,
                            #     " x=",
                            #     i,
                            #     " h=",
                            #     h,
                            #     " h_=",
                            #     h_,
                            # )
                            if index >= image_tmp.shape[0]:
                                image[h, column] = 0
                                print("err ---")
                            else:
                                image[h, column] = image_tmp[index, i]
                        column += 1

                        # image[:, column] = image_tmp[index : index + size_rows  , i]
                        # column += 1
        # print("image shape : ", image.shape)
        # np.savetxt('_kernel_reordered.txt', kernel, fmt='%d', delimiter=' ')
        np.savetxt(
            self.test_dir / "_image_reordered_2.txt", image, fmt="%d", delimiter=" "
        )
        return True

    def _convolution2d(self, image, kernel, bias):
        m, n = kernel.shape
        if m == n:
            y, x = image.shape
            y = y - m + 1
            x = x - m + 1
            new_image = np.zeros((y, x))
            for i in range(y):
                for j in range(x):
                    new_image[i][j] = (
                        np.sum(image[i : i + m, j : j + m] * kernel) + bias
                    )
        else:
            print("Kernel size is not equal")
            print("Kernel size is: ", m, n)
            print("Kernel is: ", kernel)
            print("Image size is: ", image.shape)
        return new_image

    def build_generics(self):
        return {
            'g_kernel_size':       self.convolution.kernel_size,
            'g_image_y':           self.convolution.image_size,
            'g_image_x':           self.convolution.image_size,
            'g_channels':          self.convolution.input_channels,
            'line_length_wght':    self.accelerator.line_length_wght,
            'addr_width_wght':     math.ceil(math.log2(self.accelerator.line_length_wght)),
            'line_length_iact':    self.accelerator.line_length_iact,
            'addr_width_iact':     math.ceil(math.log2(self.accelerator.line_length_iact)),
            'line_length_psum':    self.accelerator.line_length_psum,
            'addr_width_psum':     math.ceil(math.log2(self.accelerator.line_length_psum)),
            'addr_width_iact_mem': self.accelerator.mem_size_iact,
            'addr_width_wght_mem': self.accelerator.mem_size_wght,
            'addr_width_psum_mem': self.accelerator.mem_size_psum,
            'size_x':              self.accelerator.size_x,
            'size_y':              self.accelerator.size_y,
            'size_rows':           self.accelerator.size_x + self.accelerator.size_y - 1,
            'addr_width_x':        math.ceil(math.log2(self.accelerator.size_x)),
            'addr_width_y':        math.ceil(math.log2(self.accelerator.size_y)),
            'addr_width_rows':     math.ceil(math.log2(self.accelerator.size_x + self.accelerator.size_y - 1)),
            'g_iact_fifo_size':    self.accelerator.iact_fifo_size,
            'g_wght_fifo_size':    self.accelerator.wght_fifo_size,
            'g_psum_fifo_size':    self.accelerator.psum_fifo_size,
            'g_control_init':      False,
            'g_c1':                self.C1,
            'g_w1':                self.W1,
            'g_h2':                self.H2,
            'g_m0':                self.M0,
            'g_m0_last_m1':        self.M0_last_m1,
            'g_rows_last_h2':      self.rows_last_h2,
            'g_c0':                self.C0,
            'g_c0_last_c1':        self.C0_last_c1,
            'g_c0w0':              self.C0W0,
            'g_c0w0_last_c1':      self.C0W0_last_c1,
            'g_clk':               self.accelerator.clk_period,
            'g_clk_sp':            self.accelerator.clk_sp_period,
            'g_dataflow':          self.accelerator.dataflow,
            'g_init_sp':           True,
            'g_files_dir':         str(self.test_dir.absolute()) + '/',
        }

    def run(self):
        if os.path.exists(self.test_dir / "_success.txt") and sim.start_gui == False:
            print("Test already passed. Only re-evaluating results.")
            return self._evaluate()
        print("Running test: ", self.name)

        myenv = os.environ.copy()
        myenv["LM_LICENSE_FILE"] = "1717@scclic2.itiv.kit.edu"
        myenv["library"] = self.test_dir.absolute()
        myenv["library_name"] = self.name
        myenv["GENERICS"] = " ".join(f'-g{x}={y}' for x,y in self.build_generics().items())
        myenv["MTI_VCO_MODE"] = "64"
        myenv["LAUNCH_GUI"] = str(int(sim.start_gui))

        script_dir = Path(__file__).resolve().parent
        simulator = "/tools/cadence/mentor/2020-21/RHELx86/QUESTA-CORE-PRIME_2020.4/questasim/bin/vsim"
        arguments = []
        if not self.gui:
            arguments += ["-c"]
        arguments += ["-do", script_dir / "run.do"]

        with open(self.test_dir / "_log.txt", "w+") as logfile:
            try:
                check_call([simulator] + arguments,
                    stdout=logfile,
                    stderr=STDOUT,
                    env=myenv,
                    cwd=self.test_dir,
                )
            except CalledProcessError as e:
                print(f"Error while running test {self.name}: {e}")
                return False

        return self._evaluate()

    def _evaluate(self):
        try:
            # read actual output from file ../_output.txt
            actual_output = np.loadtxt(self.test_dir / "_output.txt")
            expected_output = self.convolved_images_stack

            if expected_output.shape != actual_output.shape:
                print(f'{self.name}: shape of expected ({expected_output.shape})')

            if np.equal(actual_output, expected_output).all():
                print(f'{self.name}: Output matches!')
            else:
                print(f'{self.name}: Output differs!')
                index = 0
                for actual_row, expected_row in zip(actual_output, expected_output):
                    if not np.equal(actual_row, expected_row).all():
                        print(f'{self.name}: first incorrect row {index}')
                        print(f'{self.name}: got row {actual_row}')
                        print(f'{self.name}: expected row {expected_row}')
                        raise RuntimeError(f'row {index} is incorrect')
                    index = index + 1

            print("Success: ", self.name)
            with open((self.test_dir / '_success.txt'), 'w') as f:
                f.write('Simulated and output checked successfully!')
            return True
        except (IndexError, RuntimeError) as e:
            print(f'Error while evaluating test: {self.name}: {e}')
            return False


def run_test(setting):
    test = Test(setting.name, setting.convolution, setting.accelerator, setting.start_gui)
    gen_test = test.generate_test(setting.name, Path("test") / setting.name)
    if gen_test:
        return test.run()
        return True
    else:
        print("Error while generating test: ", setting.name)
        return False


if __name__ == "__main__":
    # Define convolution parameters
    output_channels = 3
    input_bits = 4

    simulation = []

    # ## 1. Test with different dataflow. Kernel_size 1,3 and medium image size 16, 10-200 channels
    # simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [10+i*10 for i in range(20)], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # ## 2. Test with different dataflow. Kernel_size 1,3 and larger image size 32, 10-100 channels
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [1,3], input_channels = [10+i*10 for i in range(10)], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # ## 3. Test with different dataflow. Kernel_size 3 and large image size 124, 3 channels
    # simulation.append(Setting("", Convolution(image_size = [124], kernel_size = [3], input_channels = [3], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # ## 4. Test with different FIFO sizes. Kernel_size 1,3 and medium image size 16, 40 channels
    # simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [5, 10, 15, 30, 64, 128, 512], wght_fifo_size = [5, 10, 15, 30, 64, 128, 512], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # ## 5. Test with different Line buffer sizes. Kernel_size 1,3 and medium image size 16, 40 channels
    # simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [], line_length_psum = [128], line_length_wght = [16, 32, 64, 128, 256, 512],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # # 6. Test different accelerator x sizes
    # simulation.append(Setting("", Convolution(image_size = [16, 32], kernel_size = [1, 3, 5], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [5,10,15,20,25,50,100], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [16384],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # # 7. Test different accelerator y sizes
    # simulation.append(Setting("", Convolution(image_size = [16, 32], kernel_size = [1, 3, 5], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [10], size_y = [5,10,15,20,25,50,100], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [16384],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # # 8. Test different SPad clock speeds
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [100], clk_sp_period = [1+i for i in range(10)], dataflow=[0,1]), start_gui=False))

    # # 9. Test different SPad clock speeds
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [2+i for i in range(9)], dataflow=[0,1]), start_gui=False))

    # # 10. Test different SPad clock speeds
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [14], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [100], clk_sp_period = [1+i for i in range(10)], dataflow=[0,1]), start_gui=False))

    # # 11. Test different SPad clock speeds
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [1, 3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [14], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                               clk_period = [10], clk_sp_period = [2+i for i in range(9)], dataflow=[0,1]), start_gui=False))

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # ## 12. Test with different Line buffer sizes. Kernel_size 1,3 and medium image size 16, 40 channels, DF 0
    # simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                 Accelerator(size_x = [7], size_y = [10], line_length_iact = [], line_length_psum = [128], line_length_wght = [32, 48, 64, 96, 128, 256, 512, 1024],
    #                             mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                             iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                             clk_period = [10], clk_sp_period = [1], dataflow=[0]), start_gui=False))

    # ## 13. Test with different Line buffer sizes. Kernel_size 1,3 and medium image size 16, 40 channels, DF 1
    # simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [1,3], input_channels = [40], output_channels = [3], input_bits = [4]),
    #                 Accelerator(size_x = [7], size_y = [10], line_length_iact = [], line_length_psum = [128], line_length_wght = [32, 48, 64, 96, 128, 256, 512, 1024],
    #                             mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                             iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
    #                             clk_period = [10], clk_sp_period = [1], dataflow=[1]), start_gui=False))

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # very small test - GUI
    simulation.append(Setting("", Convolution(image_size = [16], kernel_size = [3], input_channels = [100], output_channels = [3], input_bits = [4]),
                      Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
                                  mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
                                  iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [512],
                                  clk_period = [10], clk_sp_period = [1], dataflow=[0]), start_gui=True))

    # # small test - 20 simulations
    # simulation.append(Setting("", Convolution(image_size = [15], kernel_size = [1, 3], input_channels = [10+i*1 for i in range(4)], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [512], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [128],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0,1]), start_gui=False))

    # the test-conv2d.cpp configuration
    # simulation.append(Setting("", Convolution(image_size = [32], kernel_size = [3], input_channels = [4], output_channels = [3], input_bits = [4]),
    #                   Accelerator(size_x = [7], size_y = [10], line_length_iact = [64], line_length_psum = [128], line_length_wght = [64],
    #                               mem_size_iact = 20, mem_size_psum = 20, mem_size_wght = 20,
    #                               iact_fifo_size = [15], wght_fifo_size = [15], psum_fifo_size = [128],
    #                               clk_period = [10], clk_sp_period = [1], dataflow=[0]), start_gui=True))

    # generate simulation settings for all permutations
    settings = []
    gui_requested = False
    for sim in simulation:
        for hw in sim.convolution.image_size:
            for rs in sim.convolution.kernel_size:
                for c in sim.convolution.input_channels:
                    for df in sim.accelerator.dataflow:
                        #for li in sim.accelerator.line_length_iact:
                            for lw in sim.accelerator.line_length_wght:
                                for lp in sim.accelerator.line_length_psum:
                                    for fifoi in sim.accelerator.iact_fifo_size:
                                        for fifow in sim.accelerator.wght_fifo_size:
                                            for fifop in sim.accelerator.psum_fifo_size:
                                                for clk in sim.accelerator.clk_period:
                                                    for clk_sp in sim.accelerator.clk_sp_period:
                                                        for x in sim.accelerator.size_x:
                                                            for y in sim.accelerator.size_y:
                                                                li = lw
                                                                name = f'HW_{hw}_RS_{rs}_C_{c}_Li_{li}_Lw_{lw}_Lp_{lp}_Fi_{fifoi}_Fw_{fifow}_Fp_{fifop}_Clk_{clk}_ClkSp_{clk_sp}_X_{x}_Y_{y}_Df_{df}'
                                                                settings.append(
                                                                    Setting(
                                                                        name,
                                                                        Convolution(hw, rs, c, output_channels, input_bits),
                                                                        Accelerator(
                                                                            x,
                                                                            y,
                                                                            li,
                                                                            lp,
                                                                            lw,
                                                                            sim.accelerator.mem_size_iact,
                                                                            sim.accelerator.mem_size_psum,
                                                                            sim.accelerator.mem_size_wght,
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
                                                                if sim.start_gui == True:
                                                                    gui_requested = True

    if len(settings) > 4 and gui_requested == True:
        print("Too many settings to display in GUI")
        exit(1)

    pool = Pool(128)
    outputs = pool.map(run_test, settings)

    print("Outputs: ", outputs)

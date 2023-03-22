from logging import exception
import numpy as np
import math
import os
import sys
from multiprocessing import Pool
from dataclasses import dataclass
from subprocess import DEVNULL, STDOUT, CalledProcessError, check_call
import subprocess
import shutil


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


@dataclass
class Setting:
    """Class to represent one setting consisting of a convolution and an accelerator."""
    def __init__(self, name, convolution, accelerator):
        self.name = name
        self.convolution = convolution
        self.accelerator = accelerator


class Test:
    def __init__(self, name, convolution, accelerator, show_output):
        self.convolution = convolution
        self.accelerator = accelerator
        self.name = name
        self.show_output = show_output

    def generate_test(self, test_name, test_dir):
        print("Generating test: ", test_name)
        os.makedirs(test_dir, exist_ok=True)
        self.test_dir = test_dir
        self._generate_stimuli()

    def _generate_stimuli(self):
        print("Generating stimuli for test: ", self.name)
        # Generate input activations
        # Generate weights
        # Generate expected output activations
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

        self.C0_last = self.convolution.input_channels - (self.C1 - 1) * self.C0

        print("H2 = ", self.H2)
        print("C1 = ", self.C1)
        print("C0 = ", self.C0)
        print("C0_last = ", self.C0_last)

        np.random.seed(2)
        st = np.random.get_state()
        # print(st)

        # print range of input_bits signed numbers
        print(
            "Input range: ",
            -(2 ** (self.convolution.input_bits - 1)),
            " to ",
            (2 ** (self.convolution.input_bits - 1)) - 1,
        )

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

        print("convolved_image_shape: ", convolved_image.shape)
        print("convolved_images_shape: ", convolved_images.shape)
        print("convolved_images_stack_shape: ", self.convolved_images_stack.shape)

        # save data as txt files
        np.savetxt(self.test_dir + "_image.txt", image, fmt="%d", delimiter=" ")
        np.savetxt(self.test_dir + "_kernel.txt", kernel, fmt="%d", delimiter=" ")
        np.savetxt(
            self.test_dir + "_kernel_stack.txt", kernels_stack, fmt="%d", delimiter=" "
        )
        np.savetxt(
            self.test_dir + "_convolution.txt", convolved_image, fmt="%d", delimiter=" "
        )
        np.savetxt(
            self.test_dir + "_convolution_stack.txt",
            self.convolved_images_stack,
            fmt="%d",
            delimiter=" ",
        )

        # save mem files
        # save image as 8-bit binary values in _mem_iact.txt in two's complement
        with open(self.test_dir + "_mem_iact.txt", "w") as f:
            for i in range(
                self.convolution.image_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.image_size):
                    f.write("{0:08b} ".format(image[i][j] & 0xFF) + "\n")
            # Append zeros to fill up memory (until 2 ** mem_size_iact)
            for i in range(
                2**self.accelerator.mem_size_iact - image.shape[0] * image.shape[1]
            ):
                f.write("{0:08b}".format(0) + "\n")

        with open(self.test_dir + "_mem_iact_dec.txt", "w") as f:
            for i in range(
                self.convolution.image_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.image_size):
                    f.write(str(image[i][j]) + "\n")
            # Append zeros to fill up memory (until 2 ** mem_size_iact)
            for i in range(
                2**self.accelerator.mem_size_iact - image.shape[0] * image.shape[1]
            ):
                f.write(str(0) + "\n")

        print("Pixels : " + str(image.shape[0] * image.shape[1]))

        # save kernel as 8-bit binary values in _mem_wght.txt in two's complement
        with open(self.test_dir + "_mem_wght.txt", "w") as f:
            for i in range(
                self.convolution.kernel_size * self.convolution.input_channels
            ):
                for j in range(self.convolution.kernel_size):
                    f.write("{0:08b} ".format(kernel[i][j] & 0xFF) + "\n")
            # Append zeros to fill up memory (until 2 ** mem_size_wght)
            for i in range(
                2**self.accelerator.mem_size_wght - kernel.shape[0] * kernel.shape[1]
            ):
                f.write("{0:08b}".format(0) + "\n")

        # save kernels as 8-bit binary values in _mem_wght_stack.txt in two's complement
        with open(self.test_dir + "_mem_wght_stack.txt", "w") as f:
            for i in range(
                self.convolution.kernel_size * self.convolution.input_channels * self.M0
            ):
                for j in range(self.convolution.kernel_size):
                    f.write("{0:08b} ".format(kernels_stack[i][j] & 0xFF) + "\n")
            # Append zeros to fill up memory (until 2 ** mem_size_wght)
            for i in range(
                2**self.accelerator.mem_size_wght
                - kernels.shape[0] * kernels.shape[1] * kernels.shape[2]
            ):
                f.write("{0:08b}".format(0) + "\n")

        # save zeros as 8-bit binary values in _mem_psum.txt
        with open(self.test_dir + "_mem_psum.txt", "w") as f:
            for i in range(2**self.accelerator.mem_size_psum):
                f.write("{0:016b}".format(0) + "\n")

        # reorder image to be able to check iact input
        image_tmp = image
        image = np.zeros(
            (
                size_rows,
                self.convolution.image_size * self.convolution.input_channels * self.H2,
            )
        )
        column = 0
        print("Reordered shape : ", image.shape)
        for tile_y in range(self.H2):
            # print("tile_y = ", tile_y)
            # print("############################")
            # print("############################")
            # print("############################")
            for tile_c in range(self.C1):
                if tile_c == self.C1 - 1:
                    c0 = self.C0_last
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
        print("image shape : ", image.shape)
        # np.savetxt('_kernel_reordered.txt', kernel, fmt='%d', delimiter=' ')
        np.savetxt(
            self.test_dir + "_image_reordered_2.txt", image, fmt="%d", delimiter=" "
        )

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

    def run(self):
        print("Running test: ", self.name)
        myenv = os.environ.copy()
        myenv["LM_LICENSE_FILE"] = "27840@ls.itiv.kit.edu"
        # myenv["generics"] = "$generics"
        myenv["library"] = self.test_dir
        myenv["library_name"] = self.name
        myenv["generics"] = (
            "-gg_kernel_size="
            + str(self.convolution.kernel_size)
            + " -gg_image_y="
            + str(self.convolution.image_size)
            + " -gg_image_x="
            + str(self.convolution.image_size)
            + " -gg_channels="
            + str(self.convolution.input_channels)
            + " -gline_length_wght="
            + str(self.accelerator.line_length_wght)
            + " -gaddr_width_wght="
            + str(math.ceil(math.log2(self.accelerator.line_length_wght)))
            + " -gline_length_iact="
            + str(self.accelerator.line_length_iact)
            + " -gaddr_width_iact="
            + str(math.ceil(math.log2(self.accelerator.line_length_iact)))
            + " -gline_length_psum="
            + str(self.accelerator.line_length_psum)
            + " -gaddr_width_psum="
            + str(math.ceil(math.log2(self.accelerator.line_length_psum)))
            + " -gaddr_width_iact_mem="
            + str(self.accelerator.mem_size_iact)
            + " -gaddr_width_wght_mem="
            + str(self.accelerator.mem_size_wght)
            + " -gaddr_width_psum_mem="
            + str(self.accelerator.mem_size_psum)
            + " -gsize_x="
            + str(self.accelerator.size_x)
            + " -gsize_y="
            + str(self.accelerator.size_y)
            + " -gsize_rows="
            + str(self.accelerator.size_x + self.accelerator.size_y - 1)
            + " -gaddr_width_x="
            + str(math.ceil(math.log2(self.accelerator.size_x)))
            + " -gaddr_width_y="
            + str(math.ceil(math.log2(self.accelerator.size_y)))
            + " -gaddr_width_rows="
            + str(
                math.ceil(
                    math.log2(self.accelerator.size_x + self.accelerator.size_y - 1)
                )
            )
            + " -gg_iact_fifo_size="
            + str(self.accelerator.iact_fifo_size)
            + " -gg_wght_fifo_size="
            + str(self.accelerator.wght_fifo_size)
            + " -gg_psum_fifo_size="
            + str(self.accelerator.psum_fifo_size)
            + " -gg_h2="
            + str(self.H2)
            + " -gg_m0="
            + str(self.M0)
            + " -gg_init_sp="
            + "True"
            + " -gg_files_dir="
            + "./"
        )
        myenv["MTI_VCO_MODE"] = "64"

        with open(os.devnull, "wb") as devnull:
            try:
                shutil.copyfile("modelsim.ini", self.test_dir + "modelsim.ini")
                shutil.copyfile("run_batch.do", self.test_dir + "run_batch.do")
                shutil.copyfile(
                    "sources_batch.tcl", self.test_dir + "sources_batch.tcl"
                )
                if self.show_output:
                    check_call(
                        [
                            "/tools/cadence/mentor/2020-21/RHELx86/QUESTA-CORE-PRIME_2020.4/questasim/bin/vsim",
                            "-c",
                            "-do",
                            "run_batch.do",
                        ],
                        stdout=subprocess.STDOUT,
                        stderr=subprocess.STDOUT,
                        env=myenv,
                        cwd=self.test_dir,
                    )
                else:
                    with open(self.test_dir + "_log.txt", "w+") as f:
                        check_call(
                            [
                                "/tools/cadence/mentor/2020-21/RHELx86/QUESTA-CORE-PRIME_2020.4/questasim/bin/vsim",
                                "-c",
                                "-do",
                                "run_batch.do",
                            ],
                            stdout=f,
                            stderr=subprocess.STDOUT,
                            env=myenv,
                            cwd=self.test_dir,
                        )
            except CalledProcessError as e:
                print("Error while running test: ", self.name, " : ", e.output)
                return False
        return self._evaluate()

    def _evaluate(self):
        try:
            # read actual output from file ../_output.txt
            actual_output = np.loadtxt(self.test_dir + "_output.txt")
            # iterate over actual_output and store in 2d array every output_size values
            output_size = self.convolution.image_size - self.convolution.kernel_size + 1
            actual_output_2d = np.zeros(
                (actual_output.shape[0] // output_size, output_size)
            )
            for i in range(actual_output.shape[0] // output_size):
                actual_output_2d[i] = actual_output[
                    i * output_size : i * output_size + output_size
                ]

            np.savetxt(
                self.test_dir + "_actual_output.txt",
                actual_output_2d,
                fmt="%d",
                delimiter=" ",
            )

            index = 0
            index_convolution_stack = 0
            index_m = np.zeros(self.M0)
            row_m = np.zeros(self.M0)
            # compare expected output with actual output
            for h2 in range(self.H2):
                for x in range(self.accelerator.size_x):
                    for m0_count in range(self.M0):
                        if index < self.convolution.image_size * self.M0:
                            valid_rows = (
                                self.convolution.image_size
                                - (m0_count + 1) * self.convolution.kernel_size
                                + 1
                            )
                            pause_rows = self.convolution.kernel_size - 1
                            start_row = m0_count * self.convolution.kernel_size
                            if index_m[m0_count] == 0:
                                row_m[m0_count] = start_row
                            # if index == 0:
                            # print("valid_rows = ", valid_rows , " pause_rows = ", pause_rows, " start_row = ", start_row)
                            if (
                                index_m[m0_count] < valid_rows
                                or index_m[m0_count] >= valid_rows + pause_rows
                            ):
                                index_convolution_stack = int(
                                    row_m[m0_count] + m0_count * output_size
                                )
                                index_actual_output = index
                                if (
                                    all(
                                        actual_output_2d[index_actual_output, :]
                                        == self.convolved_images_stack[
                                            index_convolution_stack, :
                                        ]
                                    )
                                    == True
                                ):
                                    #print(self.name + ": Row OK")
                                    pass
                                else:
                                    print(
                                        self.name + ": ERR: got row",
                                        actual_output_2d[index_actual_output, :],
                                    )
                                    print(
                                        self.name + ": expected row",
                                        self.convolved_images_stack[
                                            index_convolution_stack, :
                                        ],
                                    )
                                    print(
                                        self.name + ": index_actual_output = ",
                                        index_actual_output,
                                        " index_convolution_stack = ",
                                        index_convolution_stack,
                                    )
                                    return False
                                if row_m[m0_count] == output_size - 1:
                                    row_m[m0_count] = 0
                                else:
                                    row_m[m0_count] += 1
                            index += 1
                            index_m[m0_count] += 1
            print("Success: ", self.name)
            return True
        except IndexError as e:
            print("Error while evaluating test: ", self.name, " : ", str(e))
            return False
        


def run_test(setting):
    test = Test(setting.name, setting.convolution, setting.accelerator, False)
    test.generate_test(setting.name, "test/" + setting.name + "/")
    return test.run()


if __name__ == "__main__":
    # Define convolution parameters
    image_size = 32
    kernel_size = 3
    input_channels = 20
    output_channels = 3
    input_bits = 4

    # Define accelerator parameters
    size_x = 7
    size_y = 10
    line_length_iact = 32  # word length
    line_length_psum = 128  # word length
    line_length_wght = 32  # word length
    mem_size_iact = 16  # addressable memory size in bits
    mem_size_psum = 16  # addressable memory size in bits
    mem_size_wght = 15  # addressable memory size in bits
    iact_fifo_size = 15
    wght_fifo_size = 15
    psum_fifo_size = 128

    image_size = [16, 17, 18, 20, 21]
    kernel_size = [1, 3, 5, 7]
    input_channels = [3, 10, 20, 30]
    
    #image_size = [16]
    #kernel_size = [5]
    #input_channels = [8]
    
    #image_size = [16, 28, 42, 65]
    #kernel_size = [1, 3, 5, 7]
    
    # 18/1 21/7 20/7 17/7 18/7 16/7
    
    #image_size = [17]
    #kernel_size = [7]
    
    settings = []

    outputs = []

    for i in image_size:
        for j in kernel_size:
            for c in input_channels:
                settings.append(
                    Setting(
                        "image_size_" + str(i) + "_kernel_size_" + str(j)+"_c_"+str(c),
                        Convolution(i, j, c, output_channels, input_bits),
                        Accelerator(
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
                        ),
                    )
                )
            
    pool = Pool(128)
    outputs = pool.map(run_test, settings)

    print("Outputs: ", outputs)

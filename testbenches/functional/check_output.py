import numpy as np
import math
import os
import sys

kernel_size = 1 #(R = S)
image_size = 16 #(H = W)
channels = 2

input_bits = 5

line_length_wght = 32
line_length_iact = line_length_wght
line_length_psum = 128

mem_size_iact = 15
mem_size_wght = 15
mem_size_psum = 15

size_x = 7
size_y = 10

M0 = math.floor(size_y/kernel_size)
H1 = size_x

size_rows = size_x + size_y - 1
if M0 == 0:
    H2 = math.ceil((image_size - kernel_size + 1)/size_x)
else:
    H2 = math.ceil(image_size / size_x)

C0 = math.floor(line_length_wght/kernel_size)
if channels * kernel_size < line_length_wght:
    C0 = channels

C1 = math.ceil(channels / C0)

C0_last = channels - (C1 - 1) * C0

os.environ["generics"] = "-gg_kernel_size=" + str(kernel_size) + " -gg_image_y=" + str(image_size) + " -gg_image_x=" + str(image_size) +  " -gg_channels=" + str(channels) + " -gline_length_wght=" + str(line_length_wght) +" -gaddr_width_wght=" + str(math.ceil(math.log2(line_length_wght))) +" -gline_length_iact=" + str(line_length_iact) + " -gaddr_width_iact=" + str(math.ceil(math.log2(line_length_iact))) +  " -gline_length_psum=" + str(line_length_psum) + " -gaddr_width_psum=" + str(math.ceil(math.log2(line_length_psum))) +                         " -gaddr_width_iact_mem=" + str(mem_size_iact) + " -gaddr_width_wght_mem=" + str(mem_size_wght) + " -gaddr_width_psum_mem=" + str(mem_size_psum) + " -gsize_x=" + str(size_x) + " -gsize_y=" + str(size_y) + " -gsize_rows=" + str(size_x + size_y - 1) + " -gaddr_width_x=" + str(math.ceil(math.log2(size_x))) + " -gaddr_width_y=" + str(math.ceil(math.log2(size_y))) + " -gaddr_width_rows=" + str(math.ceil(math.log2(size_x + size_y - 1))) + " -gg_tiles_y=" + str(2) + " -gg_columns_last_tile_y=" + str(6)

#print("H2 = ", H2)
#print("C1 = ", C1)
#print("C0 = ", C0)
#print("C0_last = ", C0_last)


np.random.seed(2)
st = np.random.get_state()
#print(st)

#print range of input_bits signed numbers
#print("Input range: ", -(2**(input_bits-1)), " to ", (2**(input_bits-1))-1)

#state = ['MT19937', key_array, 624, 0, 0.0]

def convolution2d(image, kernel, bias):
    m, n = kernel.shape
    if (m == n):
        y, x = image.shape
        y = y - m + 1
        x = x - m + 1
        new_image = np.zeros((y,x))
        for i in range(y):
            for j in range(x):
                new_image[i][j] = np.sum(image[i:i+m, j:j+m]*kernel) + bias
    #else:
        #print("Kernel size is not equal")
        #print("Kernel size is: ", m, n)
        #print("Kernel is: ", kernel)
        #print("Image size is: ", image.shape)
    return new_image

# create array with random filter weights
kernel = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (kernel_size * channels, kernel_size))

kernels = np.zeros((M0, kernel_size * channels, kernel_size))
# create M0 kernels
for k in range(M0):
    #kernels[k] = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (kernel_size * channels, kernel_size))
    # TODO for now just copy the first kernel
    kernels[k] = kernel

# create array with random input activations ("image")
image = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (image_size * channels, image_size))

#create empty array for convolved image
convolved_channel = np.zeros((channels, image_size - kernel_size + 1, image_size - kernel_size + 1))
convolved_channels = np.zeros((M0, channels, image_size - kernel_size + 1, image_size - kernel_size + 1))

for c in range(channels):
    #iterate over the image and convolve each channel
    image_channel = image[c*image_size:(c+1)*image_size, :]
    kernel_channel = kernel[c*kernel_size:(c+1)*kernel_size, :]
    #print("image_channel", image_channel)
    convolved_channel[c,:,:] = convolution2d(image_channel, kernel_channel, 0)
    #print("convolved_channel", convolved_channel)
    #print(convolution2d(image[c*image_size:(c+1)*image_size,:], kernel[(c*kernel_size):((c+1)*kernel_size-1),:], 0))
    for k in range(M0):
        convolved_channels[k,c,:,:] = convolution2d(image_channel, kernels[k,c*kernel_size:(c+1)*kernel_size, :], 0)

# sum over all channels
convolved_image = np.sum(convolved_channel, axis=0)
convolved_images = np.sum(convolved_channels, axis=1)

# stack the convolved images
for k in range(M0):
    if k == 0:
        convolved_images_stack = convolved_images[k,:,:]
    else:
        convolved_images_stack = np.vstack((convolved_images_stack, convolved_images[k,:,:]))

# stack the kernels
for k in range(M0):
    if k == 0:
        kernels_stack = kernels[k,:,:]
    else:
        kernels_stack = np.vstack((kernels_stack, kernels[k,:,:]))
kernels_stack = kernels_stack.astype(int)

#print("convolved_image_shape: ", convolved_image.shape)
#print("convolved_images_shape: ", convolved_images.shape)
#print("convolved_images_stack_shape: ", convolved_images_stack.shape)

# save data as txt files
np.savetxt('src/_image.txt', image, fmt='%d', delimiter=' ')
np.savetxt('src/_kernel.txt', kernel, fmt='%d', delimiter=' ')
np.savetxt('src/_kernel_stack.txt', kernels_stack, fmt='%d', delimiter=' ')
np.savetxt('src/_convolution.txt', convolved_image, fmt='%d', delimiter=' ')
np.savetxt('src/_convolution_stack.txt', convolved_images_stack, fmt='%d', delimiter=' ')

#save mem files
#save image as 8-bit binary values in _mem_iact.txt in two's complement
with open('src/_mem_iact.txt', 'w') as f:
    for i in range(image_size * channels):
        for j in range(image_size):
            f.write('{0:08b} '.format(image[i][j] & 0xFF) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_iact)
    for i in range(2**mem_size_iact - image.shape[0] * image.shape[1]):
        f.write('{0:08b}'.format(0) + '\n')

with open('src/_mem_iact_dec.txt', 'w') as f:
    for i in range(image_size * channels):
        for j in range(image_size):
            f.write(str(image[i][j]) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_iact)
    for i in range(2**mem_size_iact - image.shape[0] * image.shape[1]):
        f.write(str(0) + '\n')

#print("Pixels : " + str(image.shape[0] * image.shape[1]))

#save kernel as 8-bit binary values in _mem_wght.txt in two's complement
with open('src/_mem_wght.txt', 'w') as f:
    for i in range(kernel_size * channels):
        for j in range(kernel_size):
            f.write('{0:08b} '.format(kernel[i][j] & 0xFF) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_wght)
    for i in range(2**mem_size_wght - kernel.shape[0] * kernel.shape[1]):
        f.write('{0:08b}'.format(0) + '\n')

# save kernels as 8-bit binary values in _mem_wght_stack.txt in two's complement
with open('src/_mem_wght_stack.txt', 'w') as f:
    for i in range(kernel_size * channels * M0):
        for j in range(kernel_size):
            f.write('{0:08b} '.format(kernels_stack[i][j] & 0xFF) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_wght)
    for i in range(2**mem_size_wght - kernels.shape[0] * kernels.shape[1] * kernels.shape[2]):
        f.write('{0:08b}'.format(0) + '\n')


#save zeros as 8-bit binary values in _mem_psum.txt
with open('src/_mem_psum.txt', 'w') as f:
    for i in range(2**mem_size_psum):
        f.write('{0:016b}'.format(0) + '\n')



# reorder image to be able to check iact input
image_tmp = image
image = np.zeros((size_rows, image_size * channels * H2))
column=0
#print("Reordered shape : ",  image.shape)
for tile_y in range(H2):
    #print("tile_y = ", tile_y)
    #print("############################")
    #print("############################")
    #print("############################")
    for tile_c in range(C1):
        if tile_c == C1 - 1:
            c0 = C0_last
        else:
            c0 = C0
        #print(c0)
        for i in range(image_size):
            for c in range(c0):
                #print("c = ", c)
                #print("tile_c = ", tile_c)
                channel = c+tile_c*C0
                for h in range(size_rows):
                    h_ = tile_y * size_x + h
                    while h_ >= image_size:
                        h_ -= image_size
                    index = channel * image_size + h_
                    #print("Address : c=", c, " tile_c=", tile_c, " tile_y=", tile_y, " index=", index, " channel=",channel, " x=", i, " h=", h, " h_=", h_)
                    if index >= image_tmp.shape[0]:
                        image[h, column] = 0
                        #print("err ---")
                    else:
                        image[h, column] = image_tmp[index, i]
                column += 1
                    
                #image[:, column] = image_tmp[index : index + size_rows  , i]
                #column += 1
#print("image shape : ", image.shape)
#np.savetxt('_kernel_reordered.txt', kernel, fmt='%d', delimiter=' ')
np.savetxt('src/_image_reordered_2.txt', image, fmt='%d', delimiter=' ')

#read actual output from file ../_output.txt
actual_output = np.loadtxt('_output.txt')
#iterate over actual_output and store in 2d array every output_size values
output_size = image_size - kernel_size + 1
actual_output_2d = np.zeros((actual_output.shape[0] // output_size, output_size))
for i in range(actual_output.shape[0] // output_size):
    actual_output_2d[i] = actual_output[i * output_size : i * output_size + output_size]

np.savetxt('src/_actual_output.txt', actual_output_2d, fmt='%d', delimiter=' ')

index = 0
index_convolution_stack = 0
index_m = np.zeros(M0)
row_m = np.zeros(M0)
#compare expected output with actual output
for h2 in range(H2):
    for x in range(size_x):
        for m0_count in range(M0):
            if index < image_size * M0:
                valid_rows = image_size - (m0_count + 1) * kernel_size + 1
                pause_rows = kernel_size - 1
                start_row  = m0_count * kernel_size
                if index_m[m0_count] == 0:
                    row_m[m0_count] = start_row
                if index == 0:
                    print("valid_rows = ", valid_rows , " pause_rows = ", pause_rows, " start_row = ", start_row)
                if index_m[m0_count] < valid_rows or index_m[m0_count] >= valid_rows + pause_rows:
                    index_convolution_stack = int(row_m[m0_count] + m0_count * output_size)
                    index_actual_output = index
                    print("index_convolution_stack = ", index_convolution_stack, " index_actual_output = ", index_actual_output, " row_m[m0_count] = ", int(row_m[m0_count]), " m0_count = ", m0_count, " index_m[m0_count] = ", int(index_m[m0_count]))
                    if all(actual_output_2d[index_actual_output,:] == convolved_images_stack[index_convolution_stack,:]) == True:
                        #print("Row OK")
                        pass
                    else:
                        print("ERR: got row" , actual_output_2d[index_actual_output,:])
                        print("expected row" , convolved_images_stack[index_convolution_stack,:])
                        print("index_actual_output = ", index_actual_output, " index_convolution_stack = ", index_convolution_stack)
                        #sys.exit("Row not OK")
                    if row_m[m0_count] == output_size - 1:
                        row_m[m0_count] = 0
                    else:
                        row_m[m0_count] += 1
                else:
                    print("Pause : ", index_m[m0_count], "valid_rows = ", valid_rows , " pause_rows = ", pause_rows, " start_row = ", start_row)
                index += 1
                index_m[m0_count] += 1

print(H2)
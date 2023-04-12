import numpy as np
import math

kernel_size = 5
image_size = 29
channels = 10
input_bits = 3

line_length_wght = 32

mem_size_iact = 15
mem_size_wght = 15
mem_size_psum = 15

size_rows = 2 * kernel_size - 1
tiles = math.ceil((image_size - kernel_size + 1) / kernel_size)

C0 = math.floor(line_length_wght/kernel_size)
if channels * kernel_size < line_length_wght:
    C0 = channels

tiles_c = math.ceil(channels / C0)

C0_last = channels - (tiles_c - 1) * C0



print("tiles_y = ", tiles)
print("tiles_c = ", tiles_c)
print("C0 = ", C0)
print("C0_last = ", C0_last)


np.random.seed(2)
st = np.random.get_state()
#print(st)

#print range of input_bits signed numbers
print("Input range: ", -(2**(input_bits-1)), " to ", (2**(input_bits-1))-1)

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
    else:
        print("Kernel size is not equal")
        print("Kernel size is: ", m, n)
        print("Kernel is: ", kernel)
        print("Image size is: ", image.shape)
    return new_image

# create array with random filter weights
#kernel = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (kernel_size * int(channels/channels), kernel_size)) # TODO MODIFIED for channel test
kernel = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (kernel_size * channels, kernel_size)) # TODO Original
# concatenate channel times kernel
#kernel = np.concatenate([kernel]*channels, axis=0)# TODO ADDED for channel test


print(kernel.shape)
# kernel = np.array([[1,2,1],[2,3,2],[3,4,3]])

# create array with random input activations ("image")
#image = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (image_size * int(channels/channels), image_size)) # TODO MODIFIED for channel test
image = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (image_size * channels, image_size)) # TODO Original
# concatenate channel times image
#image = np.concatenate([image]*channels, axis=0) # TODO ADDED for channel test
# size_x = 9
# size_y = 10

# image = np.zeros((size_y,size_x))
# for i in range(size_y):
#     for j in range(size_x):
#         image[i][j] = i*size_x + j + 1


#create empty array for convolved image
convolved_channel = np.zeros((channels, image_size - kernel_size + 1, image_size - kernel_size + 1))

for c in range(channels):
    #iterate over the image and convolve each channel
    image_channel = image[c*image_size:(c+1)*image_size, :]
    kernel_channel = kernel[c*kernel_size:(c+1)*kernel_size, :]
    #print("image_channel", image_channel)
    convolved_channel[c,:,:] = convolution2d(image_channel, kernel_channel, 0)
    #print("convolved_channel", convolved_channel)
    #print(convolution2d(image[c*image_size:(c+1)*image_size,:], kernel[(c*kernel_size):((c+1)*kernel_size-1),:], 0))

#sum over all channels
convolved_image = np.sum(convolved_channel, axis=0)

# save data as txt files
np.savetxt('_image.txt', image, fmt='%d', delimiter=' ')
np.savetxt('_kernel.txt', kernel, fmt='%d', delimiter=' ')
np.savetxt('_convolution.txt', convolved_image, fmt='%d', delimiter=' ')

#save mem files
#save image as 8-bit binary values in _mem_iact.txt in two's complement
with open('_mem_iact.txt', 'w') as f:
    for i in range(image_size * channels):
        for j in range(image_size):
            f.write('{0:08b} '.format(image[i][j] & 0xFF) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_iact)
    for i in range(2**mem_size_iact - image.shape[0] * image.shape[1]):
        f.write('{0:08b}'.format(0) + '\n')

with open('_mem_iact_dec.txt', 'w') as f:
    for i in range(image_size * channels):
        for j in range(image_size):
            f.write(str(image[i][j]) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_iact)
    for i in range(2**mem_size_iact - image.shape[0] * image.shape[1]):
        f.write(str(0) + '\n')

print("Pixels : " + str(image.shape[0] * image.shape[1]))


#save kernel as 8-bit binary values in _mem_wght.txt in two's complement
with open('_mem_wght.txt', 'w') as f:
    for i in range(kernel_size * channels):
        for j in range(kernel_size):
            f.write('{0:08b} '.format(kernel[i][j] & 0xFF) + '\n')
    #Append zeros to fill up memory (until 2 ** mem_size_wght)
    for i in range(2**mem_size_wght - kernel.shape[0] * kernel.shape[1]):
        f.write('{0:08b}'.format(0) + '\n')


#save zeros as 8-bit binary values in _mem_psum.txt
with open('_mem_psum.txt', 'w') as f:
    for i in range(2**mem_size_psum):
        f.write('{0:016b}'.format(0) + '\n')



# reorder kernel in slices of kernel_size x kernel_size
kernel_tmp = kernel
print(" Kernel TMP SHAPE", kernel_tmp.shape)

kernel = np.zeros((kernel_size, kernel_size * channels))
column=0
print("Reordered shape : ",  kernel.shape)
for tile_c in range(tiles_c):
    if tile_c == tiles_c - 1:
        c0 = C0_last
    else:
        c0 = C0
    #print(c0)
    for i in range(kernel_size):
        for c in range(c0):
            #print("c = ", c)
            #print("tile_c = ", tile_c)
            channel = c+tile_c*C0
            index = channel * kernel_size
            print("Address : c=", c, " tile_c=", tile_c, " channel=", channel, " index=", index, " x=", i)
            #print("index 1 : ", index)
            #print("index 2 : ", index + kernel_size - 1)
            #print(kernel_tmp[index : index + kernel_size  , i])
            kernel[:, column] = kernel_tmp[index : index + kernel_size  , i]
            column += 1

#kernel = np.concatenate((kernel, kernel_tmp[i*kernel_size:i*kernel_size+kernel_size,:]), axis=1)

# concatenate tiles times kernel horizontally, TILE_Y 
kernel = np.concatenate([kernel]*tiles, axis=1)

print("############################")
print("############################")
print("############################")

# reorder image
image_tmp = image
print(" Image TMP SHAPE", image_tmp.shape)
image = np.zeros((size_rows, image_size * channels * tiles))
column=0
print("Reordered shape : ",  image.shape)
for tile_y in range(tiles):
    #print("tile_y = ", tile_y)
    #print("############################")
    #print("############################")
    #print("############################")
    for tile_c in range(tiles_c):
        if tile_c == tiles_c - 1:
            c0 = C0_last
        else:
            c0 = C0
        #print(c0)
        for i in range(image_size):
            for c in range(c0):
                #print("c = ", c)
                #print("tile_c = ", tile_c)
                channel = c+tile_c*C0
                index = channel * image_size + tile_y * kernel_size
                print("Address : c=", c, " tile_c=", tile_c, " tile_y=", tile_y, " index=", index, " channel=",channel, " x=", i)
                #print("index 1 : ", index)
                #print("index 2 : ", index + size_rows - 1)
                #if c0 == C0_last:
                    #print("Image pixel --- : ", image_tmp[index, i])
                image[:, column] = image_tmp[index : index + size_rows  , i]
                column += 1

np.savetxt('_kernel_reordered.txt', kernel, fmt='%d', delimiter=' ')
np.savetxt('_image_reordered.txt', image, fmt='%d', delimiter=' ')
import numpy as np

kernel_size = 5
image_size = 19
channels = 3
input_bits = 3

np.random.seed(None)
st = np.random.get_state()
print(st)

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
kernel = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (kernel_size * channels, kernel_size))
# kernel = np.array([[1,2,1],[2,3,2],[3,4,3]])

# create array with random input activations ("image")
image = np.random.randint(-(2**(input_bits-1)), (2**(input_bits-1))-1, (image_size * channels, image_size))
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
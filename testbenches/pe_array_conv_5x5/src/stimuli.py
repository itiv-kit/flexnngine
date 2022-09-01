import numpy as np

kernel_size = 5

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
    return new_image

# create array with random values from -10 to 10
kernel = np.random.randint(-10, 10, (kernel_size, kernel_size))
# kernel = np.array([[1,2,1],[2,3,2],[3,4,3]])

# create 10x10 array with random values from -100 to 100
image = np.random.randint(-100, 100, (19, 19))
# size_x = 9
# size_y = 10

# image = np.zeros((size_y,size_x))
# for i in range(size_y):
#     for j in range(size_x):
#         image[i][j] = i*size_x + j + 1

print(image)

print(convolution2d(image, kernel, 0))

# save data as txt files
np.savetxt('_image.txt', image, fmt='%d', delimiter=' ')
np.savetxt('_kernel.txt', kernel, fmt='%d', delimiter=' ')
np.savetxt('_convolution.txt', convolution2d(image, kernel, 0), fmt='%d', delimiter=' ')
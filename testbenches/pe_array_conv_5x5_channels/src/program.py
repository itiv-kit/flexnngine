import numpy as np

np.set_printoptions(precision=1)

channels = 3
kernel_size = 5
size_x = 5 # PE array width
size_y = 5 # PE array height
image_size = 19

print("\n")
print("####################")
print("COMMANDS FOR PEs and LINE BUFFERS TO COMPUTE THE CONVOLUTION AND OBTAIN THE PARTIAL SUMS:")
print("####################")

# input read offset iact
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j] = j
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1) + (kernel_size * channels)] = channels

array[-1] = 0
print('\n')
print("Input read offset iact")
print(* array, sep = ", ")
#print('\n', repr(array))

# input read offset wght
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j] = j
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1) + (kernel_size * channels)] = 0

array[-1] = 0
print('\n')
print("Input read offset wght")
print(* array, sep = ", ")
#print('\n', repr(array))

# input read offset psum
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j] = i
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1) + (kernel_size * channels)] = 0

array[-1] = 0
print('\n')
print("Input read offset psum")
print(* array, sep = ", ")
#print('\n', repr(array))

# input update offset psum
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j + 1] = i
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1)] = 0
print('\n')
print("Input update offset psum")
print(* array, sep = ", ")
#print('\n', repr(array))

# input update offset iact, wght
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16);
print('\n')
print("Input update offset iact, wght")
print(* array, sep = ", ")
#print('\n', repr(array))

# input command iact
list = []
for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        list.append('c_lb_read')
    list.append('c_lb_shrink')
list.append('c_lb_idle')
print('\n')
print("Input command iact")
print(*list, sep =', ')

# input command wght
list = []
for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        list.append('c_lb_read')
    list.append('c_lb_idle')
list.append('c_lb_idle')
print('\n')
print("Input command wght")
print(*list, sep =', ')

# input command psum
list = []
for i in range(image_size - kernel_size + 1):
    list.append('c_lb_idle')
    for j in range(kernel_size * channels):
        list.append('c_lb_read_update')
list.append('c_lb_idle')
print('\n')
print("Input command psum")
print(*list, sep =', ')

# input pe command
list = []
for i in range(image_size - kernel_size + 1):
    list.append('c_pe_mux_mac')
    for j in range(kernel_size * channels):
        list.append('c_pe_mux_mac')
list.append('c_pe_mux_mac')
print('\n')
print("Input pe command")
print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))


print("\n")
print("####################")
print("COMMANDS TO ACCUMULATE THE PARTIAL SUMS:")
print("####################")

# output command
print('\n')
print("Output command (psum line buffer)")
for i in range(size_y):
    list = []
    i_ = size_y - i - 1
    idle_blocks = i_ - 1 if i_ - 1 > 0 else 0 # number of idle blocks before read_update
    #idle blocks before read_update
    for j in range(idle_blocks * (image_size - kernel_size + 1)):
        list.append('c_lb_idle')
    #read_update blocks
    if i_ > 0:
        for j in range(image_size - kernel_size + 1):
            list.append('c_lb_read_update')
    #read blocks
    for j in range(image_size - kernel_size + 1):
            list.append('c_lb_read')
    #idle blocks after read
    for j in range(i * (image_size - kernel_size + 1)):
            list.append('c_lb_idle')
    list.append('c_lb_idle')
    print('\n')
    print("Output command, line ", i)
    print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))

# output read offset
print('\n')
print("Output read offset")
for i in range(size_y):
    list = []
    i_ = size_y - i - 1
    idle_blocks = i_ - 1 if i_ - 1 > 0 else 0 # number of idle blocks before read_update
    #idle blocks before read_update
    for j in range(idle_blocks * (image_size - kernel_size + 1)):
        list.append(0)
    #read_update blocks
    if i_ > 0:
        for j in range(image_size - kernel_size + 1):
            list.append(j)
    #read blocks
    for j in range(image_size - kernel_size + 1):
            list.append(j)
    #idle blocks after read
    for j in range(i * (image_size - kernel_size + 1)):
            list.append(0)
    list.append(0)
    print('\n')
    print("Output command, line ", i)
    print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))

# output update offset
print('\n')
print("Output update offset")
for i in range(size_y):
    list = []
    i_ = size_y - i - 1
    idle_blocks = i_ - 1 if i_ - 1 > 0 else 0 # number of idle blocks before read_update
    #idle blocks before read_update
    for j in range(idle_blocks * (image_size - kernel_size + 1)):
        list.append(0)
    #read_update blocks
    if i_ > 0:
        for j in range(image_size - kernel_size + 1):
            list.append(j)
    #read blocks
    for j in range(image_size - kernel_size + 1):
            list.append(0)
    #idle blocks after read
    for j in range(i * (image_size - kernel_size + 1)):
            list.append(0)
    list.append(0)
    print('\n')
    print("Output command, line ", i)
    print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))

# output pe command
print('\n')
print("Output pe command (mux)")
for i in range(size_y):
    list = []
    for j in range(size_y * (image_size - kernel_size + 1)):
        list.append('c_pe_mux_psum')
    list.append('c_pe_mux_psum')
    print('\n')
    print("Output pe command, line ", i)
    print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))
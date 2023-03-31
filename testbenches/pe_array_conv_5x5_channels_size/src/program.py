from calendar import c
import numpy as np
import copy

np.set_printoptions(precision=1)

channels = 5 # number of channels
kernel_size = 5 # 5x5 kernel
size_x = 5 # PE array width
size_y = 5 # PE array height
image_size = 14 # image width and height

output_file = "pe_array_conv_5x5_channels_tb.vhd"

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
list_input_read_offset_iact = [str (x) for x in array.tolist()]
# print('\n')
# print("Input read offset iact")
# print(* array, sep = ", ")
#print('\n', repr(array))

# input read offset wght
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j] = j
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1) + (kernel_size * channels)] = 0

array[-1] = 0
list_input_read_offset_wght = [str (x) for x in array.tolist()]
# print('\n')
# print("Input read offset wght")
# print(* array, sep = ", ")
#print('\n', repr(array))

# input read offset psum
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16); 

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j] = i
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1) + (kernel_size * channels)] = 0

array[-1] = 0
list_input_read_offset_psum = [str (x) for x in array.tolist()]
# print('\n')
# print("Input read offset psum")
# print(* array, sep = ", ")
#print('\n', repr(array))

# input update offset psum
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16)

for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        array[i * (kernel_size * channels + 1) + j + 1] = i
        #array[i*(image_size - kernel_size + 2) + j] = i
    array[i * (kernel_size * channels + 1)] = 0
list_input_update_offset_psum = [str (x) for x in array.tolist()]
# print('\n')
# print("Input update offset psum")
# print(* array, sep = ", ")
#print('\n', repr(array))

# input update offset iact, wght
array = np.zeros((kernel_size * channels + 1) * (image_size - kernel_size + 1) + 1, dtype = np.int16)
list_input_update_offset_iact = [str (x) for x in array.tolist()]
list_input_update_offset_wght = [str (x) for x in array.tolist()]
# print('\n')
# print("Input update offset iact, wght")
# print(* array, sep = ", ")
#print('\n', repr(array))

# input command iact
list_input_command_iact = []
for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        list_input_command_iact.append('c_lb_read')
    list_input_command_iact.append('c_lb_shrink')
list_input_command_iact.append('c_lb_idle')
# print('\n')
# print("Input command iact")
# print(*list_input_command_iact, sep =', ')

# input command wght
list_input_command_wght = []
for i in range(image_size - kernel_size + 1):
    for j in range(kernel_size * channels):
        list_input_command_wght.append('c_lb_read')
    list_input_command_wght.append('c_lb_idle')
list_input_command_wght.append('c_lb_idle')
# print('\n')
# print("Input command wght")
# print(*list_input_command_wght, sep =', ')

# input command psum
list_input_command_psum = []
for i in range(image_size - kernel_size + 1):
    list_input_command_psum.append('c_lb_idle')
    for j in range(kernel_size * channels):
        list_input_command_psum.append('c_lb_read_update')
list_input_command_psum.append('c_lb_idle')
# print('\n')
# print("Input command psum")
# print(*list_input_command_psum, sep =', ')

# input pe command
list_input_pe_command = []
for i in range(image_size - kernel_size + 1):
    list_input_pe_command.append('c_pe_conv_mult')
    for j in range(kernel_size * channels):
        list_input_pe_command.append('c_pe_conv_mult')
list_input_pe_command.append('c_pe_conv_mult')
# print('\n')
# print("Input pe command")
# print(*list_input_pe_command, sep =', ')

print('\n')
print("Required commands: ", len(list_input_pe_command))


print("\n")
print("####################")
print("COMMANDS TO ACCUMULATE THE PARTIAL SUMS:")
print("####################")

# output command
print('\n')
print("Output command (psum line buffer)")
list_output_command = []
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
    list_output_command.append(list)
    # print('\n')
    # print("Output command, line ", i)
    # print(*list, sep =', ')

print('\n')
print("Required commands: ", len(list))

# output read offset
print('\n')
print("Output read offset")
list_output_read_offset = []
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
    list_output_read_offset.append([str (x) for x in list])
    # print('\n')
    # print("Output command, line ", i)
    # print(*list, sep =', ')


# output update offset
print('\n')
print("Output update offset")
list_output_update_offset = []
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
    list_output_update_offset.append([str (x) for x in list])
    # print('\n')
    # print("Output command, line ", i)
    # print(*list, sep =', ')


# output pe command
print('\n')
print("Output pe command (mux)")

list_output_pe_command = []
for j in range(size_y * (image_size - kernel_size + 1)):
    list_output_pe_command.append('c_pe_conv_psum')
list_output_pe_command.append('c_pe_conv_mult')
# print('\n')
# print("Output pe command for all lines")
# print(*list, sep =', ')

# write list to file at position where "output_pe_command" is written

with open(output_file, 'r') as file:
    lines = file.readlines()

    #find occurences of "output_pe_command" in lines
    input_pe_command_occurences = []
    input_command_iact_occurences = []
    input_command_wght_occurences = []
    input_command_psum_occurences = []
    input_read_offset_iact_occurences = []
    input_read_offset_wght_occurences = []
    input_read_offset_psum_occurences = []
    input_update_offset_iact_occurences = []
    input_update_offset_wght_occurences = []
    input_update_offset_psum_occurences = []
    output_read_offset_occurences = []
    output_update_offset_occurences = []
    output_pe_command_occurences = []
    output_command_occurences = []
    command_length_occurences = []
    output_command_length_occurences = []

    for i, line in enumerate(lines):
        if "/*INPUT_PE_COMMAND*/" in line:
            input_pe_command_occurences.append(i)
        if "/*INPUT_COMMAND_IACT*/" in line:
            input_command_iact_occurences.append(i)
        if "/*INPUT_COMMAND_WGHT*/" in line:
            input_command_wght_occurences.append(i)
        if "/*INPUT_COMMAND_PSUM*/" in line:
            input_command_psum_occurences.append(i)
        if "/*INPUT_READ_OFFSET_IACT*/" in line:
            input_read_offset_iact_occurences.append(i)
        if "/*INPUT_READ_OFFSET_WGHT*/" in line:
            input_read_offset_wght_occurences.append(i)
        if "/*INPUT_READ_OFFSET_PSUM*/" in line:
            input_read_offset_psum_occurences.append(i)
        if "/*INPUT_UPDATE_OFFSET_IACT*/" in line:
            input_update_offset_iact_occurences.append(i)
        if "/*INPUT_UPDATE_OFFSET_WGHT*/" in line:
            input_update_offset_wght_occurences.append(i)
        if "/*INPUT_UPDATE_OFFSET_PSUM*/" in line:
            input_update_offset_psum_occurences.append(i)
        if "/*OUTPUT_READ_OFFSET*/" in line:
            output_read_offset_occurences.append(i)
        if "/*OUTPUT_UPDATE_OFFSET*/" in line:
            output_update_offset_occurences.append(i)
        if "/*OUTPUT_PE_COMMAND*/" in line:
            output_pe_command_occurences.append(i)
        if "/*OUTPUT_COMMAND*/" in line:
            output_command_occurences.append(i)
        if "/*COMMAND_LENGTH*/" in line:
            command_length_occurences.append(i)
        if "/*OUTPUT_COMMAND_LENGTH*/" in line:
            output_command_length_occurences.append(i)
    if len(input_pe_command_occurences) == 2 and abs(input_pe_command_occurences[0] - input_pe_command_occurences[1]) == 6:
        start = int(min(input_pe_command_occurences[0], input_pe_command_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_pe_command)
            for j in range(i):
                list_tmp.insert(0, 'c_pe_conv_mult')
            for j in range(size_x - i - 1):
                list_tmp.append('c_pe_conv_mult')
            if i != size_x - 1:
                lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
            else:
                lines[start + i] = "        (" + ",".join(list_tmp) + ")\n"

        #print(lines[mid])
    else:
        print("ERROR: input_pe_command_occurences not found")
        exit
    if len(input_command_iact_occurences) == 2 and abs(input_command_iact_occurences[0] - input_command_iact_occurences[1]) == 6:
        start = int(min(input_command_iact_occurences[0], input_command_iact_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_command_iact)
            for j in range(i):
                list_tmp.insert(0, 'c_lb_idle')
            for j in range(size_x - i - 1):
                list_tmp.append('c_lb_idle')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_command_iact_occurences not found")
        exit
    if len(input_command_wght_occurences) == 2 and abs(input_command_wght_occurences[0] - input_command_wght_occurences[1]) == 6:
        start = int(min(input_command_wght_occurences[0], input_command_wght_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_command_wght)
            for j in range(i):
                list_tmp.insert(0, 'c_lb_idle')
            for j in range(size_x - i - 1):
                list_tmp.append('c_lb_idle')
            if i != size_x - 1:
                lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
            else:
                lines[start + i] = "        (" + ",".join(list_tmp) + ")\n"
        #print(lines[mid])
    else:
        print("ERROR: input_command_wght_occurences not found")
        exit
    if len(input_command_psum_occurences) == 2 and abs(input_command_psum_occurences[0] - input_command_psum_occurences[1]) == 6:
        start = int(min(input_command_psum_occurences[0], input_command_psum_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_command_psum)
            for j in range(i):
                list_tmp.insert(0, 'c_lb_idle')
            for j in range(size_x - i - 1):
                list_tmp.append('c_lb_idle')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_command_psum_occurences not found")
        exit
    if len(input_read_offset_iact_occurences) == 2 and abs(input_read_offset_iact_occurences[0] - input_read_offset_iact_occurences[1]) == 6:
        start = int(min(input_read_offset_iact_occurences[0], input_read_offset_iact_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_read_offset_iact)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_read_offset_iact_occurences not found")
        exit
    if len(input_read_offset_wght_occurences) == 2 and abs(input_read_offset_wght_occurences[0] - input_read_offset_wght_occurences[1]) == 6:
        start = int(min(input_read_offset_wght_occurences[0], input_read_offset_wght_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_read_offset_wght)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            if i != size_x - 1:
                lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
            else:
                lines[start + i] = "        (" + ",".join(list_tmp) + ")\n"
        #print(lines[mid])
    else:
        print("ERROR: input_read_offset_wght_occurences not found")
        exit
    if len(input_read_offset_psum_occurences) == 2 and abs(input_read_offset_psum_occurences[0] - input_read_offset_psum_occurences[1]) == 6:
        start = int(min(input_read_offset_psum_occurences[0], input_read_offset_psum_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_read_offset_psum)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_read_offset_psum_occurences not found")
        exit
    if len(input_update_offset_iact_occurences) == 2 and abs(input_update_offset_iact_occurences[0] - input_update_offset_iact_occurences[1]) == 6:
        start = int(min(input_update_offset_iact_occurences[0], input_update_offset_iact_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_update_offset_iact)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_update_offset_iact_occurences not found")
        exit
    if len(input_update_offset_wght_occurences) == 2 and abs(input_update_offset_wght_occurences[0] - input_update_offset_wght_occurences[1]) == 6:
        start = int(min(input_update_offset_wght_occurences[0], input_update_offset_wght_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_update_offset_wght)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            if i != size_x - 1:
                lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
            else:
                lines[start + i] = "        (" + ",".join(list_tmp) + ")\n"
        #print(lines[mid])
    else:
        print("ERROR: input_update_offset_wght_occurences not found")
        exit
    if len(input_update_offset_psum_occurences) == 2 and abs(input_update_offset_psum_occurences[0] - input_update_offset_psum_occurences[1]) == 6:
        start = int(min(input_update_offset_psum_occurences[0], input_update_offset_psum_occurences[1])) + 1
        for i in range(size_x):
            list_tmp = []
            list_tmp = copy.deepcopy(list_input_update_offset_psum)
            for j in range(i):
                list_tmp.insert(0, '0')
            for j in range(size_x - i - 1):
                list_tmp.append('0')
            lines[start + i] = "        (" + ",".join(list_tmp) + "),\n"
        #print(lines[mid])
    else:
        print("ERROR: input_update_offset_psum_occurences not found")
        exit
    if len(output_read_offset_occurences) == 2 and abs(output_read_offset_occurences[0] - output_read_offset_occurences[1]) == 26:
        start = int(min(output_read_offset_occurences[0], output_read_offset_occurences[1])) + 1
        for i in range(size_y):
            for j in range(size_x):
                list_tmp = []
                list_tmp = copy.deepcopy(list_output_read_offset[i])
                for k in range(j):
                    list_tmp.insert(0, '0')
                for k in range(size_x - j - 1):
                    list_tmp.append('0')
                if i == size_y - 1 and j == size_x - 1:
                    lines[start + i * size_x + j] = "        (" + ",".join(list_tmp) + ")\n"
                else:
                    lines[start + i * size_x + j] = "        (" + ",".join(list_tmp) + "),\n"
    else:
        print("ERROR: output_read_offset_occurences not found")
        exit
    if len(output_update_offset_occurences) == 2 and abs(output_update_offset_occurences[0] - output_update_offset_occurences[1]) == 26:
        start = int(min(output_update_offset_occurences[0], output_update_offset_occurences[1])) + 1
        for i in range(size_y):
            for j in range(size_x):
                list_tmp = []
                list_tmp = copy.deepcopy(list_output_update_offset[i])
                for k in range(j):
                    list_tmp.insert(0, '0')
                for k in range(size_x - j - 1):
                    list_tmp.append('0')
                if i == size_y - 1 and j == size_x - 1:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + ")\n"
                else:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + "),\n"
            #print(lines[start + i])
    else:
        print("ERROR: output_update_offset_occurences not found")
        exit
    if len(output_pe_command_occurences) == 2 and abs(output_pe_command_occurences[0] - output_pe_command_occurences[1]) == 26:
        start = int(min(output_pe_command_occurences[0], output_pe_command_occurences[1])) + 1
        for i in range(size_y):
            for j in range(size_x):
                list_tmp = []
                list_tmp = copy.deepcopy(list_output_pe_command)
                for k in range(j):
                    list_tmp.insert(0, 'c_pe_conv_psum')
                for k in range(size_x - j - 1):
                    list_tmp.append('c_pe_conv_mult')
                if i == size_y - 1 and j == size_x - 1:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + ")\n"
                else:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + "),\n"
    else:
        print("ERROR: output_pe_command_occurences not found")
        exit
    if len(output_command_occurences) == 2 and abs(output_command_occurences[0] - output_command_occurences[1]) == 26:
        start = int(min(output_command_occurences[0], output_command_occurences[1])) + 1
        for i in range(size_y):
            for j in range(size_x):
                list_tmp = []
                list_tmp = copy.deepcopy(list_output_command[i])
                for k in range(j):
                    list_tmp.insert(0, 'c_lb_idle')
                for k in range(size_x - j - 1):
                    list_tmp.append('c_lb_idle')
                if i == size_y - 1 and j == size_x - 1:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + ")\n"
                else:
                    lines[start + i*size_x + j] = "        (" + ",".join(list_tmp) + "),\n"
    else:
        print("ERROR: output_command_occurences not found")
        exit
    if len(output_command_length_occurences) == 2 and abs(output_command_length_occurences[0] - output_command_length_occurences[1]) == 2:
        mid = int((output_command_length_occurences[0] + output_command_length_occurences[1])/2)
        lines[mid] = "        " + str(len(list) + size_x - 1) + "\n"
        #print(lines[mid])
    else:
        print("ERROR: output_command_length_occurences not found")
        exit
    if len(command_length_occurences) == 2 and abs(command_length_occurences[0] - command_length_occurences[1]) == 2:
        mid = int((command_length_occurences[0] + command_length_occurences[1])/2)
        lines[mid] = "        " + str(len(list_input_pe_command) + size_x - 1) + "\n"
        #print(lines[mid])
    else:
        print("ERROR: command_length_occurences not found")
        exit
    

    

    with open(output_file, 'w') as file:
        file.writelines(lines)




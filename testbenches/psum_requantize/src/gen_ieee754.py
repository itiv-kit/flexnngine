#!/usr/bin/env python3

import struct

# https://stackoverflow.com/questions/51179116/ieee-754-python
def float_to_bin(num):
    return struct.pack('!f', num)

for val in [
# 1000 * 0.09 - 26.3 ~= 64
    0.09, -26.3,
# 147 * -0.0673 + 76.7941 = 67 (problem: wird 66?)
    -0.0673, 76.7941,
# -327 * 0.39144 + 0 = -128
    0.39143730886850153, 0,
# 1234 * 0.09724 + 7 = 127
    0.09724473257698542, 7]:
    print(f"{val} in IEEE754 is 0x{float_to_bin(val).hex()}")

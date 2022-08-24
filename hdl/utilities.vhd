library ieee;
    use ieee.std_logic_1164.all;

package utilities is

    type array_t is array (natural range <>) of std_logic_vector;

    type command_line_buffer_t is (c_idle, c_read, c_read_update, c_shrink);

end package utilities;

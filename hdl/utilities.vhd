library ieee;
    use ieee.std_logic_1164.all;

package utilities is

    type std_logic_row_col_t is array (natural  range <>, natural range <>) of std_logic;

    type array_t is array (natural range <>) of std_logic_vector;
    type array_row_col_t is array (natural  range <>, natural range <>) of std_logic_vector;

    type int_line_t is array(natural range <>) of integer;
    type int_image_t is array (natural  range <>, natural range <>) of integer;

    type command_lb_t is (c_lb_idle, c_lb_read, c_lb_read_update, c_lb_shrink);
    type command_lb_array_t is array (natural range <>) of command_lb_t;
    type command_lb_row_col_t is array (natural range <>, natural range <>) of command_lb_t;

    type command_pe_t is (c_pe_mux_mac, c_pe_mux_psum);
    type command_pe_array_t is array (natural range <>) of command_pe_t;
    type command_pe_row_col_t is array (natural range <>, natural range <>) of command_pe_t;

end package utilities;

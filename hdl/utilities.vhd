library ieee;
    use ieee.std_logic_1164.all;

package utilities is

    type array_t is array (natural range <>) of std_logic_vector;

    type command_lb_t is (c_lb_idle, c_lb_read, c_lb_read_update, c_lb_shrink);

    type command_pe_t is (c_pe_mux_mac, c_pe_mux_psum);

end package utilities;

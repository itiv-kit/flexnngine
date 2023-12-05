library ieee;
    use ieee.std_logic_1164.all;
    use std.textio.all;

package utilities is

    type std_logic_row_col_t is array (natural  range <>, natural range <>) of std_logic;

    type array_t is array (natural range <>) of std_logic_vector;
    type array_row_col_t is array (natural  range <>, natural range <>) of std_logic_vector;

    type int_line_t is array(natural range <>) of integer;
    type int_image_t is array (natural range <>, natural range <>) of integer;
    type int_image3_t is array (natural range <>, natural range <>, natural range <>) of integer;

    type command_lb_t is (c_lb_idle, c_lb_read, c_lb_read_update, c_lb_shrink);
    type command_lb_array_t is array (natural range <>) of command_lb_t;
    type command_lb_row_col_t is array (natural range <>, natural range <>) of command_lb_t;

    -- type command_pe_t is (c_pe_mux_mac, c_pe_mux_psum);
    type command_pe_t is (c_pe_conv_mult, c_pe_conv_psum, c_pe_conv_pass, c_pe_gemm_mult, c_pe_gemm_psum);
    type command_pe_array_t is array (natural range <>) of command_pe_t;
    type command_pe_row_col_t is array (natural range <>, natural range <>) of command_pe_t;

    impure function read_file (file_name : string; num_col : integer; num_row : integer) return int_image_t;

    impure function read_file (file_name : string; num_col : integer; num_row : integer; num_channels : integer) return int_image3_t;

    function and_reduce_2d(arr : in std_logic_row_col_t) return std_logic;

end package utilities;

package body utilities is

    impure function read_file (
        file_name : string;
        num_col : integer;
        num_row : integer)
        return int_image_t is

        file     testfile           : text open read_mode is file_name;
        variable row                : line;
        variable v_data_read        : int_line_t(1 to num_col);
        variable v_data_row_counter : integer;
        variable v_input_image      : int_image_t(0 to num_row - 1, 0 to num_col - 1);

    begin

        v_data_row_counter := 0;

        -- read row from input file
        while not endfile(testfile) loop

            v_data_row_counter := v_data_row_counter + 1;
            readline(testfile, row);

            -- read integer from row
            for i in 1 to num_col loop

                read(row, v_data_read(i));
                v_input_image(v_data_row_counter - 1, i - 1) := v_data_read(i);

            end loop;

        end loop;

        return v_input_image;

    end function;

    impure function read_file (
        file_name : string;
        num_col : integer;
        num_row : integer;
        num_channels : integer)
        return int_image3_t is

        file     testfile               : text open read_mode is file_name;
        variable row                    : line;
        variable v_data_read            : int_line_t(1 to num_col);
        variable v_data_row_counter     : integer;
        variable v_data_channel_counter : integer;
        variable v_input_image          : int_image3_t(0 to num_channels - 1, 0 to num_row - 1, 0 to num_col - 1);

    begin

        v_data_row_counter     := 0;
        v_data_channel_counter := 0;

        -- read row from input file
        while not endfile(testfile) loop

            if v_data_row_counter = num_row then
                v_data_row_counter     := 0;
                v_data_channel_counter := v_data_channel_counter + 1;
            end if;

            readline(testfile, row);

            -- read integer from row
            for i in 1 to num_col loop

                read(row, v_data_read(i));
                v_input_image(v_data_channel_counter, v_data_row_counter, i - 1) := v_data_read(i);

            end loop;

            v_data_row_counter := v_data_row_counter + 1;

        end loop;

        return v_input_image;

    end function;

    function and_reduce_2d(arr : in std_logic_row_col_t) return std_logic is
        variable res : std_logic := '1';
    begin
        for y in arr'range(1) loop
            for x in arr'range(2) loop
                res := res and arr(y,x);
            end loop;
        end loop;
        return res;
    end function;

end package body utilities;

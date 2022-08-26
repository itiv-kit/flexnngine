library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity pe_array is
    generic (
        size_x : positive := 3;
        size_y : positive := 3;

        size_rows : positive := 5;

        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 7;
        addr_width_iact  : positive := 3;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 7;
        addr_width_psum  : positive := 4;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 7;
        addr_width_wght  : positive := 3
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_preload_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_preload_psum_valid : in    std_logic;

        command      : in    command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_iact : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_psum : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        command_wght : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

        i_data_iact : in    array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
        i_data_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_data_wght : in    array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

        i_data_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
        i_data_psum_valid : in    std_logic;
        i_data_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

        o_buffer_full_iact : out   std_logic;
        o_buffer_full_psum : out   std_logic;
        o_buffer_full_wght : out   std_logic;

        update_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        update_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        update_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        read_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        read_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        read_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        o_psums       : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        o_psums_valid : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity pe_array;

architecture behavioral of pe_array is

    component pe is
        generic (
            data_width_iact  : positive := 8;
            line_length_iact : positive := 7;
            addr_width_iact  : positive := 3;

            data_width_psum  : positive := 16;
            line_length_psum : positive := 7;
            addr_width_psum  : positive := 4;

            data_width_wght  : positive := 8;
            line_length_wght : positive := 7;
            addr_width_wght  : positive := 3
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            command      : in    command_pe_t;
            command_iact : in    command_lb_t;
            command_psum : in    command_lb_t;
            command_wght : in    command_lb_t;

            data_in_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
            data_in_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
            data_in_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

            data_in_iact_valid : in    std_logic;
            data_in_psum_valid : in    std_logic;
            data_in_wght_valid : in    std_logic;

            buffer_full_iact : out   std_logic;
            buffer_full_psum : out   std_logic;
            buffer_full_wght : out   std_logic;

            update_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
            update_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
            update_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

            read_offset_iact : in    std_logic_vector(addr_width_iact - 1 downto 0);
            read_offset_psum : in    std_logic_vector(addr_width_psum - 1 downto 0);
            read_offset_wght : in    std_logic_vector(addr_width_wght - 1 downto 0);

            data_out       : out   std_logic_vector(data_width_psum - 1 downto 0);
            data_out_valid : out   std_logic
        );
    end component pe;

    component mux is
        generic (
            input_width   : natural;
            input_num     : natural;
            address_width : natural
        );
        port (
            v_i : in    array_t(0 to input_num - 1)(input_width - 1 downto 0);
            sel : in    std_logic_vector(address_width - 1 downto 0);
            z_o : out   std_logic_vector(input_width - 1 downto 0)
        );
    end component mux;

    signal w_data_in_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_iact - 1 downto 0);
    signal w_data_in_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_data_in_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_wght - 1 downto 0);

    signal w_data_in_iact_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_data_in_psum_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_data_in_wght_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_buffer_full_iact : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_psum : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_wght : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_data_out       : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_data_out_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

begin

    -- INPUT ACTIVATIONS ----------------------------------------------------------
    -- Input activations to PEs that are not directly connected to outside of array
    -- Diagonal blue connections in diagram
    /* TODO implement a way to only feed data to the outer PEs to support GEMM */

    iact_wire_y : for y in 0 to size_y - 2 generate

        iact_wire_x : for x in 1 to size_x - 1 generate

            w_data_in_iact(y,x)       <= w_data_in_iact(y + 1, x - 1);
            w_data_in_iact_valid(y,x) <= w_data_in_iact_valid(y + 1, x - 1);

        end generate iact_wire_x;

    end generate iact_wire_y;

    -- Input activations to PEs interfaced on the west
    -- Blue connections in the diagram on the west

    iact_input_y : for i in 0 to size_y - 1 generate

        w_data_in_iact(i,0)       <= i_data_iact(i) when rising_edge(clk);
        w_data_in_iact_valid(i,0) <= i_data_iact_valid(i) when rising_edge(clk);

    end generate iact_input_y;

    -- Input activations to PEs interfaced on the south
    -- Blue connections in the diagram on the south

    iact_input_x : for i in 1 to size_x - 1 generate

        w_data_in_iact(size_y - 1, i)       <= i_data_iact(size_y - 1 + i) when rising_edge(clk);
        w_data_in_iact_valid(size_y - 1, i) <= i_data_iact_valid(size_y - 1 + i) when rising_edge(clk);

    end generate iact_input_x;

    -- WEIGHTS ----------------------------------------------------------
    -- Weights to PEs that are not directly connected to outside of array
    -- Green arrows in the diagram

    wght_wire_x : for x in 1 to size_x - 1 generate

        wght_wire_y : for y in 0 to size_y - 1 generate

            w_data_in_wght(y,x)       <= w_data_in_wght(y, x - 1);
            w_data_in_wght_valid(y,x) <= w_data_in_wght_valid(y, x - 1);

        end generate wght_wire_y;

    end generate wght_wire_x;

    -- Weights to PEs interface on the west
    -- Green arrows in the diagram on the west of the array

    wght_input : for i in 0 to size_y - 1 generate

        w_data_in_wght(i,0)       <= i_data_wght(i) when rising_edge(clk);
        w_data_in_wght_valid(i,0) <= i_data_wght_valid(i) when rising_edge(clk);

    end generate wght_input;

    -- PARTIAL SUMS ---------------------------------------
    -- Partial sums to PEs that are not directly connected to outside of array
    -- Partial sums are fed by the output of the PE south to the PE. (red arrows in diagram)
    -- MUX for preloading psums
    /* TODO use different solution to preload psums / bias to the buffer*/

    psum_wire_y : for y in 0 to size_y - 2 generate

        psum_wire_x : for x in 0 to size_x - 1 generate

            mux_psum_preload : component mux
                generic map (
                    input_width   => data_width_psum,
                    input_num     => 2,
                    address_width => 1
                )
                port map (
                    v_i(0) => w_data_out(y + 1, x),
                    v_i(1) => i_preload_psum,
                    sel(0) => i_preload_psum_valid,
                    z_o    => w_data_in_psum(y,x)
                );

            mux_psum_preload_valid : component mux
                generic map (
                    input_width   => 1,
                    input_num     => 2,
                    address_width => 1
                )
                port map (
                    v_i(0)(0) => w_data_out_valid(y + 1, x),
                    v_i(1)(0) => i_preload_psum_valid,
                    sel(0)    => i_preload_psum_valid,
                    z_o(0)    => w_data_in_psum_valid(y,x)
                );

        -- w_data_in_psum(y,x)       <= w_data_out(y + 1, x);
        -- w_data_in_psum_valid(y,x) <= w_data_out_valid(y + 1, x);

        end generate psum_wire_x;

    end generate psum_wire_y;

    -- Partial sums to PEs that are connected to south. Connect all PEs in the south to the same input (i_data_psum).
    -- Hereby all psums within the PEs in the south can only be filled with the same value (bias).
    /* TODO implement more connectivity to have meaningful bias */

    psum_input : for i in 0 to size_x - 1 generate

        w_data_in_psum(size_y - 1, i)       <= i_data_psum;
        w_data_in_psum_valid(size_y - 1, i) <= i_data_psum_valid;

    end generate psum_input;

    -- Partial sums output from north PE row. This is the actual output of the PE array.

    psum_output : for i in 0 to size_x - 1 generate

        o_psums(i)       <= w_data_out(0, i);
        o_psums_valid(i) <= w_data_out_valid(0, i);

    end generate psum_output;

    -- OUTPUT BUFFER FULL SIGNALS
    /* TODO just concatenated and just for 3x3 atm*/

    -- o_buffer_full_iact <= and w_buffer_full_iact;

    o_buffer_full_iact <= w_buffer_full_iact(0, 0) and w_buffer_full_iact(0, 1) and w_buffer_full_iact(0, 2) and w_buffer_full_iact(1, 0) and w_buffer_full_iact(1, 1) and w_buffer_full_iact(1, 2) and w_buffer_full_iact(2, 0) and w_buffer_full_iact(2, 1) and w_buffer_full_iact(2, 2);
    o_buffer_full_psum <= w_buffer_full_psum(0, 0) and w_buffer_full_psum(0, 1) and w_buffer_full_psum(0, 2) and w_buffer_full_psum(1, 0) and w_buffer_full_psum(1, 1) and w_buffer_full_psum(1, 2) and w_buffer_full_psum(2, 0) and w_buffer_full_psum(2, 1) and w_buffer_full_psum(2, 2);
    o_buffer_full_wght <= w_buffer_full_wght(0, 0) and w_buffer_full_wght(0, 1) and w_buffer_full_wght(0, 2) and w_buffer_full_wght(1, 0) and w_buffer_full_wght(1, 1) and w_buffer_full_wght(1, 2) and w_buffer_full_wght(2, 0) and w_buffer_full_wght(2, 1) and w_buffer_full_wght(2, 2);

    -- GENERATE PE ---------
    -- Generate PE instances

    pe_inst_y : for y in 0 to size_y - 1 generate

        pe_inst_x : for x in 0 to size_x - 1 generate

            pe_inst : component pe
                generic map (
                    data_width_iact  => data_width_iact,
                    line_length_iact => line_length_iact,
                    addr_width_iact  => addr_width_iact,
                    data_width_psum  => data_width_psum,
                    line_length_psum => line_length_psum,
                    addr_width_psum  => addr_width_psum,
                    data_width_wght  => data_width_wght,
                    line_length_wght => line_length_wght,
                    addr_width_wght  => addr_width_wght
                )
                port map (
                    clk                => clk,
                    rstn               => rstn,
                    command            => command(y,x),
                    command_iact       => command_iact(y,x),
                    command_psum       => command_psum(y,x),
                    command_wght       => command_wght(y,x),
                    data_in_iact       => w_data_in_iact(y,x),
                    data_in_psum       => w_data_in_psum(y,x),
                    data_in_wght       => w_data_in_wght(y,x),
                    data_in_iact_valid => w_data_in_iact_valid(y,x),
                    data_in_psum_valid => w_data_in_psum_valid(y,x),
                    data_in_wght_valid => w_data_in_wght_valid(y,x),
                    buffer_full_iact   => w_buffer_full_iact(y,x),
                    buffer_full_psum   => w_buffer_full_psum(y,x),
                    buffer_full_wght   => w_buffer_full_wght(y,x),
                    update_offset_iact => update_offset_iact(y,x),
                    update_offset_psum => update_offset_psum(y,x),
                    update_offset_wght => update_offset_wght(y,x),
                    read_offset_iact   => read_offset_iact(y,x),
                    read_offset_psum   => read_offset_psum(y,x),
                    read_offset_wght   => read_offset_wght(y,x),
                    data_out           => w_data_out(y,x),
                    data_out_valid     => w_data_out_valid(y,x)
                );

        end generate pe_inst_x;

    end generate pe_inst_y;

end architecture behavioral;

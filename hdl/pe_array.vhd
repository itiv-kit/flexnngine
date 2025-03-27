library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library accel;
    use accel.utilities.all;

entity pe_array is
    generic (
        size_x : positive := 3;
        size_y : positive := 3;

        size_rows : positive := 5;

        data_width_iact  : positive := 8;
        line_length_iact : positive := 32;
        addr_width_iact  : positive := 5;

        data_width_psum  : positive := 16;
        line_length_psum : positive := 2048;
        addr_width_psum  : positive := 11;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 32;
        addr_width_wght  : positive := 5
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        i_preload_psum       : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_preload_psum_valid : in    std_logic;

        i_enable       : in    std_logic;
        i_command      : in    command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        i_command_iact : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        i_command_psum : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
        i_command_wght : in    command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

        i_data_iact : in    array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
        i_data_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
        i_data_wght : in    array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

        i_data_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
        i_data_psum_valid : in    std_logic;
        i_data_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

        o_buffer_full_iact : out   std_logic_vector(size_rows - 1 downto 0);
        o_buffer_full_psum : out   std_logic;
        o_buffer_full_wght : out   std_logic_vector(size_y - 1 downto 0);

        o_buffer_full_next_iact : out   std_logic_vector(size_rows - 1 downto 0);
        o_buffer_full_next_psum : out   std_logic;
        o_buffer_full_next_wght : out   std_logic_vector(size_y - 1 downto 0);

        i_update_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        i_update_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        i_update_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        i_read_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
        i_read_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
        i_read_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

        o_psums          : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
        o_psums_valid    : out   std_logic_vector(size_x - 1 downto 0);
        o_psums_halfword : out   std_logic_vector(size_x - 1 downto 0)
    );
end entity pe_array;

architecture behavioral of pe_array is

    signal w_data_in_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_iact - 1 downto 0);
    signal w_data_in_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_data_in_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_wght - 1 downto 0);

    signal w_data_in_iact_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_data_in_psum_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_data_in_wght_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_buffer_full_iact : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_psum : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_wght : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_buffer_full_next_iact : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_next_psum : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_buffer_full_next_wght : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_data_out       : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_data_out_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_psums_bias       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_bias_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_psums_act       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_act_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_data_in       : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_data_in_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal w_data_out_iact       : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_iact - 1 downto 0);
    signal w_data_out_wght       : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(data_width_wght - 1 downto 0);
    signal w_data_out_iact_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_data_out_wght_valid : std_logic_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    signal r_enable : std_logic_vector(size_x - 1 downto 0);

begin

    -- Enable / stall signals. Propagate through array in x-direction
    r_enable(0) <= i_enable when rising_edge(clk);

    enable : for x in 1 to size_x - 1 generate

        r_enable(x) <= r_enable(x - 1) when rising_edge(clk);

    end generate enable;

    -- INPUT ACTIVATIONS ----------------------------------------------------------
    -- Input activations to PEs that are not directly connected to outside of array
    -- Diagonal blue connections in diagram

    iact_wire_y : for y in 0 to size_y - 2 generate

        iact_wire_x : for x in 1 to size_x - 1 generate

            w_data_in_iact(y,x)       <= w_data_out_iact(y + 1, x - 1);
            w_data_in_iact_valid(y,x) <= w_data_out_iact_valid(y + 1, x - 1);

        end generate iact_wire_x;

    end generate iact_wire_y;

    -- Input activations and buffer full signals to and from PEs interfaced on the west
    -- Blue connections in the diagram on the west

    iact_input_y : for i in 0 to size_y - 1 generate

        w_data_in_iact(i,0)        <= i_data_iact(i);       -- when rising_edge(clk);
        w_data_in_iact_valid(i,0)  <= i_data_iact_valid(i); -- when rising_edge(clk);
        o_buffer_full_iact(i)      <= w_buffer_full_iact(i, 0);
        o_buffer_full_next_iact(i) <= w_buffer_full_next_iact(i, 0);

    end generate iact_input_y;

    -- Input activations and buffer full signals to and from PEs interfaced on the south
    -- Blue connections in the diagram on the south

    iact_input_x : for i in 1 to size_x - 1 generate

        w_data_in_iact(size_y - 1, i)           <= i_data_iact(size_y - 1 + i);       -- when rising_edge(clk);
        w_data_in_iact_valid(size_y - 1, i)     <= i_data_iact_valid(size_y - 1 + i); -- when rising_edge(clk);
        o_buffer_full_iact(size_y - 1 + i)      <= w_buffer_full_iact(size_y - 1, i);
        o_buffer_full_next_iact(size_y - 1 + i) <= w_buffer_full_next_iact(size_y - 1, i);

    end generate iact_input_x;

    -- WEIGHTS ----------------------------------------------------------
    -- Weights to PEs that are not directly connected to outside of array
    -- Green arrows in the diagram

    wght_wire_x : for x in 1 to size_x - 1 generate

        wght_wire_y : for y in 0 to size_y - 1 generate

            w_data_in_wght(y,x)       <= w_data_out_wght(y, x - 1);
            w_data_in_wght_valid(y,x) <= w_data_out_wght_valid(y, x - 1);

        end generate wght_wire_y;

    end generate wght_wire_x;

    -- Weights and buffer full signals to and from PEs interface on the west
    -- Green arrows in the diagram on the west of the array

    wght_input : for i in 0 to size_y - 1 generate

        w_data_in_wght(i,0)        <= i_data_wght(i);       -- when rising_edge(clk);
        w_data_in_wght_valid(i,0)  <= i_data_wght_valid(i); -- when rising_edge(clk);
        o_buffer_full_wght(i)      <= w_buffer_full_wght(i, 0);
        o_buffer_full_next_wght(i) <= w_buffer_full_next_wght(i, 0);

    end generate wght_input;

    -- PARTIAL SUMS ---------------------------------------
    -- Partial sums to PEs that are connected to south. Connect all PEs in the south to the same input (i_data_psum).
    -- Hereby all psums within the PEs in the south can only be filled with the same value (bias).
    /* TODO implement bias on north PEs ?? */

    psum_input_x : for x in 0 to size_x - 1 generate

        psum_input_y : for y in 0 to size_y - 1 generate

            w_data_in_psum(y,x)       <= (others => '0');
            w_data_in_psum_valid(y,x) <= rstn;

        end generate psum_input_y;

    end generate psum_input_x;

    -- Partial sums propagating through PE array

    psum_propagate : for y in 0 to size_y - 2 generate

        psum_propagate_x : for x in 0 to size_x - 1 generate

            w_data_in(y,x)       <= w_data_out(y + 1, x);
            w_data_in_valid(y,x) <= w_data_out_valid(y + 1, x);

        end generate psum_propagate_x;

    end generate psum_propagate;

    -- Iact input also on data_in port for south PEs (for GEMM use case)

    data_in_iact : for x in 0 to size_x - 1 generate

        w_data_in(size_y - 1, x)       <= (data_width_psum - 1 downto data_width_iact => '0') & i_data_iact(size_y - 1 + x);
        w_data_in_valid(size_y - 1, x) <= i_data_iact_valid(size_y - 1 + x);

    end generate data_in_iact;

    -- Partial sums output from north PE row. This is the actual output of the PE array.

    psum_output : for i in 0 to size_x - 1 generate

        o_psums(i)          <= w_data_out(0, i);
        o_psums_valid(i)    <= w_data_out_valid(0, i);
        o_psums_halfword(i) <= '0';

    end generate psum_output;

    -- OUTPUT BUFFER FULL SIGNALS
    o_buffer_full_psum      <= and_reduce_2d(w_buffer_full_psum);
    o_buffer_full_next_psum <= and_reduce_2d(w_buffer_full_next_psum);

    -- GENERATE PE ---------
    -- Generate PE instances

    pe_inst_y : for y in 0 to size_y - 1 generate

        pe_inst_x : for x in 0 to size_x - 1 generate

            pe_north : if y = 0 generate

                pe_inst : entity accel.pe
                    generic map (
                        data_width_iact  => data_width_iact,
                        line_length_iact => line_length_iact,
                        addr_width_iact  => addr_width_iact,
                        data_width_psum  => data_width_psum,
                        line_length_psum => line_length_psum,
                        addr_width_psum  => addr_width_psum,
                        data_width_wght  => data_width_wght,
                        line_length_wght => line_length_wght,
                        addr_width_wght  => addr_width_wght,
                        pe_north         => true,
                        pe_south         => false
                    )
                    port map (
                        clk                     => clk,
                        rstn                    => rstn,
                        i_enable                => r_enable(x),
                        i_command               => i_command(y,x),
                        i_command_iact          => i_command_iact(y,x),
                        i_command_psum          => i_command_psum(y,x),
                        i_command_wght          => i_command_wght(y,x),
                        i_data_in_iact          => w_data_in_iact(y,x),
                        i_data_in_psum          => w_data_in_psum(y,x),
                        i_data_in_wght          => w_data_in_wght(y,x),
                        i_data_in_iact_valid    => w_data_in_iact_valid(y,x),
                        i_data_in_psum_valid    => w_data_in_psum_valid(y,x),
                        i_data_in_wght_valid    => w_data_in_wght_valid(y,x),
                        o_buffer_full_iact      => w_buffer_full_iact(y,x),
                        o_buffer_full_psum      => w_buffer_full_psum(y,x),
                        o_buffer_full_wght      => w_buffer_full_wght(y,x),
                        o_buffer_full_next_iact => w_buffer_full_next_iact(y,x),
                        o_buffer_full_next_psum => w_buffer_full_next_psum(y,x),
                        o_buffer_full_next_wght => w_buffer_full_next_wght(y,x),
                        i_update_offset_iact    => i_update_offset_iact(y,x),
                        i_update_offset_psum    => i_update_offset_psum(y,x),
                        i_update_offset_wght    => i_update_offset_wght(y,x),
                        i_read_offset_iact      => i_read_offset_iact(y,x),
                        i_read_offset_psum      => i_read_offset_psum(y,x),
                        i_read_offset_wght      => i_read_offset_wght(y,x),
                        o_data_out              => w_data_out(y,x),
                        o_data_out_valid        => w_data_out_valid(y,x),
                        i_data_in               => w_data_in(y,x),
                        i_data_in_valid         => w_data_in_valid(y,x),
                        o_data_out_iact         => w_data_out_iact(y,x),
                        o_data_out_wght         => w_data_out_wght(y,x),
                        o_data_out_iact_valid   => w_data_out_iact_valid(y,x),
                        o_data_out_wght_valid   => w_data_out_wght_valid(y,x)
                    );

            end generate pe_north;

            pe_south : if y = size_y - 1 generate

                pe_inst : entity accel.pe
                    generic map (
                        data_width_iact  => data_width_iact,
                        line_length_iact => line_length_iact,
                        addr_width_iact  => addr_width_iact,
                        data_width_psum  => data_width_psum,
                        line_length_psum => line_length_psum,
                        addr_width_psum  => addr_width_psum,
                        data_width_wght  => data_width_wght,
                        line_length_wght => line_length_wght,
                        addr_width_wght  => addr_width_wght,
                        pe_north         => false,
                        pe_south         => true
                    )
                    port map (
                        clk                     => clk,
                        rstn                    => rstn,
                        i_enable                => r_enable(x),
                        i_command               => i_command(y,x),
                        i_command_iact          => i_command_iact(y,x),
                        i_command_psum          => i_command_psum(y,x),
                        i_command_wght          => i_command_wght(y,x),
                        i_data_in_iact          => w_data_in_iact(y,x),
                        i_data_in_psum          => w_data_in_psum(y,x),
                        i_data_in_wght          => w_data_in_wght(y,x),
                        i_data_in_iact_valid    => w_data_in_iact_valid(y,x),
                        i_data_in_psum_valid    => w_data_in_psum_valid(y,x),
                        i_data_in_wght_valid    => w_data_in_wght_valid(y,x),
                        o_buffer_full_iact      => w_buffer_full_iact(y,x),
                        o_buffer_full_psum      => w_buffer_full_psum(y,x),
                        o_buffer_full_wght      => w_buffer_full_wght(y,x),
                        o_buffer_full_next_iact => w_buffer_full_next_iact(y,x),
                        o_buffer_full_next_psum => w_buffer_full_next_psum(y,x),
                        o_buffer_full_next_wght => w_buffer_full_next_wght(y,x),
                        i_update_offset_iact    => i_update_offset_iact(y,x),
                        i_update_offset_psum    => i_update_offset_psum(y,x),
                        i_update_offset_wght    => i_update_offset_wght(y,x),
                        i_read_offset_iact      => i_read_offset_iact(y,x),
                        i_read_offset_psum      => i_read_offset_psum(y,x),
                        i_read_offset_wght      => i_read_offset_wght(y,x),
                        o_data_out              => w_data_out(y,x),
                        o_data_out_valid        => w_data_out_valid(y,x),
                        i_data_in               => w_data_in(y,x),
                        i_data_in_valid         => w_data_in_valid(y,x),
                        o_data_out_iact         => w_data_out_iact(y,x),
                        o_data_out_wght         => w_data_out_wght(y,x),
                        o_data_out_iact_valid   => w_data_out_iact_valid(y,x),
                        o_data_out_wght_valid   => w_data_out_wght_valid(y,x)
                    );

            end generate pe_south;

            pe_middle : if (y /= size_y - 1) and (y /= 0) generate

                pe_inst : entity accel.pe
                    generic map (
                        data_width_iact  => data_width_iact,
                        line_length_iact => line_length_iact,
                        addr_width_iact  => addr_width_iact,
                        data_width_psum  => data_width_psum,
                        line_length_psum => line_length_psum,
                        addr_width_psum  => addr_width_psum,
                        data_width_wght  => data_width_wght,
                        line_length_wght => line_length_wght,
                        addr_width_wght  => addr_width_wght,
                        pe_north         => false,
                        pe_south         => true
                    )
                    port map (
                        clk                     => clk,
                        rstn                    => rstn,
                        i_enable                => r_enable(x),
                        i_command               => i_command(y,x),
                        i_command_iact          => i_command_iact(y,x),
                        i_command_psum          => i_command_psum(y,x),
                        i_command_wght          => i_command_wght(y,x),
                        i_data_in_iact          => w_data_in_iact(y,x),
                        i_data_in_psum          => w_data_in_psum(y,x),
                        i_data_in_wght          => w_data_in_wght(y,x),
                        i_data_in_iact_valid    => w_data_in_iact_valid(y,x),
                        i_data_in_psum_valid    => w_data_in_psum_valid(y,x),
                        i_data_in_wght_valid    => w_data_in_wght_valid(y,x),
                        o_buffer_full_iact      => w_buffer_full_iact(y,x),
                        o_buffer_full_psum      => w_buffer_full_psum(y,x),
                        o_buffer_full_wght      => w_buffer_full_wght(y,x),
                        o_buffer_full_next_iact => w_buffer_full_next_iact(y,x),
                        o_buffer_full_next_psum => w_buffer_full_next_psum(y,x),
                        o_buffer_full_next_wght => w_buffer_full_next_wght(y,x),
                        i_update_offset_iact    => i_update_offset_iact(y,x),
                        i_update_offset_psum    => i_update_offset_psum(y,x),
                        i_update_offset_wght    => i_update_offset_wght(y,x),
                        i_read_offset_iact      => i_read_offset_iact(y,x),
                        i_read_offset_psum      => i_read_offset_psum(y,x),
                        i_read_offset_wght      => i_read_offset_wght(y,x),
                        o_data_out              => w_data_out(y,x),
                        o_data_out_valid        => w_data_out_valid(y,x),
                        i_data_in               => w_data_in(y,x),
                        i_data_in_valid         => w_data_in_valid(y,x),
                        o_data_out_iact         => w_data_out_iact(y,x),
                        o_data_out_wght         => w_data_out_wght(y,x),
                        o_data_out_iact_valid   => w_data_out_iact_valid(y,x),
                        o_data_out_wght_valid   => w_data_out_wght_valid(y,x)
                    );

            end generate pe_middle;

        end generate pe_inst_x;

    end generate pe_inst_y;

end architecture behavioral;

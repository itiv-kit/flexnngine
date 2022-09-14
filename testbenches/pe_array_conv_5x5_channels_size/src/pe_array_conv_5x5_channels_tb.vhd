library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;
    use work.utilities.all;
    use std.textio.all;
    use ieee.math_real.log2;
    use ieee.math_real.ceil;

--! Testbench to perform a 3x3 convolution on a 5x5 input image

--! The image as well as commands are fed into the pe_array
--! Convolution outputs are validated

-- https://docs.nvidia.com/deeplearning/performance/dl-performance-fully-connected/index.html

entity pe_array_conv_5x5_channels_tb is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;
        channels  : positive := 5; -- Number of input channels the image and kernels have

        data_width_iact  : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact : positive := 25;
        addr_width_iact  : positive := 5;

        data_width_psum  : positive := 16; -- or 17??
        line_length_psum : positive := 10;
        addr_width_psum  : positive := 4;

        data_width_wght  : positive := 8;
        line_length_wght : positive := 25;
        addr_width_wght  : positive := 5;

        image_x : positive := 14; --! size of input image
        image_y : positive := 14; --! size of input image

        command_length : positive :=
        /*COMMAND_LENGTH*/
        265
        /*COMMAND_LENGTH*/;
        output_command_length : positive :=
        /*OUTPUT_COMMAND_LENGTH*/
        55
        /*OUTPUT_COMMAND_LENGTH*/;

        kernel_size : positive := 5; --! 3 pixel kernel

        tiles : positive := positive(ceil(real((image_y -  kernel_size + 1) / kernel_size)))
    );
end entity pe_array_conv_5x5_channels_tb;

architecture imp of pe_array_conv_5x5_channels_tb is

    component pe_array is
        generic (
            size_x : positive;
            size_y : positive;

            size_rows : positive;

            data_width_iact  : positive;
            line_length_iact : positive;
            addr_width_iact  : positive;

            data_width_psum  : positive;
            line_length_psum : positive;
            addr_width_psum  : positive;

            data_width_wght  : positive;
            line_length_wght : positive;
            addr_width_wght  : positive
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

            o_buffer_full_next_iact : out   std_logic;
            o_buffer_full_next_psum : out   std_logic;
            o_buffer_full_next_wght : out   std_logic;

            update_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            update_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            update_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            read_offset_iact : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            read_offset_psum : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            read_offset_wght : in    array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            o_psums       : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
            o_psums_valid : out   std_logic_vector(size_x - 1 downto 0)
        );
    end component pe_array;

    signal clk  : std_logic := '1';
    signal rstn : std_logic;

    signal i_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_preload_psum_valid : std_logic;

    signal command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    type delay_array_t is array (natural range <>) of array_t;

    signal i_data_iact       : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_iact_delay : delay_array_t (0 to 3)(0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_iact_array : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal i_data_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal i_data_wght       : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

    signal i_data_iact_valid       : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_iact_valid_delay : array_t(0 to 3)(size_rows - 1 downto 0);
    signal i_data_iact_valid_array : std_logic_vector(size_rows - 1 downto 0);

    signal i_data_psum_valid : std_logic;
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal o_buffer_full_iact : std_logic;
    signal o_buffer_full_psum : std_logic;
    signal o_buffer_full_wght : std_logic;

    signal o_buffer_full_next_iact : std_logic;
    signal o_buffer_full_next_psum : std_logic;
    signal o_buffer_full_next_wght : std_logic;

    signal update_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal update_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal update_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal read_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal read_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal read_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal o_psums       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal o_psums_valid : std_logic_vector(size_x - 1 downto 0);

    signal s_x    : integer;
    signal s_y    : integer;
    signal s_c    : integer;
    signal s_done : boolean;

    signal s_tile_done  : boolean;

    -- INPUT IMAGE, FILTER WEIGTHS AND EXPECTED OUTPUT

    signal s_input_image     : int_image3_t(0 to channels - 1, 0 to image_y - 1, 0 to image_x - 1);         -- int_image_t(0 to image_y - 1, 0 to image_x - 1);
    signal s_input_weights   : int_image3_t(0 to channels - 1, 0 to kernel_size - 1, 0 to kernel_size - 1); -- int_image_t(0 to kernel_size - 1, 0 to kernel_size - 1);
    signal s_expected_output : int_image_t(0 to image_y - kernel_size, 0 to image_x - kernel_size);

    -- COMMANDS FOR PES AND LINE BUFFERS

    constant input_pe_command : command_pe_row_col_t(0 to size_x - 1, 0 to command_length - 1) := (
        /*INPUT_PE_COMMAND*/
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult)
        /*INPUT_PE_COMMAND*/
    );

    constant input_command : command_lb_row_col_t(0 to 3 * size_x - 1, 0 to command_length - 1) := (
        /*INPUT_COMMAND_IACT*/
        (c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_shrink,c_lb_idle),
        /*INPUT_COMMAND_IACT*/
        /*INPUT_COMMAND_PSUM*/
        (c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_idle),
        /*INPUT_COMMAND_PSUM*/
        /*INPUT_COMMAND_WGHT*/
        (c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle)
        /*INPUT_COMMAND_WGHT*/
    );

    constant input_read_offset : int_image_t(0 to 3 * size_x - 1, 0 to command_length - 1) := (
        /*INPUT_READ_OFFSET_IACT*/
        (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,0,0,0,0),
        (0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,0,0,0),
        (0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,0,0),
        (0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,0),
        (0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,5,0),
        /*INPUT_READ_OFFSET_IACT*/
        /*INPUT_READ_OFFSET_PSUM*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0),
        /*INPUT_READ_OFFSET_PSUM*/
        /*INPUT_READ_OFFSET_WGHT*/
        (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,0,0,0,0),
        (0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,0,0,0),
        (0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,0,0),
        (0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,0),
        (0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,0,0)
        /*INPUT_READ_OFFSET_WGHT*/
    );

    constant input_update_offset : int_image_t(0 to 3 * size_x - 1, 0 to command_length - 1) := (
        /*INPUT_UPDATE_OFFSET_IACT*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        /*INPUT_UPDATE_OFFSET_IACT*/
        /*INPUT_UPDATE_OFFSET_PSUM*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,0,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,0),
        /*INPUT_UPDATE_OFFSET_PSUM*/
        /*INPUT_UPDATE_OFFSET_WGHT*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        /*INPUT_UPDATE_OFFSET_WGHT*/
    );

    constant output_command : command_lb_row_col_t(0 to size_y * size_x - 1, 0 to output_command_length - 1) := (
        /*OUTPUT_COMMAND*/
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read_update,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle),
        (c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_read,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle,c_lb_idle)
        /*OUTPUT_COMMAND*/
    );
    constant output_pe_command : command_pe_row_col_t(0 to size_y * size_x - 1, 0 to output_command_length - 1) := (
        /*OUTPUT_PE_COMMAND*/
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult,c_pe_conv_mult),
        (c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_psum,c_pe_conv_mult)
        /*OUTPUT_PE_COMMAND*/
    );

    constant output_read_offset : int_image_t(0 to size_y * size_x - 1, 0 to output_command_length - 1) := (
        /*OUTPUT_READ_OFFSET*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        /*OUTPUT_READ_OFFSET*/
    );

    constant output_update_offset : int_image_t(0 to size_y * size_x - 1, 0 to output_command_length - 1) := (
        /*OUTPUT_UPDATE_OFFSET*/
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        /*OUTPUT_UPDATE_OFFSET*/
    );

    procedure incr (signal pointer_y : inout integer; signal pointer_x : inout integer; signal pointer_c : inout integer) is
    begin

        if pointer_x = image_x - 1 and pointer_c = channels - 1 then
            pointer_c <= 0;
            pointer_x <= 0;
            pointer_y <= pointer_y + kernel_size;
        elsif pointer_c = channels - 1 then
            pointer_c <= 0;
            pointer_x <= pointer_x + 1;
        else
            pointer_c <= pointer_c + 1;
        end if;

    end procedure;

begin

    i_data_iact_delay(3) <= i_data_iact when rising_edge(clk);
    i_data_iact_delay(2) <= i_data_iact_delay(3) when rising_edge(clk);
    i_data_iact_delay(1) <= i_data_iact_delay(2) when rising_edge(clk);
    i_data_iact_delay(0) <= i_data_iact_delay(1) when rising_edge(clk);

    i_data_iact_array <= i_data_iact(0 to 4) & i_data_iact_delay(3)(5) & i_data_iact_delay(2)(6) & i_data_iact_delay(1)(7) & i_data_iact_delay(0)(8);

    i_data_iact_valid_delay(3) <= i_data_iact_valid when rising_edge(clk);
    i_data_iact_valid_delay(2) <= i_data_iact_valid_delay(3) when rising_edge(clk);
    i_data_iact_valid_delay(1) <= i_data_iact_valid_delay(2) when rising_edge(clk);
    i_data_iact_valid_delay(0) <= i_data_iact_valid_delay(1) when rising_edge(clk);

    i_data_iact_valid_array <= i_data_iact_valid_delay(0)(8) & i_data_iact_valid_delay(1)(7) & i_data_iact_valid_delay(2)(6) & i_data_iact_valid_delay(3)(5) & i_data_iact_valid(4 downto 0);

    pe_array_inst : component pe_array
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
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
            clk                     => clk,
            rstn                    => rstn,
            i_preload_psum          => i_preload_psum,
            i_preload_psum_valid    => i_preload_psum_valid,
            command                 => command,
            command_iact            => command_iact,
            command_psum            => command_psum,
            command_wght            => command_wght,
            i_data_iact             => i_data_iact_array,
            i_data_psum             => i_data_psum,
            i_data_wght             => i_data_wght,
            i_data_iact_valid       => i_data_iact_valid_array,
            i_data_psum_valid       => i_data_psum_valid,
            i_data_wght_valid       => i_data_wght_valid,
            o_buffer_full_iact      => o_buffer_full_iact,
            o_buffer_full_psum      => o_buffer_full_psum,
            o_buffer_full_wght      => o_buffer_full_wght,
            o_buffer_full_next_iact => o_buffer_full_next_iact,
            o_buffer_full_next_psum => o_buffer_full_next_psum,
            o_buffer_full_next_wght => o_buffer_full_next_wght,
            update_offset_iact      => update_offset_iact,
            update_offset_psum      => update_offset_psum,
            update_offset_wght      => update_offset_wght,
            read_offset_iact        => read_offset_iact,
            read_offset_psum        => read_offset_psum,
            read_offset_wght        => read_offset_wght,
            o_psums                 => o_psums,
            o_psums_valid           => o_psums_valid
        );

    p_read_files : process is
    begin

        s_input_image     <= read_file(file_name => "src/_image.txt", num_col => image_x, num_row => image_y, num_channels => channels);
        s_input_weights   <= read_file(file_name => "src/_kernel.txt", num_col => kernel_size, num_row => kernel_size, num_channels => channels);
        s_expected_output <= read_file(file_name => "src/_convolution.txt", num_col => image_x - kernel_size + 1, num_row => image_y - kernel_size + 1);
        wait;

    end process p_read_files;

    p_constant_check : process is
    begin

        assert line_length_iact >= kernel_size * channels
            report "Line length to store input values must be greater or equal to the kernel size"
            severity failure;

        assert size_y >= kernel_size
            report "Y dimension of PE array has to be greater or equal to kernel size"
            severity failure;

        assert line_length_wght >= kernel_size * channels
            report "Length of wght buffer has to be greater or equal to kernel size, buffer has to store values of one kernel row at a time."
            severity failure;

        assert line_length_psum >= image_x - kernel_size
            report "Psum buffer has to hold output values of one row, must not be smaller than output row size"
            severity failure; /* TODO To be changed by splitting the task and propagating as many psums that the buffer can hold through the array at once */

        assert addr_width_iact = integer(ceil(log2(real(line_length_iact))))
            report "Check iact address width!"
            severity failure;

        assert addr_width_psum = integer(ceil(log2(real(line_length_psum))))
            report "Check psum address width!"
            severity failure;

        assert addr_width_wght = integer(ceil(log2(real(line_length_wght))))
            report "Check wght address width!"
            severity failure;

        wait;

    end process p_constant_check;

    rstn_gen : process is
    begin

        rstn <= '0';
        wait for 100 ns;
        rstn <= '1';
        wait;

    end process rstn_gen;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

    stimuli_data_wght : process is
    begin

        i_data_wght       <= (others => (others => '0'));
        i_data_wght_valid <= (others => '0');

        wait until rstn = '1';
        wait until rising_edge(clk);

        i_data_wght_valid <= (others => '1');

        for i in 0 to size_x - 1 loop

            for c in 0 to channels - 1 loop

                while o_buffer_full_wght = '1' loop

                    wait until rising_edge(clk);

                end loop;

                for y in 0 to size_y - 1 loop

                    -- data_in_wght <= std_logic_vector(to_signed(input_wght(i), data_width_iact_wght));
                    i_data_wght(y) <= std_logic_vector(to_signed(s_input_weights(c,y,i), data_width_wght));

                end loop;

                wait until rising_edge(clk);

            end loop;

        end loop;

        i_data_wght_valid <= (others => '0');

        wait;

    end process stimuli_data_wght;

    stimuli_data_iact : process (rstn, clk) is

        variable loop_max : integer;

    begin

        if not rstn then
            i_data_iact       <= (others => (others => '0'));
            i_data_iact_valid <= (others => '0');
            s_c               <= 0;
            s_x               <= 0;
            s_y               <= 0;
            s_done            <= false;
            loop_max          := size_rows;
        elsif rising_edge(clk) then
            if s_y >= image_y then
                s_done <= true;
            -- data_in_valid <= '0';
            elsif o_buffer_full_iact = '0' then
                if s_y + size_rows > image_y then
                    loop_max := image_y - s_y;
                end if;

                for i in 0 to loop_max - 1 loop

                    i_data_iact_valid(i) <= '1';
                    i_data_iact(i)       <= std_logic_vector(to_signed(s_input_image(s_c, i + s_y, s_x), data_width_iact));

                end loop;

                incr(s_y,s_x, s_c);
            end if;
        end if;

    end process stimuli_data_iact;

    stimuli_commands : process is
    begin

        wait until rstn = '1';

        -- for i in 0 to line_length_psum - 1 loop
        --    wait until rising_edge(clk);
        -- end loop;

        read_offset_iact <= (others => (others => (others => '0')));
        read_offset_psum <= (others => (others => (others => '0')));
        read_offset_wght <= (others => (others => (others => '0')));

        for j in 0 to tiles - 1 loop

            report "Waiting until first values in buffer";

            for i in 0 to image_x + 20 loop

                wait until rising_edge(clk);

            end loop;

            report "Start with calculation of 1-D convolutions ...";

            for i in 0 to command_length - 1 loop

                for y in 0 to size_y - 1 loop

                    for x in 0 to size_x - 1 loop

                        command(y,x) <= input_pe_command(x,i);

                        command_iact(y,x) <= input_command(0 + x,i);
                        command_psum(y,x) <= input_command(5 + x,i);
                        command_wght(y,x) <= input_command(10 + x,i);

                        read_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_read_offset(0 + x,i), addr_width_iact));
                        read_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_read_offset(5 + x,i), addr_width_psum));
                        read_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_read_offset(10 + x,i), addr_width_wght));

                        update_offset_iact(y,x) <= std_logic_vector(to_unsigned(input_update_offset(0 + x,i), addr_width_iact));
                        update_offset_psum(y,x) <= std_logic_vector(to_unsigned(input_update_offset(5 + x,i), addr_width_psum));
                        update_offset_wght(y,x) <= std_logic_vector(to_unsigned(input_update_offset(10 + x,i), addr_width_wght));

                    end loop;

                end loop;

                wait until rising_edge(clk);

            end loop;

            --wait for 50 ns;
            --wait until rising_edge(clk);

            report "Start with partial sum accumulation and output results ...";

            for i in 0 to output_command_length - 1 loop

                for x in 0 to size_x - 1 loop

                    command(0,x) <= output_pe_command(0 + x,i);
                    command(1,x) <= output_pe_command(5 + x,i);
                    command(2,x) <= output_pe_command(10 + x,i);
                    command(3,x) <= output_pe_command(15 + x,i);
                    command(4,x) <= output_pe_command(20 + x,i);

                    command_psum(0,x) <= output_command(0 + x ,i);
                    command_psum(1,x) <= output_command(5 + x ,i);
                    command_psum(2,x) <= output_command(10 + x,i);
                    command_psum(3,x) <= output_command(15 + x,i);
                    command_psum(4,x) <= output_command(20 + x,i);

                    read_offset_psum(0,x) <= std_logic_vector(to_unsigned(output_read_offset(0 + x ,i), addr_width_psum));
                    read_offset_psum(1,x) <= std_logic_vector(to_unsigned(output_read_offset(5 + x ,i), addr_width_psum));
                    read_offset_psum(2,x) <= std_logic_vector(to_unsigned(output_read_offset(10 + x,i), addr_width_psum));
                    read_offset_psum(3,x) <= std_logic_vector(to_unsigned(output_read_offset(15 + x,i), addr_width_psum));
                    read_offset_psum(4,x) <= std_logic_vector(to_unsigned(output_read_offset(20 + x,i), addr_width_psum));

                    update_offset_psum(0,x) <= std_logic_vector(to_unsigned(output_update_offset(0 + x ,i), addr_width_psum));
                    update_offset_psum(1,x) <= std_logic_vector(to_unsigned(output_update_offset(5 + x ,i), addr_width_psum));
                    update_offset_psum(2,x) <= std_logic_vector(to_unsigned(output_update_offset(10 + x,i), addr_width_psum));
                    update_offset_psum(3,x) <= std_logic_vector(to_unsigned(output_update_offset(15 + x,i), addr_width_psum));
                    update_offset_psum(4,x) <= std_logic_vector(to_unsigned(output_update_offset(20 + x,i), addr_width_psum));

                end loop;

                wait until rising_edge(clk);

            end loop;

            wait until s_tile_done = true;

            report "###################################";
            report "###################################";
            report "###################################";
            report "Prepare for NEXT TURN";
            report "Clear psums and fill with zeros";

            for x in 0 to size_x - 1 loop

                for y in 0 to size_y - 1 loop

                    read_offset_iact  <= (others => (others => std_logic_vector(to_unsigned(kernel_size * channels - channels, addr_width_iact))));
                    command_iact(y,x) <= c_lb_shrink;

                end loop;

                wait until rising_edge(clk);

                -- Stop shrinking --> set commands back to idle
                read_offset_iact <= (others => (others => std_logic_vector(to_unsigned(0, addr_width_iact))));
                command_iact     <= (others => (others => c_lb_idle));

            end loop;

            -- Shrink iact inputs by line_length_iact - kernel_size and thus clear the line buffer
            -- read_offset_iact <= (others => (others => std_logic_vector(to_unsigned(kernel_size * channels - channels, addr_width_iact)))); /* TODO Kernel_size - 1 correct? */
            -- command_iact     <= (others => (others => c_lb_shrink));

            -- Shrink psums to clear line buffer
            read_offset_psum <= (others => (others => std_logic_vector(to_unsigned(image_x - kernel_size + 1, addr_width_psum))));
            command_psum     <= (others => (others => c_lb_shrink));

            wait until rising_edge(clk);

            -- Stop shrinking --> set commands back to idle
            read_offset_iact <= (others => (others => std_logic_vector(to_unsigned(0, addr_width_iact))));
            command_iact     <= (others => (others => c_lb_idle));
            read_offset_psum <= (others => (others => std_logic_vector(to_unsigned(0, addr_width_psum))));
            command_psum     <= (others => (others => c_lb_idle));

        end loop;

        wait for 50 ns;
        wait until rising_edge(clk);

        wait;

    end process stimuli_commands;

    output_check : for p in 0 to size_x - 1 generate

        output_check_last_row : if p = size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to tiles - 1 loop /* TODO Adjust range based on image size */

                    output_loop : for i in 0 to image_x - kernel_size loop

                        wait until rising_edge(clk);

                        -- If result is not valid, wait until next rising edge with valid results.
                        if o_psums_valid(p) = '0' then
                            wait until rising_edge(clk) and o_psums_valid(p) = '1';
                        end if;

                        check_rows := size_y - 1;

                        if j = 2 then
                            check_rows := size_y - 1; /* TODO Adjust based on image size */
                        end if;

                        assert o_psums(p) = std_logic_vector(to_signed(s_expected_output(p + j * kernel_size,i), data_width_psum))
                            report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(p)))) & " - should be "
                                   & integer'image(s_expected_output(p + j * kernel_size,i))
                            severity failure;

                        report "Got correct result " & integer'image(to_integer(signed(o_psums(p))));

                    end loop;

                    s_tile_done <= true;
                    wait until rising_edge(clk);
                    s_tile_done <= false;

                end loop;

                -- Check if result valid signal is set to zero afterwards
                assert o_psums_valid(p) = '0'
                    report "Result valid should be zero"
                    severity failure;

                report "Output check is finished."
                    severity note;
                finish;

                wait;

            end process output_check;

        end generate output_check_last_row;

        output_check_other_rows : if p /= size_x - 1 generate

            output_check : process is

                variable check_rows : integer;

            begin

                report "OUTPUTS -----------------------------------------------------"
                    severity note;

                for j in 0 to tiles - 1 loop /* TODO Adjust range based on image size */

                    output_loop : for i in 0 to image_x - kernel_size loop

                        wait until rising_edge(clk);

                        -- If result is not valid, wait until next rising edge with valid results.
                        if o_psums_valid(p) = '0' then
                            wait until rising_edge(clk) and o_psums_valid(p) = '1';
                        end if;

                        check_rows := size_y - 1;

                        if j = 2 then
                            check_rows := size_y - 1; /* TODO Adjust based on image size */
                        end if;

                        assert o_psums(p) = std_logic_vector(to_signed(s_expected_output(p + j * kernel_size,i), data_width_psum))
                            report "Output wrong. Result is " & integer'image(to_integer(signed(o_psums(p)))) & " - should be "
                                   & integer'image(s_expected_output(p + j * kernel_size,i))
                            severity failure;

                        report "Got correct result " & integer'image(to_integer(signed(o_psums(p))));

                    end loop;

                    -- s_tile_done <= true;
                    wait until rising_edge(clk);
                -- s_tile_done <= false;

                end loop;

                -- Check if result valid signal is set to zero afterwards
                assert o_psums_valid(p) = '0'
                    report "Result valid should be zero"
                    severity failure;

                wait;

            end process output_check;

        end generate output_check_other_rows;

    end generate output_check;

end architecture imp;

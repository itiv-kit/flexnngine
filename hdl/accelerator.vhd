library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity accelerator is
    generic (
        size_x    : positive := 5;
        size_y    : positive := 5;
        size_rows : positive := 9;

        addr_width_rows : positive := 4;
        addr_width_y    : positive := 3;
        addr_width_x    : positive := 3;

        data_width_iact     : positive := 8; -- Width of the input data (weights, iacts)
        line_length_iact    : positive := 512;
        addr_width_iact     : positive := 9;
        addr_width_iact_mem : positive := 15;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 1024;
        addr_width_psum     : positive := 10;
        addr_width_psum_mem : positive := 15;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 512;
        addr_width_wght     : positive := 9;
        addr_width_wght_mem : positive := 15;

        fifo_width : positive := 16;

        g_channels    : positive := 28;
        g_image_y     : positive := 14;
        g_image_x     : positive := 14;
        g_kernel_size : positive := 5
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;

        clk_sp : in    std_logic;

        i_start_init : in    std_logic;
        i_start      : in    std_logic;

        o_dout_psum       : out   std_logic_vector(data_width_psum - 1 downto 0);
        o_dout_psum_valid : out   std_logic;

        i_write_en_iact : in    std_logic;
        i_write_en_wght : in    std_logic;

        i_din_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        i_din_wght : in    std_logic_vector(data_width_wght - 1 downto 0)
    );
end entity accelerator;

architecture rtl of accelerator is

    component pe_array is
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

            o_psums       : out   array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
            o_psums_valid : out   std_logic_vector(size_x - 1 downto 0)
        );
    end component pe_array;

    component control is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            line_length_iact : positive := 512;
            addr_width_iact  : positive := 9;
            line_length_psum : positive := 512;
            addr_width_psum  : positive := 9;
            line_length_wght : positive := 512;
            addr_width_wght  : positive := 9
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            o_status     : out   std_logic;
            i_start      : in    std_logic;
            i_start_init : in    std_logic;

            o_c1 : out   integer range 0 to 1023;
            o_w1 : out   integer range 0 to 1023;
            o_h2 : out   integer range 0 to 1023;
            o_m0 : out   integer range 0 to 1023;

            o_c0         : out   integer range 0 to 1023;
            o_c0_last_c1 : out   integer range 0 to 1023;

            i_image_x : in    integer range 0 to 1023;
            i_image_y : in    integer range 0 to 1023;

            i_channels : in    integer range 0 to 4095;

            i_kernel_size : in    integer range 0 to 32;

            o_command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            o_command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

            o_update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            o_read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            o_read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            o_read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
        );
    end component control;

    component address_generator is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            line_length_iact    : positive := 512;
            addr_width_iact     : positive := 9;
            addr_width_iact_mem : positive := 15;

            line_length_psum    : positive := 512;
            addr_width_psum     : positive := 9;
            addr_width_psum_mem : positive := 15;

            line_length_wght    : positive := 512;
            addr_width_wght     : positive := 9;
            addr_width_wght_mem : positive := 15
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_start : in    std_logic;

            i_c1 : in    integer range 0 to 1023;
            i_w1 : in    integer range 0 to 1023;
            i_h2 : in    integer range 0 to 1023;
            i_m0 : in    integer range 0 to 1023;

            i_c0         : in    integer range 0 to 1023;
            i_c0_last_c1 : in    integer range 0 to 1023;

            i_image_x     : in    integer range 0 to 1023;
            i_image_y     : in    integer range 0 to 1023;
            i_channels    : in    integer range 0 to 4095;
            i_kernel_size : in    integer range 0 to 32;

            i_fifo_full_iact : in    std_logic;
            i_fifo_full_wght : in    std_logic;

            o_address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            o_address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            o_address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
            o_address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
        );
    end component address_generator;

    component scratchpad_init is
        generic (
            data_width_iact : positive := 8;
            addr_width_iact : positive := 15;

            data_width_psum : positive := 16;
            addr_width_psum : positive := 15;

            data_width_wght : positive := 8;
            addr_width_wght : positive := 15
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            write_adr_iact : in    std_logic_vector(addr_width_iact_mem - 1 downto 0);
            write_adr_psum : in    std_logic_vector(addr_width_psum_mem - 1 downto 0);
            write_adr_wght : in    std_logic_vector(addr_width_wght_mem - 1 downto 0);

            read_adr_iact : in    std_logic_vector(addr_width_iact_mem - 1 downto 0);
            read_adr_psum : in    std_logic_vector(addr_width_psum_mem - 1 downto 0);
            read_adr_wght : in    std_logic_vector(addr_width_wght_mem - 1 downto 0);

            write_en_iact : in    std_logic;
            write_en_psum : in    std_logic;
            write_en_wght : in    std_logic;

            read_en_iact : in    std_logic;
            read_en_psum : in    std_logic;
            read_en_wght : in    std_logic;

            din_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
            din_psum : in    std_logic_vector(data_width_psum - 1 downto 0);
            din_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

            dout_iact : out   std_logic_vector(data_width_iact - 1 downto 0);
            dout_psum : out   std_logic_vector(data_width_psum - 1 downto 0);
            dout_wght : out   std_logic_vector(data_width_wght - 1 downto 0);

            dout_iact_valid : out   std_logic;
            dout_psum_valid : out   std_logic;
            dout_wght_valid : out   std_logic
        );
    end component scratchpad_init;

    component scratchpad_interface is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_rows : positive := 4;
            addr_width_y    : positive := 3;
            addr_width_x    : positive := 3;

            data_width_iact     : positive := 8;
            line_length_iact    : positive := 32;
            addr_width_iact     : positive := 5;
            addr_width_iact_mem : positive := 15;

            data_width_psum     : positive := 16;
            line_length_psum    : positive := 127;
            addr_width_psum     : positive := 7;
            addr_width_psum_mem : positive := 15;

            data_width_wght     : positive := 8;
            line_length_wght    : positive := 32;
            addr_width_wght     : positive := 5;
            addr_width_wght_mem : positive := 15;

            fifo_width : positive := 15;

            g_channels    : positive := 28;
            g_image_y     : positive := 14;
            g_image_x     : positive := 14;
            g_kernel_size : positive := 5
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            clk_sp : in    std_logic;

            i_start  : in    std_logic;
            o_status : out   std_logic;
            o_enable : out   std_logic;

            -- Data to and from Address generator
            i_address_iact : in    array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            i_address_wght : in    array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            i_address_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
            i_address_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

            o_fifo_iact_address_full : out   std_logic;
            o_fifo_wght_address_full : out   std_logic;

            o_valid_psums_out   : out   std_logic_vector(size_x - 1 downto 0);
            o_gnt_psum_binary_d : out   std_logic_vector(addr_width_x - 1 downto 0);
            o_empty_psum_fifo   : out   std_logic_vector(size_x - 1 downto 0);

            -- Addresses to Scratchpad
            o_address_iact : out   std_logic_vector(addr_width_iact_mem - 1 downto 0);
            o_address_wght : out   std_logic_vector(addr_width_wght_mem - 1 downto 0);

            o_address_iact_valid : out   std_logic;
            o_address_wght_valid : out   std_logic;

            o_write_en_psum : out   std_logic;
            o_data_psum     : out   std_logic_vector(data_width_psum - 1 downto 0);

            -- Data from Scratchpad
            i_data_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
            i_data_wght : in    std_logic_vector(data_width_wght - 1 downto 0);

            i_data_iact_valid : in    std_logic;
            i_data_wght_valid : in    std_logic;

            -- Data to PE array
            o_data_iact : out   array_t(0 to size_rows - 1)(data_width_iact - 1 downto 0);
            o_data_wght : out   array_t(0 to size_y - 1)(data_width_wght - 1 downto 0);

            o_data_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
            o_data_wght_valid : out   std_logic_vector(size_y - 1 downto 0);

            -- Buffer full signals from PE array
            i_buffer_full_iact : in    std_logic_vector(size_rows - 1 downto 0);
            i_buffer_full_wght : in    std_logic_vector(size_y - 1 downto 0);

            -- Data from PE array
            i_psums       : in    array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
            i_psums_valid : in    std_logic_vector(size_x - 1 downto 0)
        );
    end component scratchpad_interface;

    component address_generator_psum is
        generic (
            size_x    : positive := 5;
            size_y    : positive := 5;
            size_rows : positive := 9;

            addr_width_x : positive := 3;

            line_length_iact    : positive := 512;
            addr_width_iact     : positive := 9;
            addr_width_iact_mem : positive := 15;

            line_length_psum    : positive := 512;
            addr_width_psum     : positive := 9;
            addr_width_psum_mem : positive := 15;

            line_length_wght    : positive := 512;
            addr_width_wght     : positive := 9;
            addr_width_wght_mem : positive := 15
        );
        port (
            clk  : in    std_logic;
            rstn : in    std_logic;

            i_start : in    std_logic;

            i_tiles_x : in    integer range 0 to 1023;

            i_valid_psum_out    : in    std_logic_vector(size_x - 1 downto 0);
            i_gnt_psum_binary_d : in    std_logic_vector(addr_width_x - 1 downto 0);
            i_command_psum      : in    command_lb_t;
            i_empty_psum_fifo   : in    std_logic_vector(size_x - 1 downto 0);

            o_address_psum : out   std_logic_vector(addr_width_psum_mem - 1 downto 0)
        );
    end component address_generator_psum;

    signal w_preload_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_preload_psum_valid : std_logic;

    signal w_command      : command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_iact : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_psum : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
    signal w_command_wght : command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

    type delay_array_t is array (natural range <>) of array_t;

    signal w_data_iact       : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal w_data_iact_delay : delay_array_t (0 to 3)(0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal w_data_iact_array : array_t (0 to size_rows - 1)(data_width_iact - 1 downto 0);
    signal w_data_psum       : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_data_wght       : array_t (0 to size_y - 1)(data_width_wght - 1 downto 0);

    signal w_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_data_psum_valid : std_logic;
    signal w_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal w_buffer_full_iact : std_logic_vector(size_rows - 1 downto 0);
    signal w_buffer_full_psum : std_logic;
    signal w_buffer_full_wght : std_logic_vector(size_y - 1 downto 0);

    signal w_buffer_full_next_iact : std_logic_vector(size_rows - 1 downto 0);
    signal w_buffer_full_next_psum : std_logic;
    signal w_buffer_full_next_wght : std_logic_vector(size_y - 1 downto 0);

    signal w_update_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal w_update_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal w_update_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal w_read_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal w_read_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal w_read_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal w_psums       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal w_psums_valid : std_logic_vector(size_x - 1 downto 0);

    signal w_write_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal w_write_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal w_write_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    signal w_read_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal w_read_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal w_read_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    -- signal write_en_iact : std_logic;
    signal w_write_en_psum : std_logic;
    -- signal write_en_wght : std_logic;

    signal w_read_en_iact : std_logic;
    signal w_read_en_psum : std_logic;
    signal w_read_en_wght : std_logic;

    -- signal din_iact : std_logic_vector(data_width_iact - 1 downto 0);
    signal w_din_psum : std_logic_vector(data_width_psum - 1 downto 0);
    -- signal din_wght : std_logic_vector(data_width_wght - 1 downto 0);

    signal w_dout_iact : std_logic_vector(data_width_iact - 1 downto 0);
    -- signal dout_psum : std_logic_vector(data_width_psum - 1 downto 0);
    signal w_dout_wght : std_logic_vector(data_width_wght - 1 downto 0);

    signal w_status_control     : std_logic;
    signal r_start_control      : std_logic;
    signal r_start_init_control : std_logic;

    signal w_status_if : std_logic;
    signal w_enable    : std_logic;

    signal w_status_adr     : std_logic;
    signal r_start_adr      : std_logic;
    signal w_start_init_adr : std_logic;

    signal w_c1 : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal w_w1 : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal w_h2 : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal w_m0 : integer range 0 to 1023;

    signal w_c0          : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal w_c0_last_c1  : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal r_image_x     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal r_image_y     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal r_channels    : integer range 0 to 4095; /* TODO change range to sth. useful */
    signal r_kernel_size : integer range 0 to 32; /* TODO change range to sth. useful */

    signal w_dout_iact_valid : std_logic;
    -- signal dout_psum_valid : std_logic;
    signal w_dout_wght_valid : std_logic;

    signal w_fifo_iact_address_full : std_logic;
    signal w_fifo_wght_address_full : std_logic;

    signal w_valid_psums_out   : std_logic_vector(size_x - 1 downto 0);
    signal w_gnt_psum_binary_d : std_logic_vector(addr_width_x - 1 downto 0);
    signal w_empty_psum_fifo   : std_logic_vector(size_x - 1 downto 0);

    signal w_address_iact       : array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal w_address_wght       : array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
    signal w_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal w_address_wght_valid : std_logic_vector(size_y - 1 downto 0);

    type   t_state is (s_idle, s_init_started, s_load_fifo_started, s_processing);
    signal r_state : t_state;

begin

    /* TODO Debug */
    w_write_adr_iact <= (others => '0');
    w_write_adr_wght <= (others => '0');
    w_read_adr_psum  <= (others => '0');

    start_procedure : process (clk, rstn) is
    begin

        if not rstn then
            r_start_control      <= '0';
            r_start_init_control <= '0';
            r_start_adr          <= '0';

            r_image_x     <= 0;
            r_image_y     <= 0;
            r_channels    <= 0;
            r_kernel_size <= 0;

            r_state <= s_idle;
        elsif rising_edge(clk) then
            if i_start = '1' or r_state /= s_idle then
                r_image_x     <= g_image_x;
                r_image_y     <= g_image_y;
                r_channels    <= g_channels;
                r_kernel_size <= g_kernel_size;

                if r_state = s_idle then
                    r_state              <= s_init_started;
                    r_start_init_control <= '1';
                elsif w_status_control then
                    r_state              <= s_load_fifo_started;
                    r_start_adr          <= '1';
                    r_start_init_control <= '0';
                    if w_status_if = '1' then
                        r_start_control <= '1';
                        r_state         <= s_processing;
                    end if;
                end if;
            end if;
        end if;

    end process start_procedure;

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
            i_preload_psum          => w_preload_psum,
            i_preload_psum_valid    => w_preload_psum_valid,
            i_enable                => w_enable,
            i_command               => w_command,
            i_command_iact          => w_command_iact,
            i_command_psum          => w_command_psum,
            i_command_wght          => w_command_wght,
            i_data_iact             => w_data_iact,
            i_data_psum             => w_data_psum,
            i_data_wght             => w_data_wght,
            i_data_iact_valid       => w_data_iact_valid,
            i_data_psum_valid       => w_data_psum_valid,
            i_data_wght_valid       => w_data_wght_valid,
            o_buffer_full_iact      => w_buffer_full_iact,
            o_buffer_full_psum      => w_buffer_full_psum,
            o_buffer_full_wght      => w_buffer_full_wght,
            o_buffer_full_next_iact => w_buffer_full_next_iact,
            o_buffer_full_next_psum => w_buffer_full_next_psum,
            o_buffer_full_next_wght => w_buffer_full_next_wght,
            i_update_offset_iact    => w_update_offset_iact,
            i_update_offset_psum    => w_update_offset_psum,
            i_update_offset_wght    => w_update_offset_wght,
            i_read_offset_iact      => w_read_offset_iact,
            i_read_offset_psum      => w_read_offset_psum,
            i_read_offset_wght      => w_read_offset_wght,
            o_psums                 => w_psums,
            o_psums_valid           => w_psums_valid
        );

    control_inst : component control
        generic map (
            size_x           => size_x,
            size_y           => size_y,
            size_rows        => size_rows,
            line_length_iact => line_length_iact,
            addr_width_iact  => addr_width_iact,
            line_length_psum => line_length_psum,
            addr_width_psum  => addr_width_psum,
            line_length_wght => line_length_wght,
            addr_width_wght  => addr_width_wght
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            o_status             => w_status_control,
            i_start              => w_enable,
            i_start_init         => r_start_init_control,
            o_c1                 => w_c1,
            o_w1                 => w_w1,
            o_h2                 => w_h2,
            o_m0                 => w_m0,
            o_c0                 => w_c0,
            o_c0_last_c1         => w_c0_last_c1,
            i_image_x            => r_image_x,
            i_image_y            => r_image_y,
            i_channels           => r_channels,
            i_kernel_size        => r_kernel_size,
            o_command            => w_command,
            o_command_iact       => w_command_iact,
            o_command_psum       => w_command_psum,
            o_command_wght       => w_command_wght,
            o_update_offset_iact => w_update_offset_iact,
            o_update_offset_psum => w_update_offset_psum,
            o_update_offset_wght => w_update_offset_wght,
            o_read_offset_iact   => w_read_offset_iact,
            o_read_offset_psum   => w_read_offset_psum,
            o_read_offset_wght   => w_read_offset_wght
        );

    scratchpad_inst : component scratchpad_init
        generic map (
            data_width_iact => data_width_iact,
            addr_width_iact => addr_width_iact_mem,
            data_width_psum => data_width_psum,
            addr_width_psum => addr_width_psum_mem,
            data_width_wght => data_width_wght,
            addr_width_wght => addr_width_wght_mem
        )
        port map (
            clk             => clk_sp,
            rstn            => rstn,
            write_adr_iact  => w_write_adr_iact,
            write_adr_psum  => w_write_adr_psum,
            write_adr_wght  => w_write_adr_wght,
            read_adr_iact   => w_read_adr_iact,
            read_adr_psum   => w_read_adr_psum,
            read_adr_wght   => w_read_adr_wght,
            write_en_iact   => i_write_en_iact,
            write_en_psum   => w_write_en_psum,
            write_en_wght   => i_write_en_wght,
            read_en_iact    => w_read_en_iact,
            read_en_psum    => w_read_en_psum,
            read_en_wght    => w_read_en_wght,
            din_iact        => i_din_iact,
            din_psum        => w_din_psum,
            din_wght        => i_din_wght,
            dout_iact       => w_dout_iact,
            dout_psum       => o_dout_psum,
            dout_wght       => w_dout_wght,
            dout_iact_valid => w_dout_iact_valid,
            dout_psum_valid => o_dout_psum_valid,
            dout_wght_valid => w_dout_wght_valid
        );

    address_generator_inst : component address_generator
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => r_start_adr,
            i_c1                 => w_c1,
            i_w1                 => w_w1,
            i_h2                 => w_h2,
            i_m0                 => w_m0,
            i_c0                 => w_c0,
            i_c0_last_c1         => w_c0_last_c1,
            i_image_x            => r_image_x,
            i_image_y            => r_image_y,
            i_channels           => r_channels,
            i_kernel_size        => r_kernel_size,
            i_fifo_full_iact     => w_fifo_iact_address_full,
            i_fifo_full_wght     => w_fifo_wght_address_full,
            o_address_iact       => w_address_iact,
            o_address_wght       => w_address_wght,
            o_address_iact_valid => w_address_iact_valid,
            o_address_wght_valid => w_address_wght_valid
        );

    scratchpad_interface_inst : component scratchpad_interface
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            addr_width_rows     => addr_width_rows,
            addr_width_y        => addr_width_y,
            addr_width_x        => addr_width_x,
            data_width_iact     => data_width_iact,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            data_width_psum     => data_width_psum,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            data_width_wght     => data_width_wght,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem,
            fifo_width          => fifo_width,
            g_channels          => g_channels,
            g_image_y           => g_image_y,
            g_image_x           => g_image_x,
            g_kernel_size       => g_kernel_size
        )
        port map (
            clk                      => clk,
            rstn                     => rstn,
            clk_sp                   => clk_sp,
            i_start                  => r_start_adr,
            o_status                 => w_status_if,
            o_enable                 => w_enable,
            i_address_iact           => w_address_iact,
            i_address_wght           => w_address_wght,
            i_address_iact_valid     => w_address_iact_valid,
            i_address_wght_valid     => w_address_wght_valid,
            o_fifo_iact_address_full => w_fifo_iact_address_full,
            o_fifo_wght_address_full => w_fifo_wght_address_full,
            o_valid_psums_out        => w_valid_psums_out,
            o_gnt_psum_binary_d      => w_gnt_psum_binary_d,
            o_empty_psum_fifo        => w_empty_psum_fifo,
            o_address_iact           => w_read_adr_iact,
            o_address_wght           => w_read_adr_wght,
            o_address_iact_valid     => w_read_en_iact,
            o_address_wght_valid     => w_read_en_wght,
            o_write_en_psum          => w_write_en_psum,
            o_data_psum              => w_din_psum,
            i_data_iact              => w_dout_iact,
            i_data_wght              => w_dout_wght,
            i_data_iact_valid        => w_dout_iact_valid,
            i_data_wght_valid        => w_dout_wght_valid,
            o_data_iact              => w_data_iact,
            o_data_wght              => w_data_wght,
            o_data_iact_valid        => w_data_iact_valid,
            o_data_wght_valid        => w_data_wght_valid,
            i_buffer_full_iact       => w_buffer_full_next_iact,
            i_buffer_full_wght       => w_buffer_full_next_wght,
            i_psums                  => w_psums,
            i_psums_valid            => w_psums_valid
        );

    address_generator_psum_inst : component address_generator_psum
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_rows,
            line_length_iact    => line_length_iact,
            addr_width_iact     => addr_width_iact,
            addr_width_iact_mem => addr_width_iact_mem,
            addr_width_x        => addr_width_x,
            line_length_psum    => line_length_psum,
            addr_width_psum     => addr_width_psum,
            addr_width_psum_mem => addr_width_psum_mem,
            line_length_wght    => line_length_wght,
            addr_width_wght     => addr_width_wght,
            addr_width_wght_mem => addr_width_wght_mem
        )
        port map (
            clk                 => clk_sp,
            rstn                => rstn,
            i_start             => r_start_adr,
            i_tiles_x           => w_w1,
            i_valid_psum_out    => w_valid_psums_out,
            i_gnt_psum_binary_d => w_gnt_psum_binary_d,
            i_command_psum      => w_command_psum(0,0),
            i_empty_psum_fifo   => w_empty_psum_fifo,
            o_address_psum      => w_write_adr_psum
        );

end architecture rtl;

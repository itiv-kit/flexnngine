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
        line_length_iact    : positive := 32;
        addr_width_iact     : positive := 5;
        addr_width_iact_mem : positive := 15;

        data_width_psum     : positive := 16; -- or 17??
        line_length_psum    : positive := 127;
        addr_width_psum     : positive := 7;
        addr_width_psum_mem : positive := 15;

        data_width_wght     : positive := 8;
        line_length_wght    : positive := 32;
        addr_width_wght     : positive := 5;
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

        start_init : in    std_logic;
        start      : in    std_logic;

        dout_psum       : out   std_logic_vector(data_width_psum - 1 downto 0);
        dout_psum_valid : out   std_logic;

        write_en_iact : in    std_logic;
        write_en_wght : in    std_logic;

        din_iact : in    std_logic_vector(data_width_iact - 1 downto 0);
        din_wght : in    std_logic_vector(data_width_wght - 1 downto 0)
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

            o_buffer_full_iact : out   std_logic_vector(size_rows - 1 downto 0);
            o_buffer_full_psum : out   std_logic;
            o_buffer_full_wght : out   std_logic_vector(size_y - 1 downto 0);

            o_buffer_full_next_iact : out   std_logic_vector(size_rows - 1 downto 0);
            o_buffer_full_next_psum : out   std_logic;
            o_buffer_full_next_wght : out   std_logic_vector(size_y - 1 downto 0);

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

            status     : out   std_logic;
            start      : in    std_logic;
            start_init : in    std_logic;

            tiles_c : out   integer range 0 to 1023;
            tiles_x : out   integer range 0 to 1023;
            tiles_y : out   integer range 0 to 1023;

            c_per_tile  : out   integer range 0 to 1023;
            c_last_tile : out   integer range 0 to 1023;

            image_x : in    integer range 0 to 1023;
            image_y : in    integer range 0 to 1023;

            channels : in    integer range 0 to 4095;

            kernel_size : in    integer range 0 to 32;

            command      : out   command_pe_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_iact : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_psum : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);
            command_wght : out   command_lb_row_col_t(0 to size_y - 1, 0 to size_x - 1);

            update_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            update_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            update_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

            read_offset_iact : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
            read_offset_psum : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
            read_offset_wght : out   array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0)
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

            start : in    std_logic;

            tiles_c : in    integer range 0 to 1023;
            tiles_x : in    integer range 0 to 1023;
            tiles_y : in    integer range 0 to 1023;

            c_per_tile  : in    integer range 0 to 1023;
            c_last_tile : in    integer range 0 to 1023;

            image_x     : in    integer range 0 to 1023;
            image_y     : in    integer range 0 to 1023;
            channels    : in    integer range 0 to 4095;
            kernel_size : in    integer range 0 to 32;

            fifo_full_iact : in    std_logic;
            fifo_full_wght : in    std_logic;

            address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
            address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
        );
    end component address_generator;

    component scratchpad is
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
    end component scratchpad;

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

            start  : in    std_logic;
            status : out   std_logic;

            -- Data to and from Address generator
            i_address_iact : in    array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
            i_address_wght : in    array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

            i_address_iact_valid : in    std_logic_vector(size_rows - 1 downto 0);
            i_address_wght_valid : in    std_logic_vector(size_y - 1 downto 0);

            o_fifo_iact_address_full : out   std_logic;
            o_fifo_wght_address_full : out   std_logic;

            -- Addresses to Scratchpad
            o_address_iact : out   std_logic_vector(addr_width_iact_mem - 1 downto 0);
            o_address_wght : out   std_logic_vector(addr_width_wght_mem - 1 downto 0);

            o_address_iact_valid : out   std_logic;
            o_address_wght_valid : out   std_logic;

            o_address_psum  : out   std_logic_vector(addr_width_psum_mem - 1 downto 0);
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

    signal i_data_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal i_data_psum_valid : std_logic;
    signal i_data_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal o_buffer_full_iact : std_logic_vector(size_rows - 1 downto 0);
    signal o_buffer_full_psum : std_logic;
    signal o_buffer_full_wght : std_logic_vector(size_y - 1 downto 0);

    signal o_buffer_full_next_iact : std_logic_vector(size_rows - 1 downto 0);
    signal o_buffer_full_next_psum : std_logic;
    signal o_buffer_full_next_wght : std_logic_vector(size_y - 1 downto 0);

    signal update_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal update_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal update_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal read_offset_iact : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_iact - 1 downto 0);
    signal read_offset_psum : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_psum - 1 downto 0);
    signal read_offset_wght : array_row_col_t(0 to size_y - 1, 0 to size_x - 1)(addr_width_wght - 1 downto 0);

    signal o_psums       : array_t(0 to size_x - 1)(data_width_psum - 1 downto 0);
    signal o_psums_valid : std_logic_vector(size_x - 1 downto 0);

    signal write_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal write_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal write_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    signal read_adr_iact : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal read_adr_psum : std_logic_vector(addr_width_psum_mem - 1 downto 0);
    signal read_adr_wght : std_logic_vector(addr_width_wght_mem - 1 downto 0);

    -- signal write_en_iact : std_logic;
    signal write_en_psum : std_logic;
    -- signal write_en_wght : std_logic;

    signal read_en_iact : std_logic;
    signal read_en_psum : std_logic;
    signal read_en_wght : std_logic;

    -- signal din_iact : std_logic_vector(data_width_iact - 1 downto 0);
    signal din_psum : std_logic_vector(data_width_psum - 1 downto 0);
    -- signal din_wght : std_logic_vector(data_width_wght - 1 downto 0);

    signal dout_iact : std_logic_vector(data_width_iact - 1 downto 0);
    -- signal dout_psum : std_logic_vector(data_width_psum - 1 downto 0);
    signal dout_wght : std_logic_vector(data_width_wght - 1 downto 0);

    signal status_control     : std_logic;
    signal start_control      : std_logic;
    signal start_init_control : std_logic;

    signal status_if : std_logic;

    signal status_adr     : std_logic;
    signal start_adr      : std_logic;
    signal start_init_adr : std_logic;

    signal tiles_c : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal tiles_x : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal tiles_y : integer range 0 to 1023; /* TODO change range to sth. useful */

    signal c_per_tile  : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal c_last_tile : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal image_x     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal image_y     : integer range 0 to 1023; /* TODO change range to sth. useful */
    signal channels    : integer range 0 to 4095; /* TODO change range to sth. useful */
    signal kernel_size : integer range 0 to 32; /* TODO change range to sth. useful */

    signal dout_iact_valid : std_logic;
    -- signal dout_psum_valid : std_logic;
    signal dout_wght_valid : std_logic;

    signal o_fifo_iact_address_full : std_logic;
    signal o_fifo_wght_address_full : std_logic;

    signal address_iact       : array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal address_wght       : array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
    signal address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    signal address_wght_valid : std_logic_vector(size_y - 1 downto 0);

    type   t_state_type is (s_idle, s_init_started, s_load_fifo_started, s_processing);
    signal state : t_state_type;

begin

    /* TODO Debug */
    write_adr_iact <= (others => '0');
    write_adr_wght <= (others => '0');
    read_adr_psum  <= (others => '0');

    start_procedure : process (clk, rstn) is
    begin

        if not rstn then
            start_control      <= '0';
            start_init_control <= '0';
            start_adr          <= '0';

            image_x     <= 0;
            image_y     <= 0;
            channels    <= 0;
            kernel_size <= 0;

            state <= s_idle;
        elsif rising_edge(clk) then
            if start = '1' or state /= s_idle then
                image_x     <= g_image_x;
                image_y     <= g_image_y;
                channels    <= g_channels;
                kernel_size <= g_kernel_size;

                if state = s_idle then
                    state              <= s_init_started;
                    start_init_control <= '1';
                elsif status_control then
                    state              <= s_load_fifo_started;
                    start_adr          <= '1';
                    start_init_control <= '0';
                    if status_if = '1' then
                        start_control <= '1';
                        state         <= s_processing;
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
            i_preload_psum          => i_preload_psum,
            i_preload_psum_valid    => i_preload_psum_valid,
            command                 => command,
            command_iact            => command_iact,
            command_psum            => command_psum,
            command_wght            => command_wght,
            i_data_iact             => i_data_iact,
            i_data_psum             => i_data_psum,
            i_data_wght             => i_data_wght,
            i_data_iact_valid       => i_data_iact_valid,
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
            clk                => clk,
            rstn               => rstn,
            status             => status_control,
            start              => start_control,
            start_init         => start_init_control,
            tiles_c            => tiles_c,
            tiles_x            => tiles_x,
            tiles_y            => tiles_y,
            c_per_tile         => c_per_tile,
            c_last_tile        => c_last_tile,
            image_x            => image_x,
            image_y            => image_y,
            channels           => channels,
            kernel_size        => kernel_size,
            command            => command,
            command_iact       => command_iact,
            command_psum       => command_psum,
            command_wght       => command_wght,
            update_offset_iact => update_offset_iact,
            update_offset_psum => update_offset_psum,
            update_offset_wght => update_offset_wght,
            read_offset_iact   => read_offset_iact,
            read_offset_psum   => read_offset_psum,
            read_offset_wght   => read_offset_wght
        );

    scratchpad_inst : component scratchpad
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
            write_adr_iact  => write_adr_iact,
            write_adr_psum  => write_adr_psum,
            write_adr_wght  => write_adr_wght,
            read_adr_iact   => read_adr_iact,
            read_adr_psum   => read_adr_psum,
            read_adr_wght   => read_adr_wght,
            write_en_iact   => write_en_iact,
            write_en_psum   => write_en_psum,
            write_en_wght   => write_en_wght,
            read_en_iact    => read_en_iact,
            read_en_psum    => read_en_psum,
            read_en_wght    => read_en_wght,
            din_iact        => din_iact,
            din_psum        => din_psum,
            din_wght        => din_wght,
            dout_iact       => dout_iact,
            dout_psum       => dout_psum,
            dout_wght       => dout_wght,
            dout_iact_valid => dout_iact_valid,
            dout_psum_valid => dout_psum_valid,
            dout_wght_valid => dout_wght_valid
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
            clk                => clk,
            rstn               => rstn,
            start              => start_adr,
            tiles_c            => tiles_c,
            tiles_x            => tiles_x,
            tiles_y            => tiles_y,
            c_per_tile         => c_per_tile,
            c_last_tile        => c_last_tile,
            image_x            => image_x,
            image_y            => image_y,
            channels           => channels,
            kernel_size        => kernel_size,
            fifo_full_iact     => o_fifo_iact_address_full,
            fifo_full_wght     => o_fifo_wght_address_full,
            address_iact       => address_iact,
            address_wght       => address_wght,
            address_iact_valid => address_iact_valid,
            address_wght_valid => address_wght_valid
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
            start                    => start_adr,
            status                   => status_if,
            i_address_iact           => address_iact,
            i_address_wght           => address_wght,
            i_address_iact_valid     => address_iact_valid,
            i_address_wght_valid     => address_wght_valid,
            o_fifo_iact_address_full => o_fifo_iact_address_full,
            o_fifo_wght_address_full => o_fifo_wght_address_full,
            o_address_iact           => read_adr_iact,
            o_address_wght           => read_adr_wght,
            o_address_iact_valid     => read_en_iact,
            o_address_wght_valid     => read_en_wght,
            o_address_psum           => write_adr_psum,
            o_write_en_psum          => write_en_psum,
            o_data_psum              => din_psum,
            i_data_iact              => dout_iact,
            i_data_wght              => dout_wght,
            i_data_iact_valid        => dout_iact_valid,
            i_data_wght_valid        => dout_wght_valid,
            o_data_iact              => i_data_iact,
            o_data_wght              => i_data_wght,
            o_data_iact_valid        => i_data_iact_valid,
            o_data_wght_valid        => i_data_wght_valid,
            i_buffer_full_iact       => o_buffer_full_next_iact,
            i_buffer_full_wght       => o_buffer_full_next_wght,
            i_psums                  => o_psums,
            i_psums_valid            => o_psums_valid
        );

end architecture rtl;

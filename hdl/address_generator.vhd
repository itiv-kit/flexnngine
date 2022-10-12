library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator is
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

        image_x     : in    integer range 0 to 1023; --! size of input image
        image_y     : in    integer range 0 to 1023; --! size of input image
        channels    : in    integer range 0 to 4095; -- Number of input channels the image and kernels have
        kernel_size : in    integer range 0 to 32;

        fifo_full_iact : in    std_logic;
        fifo_full_wght : in    std_logic;

        address_iact : out   array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
        address_wght : out   array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);

        address_iact_valid : out   std_logic_vector(size_rows - 1 downto 0);
        address_wght_valid : out   std_logic_vector(size_y - 1 downto 0)
    );
end entity address_generator;

architecture rtl of address_generator is

    type   t_state_type is (s_idle, s_processing);
    signal r_state_wght : t_state_type;
    signal r_state_iact : t_state_type;

    signal r_c0_iact       : integer;
    signal r_count_c0_iact : integer;

    -- signal r_W0 : integer; Kernel size
    -- signal r_count_w0 : integer; Kernel size

    signal r_w1            : integer;
    signal r_count_w1_iact : integer;

    signal r_c1            : integer;
    signal r_count_c1_iact : integer;

    signal r_h2            : integer;
    signal r_count_h2_iact : integer;

    signal r_index_x_iact : integer;
    signal r_index_y_iact : integer;

    signal r_index_c_iact      : integer;
    signal r_index_c_last_iact : integer;

    signal r_offset_c_iact         : integer;
    signal r_offset_c_last_c1_iact : integer;
    signal r_offset_c_last_h2_iact : integer;

    signal r_data_valid_iact : std_logic;

    signal r_offset_mem_iact : integer;
    signal r_offset_mem_wght : integer;

    signal r_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);

    -- WGHT

    signal r_w1_wght : integer;

    signal r_c0_wght       : integer;
    signal r_count_c0_wght : integer;

    -- signal r_W0 : integer; Kernel size
    -- signal r_count_w0 : integer; Kernel size

    signal r_count_w1_wght : integer;

    signal r_count_c1_wght : integer;

    signal r_count_h2_wght : integer;

    signal r_index_x_wght : integer;
    signal r_index_y_wght : integer;

    signal r_index_c_wght      : integer;
    signal r_index_c_last_wght : integer;

    signal r_offset_c_wght         : integer;
    signal r_offset_c_last_c1_wght : integer;
    signal r_offset_c_last_h2_wght : integer;

    signal r_data_valid_wght : std_logic;

    signal r_address_wght_valid : std_logic_vector(size_y - 1 downto 0);

    signal r_iact_done : std_logic;
    signal r_wght_done : std_logic;

    signal r_address_psum : array_t(0 to size_x)(addr_width_psum_mem - 1 downto 0);
    signal r_address_offsets_psum : array_t(0 to size_x - 1)(addr_width_psum_mem - 1 downto 0);
    signal address_offsets_psum_done : std_logic;
    signal address_offsets_count_x : integer range 0 to size_x;

begin

    r_c1      <= tiles_c;
    r_w1      <= image_x;
    r_h2      <= tiles_y;
    r_w1_wght <= kernel_size;

    r_c0_iact <= c_per_tile when r_count_c1_iact /= r_c1 - 1 else
                 c_last_tile;

    r_c0_wght <= c_per_tile when r_count_c1_wght /= r_c1 - 1 else
                 c_last_tile;

    r_offset_mem_iact <= r_offset_c_iact * image_x + r_count_w1_iact;
    r_offset_mem_wght <= r_offset_c_wght * kernel_size + r_count_w1_wght;

    iact_address_out : for i in 0 to size_rows - 1 generate

        address_iact(i)         <= std_logic_vector(to_unsigned(r_offset_mem_iact + i * image_x, addr_width_iact_mem));
        r_address_iact_valid(i) <= '1' when start = '1' and fifo_full_iact = '0' and r_iact_done = '0' else --
                                   '0';

    end generate iact_address_out;

    address_iact_valid <= r_address_iact_valid; --( others => r_data_valid_iact); --
    address_wght_valid <= r_address_wght_valid; --( others => r_data_valid_wght); --

    wght_address_out : for i in 0 to size_y - 1 generate

        address_wght(i)         <= std_logic_vector(to_unsigned(r_offset_mem_wght + i * kernel_size, addr_width_iact_mem));
        r_address_wght_valid(i) <= '1' when start = '1' and fifo_full_wght = '0' and r_wght_done = '0' else --
                                   '0';

    end generate wght_address_out;

    -- IACT

    p_iact_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_iact <= 0;
            r_count_c1_iact <= 0;
            r_count_h2_iact <= 0;
            r_count_w1_iact <= 0;

            r_offset_c_iact         <= 0;
            r_offset_c_last_c1_iact <= 0;
            r_offset_c_last_h2_iact <= 0;

            r_index_c_iact      <= 0;
            r_index_c_last_iact <= 0;

            r_data_valid_iact <= '0';

            r_iact_done <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                if not fifo_full_iact then
                    r_data_valid_iact <= '1';

                    if r_count_h2_iact /= r_h2 then
                        if r_count_c0_iact /= r_c0_iact - 1 then
                            r_count_c0_iact <= r_count_c0_iact + 1;
                            r_offset_c_iact <= r_offset_c_iact + image_x;
                            r_index_c_iact  <= r_index_c_iact + 1;
                        else
                            r_count_c0_iact <= 0;
                            r_offset_c_iact <= r_offset_c_last_c1_iact;
                            r_index_c_iact  <= r_index_c_last_iact;

                            if r_count_w1_iact /= r_w1 - 1 then
                                r_count_w1_iact <= r_count_w1_iact + 1;

                                if r_count_w1_iact = r_w1 - 2 then
                                    r_offset_c_last_c1_iact <= r_offset_c_iact + image_x;
                                    r_index_c_last_iact     <= r_index_c_iact + 1;
                                end if;
                            else
                                r_count_w1_iact <= 0;

                                if r_count_c1_iact /= r_c1 - 1 then
                                    r_count_c1_iact <= r_count_c1_iact + 1;
                                else
                                    r_count_c1_iact     <= 0;
                                    r_index_c_iact      <= 0;
                                    r_index_c_last_iact <= 0;
                                    r_offset_c_iact     <= r_offset_c_last_h2_iact + kernel_size;

                                    if r_count_h2_iact /= r_h2 then
                                        r_count_h2_iact         <= r_count_h2_iact + 1;
                                        r_offset_c_last_h2_iact <= r_offset_c_last_h2_iact + kernel_size;
                                        r_offset_c_last_c1_iact <= r_offset_c_last_h2_iact + kernel_size;
                                    else
                                        r_data_valid_iact <= '0';
                                        r_iact_done       <= '1';
                                    -- END
                                    end if;
                                end if;
                            end if;
                        end if;
                    else
                        r_data_valid_iact <= '0';
                        r_iact_done       <= '1';
                    end if;
                else
                    r_data_valid_iact <= '0';
                end if;
            else
                r_data_valid_iact <= '0';
            end if;
        end if;

    end process p_iact_counter;

    -- WGHT

    p_wght_counter : process (clk, rstn) is
    begin

        if not rstn then
            r_count_c0_wght <= 0;
            r_count_c1_wght <= 0;
            r_count_h2_wght <= 0;
            r_count_w1_wght <= 0;

            r_offset_c_wght         <= 0;
            r_offset_c_last_c1_wght <= 0;
            r_offset_c_last_h2_wght <= 0;

            r_index_c_wght      <= 0;
            r_index_c_last_wght <= 0;

            r_data_valid_wght <= '0';

            r_wght_done <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                if not fifo_full_wght then
                    r_data_valid_wght <= '1';

                    if r_count_h2_wght /= r_h2 then
                        if r_count_c0_wght /= r_c0_wght - 1 then
                            r_count_c0_wght <= r_count_c0_wght + 1;
                            r_offset_c_wght <= r_offset_c_wght + kernel_size;
                            r_index_c_wght  <= r_index_c_wght + 1;
                        else
                            r_count_c0_wght <= 0;
                            r_offset_c_wght <= r_offset_c_last_c1_wght;
                            r_index_c_wght  <= r_index_c_last_wght;

                            if r_count_w1_wght /= r_w1_wght - 1 then
                                r_count_w1_wght <= r_count_w1_wght + 1;

                                if r_count_w1_wght = r_w1_wght - 2 then
                                    r_offset_c_last_c1_wght <= r_offset_c_wght + kernel_size;
                                    r_index_c_last_wght     <= r_index_c_wght + 1;
                                end if;
                            else
                                r_count_w1_wght <= 0;

                                if r_count_c1_wght /= r_c1 - 1 then
                                    r_count_c1_wght <= r_count_c1_wght + 1;
                                else
                                    r_count_c1_wght     <= 0;
                                    r_index_c_wght      <= 0;
                                    r_index_c_last_wght <= 0;
                                    r_offset_c_wght     <= 0;

                                    if r_count_h2_wght /= r_h2 then
                                        r_count_h2_wght         <= r_count_h2_wght + 1;
                                        r_offset_c_last_c1_wght <= 0;
                                    else
                                        -- END
                                        r_data_valid_wght <= '0';
                                        r_wght_done       <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;
                    else
                        r_data_valid_wght <= '0';
                        r_wght_done       <= '1';
                    end if;
                elsif r_count_h2_wght = r_h2 then
                    r_data_valid_wght <= '0';
                    r_wght_done       <= '1';
                else
                    r_data_valid_wght <= '0';
                end if;
            end if;
        end if;

    end process p_wght_counter;

    p_calc_psum_offsets : process(clk, rstn) is
    begin

        if not rstn then

            r_address_offsets_psum <= (others => (others => '0'));
            address_offsets_psum_done <= '0';
            address_offsets_count_x <= 0;

        elsif rising_edge(clk) then
        
            if start = '1' and not address_offsets_psum_done = '1' then

                if address_offsets_count_x /= size_x - 1 then
                    r_address_offsets_psum(address_offsets_count_x + 1) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_offsets_psum(address_offsets_count_x)) + tiles_x), addr_width_psum_mem));
                    address_offsets_count_x <= address_offsets_count_x + 1;
                else
                    address_offsets_psum_done <= '1';
                end if;

            end if;

        end if;

    end process p_calc_psum_offsets;

    p_psum_counter : process(clk, rstn) is
    begin

        if not rstn then

        elsif rising_edge(clk) then

            -- tiles_x

        end if;

    end process p_psum_counter;

end architecture rtl;

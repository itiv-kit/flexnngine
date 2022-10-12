library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator_psum is
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

        start : in    std_logic;

        tiles_x : in    integer range 0 to 1023;

        i_valid_psum_out    : in    std_logic_vector(size_x - 1 downto 0);
        i_gnt_psum_binary_d : in    std_logic_vector(addr_width_x - 1 downto 0);
        i_command_psum      : in    command_lb_t;
        i_empty_psum_fifo   : in    std_logic_vector(size_x - 1 downto 0);

        o_address_psum : out   std_logic_vector(addr_width_psum_mem - 1 downto 0)
    );
end entity address_generator_psum;

architecture rtl of address_generator_psum is

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

    signal r_address_psum            : array_t(0 to size_x - 1)(addr_width_psum_mem - 1 downto 0);
    signal r_address_offsets_psum    : array_t(0 to size_x - 1)(addr_width_psum_mem - 1 downto 0);
    signal address_offsets_psum_done : std_logic;
    signal address_offsets_count_x   : integer range 0 to size_x;
    signal empty_fifo_d              : array_t(0 to 2)(size_x - 1 downto 0);

begin

    empty_fifo_d <= i_empty_psum_fifo & empty_fifo_d(0 to 1) when rising_edge(clk);

    -- Multiplex addresses for PE colums to interface the single Psum scratchpad
    mux_psum_adr : component mux
        generic map (
            input_width   => addr_width_psum_mem,
            input_num     => size_x,
            address_width => addr_width_x
        )
        port map (
            v_i => r_address_psum,
            sel => i_gnt_psum_binary_d,
            z_o => o_address_psum
        );

    -- Calculate offset for PE columns
    p_calc_psum_offsets : process (clk, rstn) is
    begin

        if not rstn then
            r_address_offsets_psum    <= (others => (others => '0'));
            address_offsets_psum_done <= '0';
            address_offsets_count_x   <= 0;
        elsif rising_edge(clk) then
            if start = '1' and address_offsets_psum_done = '0' then
                if address_offsets_count_x /= size_x - 1 then
                    r_address_offsets_psum(address_offsets_count_x + 1) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_offsets_psum(address_offsets_count_x)) + tiles_x), addr_width_psum_mem));
                    address_offsets_count_x                             <= address_offsets_count_x + 1;
                else
                    address_offsets_psum_done <= '1';
                end if;
            elsif address_offsets_psum_done = '1' and i_command_psum = c_lb_shrink then
                address_offsets_psum_done <= '0'; -- Tile h2 change
                address_offsets_count_x   <= 0;
                r_address_offsets_psum(0) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_offsets_psum(size_x - 1)) + tiles_x), addr_width_psum_mem));
            end if;
        end if;

    end process p_calc_psum_offsets;

    -- Calculate address by adding '1' each time a valid output appears

    gen_counter : for x in 0 to size_x - 1 generate

        p_psum_counter : process (clk, rstn) is
        begin

            if not rstn then
                r_address_psum(x) <= (others => '0');
            elsif rising_edge(clk) then
                if i_valid_psum_out(x) then
                    r_address_psum(x) <= std_logic_vector(to_unsigned(to_integer(unsigned(r_address_psum(x))) + 1, addr_width_psum_mem));
                elsif (and empty_fifo_d(0) = '1') and (and empty_fifo_d(1) = '1') and (and empty_fifo_d(2) = '1') then /* TODO Does that always make sense? Do not load when storing psums */
                    -- "Load" address offset to start with.
                    r_address_psum(x) <= r_address_offsets_psum(x);
                end if;
            end if;

        end process p_psum_counter;

    end generate gen_counter;

end architecture rtl;

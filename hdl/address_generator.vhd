library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

entity address_generator is
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

        tiles_c : in    integer range 0 to 1023;
        tiles_x : in    integer range 0 to 1023;
        tiles_y : in    integer range 0 to 1023;

        c_per_tile  : in    integer range 0 to 1023;
        c_last_tile : in    integer range 0 to 1023;

        image_x : in    integer range 0 to 1023; --! size of input image
        image_y : in    integer range 0 to 1023; --! size of input image
        channels : in    integer range 0 to 4095; -- Number of input channels the image and kernels have
        kernel_size : in    integer range 0 to 32;

        o_buffer_full_iact : in std_logic;
        o_buffer_full_wght : in std_logic
    );
end entity address_generator;

architecture rtl of address_generator is

    type   t_state_type is (s_idle, s_processing);
    signal r_state_wght : t_state_type;
    signal r_state_iact : t_state_type;

    signal r_C0 : integer;
    signal r_count_c0 : integer;

    -- signal r_W0 : integer; Kernel size
    -- signal r_count_w0 : integer; Kernel size

    signal r_W1 : integer;
    signal r_count_w1 : integer;

    signal r_C1 : integer;
    signal r_count_c1 : integer;

    signal r_H2 : integer;
    signal r_count_h2 : integer;

    signal r_index_x : integer;
    signal r_index_y : integer;

    signal r_index_c : integer;
    signal r_index_c_last : integer;

    signal r_offset_c : integer;
    signal r_offset_c_last_c1 : integer;
    signal r_offset_c_last_h2 : integer;

    signal r_data_valid : std_logic;
begin

    r_C1 <= tiles_c;
    r_C0 <= c_per_tile when r_count_c1 /= r_C1 - 1 else
            c_last_tile;
    r_W1 <= image_x;
    r_H2 <= tiles_y;

    p_command_counter : process (clk, rstn) is
    begin

        if not rstn then
            
            r_count_c0 <= 0;
            r_count_c1 <= 0;
            r_count_h2 <= 0;
            r_count_w1 <= 0;

            r_offset_c <= 0;
            r_offset_c_last_c1 <= 0;
            r_offset_c_last_h2 <= 0;

            r_index_c <= 0;
            r_index_c_last <= 0;

            r_data_valid <= '0';

        elsif rising_edge(clk) then

            if start = '1' then

                if not o_buffer_full_iact then

                    r_data_valid <= '1';

                    if r_count_h2 /= r_H2 then

                        if r_count_c0 /= r_C0 - 1 then

                            r_count_c0 <= r_count_c0 + 1;
                            r_offset_c <= r_offset_c + image_x;
                            r_index_c  <= r_index_c + 1;

                        else

                            r_count_c0 <= 0;
                            r_offset_c <= r_offset_c_last_c1;
                            r_index_c  <= r_index_c_last;
                            
                            if r_count_w1 /= r_W1 - 1 then

                                r_count_w1 <= r_count_w1 + 1;

                                if r_count_w1 = r_W1 - 2 then

                                    r_offset_c_last_c1 <= r_offset_c + image_x;
                                    r_index_c_last  <= r_index_c + 1; 

                                end if;

                            else

                                r_count_w1 <= 0;
                                
                                if r_count_c1 /= r_C1 - 1 then

                                    r_count_c1 <= r_count_c1 + 1;

                                else

                                    r_count_c1     <= 0;
                                    r_index_c      <= 0;
                                    r_index_c_last <= 0;
                                    r_offset_c     <= r_offset_c_last_h2 + kernel_size;

                                    if r_count_h2 /= r_H2 then

                                        r_count_h2 <= r_count_h2 + 1;
                                        r_offset_c_last_h2 <= r_offset_c_last_h2 + kernel_size;
                                        r_offset_c_last_c1 <= r_offset_c_last_h2 + kernel_size;

                                    else

                                        -- END

                                    end if;

                                end if;

                            end if;

                        end if;

                    end if;
                
                else

                    r_data_valid <= '0';

                end if;
                
            end if;

        end if;

    end process p_command_counter;


end architecture rtl;

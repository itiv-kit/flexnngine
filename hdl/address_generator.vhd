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

    signal r_C0_iact : integer;
    signal r_count_c0_iact : integer;

    -- signal r_W0 : integer; Kernel size
    -- signal r_count_w0 : integer; Kernel size

    signal r_W1 : integer;
    signal r_count_w1_iact : integer;

    signal r_C1 : integer;
    signal r_count_c1_iact : integer;

    signal r_H2 : integer;
    signal r_count_h2_iact : integer;

    signal r_index_x_iact : integer;
    signal r_index_y_iact : integer;

    signal r_index_c_iact : integer;
    signal r_index_c_last_iact : integer;

    signal r_offset_c_iact : integer;
    signal r_offset_c_last_c1_iact : integer;
    signal r_offset_c_last_h2_iact : integer;

    signal r_data_valid_iact : std_logic;

    -- WGHT

    signal r_W1_wght : integer;

    signal r_C0_wght : integer;
    signal r_count_c0_wght : integer;

    -- signal r_W0 : integer; Kernel size
    -- signal r_count_w0 : integer; Kernel size

    signal r_count_w1_wght : integer;

    signal r_count_c1_wght : integer;

    signal r_count_h2_wght : integer;

    signal r_index_x_wght : integer;
    signal r_index_y_wght : integer;

    signal r_index_c_wght : integer;
    signal r_index_c_last_wght : integer;

    signal r_offset_c_wght : integer;
    signal r_offset_c_last_c1_wght : integer;
    signal r_offset_c_last_h2_wght : integer;

    signal r_data_valid_wght : std_logic;

begin

    r_C1 <= tiles_c;
    r_W1 <= image_x;
    r_H2 <= tiles_y;
    r_W1_wght <= kernel_size;

    r_C0_iact <= c_per_tile when r_count_c1_iact /= r_C1 - 1 else
                 c_last_tile;

    r_C0_wght <= c_per_tile when r_count_c1_wght /= r_C1 - 1 else
                 c_last_tile;

    -- IACT

    p_iact_counter : process (clk, rstn) is
    begin

        if not rstn then
            
            r_count_c0_iact <= 0;
            r_count_c1_iact <= 0;
            r_count_h2_iact <= 0;
            r_count_w1_iact <= 0;

            r_offset_c_iact <= 0;
            r_offset_c_last_c1_iact <= 0;
            r_offset_c_last_h2_iact <= 0;

            r_index_c_iact <= 0;
            r_index_c_last_iact <= 0;

            r_data_valid_iact <= '0';

        elsif rising_edge(clk) then

            if start = '1' then

                if not o_buffer_full_iact then

                    r_data_valid_iact <= '1';

                    if r_count_h2_iact /= r_H2 then

                        if r_count_c0_iact /= r_C0_iact - 1 then

                            r_count_c0_iact <= r_count_c0_iact + 1;
                            r_offset_c_iact <= r_offset_c_iact + image_x;
                            r_index_c_iact  <= r_index_c_iact + 1;

                        else

                            r_count_c0_iact <= 0;
                            r_offset_c_iact <= r_offset_c_last_c1_iact;
                            r_index_c_iact  <= r_index_c_last_iact;
                            
                            if r_count_w1_iact /= r_W1 - 1 then

                                r_count_w1_iact <= r_count_w1_iact + 1;

                                if r_count_w1_iact = r_W1 - 2 then

                                    r_offset_c_last_c1_iact <= r_offset_c_iact + image_x;
                                    r_index_c_last_iact  <= r_index_c_iact + 1; 

                                end if;

                            else

                                r_count_w1_iact <= 0;
                                
                                if r_count_c1_iact /= r_C1 - 1 then

                                    r_count_c1_iact <= r_count_c1_iact + 1;

                                else

                                    r_count_c1_iact     <= 0;
                                    r_index_c_iact      <= 0;
                                    r_index_c_last_iact <= 0;
                                    r_offset_c_iact     <= r_offset_c_last_h2_iact + kernel_size;

                                    if r_count_h2_iact /= r_H2 then

                                        r_count_h2_iact <= r_count_h2_iact + 1;
                                        r_offset_c_last_h2_iact <= r_offset_c_last_h2_iact + kernel_size;
                                        r_offset_c_last_c1_iact <= r_offset_c_last_h2_iact + kernel_size;

                                    else

                                        -- END

                                    end if;

                                end if;

                            end if;

                        end if;

                    end if;
                
                else

                    r_data_valid_iact <= '0';

                end if;
                
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
    
                r_offset_c_wght <= 0;
                r_offset_c_last_c1_wght <= 0;
                r_offset_c_last_h2_wght <= 0;
    
                r_index_c_wght <= 0;
                r_index_c_last_wght <= 0;
    
                r_data_valid_wght <= '0';
    
            elsif rising_edge(clk) then
    
                if start = '1' then
    
                    if not o_buffer_full_wght then
    
                        r_data_valid_wght <= '1';
    
                        if r_count_h2_wght /= r_H2 then
    
                            if r_count_c0_wght /= r_C0_wght - 1 then
    
                                r_count_c0_wght <= r_count_c0_wght + 1;
                                r_offset_c_wght <= r_offset_c_wght + kernel_size;
                                r_index_c_wght  <= r_index_c_wght + 1;
    
                            else
    
                                r_count_c0_wght <= 0;
                                r_offset_c_wght <= r_offset_c_last_c1_wght;
                                r_index_c_wght  <= r_index_c_last_wght;
                                
                                if r_count_w1_wght /= r_W1_wght - 1 then
    
                                    r_count_w1_wght <= r_count_w1_wght + 1;
    
                                    if r_count_w1_wght = r_W1_wght - 2 then
    
                                        r_offset_c_last_c1_wght <= r_offset_c_wght + kernel_size;
                                        r_index_c_last_wght  <= r_index_c_wght + 1; 
    
                                    end if;
    
                                else
    
                                    r_count_w1_wght <= 0;
                                    
                                    if r_count_c1_wght /= r_C1 - 1 then
    
                                        r_count_c1_wght <= r_count_c1_wght + 1;
    
                                    else
    
                                        r_count_c1_wght     <= 0;
                                        r_index_c_wght      <= 0;
                                        r_index_c_last_wght <= 0;
                                        r_offset_c_wght     <= 0;
    
                                        if r_count_h2_wght /= r_H2 then
    
                                            r_count_h2_wght <= r_count_h2_wght + 1;
                                            r_offset_c_last_c1_wght <= 0;
    
                                        else
    
                                            -- END
    
                                        end if;
    
                                    end if;
    
                                end if;
    
                            end if;
    
                        end if;
                    
                    else
    
                        r_data_valid_wght <= '0';
    
                    end if;
                    
                end if;
    
            end if;
    
        end process p_wght_counter;

end architecture rtl;

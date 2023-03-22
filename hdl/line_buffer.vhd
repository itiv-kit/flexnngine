library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.utilities.all;

--! This component buffers the pixels of one line in the input image
--! The component implements a FIFO like buffer with a depth of #line_length.
--! If #data_in_valid is '1' the first element in the FIFO queue will be removed
--! and the input from #data_in is pushed to the end of the queue.

entity line_buffer is
    generic (
        line_length : positive := 32; --! Length of the lines in the image
        addr_width  : positive := 5;  --! Address width for the ram_dp subcomponent. ceil(log2(line_length))
        data_width  : positive := 8;  --! Data width for the ram_dp subcomponent - should be the width of data to be stored (8 / 16 bit?)
        psum_type   : boolean  := false
    );
    port (
        clk                : in    std_logic;                                 --! Clock input
        rstn               : in    std_logic;                                 --! Negated asynchronous reset
        i_enable           : in    std_logic;
        i_data             : in    std_logic_vector(data_width - 1 downto 0); --! Input to be pushed to the FIFO
        i_data_valid       : in    std_logic;                                 --! Data only read if valid = '1'
        o_data             : out   std_logic_vector(data_width - 1 downto 0); --! Outputs the element read_offset away from the head of the FIFO
        o_data_valid       : out   std_logic;
        o_buffer_full      : out   std_logic;
        o_buffer_full_next : out   std_logic;
        i_update_val       : in    std_logic_vector(data_width - 1 downto 0);
        i_update_offset    : in    std_logic_vector(addr_width - 1 downto 0);
        i_read_offset      : in    std_logic_vector(addr_width - 1 downto 0); --! Offset from head of FIFO; Shrink FIFO by this many elements
        i_command          : in    command_lb_t
    );
end entity line_buffer;

architecture rtl of line_buffer is

    component ram_dp is
        generic (
            addr_width     : positive;
            data_width     : positive;
            use_output_reg : std_logic := '0'
        );
        port (
            clk   : in    std_logic;
            wena  : in    std_logic;
            wenb  : in    std_logic;
            addra : in    std_logic_vector(addr_width - 1 downto 0);
            addrb : in    std_logic_vector(addr_width - 1 downto 0);
            dina  : in    std_logic_vector(data_width - 1 downto 0);
            dinb  : in    std_logic_vector(data_width - 1 downto 0);
            douta : out   std_logic_vector(data_width - 1 downto 0);
            doutb : out   std_logic_vector(data_width - 1 downto 0)
        );
    end component;

    -- input and output signals for the ram_dp
    signal r_wena  : std_logic;
    signal r_wenb  : std_logic;
    signal r_addra : std_logic_vector(addr_width - 1 downto 0);
    signal r_addrb : std_logic_vector(addr_width - 1 downto 0);
    signal r_dina  : std_logic_vector(data_width - 1 downto 0);
    signal r_dinb  : std_logic_vector(data_width - 1 downto 0);
    signal douta   : std_logic_vector(data_width - 1 downto 0);
    signal doutb   : std_logic_vector(data_width - 1 downto 0);

    -- process internal signals
    signal r_pointer_head   : integer;
    signal r_pointer_tail : integer;
    signal r_fill_count     : integer range 0 to line_length;
    -- signal fifo_filled_s    : std_logic;
    signal r_fifo_empty_s : std_logic;
    -- signal fifo_shrink_s    : std_logic;
    signal r_data_out_valid : std_logic;
    signal w_read_offset    : integer;
    -- signal update_offset_s  : std_logic_vector(addr_width - 1 downto 0);
    -- signal command_s        : std_logic_vector(1 downto 0);
    signal w_forward_update       : std_logic;
    signal r_forward_update_delay : std_logic_vector(1 downto 0);

    type t_array_command is array (0 to 2) of command_lb_t;

    signal r_command_delay : t_array_command;

    type t_array_update_offset is array (0 to 2) of std_logic_vector(addr_width - 1 downto 0);

    signal r_update_offset_delay : t_array_update_offset;

    -- Increment by one

    procedure incr (signal pointer : inout integer) is
    begin

        if pointer = line_length - 1 then
            pointer <= 0;
        else
            pointer <= pointer + 1;
        end if;

    end procedure;

    -- Increment by offset

    procedure incr_offset (
        signal pointer : inout integer;
        signal offset  : in integer) is
    begin

        if pointer + offset >= line_length then
            pointer <= pointer + offset - line_length;
        else
            pointer <= pointer + offset;
        end if;

    end procedure;

    -- Increment by offset variable

    procedure incr_offset_v (
        variable pointer : inout integer;
        variable offset  : in integer) is
    begin

        if pointer + offset >= line_length then
            pointer := pointer + offset - line_length;
        else
            pointer := pointer + offset;
        end if;

    end procedure;

begin

    read_update_empty : process (clk) is
    begin

        if rising_edge(clk) then
            if i_enable = '1' or psum_type = true then
                if i_command = c_lb_read or i_command = c_lb_read_update then
                    assert to_integer(unsigned(i_read_offset)) <= r_fill_count
                        report "Error: reading from offset " & integer'image(to_integer(unsigned(i_read_offset))) & " ; Fill count only " & integer'image(r_fill_count)
                        severity failure;

                    assert to_integer(unsigned(i_update_offset)) <= r_fill_count
                        report "Error: updating value at offset " & integer'image(to_integer(unsigned(i_read_offset))) & " ; Fill count only " & integer'image(r_fill_count)
                        severity failure;
                end if;
            end if;
        end if;

    end process read_update_empty;

    ram : component ram_dp
        generic map (
            addr_width => addr_width,
            data_width => data_width
        )
        port map (
            clk   => clk,
            wena  => r_wena,
            wenb  => r_wenb,
            addra => r_addra,
            addrb => r_addrb,
            dina  => r_dina,
            dinb  => r_dinb,
            douta => douta,
            doutb => doutb
        );

    -- Process to store input values that are valid
    write_val : process (clk, rstn) is

        variable v_pointer_update : integer;
        variable v_offset         : integer;

    begin

        if not rstn then
            r_wena           <= '0';
            r_addra          <= (others => '0');
            r_dina           <= (others => '0');
            r_pointer_tail <= 0;
            r_fifo_empty_s   <= '1';
        elsif rising_edge(clk) then
            -- Update data
            if r_command_delay(2) = c_lb_read_update then
                v_pointer_update := r_pointer_head;
                if or r_update_offset_delay(2) /= '0' then -- only calculate offset if update_offset not zero
                    v_offset := to_integer(unsigned(r_update_offset_delay(2)));
                    incr_offset_v(v_pointer_update, v_offset);
                end if;
                r_wena  <= '1';
                r_addra <= std_logic_vector(to_unsigned(v_pointer_update, addr_width));
                r_dina  <= i_update_val;
            -- Write data to tail
            elsif i_data_valid and not o_buffer_full then
                r_wena         <= '1';
                r_addra        <= std_logic_vector(to_unsigned(r_pointer_tail, addr_width));
                r_dina         <= i_data;
                incr(r_pointer_tail);
                r_fifo_empty_s <= '0';
            -- Idle
            else
                r_wena  <= '0';
                r_addra <= (others => '0');
                r_dina  <= (others => '0');
            end if;
        end if;

    end process write_val;

    o_buffer_full_next <= '1' when r_fill_count >= line_length - 1 else
                          '0';
    o_buffer_full      <= '1' when r_fill_count = line_length else
                          '0';

    p_fill_stat : process (clk, rstn) is
    begin

        if not rstn then
            r_fill_count <= 0;
        elsif rising_edge(clk) then
            if i_data_valid = '1' and (o_buffer_full = '0') and (r_command_delay(2) /= c_lb_read_update) and i_command /= c_lb_shrink then
                r_fill_count <= r_fill_count + 1;
            -- end if;
            elsif i_command = c_lb_shrink and i_data_valid = '1' and (o_buffer_full = '0') and (r_command_delay(2) /= c_lb_read_update) then
                if r_fill_count - w_read_offset + 1 < 0 then
                    r_fill_count <= 0;
                else
                    r_fill_count <= r_fill_count - w_read_offset + 1;
                end if;
            elsif i_command = c_lb_shrink then
                if r_fill_count - w_read_offset < 0 then
                    r_fill_count <= 0;
                else
                    r_fill_count <= r_fill_count - w_read_offset;
                end if;
            end if;
        end if;

    end process p_fill_stat;

    -- Process to set / clear the buffer full flag
    /*fifo_status : process (all) is
    begin

        if not rstn then
            buffer_full <= '0';
        else
            if pointer_tail_s = pointer_head_s and fifo_empty_s = '0' then
                buffer_full <= '1';
            elsif fifo_shrink_s then
                buffer_full <= '0';
            end if;
        end if;

    end process fifo_status;*/

    -- buffer_full      <= '1' when (pointer_tail_s = pointer_head_s) and (fifo_empty_s = '0') else
    --                    '0';

    w_forward_update <= '1' when r_command_delay(0) = c_lb_read_update and (i_command = c_lb_read_update or i_command = c_lb_read)
                                 and i_update_offset = r_update_offset_delay(0) else
                        '0';
    w_read_offset    <= to_integer(unsigned(i_read_offset));
    o_data           <= i_update_val when r_forward_update_delay(1) = '1' else
                        doutb;

    -- Process to delay signals
    delays : process (clk, rstn) is
    begin

        if not rstn then
            r_forward_update_delay <= (others => '0');
            r_command_delay        <= (others => c_lb_idle);
            r_update_offset_delay  <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if i_enable = '1' or psum_type = true then
                r_forward_update_delay <= r_forward_update_delay(0) & w_forward_update;
                r_command_delay        <= (i_command, r_command_delay(0), r_command_delay(1));
                r_update_offset_delay  <= (i_update_offset, r_update_offset_delay(0), r_update_offset_delay(1));
            end if;
        end if;

    end process delays;

    -- Process to execute read / read from address / update / shrink
    read_command : process (clk, rstn) is

        variable v_pointer_read : integer;
        variable v_offset       : integer;

    begin

        if not rstn then
            r_wenb           <= '0';
            r_addrb          <= (others => '0');
            r_dinb           <= (others => '0');
            r_pointer_head   <= 0;
            v_pointer_read   := 0;
            o_data_valid     <= '0';
            r_data_out_valid <= '0';
        elsif rising_edge(clk) then
            if i_enable = '1' or psum_type = true then
                o_data_valid <= r_data_out_valid;
                -- fifo_shrink_s  <= '0';
                r_wenb  <= '0';
                r_addrb <= (others => '0');
                r_dinb  <= (others => '0');

                case i_command is

                    -- idle
                    when c_lb_idle =>

                        r_data_out_valid <= '0';

                    -- read
                    when c_lb_read =>

                        v_pointer_read := r_pointer_head;
                        -- only calculate offset if read_offset not zero
                        if or i_read_offset /= '0' then
                            v_offset := to_integer(unsigned(i_read_offset));
                            incr_offset_v(v_pointer_read, v_offset);
                        end if;
                        -- read at pointer_read_v that was offset from pointer_head_s by read_offset
                        r_addrb          <= std_logic_vector(to_unsigned(v_pointer_read, addr_width));
                        r_data_out_valid <= '1';

                    -- read / update
                    when c_lb_read_update =>

                        v_pointer_read := r_pointer_head;
                        -- only calculate offset if read_offset not zero
                        if or i_read_offset /= '0' then
                            v_offset := to_integer(unsigned(i_read_offset));
                            incr_offset_v(v_pointer_read, v_offset);
                        end if;
                        -- read at pointer_read_v that was offset from pointer_head_s by read_offset
                        r_addrb          <= std_logic_vector(to_unsigned(v_pointer_read, addr_width));
                        r_data_out_valid <= '1';

                    -- shrink
                    when c_lb_shrink =>

                        r_data_out_valid <= '0';
                        -- incr(pointer_head_s);
                        incr_offset(r_pointer_head,  w_read_offset);
                    -- fifo_shrink_s <= '1';

                    when others =>

                        r_data_out_valid <= '0';

                end case;

            else
                r_data_out_valid <= '0';
                o_data_valid     <= r_data_out_valid;
            end if;
        end if;

    end process read_command;

end architecture rtl;

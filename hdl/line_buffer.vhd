library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
    use axi_filter_dma_v1_00_a.all;

--! This component buffers the pixels of one line in the input image
--! The component implements a FIFO like buffer with a depth of #line_length.
--! If #data_in_valid is '1' the first element in the FIFO queue will be removed
--! and the input from #data_in is pushed to the end of the queue.

entity line_buffer is
    generic (
        line_length : positive := 7; --! Length of the lines in the image
        addr_width  : positive := 3; --! Address width for the ram_dp subcomponent. ceil(log2(line_length))
        data_width  : positive := 8  --! Data width for the ram_dp subcomponent - should be the width of data to be stored (8 / 16 bit?)
    );
    port (
        clk            : in    std_logic;                                 --! Clock input
        rstn           : in    std_logic;                                 --! Negated asynchronous reset
        data_in        : in    std_logic_vector(data_width - 1 downto 0); --! Input to be pushed to the FIFO
        data_in_valid  : in    std_logic;                                 --! Data only read if valid = '1'
        data_out       : out   std_logic_vector(data_width - 1 downto 0); --! Outputs the element read_offset away from the head of the FIFO
        data_out_valid : out   std_logic;
        buffer_full    : out   std_logic;
        update_val     : in    std_logic_vector(data_width - 1 downto 0);
        update_offset    : in    std_logic_vector(addr_width - 1 downto 0);
        read_offset    : in    std_logic_vector(addr_width - 1 downto 0); --! Offset from head of FIFO; Shrink FIFO by this many elements
        command        : in    std_logic_vector(1 downto 0)
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
    signal wena  : std_logic;
    signal wenb  : std_logic;
    signal addra : std_logic_vector(addr_width - 1 downto 0);
    signal addrb : std_logic_vector(addr_width - 1 downto 0);
    signal dina  : std_logic_vector(data_width - 1 downto 0);
    signal dinb  : std_logic_vector(data_width - 1 downto 0);
    signal douta : std_logic_vector(data_width - 1 downto 0);
    signal doutb : std_logic_vector(data_width - 1 downto 0);

    -- process internal signals
    signal pointer_head_s : integer;
    signal pointer_tail_s : integer;
    -- signal fifo_filled_s    : std_logic;
    signal fifo_empty_s     : std_logic;
    -- signal fifo_shrink_s    : std_logic;
    signal data_out_valid_s : std_logic;
    signal read_offset_s    : integer;

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

    -- Decrement by offset variable

    /*procedure decr (
        variable pointer : inout integer;
        variable offset  : in integer) is
    begin

        if pointer = offset - 1 then
            pointer := line_length - 1;
        elsif pointer < offset - 1 then
            pointer := line_length - (offset - pointer);
        else
            pointer := pointer - offset;
        end if;

    end procedure;*/

begin

    ram : component ram_dp
        generic map (
            addr_width => addr_width,
            data_width => data_width
        )
        port map (
            clk   => clk,
            wena  => wena,
            wenb  => wenb,
            addra => addra,
            addrb => addrb,
            dina  => dina,
            dinb  => dinb,
            douta => douta,
            doutb => doutb
        );

    -- Process to store input values that are valid
    write_val : process (clk, rstn) is
        variable pointer_update_v : integer;
        variable offset_v         : integer;
    begin

        if not rstn then
            wena           <= '0';
            addra          <= (others => '0');
            dina           <= (others => '0');
            pointer_tail_s <= 0;
            fifo_empty_s   <= '1';
        elsif rising_edge(clk) then
            -- Update data
            if command = "10" then
                pointer_update_v := pointer_head_s;
                if or update_offset /= '0' then -- only calculate offset if update_offset not zero
                    offset_v := to_integer(unsigned(update_offset));
                    incr_offset_v(pointer_update_v, offset_v);
                end if;
                wena  <= '1';
                addra <= std_logic_vector(to_unsigned(pointer_update_v, addr_width));
                dina  <= update_val; 
            -- Write data to tail
            elsif data_in_valid and not buffer_full then
                wena         <= '1';
                addra        <= std_logic_vector(to_unsigned(pointer_tail_s, addr_width));
                dina         <= data_in;
                incr(pointer_tail_s);
                fifo_empty_s <= '0';
            -- Idle
            else
                wena  <= '0';
                addra <= (others => '0');
                dina  <= (others => '0');
            end if;
        end if;

    end process write_val;

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

    buffer_full <= '1' when (pointer_tail_s = pointer_head_s) and (fifo_empty_s = '0') else '0';

    -- Process to execute read / read from address / update / shrink
    read_command : process (clk, rstn) is

        variable pointer_read_v : integer;
        variable offset_v       : integer;

    begin

        if not rstn then
            wenb             <= '0';
            addrb            <= (others => '0');
            dinb             <= (others => '0');
            pointer_head_s   <= 0;
            pointer_read_v   := 0;
            data_out_valid   <= '0';
            data_out_valid_s <= '0';

            elsif rising_edge(clk) then
            data_out_valid   <= data_out_valid_s;
            -- fifo_shrink_s  <= '0';
            wenb           <= '0';
            addrb          <= (others => '0');
            dinb           <= (others => '0');

            case command is

                -- idle
                when "00" =>

                    data_out_valid_s <= '0';

                -- read
                when "01" =>

                    pointer_read_v := pointer_head_s;
                    if or read_offset /= '0' then -- only calculate offset if read_offset not zero
                        offset_v := to_integer(unsigned(read_offset));
                        incr_offset_v(pointer_read_v, offset_v);
                    end if;
                    -- read at pointer_read_v that was offset from pointer_head_s by read_offset
                    addrb            <= std_logic_vector(to_unsigned(pointer_read_v, addr_width));
                    data_out_valid_s <= '1';

                -- read / update
                when "10" =>

                    pointer_read_v := pointer_head_s;
                    if or read_offset /= '0' then -- only calculate offset if read_offset not zero
                        offset_v := to_integer(unsigned(read_offset));
                        incr_offset_v(pointer_read_v, offset_v);
                    end if;
                    -- read at pointer_read_v that was offset from pointer_head_s by read_offset
                    addrb            <= std_logic_vector(to_unsigned(pointer_read_v, addr_width));
                    data_out_valid_s <= '1';

                -- shrink
                when "11" =>

                    data_out_valid_s <= '0';
                    -- incr(pointer_head_s);
                    incr_offset(pointer_head_s,  read_offset_s);
                    -- fifo_shrink_s <= '1';

                when others =>

                    data_out_valid_s <= '0';

            end case;

        end if;

    end process read_command;

    read_offset_s   <= to_integer(unsigned(read_offset));
    data_out        <= doutb;
-- buffer_full <= fifo_filled_s;

end architecture rtl;

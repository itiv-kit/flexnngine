library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;

library accel;
    use accel.utilities.all;

--! Testbench for the reshaping scratchpad unit

entity spad_reshape_tb is
    generic (
        word_size : positive := 8; -- bits of a single word
        cols      : positive := 8; -- columns of word_size words

        addr_width : positive := 12; -- address width for standard & reshaped ports
        data_width : positive := cols * word_size;

        image_width  : positive := 8; -- image columns
        image_height : positive := 8; -- image rows
        image_size   : positive := image_height * image_width; -- number of words per image
        channels     : positive := 16 -- number of channels (= image count)
    );
end entity spad_reshape_tb;

architecture imp of spad_reshape_tb is

    -- address offset within channel packets (i.e. sets of cols channels)
    constant channel_stride : integer := 2 ** addr_width / cols;

    signal write_done : boolean := false;
    signal read_data_inflight : boolean;
    signal read_data_expected : array_t(0 to cols - 1)(word_size - 1 downto 0);

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';

    -- "standard" interface for non-reshaped data I/O
    signal std_en       : std_logic;
    signal std_write_en : std_logic_vector(cols - 1 downto 0);
    signal std_addr     : std_logic_vector(addr_width - 1 downto 0);
    signal std_din      : std_logic_vector(data_width - 1 downto 0);
    signal std_dout     : std_logic_vector(data_width - 1 downto 0);

    -- "reshaped" interface to read nchw <-> nhwc reshaped data (currently read only)
    signal rsh_en       : std_logic;
    signal rsh_addr     : std_logic_vector(addr_width - 1 downto 0);
    signal rsh_dout     : std_logic_vector(data_width - 1 downto 0);

begin

    dut : entity accel.spad_reshape
        generic map (
            word_size  => word_size,
            cols       => cols,
            addr_width => addr_width
        )
        port map (
            clk          => clk,
            rstn         => not rst,
            std_en       => std_en,
            std_write_en => std_write_en,
            std_addr     => std_addr,
            std_din      => std_din,
            std_dout     => std_dout,
            rsh_en       => rsh_en,
            rsh_addr     => rsh_addr,
            rsh_dout     => rsh_dout
        );

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rst : process is
    begin

        wait for 30 ns;

        wait until rising_edge(clk);
        rst <= '0';

        wait;

    end process gen_rst;

    gen_inputs : process is
        variable element : unsigned(word_size - 1 downto 0);
        variable address : unsigned(addr_width - 1 downto 0);
    begin

        std_en       <= '0';
        std_write_en <= (others => '0');

        if rst = '0' then
            wait until rst = '0';
        end if;

        wait for 50 ns;

        for channel in 0 to channels - 1 loop

            -- calculate base address for this channel, strides across sub-memories
            address := to_unsigned(channel / cols * image_size / cols + channel mod cols * channel_stride, addr_width);

            -- write an image with cols pixels per cycle
            for i in 0 to image_size / cols - 1 loop

                wait until rising_edge(clk);

                std_en       <= '1';
                std_write_en <= (others => '1');
                std_addr     <= std_logic_vector(address);
                std_din      <= (others => '0');

                for w in 0 to cols - 1 loop
                    element := to_unsigned((image_size * channel + i * cols + w) mod 2 ** word_size, word_size);
                    std_din(word_size * (w + 1) - 1 downto word_size * w) <= std_logic_vector(element);
                end loop;

                address := address + 1;

            end loop;

            wait until rising_edge(clk);

            std_en       <= '0';
            std_write_en <= (others => '0');

        end loop;

        std_write_en <= (others => '0');

        wait for 200 ns;

        write_done <= true;

        wait;

    end process gen_inputs;

    read_data : process is

        variable address : unsigned(addr_width - 1 downto 0);
        variable element : integer;
        variable expect  : integer;

    begin

        rsh_en   <= '0';
        rsh_addr <= (others => '0');

        read_data_inflight <= false;

        wait until write_done = true;

        -- read out image data with cols channels per row, rows first

        for channel_set in 0 to channels / cols - 1 loop -- sets of col channels

            for row in 0 to image_height - 1 loop

                address := to_unsigned(row * image_width + channel_set * image_size, addr_width);

                rsh_en   <= '1';
                rsh_addr <= std_logic_vector(address);

                wait until rising_edge(clk);

                read_data_inflight <= true;

                for channel in 0 to cols - 1 loop

                    expect := (row * image_width + image_size * channel) mod 2 ** word_size;

                    read_data_expected(channel) <= std_logic_vector(to_unsigned(expect, word_size));

                end loop;

                -- report "got read " & integer'image(to_integer(unsigned(rsh_dout(7 downto 0))));

            end loop;

        end loop;

        wait until rising_edge(clk);

        rsh_en             <= '0';
        read_data_inflight <= false;

        wait;

        -- for n in 0 to equations'high loop

        --     wait until rising_edge(clk) and o_data_valid = '1';
        --     eq := equations(n);
        --     tmp_out := to_integer(signed(o_data));

        --     assert eq.output = tmp_out report "Output invalid, expected " & integer'image(eq.output) & " but got " & integer'image(tmp_out)
        --         severity failure;

        -- end loop;

        -- report "Output check is finished."
        --     severity note;

        -- finish;

    end process read_data;

    check_output : process is

        variable element : integer;
        variable expect  : integer;

    begin

        wait until rising_edge(clk);

        if read_data_inflight then

                for channel in 0 to cols - 1 loop

                    expect := to_integer(unsigned(read_data_expected(channel)));

                    element := to_integer(unsigned(rsh_dout(word_size * (channel + 1) - 1 downto word_size * channel)));

                    assert element = expect report "Output invalid, expected " & integer'image(expect) & " but got " & integer'image(element)
                        severity warning; --failure;

                end loop;

        end if;

    end process check_output;

end architecture imp;

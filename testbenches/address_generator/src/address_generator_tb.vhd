library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use std.env.finish;
    use std.env.stop;

library accel;
    use accel.utilities.all;

--! Testbench for the address generator

entity address_generator_tb is
    generic (
        size_y              : positive := 5; --! accelerator height
        size_x              : positive := 5; --! accelerator width
        addr_width_x        : positive := 3; --! array pe index bit width
        addr_width_y        : positive := 3; --! array pe index bit width
        addr_width_iact_mem : positive := 16;
        addr_width_wght_mem : positive := 16;
        read_size           : positive := 8; -- columns of word_size words
        word_size           : positive := 8
    );
end entity address_generator_tb;

architecture imp of address_generator_tb is

    constant size_rows      : integer := size_x + size_y - 1;
    constant mem_data_width : integer := read_size * word_size;

    constant params : parameters_t :=
    (
        -- inputchs => 34, -- (c1 - 1) * c0 + c0_last_c1
        inputchs    => 8,  -- (c1 - 1) * c0 + c0_last_c1
        outputchs   => 3,
        image_y     => 16,
        image_x     => 16,
        kernel_size => 3,
        c1          => 1,
        w1          => 14, -- output image width
        h2          => 4,  -- number of iterations to process full image height (ceil(image_y/size_x)=4)
        m0          => 3,  -- number of mapped kernels (here: three 3x3 kernels)
        m0_last_m1  => 1,
        c0          => 8,  -- number of channels processed at once
        c0_last_c1  => 8,
        -- c0 => 12, -- number of channels processed at once
        -- c0_last_c1 => 10,
        scale_fp32   => (others => (others => '0')),
        zeropt_fp32  => (others => (others => '0')),
        mode_act     => passthrough,
        bias         => (others => 0),
        requant_enab => true,
        base_iact    => 0,
        -- stride_iact_ch => 5, -- 5 words of read size 8 bytes for inputchs channels (ceil(34/8) = 5)
        -- stride_iact_ch => 1, -- 6 words of read size 8 bytes for inputchs channels (ceil(48/8) = 6)
        stride_iact_w  => 16 / 8,      -- words of read size 8 bytes for a full image row (with w pixels, padded to multiple of read size)
        stride_iact_hw => 16 * 16 / 8, -- 128 8-byte words to load a hxw image
        others         => 0
    );

    constant w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0) := ("001", "001", "001", "000", "000");
    -- constant w_m0_dist : array_t(0 to size_y - 1)(addr_width_y - 1 downto 0) := ("001","001","001","001","001","001","001","001","001","000");

    signal clk   : std_logic := '1';
    signal rstn  : std_logic := '0';
    signal done  : boolean   := false;
    signal start : std_logic := '0';

    signal o_iact_done : std_logic;
    -- signal o_wght_done : std_logic;

    signal i_fifo_full_iact : std_logic := '0';
    -- signal i_fifo_full_wght : std_logic := '0';

    signal o_address_iact : array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    -- -- signal o_address_wght       : array_t(0 to size_y - 1)(addr_width_wght_mem - 1 downto 0);
    signal o_address_iact_valid : std_logic_vector(size_rows - 1 downto 0);
    -- signal o_address_wght_valid : std_logic_vector(size_y - 1 downto 0);

    type ram_type is array (0 to (2 ** addr_width_iact_mem / read_size) - 1) of std_logic_vector(mem_data_width - 1 downto 0);

    -- "standard" interface for non-reshaped data I/O
    -- signal std_en       : std_logic;
    -- signal std_write_en : std_logic_vector(cols - 1 downto 0);
    -- signal std_addr     : std_logic_vector(addr_width - 1 downto 0);
    -- signal std_din      : std_logic_vector(data_width - 1 downto 0);
    -- signal std_dout     : std_logic_vector(data_width - 1 downto 0);

    -- "reshaped" interface to read nchw <-> nhwc reshaped data (currently read only)
    signal mem_rsh_en   : std_logic;
    signal mem_rsh_addr : std_logic_vector(addr_width_iact_mem - 1 downto 0);
    signal mem_rsh_din  : std_logic_vector(mem_data_width - 1 downto 0);
    signal mem_rsh_dout : std_logic_vector(mem_data_width - 1 downto 0);

    signal fifo_rd    : std_logic_vector(0 to size_rows - 1);
    signal fifo_dout  : array_t(0 to size_rows - 1)(addr_width_iact_mem - 1 downto 0);
    signal fifo_empty : std_logic_vector(0 to size_rows - 1);
    signal fifo_full  : std_logic_vector(0 to size_rows - 1);

    signal fifo_rd_delay    : std_logic_vector(0 to size_rows - 1);
    signal mem_rsh_en_delay : std_logic;
    signal row_read         : integer;
    signal row_read_delay   : integer;

begin

    dut : entity accel.address_generator_iact(rs_dataflow)
        generic map (
            size_x              => size_x,
            size_y              => size_y,
            size_rows           => size_x + size_y - 1,
            line_length_iact    => 64,
            line_length_psum    => 128,
            line_length_wght    => 64,
            addr_width_x        => addr_width_x,
            addr_width_y        => addr_width_y,
            addr_width_iact_mem => addr_width_iact_mem,
            addr_width_wght_mem => addr_width_wght_mem
        )
        port map (
            clk                  => clk,
            rstn                 => rstn,
            i_start              => start,
            i_params             => params,
            o_iact_done          => o_iact_done,
            i_fifo_full_iact     => i_fifo_full_iact,
            o_address_iact       => o_address_iact,
            o_address_iact_valid => o_address_iact_valid
        -- i_m0_dist            => w_m0_dist,
        -- o_wght_done          => o_wght_done,
        -- i_fifo_full_wght     => i_fifo_full_wght,
        -- o_address_wght       => o_address_wght,
        -- o_address_wght_valid => o_address_wght_valid
        );

    mem : entity accel.spad_reshape
        generic map (
            cols       => read_size,
            addr_width => addr_width_iact_mem
        )
        port map (
            clk  => clk,
            rstn => rstn,
            -- std_en       => std_en,
            -- std_write_en => std_write_en,
            -- std_addr     => std_addr,
            -- std_din      => std_din,
            -- std_dout     => std_dout,
            std_en       => '0',
            std_write_en => (others => '0'),
            std_addr     => (others => '0'),
            std_din      => (others => '0'),
            std_dout     => open,
            rsh_en       => mem_rsh_en,
            rsh_addr     => mem_rsh_addr,
            rsh_din      => mem_rsh_din,
            rsh_dout     => mem_rsh_dout
        );

    fifo_iact_address : for y in 0 to size_rows - 1 generate

        fifo_iact_address : entity accel.fifo
            generic map (
                mem_size => 16
            )
            port map (
                clk   => clk,
                rst   => not rstn,
                wr    => o_address_iact_valid(y),
                din   => o_address_iact(y),
                full  => fifo_full(y),
                rd    => fifo_rd(y),
                dout  => fifo_dout(y),
                empty => fifo_empty(y)
            );

    end generate fifo_iact_address;

    gen_clk : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process gen_clk;

    gen_rstn : process is
    begin

        wait for 50 ns;
        wait until rising_edge(clk);
        rstn <= '1';
        wait;

    end process gen_rstn;

    gen_inputs : process is
    begin

        start <= '0';

        if rstn = '0' then
            wait until rstn = '1';
        end if;

        wait for 150 ns;

        wait until rising_edge(clk);
        start <= '1';

        wait until o_iact_done and and fifo_empty;
        wait for 150 ns;

        wait until rising_edge(clk);
        start <= '0';

        wait;

    end process gen_inputs;

    -- individual processes for each memory column

    gen_mem : for col in 0 to read_size - 1 generate

        fill_mem : process is

            alias    ram     is << variable ^.mem.gen_cols(col).ram.ram : ram_type >>;
            variable address : integer;
            variable word    : integer;
            variable pixel   : integer;
            variable data    : std_logic_vector(word_size - 1 downto 0);
            variable ichs    : integer;

        begin

            word := 0;
            ichs := 0;

            -- every read_size channels are in parallel. generate enough images to reach inputchs
            while ichs < params.inputchs / read_size loop

                -- write one full image linearly to a column
                for h in 0 to params.image_y - 1 loop

                    for w in 0 to params.image_x - 1 loop

                        pixel := h * params.image_x + w;

                        address := ichs * params.stride_iact_hw + h * params.stride_iact_w + w / read_size;
                        data    := std_logic_vector(to_unsigned(pixel mod 2 ** word_size, word_size));

                        ram(address)((word + 1) * word_size - 1 downto word * word_size) := data;

                        if word < read_size - 1 then
                            word := word + 1;
                        else
                            word := 0;
                        -- report "wrote to mem addr " & integer'image(address) & ": " & integer'image(pixel);
                        end if;

                    end loop;

                end loop;

                ichs := ichs + 1;

            end loop;

            wait;

        end process fill_mem;

    end generate gen_mem;

    i_fifo_full_iact <= or fifo_full;

    fifo_read : process (all) is
    begin

        -- read from first non-empty fifo
        fifo_rd <= (others => '0');

        for row in 0 to size_rows - 1 loop

            if fifo_empty(row) = '0' then
                fifo_rd(row) <= '1';
                exit;
            end if;

        end loop;

    end process fifo_read;

    verify : process is

        variable row_cnt : int_line_t(0 to size_rows - 1) := (others => 0);
        variable c0_cnt  : int_line_t(0 to size_rows - 1) := (others => 0);
        variable w1_cnt  : int_line_t(0 to size_rows - 1) := (others => 0);
        variable expect  : integer;
        variable tmp     : integer;
        variable row     : integer;

    begin

        wait until rising_edge(clk);

        fifo_rd_delay    <= fifo_rd;
        mem_rsh_en_delay <= mem_rsh_en;
        row_read_delay   <= row_read;

        -- process word read in previous cycle
        mem_rsh_en <= '0';

        for rdrow in 0 to size_rows - 1 loop

            if fifo_rd_delay(rdrow) = '1' then
                mem_rsh_en   <= '1';
                mem_rsh_addr <= fifo_dout(rdrow);
                row_read     <= rdrow;
                exit;
            end if;

        end loop;

        -- verify data read from spad_reshape
        row := row_read_delay;

        if mem_rsh_en_delay = '1' then
            -- our test pixels are same in all channels and just numbered linearly
            -- after c1 rows are processed, start next h2 iteration -> offset by size_x rows
            expect := (row_cnt(row) / params.c1) * size_x * params.image_x + row * params.image_x + w1_cnt(row);
            expect := expect mod 2 ** word_size; -- wrap to 8 bits

            for word in 0 to read_size - 1 loop

                tmp := to_integer(unsigned(mem_rsh_dout((word + 1) * word_size - 1 downto word * word_size)));
                assert tmp = expect
                    report "expected " & integer'image(expect) & " for c0 " & integer'image(c0_cnt(row)) & " w1 " & integer'image(w1_cnt(row)) & " row " & integer'image(row) & ", got " & integer'image(tmp)
                    severity failure;

            end loop;

            if c0_cnt(row) <= params.c0 - read_size - 1 then
                c0_cnt(row) := c0_cnt(row) + read_size; -- TODO: smaller for partial reads once implemented
            else
                c0_cnt(row) := 0;

                if w1_cnt(row) < params.image_x - 1 then
                    w1_cnt(row) := w1_cnt(row) + 1;
                else
                    w1_cnt(row)  := 0;
                    row_cnt(row) := row_cnt(row) + 1;
                    report integer'image(row_cnt(row)) & " full c0*w0 rows loaded for PE row " & integer'image(row);
                end if;
            end if;
        end if;

        if o_iact_done and not mem_rsh_en_delay and and fifo_empty then

            for row in 0 to size_rows - 1 loop

                assert row_cnt(row) = params.c1 * params.h2
                    report "row " & integer'image(row) & " incomplete"
                    severity failure;

            end loop;

            report "Output checked successfully"
                severity note;

            wait until start = '0';

            finish;
        end if;

    end process verify;

end architecture imp;

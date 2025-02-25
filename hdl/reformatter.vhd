library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library accel;
    use accel.utilities.all;

-- reshape input rows to output columns
-- input words of elemt_count elements of elemtn_size bits each
-- output will start after element_count input words are present
-- input example:
--   word 0: 00 01 02 03   word 4: 04 05 06 07 (input channel 0)
--   word 1: 10 11 12 13   word 5: 14 15 16 17 (input channel 1)
--   word 2: 20 21 22 23   word 6: 24 25 26 27 (input channel 2)
--   word 3: 30 31 32 33   word 7: 34 35 36 37 (input channel 3)
-- output example:
--   row 0: 00 10 20 30 then 04 14 24 34 (row 0 of all input channels)
--   row 1: 01 11 21 31 then 05 15 25 35 (row 1 of all input channels)
--   row 2: 02 12 22 32 then 06 16 26 36 (row 2 of all input channels)
--   row 3: 03 13 23 33 then 07 17 27 37 (row 3 of all input channels)

entity reformatter is
    generic (
        element_size  : positive := 8;
        element_count : positive := 8;
        output_rows   : positive := 16;
        element_width : positive := element_count * element_size
    );
    port (
        clk : in    std_logic;
        rst : in    std_logic;
        -- input data from spad
        o_ready : out   std_logic;
        i_valid : in    std_logic;
        i_data  : in    std_logic_vector(element_width - 1 downto 0);
        -- output data to pe array fifos
        i_ready : in    std_logic_vector(output_rows - 1 downto 0);
        o_valid : out   std_logic_vector(output_rows - 1 downto 0);
        o_data  : out   std_logic_vector(element_width - 1 downto 0)
    );
end entity reformatter;

architecture rtl of reformatter is

    constant mem_word_count    : integer := output_rows;
    constant mem_addr_width    : integer := integer(ceil(log2(real(mem_word_count))));
    constant output_steps      : integer := (output_rows + element_count - 1) / element_count;
    constant input_index_width : integer := integer(ceil(log2(real(element_count))));

    signal w_mem_din   : array_t(element_count - 1 downto 0)(element_size - 1 downto 0);
    signal w_mem_dout  : array_t(element_count - 1 downto 0)(element_width - 1 downto 0);
    signal w_mem_wen   : std_logic_vector(element_count - 1 downto 0);
    signal w_mem_addra : std_logic_vector(mem_addr_width + input_index_width - 1 downto 0);
    signal w_mem_addrb : std_logic_vector(mem_addr_width - 1 downto 0);

    signal output_step    : integer range 0 to output_steps - 1;
    signal output_element : integer range 0 to output_rows - 1;
    signal mem_write_idx  : unsigned(mem_addr_width + input_index_width - 1 downto 0);

begin

    o_data <= w_mem_dout(output_element);

    w_mem_addra <= std_logic_vector(mem_write_idx);
    w_mem_addrb <= std_logic_vector(to_unsigned(output_step, mem_addr_width));

    gen_memory : for i in 0 to element_count - 1 generate

        w_mem_din(i) <= i_data((i + 1) * element_size - 1 downto i * element_size);
        -- w_mem_addra(i) <= std_logic_vector(mem_write_idx);
        w_mem_wen(i) <= i_valid when mem_write_idx = i else '0';

        mem : entity accel.ram_mw
            generic map (
                addr_width_b     => mem_addr_width,
                addr_width_delta => input_index_width,
                data_width_a     => element_size
            )
            port map (
                clka  => clk,
                clkb  => clk,
                wena  => w_mem_wen(i),
                wenb  => '0',
                addra => w_mem_addra,
                addrb => w_mem_addrb,
                dina  => w_mem_din(i),
                dinb  => (others => '0'),
                doutb => w_mem_dout(i)
            );

    -- mem : entity accel.ram_dp generic map (
    --     addr_width => mem_addr_width,
    --     data_width => element_size
    -- ) port map (
    --     clk   => clk,
    --     wena  => w_mem_wen(i),
    --     wenb  => '0',
    --     addra => w_mem_addra(i),
    --     addrb => w_mem_addrb,
    --     dina  => w_mem_din(i),
    --     dinb  => (others => '0'),
    --     douta => w_mem_dout(i)
    -- );

    end generate gen_memory;

    p_reformat : process is
    begin

        wait until rising_edge(clk);

        if rst then
            output_step    <= 0;
            output_element <= 0;
            mem_write_idx  <= (others => '0');
        else
            if i_valid = '1' and mem_write_idx < 8 then
                mem_write_idx <= mem_write_idx + 1;
            end if;

            o_valid <= (others => '0');
            if mem_write_idx > element_count * output_step then
                output_element          <= output_element + 1;
                o_valid(output_element) <= '1';
            else
            end if;
        end if;

    end process p_reformat;

end architecture rtl;

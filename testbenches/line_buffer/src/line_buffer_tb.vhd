library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--! This testbench can be used to test the line_buffer component.

--! The line_buffer is filled with the pixels of a test image.
--! The testbench checks if the correct pixels appear on the line_buffer output
--! at the right time.

entity line_buffer_tb is
    generic (
        line_length     : POSITIVE := 7; --! Length of the lines in the test image
        number_of_lines : POSITIVE := 5; --! Number of lines in the test image
        addr_width      : POSITIVE := 3; --! Address width for the ram_dp component
        data_width      : POSITIVE := 8  --! 8 bit data being saved
    );
end entity line_buffer_tb;

architecture imp of line_buffer_tb is

    component line_buffer is
        generic (
            line_length : positive := 7;
            addr_width  : positive := 3;
            data_width  : positive := 8
        );
        port (
            clk            : in    std_logic;
            rstn           : in    std_logic;
            data_in        : in    std_logic_vector(data_width - 1 downto 0);
            data_in_valid  : in    std_logic;
            data_out       : out   std_logic_vector(data_width - 1 downto 0);
            data_out_valid : out   std_logic;
            update_val     : in    std_logic_vector(data_width - 1 downto 0);
            update_addr    : in    std_logic_vector(addr_width - 1 downto 0);
            read_offset    : in    std_logic_vector(addr_width - 1 downto 0);
            command        : in    std_logic_vector(1 downto 0)
        );
    end component;

    signal clk            : std_logic := '1';
    signal rstn           : std_logic;
    signal data_in_valid  : std_logic;
    signal data_in        : std_logic_vector(data_width - 1 downto 0);
    signal data_out       : std_logic_vector(data_width - 1 downto 0);
    signal data_out_valid : std_logic;
    signal update_val     : std_logic_vector(data_width - 1 downto 0);
    signal update_addr    : std_logic_vector(addr_width - 1 downto 0);
    signal read_offset    : std_logic_vector(addr_width - 1 downto 0);
    signal command        : std_logic_vector(1 downto 0);

    type image_t is array(natural range <>, natural range <>) of integer;

    -- test data, simulates the output of classify
    constant test_image : image_t(0 to number_of_lines-1, 0 to line_length-1) := (
        (1,2,3,4,5,6,7),
        (1,2,3,4,5,6,7),
        (1,2,3,4,5,6,7),
        (1,2,3,4,5,6,7),
        (1,2,3,4,5,6,7)
    );

begin

    line_buffer_inst : component line_buffer
        generic map (
            line_length => line_length,
            addr_width  => addr_width,
            data_width  => data_width
        )
        port map (
            clk            => clk,
            rstn           => rstn,
            data_in        => data_in,
            data_in_valid  => data_in_valid,
            data_out       => data_out,
            data_out_valid => data_out_valid,
            update_val     => update_val,
            update_addr    => update_addr,
            read_offset    => read_offset,
            command        => command
        );

    stimuli : process is
    begin

        rstn          <= '0';
        data_in       <= (others => '0');
        data_in_valid <= '0';

        read_offset <= (others => '0');

        wait for 100 ns;
        rstn          <= '1';
        wait until rising_edge(clk);
        data_in_valid <= '1';

        for y in 0 to number_of_lines - 1 loop

            for x in 0 to line_length - 1 loop

                data_in <= std_logic_vector(to_signed(test_image(y,x), data_width));
                wait until rising_edge(clk);

                if x = 4 then
                    command <= "01";
                elsif x = 5 or x = 6 then
                    command <= "11";
                else
                    command <= "00";
                end if;    

            end loop;

        end loop;

    end process stimuli;

    clkgen : process (clk) is
    begin

        clk <= not clk after 10 ns;

    end process clkgen;

end architecture imp;

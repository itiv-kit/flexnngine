library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity throttle is
    generic (
        counter_width : natural := 8
    );
    port (
        clk                : in    std_logic;
        rstn               : in    std_logic;
        i_throttle_level   : in    unsigned(counter_width - 1 downto 0);
        o_throttled_enable : out   std_logic
    );
end entity throttle;

architecture syn of throttle is

    signal r_counter : unsigned (counter_width downto 0); -- one more bit as delta-sigma output

begin

    -- allow to throttle the output phase
    -- this mechanism is very simple by just pulling o_throttled_enable low
    -- a better solution would be to drive r_command_psum with some idle commands appropriately
    -- we use a delta-sigma modulation approach to achieve fine-grained toggling of o_throttled_enable
    p_output_throttle : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' or i_throttle_level = 0 then
            r_counter <= (others => '0');
        else
            r_counter <= r_counter + i_throttle_level;
        end if;

        o_throttled_enable <= not r_counter(counter_width);

    end process p_output_throttle;

end architecture syn;

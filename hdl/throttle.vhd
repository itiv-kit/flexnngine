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

    constant c_cnt_max : integer := 2 ** counter_width - 1;
    signal   r_counter : integer range 0 to c_cnt_max;

begin

    -- allow to throttle the output phase
    -- this mechanism is very simple by just pulling o_enable low
    -- a better solution would be to drive r_command_psum with some idle commands appropriately
    p_output_throttle : process is
    begin

        wait until rising_edge(clk);

        if rstn = '0' then
            r_counter <= 0;
        else
            if r_counter = 0 then
                r_counter <= c_cnt_max;
            else
                r_counter <= r_counter - 1;
            end if;
        end if;

        if r_counter < to_integer(i_throttle_level) then
            o_throttled_enable <= '0';
        else
            o_throttled_enable <= '1';
        end if;

    end process p_output_throttle;

end architecture syn;

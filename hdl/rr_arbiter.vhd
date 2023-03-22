library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity rr_arbiter is
    generic (
        arbiter_width : positive := 9
    );
    port (
        clk   : in    std_logic;
        rstn  : in    std_logic;
        i_req : in    std_logic_vector(arbiter_width - 1 downto 0);
        o_gnt : out   std_logic_vector(arbiter_width - 1 downto 0)
    );
end entity rr_arbiter;

architecture rtl of rr_arbiter is

    signal w_double_req : std_logic_vector(2 * arbiter_width - 1 downto 0);
    signal w_double_gnt : std_logic_vector(2 * arbiter_width - 1 downto 0);
    signal r_priority   : std_logic_vector(arbiter_width - 1 downto 0);
    signal r_last_gnt   : std_logic_vector(arbiter_width - 1 downto 0);

begin

    w_double_req <= i_req & i_req when or r_last_gnt = '0' else
                    (i_req and not(r_last_gnt)) & (i_req and not(r_last_gnt)); -- remove last_gnt from request list to avoid gnt pulses longer than 2
    w_double_gnt <= w_double_req and not std_logic_vector((unsigned(w_double_req) - unsigned(r_priority)));

    arbiter_pr : process (clk, rstn) is

    begin

        if not rstn then
            r_priority <= std_logic_vector(to_unsigned(1, arbiter_width));
            o_gnt      <= (others => '0');
            r_last_gnt <= (others => '0');
        elsif rising_edge(clk) then
            r_priority(arbiter_width - 1 downto 1) <= r_priority(arbiter_width - 2 downto 0);
            r_priority(0)                          <= r_priority(arbiter_width - 1);
            o_gnt                                  <= w_double_gnt(arbiter_width - 1 downto 0)
                                                      or w_double_gnt(2 * arbiter_width - 1 downto arbiter_width);
            r_last_gnt                             <= o_gnt;
        end if;

    end process arbiter_pr;

end architecture rtl;

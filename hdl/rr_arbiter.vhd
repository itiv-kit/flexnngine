library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity rr_arbiter is
    generic (
        arbiter_width : positive := 9
    );
    port (
        clk  : in    std_logic;
        rstn : in    std_logic;
        req  : in    std_logic_vector(arbiter_width - 1 downto 0);
        gnt  : out   std_logic_vector(arbiter_width - 1 downto 0)
    );
end entity rr_arbiter;

architecture rtl of rr_arbiter is

    signal double_req : std_logic_vector(2 * arbiter_width - 1 downto 0);
    signal double_gnt : std_logic_vector(2 * arbiter_width - 1 downto 0);
    signal priority   : std_logic_vector(arbiter_width - 1 downto 0);
    signal last_gnt   : std_logic_vector(arbiter_width - 1 downto 0);

begin

    double_req <= req & req when or last_gnt = '0' else
                  (req and not(last_gnt)) & (req and not(last_gnt)); -- remove last_gnt from request list to avoid gnt pulses longer than 2
    double_gnt <= double_req and not std_logic_vector((unsigned(double_req) - unsigned(priority)));

    arbiter_pr : process (clk, rstn) is

    begin

        if not rstn then
            priority <= std_logic_vector(to_unsigned(1, arbiter_width));
            gnt      <= (others => '0');
            last_gnt <= (others => '0');
        elsif rising_edge(clk) then
            priority(arbiter_width - 1 downto 1) <= priority(arbiter_width - 2 downto 0);
            priority(0)                          <= priority(arbiter_width - 1);
            gnt                                  <= double_gnt(arbiter_width - 1 downto 0)
                                                    or double_gnt(2 * arbiter_width - 1 downto arbiter_width);
            last_gnt                             <= gnt;
        end if;

    end process arbiter_pr;

end architecture rtl;

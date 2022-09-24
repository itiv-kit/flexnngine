library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std.unsigned;

entity div16_8_8 is
	generic(
		A_WIDTH			: POSITIVE := 17;
		B_WIDTH			: POSITIVE := 8;
		RESULT_WIDTH	: POSITIVE := 9
	);
	port (
		clk        : in  STD_LOGIC;
		en         : in  STD_LOGIC;
		rstn       : in  STD_LOGIC;
		a          : in  STD_LOGIC_VECTOR( A_WIDTH-1 downto 0);
		b          : in  STD_LOGIC_VECTOR( B_WIDTH-1 downto 0);
		result     : out STD_LOGIC_VECTOR( RESULT_WIDTH-1 downto 0)		
	);
end entity div16_8_8;

architecture rtl of div16_8_8 is

    type unsigned_8_array  is array(natural range <>) of UNSIGNED( 7 downto 0);
	type unsigned_16_array is array(natural range <>) of UNSIGNED(15 downto 0);

	signal r_remainder 		: unsigned_16_array(1 to 9);
	signal r_shifted_b 		: unsigned_16_array(1 to 9);
	signal r_result    		: unsigned_8_array (1 to 9);
	signal r_result_signed 	: SIGNED(8 downto 0);
	signal r_sign      		: STD_LOGIC_VECTOR(1 to 9);
	signal r_en		     	: STD_LOGIC_VECTOR(1 to 9);
begin

	process(clk, rstn, en)
		variable v_result 	: UNSIGNED( 8 downto 1);
        variable a_signed 	: SIGNED(16 downto 0);
        variable a_unsigned : UNSIGNED(15 downto 0);
	begin
		if rstn = '0' then
	
	        -- STUDENT CODE HERE
            r_remainder <= (others => (others => '0'));
			r_shifted_b <= (others => (others => '0'));
			r_result <= (others => (others => '0'));
			r_result_signed <= (others => 'X');
			r_sign <= (others => '0');
			r_en <= (others => '0');
			a_signed := (others => '0');
			a_unsigned := (others => '0');

            -- STUDENT CODE until HERE
		elsif rising_edge(clk) then
		
    		-- STUDENT CODE HERE
            a_signed := signed(a);
			if a_signed(16) = '1' then
				a_signed := not(a_signed - "00000000000000001");
				r_sign(1) <= '1';
            else
                r_sign(1) <= '0';
			end if;
			a_unsigned := unsigned(a_signed(15 downto 0));

            r_en(1) <= en;
            r_remainder(1) <= a_unsigned;
            r_result(1) <= "00000000";
            r_shifted_b(1) <= unsigned("0" & b & "0000000");
            
            for i in 1 to 8 loop
                if r_en(i) = '1' then
                    if (r_remainder(i) >= r_shifted_b(i)) then
                        r_remainder(i+1) <= r_remainder(i) - r_shifted_b(i);
                        r_result(i+1) <= unsigned(r_result(i)(6 downto 0) & '1');
                    else
                        r_remainder(i+1) <= r_remainder(i);
                        r_result(i+1) <= unsigned(r_result(i)(6 downto 0) & '0');
                    end if;
                else
                    r_remainder(i+1) <= r_remainder(i);
                    r_result(i+1) <= r_result(i);
                end if;    
                
                r_en(i+1) <= r_en(i);
                r_shifted_b(i+1) <= unsigned('0' & r_shifted_b(i)(15 downto 1));
                r_sign(i+1) <= r_sign(i);
                
			end loop;
			
			if r_en(9) = '1' then
				if r_sign(9) = '1' then 
					r_result_signed <= signed(not('0' & r_result(9)) + "000000001");
				else
					r_result_signed <= signed('0' & r_result(9));
				end if;
			else
				r_result_signed <= (others => 'X');
			end if;
			-- STUDENT CODE until HERE
		end if;
	end process;
	
	result <= STD_LOGIC_VECTOR(r_result_signed);

end architecture rtl;

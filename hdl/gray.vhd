library ieee;
    use ieee.std_logic_1164.all;

package gray_code is

    function to_gray (bin : std_logic_vector) return std_logic_vector;

    function to_binary (gray : std_logic_vector) return std_logic_vector;

end package gray_code;

package body gray_code is

    function to_gray (bin : std_logic_vector) return std_logic_vector is

        variable gray : std_logic_vector(bin'range);

    begin

        gray := bin xor ('0' & bin(bin'high downto 1));

        return gray;

    end function;

    function to_binary (gray : std_logic_vector) return std_logic_vector is

        variable bin : std_logic_vector(gray'range);

    begin

        bin(bin'high) := gray(gray'high);

        for i in gray'high-1 downto 0 loop

            bin(i) := gray(i) xor bin(i + 1);

        end loop;

        return bin;

    end function;

end package body gray_code;

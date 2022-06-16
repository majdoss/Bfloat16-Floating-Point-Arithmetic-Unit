library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LZE_5 is
    port(
        in_a: in std_logic_vector(4 downto 0);
        count: out std_logic_vector(2 downto 0)
    );
end LZE_5;

architecture rtl of LZE_5 is

begin
    process(in_a) is
        begin
            if (in_a(4) = '0') then
                count <= "000";
            elsif(in_a(4 downto 3) = "10") then
                count <= "001";
            elsif(in_a(4 downto 2) = "110") then
                count <= "010";
            elsif(in_a(4 downto 1) = "1110") then
                count <= "011";
            elsif(in_a(4 downto 0) = "11110") then
                count <= "100";
            else
                count <= "000";
            end if;
    end process;

end architecture;
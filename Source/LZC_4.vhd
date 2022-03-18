library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LZC_4 is
    port(
        in_4: in std_logic_vector(3 downto 0);
        count: out std_logic_vector(1 downto 0);
        a: out std_logic -- indicates that all bits are zeros
    );
end LZC_4;

architecture rtl of LZC_4 is

begin
    count(0) <= ((NOT in_4(3)) AND in_4(2)) OR ((NOT in_4(3)) AND (NOT in_4(1)));
    count(1) <= NOT (in_4(3) OR in_4(2));
    a <= '1' when in_4 = "0000" else '0';

end architecture;
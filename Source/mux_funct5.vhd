library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_funct5 is
    port(
        mult_add_sub: in std_logic_vector(15 downto 0) ;
        div: in std_logic_vector(15 downto 0) ;
        funct5: in std_logic_vector(4 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end mux_funct5;

architecture rtl of mux_funct5 is
begin
    with funct5 select
        result <= mult_add_sub when "00000"|"00001"|"00010"|"00101"|"00100",
                  div when "00011",
                  (others => '0') when others;
end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LZC_20_tb is
end LZC_20_tb;

architecture driver of LZC_20_tb is
    component LZC_20 is
        port(
            in_20: in std_logic_vector(19 downto 0);
            count: out std_logic_vector(4 downto 0)
        );
    end component;

signal tb_in_20: std_logic_vector(19 downto 0) := (others => '0') ;
signal tb_count: std_logic_vector(4 downto 0);

begin
    UUT: LZC_20 port map (  in_20 => tb_in_20,
                            count => tb_count);
                                 
    tb_in_20 <= "11101010101000010101" after 20ns,
                "01101100100111101111" after 30ns,
                "00100101001010001100" after 40ns,
                "00011000100010101001" after 50ns,
                "00001110010110001111" after 60ns,
                "00000101010101100111" after 70ns,
                "00000011010000001111" after 80ns,
                "00000001000000010010" after 90ns,
                "00000000101010001110" after 100ns,
                "00000000010101000111" after 110ns,
                "00000000001010001110" after 120ns,
                "00000000000101000111" after 130ns,
                "00000000000010001110" after 140ns,
                "00000000000001001110" after 150ns,
                "00000000000000101110" after 160ns,
                "00000000000000011110" after 170ns,
                "00000000000000001110" after 180ns,
                "00000000000000000110" after 190ns,
                "00000000000000000010" after 200ns,
                "00000000000000000000" after 210ns;


end architecture;

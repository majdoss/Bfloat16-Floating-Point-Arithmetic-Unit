library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity acc_tb is
    generic (G : integer := 3);
end acc_tb;

architecture driver of acc_tb is
    component acc is
        generic (G : integer := 3);
        port(
            clk: in std_logic;
            reset: in std_logic;
            start: in std_logic;
            in_acc: in std_logic_vector(G+15 downto 0) ;
            result: out std_logic_vector(G+15 downto 0)
        );
    end component;

signal tb_clk: std_logic := '0' ;
signal tb_reset: std_logic:= '0' ;
signal tb_start: std_logic:= '0' ;
signal tb_in_acc: std_logic_vector(G+15 downto 0) := (others =>'0') ;
signal tb_result: std_logic_vector(G+15 downto 0);

constant ClockFrequency: integer := 100e6; --100MHz
constant ClockPeriod: time := 1000ms / ClockFrequency;

begin
    UUT: acc port map (  clk => tb_clk,
                               reset => tb_reset,
                               start => tb_start,
                               in_acc => tb_in_acc,
                               result => tb_result);

p1: process
begin
    tb_clk <= '1';
    wait for ClockPeriod/2;  --for 10 ns signal is '0'.
    tb_clk <= '0';
    wait for ClockPeriod/2;  --for next 10 ns signal is '1'.
end process p1;
                                 
    tb_reset <= '1' after 20ns;

    tb_start <= '1' after 90ns, '0' after 100ns;

    
    tb_in_acc <= "0000000000010011010" after 30ns,
                 "0000000000010110111" after 40ns,
                 "0000000011000100000" after 50ns,
                 "0000000001010101010" after 60ns,
                 "0000000000010011010" after 70ns,
                 "0001010001000010000" after 80ns,
                 "0001011010100100000" after 90ns,
                 "0000100111001111110" after 100ns,
                 "0001111111111111111" after 110ns,
                 "0001100000000000001" after 120ns,
                 "0000110001011111000" after 130ns;

end architecture;

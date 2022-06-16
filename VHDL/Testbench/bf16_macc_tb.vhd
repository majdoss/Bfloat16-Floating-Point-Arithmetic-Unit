library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_macc_tb is
    generic (G : integer := 3);
end bf16_macc_tb;

architecture driver of bf16_macc_tb is
    component bf16_macc is
        generic (G : integer := 3);
        port(
            clk: in std_logic;
            reset: in std_logic;
            start: in std_logic;
            in1: in std_logic_vector(15 downto 0) ;
            in2: in std_logic_vector(15 downto 0) ;
            result: out std_logic_vector(15 downto 0)
        );
    end component;

signal tb_clk: std_logic := '0' ;
signal tb_reset: std_logic:= '0' ;
signal tb_start: std_logic:= '0' ;
signal tb_in1: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in2: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_result: std_logic_vector(15 downto 0);

constant ClockFrequency: integer := 100e6; --100MHz
constant ClockPeriod: time := 1000ms / ClockFrequency;

begin
    UUT: bf16_macc port map (  clk => tb_clk,
                               reset => tb_reset,
                               start => tb_start,
                               in1 => tb_in1,
                               in2 => tb_in2,
                               result => tb_result);

p1: process
begin
    tb_clk <= '1';
    wait for ClockPeriod/2;  --for 10 ns signal is '0'.
    tb_clk <= '0';
    wait for ClockPeriod/2;  --for next 10 ns signal is '1'.
end process p1;
                                 
    tb_reset <= '1' after 20ns;

    tb_start <= '1' after 30ns, '0' after 40ns, '1' after 70ns;

    
    tb_in1 <=   "0100010001011000" after 30ns,   --   1.1011000*(2^9)
                "0100010001111000" after 40ns,   --   1.1111000*(2^9)
                "0100010000001000" after 50ns,   --   1.0001000*(2^9)
                "0100010001000001" after 60ns,   --   1.1000001*(2^9)
                "0100010001011000" after 70ns;   --   1.1011000*(2^9)

    tb_in2 <= "0011111110000000";

end architecture;

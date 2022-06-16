library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_SIMD_MACC_4_tb is
    generic (G : integer := 4);
end bf16_SIMD_MACC_4_tb;

architecture driver of bf16_SIMD_MACC_4_tb is
    component bf16_SIMD_MACC_4 is
        generic (G : integer := 4);
        port(
            clk: in std_logic;
            reset: in std_logic;
            in1: in std_logic_vector(15 downto 0) ;
            in2: in std_logic_vector(15 downto 0) ;
            in3: in std_logic_vector(15 downto 0) ;
            in4: in std_logic_vector(15 downto 0) ;
            in5: in std_logic_vector(15 downto 0) ;
            in6: in std_logic_vector(15 downto 0) ;
            in7: in std_logic_vector(15 downto 0) ;
            in8: in std_logic_vector(15 downto 0) ;
            result: out std_logic_vector(15 downto 0)
        );
    end component;

signal tb_clk: std_logic := '0' ;
signal tb_reset: std_logic:= '0' ;
signal tb_in1: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in2: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in3: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in4: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in5: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in6: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in7: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in8: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_result: std_logic_vector(15 downto 0);

constant ClockFrequency: integer := 100e6; --100MHz
constant ClockPeriod: time := 1000ms / ClockFrequency;

begin
    UUT: bf16_SIMD_MACC port map (  clk => tb_clk,
                                    reset => tb_reset,
                                    in1 => tb_in1,
                                    in2 => tb_in2,
                                    in3 => tb_in3,
                                    in4 => tb_in4,
                                    in5 => tb_in5,
                                    in6 => tb_in6,
                                    in7 => tb_in7,
                                    in8 => tb_in8,
                                    result => tb_result);

p1: process
begin
    tb_clk <= '1';
    wait for ClockPeriod/2;  --for 10 ns signal is '0'.
    tb_clk <= '0';
    wait for ClockPeriod/2;  --for next 10 ns signal is '1'.
end process p1;
                                 
    tb_reset <= '1' after 20ns;
    
    tb_in1 <= "0100000001100000" after 30ns; -- 1.1011000*(2^9)
    tb_in2 <= "0100000100010000" after 30ns; -- 1.1011111*(2^9)
    tb_in3 <= "0100000000110000" after 30ns; -- 1.1001000*(2^11)
    tb_in4 <= "0011111110000000" after 30ns; -- 1.1011000*(2^13)
    tb_in5 <= "0011111110000000" after 30ns; -- 1.1000000*(2^9)
    tb_in6 <= "0011111110000000" after 30ns; -- 1.1010000*(2^9)
    tb_in7 <= "0011111110000000" after 30ns; -- 1.1010000*(2^10)
    tb_in8 <= "0011111110000000" after 30ns; -- 1.1011000*(2^9)

end architecture;

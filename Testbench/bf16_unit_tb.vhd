library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_unit_tb is
end bf16_unit_tb;

architecture driver of bf16_unit_tb is
    component bf16_unit
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
        in9: in std_logic_vector(15 downto 0) ;
        in10: in std_logic_vector(15 downto 0) ;
        in11: in std_logic_vector(15 downto 0) ;
        in12: in std_logic_vector(15 downto 0) ;
        in13: in std_logic_vector(15 downto 0) ;
        in14: in std_logic_vector(15 downto 0) ;
        in15: in std_logic_vector(15 downto 0) ;
        in16: in std_logic_vector(15 downto 0) ;
        funct5: in std_logic_vector(4 downto 0) ;
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
signal tb_in9: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in10: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in11: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in12: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in13: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in14: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in15: std_logic_vector(15 downto 0) := (others =>'0') ;
signal tb_in16: std_logic_vector(15 downto 0) := (others =>'0') ;

signal tb_funct5: std_logic_vector(4 downto 0) := "00000";
signal tb_result: std_logic_vector(15 downto 0);

constant ClockFrequency: integer := 100e6; --100MHz
constant ClockPeriod: time := 1000ms / ClockFrequency;

begin
    UUT: bf16_unit port map ( clk => tb_clk,
				                 reset => tb_reset,
				                 in1 => tb_in1,
                        	     in2 => tb_in2,
                                 in3 => tb_in3,
                                 in4 => tb_in4,
                        	     in5 => tb_in5,
                                 in6 => tb_in6,
                                 in7 => tb_in7,
                        	     in8 => tb_in8,
                                 in9 => tb_in9,
                                 in10 => tb_in10,
                        	     in11 => tb_in11,
                                 in12 => tb_in12,
                                 in13 => tb_in13,
                        	     in14 => tb_in14,
                                 in15 => tb_in15,
                                 in16 => tb_in16,
				                 funct5 => tb_funct5,
                             	 result => tb_result );

p1: process
begin
    tb_clk <= '1';
    wait for ClockPeriod/2;  --for 10 ns signal is '0'.
    tb_clk <= '0';
    wait for ClockPeriod/2;  --for next 10 ns signal is '1'.
end process p1;
                                 
    tb_reset <= '1' after 25ns;
    tb_funct5 <= "00111" after 30ns,
                 "00000" after 230ns,
                 "00010" after 430ns,
                 "00011" after 630ns,
                 "00100" after 830ns;
    
    tb_in1 <= "0011110111111000" after 30ns,   --   1.1011000*(2^9)
	          "0001011001001011" after 40ns,   --  -1.1111000*(2^9)
	          "0001010001000010" after 50ns,   --   1.1000010*(2^-87)
	          "0100101001001011" after 60ns,   --   1.1001011*(2^21)
	          "1000000011101000" after 70ns,   --  -1.1101000*(2^-126)
	          "0111111110011000" after 80ns,   --   NaN
	          "1100011001001101" after 90ns,   --  -1.1001101*(2^13)
	          "1000000001001101" after 100ns,   --  -0
	          "0000000000000000" after 110ns,  --   0
	          "1111111110000000" after 120ns,  --  -inf
              "0100000011110011" after 130ns,  --   1.1110011*(2^2)
              "1100000011110011" after 140ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 150ns,  --   1.0101100*(2^7)
              "0100001100001100" after 160ns,  --   1.0001100*(2^7)
              "0100001101101100" after 170ns,  --   1.1101100*(2^7)
              "1011111010000000" after 180ns,  --  -0.25
              "1100000011000000" after 190ns,  --  -6
              "0010101010000111" after 200ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 210ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 220ns,  --  +1.0100000*2^(12) (5632)
              "0100010001011000" after 230ns,  --   1.1011000*(2^9)
	          "1100010001111000" after 240ns,  --  -1.1111000*(2^9)
	          "0001010001000010" after 250ns,  --   1.1000010*(2^-87)
	          "0100101001001011" after 260ns,  --   1.1001011*(2^21)
	          "1000000011101000" after 270ns,  --  -1.1101000*(2^-126)
	          "0111111110011000" after 280ns,  --   NaN
	          "1100011001001101" after 290ns,  --  -1.1001101*(2^13)
	          "1000000001001101" after 300ns,  --  -0
	          "0000000000000000" after 310ns,  --   0
	          "1111111110000000" after 320ns,  --  -inf
              "0100000011110011" after 330ns,  --   1.1110011*(2^2)
              "1100000011110011" after 340ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 350ns,  --   1.0101100*(2^7)
              "0100001100001100" after 360ns,  --   1.0001100*(2^7)
              "0100001101101100" after 370ns,  --   1.1101100*(2^7)
              "1011111010000000" after 380ns,  --  -0.25
              "1100000011000000" after 390ns,  --  -6
              "0010101010000111" after 400ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 410ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 420ns,  --  +1.0100000*2^(12) (5632)
              "0100010001011000" after 430ns,   --   1.1011000*(2^9)
	          "1100010001111000" after 440ns,   --  -1.1111000*(2^9)
	          "0001010001000010" after 450ns,   --   1.1000010*(2^-87)
	          "0100101001001011" after 460ns,   --   1.1001011*(2^21)
	          "1000000011101000" after 470ns,   --  -1.1101000*(2^-126)
	          "0111111110011000" after 480ns,   --   NaN
	          "1100011001001101" after 490ns,   --  -1.1001101*(2^13)
	          "1000000001001101" after 500ns,   --  -0
	          "0000000000000000" after 510ns,  --   0
	          "1111111110000000" after 520ns,  --  -inf
              "0100000011110011" after 530ns,  --   1.1110011*(2^2)
              "1100000011110011" after 540ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 550ns,  --   1.0101100*(2^7)
              "0100001100001100" after 560ns,  --   1.0001100*(2^7)
              "0100001101101100" after 570ns,  --   1.1101100*(2^7)
              "1011111010000000" after 580ns,  --  -0.25
              "1100000011000000" after 590ns,  --  -6
              "0010101010000111" after 600ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 610ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 620ns,  --  +1.0100000*2^(12) (5632)
              "0100010001011000" after 630ns,  --   1.1011000*(2^9)
	          "1100010001111000" after 640ns,  --  -1.1111000*(2^9)
	          "0001010001000010" after 650ns,  --   1.1000010*(2^-87)
	          "0100101001001011" after 660ns,  --   1.1001011*(2^21)
	          "1000000011101000" after 670ns,  --  -1.1101000*(2^-126)
	          "0111111110011000" after 680ns,  --   NaN
	          "1100011001001101" after 690ns,  --  -1.1001101*(2^13)
	          "1000000001001101" after 700ns,  --  -0
	          "0000000000000000" after 710ns,  --   0
	          "1111111110000000" after 720ns,  --  -inf
              "0100000011110011" after 730ns,  --   1.1110011*(2^2)
              "1100000011110011" after 740ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 750ns,  --   1.0101100*(2^7)
              "0100001100001100" after 760ns,  --   1.0001100*(2^7)
              "0100001101101100" after 770ns,  --   1.1101100*(2^7)
              "1011111010000000" after 780ns,  --  -0.25
              "1100000011000000" after 790ns,  --  -6
              "0010101010000111" after 800ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 810ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 820ns,  --  +1.0100000*2^(12) (5632)
              "0100010001011000" after 830ns,   --   1.1011000*(2^9)
	          "1100010001111000" after 840ns,   --  -1.1111000*(2^9)
	          "0001010001000010" after 850ns,   --   1.1000010*(2^-87)
	          "0100101001001011" after 860ns,   --   1.1001011*(2^21)
	          "1000000011101000" after 870ns,   --  -1.1101000*(2^-126)
	          "0111111110011000" after 880ns,   --   NaN
	          "1100011001001101" after 890ns,   --  -1.1001101*(2^13)
	          "1000000001001101" after 900ns,   --  -0
	          "0000000000000000" after 910ns,  --   0
	          "1111111110000000" after 920ns,  --  -inf
              "0100000011110011" after 930ns,  --   1.1110011*(2^2)
              "1100000011110011" after 940ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 950ns,  --   1.0101100*(2^7)
              "0100001100001100" after 960ns,  --   1.0001100*(2^7)
              "0100001101101100" after 970ns,  --   1.1101100*(2^7)
              "1011111010000000" after 980ns,  --  -0.25
              "1100000011000000" after 990ns,  --  -6
              "0010101010000111" after 1000ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 1010ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 1020ns,  --  +1.0100000*2^(12) (5632)
              "0100010001011000" after 1030ns,  --   1.1011000*(2^9)
	          "1100010001111000" after 1040ns,  --  -1.1111000*(2^9)
	          "0001010001000010" after 1050ns,  --   1.1000010*(2^-87)
	          "0100101001001011" after 1060ns,  --   1.1001011*(2^21)
	          "1000000011101000" after 1070ns,  --  -1.1101000*(2^-126)
	          "0111111110011000" after 1080ns,  --   NaN
	          "1100011001001101" after 1090ns,  --  -1.1001101*(2^13)
	          "1000000001001101" after 1100ns,  --  -0
	          "0000000000000000" after 1110ns,  --   0
	          "1111111110000000" after 1120ns,  --  -inf
              "0100000011110011" after 1130ns,  --   1.1110011*(2^2)
              "1100000011110011" after 1140ns,  --  -1.1110011*(2^2)
              "0100001100101100" after 1150ns,  --   1.0101100*(2^7)
              "0100001100001100" after 1160ns,  --   1.0001100*(2^7)
              "0100001101101100" after 1170ns,  --   1.1101100*(2^7)
              "1011111010000000" after 1180ns,  --  -0.25
              "1100000011000000" after 1190ns,  --  -6
              "0010101010000111" after 1200ns,  --  +1.0000111*2^(-42)
              "0010101010000111" after 1210ns,  --  +1.0000111*2^(-42)
              "0100010110100000" after 1220ns;  --  +1.0100000*2^(12) (5632)
	      
    tb_in2 <= "0011110101010101" after 30ns,   --  -1.1111000*(2^9)
	          "0001011001001011" after 40ns,   --   1.1011000*(2^9)
              "0001011001001011" after 50ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 60ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 70ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 80ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 90ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 100ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 110ns,  --   0
	          "0100000011110011" after 120ns,  --   1.1110011*(2^2)
              "0100000011110011" after 130ns,  --   1.1110011*(2^2)
              "0100000011110011" after 140ns,  --   1.1110011*(2^2)
              "1100010111101010" after 150ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 160ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 170ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 180ns,  --   6
              "1100000111001000" after 190ns,  --   -25
              "0110101010100111" after 200ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 210ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 220ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 230ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 240ns,  --   1.1011000*(2^9)
              "0001011001001011" after 250ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 260ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 270ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 280ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 290ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 300ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 310ns,  --   0
	          "0100000011110011" after 320ns,  --   1.1110011*(2^2)
              "0100000011110011" after 330ns,  --   1.1110011*(2^2)
              "0100000011110011" after 340ns,  --   1.1110011*(2^2)
              "1100010111101010" after 350ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 360ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 370ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 380ns,  --   6
              "1100000111001000" after 390ns,  --   -25
              "0110101010100111" after 400ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 410ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 420ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 430ns,   --  -1.1111000*(2^9)
	          "0100010001011000" after 440ns,   --   1.1011000*(2^9)
              "0001011001001011" after 450ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 460ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 470ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 480ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 490ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 500ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 510ns,  --   0
	          "0100000011110011" after 520ns,  --   1.1110011*(2^2)
              "0100000011110011" after 530ns,  --   1.1110011*(2^2)
              "0100000011110011" after 540ns,  --   1.1110011*(2^2)
              "1100010111101010" after 550ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 560ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 570ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 580ns,  --   6
              "1100000111001000" after 590ns,  --   -25
              "0110101010100111" after 600ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 610ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 620ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 630ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 640ns,  --   1.1011000*(2^9)
              "0001011001001011" after 650ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 660ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 670ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 680ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 690ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 700ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 710ns,  --   0
	          "0100000011110011" after 720ns,  --   1.1110011*(2^2)
              "0100000011110011" after 730ns,  --   1.1110011*(2^2)
              "0100000011110011" after 740ns,  --   1.1110011*(2^2)
              "1100010111101010" after 750ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 760ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 770ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 780ns,  --   6
              "1100000111001000" after 790ns,  --   -25
              "0110101010100111" after 800ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 810ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 820ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 830ns,   --  -1.1111000*(2^9)
	          "0100010001011000" after 840ns,   --   1.1011000*(2^9)
              "0001011001001011" after 850ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 860ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 870ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 880ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 890ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 900ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 910ns,  --   0
	          "0100000011110011" after 920ns,  --   1.1110011*(2^2)
              "0100000011110011" after 930ns,  --   1.1110011*(2^2)
              "0100000011110011" after 940ns,  --   1.1110011*(2^2)
              "1100010111101010" after 950ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 960ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 970ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 980ns,  --   6
              "1100000111001000" after 990ns,  --   -25
              "0110101010100111" after 1000ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 1010ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 1020ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 1030ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 1040ns,  --   1.1011000*(2^9)
              "0001011001001011" after 1050ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 1060ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 1070ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 1080ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 1090ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 1100ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 1110ns,  --   0
	          "0100000011110011" after 1120ns,  --   1.1110011*(2^2)
              "0100000011110011" after 1130ns,  --   1.1110011*(2^2)
              "0100000011110011" after 1140ns,  --   1.1110011*(2^2)
              "1100010111101010" after 1150ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 1160ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 1170ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 1180ns,  --   6
              "1100000111001000" after 1190ns,  --   -25
              "0110101010100111" after 1200ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 1210ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 1220ns;  --  +1.0100000*2^(4) (20)

    tb_in3 <= "0011110111111100" after 30ns,   --  -1.1111000*(2^9)
	          "0001011001001011" after 40ns,   --   1.1011000*(2^9)
              "0001011001001011" after 50ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 60ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 70ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 80ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 90ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 100ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 110ns,  --   0
	          "0100000011110011" after 120ns,  --   1.1110011*(2^2)
              "0100000011110011" after 130ns,  --   1.1110011*(2^2)
              "0100000011110011" after 140ns,  --   1.1110011*(2^2)
              "1100010111101010" after 150ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 160ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 170ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 180ns,  --   6
              "1100000111001000" after 190ns,  --   -25
              "0110101010100111" after 200ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 210ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 220ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 230ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 240ns,  --   1.1011000*(2^9)
              "0001011001001011" after 250ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 260ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 270ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 280ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 290ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 300ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 310ns,  --   0
	          "0100000011110011" after 320ns,  --   1.1110011*(2^2)
              "0100000011110011" after 330ns,  --   1.1110011*(2^2)
              "0100000011110011" after 340ns,  --   1.1110011*(2^2)
              "1100010111101010" after 350ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 360ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 370ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 380ns,  --   6
              "1100000111001000" after 390ns,  --   -25
              "0110101010100111" after 400ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 410ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 420ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 430ns,   --  -1.1111000*(2^9)
	          "0100010001011000" after 440ns,   --   1.1011000*(2^9)
              "0001011001001011" after 450ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 460ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 470ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 480ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 490ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 500ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 510ns,  --   0
	          "0100000011110011" after 520ns,  --   1.1110011*(2^2)
              "0100000011110011" after 530ns,  --   1.1110011*(2^2)
              "0100000011110011" after 540ns,  --   1.1110011*(2^2)
              "1100010111101010" after 550ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 560ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 570ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 580ns,  --   6
              "1100000111001000" after 590ns,  --   -25
              "0110101010100111" after 600ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 610ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 620ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 630ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 640ns,  --   1.1011000*(2^9)
              "0001011001001011" after 650ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 660ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 670ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 680ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 690ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 700ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 710ns,  --   0
	          "0100000011110011" after 720ns,  --   1.1110011*(2^2)
              "0100000011110011" after 730ns,  --   1.1110011*(2^2)
              "0100000011110011" after 740ns,  --   1.1110011*(2^2)
              "1100010111101010" after 750ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 760ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 770ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 780ns,  --   6
              "1100000111001000" after 790ns,  --   -25
              "0110101010100111" after 800ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 810ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 820ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 830ns,   --  -1.1111000*(2^9)
	          "0100010001011000" after 840ns,   --   1.1011000*(2^9)
              "0001011001001011" after 850ns,   --   1.1001011*(2^-83)
              "0000001001101000" after 860ns,   --   1.1101000*(2^-123)
              "0000001001101000" after 870ns,   --   1.1101000*(2^-123)
              "1000100101001000" after 880ns,   --   1.1001000*(2^-109)
	          "1100011110011000" after 890ns,   --  -1.0011000*(2^16)
	          "1000000100001010" after 900ns,   --  -1.0001010*(2^-125)
	          "0000000000011100" after 910ns,  --   0
	          "0100000011110011" after 920ns,  --   1.1110011*(2^2)
              "0100000011110011" after 930ns,  --   1.1110011*(2^2)
              "0100000011110011" after 940ns,  --   1.1110011*(2^2)
              "1100010111101010" after 950ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 960ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 970ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 980ns,  --   6
              "1100000111001000" after 990ns,  --   -25
              "0110101010100111" after 1000ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 1010ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 1020ns,  --  +1.0100000*2^(4) (20)
              "1100010001111000" after 1030ns,  --  -1.1111000*(2^9)
	          "0100010001011000" after 1040ns,  --   1.1011000*(2^9)
              "0001011001001011" after 1050ns,  --   1.1001011*(2^-83)
              "0000001001101000" after 1060ns,  --   1.1101000*(2^-123)
              "0000001001101000" after 1070ns,  --   1.1101000*(2^-123)
              "1000100101001000" after 1080ns,  --   1.1001000*(2^-109)
	          "1100011110011000" after 1090ns,  --  -1.0011000*(2^16)
	          "1000000100001010" after 1100ns,  --  -1.0001010*(2^-125)
	          "0000000000011100" after 1110ns,  --   0
	          "0100000011110011" after 1120ns,  --   1.1110011*(2^2)
              "0100000011110011" after 1130ns,  --   1.1110011*(2^2)
              "0100000011110011" after 1140ns,  --   1.1110011*(2^2)
              "1100010111101010" after 1150ns,  --  -1.1101010*(2^12)
              "1100001101101010" after 1160ns,  --  -1.1101010*(2^7)
              "1100001101101010" after 1170ns,  --  -1.1101010*(2^7)
              "0100000011000000" after 1180ns,  --   6
              "1100000111001000" after 1190ns,  --   -25
              "0110101010100111" after 1200ns,  --  +1.0100111*2^(86)
              "0100010000100011" after 1210ns,  --  +1.0100011*2^(9)
              "0100000110100000" after 1220ns;  --  +1.0100000*2^(4) (20)

              tb_in4 <= "0011111101011010" after 30ns, -- 1.1011000*(2^13)
              "0000000000000000" after 40ns; -- 1.1011000*(2^13)
          
              tb_in5 <= "0011111100011001" after 30ns, -- 1.1000000*(2^9)
              "0000000000000000" after 40ns; -- 1.1000000*(2^9)
          
              tb_in6 <= "0011111010101000" after 30ns, -- 1.1010000*(2^9)
              "0000000000000000" after 40ns; -- 1.1010000*(2^9)
          
              tb_in7 <= "0000000000000000" after 30ns, -- 1.1010000*(2^10)
               "0000000000000000" after 40ns; -- 1.1010000*(2^10)
          
              tb_in8 <= "0000000000000000" after 30ns, -- 1.1011000*(2^9)
              "0000000000000000" after 40ns; -- 1.1011000*(2^9)
          
              tb_in9 <= "0000000000000000" after 30ns, -- 1.1011000*(2^9)
              "0000000000000000" after 40ns; -- 1.1011000*(2^9)
          
              tb_in10 <= "0000000000000000" after 30ns, -- 1.1011111*(2^9)
               "0000000000000000" after 40ns; -- 1.1011111*(2^9)
          
              tb_in11 <= "0000000000000000" after 30ns, -- 1.1001000*(2^11)
              "0000000000000000" after 40ns; -- 1.1001000*(2^11)
          
              tb_in12 <= "0000000000000000" after 30ns, -- 1.1011000*(2^13)
               "0000000000000000" after 40ns; -- 1.1011000*(2^13)
          
              tb_in13 <= "0000000000000000" after 30ns, -- 1.1000000*(2^9)
               "0000000000000000" after 40ns; -- 1.1000000*(2^9)
          
              tb_in14 <= "0000000000000000" after 30ns, -- 1.1010000*(2^9)
              "0000000000000000" after 40ns; -- 1.1010000*(2^9)
          
              tb_in15 <= "0000000000000000" after 30ns, -- 1.1010000*(2^10)
               "0000000000000000" after 40ns; -- 1.1010000*(2^10)
          
              tb_in16 <= "0000000000000000" after 30ns, -- 1.1011000*(2^9)
               "0000000000000000" after 40ns; -- 1.1011000*(2^9)

end architecture;



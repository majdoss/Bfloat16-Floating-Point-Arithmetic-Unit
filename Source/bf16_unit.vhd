library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_unit is
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
end bf16_unit;

architecture rtl of bf16_unit is

    component bf16_fmadd_fmsub
        port(
            clk: in std_logic;
            reset: in std_logic;
            in1: in std_logic_vector(15 downto 0) ;
            in2: in std_logic_vector(15 downto 0) ;
            in3: in std_logic_vector(15 downto 0) ;
            funct5: in std_logic_vector(4 downto 0) ;
            result: out std_logic_vector(15 downto 0)
        );
    end component;
    
    component decoder
        port(
            in1: in std_logic_vector(15 downto 0);
            in2: in std_logic_vector(15 downto 0);
            in3: in std_logic_vector(15 downto 0);
            funct5: in std_logic_vector(4 downto 0);
            out1: out std_logic_vector(15 downto 0);
            out2: out std_logic_vector(15 downto 0);
            out3: out std_logic_vector(15 downto 0)
        );
    end component;

    component bf16_SIMD_MACC is
        generic (G : integer := 5);
        port(
            clk: in std_logic;
            reset: in std_logic;
            -- in bf16 format
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
            result: out std_logic_vector(15 downto 0)
        );
    end component;

    component bf16_div
        port(
            clk: in std_logic;
            reset: in std_logic;
            in1: in std_logic_vector(15 downto 0) ;
            in2: in std_logic_vector(15 downto 0) ;
            result: out std_logic_vector(15 downto 0)
        );
    end component;

    component mux_funct5
        port(
            mult_add_sub: in std_logic_vector(15 downto 0) ;
            div: in std_logic_vector(15 downto 0) ;
            macc: in std_logic_vector(15 downto 0) ;
            funct5: in std_logic_vector(4 downto 0) ;
            result: out std_logic_vector(15 downto 0)
        );
    end component;

    -- We have to save the value of funct5 in pipeline registers
    signal p1_funct5: std_logic_vector(4 downto 0) ;
    signal p2_funct5: std_logic_vector(4 downto 0) ;
    signal p3_funct5: std_logic_vector(4 downto 0) ;
    signal p4_funct5: std_logic_vector(4 downto 0) ;
    signal p5_funct5: std_logic_vector(4 downto 0) ;
    signal p6_funct5: std_logic_vector(4 downto 0) ;
    signal p7_funct5: std_logic_vector(4 downto 0) ;
    signal p8_funct5: std_logic_vector(4 downto 0) ;
    signal p9_funct5: std_logic_vector(4 downto 0) ;
    signal p10_funct5: std_logic_vector(4 downto 0) ;
    signal p11_funct5: std_logic_vector(4 downto 0) ;

    -- Connect output of each circuit to multiplexer
    signal mux_mult_add_sub: std_logic_vector(15 downto 0) ;
    signal mux_div: std_logic_vector(15 downto 0) ;
    signal mux_macc: std_logic_vector(15 downto 0) ;
    
    signal s_in1: std_logic_vector(15 downto 0) ;
    signal s_in2: std_logic_vector(15 downto 0) ;
    signal s_in3: std_logic_vector(15 downto 0) ;

begin
    bf16_SIMD: bf16_SIMD_MACC port map (    clk => clk,
                                            reset => reset,
                                            in1 => in1,
                                            in2 => in2,
                                            in3 => in3,
                                            in4 => in4,
                                            in5 => in5,
                                            in6 => in6,
                                            in7 => in7,
                                            in8 => in8,
                                            in9 => in9,
                                            in10 => in10,
                                            in11 => in11,
                                            in12 => in12,
                                            in13 => in13,
                                            in14 => in14,
                                            in15 => in15,
                                            in16 => in16,
                                            result => mux_macc );
                                            
    dec: decoder port map (    in1 => in1,
                               in2 => in2,
                               in3 => in3,
                               funct5 => funct5,
                               out1 => s_in1,
                               out2 => s_in2,
                               out3 => s_in3 );

    fmadd_fmsub: bf16_fmadd_fmsub port map (   clk => clk,
                                               reset => reset,
                                               in1 => s_in1,
                                               in2 => s_in2,
                                               in3 => s_in3,
                                               funct5 => funct5,
                                               result => mux_mult_add_sub );

    div: bf16_div port map (    clk => clk,
				                reset => reset,
				                in1 => in1,
                        	    in2 => in2,
                             	result => mux_div );

    mux: mux_funct5 port map (   mult_add_sub => mux_mult_add_sub,
                                 div => mux_div,
                                 macc => mux_macc,
                                 funct5 => p11_funct5,
                                 result => result );

    p_reg: process (clk, reset) is
        begin
            if (reset = '0') then
                p1_funct5 <= (others => '0');
                p2_funct5 <= (others => '0');
                p3_funct5 <= (others => '0');
                p4_funct5 <= (others => '0');
                p5_funct5 <= (others => '0');
                p6_funct5 <= (others => '0');
                p7_funct5 <= (others => '0');
                p8_funct5 <= (others => '0');
                p9_funct5 <= (others => '0');
                p10_funct5 <= (others => '0');
                p11_funct5 <= (others => '0');
            elsif rising_edge(clk) then
                p1_funct5 <= funct5;
                p2_funct5 <= p1_funct5;
                p3_funct5 <= p2_funct5;
                p4_funct5 <= p3_funct5;
                p5_funct5 <= p4_funct5;
                p6_funct5 <= p5_funct5;
                p7_funct5 <= p6_funct5;
                p8_funct5 <= p7_funct5;
                p9_funct5 <= p8_funct5;
                p10_funct5 <= p9_funct5;
                p11_funct5 <= p10_funct5;
            end if;
    end process p_reg;
end architecture;
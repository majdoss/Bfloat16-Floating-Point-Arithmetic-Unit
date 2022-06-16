library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_SIMD_MACC is
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
end bf16_SIMD_MACC;

architecture MACC_SIMD of bf16_SIMD_MACC is
    component bf16_add_branch is
        generic (G : integer := 5);
        port(
            clk: in std_logic;
            reset: in std_logic;
    
            -- in1 parameters
            in1: in std_logic_vector(G+15 downto 0) ;
            exp_1: integer;
            s_in1: in std_logic;
            exc_flag_1: in std_logic;
            err_code_1: in std_logic;
    
            -- in2 parameters
            in2: in std_logic_vector(G+15 downto 0) ;
            exp_2: integer;
            s_in2: in std_logic;
            exc_flag_2: in std_logic;
            err_code_2: in std_logic;
    
            -- result parameters
            out_alu_r: out std_logic_vector(G+15 downto 0);
            out_exp_r: out integer;
            out_s_r: out std_logic;
            out_exc_flag: out std_logic;
            out_err_code: out std_logic
        );
    end component;

    component bf16_mult_leaf is
        generic (G : integer := 5);
        port(
            clk: in std_logic;
            reset: in std_logic;
            in1: in std_logic_vector(15 downto 0) ; -- in bf16 format
            in2: in std_logic_vector(15 downto 0) ; -- in bf16 format
            out_alu_m: out std_logic_vector(G+15 downto 0) ; -- mult result
            out_exp_m: out integer ; -- mult result exponent
            out_s_m: out std_logic; -- mult result sign 
            out_exc_flag: out std_logic; -- exception flag
            out_err_code: out std_logic -- indicates if NaN or Infinity
        );
    end component;

    component bf16_add_root is
        generic (G : integer := 5);
        port(
            clk: in std_logic;
            reset: in std_logic;
    
            -- in1 parameters
            in1: in std_logic_vector(G+15 downto 0) ;
            exp_1: integer;
            s_in1: in std_logic;
            exc_flag_1: in std_logic;
            err_code_1: in std_logic;
    
            -- in2 parameters
            in2: in std_logic_vector(G+15 downto 0) ;
            exp_2: integer;
            s_in2: in std_logic;
            exc_flag_2: in std_logic;
            err_code_2: in std_logic;
    
            -- final result in bf16 format
            result: out std_logic_vector(15 downto 0)
        );
    end component;
    
    signal m1_alu_m: std_logic_vector(G+15 downto 0);
    signal m1_exp_m: integer;
    signal m1_s_m: std_logic;
    signal m1_exc_flag: std_logic;
    signal m1_err_code: std_logic;

    signal m2_alu_m: std_logic_vector(G+15 downto 0);
    signal m2_exp_m: integer;
    signal m2_s_m: std_logic;
    signal m2_exc_flag: std_logic;
    signal m2_err_code: std_logic;

    signal m3_alu_m: std_logic_vector(G+15 downto 0);
    signal m3_exp_m: integer;
    signal m3_s_m: std_logic;
    signal m3_exc_flag: std_logic;
    signal m3_err_code: std_logic;

    signal m4_alu_m: std_logic_vector(G+15 downto 0);
    signal m4_exp_m: integer;
    signal m4_s_m: std_logic;
    signal m4_exc_flag: std_logic;
    signal m4_err_code: std_logic;

    signal m5_alu_m: std_logic_vector(G+15 downto 0);
    signal m5_exp_m: integer;
    signal m5_s_m: std_logic;
    signal m5_exc_flag: std_logic;
    signal m5_err_code: std_logic;

    signal m6_alu_m: std_logic_vector(G+15 downto 0);
    signal m6_exp_m: integer;
    signal m6_s_m: std_logic;
    signal m6_exc_flag: std_logic;
    signal m6_err_code: std_logic;

    signal m7_alu_m: std_logic_vector(G+15 downto 0);
    signal m7_exp_m: integer;
    signal m7_s_m: std_logic;
    signal m7_exc_flag: std_logic;
    signal m7_err_code: std_logic;

    signal m8_alu_m: std_logic_vector(G+15 downto 0);
    signal m8_exp_m: integer;
    signal m8_s_m: std_logic;
    signal m8_exc_flag: std_logic;
    signal m8_err_code: std_logic;

    signal a1_alu_r: std_logic_vector(G+15 downto 0);
    signal a1_exp_r: integer;
    signal a1_s_r: std_logic;
    signal a1_exc_flag: std_logic;
    signal a1_err_code: std_logic;

    signal a2_alu_r: std_logic_vector(G+15 downto 0);
    signal a2_exp_r: integer;
    signal a2_s_r: std_logic;
    signal a2_exc_flag: std_logic;
    signal a2_err_code: std_logic;

    signal a3_alu_r: std_logic_vector(G+15 downto 0);
    signal a3_exp_r: integer;
    signal a3_s_r: std_logic;
    signal a3_exc_flag: std_logic;
    signal a3_err_code: std_logic;

    signal a4_alu_r: std_logic_vector(G+15 downto 0);
    signal a4_exp_r: integer;
    signal a4_s_r: std_logic;
    signal a4_exc_flag: std_logic;
    signal a4_err_code: std_logic;

    signal a5_alu_r: std_logic_vector(G+15 downto 0);
    signal a5_exp_r: integer;
    signal a5_s_r: std_logic;
    signal a5_exc_flag: std_logic;
    signal a5_err_code: std_logic;

    signal a6_alu_r: std_logic_vector(G+15 downto 0);
    signal a6_exp_r: integer;
    signal a6_s_r: std_logic;
    signal a6_exc_flag: std_logic;
    signal a6_err_code: std_logic;

begin
    MULT1: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in1, 
                                    in2 => in2,
                                    out_alu_m => m1_alu_m,
                                    out_exp_m => m1_exp_m,
                                    out_s_m => m1_s_m, 
                                    out_exc_flag => m1_exc_flag,
                                    out_err_code => m1_err_code );
    
    MULT2: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in3, 
                                    in2 => in4,
                                    out_alu_m => m2_alu_m,
                                    out_exp_m => m2_exp_m,
                                    out_s_m => m2_s_m, 
                                    out_exc_flag => m2_exc_flag,
                                    out_err_code => m2_err_code );

    MULT3: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in5, 
                                    in2 => in6,
                                    out_alu_m => m3_alu_m,
                                    out_exp_m => m3_exp_m,
                                    out_s_m => m3_s_m, 
                                    out_exc_flag => m3_exc_flag,
                                    out_err_code => m3_err_code );

    MULT4: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in7, 
                                    in2 => in8,
                                    out_alu_m => m4_alu_m,
                                    out_exp_m => m4_exp_m,
                                    out_s_m => m4_s_m, 
                                    out_exc_flag => m4_exc_flag,
                                    out_err_code => m4_err_code );

    MULT5: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in9, 
                                    in2 => in10,
                                    out_alu_m => m5_alu_m,
                                    out_exp_m => m5_exp_m,
                                    out_s_m => m5_s_m, 
                                    out_exc_flag => m5_exc_flag,
                                    out_err_code => m5_err_code );

    MULT6: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in11, 
                                    in2 => in12,
                                    out_alu_m => m6_alu_m,
                                    out_exp_m => m6_exp_m,
                                    out_s_m => m6_s_m, 
                                    out_exc_flag => m6_exc_flag,
                                    out_err_code => m6_err_code );

    MULT7: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in13, 
                                    in2 => in14,
                                    out_alu_m => m7_alu_m,
                                    out_exp_m => m7_exp_m,
                                    out_s_m => m7_s_m, 
                                    out_exc_flag => m7_exc_flag,
                                    out_err_code => m7_err_code );

    MULT8: bf16_mult_leaf port map (clk => clk, 
                                    reset => reset, 
                                    in1 => in15, 
                                    in2 => in16,
                                    out_alu_m => m8_alu_m,
                                    out_exp_m => m8_exp_m,
                                    out_s_m => m8_s_m, 
                                    out_exc_flag => m8_exc_flag,
                                    out_err_code => m8_err_code );

    ADD1: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => m1_alu_m, 
                                    exp_1 => m1_exp_m,
                                    s_in1 => m1_s_m,
                                    exc_flag_1 => m1_exc_flag,
                                    err_code_1 => m1_err_code,
                                    in2 => m2_alu_m, 
                                    exp_2 => m2_exp_m,
                                    s_in2 => m2_s_m,
                                    exc_flag_2 => m2_exc_flag,
                                    err_code_2 => m2_err_code,
                                    out_alu_r => a1_alu_r,
                                    out_exp_r => a1_exp_r,
                                    out_s_r => a1_s_r,
                                    out_exc_flag => a1_exc_flag,
                                    out_err_code => a1_err_code );

    ADD2: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => m3_alu_m, 
                                    exp_1 => m3_exp_m,
                                    s_in1 => m3_s_m,
                                    exc_flag_1 => m3_exc_flag,
                                    err_code_1 => m3_err_code,
                                    in2 => m4_alu_m, 
                                    exp_2 => m4_exp_m,
                                    s_in2 => m4_s_m,
                                    exc_flag_2 => m4_exc_flag,
                                    err_code_2 => m4_err_code,
                                    out_alu_r => a2_alu_r,
                                    out_exp_r => a2_exp_r,
                                    out_s_r => a2_s_r,
                                    out_exc_flag => a2_exc_flag,
                                    out_err_code => a2_err_code );

    ADD3: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => m5_alu_m, 
                                    exp_1 => m5_exp_m,
                                    s_in1 => m5_s_m,
                                    exc_flag_1 => m5_exc_flag,
                                    err_code_1 => m5_err_code,
                                    in2 => m6_alu_m, 
                                    exp_2 => m6_exp_m,
                                    s_in2 => m6_s_m,
                                    exc_flag_2 => m6_exc_flag,
                                    err_code_2 => m6_err_code,
                                    out_alu_r => a3_alu_r,
                                    out_exp_r => a3_exp_r,
                                    out_s_r => a3_s_r,
                                    out_exc_flag => a3_exc_flag,
                                    out_err_code => a3_err_code );

    ADD4: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => m7_alu_m, 
                                    exp_1 => m7_exp_m,
                                    s_in1 => m7_s_m,
                                    exc_flag_1 => m7_exc_flag,
                                    err_code_1 => m7_err_code,
                                    in2 => m8_alu_m, 
                                    exp_2 => m8_exp_m,
                                    s_in2 => m8_s_m,
                                    exc_flag_2 => m8_exc_flag,
                                    err_code_2 => m8_err_code,
                                    out_alu_r => a4_alu_r,
                                    out_exp_r => a4_exp_r,
                                    out_s_r => a4_s_r,
                                    out_exc_flag => a4_exc_flag,
                                    out_err_code => a4_err_code );

    ADD5: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => a1_alu_r, 
                                    exp_1 => a1_exp_r,
                                    s_in1 => a1_s_r,
                                    exc_flag_1 => a1_exc_flag,
                                    err_code_1 => a1_err_code,
                                    in2 => a2_alu_r, 
                                    exp_2 => a2_exp_r,
                                    s_in2 => a2_s_r,
                                    exc_flag_2 => a2_exc_flag,
                                    err_code_2 => a2_err_code,
                                    out_alu_r => a5_alu_r,
                                    out_exp_r => a5_exp_r,
                                    out_s_r => a5_s_r,
                                    out_exc_flag => a5_exc_flag,
                                    out_err_code => a5_err_code );

    ADD6: bf16_add_branch port map (clk => clk, 
                                    reset => reset,
                                    in1 => a3_alu_r, 
                                    exp_1 => a3_exp_r,
                                    s_in1 => a3_s_r,
                                    exc_flag_1 => a3_exc_flag,
                                    err_code_1 => a3_err_code,
                                    in2 => a4_alu_r, 
                                    exp_2 => a4_exp_r,
                                    s_in2 => a4_s_r,
                                    exc_flag_2 => a4_exc_flag,
                                    err_code_2 => a4_err_code,
                                    out_alu_r => a6_alu_r,
                                    out_exp_r => a6_exp_r,
                                    out_s_r => a6_s_r,
                                    out_exc_flag => a6_exc_flag,
                                    out_err_code => a6_err_code );

    ADD7: bf16_add_root port map (  clk => clk, 
                                    reset => reset,
                                    in1 => a5_alu_r, 
                                    exp_1 => a5_exp_r,
                                    s_in1 => a5_s_r,
                                    exc_flag_1 => a5_exc_flag,
                                    err_code_1 => a5_err_code,
                                    in2 => a6_alu_r, 
                                    exp_2 => a6_exp_r,
                                    s_in2 => a6_s_r,
                                    exc_flag_2 => a6_exc_flag,
                                    err_code_2 => a6_err_code,
                                    result => result );

end architecture;   

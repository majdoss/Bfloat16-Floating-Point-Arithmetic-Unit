library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_add_branch is
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
end bf16_add_branch;

architecture rtl of bf16_add_branch is
    -- p1 register
    signal p1_reg_alu_in2: std_logic_vector(G+15 downto 0) ;
    signal p1_reg_alu_in2_shifted: std_logic_vector(G+15 downto 0) ;
    signal p1_reg_alu_in1: std_logic_vector(G+15 downto 0) ;
    signal p1_reg_alu_in1_shifted: std_logic_vector(G+15 downto 0) ;
    signal p1_reg_exp_1: integer;
    signal p1_reg_exp_2: integer;
    signal p1_reg_s_in2: std_logic;
    signal p1_reg_s_in1: std_logic;
    signal p1_reg_exc_flag: std_logic;
    signal p1_reg_err_code: std_logic;

    -- p2 register
    signal p2_reg_exp_r: integer;
    signal p2_reg_exc_flag: std_logic;
    signal p2_reg_err_code: std_logic;
    signal p2_reg_alu_in1: std_logic_vector(G+15 downto 0) ;
    signal p2_reg_alu_in2: std_logic_vector(G+15 downto 0) ;

    -- STAGE 1
    signal alu_in1: std_logic_vector(G+15 downto 0) ;
    signal alu_in1_shifted: std_logic_vector(G+15 downto 0) ;
    signal alu_in2: std_logic_vector(G+15 downto 0) ;
    signal alu_in2_shifted: std_logic_vector(G+15 downto 0) ;

    signal exc_flag: std_logic;
    signal err_code: std_logic;
    signal guard: std_logic_vector(G-1 downto 0) ;

    -- STAGE 2
    signal exp_r: integer;
begin
    guard <= (others => '0');

    -- STAGE 1
    process (exc_flag_1, exc_flag_2, err_code_1, err_code_2) is
        -- check exception
        begin
            if (exc_flag_1 = '1' or exc_flag_2 = '1') then
                exc_flag <= '1';
                err_code <= err_code_1 or err_code_2 ;
            else
                exc_flag <= '0';
                err_code <= '0';
            end if;
    end process;

    process (exp_1, exp_2, in1, in2) is
        variable exp_s1: integer range 0 to 255; 
        variable exp_s2: integer range 0 to 255;
        -- these are used to store the "shift value" in case we need to shift mantissas for allignment
        begin
            if ((exp_1 - exp_2) < 0) then
                exp_s1 := -(exp_1 - exp_2);
            else
                exp_s1 := exp_1 - exp_2;
            end if;

            if ((exp_2 - exp_1) < 0) then
                exp_s2 := -(exp_2 - exp_1);
            else
                exp_s2 := exp_2 - exp_1;
            end if;

            -- Prepare operands
            alu_in1 <= in1;
            -- Used for Mantissa allignment in case needed
            alu_in1_shifted <= std_logic_vector(shift_right(signed(in1), exp_s2));

            alu_in2 <= in2;
            alu_in2_shifted <= std_logic_vector(shift_right(signed(in2), exp_s1));
    end process;

    -- STAGE 2
    process(clk, reset, p1_reg_exp_1, p1_reg_exp_2, p1_reg_s_in1, p1_reg_s_in2) is
        variable v_alu_in1: std_logic_vector(G+15 downto 0) ;
        variable v_alu_in2: std_logic_vector(G+15 downto 0) ;
        begin
            v_alu_in1 := p1_reg_alu_in1;
            v_alu_in2 := p1_reg_alu_in2;
            
            if (p1_reg_exp_2 >= p1_reg_exp_1) then
                -- Mantissa allignment
                v_alu_in1 := p1_reg_alu_in1_shifted;
                -- Choose correct exponent as result
                exp_r <= p1_reg_exp_2;
            else
                v_alu_in2 := p1_reg_alu_in2_shifted;
                exp_r <= p1_reg_exp_1;
            end if;

            -- Express both operands in two's complement 
            if p1_reg_s_in1 = '1' then
                v_alu_in1 := std_logic_vector(-signed(v_alu_in1));
            else
                v_alu_in1 := std_logic_vector(signed(v_alu_in1));
            end if;

            if p1_reg_s_in2 = '1' then
                v_alu_in2 := std_logic_vector(-signed(v_alu_in2));
            else
                v_alu_in2 := std_logic_vector(signed(v_alu_in2));
            end if;

            if (reset = '0') then
                p2_reg_alu_in1 <= (others => '0');
                p2_reg_alu_in2 <= (others => '0');
            elsif (rising_edge(clk)) then
                p2_reg_alu_in1 <= v_alu_in1;
                p2_reg_alu_in2 <= v_alu_in2;
            end if;
    end process;

    -- STAGE 3
    process(clk, reset, p2_reg_alu_in2, p2_reg_alu_in1, p2_reg_exp_r) is
        variable alu_r: std_logic_vector(G+15 downto 0) ;
        variable s_r: std_logic;  -- result sign
        variable v_exp: integer;
        begin
            v_exp := p2_reg_exp_r;
            alu_r := std_logic_vector(signed(p2_reg_alu_in2) + signed(p2_reg_alu_in1));

            -- Set result sign bit and express result as a magnitude
            s_r := '0';
            if ((signed(alu_r)) < 0) then
                s_r := '1';
                alu_r := std_logic_vector(-signed(alu_r));
            end if;
            
            if (reset = '0') then
                out_alu_r <= (others => '0');
                out_s_r <= '0';
            elsif (rising_edge(clk)) then
                out_alu_r <= alu_r;
                out_s_r <= s_r;
            end if;
    end process;

    process (clk, reset, exp_1, exp_2, alu_in1, alu_in2, s_in1, s_in2, exc_flag, err_code, exp_r) is
        begin
            if (reset = '0') then
                -- STAGE 1
                p1_reg_alu_in2 <= (others => '0');
                p1_reg_alu_in2_shifted <= (others => '0');
                p1_reg_alu_in1 <= (others => '0');
                p1_reg_alu_in1_shifted <= (others => '0');
                p1_reg_exp_1 <= 0;
                p1_reg_exp_2 <= 0;
                p1_reg_s_in2 <= '0';
                p1_reg_s_in1 <= '0';
                p1_reg_exc_flag <= '1';
                p1_reg_err_code <= '0';
                -- STAGE 2
                p2_reg_exp_r <= 0;
                p2_reg_exc_flag <= '1';
                p2_reg_err_code <= '0';
                -- STAGE 3
                out_exp_r <= 0;
                out_exc_flag <= '1';
                out_err_code <= '0';
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_alu_in2 <= alu_in2;
                p1_reg_alu_in2_shifted <= alu_in2_shifted;
                p1_reg_alu_in1 <= alu_in1;
                p1_reg_alu_in1_shifted <= alu_in1_shifted;
                p1_reg_exp_1 <= exp_1;
                p1_reg_exp_2 <= exp_2;
                p1_reg_s_in2 <= s_in2;
                p1_reg_s_in1 <= s_in1;
                p1_reg_exc_flag <= exc_flag;
                p1_reg_err_code <= err_code;
                -- STAGE 2
                p2_reg_exp_r <= exp_r;
                p2_reg_exc_flag <= p1_reg_exc_flag;
                p2_reg_err_code <= p1_reg_err_code;
                -- STAGE 3
                out_exp_r <= p2_reg_exp_r;
                out_exc_flag <= p2_reg_exc_flag;
                out_err_code <= p2_reg_err_code;
            end if;
    end process;
end architecture;   
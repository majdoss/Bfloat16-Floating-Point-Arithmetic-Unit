library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_mult is
    port(
        clk: in std_logic;
        reset: in std_logic;
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_mult;

architecture rtl of bf16_mult is
    -- p1 register
    signal p1_in_exp_rm: integer range 0 to 511 ; 
    signal p1_in_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_in_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_in_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p1_in_s_rm: std_logic;
    signal p1_in_exc_flag_mult: std_logic;

    signal p1_out_exp_rm: integer range 0 to 511 ;
    signal p1_out_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_out_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_out_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p1_out_s_rm: std_logic;
    signal p1_out_exc_flag_mult: std_logic;

    -- p2 register
    signal p2_in_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_in_exp_rm: integer range 0 to 511 ;
    signal p2_in_s_rm: std_logic;
    signal p2_in_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p2_in_exc_flag_mult: std_logic;

    signal p2_out_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_out_exp_rm: integer range 0 to 511 ;
    signal p2_out_s_rm: std_logic;
    signal p2_out_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p2_out_exc_flag_mult: std_logic;
begin
    p_reg: process (clk, reset) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_out_exp_rm <= 0;
                p1_out_alu_in1<= (others => '0');
                p1_out_alu_in2<= (others => '0');
                p1_out_exc_result_mult <= (others => '0');
                p1_out_s_rm <= '0';
                p1_out_exc_flag_mult <= '1';
                -- p2 register
                p2_out_alu_rm <= (others => '0');
                p2_out_exp_rm <= 0;
                p2_out_s_rm <= '0';
                p2_out_exc_result_mult <= (others => '0');
                p2_out_exc_flag_mult <= '1';
            elsif rising_edge(clk) then
                -- p1 register
                p1_out_exp_rm <= p1_in_exp_rm;
                p1_out_alu_in1 <= p1_in_alu_in1;
                p1_out_alu_in2 <= p1_in_alu_in2;
                p1_out_exc_result_mult <= p1_in_exc_result_mult;
                p1_out_s_rm <= p1_in_s_rm;
                p1_out_exc_flag_mult <= p1_in_exc_flag_mult;
                -- p2 register
                p2_out_alu_rm <= p2_in_alu_rm;
                p2_out_exp_rm <= p2_in_exp_rm;
                p2_out_s_rm <= p2_in_s_rm;
                p2_out_exc_result_mult <= p2_in_exc_result_mult;
                p2_out_exc_flag_mult <= p2_in_exc_flag_mult;
            end if;
    end process p_reg;

    stage_1: process(in1, in2) is
        variable exp_1: integer range 0 to 255 ;
        variable exp_2: integer range 0 to 255 ; 
        variable alu_in1: std_logic_vector(7 downto 0) ;
        variable alu_in2: std_logic_vector(7 downto 0) ;
        variable s_rm: std_logic ;  -- multiplication result sign
        variable exp_rm: integer range 0 to 511 ; 
        variable exc_flag_mult: std_logic;
        variable exc_result_mult: std_logic_vector(15 downto 0) ;
        begin
        
            exp_1 := to_integer(unsigned(in1(14 downto 7)));
            exp_2 := to_integer(unsigned(in2(14 downto 7)));

            -- Handle exceptions: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero
            exc_flag_mult:= '1';
            -- handle zeros and denorms
            if ((exp_1 = 0) or (exp_2 = 0)) then
                exc_result_mult := (others => '0');
            
            -- handle NaN and infinity
            elsif ((exp_1 = 255) or (exp_2 = 255)) then
                if (((in1(6 downto 0)) /= "0000000") and (exp_1 = 255)) then
                    exc_result_mult := in1;
                elsif (((in2(6 downto 0)) /= "0000000") and (exp_2 = 255)) then
                    exc_result_mult := in2;
                else
                    if (exp_1 = 255) then
                        exc_result_mult := in1;
                    else
                        exc_result_mult := in2;
                    end if;
                end if;
            
            -- handle normal
            else
                exc_flag_mult:= '0';
                -- Prepare operands
                alu_in1 := '1' & in1(6 downto 0);
                alu_in2 := '1' & in2(6 downto 0);

                exp_rm := exp_1 + exp_2;
                
                -- adjust multiplication result sign
                s_rm := in1(15) xor in2(15);
                exc_flag_mult:= '1';
                -- detect overflow/underflow
                -- We are working with bias notation and not actual exponent
                if ((exp_rm > 381) and (s_rm = '0')) then
                    exc_result_mult := "0111111110000000"; -- +inf
                elsif ((exp_rm > 381) and (s_rm = '1')) then
                    exc_result_mult := "1111111110000000"; -- -inf
                elsif (exp_rm < (128)) then
                    exc_result_mult := "0000000000000000"; -- zero
                else
                    exc_flag_mult:= '0';
                end if;
            end if;

            p1_in_exp_rm <= exp_rm;
            p1_in_alu_in1<= alu_in1;
            p1_in_alu_in2<= alu_in2;
            p1_in_exc_result_mult <= exc_result_mult;
            p1_in_s_rm <= s_rm;
            p1_in_exc_flag_mult <= exc_flag_mult;
    end process stage_1;
    
    stage_2: process(p1_out_exp_rm, p1_out_alu_in1, p1_out_alu_in2, p1_out_exc_result_mult, p1_out_s_rm, p1_out_exc_flag_mult) is
        variable alu_rm: std_logic_vector(15 downto 0);
        begin
            -- multiply the mantissas
            alu_rm := std_logic_vector(unsigned(p1_out_alu_in1) * unsigned(p1_out_alu_in2));

            p2_in_alu_rm <= alu_rm;
            p2_in_exp_rm <= p1_out_exp_rm;
            p2_in_s_rm <= p1_out_s_rm;
            p2_in_exc_result_mult <= p1_out_exc_result_mult;
            p2_in_exc_flag_mult <= p1_out_exc_flag_mult;
    end process stage_2;

    stage_3: process(p2_out_alu_rm, p2_out_exp_rm, p2_out_s_rm, p2_out_exc_result_mult, p2_out_exc_flag_mult) is
        variable p2_exp_rm: integer range 0 to 511 ; 
        variable p2_alu_rm: std_logic_vector (15 downto 0);
        variable p2_s_rm: std_logic;
        variable flag: std_logic;
        variable exception: std_logic_vector (15 downto 0);
        begin
            p2_exp_rm := p2_out_exp_rm;
            p2_alu_rm := p2_out_alu_rm;
            p2_s_rm := p2_out_s_rm;
            exception := p2_out_exc_result_mult;
            flag := p2_out_exc_flag_mult;

            if (p2_alu_rm(15) = '1') then
                -- Adjust exponent
                p2_exp_rm := p2_exp_rm + 1;
            else
                -- Perform correct allignment
                p2_alu_rm := std_logic_vector(shift_left(unsigned(p2_alu_rm), 1));
            end if;

            -- round to the nearest even
            if (p2_alu_rm(7) = '1') then
                p2_alu_rm(14 downto 8) := std_logic_vector(unsigned(p2_alu_rm(14 downto 8))+1);
                -- Adjust exponent
                if (p2_alu_rm(14 downto 8) = "0000000") then
                    p2_exp_rm := p2_exp_rm + 1;
                end if;
            end if;

            -- check again for overflow/underflow
            if (flag = '0') then
                if ((p2_exp_rm > 381) and (p2_s_rm = '0')) then
                    exception := "0111111110000000"; -- +inf
                    flag := '1';
                elsif ((p2_exp_rm > 381) and (p2_s_rm = '1')) then
                    exception := "1111111110000000"; -- -inf
                    flag := '1';
                elsif (p2_exp_rm < (128)) then
                    exception := "0000000000000000"; -- zero
                    flag := '1';
                end if;
            end if;

            -- Generate final result in bfloat 16 format
            if (flag = '1') then
                result <= exception;
            else
                result(15) <= p2_s_rm;
                result(14 downto 7) <= std_logic_vector(to_unsigned(p2_exp_rm - 127,8));
                result(6 downto 0) <= p2_alu_rm(14 downto 8);
            end if;
    end process stage_3;
end architecture;   


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_fmadd_fmsub is
    port(
        clk: in std_logic;
        reset: in std_logic;
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        in3: in std_logic_vector(15 downto 0) ;
        funct5: in std_logic_vector(4 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_fmadd_fmsub;

architecture rtl of bf16_fmadd_fmsub is
    -- p1 register
    signal p1_in_in3: std_logic_vector(15 downto 0) ;
    signal p1_in_funct5: std_logic_vector(4 downto 0) ;
    signal p1_in_exp_rm: integer range 0 to 510 ; 
    signal p1_in_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_in_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_in_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p1_in_s_rm: std_logic;
    signal p1_in_exc_flag_mult: std_logic;

    signal p1_out_in3: std_logic_vector(15 downto 0) ;
    signal p1_out_funct5: std_logic_vector(4 downto 0) ;
    signal p1_out_exp_rm: integer range 0 to 510 ;
    signal p1_out_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_out_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_out_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p1_out_s_rm: std_logic;
    signal p1_out_exc_flag_mult: std_logic;

    -- p2 register
    signal p2_in_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_in_exp_rm: integer range 0 to 510 ;
    signal p2_in_s_rm: std_logic;
    signal p2_in_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p2_in_in3: std_logic_vector(15 downto 0) ;
    signal p2_in_funct5: std_logic_vector(4 downto 0) ;
    signal p2_in_exc_flag_mult: std_logic;

    signal p2_out_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_out_exp_rm: integer range 0 to 510 ;
    signal p2_out_s_rm: std_logic;
    signal p2_out_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p2_out_in3: std_logic_vector(15 downto 0) ;
    signal p2_out_funct5: std_logic_vector(4 downto 0) ;
    signal p2_out_exc_flag_mult: std_logic;

    -- p3 register
    signal p3_in_in3: std_logic_vector(15 downto 0) ;
    signal p3_in_funct5: std_logic_vector(4 downto 0) ;
    signal p3_in_result_mult: std_logic_vector(15 downto 0) ;

    signal p3_out_in3: std_logic_vector(15 downto 0) ;
    signal p3_out_funct5: std_logic_vector(4 downto 0) ;
    signal p3_out_result_mult: std_logic_vector(15 downto 0) ;

    -- p4 register
    signal p4_in_alu_m: std_logic_vector(9 downto 0) ;
    signal p4_in_alu_in3: std_logic_vector(9 downto 0) ;
    signal p4_in_exc_res: std_logic_vector(15 downto 0) ;
    signal p4_in_exc_flag: std_logic ;
    signal p4_in_funct5: std_logic_vector(4 downto 0) ;
    signal p4_in_exp_r: integer range 0 to 255 ;

    signal p4_out_alu_m: std_logic_vector(9 downto 0) ;
    signal p4_out_alu_in3: std_logic_vector(9 downto 0) ;
    signal p4_out_exc_res: std_logic_vector(15 downto 0) ;
    signal p4_out_exc_flag: std_logic ;
    signal p4_out_funct5: std_logic_vector(4 downto 0) ;
    signal p4_out_exp_r: integer range 0 to 255 ;

    -- p5 register
    signal p5_in_exp_r: integer range 0 to 255 ;
    signal p5_in_alu_r: std_logic_vector(9 downto 0) ;
    signal p5_in_exc_res: std_logic_vector(15 downto 0) ;
    signal p5_in_exc_flag: std_logic ;
    signal p5_in_s_r: std_logic ;

    signal p5_out_exp_r: integer range 0 to 255 ;
    signal p5_out_alu_r: std_logic_vector(9 downto 0) ;
    signal p5_out_exc_res: std_logic_vector(15 downto 0) ;
    signal p5_out_exc_flag: std_logic ;
    signal p5_out_s_r: std_logic ;
begin
    p_reg: process (clk, reset) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_out_in3 <= (others => '0');
                p1_out_funct5 <= (others => '0');
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
                p2_out_in3 <= (others => '0');
                p2_out_funct5 <= (others => '0');
                p2_out_exc_flag_mult <= '1';
                -- p3 register
                p3_out_in3 <= (others => '0');
                p3_out_funct5 <= (others => '0');
                p3_out_result_mult <= (others => '0');
                -- p4 register
                p4_out_alu_m <= (others => '0');
                p4_out_alu_in3 <= (others => '0');
                p4_out_exc_res <= (others => '0');
                p4_out_exc_flag <= '1';
                p4_out_funct5 <= (others => '0');
                p4_out_exp_r <= 0;
                -- p5 register
                p5_out_exp_r <= 0;
                p5_out_alu_r <= (others => '0');
                p5_out_exc_res <= (others => '0');
                p5_out_exc_flag <= '1';
                p5_out_s_r <= '0';
            elsif rising_edge(clk) then
                -- p1 register
                p1_out_in3 <= p1_in_in3;
                p1_out_funct5 <= p1_in_funct5;
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
                p2_out_in3 <= p2_in_in3;
                p2_out_funct5 <= p2_in_funct5;
                p2_out_exc_flag_mult <= p2_in_exc_flag_mult;
                -- p3 register
                p3_out_in3 <= p3_in_in3;
                p3_out_funct5 <= p3_in_funct5 ;
                p3_out_result_mult <= p3_in_result_mult;
                -- p4 register
                p4_out_alu_m <= p4_in_alu_m;
                p4_out_alu_in3 <= p4_in_alu_in3;
                p4_out_exc_res <= p4_in_exc_res;
                p4_out_exc_flag <= p4_in_exc_flag;
                p4_out_funct5 <= p4_in_funct5;
                p4_out_exp_r <= p4_in_exp_r;
                -- p5 register
                p5_out_exp_r <= p5_in_exp_r;
                p5_out_alu_r <= p5_in_alu_r;
                p5_out_exc_res <= p5_in_exc_res;
                p5_out_exc_flag <= p5_in_exc_flag;
                p5_out_s_r <= p5_in_s_r;
            end if;
    end process p_reg;

    stage_1: process(in1, in2, in3, funct5) is
        variable exp_1: integer range 0 to 255 ;
        variable exp_2: integer range 0 to 255 ; 
        variable alu_in1: std_logic_vector(7 downto 0) ;
        variable alu_in2: std_logic_vector(7 downto 0) ;
        variable s_rm: std_logic ;  -- multiplication result sign
        variable exp_rm: integer range 0 to 510 ; 
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

            p1_in_in3 <= in3;
            p1_in_funct5 <= funct5;
            p1_in_exp_rm <= exp_rm;
            p1_in_alu_in1<= alu_in1;
            p1_in_alu_in2<= alu_in2;
            p1_in_exc_result_mult <= exc_result_mult;
            p1_in_s_rm <= s_rm;
            p1_in_exc_flag_mult <= exc_flag_mult;
    end process stage_1;
    
    stage_2: process(p1_out_in3, p1_out_funct5, p1_out_exp_rm, p1_out_alu_in1, p1_out_alu_in2, p1_out_exc_result_mult, p1_out_s_rm, p1_out_exc_flag_mult) is
        variable alu_rm: std_logic_vector(15 downto 0);
        begin
            -- multiply the mantissas
            alu_rm := std_logic_vector(unsigned(p1_out_alu_in1) * unsigned(p1_out_alu_in2));

            p2_in_alu_rm <= alu_rm;
            p2_in_exp_rm <= p1_out_exp_rm;
            p2_in_s_rm <= p1_out_s_rm;
            p2_in_exc_result_mult <= p1_out_exc_result_mult;
            p2_in_in3 <= p1_out_in3;
            p2_in_funct5 <= p1_out_funct5;
            p2_in_exc_flag_mult <= p1_out_exc_flag_mult;
    end process stage_2;

    stage_3: process(p2_out_alu_rm, p2_out_exp_rm, p2_out_s_rm, p2_out_exc_result_mult, p2_out_in3, p2_out_funct5, p2_out_exc_flag_mult) is
        variable p2_exp_rm: integer range 0 to 510 ; 
        variable p2_alu_rm: std_logic_vector (15 downto 0);
        variable result: std_logic_vector (15 downto 0);
        begin
            p2_exp_rm := p2_out_exp_rm;
            p2_alu_rm := p2_out_alu_rm;
            if (p2_alu_rm(15) = '1') then
                -- Adjust exponent
                p2_exp_rm := p2_exp_rm + 1;
            else
                -- Perform correct allignment
                p2_alu_rm := std_logic_vector(shift_left(unsigned(p2_alu_rm), 1));
            end if;

            -- Generate final result in bfloat 16 format
            if (p2_out_exc_flag_mult = '1') then
                result := p2_out_exc_result_mult;
            else
                result(15):= p2_out_s_rm;
                result(14 downto 7):= std_logic_vector(to_unsigned(p2_exp_rm - 127,8));
                result(6 downto 0):= p2_alu_rm(14 downto 8);
            end if;

            p3_in_in3 <= p2_out_in3;
            p3_in_funct5 <= p2_out_funct5;
            p3_in_result_mult <= result;
    end process stage_3;

    stage_4: process(p3_out_in3, p3_out_funct5, p3_out_result_mult) is
        variable exp_m: integer range 0 to 255 ; -- exponent
        variable exp_3: integer range 0 to 255 ;
        variable alu_m: std_logic_vector(9 downto 0) ;
        variable alu_in3: std_logic_vector(9 downto 0) ;
        -- 10 bits used as operand: 
        -- 1 sign bit, 1 guard bit, 1 implied one, 7 from significand
        variable exp_r: integer range 0 to 255; -- exponent
        variable exc_res: std_logic_vector(15 downto 0); -- result of exception
        variable exc_flag: std_logic ; -- exception flag

        begin
            -- We do not need to work with actual exponent. We use bias notation.
            exp_m := to_integer(unsigned(p3_out_result_mult(14 downto 7)));
            exp_3 := to_integer(unsigned(p3_out_in3(14 downto 7)));

            -- Prepare operands
            alu_m := "001" & p3_out_result_mult(6 downto 0);
            alu_in3 := "001" & p3_out_in3(6 downto 0);

            -- Handle exceptions: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero
            exc_flag := '1';
            -- handle zeros and denorms
            if ((exp_m = 0) and (exp_3 /= 0)) then
                if (p3_out_funct5(1 downto 0) = "01") then
                    exc_res := not(p3_out_in3(15)) & p3_out_in3(14 downto 0);
                else
                    exc_res := p3_out_in3;
                end if;
            elsif ((exp_3 = 0) and (exp_m /= 0)) then
                if (p3_out_funct5(1 downto 0) = "01") then
                    exc_res := not(p3_out_result_mult(15)) & p3_out_result_mult(14 downto 0);
                else
                    exc_res := p3_out_result_mult;
                end if;
            elsif ((exp_3 = 0) and (exp_m = 0)) then
                exc_res := (others => '0');
            
            -- handle cancellation (result = 0)
            elsif ((p3_out_result_mult(14 downto 0) = p3_out_in3(14 downto 0)) and (p3_out_result_mult(15) /= p3_out_in3(15)) and (p3_out_funct5(1 downto 0) = "00")) then
                exc_res := (others => '0');
            elsif ((p3_out_result_mult(14 downto 0) = p3_out_in3(14 downto 0)) and (p3_out_result_mult(15) = p3_out_in3(15)) and (p3_out_funct5(1 downto 0) = "01")) then
                exc_res := (others => '0');
        
            -- handle NaN and infinity
            elsif ((exp_m = 255) or (exp_3 = 255)) then
                if (((p3_out_result_mult(6 downto 0)) /= "0000000") and (exp_m = 255)) then
                    exc_res := p3_out_result_mult;
                elsif (((p3_out_in3(6 downto 0)) /= "0000000") and (exp_3 = 255)) then
                    exc_res := p3_out_in3;
                else
                    if (exp_m = 255) then
                        exc_res := p3_out_result_mult;
                    else
                        exc_res := p3_out_in3;
                    end if;
                end if;
            else
                exc_flag := '0'; -- no exception
            end if;

            if (exp_m >= exp_3) then
                -- Mantissa allignment
                alu_in3 := std_logic_vector(shift_right(unsigned(alu_in3),(exp_m-exp_3)));
                exp_r := exp_m;
            else
                alu_m := std_logic_vector(shift_right(unsigned(alu_m),(exp_3-exp_m)));
                exp_r := exp_3;
            end if;
            
            -- Express both operands in two's complement 
            if p3_out_result_mult(15) = '1' then
                alu_m := std_logic_vector(-signed(alu_m));
            else
                alu_m := std_logic_vector(signed(alu_m));
            end if;

            if p3_out_in3(15) = '1' then
                alu_in3 := std_logic_vector(-signed(alu_in3));
            else
                alu_in3 := std_logic_vector(signed(alu_in3));
            end if;

            -- assign the final value of each variable to these signals
            -- they need to be preserved since we are using pipeling
            p4_in_alu_m <= alu_m;
            p4_in_alu_in3 <= alu_in3;
            p4_in_exc_res <= exc_res;
            p4_in_exc_flag <= exc_flag;
            p4_in_funct5 <= p3_out_funct5;
            p4_in_exp_r <= exp_r;
    end process stage_4;

    stage_5: process(p4_out_alu_m, p4_out_alu_in3, p4_out_exc_res, p4_out_exc_flag, p4_out_funct5, p4_out_exp_r) is
        variable alu_r: std_logic_vector(9 downto 0) ;
        variable s_r: std_logic;  -- result sign
        begin
            case p4_out_funct5 is 
                when "00100"|"00000" => -- add
                    alu_r := std_logic_vector(signed(p4_out_alu_m) + signed(p4_out_alu_in3));
                when "00101"|"00001" => -- sub
                    alu_r := std_logic_vector(signed(p4_out_alu_m) - signed(p4_out_alu_in3));
                when others =>
                    alu_r := (others => '0');
            end case;

            -- Set result sign bit and express result as a magnitude
            s_r := '0';
            if ((signed(alu_r)) < 0) then
                s_r := '1';
                alu_r := std_logic_vector(-signed(alu_r));
            end if;

            p5_in_exp_r <= p4_out_exp_r;
            p5_in_exc_res <= p4_out_exc_res;
            p5_in_exc_flag <= p4_out_exc_flag;
            p5_in_alu_r <= alu_r;
            p5_in_s_r <= s_r;
    end process stage_5;

    stage_6: process (p5_out_exp_r, p5_out_alu_r, p5_out_exc_res, p5_out_exc_flag, p5_out_s_r) is
        variable p5_alu_r: std_logic_vector(9 downto 0) ;
        variable p5_exp_r: integer range -7 to 255 ;
        begin
            -- Normalize mantissa and adjust exponent
            p5_alu_r := p5_out_alu_r;
            p5_exp_r := p5_out_exp_r;

            if (p5_alu_r(8) = '1') then
                -- overflow
                p5_exp_r := p5_exp_r + 1;
                p5_alu_r := std_logic_vector(shift_right(unsigned(p5_alu_r), 1));
            elsif (p5_alu_r(7) = '1') then
                -- do not shift
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 0));
            elsif (p5_alu_r(6) = '1') then
                p5_exp_r := p5_exp_r - 1;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 1));
            elsif (p5_alu_r(5) = '1') then
                p5_exp_r := p5_exp_r - 2;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 2));
            elsif (p5_alu_r(4) = '1') then
                p5_exp_r := p5_exp_r - 3;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 3));
            elsif (p5_alu_r(3) = '1') then
                p5_exp_r := p5_exp_r - 4;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 4));
            elsif (p5_alu_r(2) = '1') then
                p5_exp_r := p5_exp_r - 5;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 5));
            elsif (p5_alu_r(1) = '1') then
                p5_exp_r := p5_exp_r - 6;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 6));
            elsif (p5_alu_r(0) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 7));
            end if;
            
            -- Generate final result in bfloat 16 format
            if (p5_out_exc_flag = '1') then
                result <= p5_out_exc_res;
            elsif ((p5_exp_r = 255) and (p5_out_s_r = '0')) then
                result <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p5_exp_r = 255) and (p5_out_s_r = '1')) then
                result <= "1111111110000000"; -- overflow, result = -inf
            elsif (p5_exp_r < (-126)) then
                result <= "0000000000000000"; -- underflow, result = zero
            else
                result(15) <= p5_out_s_r;
                result(14 downto 7) <= std_logic_vector(to_unsigned(p5_exp_r,8));
                result(6 downto 0) <= p5_alu_r(6 downto 0);
            end if;
    end process stage_6;
end architecture;



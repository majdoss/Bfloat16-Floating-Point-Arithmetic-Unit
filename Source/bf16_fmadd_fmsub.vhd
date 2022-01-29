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
    signal p1_reg_in3: std_logic_vector(15 downto 0) ;
    signal p1_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p1_reg_exp_rm: integer range 0 to 511 ;
    signal p1_reg_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_reg_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_reg_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p1_reg_s_rm: std_logic;
    signal p1_reg_exc_flag_mult: std_logic;

    -- p2 register
    signal p2_reg_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_reg_exp_rm: integer range 0 to 511 ;
    signal p2_reg_s_rm: std_logic;
    signal p2_reg_exc_result_mult: std_logic_vector(15 downto 0) ;
    signal p2_reg_in3: std_logic_vector(15 downto 0) ;
    signal p2_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p2_reg_exc_flag_mult: std_logic;

    -- p3 register
    signal p3_reg_in3: std_logic_vector(15 downto 0) ;
    signal p3_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p3_reg_result_mult: std_logic_vector(15 downto 0) ;

    -- p4 register
    signal p4_reg_alu_m: std_logic_vector(9 downto 0) ;
    signal p4_reg_alu_in3: std_logic_vector(9 downto 0) ;
    signal p4_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p4_reg_exc_flag: std_logic ;
    signal p4_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p4_reg_exp_r: integer range 0 to 255 ;

    -- p5 register
    signal p5_reg_exp_r: integer range 0 to 255 ;
    signal p5_reg_alu_r: std_logic_vector(9 downto 0) ;
    signal p5_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p5_reg_exc_flag: std_logic ;
    signal p5_reg_s_r: std_logic ;
    
    -- p6 register
    signal p6_reg_result: std_logic_vector(15 downto 0) ;

    -- STAGE 1
    signal alu_rm: std_logic_vector(15 downto 0);
    signal exp_1: integer range 0 to 255 ;
    signal exp_2: integer range 0 to 255 ;
    signal alu_in1: std_logic_vector(7 downto 0) ;
    signal alu_in2: std_logic_vector(7 downto 0) ; 
    signal s_rm: std_logic ;  -- multiplication result sign
    -- STAGE 3 
    signal result_mult: std_logic_vector(15 downto 0);  -- multiplication result in bf16 format
    -- STAGE 4 
    signal exp_m: integer range 0 to 255 ; -- exponent
    signal exp_3: integer range 0 to 255 ;
    signal exp_r: integer range 0 to 255;
    signal alu_m: std_logic_vector(9 downto 0) ;
    signal alu_in3: std_logic_vector(9 downto 0) ;
    -- 10 bits used as operand: 
    -- 1 sign bit, 1 guard bit, 1 implied one, 7 from significand
    signal alu_m_shifted: std_logic_vector(9 downto 0) ;
    signal alu_in3_shifted: std_logic_vector(9 downto 0) ;
    signal s_m: std_logic;
    signal s_in3: std_logic;
    -- STAGE 6
    signal result_s6: std_logic_vector(15 downto 0) ;
begin
    process (clk, exp_1, exp_2, in3, funct5, alu_in1, alu_in2, s_rm, exp_r) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_exp_rm <= 0;
                p1_reg_in3 <= (others => '0');
                p1_reg_funct5 <= (others => '0');
                p1_reg_alu_in1<= (others => '0');
                p1_reg_alu_in2<= (others => '0');
                p1_reg_s_rm <= '0';
                -- p2 register
                p2_reg_alu_rm <= (others => '0');
                p2_reg_exp_rm <= 0;
                p2_reg_s_rm <= '0';
                p2_reg_exc_result_mult <= (others => '0');
                p2_reg_in3 <= (others => '0');
                p2_reg_funct5 <= (others => '0');
                p2_reg_exc_flag_mult <= '1';
                -- p3 register
                p3_reg_in3 <= (others => '0');
                p3_reg_funct5 <= (others => '0');
                p3_reg_result_mult <= (others => '0');
                -- p4 register
                p4_reg_funct5 <= (others => '0');
                p4_reg_exp_r <= 0;
                -- p5 register
                p5_reg_exp_r <= 0;
                p5_reg_exc_res <= (others => '0');
                p5_reg_exc_flag <= '1';
                p6_reg_result <=  (others => '0');
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_exp_rm <= exp_1 + exp_2; -- prepare multiplication result exponent
                p1_reg_in3 <= in3;
                p1_reg_funct5 <= funct5;
                p1_reg_alu_in1<= alu_in1;
                p1_reg_alu_in2<= alu_in2;
                p1_reg_s_rm <= s_rm;
                -- STAGE 2
                p2_reg_alu_rm <= std_logic_vector(unsigned(p1_reg_alu_in1) * unsigned(p1_reg_alu_in2)); -- multiply operands
                p2_reg_exp_rm <= p1_reg_exp_rm;
                p2_reg_s_rm <= p1_reg_s_rm;
                p2_reg_exc_result_mult <= p1_reg_exc_result_mult;
                p2_reg_in3 <= p1_reg_in3;
                p2_reg_funct5 <= p1_reg_funct5;
                p2_reg_exc_flag_mult <= p1_reg_exc_flag_mult;
                -- STAGE 3
                p3_reg_in3 <= p2_reg_in3;
                p3_reg_funct5 <= p2_reg_funct5;
                p3_reg_result_mult <= result_mult;
                -- STAGE 4
                p4_reg_funct5 <= p3_reg_funct5;
                p4_reg_exp_r <= exp_r;
                -- STAGE 5
                p5_reg_exp_r <= p4_reg_exp_r;
                p5_reg_exc_res <= p4_reg_exc_res;
                p5_reg_exc_flag <= p4_reg_exc_flag;
                -- STAGE 6
                p6_reg_result <= result_s6;
            end if;
    end process;

    -- STAGE 1
    process (in1, in2) is
        begin
            -- Prepare exponents
            -- We do not need to work with actual exponent. We use bias notation.
            exp_1 <= to_integer(unsigned(in1(14 downto 7)));
            exp_2 <= to_integer(unsigned(in2(14 downto 7)));
            -- Prepare operands
            alu_in1 <= '1' & in1(6 downto 0);
            alu_in2 <= '1' & in2(6 downto 0);
            -- adjust multiplication result sign
            s_rm <= in1(15) xor in2(15);
    end process;

    -- STAGE 1
    process(clk, reset, in1, in2, exp_1, exp_2) is
        variable exc_flag_mult: std_logic;
        variable exc_result_mult: std_logic_vector(15 downto 0) ;
        begin
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
            -- no exception
            else
                exc_flag_mult:= '0';
            end if;

            if (reset = '0') then
                p1_reg_exc_flag_mult <= '1';
                p1_reg_exc_result_mult <= (others => '0');
            elsif (rising_edge(clk)) then
                p1_reg_exc_flag_mult <= exc_flag_mult;
                p1_reg_exc_result_mult <= exc_result_mult;
            end if;
    end process;

    -- STAGE 3
    process(p2_reg_alu_rm, p2_reg_exp_rm, p2_reg_s_rm, p2_reg_exc_result_mult, p2_reg_in3, p2_reg_funct5, p2_reg_exc_flag_mult) is
        variable p2_exp_rm: integer range 0 to 511 ; 
        variable p2_alu_rm: std_logic_vector (15 downto 0);
        variable flag: std_logic;
        variable exception: std_logic_vector (15 downto 0);
        begin
            p2_exp_rm := p2_reg_exp_rm;
            p2_alu_rm := p2_reg_alu_rm;
            exception := p2_reg_exc_result_mult;
            flag := p2_reg_exc_flag_mult;

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

            -- check for overflow/underflow
            if (flag = '0') then
                if ((p2_exp_rm > 381) and (p2_reg_s_rm = '0')) then
                    exception := "0111111110000000"; -- +inf
                    flag := '1';
                elsif ((p2_exp_rm > 381) and (p2_reg_s_rm = '1')) then
                    exception := "1111111110000000"; -- -inf
                    flag := '1';
                elsif (p2_exp_rm < (128)) then
                    exception := "0000000000000000"; -- zero
                    flag := '1';
                end if;
            end if;

            -- Generate final result in bfloat 16 format
            if (flag = '1') then
                result_mult <= exception;
            else
                result_mult(15) <= p2_reg_s_rm;
                result_mult(14 downto 7) <= std_logic_vector(to_unsigned(p2_exp_rm - 127,8));
                result_mult(6 downto 0) <= p2_alu_rm(14 downto 8);
            end if;
    end process;

    -- STAGE 4
    process (p3_reg_result_mult, p3_reg_in3) is
        variable exp_s1: integer range 0 to 255;
        variable exp_s2: integer range 0 to 255;
        begin
            -- Prepare exponents
            exp_3 <= to_integer(unsigned(p3_reg_in3(14 downto 7)));
            exp_m <= to_integer(unsigned(p3_reg_result_mult(14 downto 7)));
            exp_s2 := to_integer(unsigned((unsigned(p3_reg_result_mult(14 downto 7)) - unsigned(p3_reg_in3(14 downto 7)))));
            exp_s1 := to_integer(unsigned((unsigned(p3_reg_in3(14 downto 7)) - unsigned(p3_reg_result_mult(14 downto 7)))));
            -- Prepare operands
            alu_m <= "001" & p3_reg_result_mult(6 downto 0);
            alu_in3 <= "001" & p3_reg_in3(6 downto 0);
            -- Used for Mantissa allignment in case needed
            alu_m_shifted <= std_logic_vector(shift_right(signed(("001" & p3_reg_result_mult(6 downto 0))),exp_s1));
            alu_in3_shifted <= std_logic_vector(shift_right(signed(("001" & p3_reg_in3(6 downto 0))),exp_s2));
            -- Prepare operands signs
            s_m <= p3_reg_result_mult(15);
            s_in3 <= p3_reg_in3(15);
    end process;

    -- STAGE 4
    process(clk, reset, exp_m, exp_3, p3_reg_funct5, p3_reg_in3, p3_reg_result_mult) is
        variable exc_res: std_logic_vector(15 downto 0); -- result of exception
        variable exc_flag: std_logic ; -- exception flag
        begin
            -- Handle exceptions: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero
            exc_flag := '1';
            -- handle zeros and denorms
            if ((exp_m = 0) and (exp_3 /= 0)) then
                if (p3_reg_funct5(1 downto 0) = "01") then
                    exc_res := not(p3_reg_in3(15)) & p3_reg_in3(14 downto 0);
                else
                    exc_res := p3_reg_in3;
                end if;
            elsif ((exp_3 = 0) and (exp_m /= 0)) then
                if (p3_reg_funct5(1 downto 0) = "01") then
                    exc_res := not(p3_reg_result_mult(15)) & p3_reg_result_mult(14 downto 0);
                else
                    exc_res := p3_reg_result_mult;
                end if;
            elsif ((exp_3 = 0) and (exp_m = 0)) then
                exc_res := (others => '0');
            
            -- handle cancellation (result = 0)
            elsif ((p3_reg_result_mult(14 downto 0) = p3_reg_in3(14 downto 0)) and (p3_reg_result_mult(15) /= p3_reg_in3(15)) and (p3_reg_funct5(1 downto 0) = "00")) then
                exc_res := (others => '0');
            elsif ((p3_reg_result_mult(14 downto 0) = p3_reg_in3(14 downto 0)) and (p3_reg_result_mult(15) = p3_reg_in3(15)) and (p3_reg_funct5(1 downto 0) = "01")) then
                exc_res := (others => '0');
        
            -- handle NaN and infinity
            elsif ((exp_m = 255) or (exp_3 = 255)) then
                if (((p3_reg_result_mult(6 downto 0)) /= "0000000") and (exp_m = 255)) then
                    exc_res := p3_reg_result_mult;
                elsif (((p3_reg_in3(6 downto 0)) /= "0000000") and (exp_3 = 255)) then
                    exc_res := p3_reg_in3;
                else
                    if (exp_m = 255) then
                        exc_res := p3_reg_result_mult;
                    else
                        exc_res := p3_reg_in3;
                    end if;
                end if;
            else
                exc_flag := '0'; -- no exception
            end if;

            if (reset = '0') then
                p4_reg_exc_flag <= '1';
                p4_reg_exc_res <= (others => '0');
            elsif (rising_edge(clk)) then
                p4_reg_exc_flag <= exc_flag;
                p4_reg_exc_res <= exc_res;
            end if;
    end process;

    -- STAGE 4
    process(clk, reset, s_m, s_in3, alu_in3_shifted, alu_m_shifted, exp_m, exp_3) is
        variable v_alu_m: std_logic_vector(9 downto 0) ;
        variable v_alu_in3: std_logic_vector(9 downto 0) ;
        begin
            v_alu_m := alu_m;
            v_alu_in3 := alu_in3;
            
            if (exp_m >= exp_3) then
                -- Mantissa allignment
                v_alu_in3 := alu_in3_shifted;
                exp_r <= exp_m;
            else
                v_alu_m := alu_m_shifted;
                exp_r <= exp_3;
            end if;

            -- Express both operands in two's complement 
            if s_m = '1' then
                v_alu_m := std_logic_vector(-signed(v_alu_m));
            else
                v_alu_m := std_logic_vector(signed(v_alu_m));
            end if;

            if s_in3 = '1' then
                v_alu_in3 := std_logic_vector(-signed(v_alu_in3));
            else
                v_alu_in3 := std_logic_vector(signed(v_alu_in3));
            end if;

            if (reset = '0') then
                p4_reg_alu_m <= (others => '0');
                p4_reg_alu_in3 <= (others => '0');
            elsif (rising_edge(clk)) then
                p4_reg_alu_m <= v_alu_m;
                p4_reg_alu_in3 <= v_alu_in3;
            end if;
    end process;

    -- STAGE 5
    process(clk, reset, p4_reg_alu_m, p4_reg_alu_in3, p4_reg_exc_res, p4_reg_exc_flag, p4_reg_funct5, p4_reg_exp_r) is
        variable alu_r: std_logic_vector(9 downto 0) ;
        variable s_r: std_logic;  -- result sign
        begin
            case p4_reg_funct5 is 
                when "00100"|"00000" => -- add
                    alu_r := std_logic_vector(signed(p4_reg_alu_m) + signed(p4_reg_alu_in3));
                when "00101"|"00001" => -- sub
                    alu_r := std_logic_vector(signed(p4_reg_alu_m) - signed(p4_reg_alu_in3));
                when others =>
                    alu_r := (others => '0');
            end case;

            -- Set result sign bit and express result as a magnitude
            s_r := '0';
            if ((signed(alu_r)) < 0) then
                s_r := '1';
                alu_r := std_logic_vector(-signed(alu_r));
            end if;

            if (reset = '0') then
                p5_reg_alu_r <= (others => '0');
                p5_reg_s_r <= '0';
            elsif (rising_edge(clk)) then
                p5_reg_alu_r <= alu_r;
                p5_reg_s_r <= s_r;
            end if;
    end process;

    -- STAGE 6
    process (p5_reg_exp_r, p5_reg_alu_r, p5_reg_exc_res, p5_reg_exc_flag, p5_reg_s_r) is
        variable p5_alu_r: std_logic_vector(9 downto 0) ;
        variable p5_exp_r: integer range -7 to 255 ;
        begin
            -- Normalize mantissa and adjust exponent
            p5_alu_r := p5_reg_alu_r;
            p5_exp_r := p5_reg_exp_r;

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
            if (p5_reg_exc_flag = '1') then
                result_s6 <= p5_reg_exc_res;
            elsif ((p5_exp_r >= 255) and (p5_reg_s_r = '0')) then
                result_s6 <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p5_exp_r >= 255) and (p5_reg_s_r = '1')) then
                result_s6 <= "1111111110000000"; -- overflow, result = -inf
            elsif (p5_exp_r <= 0) then
                result_s6 <= "0000000000000000"; -- underflow, result = zero
            else
                result_s6(15) <= p5_reg_s_r;
                result_s6(14 downto 7) <= std_logic_vector(to_unsigned(p5_exp_r,8));
                result_s6(6 downto 0) <= p5_alu_r(6 downto 0);
            end if;
    end process;

    -- STAGE 7
    result <= p6_reg_result;

end architecture;



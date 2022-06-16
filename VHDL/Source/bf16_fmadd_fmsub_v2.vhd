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
    -- pipeline registers
    -- used to propagate information used at later stages

    -- p1 register
    signal p1_reg_in3: std_logic_vector(15 downto 0) ;
    signal p1_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p1_reg_exp_rm: integer ;
    signal p1_reg_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_reg_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p1_reg_s_rm: std_logic;
    signal p1_reg_exc_flag: std_logic;

    -- p2 register
    signal p2_reg_alu_rm: std_logic_vector(15 downto 0) ;
    signal p2_reg_exp_rm: integer ;
    signal p2_reg_s_rm: std_logic;
    signal p2_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_reg_in3: std_logic_vector(15 downto 0) ;
    signal p2_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p2_reg_exc_flag: std_logic;

    -- p3 register
    signal p3_reg_alu_m: std_logic_vector(17 downto 0) ;
    signal p3_reg_alu_m_shifted: std_logic_vector(17 downto 0) ;
    signal p3_reg_alu_in3: std_logic_vector(17 downto 0) ;
    signal p3_reg_alu_in3_shifted: std_logic_vector(17 downto 0) ;
    signal p3_reg_exp_3: integer  ;
    signal p3_reg_exp_m: integer  ;
    signal p3_reg_s_m: std_logic ;
    signal p3_reg_s_in3: std_logic ;
    signal p3_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p3_reg_exc_flag: std_logic ;
    signal p3_reg_funct5: std_logic_vector(4 downto 0) ;

    -- p4 register
    signal p4_reg_alu_m: std_logic_vector(17 downto 0) ;
    signal p4_reg_alu_in3: std_logic_vector(17 downto 0) ;
    signal p4_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p4_reg_exc_flag: std_logic ;
    signal p4_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p4_reg_exp_r: integer ;

    -- p5 register
    signal p5_reg_exp_r: integer ;
    signal p5_reg_alu_r: std_logic_vector(17 downto 0) ;
    signal p5_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p5_reg_exc_flag: std_logic ;
    signal p5_reg_s_r: std_logic ;
    signal p5_reg_cancel_flag: std_logic;

    signal p6_reg_exc_flag: std_logic ;
    signal p6_reg_s_r: std_logic ;
    signal p6_reg_cancel_flag: std_logic ;
    signal p6_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p6_reg_alu_r: std_logic_vector(17 downto 0) ;
    signal p6_reg_exp_r: integer ;
    
    -- p6 register
    signal p7_reg_result: std_logic_vector(15 downto 0) ;

    -- STAGE 1
    signal exp_1: integer ; -- exponent 1
    signal exp_2: integer ; -- exponent 2
    signal alu_in1: std_logic_vector(7 downto 0) ; -- operand 1
    signal alu_in2: std_logic_vector(7 downto 0) ; -- operand 2
    signal s_rm: std_logic ;  -- multiplication result sign
    -- STAGE 3 
    signal exp_m: integer ; -- multiplication result exponent (used for first input to add/sub)
    signal exp_3: integer ; -- exponent 3 (used for second input to add/sub)
    signal exp_r: integer; -- final result exponent
    signal alu_m: std_logic_vector(17 downto 0) ; -- operand 1 (generated from multiplication result)
    signal alu_in3: std_logic_vector(17 downto 0) ; -- operand 2
    -- 10 bits used as operand: 
    -- 1 sign bit, 1 guard bit, 1 implied one, 7 from significand
    signal alu_m_shifted: std_logic_vector(17 downto 0) ; -- shifted operand 1 (used if necessary)
    signal alu_in3_shifted: std_logic_vector(17 downto 0) ; -- shifted operand 2 (used if necessary)
    signal s_m: std_logic; -- multiplication sign
    signal s_in3: std_logic; -- input 3 sign
    -- STAGE 6
    signal result_s7: std_logic_vector(15 downto 0) ; -- final result
    
    attribute use_dsp: string;
    attribute use_dsp of p2_reg_alu_rm: signal is "yes";
begin
    -- pipeline registers
    process (clk, reset, exp_1, exp_2, in3, funct5, alu_in1, alu_in2, s_rm, exp_r) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_exp_rm <= 0;
                p1_reg_in3 <= (others => '0');
                p1_reg_funct5 <= (others => '0');
                p1_reg_alu_in1 <= (others => '0');
                p1_reg_alu_in2 <= (others => '0');
                p1_reg_s_rm <= '0';
                -- p2 register
                p2_reg_alu_rm <= (others => '0');
                p2_reg_exp_rm <= 0;
                p2_reg_s_rm <= '0';
                p2_reg_exc_res <= (others => '0');
                p2_reg_in3 <= (others => '0');
                p2_reg_funct5 <= (others => '0');
                p2_reg_exc_flag <= '1';
                -- p3 register
                p3_reg_alu_m <= (others => '0');
                p3_reg_alu_m_shifted <= (others => '0');
                p3_reg_alu_in3 <= (others => '0');
                p3_reg_alu_in3_shifted <= (others => '0');
                p3_reg_exp_3 <= 0;
                p3_reg_exp_m <= 0;
                p3_reg_s_m <= '0';
                p3_reg_s_in3 <= '0';
                p3_reg_exc_res <= (others => '0');
                p3_reg_exc_flag <= '1';
                p3_reg_funct5 <= (others => '0');
                -- p4 register
                p4_reg_funct5 <= (others => '0');
                p4_reg_exp_r <= 0;
                p4_reg_exc_res <= (others => '0');
                p4_reg_exc_flag <= '1';
                -- p5 register
                p5_reg_exp_r <= 0;
                p5_reg_exc_res <= (others => '0');
                p5_reg_exc_flag <= '1';
                -- p6 register
                p6_reg_exc_flag <= '1';
                p6_reg_s_r <= '0';
                p6_reg_cancel_flag <= '0';
                p6_reg_exc_res <= (others => '0');
                -- p7 register
                p7_reg_result <=  (others => '0');
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_exp_rm <= (exp_1 + exp_2)-127; -- compute multiplication result exponent
                p1_reg_in3 <= in3;
                p1_reg_funct5 <= funct5;
                p1_reg_alu_in1<= alu_in1;
                p1_reg_alu_in2<= alu_in2;
                p1_reg_s_rm <= s_rm;
                -- STAGE 2
                p2_reg_alu_rm <= std_logic_vector(unsigned(p1_reg_alu_in1) * unsigned(p1_reg_alu_in2)); -- multiply operands
                p2_reg_exp_rm <= p1_reg_exp_rm;
                p2_reg_s_rm <= p1_reg_s_rm;
                p2_reg_exc_res <= p1_reg_exc_res;
                p2_reg_in3 <= p1_reg_in3;
                p2_reg_funct5 <= p1_reg_funct5;
                p2_reg_exc_flag <= p1_reg_exc_flag;
                -- STAGE 3
                p3_reg_alu_m <= alu_m;
                p3_reg_alu_m_shifted <= alu_m_shifted;
                p3_reg_alu_in3 <= alu_in3;
                p3_reg_alu_in3_shifted <= alu_in3_shifted;
                p3_reg_exp_3 <= exp_3;
                p3_reg_exp_m <= exp_m;
                p3_reg_s_m <= s_m;
                p3_reg_s_in3 <= s_in3;
                p3_reg_exc_res <= p2_reg_exc_res;
                p3_reg_exc_flag <= p2_reg_exc_flag;
                p3_reg_funct5 <= p2_reg_funct5;
                -- STAGE 4
                p4_reg_funct5 <= p3_reg_funct5;
                p4_reg_exp_r <= exp_r;
                p4_reg_exc_res <= p3_reg_exc_res;
                p4_reg_exc_flag <= p3_reg_exc_flag;
                -- STAGE 5
                p5_reg_exp_r <= p4_reg_exp_r;
                p5_reg_exc_res <= p4_reg_exc_res;
                p5_reg_exc_flag <= p4_reg_exc_flag;
                -- STAGE 6
                p6_reg_exc_flag <= p5_reg_exc_flag;
                p6_reg_s_r <= p5_reg_s_r;
                p6_reg_cancel_flag <= p5_reg_cancel_flag;
                p6_reg_exc_res <= p5_reg_exc_res;
                -- STAGE 7
                p7_reg_result <= result_s7;
            end if;
    end process;

    -- STAGE 1
    process (in1, in2) is
        begin
            if ((in1(14 downto 7) = "00000000") or (in2(14 downto 7) = "00000000")) then
                -- handle zeros and denorms
                -- Denormalized numbers are flushed to zero
                exp_1 <= 0;
                exp_2 <= 127;
                alu_in1 <= (others => '0');
                alu_in2 <= (others => '0');
                s_rm <= '0';
            else
                -- Prepare exponents
                -- We do not need to work with actual exponent.
                -- We use bias notation to save on calculations.
                exp_1 <= to_integer(unsigned(in1(14 downto 7)));
                exp_2 <= to_integer(unsigned(in2(14 downto 7)));
                -- Prepare operands
                alu_in1 <= '1' & in1(6 downto 0);
                alu_in2 <= '1' & in2(6 downto 0);
                -- adjust multiplication result sign
                s_rm <= in1(15) xor in2(15);
            end if;
    end process;

    -- STAGE 1
    process(clk, reset, in1, in2, in3, exp_1, exp_2, exp_3) is
        variable exc_flag: std_logic;
        variable exc_res: std_logic_vector(15 downto 0) ;
        begin
            -- Handle exceptions: NaN and infinity
            exc_flag:= '1';
            
            -- handle NaN and infinity
            if ((exp_1 = 255) or (exp_2 = 255) or (in3(14 downto 7) = "11111111")) then
                if (((in1(6 downto 0)) /= "0000000") and (exp_1 = 255)) then
                    exc_res := in1;
                elsif (((in2(6 downto 0)) /= "0000000") and (exp_2 = 255)) then
                    exc_res := in2;
                elsif (((in3(6 downto 0)) /= "0000000") and (in3(14 downto 7) = "11111111")) then
                    exc_res := in3;
                else
                    if (exp_1 = 255) then
                        exc_res := in1;
                    elsif (exp_2 = 255) then
                        exc_res := in2;
                    else
                        exc_res := in3;
                    end if;
                end if;
            else
                -- no exception
                exc_flag:= '0';
            end if;

            if (reset = '0') then
                p1_reg_exc_flag <= '1';
                p1_reg_exc_res <= (others => '0');
            elsif (rising_edge(clk)) then
                p1_reg_exc_flag <= exc_flag;
                p1_reg_exc_res <= exc_res;
            end if;
    end process;

    -- STAGE 3
    process (p2_reg_alu_rm, p2_reg_exp_rm, p2_reg_in3, p2_reg_s_rm) is
        variable exp_s1: integer ;
        variable exp_s2: integer ;
        variable exp_rm_signed: signed (9 downto 0);
        -- these are used to store the "shift value" in case we need to shift mantissas for allignment
        begin
            -- Prepare exponents
            exp_3 <= to_integer(unsigned(p2_reg_in3(14 downto 7)));
            exp_m <= p2_reg_exp_rm;
            exp_rm_signed := to_signed(p2_reg_exp_rm, 10);

            exp_s1 := to_integer(signed((signed("00" & p2_reg_in3(14 downto 7)) - exp_rm_signed)));
            exp_s2 := to_integer(signed((exp_rm_signed - signed("00" & p2_reg_in3(14 downto 7)))));

            if ((p2_reg_in3(14 downto 7)) = "00000000") then
                -- handle zeros and denorms
                -- Denormalized numbers are flushed to zero
                alu_in3 <= (others => '0');
                alu_in3_shifted <= (others => '0');
                s_in3 <= '0';
            else
                -- normal case
                -- Prepare operands
                alu_in3 <= "0001" & p2_reg_in3(6 downto 0) & "0000000";
                -- Used for Mantissa allignment in case needed
                alu_in3_shifted <= std_logic_vector(shift_right(signed(("0001" & p2_reg_in3(6 downto 0) & "0000000")),exp_s2));
                -- Prepare operands signs
                s_in3 <= p2_reg_in3(15);
            end if;

            if ((p2_reg_alu_rm(14 downto 7)) = "00000000") then
                alu_m <= (others => '0');
                alu_m_shifted <= (others => '0');
                s_m <= '0';
            else
                alu_m <= "00" & p2_reg_alu_rm;
                alu_m_shifted <= std_logic_vector(shift_right(signed(("00" & p2_reg_alu_rm)),exp_s1));
                s_m <= p2_reg_s_rm;
            end if;
    end process;

    -- STAGE 4
    process(clk, reset, p3_reg_s_m, p3_reg_s_in3, p3_reg_alu_in3_shifted, p3_reg_alu_m_shifted, p3_reg_exp_m, p3_reg_exp_3, p3_reg_alu_m, p3_reg_alu_in3) is
        variable v_alu_m: std_logic_vector(17 downto 0) ;
        variable v_alu_in3: std_logic_vector(17 downto 0) ;
        begin
            v_alu_m := p3_reg_alu_m;
            v_alu_in3 := p3_reg_alu_in3;
            
            if (p3_reg_exp_m >= p3_reg_exp_3) then
                -- Mantissa allignment
                v_alu_in3 := p3_reg_alu_in3_shifted;
                -- Choose correct exponent as result
                exp_r <= p3_reg_exp_m;
            else
                v_alu_m := p3_reg_alu_m_shifted;
                exp_r <= p3_reg_exp_3;
            end if;

            -- Express both operands in two's complement 
            if p3_reg_s_m = '1' then
                v_alu_m := std_logic_vector(-signed(v_alu_m));
            else
                v_alu_m := std_logic_vector(signed(v_alu_m));
            end if;

            if p3_reg_s_in3 = '1' then
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
        variable alu_r: std_logic_vector(17 downto 0) ;
        variable s_r: std_logic;  -- result sign
        variable cancel_flag: std_logic; -- cancellation flag
        begin
            case p4_reg_funct5 is 
                when "00100"|"00000"|"00010" => -- for performing fused multiply add or regular add
                    alu_r := std_logic_vector(signed(p4_reg_alu_m) + signed(p4_reg_alu_in3));
                when "00101"|"00001" => -- for performing fused multiply sub or regular sub
                    alu_r := std_logic_vector(signed(p4_reg_alu_m) - signed(p4_reg_alu_in3));
                when others =>
                    alu_r := (others => '0');
            end case;

            -- handle cancellation
            if (alu_r = "000000000000000000") then
                cancel_flag := '1';
            else
                cancel_flag := '0';
            end if;

            -- Set result sign bit and express result as a magnitude
            s_r := '0';
            if ((signed(alu_r)) < 0) then
                s_r := '1';
                alu_r := std_logic_vector(-signed(alu_r));
            end if;

            if (reset = '0') then
                p5_reg_alu_r <= (others => '0');
                p5_reg_s_r <= '0';
                p5_reg_cancel_flag <= '0';
            elsif (rising_edge(clk)) then
                p5_reg_alu_r <= alu_r;
                p5_reg_s_r <= s_r;
                p5_reg_cancel_flag <= cancel_flag;
            end if;
    end process;

    process(p5_reg_alu_r, p5_reg_exp_r, clk, reset) is
        variable p5_alu_r: std_logic_vector(17 downto 0) ;
        variable p5_exp_r: integer ;
        begin
            p5_alu_r := p5_reg_alu_r;
            p5_exp_r := p5_reg_exp_r;

            if (p5_alu_r(16) = '1') then
                p5_exp_r := p5_exp_r + 2;
                p5_alu_r := std_logic_vector(shift_right(unsigned(p5_alu_r), 2));
            elsif (p5_alu_r(15) = '1') then
                p5_exp_r := p5_exp_r + 1;
                p5_alu_r := std_logic_vector(shift_right(unsigned(p5_alu_r), 1));
            elsif (p5_alu_r(14) = '1') then
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 0));
            elsif (p5_alu_r(13) = '1') then
                p5_exp_r := p5_exp_r - 1;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 1));
            elsif (p5_alu_r(12) = '1') then
                p5_exp_r := p5_exp_r - 2;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 2));
            elsif (p5_alu_r(11) = '1') then
                p5_exp_r := p5_exp_r - 3;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 3));
            elsif (p5_alu_r(10) = '1') then
                p5_exp_r := p5_exp_r - 4;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 4));
            elsif (p5_alu_r(9) = '1') then
                p5_exp_r := p5_exp_r - 5;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 5));
            elsif (p5_alu_r(8) = '1') then
                p5_exp_r := p5_exp_r - 6;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 6));
            elsif (p5_alu_r(7) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 7));
            elsif (p5_alu_r(6) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 8));
            elsif (p5_alu_r(5) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 9));
            elsif (p5_alu_r(4) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 10));
            elsif (p5_alu_r(3) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 11));
            elsif (p5_alu_r(2) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 12));
            elsif (p5_alu_r(1) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 13));
            elsif (p5_alu_r(0) = '1') then
                p5_exp_r := p5_exp_r - 7;
                p5_alu_r := std_logic_vector(shift_left(unsigned(p5_alu_r), 14));
            end if;

            if (reset = '0') then
                p6_reg_alu_r <= (others => '0');
                p6_reg_exp_r <= 0;
            elsif (rising_edge(clk)) then
                p6_reg_alu_r <= p5_alu_r;
                p6_reg_exp_r <= p5_exp_r;
            end if;
    end process;

    -- STAGE 6
    process (p6_reg_cancel_flag, p6_reg_exp_r, p6_reg_alu_r, p6_reg_exc_res, p6_reg_exc_flag, p6_reg_s_r) is
        variable p6_alu_r: std_logic_vector(17 downto 0) ;
        variable p6_exp_r: integer ;
        begin
            p6_alu_r := p6_reg_alu_r;
            p6_exp_r := p6_reg_exp_r;

            -- round to the nearest even
            if (p6_alu_r(6) = '1') then
                p6_alu_r(13 downto 7) := std_logic_vector(unsigned(p6_alu_r(13 downto 7))+1);
                -- Adjust exponent
                if (p6_alu_r(13 downto 7) = "0000000") then
                    p6_exp_r := p6_exp_r + 1;
                end if;
            end if;
            
            -- Generate final result in bfloat 16 format
            if (p6_reg_exc_flag = '1') then
                result_s7 <= p6_reg_exc_res;
            elsif (p6_reg_cancel_flag = '1') then
                result_s7 <= (others => '0');
            elsif ((p6_exp_r >= 255) and (p6_reg_s_r = '0')) then
                result_s7 <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p6_exp_r >= 255) and (p6_reg_s_r = '1')) then
                result_s7 <= "1111111110000000"; -- overflow, result = -inf
            elsif (p6_exp_r <= 0) then
                result_s7 <= "0000000000000000"; -- underflow, result = zero
            else
                result_s7(15) <= p6_reg_s_r;
                result_s7(14 downto 7) <= std_logic_vector(to_unsigned(p6_exp_r,8));
                result_s7(6 downto 0) <= p6_alu_r(13 downto 7);
            end if;
    end process;

    -- STAGE 7
    result <= p7_reg_result;

end architecture;
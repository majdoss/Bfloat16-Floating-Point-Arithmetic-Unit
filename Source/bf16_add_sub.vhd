library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_add_sub is
    port(
        clk: in std_logic;
        reset: in std_logic;
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        funct5: in std_logic_vector(4 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_add_sub;

architecture rtl of bf16_add_sub is
    -- p1 register
    signal p1_reg_alu_in1: std_logic_vector(9 downto 0) ;
    signal p1_reg_alu_in2: std_logic_vector(9 downto 0) ;
    signal p1_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p1_reg_exc_flag: std_logic ;
    signal p1_reg_funct5: std_logic_vector(4 downto 0) ;
    signal p1_reg_exp_r: integer range 0 to 255 ;

    -- p2 register
    signal p2_reg_exp_r: integer range 0 to 255 ;
    signal p2_reg_alu_r: std_logic_vector(9 downto 0) ;
    signal p2_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_reg_exc_flag: std_logic ;
    signal p2_reg_s_r: std_logic ;
    
    -- p3 register
    signal p3_reg_result: std_logic_vector(15 downto 0) ;

    -- STAGE 1 
    signal exp_1: integer range 0 to 255 ; -- exponent
    signal exp_2: integer range 0 to 255 ;
    signal exp_r: integer range 0 to 255;
    signal alu_in1: std_logic_vector(9 downto 0) ;
    signal alu_in2: std_logic_vector(9 downto 0) ;
    -- 10 bits used as operand: 
    -- 1 sign bit, 1 guard bit, 1 implied one, 7 from significand
    signal alu_in1_shifted: std_logic_vector(9 downto 0) ;
    signal alu_in2_shifted: std_logic_vector(9 downto 0) ;
    signal s_in1: std_logic;
    signal s_in2: std_logic;
    -- STAGE 3
    signal result_s3: std_logic_vector(15 downto 0) ;
begin
    process (clk, exp_1, exp_2, funct5, alu_in1, alu_in2, exp_r) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_funct5 <= (others => '0');
                p1_reg_exp_r <= 0;
                -- p2 register
                p2_reg_exp_r <= 0;
                p2_reg_exc_res <= (others => '0');
                p2_reg_exc_flag <= '1';
                p3_reg_result <=  (others => '0');
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_funct5 <= funct5;
                p1_reg_exp_r <= exp_r;
                -- STAGE 2
                p2_reg_exp_r <= p1_reg_exp_r;
                p2_reg_exc_res <= p1_reg_exc_res;
                p2_reg_exc_flag <= p1_reg_exc_flag;
                -- STAGE 3
                p3_reg_result <= result_s3;
            end if;
    end process;

    -- STAGE 1
    process (in1, in2) is
        variable exp_s1: integer range 0 to 255;
        variable exp_s2: integer range 0 to 255;
        begin
            -- Prepare exponents
            exp_1 <= to_integer(unsigned(in1(14 downto 7)));
            exp_2 <= to_integer(unsigned(in2(14 downto 7)));
            exp_s2 := to_integer(unsigned((unsigned(in1(14 downto 7)) - unsigned(in2(14 downto 7)))));
            exp_s1 := to_integer(unsigned((unsigned(in2(14 downto 7)) - unsigned(in1(14 downto 7)))));
            -- Prepare operands
            alu_in1 <= "001" & in1(6 downto 0);
            alu_in2 <= "001" & in2(6 downto 0);
            -- Used for Mantissa allignment in case needed
            alu_in1_shifted <= std_logic_vector(shift_right(signed(("001" & in1(6 downto 0))),exp_s1));
            alu_in2_shifted <= std_logic_vector(shift_right(signed(("001" & in2(6 downto 0))),exp_s2));
            -- Prepare operands signs
            s_in1 <= in1(15);
            s_in2 <= in2(15);
    end process;

    -- STAGE 1
    process(clk, reset, exp_1, exp_2, funct5, in1, in2) is
        variable exc_res: std_logic_vector(15 downto 0); -- result of exception
        variable exc_flag: std_logic ; -- exception flag
        begin
            -- Handle exceptions: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero
            exc_flag := '1';
            -- handle zeros and denorms
            if ((exp_1 = 0) and (exp_2 /= 0)) then
                if (funct5 = "00001") then
                    exc_res := not(in2(15)) & in2(14 downto 0);
                else
                    exc_res := in2;
                end if;
            elsif ((exp_2 = 0) and (exp_1 /= 0)) then
                if (funct5 = "00001") then
                    exc_res := not(in1(15)) & in1(14 downto 0);
                else
                    exc_res := in1;
                end if;
            elsif ((exp_2 = 0) and (exp_1 = 0)) then
                exc_res := (others => '0');
            
            -- handle cancellation (result = 0)
            elsif ((in1(14 downto 0) = in2(14 downto 0)) and (in1(15) /= in2(15)) and (funct5 = "00000")) then
                exc_res := (others => '0');
            elsif ((in1(14 downto 0) = in2(14 downto 0)) and (in1(15) = in2(15)) and (funct5 = "00001")) then
                exc_res := (others => '0');
        
            -- handle NaN and infinity
            elsif ((exp_1 = 255) or (exp_2 = 255)) then
                if (((in1(6 downto 0)) /= "0000000") and (exp_1 = 255)) then
                    exc_res := in1;
                elsif (((in2(6 downto 0)) /= "0000000") and (exp_2 = 255)) then
                    exc_res := in2;
                else
                    if (exp_1 = 255) then
                        exc_res := in1;
                    else
                        exc_res := in2;
                    end if;
                end if;
            else
                exc_flag := '0'; -- no exception
            end if;

            if (reset = '0') then
                p1_reg_exc_flag <= '1';
                p1_reg_exc_res <= (others => '0');
            elsif (rising_edge(clk)) then
                p1_reg_exc_flag <= exc_flag;
                p1_reg_exc_res <= exc_res;
            end if;
    end process;

    -- STAGE 1
    process(clk, reset, s_in1, s_in2, alu_in2_shifted, alu_in1_shifted, exp_1, exp_2) is
        variable v_alu_in1: std_logic_vector(9 downto 0) ;
        variable v_alu_in2: std_logic_vector(9 downto 0) ;
        begin
            v_alu_in1 := alu_in1;
            v_alu_in2 := alu_in2;
            
            if (exp_1 >= exp_2) then
                -- Mantissa allignment
                v_alu_in2 := alu_in2_shifted;
                exp_r <= exp_1;
            else
                v_alu_in1 := alu_in1_shifted;
                exp_r <= exp_2;
            end if;

            -- Express both operands in two's complement 
            if s_in1 = '1' then
                v_alu_in1 := std_logic_vector(-signed(v_alu_in1));
            else
                v_alu_in1 := std_logic_vector(signed(v_alu_in1));
            end if;

            if s_in2 = '1' then
                v_alu_in2 := std_logic_vector(-signed(v_alu_in2));
            else
                v_alu_in2 := std_logic_vector(signed(v_alu_in2));
            end if;

            if (reset = '0') then
                p1_reg_alu_in1 <= (others => '0');
                p1_reg_alu_in2 <= (others => '0');
            elsif (rising_edge(clk)) then
                p1_reg_alu_in1 <= v_alu_in1;
                p1_reg_alu_in2 <= v_alu_in2;
            end if;
    end process;

    -- STAGE 2
    process(clk, reset, p1_reg_alu_in1, p1_reg_alu_in2, p1_reg_exc_res, p1_reg_exc_flag, p1_reg_funct5, p1_reg_exp_r) is
        variable alu_r: std_logic_vector(9 downto 0) ;
        variable s_r: std_logic;  -- result sign
        begin
            case p1_reg_funct5 is 
                when "00000" => -- add
                    alu_r := std_logic_vector(signed(p1_reg_alu_in1) + signed(p1_reg_alu_in2));
                when "00001" => -- sub
                    alu_r := std_logic_vector(signed(p1_reg_alu_in1) - signed(p1_reg_alu_in2));
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
                p2_reg_alu_r <= (others => '0');
                p2_reg_s_r <= '0';
            elsif (rising_edge(clk)) then
                p2_reg_alu_r <= alu_r;
                p2_reg_s_r <= s_r;
            end if;
    end process;

    -- STAGE 3
    process (p2_reg_exp_r, p2_reg_alu_r, p2_reg_exc_res, p2_reg_exc_flag, p2_reg_s_r) is
        variable p2_alu_r: std_logic_vector(9 downto 0) ;
        variable p2_exp_r: integer range -7 to 255 ;
        begin
            -- Normalize mantissa and adjust exponent
            p2_alu_r := p2_reg_alu_r;
            p2_exp_r := p2_reg_exp_r;

            if (p2_alu_r(8) = '1') then
                -- overflow
                p2_exp_r := p2_exp_r + 1;
                p2_alu_r := std_logic_vector(shift_right(unsigned(p2_alu_r), 1));
            elsif (p2_alu_r(7) = '1') then
                -- do not shift
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 0));
            elsif (p2_alu_r(6) = '1') then
                p2_exp_r := p2_exp_r - 1;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 1));
            elsif (p2_alu_r(5) = '1') then
                p2_exp_r := p2_exp_r - 2;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 2));
            elsif (p2_alu_r(4) = '1') then
                p2_exp_r := p2_exp_r - 3;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 3));
            elsif (p2_alu_r(3) = '1') then
                p2_exp_r := p2_exp_r - 4;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 4));
            elsif (p2_alu_r(2) = '1') then
                p2_exp_r := p2_exp_r - 5;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 5));
            elsif (p2_alu_r(1) = '1') then
                p2_exp_r := p2_exp_r - 6;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 6));
            elsif (p2_alu_r(0) = '1') then
                p2_exp_r := p2_exp_r - 7;
                p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 7));
            end if;
            
            -- Generate final result in bfloat 16 format
            if (p2_reg_exc_flag = '1') then
                result_s3 <= p2_reg_exc_res;
            elsif ((p2_exp_r >= 255) and (p2_reg_s_r = '0')) then
                result_s3 <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p2_exp_r >= 255) and (p2_reg_s_r = '1')) then
                result_s3 <= "1111111110000000"; -- overflow, result = -inf
            elsif (p2_exp_r <= 0) then
                result_s3 <= "0000000000000000"; -- underflow, result = zero
            else
                result_s3(15) <= p2_reg_s_r;
                result_s3(14 downto 7) <= std_logic_vector(to_unsigned(p2_exp_r,8));
                result_s3(6 downto 0) <= p2_alu_r(6 downto 0);
            end if;
    end process;

    -- STAGE 4
    result <= p3_reg_result;
end architecture;


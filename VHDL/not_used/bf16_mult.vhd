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
    signal p2_reg_exc_flag_mult: std_logic;

    -- p3 register
    signal p3_reg_result_mult: std_logic_vector(15 downto 0) ;

    -- STAGE 1
    signal alu_rm: std_logic_vector(15 downto 0);
    signal exp_1: integer range 0 to 255 ;
    signal exp_2: integer range 0 to 255 ;
    signal alu_in1: std_logic_vector(7 downto 0) ;
    signal alu_in2: std_logic_vector(7 downto 0) ; 
    signal s_rm: std_logic ;  -- multiplication result sign
    -- STAGE 3 
    signal result_mult: std_logic_vector(15 downto 0);  -- multiplication result in bf16 format
begin
    process (clk, exp_1, exp_2, alu_in1, alu_in2, s_rm) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_exp_rm <= 0;
                p1_reg_alu_in1<= (others => '0');
                p1_reg_alu_in2<= (others => '0');
                p1_reg_s_rm <= '0';
                -- p2 register
                p2_reg_alu_rm <= (others => '0');
                p2_reg_exp_rm <= 0;
                p2_reg_s_rm <= '0';
                p2_reg_exc_result_mult <= (others => '0');
                p2_reg_exc_flag_mult <= '1';
                -- p3 register
                p3_reg_result_mult <= (others => '0');
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_exp_rm <= exp_1 + exp_2; -- prepare multiplication result exponent
                p1_reg_alu_in1<= alu_in1;
                p1_reg_alu_in2<= alu_in2;
                p1_reg_s_rm <= s_rm;
                -- STAGE 2
                p2_reg_alu_rm <= std_logic_vector(unsigned(p1_reg_alu_in1) * unsigned(p1_reg_alu_in2)); -- multiply operands
                p2_reg_exp_rm <= p1_reg_exp_rm;
                p2_reg_s_rm <= p1_reg_s_rm;
                p2_reg_exc_result_mult <= p1_reg_exc_result_mult;
                p2_reg_exc_flag_mult <= p1_reg_exc_flag_mult;
                -- STAGE 3
                p3_reg_result_mult <= result_mult;
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
    process(p2_reg_alu_rm, p2_reg_exp_rm, p2_reg_s_rm, p2_reg_exc_result_mult, p2_reg_exc_flag_mult) is
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

    result <= p3_reg_result_mult;
end architecture;   


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_div is
    port(
        clk: in std_logic;
        reset: in std_logic;
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_div;

architecture rtl of bf16_div is
    -- p1 register
    signal p1_reg_alu_in2 : std_logic_vector(7 downto 0);
    signal p1_reg_alu_r: std_logic_vector(17 downto 0);
    signal p1_reg_exc_res: std_logic_vector(15 downto 0);
    signal p1_reg_exc_flag: std_logic;
    signal p1_reg_s_r: std_logic;
    signal p1_reg_exp_r: integer range -254 to 255 ;

    -- p2 register
    signal p2_in_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_in_exc_flag: std_logic ;
    signal p2_in_exp_r: integer range -254 to 255 ;
    signal p2_in_s_r: std_logic ;
    signal p2_in_alu_r: std_logic_vector(17 downto 0) ;
    signal p2_in_count: integer range 0 to 7 ;

    signal p2_out_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_out_exc_flag: std_logic ;
    signal p2_out_exp_r: integer range -254 to 255 ;
    signal p2_out_s_r: std_logic ;
    signal p2_out_alu_r: std_logic_vector(17 downto 0) ;
    signal p2_out_count: integer range 0 to 7 ;

    -- p3 register
    signal p3_reg_result_s3: std_logic_vector(15 downto 0) ;

    type myState is (idle_s, busy_s, done_s);
    signal currentState : myState; -- state of the FSM

    signal exp_1: integer range -254 to 255 ; -- exponent
    signal exp_2: integer range -254 to 255 ; -- exponent
    signal result_s3: std_logic_vector(15 downto 0) ;
begin
    -- STAGE 1
    process (in1, in2) is
        begin
            -- Prepare exponents
            -- We do not need to work with actual exponent. We use bias notation.
            exp_1 <= to_integer(unsigned(in1(14 downto 7)));
            exp_2 <= to_integer(unsigned(in2(14 downto 7)));
    end process;

    -- STAGE 1
    process(clk, reset, in1, in2, exp_1, exp_2) is
        variable alu_in1: std_logic_vector(7 downto 0); -- operand 1
        variable alu_in2: std_logic_vector(7 downto 0); -- operand 2

        variable alu_r: std_logic_vector(17 downto 0); -- result
        -- 18 bits: 
        -- 9 bits to shift dividend when it is smaller then divisor
        -- 8 bits for the mantissa with 1 extra bit to shift in case mantissa is not normalized

        variable s_r: std_logic;  -- result sign
        variable exp_r: integer range -254 to 255 ; -- exponent
        variable exc_res: std_logic_vector(15 downto 0); -- result of exception
        variable exc_flag: std_logic ; -- exception flag
        begin
            -- First consider special cases: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero
            exc_flag := '1';
            -- handle zeros and denorms
            if ((exp_1 = 0) or (exp_2 = 0)) then
                if (exp_2 = 0) then
                    exc_res := "0111111111111111"; -- NaN
                else
                    exc_res := (others => '0');
                end if;

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
                        exc_res := (others => '0'); -- division by infinity = 0
                    end if;
                end if;
            else
                exc_flag := '0';
            end if;

            -- Prepare operands
            alu_in1 := '1' & in1(6 downto 0);
            alu_in2 := '1' & in2(6 downto 0);
            -- result exponent
            exp_r := exp_1 - exp_2;
            -- adjust result sign
            s_r := in1(15) xor in2(15);
            
            -- start operation
            alu_r :=  (others => '0');
            -- divide the mantissas through multiple subtractions
            -- we start with one iteration to check how many subtractions to perform
            if (unsigned(alu_in2) <= unsigned(alu_in1)) then
                alu_r(16 downto 9):= std_logic_vector(unsigned(alu_in1) - unsigned(alu_in2));
                alu_r(0):= '1';
            else
                -- the bit representing the "integral" part is 0
                -- we need to shift left once and adjust exponent
                -- this allows us to perform one more subtraction to get more precision
                alu_in1 := std_logic_vector(shift_left(unsigned(alu_in1), 1));
                alu_r(16 downto 9):= std_logic_vector(unsigned(alu_in1) - unsigned(alu_in2));
                alu_r(0):= '1';
                exp_r := exp_r - 1;
            end if;

            -- p1 register
            if (reset = '0') then
                p1_reg_exc_flag <= '1';
                p1_reg_exc_res <= (others => '0');
                p1_reg_alu_in2 <=  (others => '0');
                p1_reg_exp_r <= 0;
                p1_reg_alu_r <= (others => '0');
                p1_reg_s_r <= '0';
            elsif (rising_edge(clk) and (currentState = done_s)) then
                p1_reg_alu_in2 <= alu_in2;
                p1_reg_exp_r <= exp_r;
                p1_reg_alu_r <= alu_r;
                p1_reg_s_r <= s_r;
                p1_reg_exc_flag <= exc_flag;
                p1_reg_exc_res <= exc_res;
            end if;
    end process;

    -- STAGE 2
    process(clk, reset, p1_reg_alu_in2, p1_reg_exp_r, p1_reg_alu_r, p1_reg_exc_res, p1_reg_exc_flag, p1_reg_s_r) is
        variable count: integer range 0 to 7 ;
        variable p1_alu_in2: std_logic_vector(7 downto 0) ;
        variable p1_alu_r: std_logic_vector(17 downto 0);
        begin
            -- In this stage, we are basically performing the "paper and pencil" long divison algorithm
            -- It is based on multiple subtractions
            if (rising_edge(clk)) then
                if (reset = '0') then
                    currentState <= idle_s;
                else
                    case currentState is
                        when idle_s =>
                            count := 0;
                            p1_alu_in2 := p1_reg_alu_in2;
                            p1_alu_r := p1_reg_alu_r;
                            currentState <= busy_s;
                        when busy_s =>
                            if (unsigned(p1_alu_in2) > unsigned(p1_alu_r(17 downto 9))) and (p1_alu_r(17 downto 9) /= "000000000") and (count < 7) then
                                p1_alu_r := std_logic_vector(shift_left(unsigned(p1_alu_r), 1));

                                if (unsigned(p1_alu_in2) <= unsigned(p1_alu_r(17 downto 9))) then
                                    p1_alu_r(17 downto 9):= std_logic_vector(unsigned(p1_alu_r(17 downto 9)) - unsigned(p1_alu_in2));
                                    p1_alu_r(0):= '1';
                                end if;
                                count := count + 1;
                                currentState <= busy_s;
                            else
                                p2_in_exc_res <= p1_reg_exc_res;
                                p2_in_exc_flag <= p1_reg_exc_flag;
                                p2_in_exp_r <= p1_reg_exp_r;
                                p2_in_s_r <= p1_reg_s_r;
                                p2_in_alu_r <= p1_alu_r;
                                p2_in_count <= count;
                                currentState <= done_s;
                            end if;
                        when done_s =>
                            currentState <= idle_s;
                    end case;
                end if;
            end if;
    end process;

    -- STAGE 2
    process (clk, reset) is
        begin
            if (reset = '0') then
                -- p2 register
                p2_out_exc_res <= (others => '0');
                p2_out_exc_flag <= '1';
                p2_out_exp_r <= 0;
                p2_out_s_r <= '0';
                p2_out_alu_r <= (others => '0');
                p2_out_count <= 0;
            elsif ((rising_edge(clk)) and (currentState = done_s))  then
                -- p2 register
                p2_out_exc_res <= p2_in_exc_res;
                p2_out_exc_flag <= p2_in_exc_flag;
                p2_out_exp_r <= p2_in_exp_r;
                p2_out_s_r <= p2_in_s_r;
                p2_out_alu_r <= p2_in_alu_r;
                p2_out_count <= p2_in_count;
                -- p3 register
                p3_reg_result_s3 <= result_s3;
            end if;
    end process;

    -- STAGE 3
    process(p2_out_exc_res, p2_out_exc_flag, p2_out_exp_r, p2_out_s_r, p2_out_alu_r, p2_out_count) is
        variable p2_alu_r: std_logic_vector(17 downto 0) ;
        begin
            p2_alu_r := p2_out_alu_r;
            -- Perform correct allignment
            p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 7-p2_out_count));

            -- Generate final result in bfloat 16 format
            if (p2_out_exc_flag = '1') then
                result_s3 <= p2_out_exc_res;
            elsif ((p2_out_exp_r > 127) and (p2_out_s_r = '0')) then
                result_s3 <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p2_out_exp_r > 127) and (p2_out_s_r = '1')) then
                result_s3 <= "1111111110000000"; -- overflow, result = -inf
            elsif (p2_out_exp_r < (-126)) then
                result_s3 <= "0000000000000000"; -- underflow, result = zero
            else
                result_s3(15) <= p2_out_s_r;
                result_s3(14 downto 7) <= std_logic_vector(to_unsigned(p2_out_exp_r + 127,8));
                result_s3(6 downto 0) <= p2_alu_r(6 downto 0);
            end if;
    end process;

    result <= p3_reg_result_s3;
end architecture;   
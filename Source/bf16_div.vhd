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
    signal p1_in_alu_in2 : std_logic_vector(7 downto 0);
    signal p1_in_alu_r: std_logic_vector(18 downto 0);
    signal p1_in_exc_res: std_logic_vector(15 downto 0);
    signal p1_in_exc_flag: std_logic;
    signal p1_in_s_r: std_logic;
    signal p1_in_exp_r: integer range -254 to 255 ;

    signal p1_out_alu_in2 : std_logic_vector(7 downto 0);
    signal p1_out_alu_r: std_logic_vector(18 downto 0);
    signal p1_out_exc_res: std_logic_vector(15 downto 0);
    signal p1_out_exc_flag: std_logic;
    signal p1_out_s_r: std_logic;
    signal p1_out_exp_r: integer range -254 to 255 ;

    -- p2 register
    signal p2_in_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_in_exc_flag: std_logic ;
    signal p2_in_exp_r: integer range -254 to 255 ;
    signal p2_in_s_r: std_logic ;
    signal p2_in_alu_r: std_logic_vector(18 downto 0) ;
    signal p2_in_count: integer range 0 to 8 ;

    signal p2_out_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_out_exc_flag: std_logic ;
    signal p2_out_exp_r: integer range -254 to 255 ;
    signal p2_out_s_r: std_logic ;
    signal p2_out_alu_r: std_logic_vector(18 downto 0) ;
    signal p2_out_count: integer range 0 to 8 ;

    type myState is (idle_s, busy_s, done_s);
    signal currentState : myState; -- state of the FSM
begin
    p_reg: process (clk, reset) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_out_alu_in2 <= (others => '0');
                p1_out_alu_r <= (others => '0');
                p1_out_exc_res <= (others => '0');
                p1_out_exc_flag <= '1';
                p1_out_s_r <= '0';
                p1_out_exp_r <= 0;
                -- p2 register
                p2_out_exc_res <= (others => '0');
                p2_out_exc_flag <= '1';
                p2_out_exp_r <= 0;
                p2_out_s_r <= '0';
                p2_out_alu_r <= (others => '0');
                p2_out_count <= 0;
            elsif ((rising_edge(clk)) and (currentState = done_s))  then
                -- p1 register
                p1_out_alu_in2 <= p1_in_alu_in2;
                p1_out_alu_r <= p1_in_alu_r;
                p1_out_exc_res <= p1_in_exc_res;
                p1_out_exc_flag <= p1_in_exc_flag;
                p1_out_s_r <= p1_in_s_r;
                p1_out_exp_r <= p1_in_exp_r;
                -- p2 register
                p2_out_exc_res <= p2_in_exc_res;
                p2_out_exc_flag <= p2_in_exc_flag;
                p2_out_exp_r <= p2_in_exp_r;
                p2_out_s_r <= p2_in_s_r;
                p2_out_alu_r <= p2_in_alu_r;
                p2_out_count <= p2_in_count;
            end if;
    end process p_reg;

    stage_1: process(in1, in2) is
        variable exp_1: integer range -254 to 255 ; -- exponent
        variable alu_in1: std_logic_vector(7 downto 0); -- operand

        variable exp_2: integer range -254 to 255 ; -- exponent
        variable alu_in2: std_logic_vector(7 downto 0); -- operand

        variable alu_r: std_logic_vector(18 downto 0); -- result
        -- 19 bits: 
        -- 9 bits to shift dividend when it is smaller then divisor
        -- 8 bits for the mantissa with 1 extra bit to shift in case mantissa is not normalized
        -- 1 extra bit for rounding correctly

        variable s_r: std_logic;  -- result sign
        variable exp_r: integer range -254 to 255 ; -- exponent
        variable exc_res: std_logic_vector(15 downto 0); -- result of exception
        variable exc_flag: std_logic ; -- exception flag

        begin

        exp_1 := to_integer(unsigned(in1(14 downto 7)));
        exp_2 := to_integer(unsigned(in2(14 downto 7)));

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

        -- handle normal
        else
            exc_flag := '0';
            -- Prepare operands
            alu_in1 := '1' & in1(6 downto 0);
            alu_in2 := '1' & in2(6 downto 0);

            exp_r := exp_1 - exp_2;

            -- adjust result sign
            s_r := in1(15) xor in2(15);

            -- detect overflow/underflow
            exc_flag := '1';
            if ((exp_r > 127) and (s_r = '0')) then
                exc_res := "0111111110000000"; -- +inf
            elsif ((exp_r > 127) and (s_r = '1')) then
                exc_res := "1111111110000000"; -- -inf
            elsif (exp_r < (-126)) then
                exc_res := "0000000000000000"; -- zero
            else
                exc_flag := '0';
            end if;
        end if;

        -- start operation

        alu_r :=  (others => '0');
        -- divide the mantissas through multiple subtractions
        -- we start with one iteration to check how many subtractions to perform
        if (exc_flag = '0') then
            if (unsigned(alu_in2) <= unsigned(alu_in1)) then
                alu_r(17 downto 10):= std_logic_vector(unsigned(alu_in1) - unsigned(alu_in2));
                alu_r(0):= '1';
            else
                -- the bit representing the "integral" part is 0
                -- we need to shift left once and adjust exponent
                -- this allows us to perform one more subtraction to get more precision
                alu_in1 := std_logic_vector(shift_left(unsigned(alu_in1), 1));
                alu_r(17 downto 10):= std_logic_vector(unsigned(alu_in1) - unsigned(alu_in2));
                alu_r(0):= '1';
                exp_r := exp_r - 1;
            end if;
        end if;

        p1_in_alu_in2 <= alu_in2;
        p1_in_exp_r <= exp_r;
        p1_in_alu_r <= alu_r;
        p1_in_exc_res <= exc_res;
        p1_in_exc_flag <= exc_flag;
        p1_in_s_r <= s_r;
    end process stage_1;

    stage_2: process(clk, reset, p1_out_alu_in2, p1_out_exp_r, p1_out_alu_r, p1_out_exc_res, p1_out_exc_flag, p1_out_s_r) is
        variable count: integer range 0 to 8 ;
        variable p1_alu_in2: std_logic_vector(7 downto 0) ;
        variable p1_alu_r: std_logic_vector(18 downto 0);
        begin

            if (rising_edge(clk)) then
                if (reset = '0') then
                    currentState <= idle_s;
                else
                    case currentState is
                        when idle_s =>
                            count := 0;
                            p1_alu_in2 := p1_out_alu_in2;
                            p1_alu_r := p1_out_alu_r;
                            currentState <= busy_s;
                        when busy_s =>
                            if (unsigned(p1_alu_in2) > unsigned(p1_alu_r(18 downto 10))) and (p1_alu_r(18 downto 10) /= "000000000") and (count < 8) then
                                p1_alu_r := std_logic_vector(shift_left(unsigned(p1_alu_r), 1));

                                if (unsigned(p1_alu_in2) <= unsigned(p1_alu_r(18 downto 10))) then
                                    p1_alu_r(18 downto 10):= std_logic_vector(unsigned(p1_alu_r(18 downto 10)) - unsigned(p1_alu_in2));
                                    p1_alu_r(0):= '1';
                                end if;
                                count := count + 1;
                                currentState <= busy_s;
                            else
                                p2_in_exc_res <= p1_out_exc_res;
                                p2_in_exc_flag <= p1_out_exc_flag;
                                p2_in_exp_r <= p1_out_exp_r;
                                p2_in_s_r <= p1_out_s_r;
                                p2_in_alu_r <= p1_alu_r;
                                p2_in_count <= count;
                                currentState <= done_s;
                            end if;
                        when done_s =>
                            currentState <= idle_s;
                    end case;
                end if;
            end if;
    end process stage_2;

    stage_3: process(p2_out_exc_res, p2_out_exc_flag, p2_out_exp_r, p2_out_s_r, p2_out_alu_r, p2_out_count) is
        variable p2_alu_r: std_logic_vector(18 downto 0) ;
        variable expo: integer range -254 to 255 ; -- exponent
        begin
            p2_alu_r := p2_out_alu_r;
            expo := p2_out_exp_r;
            -- Perform correct allignment
            p2_alu_r := std_logic_vector(shift_left(unsigned(p2_alu_r), 8-p2_out_count));

            if (p2_alu_r(0) = '1') then
                p2_alu_r(7 downto 1) := std_logic_vector(unsigned(p2_alu_r(7 downto 1))+1);
                if (p2_alu_r(7 downto 1) = "0000000") then
                    expo := expo + 1;
                end if;
            end if;


            -- Generate final result in bfloat 16 format
            if (p2_out_exc_flag = '1') then
                result <= p2_out_exc_res;
            elsif ((expo = 255) and (p2_out_s_r = '0')) then
                result <= "0111111110000000"; -- overflow, result = +inf
            elsif ((expo = 255) and (p2_out_s_r = '1')) then
                result <= "1111111110000000"; -- overflow, result = -inf
            elsif (expo < (-126)) then
                result <= "0000000000000000"; -- underflow, result = zero
            else
                result(15) <= p2_out_s_r;
                result(14 downto 7) <= std_logic_vector(to_unsigned(expo + 127,8));
                result(6 downto 0) <= p2_alu_r(7 downto 1);
            end if;
    end process stage_3;
end architecture;   
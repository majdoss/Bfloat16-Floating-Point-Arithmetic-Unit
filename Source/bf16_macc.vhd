library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_macc is
    generic (G : integer := 3);
    port(
        clk: in std_logic;
        reset: in std_logic;
        start: in std_logic; -- needs to be pulsed for 1CC to start accumulation
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_macc;

architecture rtl of bf16_macc is

    signal guard: std_logic_vector(G-1 downto 0) ;
    
    -- p1 register
    signal p1_reg_exp_rm: integer ;
    signal p1_reg_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_reg_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p1_reg_s_rm: std_logic;
    signal p1_reg_exc_flag: std_logic;
    signal p1_reg_start: std_logic;

    -- p2 register
    signal p2_reg_alu_rm: std_logic_vector(G+15 downto 0) ;
    signal p2_reg_exp_rm: integer ;
    signal p2_reg_s_rm: std_logic;
    signal p2_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p2_reg_exc_flag: std_logic;
    signal p2_reg_start: std_logic;

    -- p3 register
    signal p3_reg_exp_rm: integer ;
    signal p3_reg_exc_res: std_logic_vector(15 downto 0) ;
    signal p3_reg_exc_flag: std_logic;
    signal p3_reg_s_r: std_logic;
    signal p3_reg_alu_r: std_logic_vector(G+15 downto 0) ;
    signal p3_reg_cancel_flag: std_logic;

    signal result_acc: std_logic_vector(G+15 downto 0) ;
    signal result_s4: std_logic_vector(15 downto 0) ; -- final result
    signal p4_reg_result: std_logic_vector(15 downto 0) ;

    -- STAGE 1
    signal exp_1: integer ; -- exponent 1
    signal exp_2: integer ; -- exponent 2
    signal alu_in1: std_logic_vector(7 downto 0) ; -- operand 1
    signal alu_in2: std_logic_vector(7 downto 0) ; -- operand 2
    signal s_rm: std_logic ;  -- multiplication result sign

    -- STAGE 3
    signal in_acc: std_logic_vector(G+15 downto 0) ;
    
    attribute use_dsp: string;
    attribute use_dsp of p1_reg_alu_in1: signal is "yes";
    attribute use_dsp of p1_reg_alu_in2: signal is "yes";
    attribute use_dsp of p2_reg_alu_rm: signal is "yes";

    component acc is
        generic (G : integer := 3);
        port(
            clk: in std_logic;
            reset: in std_logic;
            start: in std_logic;
            in_acc: in std_logic_vector(G+15 downto 0) ; -- typically this is a product
            result: out std_logic_vector(G+15 downto 0)
        );
    end component;
begin
    guard <= (others => '0');
    
    -- pipeline registers
    process (clk, reset, exp_1, exp_2, alu_in1, alu_in2, s_rm) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_exp_rm <= 0;
                p1_reg_alu_in1 <= (others => '0');
                p1_reg_alu_in2 <= (others => '0');
                p1_reg_s_rm <= '0';
                p1_reg_start <= '0';
                -- p2 register
                p2_reg_alu_rm <= (others => '0');
                p2_reg_exp_rm <= 0;
                p2_reg_s_rm <= '0';
                p2_reg_exc_res <= (others => '0');
                p2_reg_exc_flag <= '1';
                p2_reg_start <= '0';
                -- p3 register
                p3_reg_exp_rm <= 0;
                p3_reg_exc_res <= (others => '0');
                p3_reg_exc_flag <= '1';
                -- p4 register
                p4_reg_result <= result_s4;
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_exp_rm <= (exp_1 + exp_2)-127; -- compute multiplication result exponent
                p1_reg_alu_in1<= alu_in1;
                p1_reg_alu_in2<= alu_in2;
                p1_reg_s_rm <= s_rm;
                p1_reg_start <= start;
                -- STAGE 2
                p2_reg_alu_rm <= guard & std_logic_vector(unsigned(p1_reg_alu_in1) * unsigned(p1_reg_alu_in2)); -- multiply operands
                p2_reg_exp_rm <= p1_reg_exp_rm;
                p2_reg_s_rm <= p1_reg_s_rm;
                p2_reg_exc_res <= p1_reg_exc_res;
                p2_reg_exc_flag <= p1_reg_exc_flag;
                p2_reg_start <= p1_reg_start;
                -- STAGE 3
                p3_reg_exp_rm <= p2_reg_exp_rm;
                p3_reg_exc_res <= p2_reg_exc_res;
                p3_reg_exc_flag <= p2_reg_exc_flag;
                -- STAGE 5
                p4_reg_result <= result_s4;
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
    process(clk, reset, in1, in2, exp_1, exp_2) is
        variable exc_flag: std_logic;
        variable exc_res: std_logic_vector(15 downto 0) ;
        begin
            -- Handle exceptions: NaN and infinity
            exc_flag:= '1';
            
            -- handle NaN and infinity
            if ((exp_1 = 255) or (exp_2 = 255)) then
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
    process(p2_reg_alu_rm, p2_reg_s_rm) is
        begin
            if ( p2_reg_s_rm = '1') then
                in_acc <= std_logic_vector(-signed(p2_reg_alu_rm));
            else
                in_acc <= p2_reg_alu_rm;
            end if;
    end process;
                
    acc1: acc port map (clk => clk, reset => reset, start => p2_reg_start, in_acc => in_acc, result => result_acc);

    process(clk, reset, result_acc, guard) is
        variable cancel_flag: std_logic;
        variable s_r: std_logic;
        variable alu_r: std_logic_vector(G+15 downto 0) ;
        begin
            alu_r := result_acc;
            -- handle cancellation
            if (alu_r = (guard & "000000000000000")) then
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
                p3_reg_s_r <= '0';
                p3_reg_alu_r <= (others => '0');
                p3_reg_cancel_flag <= '0';
            elsif (rising_edge(clk)) then
                p3_reg_s_r <= s_r;
                p3_reg_alu_r <= alu_r;
                p3_reg_cancel_flag <= cancel_flag;
            end if;
    end process;

    -- STAGE 4
    process (p3_reg_cancel_flag, p3_reg_exp_rm, p3_reg_alu_r, p3_reg_exc_res, p3_reg_exc_flag, p3_reg_s_r) is
        variable p3_alu_r: std_logic_vector(G+15 downto 0) ;
        variable p3_exp_rm: integer ;
        begin
            -- Normalize mantissa and adjust exponent
            p3_alu_r := p3_reg_alu_r;
            p3_exp_rm := p3_reg_exp_rm;

            -- We have to make sure that the accumulation does not overflow beforehand
            if (p3_alu_r(17) = '1') then
                p3_exp_rm := p3_exp_rm + 3;
                p3_alu_r := std_logic_vector(shift_right(unsigned(p3_alu_r), 3));
            elsif (p3_alu_r(16) = '1') then
                p3_exp_rm := p3_exp_rm + 2;
                p3_alu_r := std_logic_vector(shift_right(unsigned(p3_alu_r), 2));
            elsif (p3_alu_r(15) = '1') then
                p3_exp_rm := p3_exp_rm + 1;
                p3_alu_r := std_logic_vector(shift_right(unsigned(p3_alu_r), 1));
            elsif (p3_alu_r(14) = '1') then
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 0));
            elsif (p3_alu_r(13) = '1') then
                p3_exp_rm := p3_exp_rm - 1;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 1));
            elsif (p3_alu_r(12) = '1') then
                p3_exp_rm := p3_exp_rm - 2;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 2));
            elsif (p3_alu_r(11) = '1') then
                p3_exp_rm := p3_exp_rm - 3;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 3));
            elsif (p3_alu_r(10) = '1') then
                p3_exp_rm := p3_exp_rm - 4;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 4));
            elsif (p3_alu_r(9) = '1') then
                p3_exp_rm := p3_exp_rm - 5;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 5));
            elsif (p3_alu_r(8) = '1') then
                p3_exp_rm := p3_exp_rm - 6;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 6));
            elsif (p3_alu_r(7) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 7));
            elsif (p3_alu_r(6) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 8));
            elsif (p3_alu_r(5) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 9));
            elsif (p3_alu_r(4) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 10));
            elsif (p3_alu_r(3) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 11));
            elsif (p3_alu_r(2) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 12));
            elsif (p3_alu_r(1) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 13));
            elsif (p3_alu_r(0) = '1') then
                p3_exp_rm := p3_exp_rm - 7;
                p3_alu_r := std_logic_vector(shift_left(unsigned(p3_alu_r), 14));
            end if;

            -- round to the nearest even
            if (p3_alu_r(6) = '1') then
                p3_alu_r(13 downto 7) := std_logic_vector(unsigned(p3_alu_r(13 downto 7))+1);
                -- Adjust exponent
                if (p3_alu_r(13 downto 7) = "0000000") then
                    p3_exp_rm := p3_exp_rm + 1;
                end if;
            end if;
            
            -- Generate final result in bfloat 16 format
            if (p3_reg_exc_flag = '1') then
                result_s4 <= p3_reg_exc_res;
            elsif (p3_reg_cancel_flag = '1') then
                result_s4 <= (others => '0');
            elsif ((p3_exp_rm >= 255) and (p3_reg_s_r = '0')) then
                result_s4 <= "0111111110000000"; -- overflow, result = +inf
            elsif ((p3_exp_rm >= 255) and (p3_reg_s_r = '1')) then
                result_s4 <= "1111111110000000"; -- overflow, result = -inf
            elsif (p3_exp_rm <= 0) then
                result_s4 <= "0000000000000000"; -- underflow, result = zero
            else
                result_s4(15) <= p3_reg_s_r;
                result_s4(14 downto 7) <= std_logic_vector(to_unsigned(p3_exp_rm,8));
                result_s4(6 downto 0) <= p3_alu_r(13 downto 7);
            end if;
    end process;

    result <= p4_reg_result;

end architecture;
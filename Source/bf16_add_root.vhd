library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_add_root is
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

        -- final result in bf16 format
        result: out std_logic_vector(15 downto 0)
    );
end bf16_add_root;

architecture rtl of bf16_add_root is
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

    -- p3 register
    signal p3_reg_exp_r: integer;
    signal p3_reg_exc_flag: std_logic;
    signal p3_reg_err_code: std_logic;
    signal p3_reg_alu_r: std_logic_vector(G+15 downto 0) ;
    signal p3_reg_s_r: std_logic;
    signal p3_reg_cancel_flag: std_logic;

    -- p4 register
    signal p4_reg_exc_flag: std_logic;
    signal p4_reg_err_code: std_logic;
    signal p4_reg_exp_r: integer;
    signal p4_reg_alu_r: std_logic_vector(G+15 downto 0) ;
    signal p4_reg_s_r: std_logic;
    signal p4_reg_cancel_flag: std_logic;

    signal p5_reg_result: std_logic_vector(15 downto 0) ;
    signal result_s5: std_logic_vector(15 downto 0) ;

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
        variable exp_s1: integer ; 
        variable exp_s2: integer ;
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
        variable cancel_flag: std_logic;
        begin
            v_exp := p2_reg_exp_r;
            alu_r := std_logic_vector(signed(p2_reg_alu_in2) + signed(p2_reg_alu_in1));

            -- handle cancellation
            if (alu_r = (guard & "0000000000000000")) then
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
                p3_reg_alu_r <= (others => '0');
                p3_reg_s_r <= '0';
                p3_reg_cancel_flag <= '0';
            elsif (rising_edge(clk)) then
                p3_reg_alu_r <= alu_r;
                p3_reg_s_r <= s_r;
                p3_reg_cancel_flag <= cancel_flag;
            end if;
    end process;

    -- STAGE 4
    process (clk, reset, p3_reg_alu_r, p3_reg_exp_r) is
        variable v_alu_r: std_logic_vector(G+15 downto 0) ;
        variable v_exp_r: integer ;
        begin
            -- Normalize mantissa and adjust exponent
            v_alu_r := p3_reg_alu_r;
            v_exp_r := p3_reg_exp_r;

            --for i in G+14 downto 0 loop
                --v_exp_r := v_exp_r + (i-14);
                --if (i > 14) then
                    --if (v_alu_r(i) = '1') then
                        --v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), (i-14)));
                        --exit;
                    --end if;
                --else
                    --if (v_alu_r(i) = '1') then
                        --v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), -(i-14)));
                        --exit;
                    --end if;
                --end if;
            --end loop;

            if (v_alu_r(19) = '1') then
                v_exp_r := v_exp_r + 5;
                v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), 5));
            elsif (v_alu_r(18) = '1') then
                v_exp_r := v_exp_r + 4;
                v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), 4));
            elsif (v_alu_r(17) = '1') then
                v_exp_r := v_exp_r + 3;
                v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), 3));
            elsif (v_alu_r(16) = '1') then
                v_exp_r := v_exp_r + 2;
                v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), 2));
            elsif (v_alu_r(15) = '1') then
                v_exp_r := v_exp_r + 1;
                v_alu_r := std_logic_vector(shift_right(unsigned(v_alu_r), 1));
            elsif (v_alu_r(14) = '1') then
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 0));
            elsif (v_alu_r(13) = '1') then
                v_exp_r := v_exp_r - 1;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 1));
            elsif (v_alu_r(12) = '1') then
                v_exp_r := v_exp_r - 2;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 2));
            elsif (v_alu_r(11) = '1') then
                v_exp_r := v_exp_r - 3;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 3));
            elsif (v_alu_r(10) = '1') then
                v_exp_r := v_exp_r - 4;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 4));
            elsif (v_alu_r(9) = '1') then
                v_exp_r := v_exp_r - 5;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 5));
            elsif (v_alu_r(8) = '1') then
                v_exp_r := v_exp_r - 6;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 6));
            elsif (v_alu_r(7) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 7));
            elsif (v_alu_r(6) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 8));
            elsif (v_alu_r(5) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 9));
            elsif (v_alu_r(4) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 10));
            elsif (v_alu_r(3) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 11));
            elsif (v_alu_r(2) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 12));
            elsif (v_alu_r(1) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 13));
            elsif (v_alu_r(0) = '1') then
                v_exp_r := v_exp_r - 7;
                v_alu_r := std_logic_vector(shift_left(unsigned(v_alu_r), 14));
            end if;

            if (reset = '0') then
                p4_reg_alu_r <= (others => '0');
                p4_reg_exp_r <= 0;
            elsif (rising_edge(clk)) then
                p4_reg_alu_r <= v_alu_r;
                p4_reg_exp_r <= v_exp_r;
            end if;
    end process;

    -- STAGE 5
    process(p4_reg_alu_r, p4_reg_s_r, p4_reg_exp_r, p4_reg_exc_flag, p4_reg_err_code, p4_reg_cancel_flag) is
        variable v_alu_r: std_logic_vector(G+15 downto 0) ;
        variable v_exp_r: integer ;
        begin
            -- Normalize mantissa and adjust exponent
            v_alu_r := p4_reg_alu_r;
            v_exp_r := p4_reg_exp_r;

            -- round to the nearest even
            if (v_alu_r(6) = '1') then
                v_alu_r(13 downto 7) := std_logic_vector(unsigned(v_alu_r(13 downto 7))+1);
                -- Adjust exponent
                if (v_alu_r(13 downto 7) = "0000000") then
                    v_exp_r := v_exp_r + 1;
                end if;
            end if;
            
            -- Generate final result in bfloat 16 format
            if (p3_reg_exc_flag = '1') then
                if (p3_reg_err_code = '1') then
                    result_s5 <= p3_reg_s_r & "111111110000001"; -- NaN
                else
                    result_s5 <= p3_reg_s_r & "111111110000000"; -- +-inf
                end if;
            elsif (p3_reg_cancel_flag = '1') then
                result_s5 <= (others => '0');
            elsif ((v_exp_r > 381) and (p3_reg_s_r = '0')) then
                result_s5 <= "0111111110000000"; -- overflow, result_s5 = +inf
            elsif ((v_exp_r > 381) and (p3_reg_s_r = '1')) then
                result_s5 <= "1111111110000000"; -- overflow, result_s5 = -inf
            elsif (v_exp_r < 128) then
                result_s5 <= "0000000000000000"; -- underflow, result_s5 = zero
            else
                result_s5(15) <= p3_reg_s_r;
                result_s5(14 downto 7) <= std_logic_vector(to_unsigned(v_exp_r,8) - 127);
                result_s5(6 downto 0) <= v_alu_r(13 downto 7);
            end if;
    end process;

    result <= p5_reg_result;

    process (clk, reset, exp_1, exp_2, alu_in1, alu_in2, s_in1, s_in2, exc_flag, err_code, exp_r, result_s5) is
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
                p3_reg_exp_r <= 0;
                p3_reg_exc_flag <= '1';
                p3_reg_err_code <= '0';
                -- STAGE 4
                p4_reg_exc_flag <= '1';
                p4_reg_err_code <= '0';
                p4_reg_s_r <= '0';
                p4_reg_cancel_flag <= '0';
                -- STAGE 6
                p5_reg_result <= (others => '0');
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
                p3_reg_exp_r <= p2_reg_exp_r;
                p3_reg_exc_flag <= p2_reg_exc_flag;
                p3_reg_err_code <= p2_reg_err_code;
                -- STAGE 4
                p4_reg_exc_flag <= p3_reg_exc_flag;
                p4_reg_err_code <= p3_reg_err_code;
                p4_reg_s_r <= p3_reg_s_r;
                p4_reg_cancel_flag <= p3_reg_cancel_flag;
                -- STAGE 6
                p5_reg_result <= result_s5;
            end if;
    end process;
end architecture;   
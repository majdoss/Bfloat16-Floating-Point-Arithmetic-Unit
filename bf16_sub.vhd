library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_sub is
    port(
        in1: in std_logic_vector(15 downto 0) ;
        in2: in std_logic_vector(15 downto 0) ;
        result: out std_logic_vector(15 downto 0)
    );
end bf16_sub;

architecture rtl of bf16_sub is

begin
    process(in1, in2) is
        variable exp_1: integer range 0 to 255; -- exponent
        variable alu_in1: std_logic_vector(9 downto 0) ;
        -- 10 bits used as operand: 
        -- 1 sign bit, 1 guard bit, 1 implied one, 7 from significand

        variable exp_2: integer range 0 to 255; -- exponent
        variable alu_in2: std_logic_vector(9 downto 0) ;

        variable s_r: std_logic;  -- result sign
        variable exp_r: integer range 0 to 255; -- exponent
        variable alu_r: std_logic_vector(9 downto 0) ;

        variable count: integer range -7 to 1;

        begin
            -- Note that biased exponent/actual exponent notation is irrelevant for us
            -- We only use one notation (biased notation)
            exp_1 := to_integer(unsigned(in1(14 downto 7)));
            exp_2 := to_integer(unsigned(in2(14 downto 7)));

            -- First consider special cases: NaN, zero and infinity
            -- Denormalized numbers are flushed to zero

            -- handle zeros and denorms
            if ((exp_1 = 0) and (exp_2 /= 0)) then
                result <= in2;
            elsif ((exp_2 = 0) and (exp_1 /= 0)) then
                result <= in1;
            elsif ((exp_2 = 0) and (exp_1 = 0)) then
                result <= (others => '0');
            
            -- case where we subtract two inputs of same magnitude (result = 0)
            elsif ((in1(14 downto 0) = in2(14 downto 0)) and (in1(15) = in2(15))) then
                result <= (others => '0');
            
            -- handle NaN and infinity
            elsif ((exp_1 = 255) or (exp_2 = 255)) then
                if (((in1(6 downto 0)) /= "0000000") and (exp_1 = 255)) then
                    result <= in1;
                elsif (((in2(6 downto 0)) /= "0000000") and (exp_2 = 255)) then
                    result <= in2;
                else
                    if (exp_1 = 255) then
                        result <= in1;
                    else
                        result <= in2;
                    end if;
                end if;

            -- handle normal
            else
                -- Prepare operands
                alu_in1 := "001" & in1(6 downto 0);
                alu_in2 := "001" & in2(6 downto 0);

                if (exp_1 >= exp_2) then
                    -- Mantissa allignment
                    alu_in2 := std_logic_vector(shift_right(unsigned(alu_in2),(exp_1-exp_2)));
                    exp_r := exp_1;
                else
                    -- Mantissa allignment
                    alu_in1 := std_logic_vector(shift_right(unsigned(alu_in1),(exp_2-exp_1)));
                    exp_r := exp_2;
                end if;
                
                -- Express both operands in two's complement 
                if in1(15) = '1' then
                    alu_in1 := std_logic_vector(-signed(alu_in1));
                else
                    alu_in1 := std_logic_vector(signed(alu_in1));
                end if;

                if in2(15) = '1' then
                    alu_in2 := std_logic_vector(-signed(alu_in2));
                else
                    alu_in2 := std_logic_vector(signed(alu_in2));
                end if;

                -- Subtract the operands
                alu_r := std_logic_vector(signed(alu_in1) - signed(alu_in2));
                
                -- Set result sign bit and express result as a magnitude
                s_r := '0';
                if ((signed(alu_r)) < 0) then
                    s_r := '1';
                    alu_r := std_logic_vector(-signed(alu_r));
                end if;

                -- Normalize mantissa and adjust exponent
                count := 1;  
                while ((alu_r(8) /= '1') and (count > -7)) loop
                    alu_r := std_logic_vector(shift_left(unsigned(alu_r), 1));
                    count := count - 1;
                end loop;
                
                -- Shift right once to get correct allignment
                -- In case of overflow, we will skip the while loop and only shift right once
                alu_r := std_logic_vector(shift_right(unsigned(alu_r), 1));
                -- Adjust exponent
                exp_r := exp_r + count;
                
                -- Generate final result in bfloat 16 format
                result(15) <= s_r;
                result(14 downto 7) <= std_logic_vector(to_unsigned(exp_r,8));
                result(6 downto 0) <= alu_r(6 downto 0);
            end if;
    end process;
end architecture;   


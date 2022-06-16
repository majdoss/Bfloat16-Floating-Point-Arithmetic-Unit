library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bf16_mult_leaf is
    generic (G : integer := 5);
    port(
        clk: in std_logic;
        reset: in std_logic;
        in1: in std_logic_vector(15 downto 0) ; -- in bf16 format
        in2: in std_logic_vector(15 downto 0) ; -- in bf16 format
        out_alu_m: out std_logic_vector(G+15 downto 0) ; -- mult result
        out_exp_m: out integer ; -- mult result exponent
        out_s_m: out std_logic; -- mult result sign 
        out_exc_flag: out std_logic; -- exception flag
        out_err_code: out std_logic -- indicates if NaN or Infinity
    );
end bf16_mult_leaf;

architecture rtl of bf16_mult_leaf is
    -- p1 register
    signal p1_reg_exp_m: integer ;
    signal p1_reg_alu_in1: std_logic_vector(7 downto 0) ;
    signal p1_reg_alu_in2: std_logic_vector(7 downto 0) ;
    signal p1_reg_s_m: std_logic;
    signal p1_reg_exc_flag: std_logic;
    signal p1_reg_err_code: std_logic;

    -- STAGE 1
    -- signal alu_m: std_logic_vector(G+15 downto 0);
    signal exp_1: integer range 0 to 255 ;
    signal exp_2: integer range 0 to 255 ;
    signal alu_in1: std_logic_vector(7 downto 0) ;
    signal alu_in2: std_logic_vector(7 downto 0) ; 
    signal s_m: std_logic ;  -- multiplication result sign

    signal guard: std_logic_vector(G-1 downto 0);
    signal s_alu_m: std_logic_vector(15 downto 0);

    attribute use_dsp: string;
    --attribute use_dsp of p1_reg_alu_in1: signal is "yes";
    --attribute use_dsp of p1_reg_alu_in2: signal is "yes";
    attribute use_dsp of s_alu_m: signal is "yes";

begin
    guard <= (others => '0');

    -- STAGE 1
    process (in1, in2) is
        begin
            if ((in1(14 downto 7) = "00000000") or (in2(14 downto 7) = "00000000")) then
                -- handle zeros and denorms
                -- Denormalized numbers are flushed to zero
                exp_1 <= 0;
                exp_2 <= 0;
                alu_in1 <= (others => '0');
                alu_in2 <= (others => '0');
                s_m <= '0';
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
                s_m <= in1(15) xor in2(15);
            end if;
    end process;

    -- STAGE 1
    process(clk, reset, in1, in2, exp_1, exp_2) is
        variable exc_flag: std_logic;
        variable err_code: std_logic;
        begin
            -- Handle exceptions: NaN and infinity
            exc_flag:= '1';
            err_code := '0';
            -- handle NaN and infinity
            if ((exp_1 = 255) or (exp_2 = 255)) then
                if ( (((in1(6 downto 0)) /= "0000000") and (exp_1 = 255)) or (((in2(6 downto 0)) /= "0000000") and (exp_2 = 255))) then
                    err_code := '1';
                else
                    err_code := '0';
                end if;
            -- no exception
            else
                exc_flag:= '0';
            end if;

            if (reset = '0') then
                p1_reg_exc_flag <= '1';
                p1_reg_err_code <= '0';
            elsif (rising_edge(clk)) then
                p1_reg_exc_flag <= exc_flag;
                p1_reg_err_code <= err_code;
            end if;
    end process;

    process (clk, reset, exp_1, exp_2, alu_in1, alu_in2, s_m, p1_reg_exc_flag, p1_reg_err_code) is
        begin
            if (reset = '0') then
                -- p1 register
                p1_reg_exp_m <= 0;
                p1_reg_alu_in1 <= (others => '0');
                p1_reg_alu_in2 <= (others => '0');
                p1_reg_s_m <= '0';
                -- p2 register
                s_alu_m <= (others => '0');
                out_exp_m <= 0;
                out_s_m <= '0';
                out_err_code <= '0';
                out_exc_flag <= '1';
            elsif (rising_edge(clk)) then
                -- STAGE 1
                p1_reg_exp_m <= exp_1 + exp_2; -- prepare multiplication result exponent
                p1_reg_alu_in1 <= alu_in1;
                p1_reg_alu_in2 <= alu_in2;
                p1_reg_s_m <= s_m;
                -- STAGE 2
                s_alu_m <= std_logic_vector(unsigned(p1_reg_alu_in1) * unsigned(p1_reg_alu_in2)); -- multiply operands
                out_exp_m <= p1_reg_exp_m;
                out_s_m <= p1_reg_s_m;
                out_err_code <= p1_reg_err_code;
                out_exc_flag <= p1_reg_exc_flag;
            end if;
    end process;

    out_alu_m <= guard & s_alu_m;
end architecture;   
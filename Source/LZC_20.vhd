library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This Leading Zero Counter is inspired by this paper
-- Z. Milenković et al. “MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT”

entity LZC_20 is
    port(
        in_20: in std_logic_vector(19 downto 0);
        count: out std_logic_vector(4 downto 0)
    );
end LZC_20;

architecture rtl of LZC_20 is
    signal a0: std_logic;
    signal a1: std_logic;
    signal a2: std_logic;
    signal a3: std_logic;
    signal a4: std_logic;
    
    signal z0: std_logic_vector(1 downto 0);
    signal z1: std_logic_vector(1 downto 0);
    signal z2: std_logic_vector(1 downto 0);
    signal z3: std_logic_vector(1 downto 0);
    signal z4: std_logic_vector(1 downto 0);
    
    signal in_LZE: std_logic_vector(4 downto 0);
    signal MSBs: std_logic_vector(2 downto 0);

    component LZC_4 is
        port(
            in_4: in std_logic_vector(3 downto 0);
            count: out std_logic_vector(1 downto 0);
            a: out std_logic -- indicates that all bits are zeros
        );
    end component;

    component LZE_5 is
        port(
            in_a: in std_logic_vector(4 downto 0);
            count: out std_logic_vector(2 downto 0)
        );
    end component;
begin

    L0: LZC_4 port map (in_4 => in_20(19 downto 16), count => z0, a => a0);
    L1: LZC_4 port map (in_4 => in_20(15 downto 12), count => z1, a => a1);
    L2: LZC_4 port map (in_4 => in_20(11 downto 8), count => z2, a => a2);
    L3: LZC_4 port map (in_4 => in_20(7 downto 4), count => z3, a => a3);
    L4: LZC_4 port map (in_4 => in_20(3 downto 0), count => z4, a => a4);

    in_LZE <= a0 & a1 & a2 & a3 & a4;

    LZE: LZE_5 port map (in_a => in_LZE, count => MSBs);

    with MSBs select
        count(1 downto 0) <= z0 when "000",
                             z1 when "001",
                             z2 when "010",
                             z3 when "011",
                             z4 when "100",
                             (others => '0') when others;

    count(4 downto 2) <= MSBs;

end architecture;
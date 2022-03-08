library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- accumulator
-- it is the responsibility of the programer to make sure we don't overflow

entity acc is
    generic (G : integer := 3);
    port(
        clk: in std_logic;
        reset: in std_logic;
        start: in std_logic; -- needs to be pulsed for 1CC to start accumulation
        in_acc: in std_logic_vector(G+15 downto 0) ; -- typically this is a product
        result: out std_logic_vector(G+15 downto 0)
    );
end acc;

architecture rtl of acc is
    signal mux_res: std_logic_vector(G+15 downto 0) ;
    signal mux_acc: std_logic_vector(G+15 downto 0) ;
begin
    process(clk, reset, in_acc, mux_res) is
        begin
            if (rising_edge(clk)) then
                if (reset = '0') then
                    mux_acc <= (others => '0');
                else
                    if (start = '1') then
                        mux_acc <= std_logic_vector(signed(in_acc));
                    else
                        mux_acc <= std_logic_vector(signed(mux_res) + signed(in_acc));
                    end if;
                end if;
            end if;
    end process;

    mux_res <= mux_acc;
    result <= mux_acc;

end architecture;
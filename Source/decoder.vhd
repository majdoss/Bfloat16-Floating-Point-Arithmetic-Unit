library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    port(
        in1: in std_logic_vector(15 downto 0);
        in2: in std_logic_vector(15 downto 0);
        in3: in std_logic_vector(15 downto 0);
        funct5: in std_logic_vector(4 downto 0);
        out1: out std_logic_vector(15 downto 0);
        out2: out std_logic_vector(15 downto 0);
        out3: out std_logic_vector(15 downto 0)
    );
end decoder;

architecture rtl of decoder is

begin
    process(in1, in2, in3, funct5)
        begin
            case funct5 is
                when "00000"|"00001" =>
                    out1 <= in1;
                    out2 <= "0011111110000000";
                    out3 <= in2;
                when "00010" =>
                    out1 <= in1;
                    out2 <= in2;
                    out3 <= "0000000000000000";
                when "00100"|"00101" =>
                    out1 <= in1;
                    out2 <= in2;
                    out3 <= in3;
                when others =>
                    out1 <= "0000000000000000";
                    out2 <= "0000000000000000";
                    out3 <= "0000000000000000";
            end case;
    end process;

end architecture;
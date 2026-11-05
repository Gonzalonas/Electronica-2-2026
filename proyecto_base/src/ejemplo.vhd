library ieee;
use ieee.std_logic_1164.all;

entity ejemplo is
    port(
        A : in std_logic;
        B : in std_logic;
        y : out std_logic
    );
end ejemplo;

architecture arch of ejemplo is
begin
    y <= A AND B;
end arch;

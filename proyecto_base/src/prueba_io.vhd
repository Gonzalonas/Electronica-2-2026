library ieee;
use ieee.std_logic_1164.all;

entity prueba_io is
    port(
        A : in std_logic_vector (7 downto 0);
        y : out std_logic_vector (7 downto 0)
    );
end prueba_io;

architecture arch of prueba_io is
begin
    y <= A;
end arch;

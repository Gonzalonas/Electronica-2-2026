library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity contador_4bit is
port(
reset : in std_logic;
hab : in std_logic;
carga : in std_logic;
clk : in std_logic;
valor : in std_logic_vector (3 downto 0);
cuenta : out std_logic_vector(3 downto 0)
);
end entity contador_4bit;

architecture arch of contador_4bit is
signal estado_actual : std_logic_vector(3 downto 0);
begin
process(clk)
begin
if rising_edge(clk) then
if reset = '1' then
estado_actual <= "0000";
elsif carga = '1' then
estado_actual <= valor;
elsif hab = '1' then
estado_actual <= std_logic_vector(unsigned(estado_actual) + 1);
else
estado_actual <= estado_actual;
end if;
end if;
end process;

Cuenta <= estado_actual;

end architecture arch;
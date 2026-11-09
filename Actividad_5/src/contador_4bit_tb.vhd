library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity contador_4bit_tb is
end entity contador_4bit_tb;

architecture arch of contador_4bit_tb is
component contador_4bit
port(
reset : in std_logic;
hab : in std_logic;
carga : in std_logic;
clk : in std_logic;
valor : in std_logic_vector(3 downto 0);
cuenta : out std_logic_vector(3 downto 0)
);
end component;

signal reset_tb : std_logic := '0';
signal hab_tb : std_logic := '0';
signal carga_tb : std_logic := '0';
signal clk_tb : std_logic := '0';
signal valor_tb : std_logic_vector(3 downto 0) := "0000";
signal cuenta_tb : std_logic_vector(3 downto 0);

constant periodo : time := 10 ns;
begin
conexiones : contador_4bit
port map(
reset => reset_tb,
hab => hab_tb,
carga => carga_tb,
clk => clk_tb,
valor => valor_tb,
cuenta => cuenta_tb
);

reloj_process : process
begin
clk_tb <= '0';
wait for periodo / 2;
clk_tb <= '1';
wait for periodo / 2;
end process;

estimulo : process
begin
reset_tb <= '1';
carga_tb <= '0';
hab_tb <= '0';
wait for periodo * 2;

reset_tb <= '0';
hab_tb <= '1';
carga_tb <= '0';

wait for periodo * 10;

carga_tb <= '1';
valor_tb <= "0111";
hab_tb <= '0';
wait for periodo;

wait for periodo * 5;

reset_tb <= '1';
carga_tb <= '0';
hab_tb <= '1';
wait for periodo * 2;

reset_tb <= '0';
hab_tb <= '1';
wait for periodo *5;

finish;
end process;

end architecture arch;
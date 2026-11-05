library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity ejemplo_tb is
end ejemplo_tb;

architecture tb of ejemplo_tb is
    signal A,B,y : std_logic;
begin
    DUT : entity ejemplo port map (A => A, B => B, y => y);
    stim : process is
    begin
        A <= '0';
        B <= '0';
        wait for 1 ns;
        B <= '1';
        wait for 1 ns;
        A <= '1';
        wait for 1 ns;
        B <= '0';
        wait for 1 ns;
        wait for 1 ns; -- Punto adicional para que se vea bien la forma de onda
        finish;
    end process;
end tb;

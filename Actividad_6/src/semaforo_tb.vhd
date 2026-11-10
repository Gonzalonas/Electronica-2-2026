library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity semaforo_tb is
end entity semaforo_tb;

architecture sim of semaforo_tb is

    -- Configuramos FCK = 2 para que 1 segundo equivalga a solo 2 ciclos de reloj en simulación
    constant FCK_SIM     : positive := 2;
    constant NP_SIM      : positive := 4;
    constant N_SIM       : positive := 7;
    constant PERIODO_CLK : time := 5 ns;
    constant UN_SEG      : time := PERIODO_CLK * FCK_SIM; -- 10 ns = 1 segundo simulado

    signal clk_tb   : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal p_ns_tb  : std_logic := '0';
    signal p_eo_tb  : std_logic := '0';
    signal e_ns_tb  : std_logic := '0';
    signal e_eo_tb  : std_logic := '0';
    signal l_ns_tb  : std_logic_vector(2 downto 0);
    signal l_eo_tb  : std_logic_vector(2 downto 0);

begin

    uut : entity work.semaforo
        generic map (
            FCK => FCK_SIM,
            NP  => NP_SIM,
            N   => N_SIM
        )
        port map (
            clk   => clk_tb,
            reset => reset_tb,
            p_ns  => p_ns_tb,
            p_eo  => p_eo_tb,
            e_ns  => e_ns_tb,
            e_eo  => e_eo_tb,
            l_ns  => l_ns_tb,
            l_eo  => l_eo_tb
        );

    -- Generación de reloj
    reloj_process : process
    begin
        clk_tb <= '0';
        wait for PERIODO_CLK / 2;
        clk_tb <= '1';
        wait for PERIODO_CLK / 2;
    end process;

    -- Proceso de estímulos
    estimulo : process
    begin
        -- 1. Pulso de Reset inicial (Arranca en RV con Q = 50)
        reset_tb <= '1';
        wait for 2 * PERIODO_CLK;
        reset_tb <= '0';

        
        -- CASO 1: Ciclo normal completo (50s RV -> 10s RA -> 50s VR -> 10s AR)
        
        --wait for 125 * UN_SEG;

        
        -- CASO 2: Cruce peatonal en Este-Oeste (RV -> RVEXT -> RA)
        
        -- Pulsamos P_EO mientras está en RV; S_EO se clava en '1' (estado PED)
        --p_eo_tb <= '1';
        --wait for 2 * UN_SEG;
        --p_eo_tb <= '0';

        -- Al terminar los primeros 50s de RV, pasa a RVEXT por otros 50s más
        -- y al pasar a RA activa RES_EO = '1' limpiando el bloque Cruce
       --wait for 115 * UN_SEG;

        
        -- CASO 3: Emergencia en Este-Oeste (E_EO = '1') mientras NS está en Verde (VR)
        
      
       
        reset_tb <= '1';
        wait for 3 * PERIODO_CLK;
        reset_tb <= '0';

        -- 1. Estamos en RV (EO en Verde, NS en Rojo).
        -- Esperamos 15 pulsos de zp y activamos emergencia en NS (E_NS = '1'):
       
        wait for 375 ns; 
        e_ns_tb <= '1';

        -- 2. Mantenemos E_NS = '1' durante 10s de amarillo + 65s de verde NS (retención > 50s)
        wait for 1875 ns;
        e_ns_tb <= '0'; -- Recién al bajar E_NS, NS pasa a amarillo (010)

        wait for 500 ns;
        finish;
    end process;

end architecture sim;
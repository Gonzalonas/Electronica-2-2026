
-- 1. MÓDULO CRUCE (MEF de captura de pulsador peatonal: NPED -> PED)

library ieee;
use ieee.std_logic_1164.all;

entity cruce is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        p     : in  std_logic;
        s     : out std_logic
    );
end entity cruce;

architecture rtl of cruce is
    type estado_t is (NPED, PED);
    signal estado : estado_t := NPED;
begin
    -- Reemplaza el process de la entidad "cruce" por este:
    process(clk, reset)
    begin
        if reset = '1' then
            estado <= NPED;
        elsif rising_edge(clk) then
            case estado is
                when NPED =>
                    if p = '1' then
                        estado <= PED;
                    end if;
                when PED =>
                    estado <= PED;
            end case;
        end if;
    end process;

    s <= '1' when estado = PED else '0';
end architecture rtl;


-- 2. MÓDULO MEF TEMPORIZADOR (Sirve para el Temporizador y para el Prescaler)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mef_temporizador is
    generic (
        N : positive := 7
    );
    port (
        clk : in  std_logic;
        c   : in  std_logic;                    -- Señal de carga sincrónica
        hab : in  std_logic;                    -- Habilitación de descuento
        q   : in  std_logic_vector(N-1 downto 0); -- Valor a cargar
        z   : out std_logic                     -- Bandera de fin de cuenta (cero)
    );
end entity mef_temporizador;

architecture rtl of mef_temporizador is
    signal cuenta : unsigned(N-1 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if c = '1' then
                cuenta <= unsigned(q);
            elsif hab = '1' then
                if cuenta > 0 then
                    cuenta <= cuenta - 1;
                end if;
            end if;
        end if;
    end process;

    z <= '1' when cuenta = 0 else '0';
end architecture rtl;


-- 3. MÓDULO CONTROL (MEF Principal de 6 estados: RV, RVEXT, RA, VR, VREXT, AR)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
    generic (
        N : positive := 7
    );
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        s_ns   : in  std_logic;
        s_eo   : in  std_logic;
        e_ns   : in  std_logic;
        e_eo   : in  std_logic;
        z      : in  std_logic;
        l_ns   : out std_logic_vector(2 downto 0); -- "100"=R, "010"=A, "001"=V
        l_eo   : out std_logic_vector(2 downto 0); -- "100"=R, "010"=A, "001"=V
        c      : out std_logic;
        q      : out std_logic_vector(N-1 downto 0);
        res_ns : out std_logic;
        res_eo : out std_logic
    );
end entity control;

architecture rtl of control is
    -- Estados según el diagrama: 1ra letra = NS, 2da letra = EO
    type estado_t is (RV, RVEXT, RA, VR, VREXT, AR);
    signal estado_act, estado_sig : estado_t := RV;

    -- Codificación one-hot de 3 bits (Nl = 3) para las luces de cada calle
    constant LUZ_R : std_logic_vector(2 downto 0) := "100"; -- Rojo
    constant LUZ_A : std_logic_vector(2 downto 0) := "010"; -- Amarillo
    constant LUZ_V : std_logic_vector(2 downto 0) := "001"; -- Verde
begin

    -- Registro de estado (con inicialización en RV y precarga de Q=50 en Reset)
    reg_estado : process(clk, reset)
    begin
        if reset = '1' then
            estado_act <= RV;
        elsif rising_edge(clk) then
            estado_act <= estado_sig;
        end if;
    end process;

    -- Lógica de estado siguiente y salidas (Mealy)
    logica_mealy : process(estado_act, reset, s_ns, s_eo, e_ns, e_eo, z)
    begin
        -- Valores por defecto especificados en el diagrama
        estado_sig <= estado_act;
        c          <= '0';
        q          <= (others => '0');
        res_eo     <= '0';
        res_ns     <= '0';
        l_ns       <= LUZ_R;
        l_eo       <= LUZ_V;

        if reset = '1' then
            estado_sig <= RV;
            c          <= '1';
            q          <= std_logic_vector(to_unsigned(50, N));
            l_ns       <= LUZ_R;
            l_eo       <= LUZ_V;
            res_eo     <= '1';
            res_ns     <= '1';
        else
            case estado_act is

                
                -- Estado RV: Norte-Sur en Rojo, Este-Oeste en Verde (50 s)
                
                when RV =>
                    l_ns <= LUZ_R;
                    l_eo <= LUZ_V;
                    if (z = '1' or e_ns = '1') and e_eo = '0' then
                        if s_eo = '1' then
                            -- (Z + E_NS) * S_EO * /E_EO -> Pasa a RVEXT
                            estado_sig <= RVEXT;
                            c          <= '1';
                            q          <= std_logic_vector(to_unsigned(50, N));
                            l_ns       <= LUZ_R;
                            l_eo       <= LUZ_V;
                        else
                            -- (Z + E_NS) * /S_EO * /E_EO -> Pasa a RA
                            estado_sig <= RA;
                            c          <= '1';
                            q          <= std_logic_vector(to_unsigned(10, N));
                            l_ns       <= LUZ_R;
                            l_eo       <= LUZ_V;
                        end if;
                    end if;

                
                -- Estado RVEXT: Extensión de Verde Este-Oeste por cruce peatonal
                
                when RVEXT =>
                    l_ns <= LUZ_R;
                    l_eo <= LUZ_V;

                    -- Transición a RA: Z * /E_EO
                    if (z = '1' and e_eo = '0') then
                        estado_sig <= RA;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(10, N));
                        l_ns       <= LUZ_R;
                        l_eo       <= LUZ_A;
                        res_eo     <= '1';
                    
                    end if;

                
                -- Estado RA: Norte-Sur en Rojo, Este-Oeste en Amarillo (10 s)
                
                when RA =>
                    l_ns <= LUZ_R;
                    l_eo <= LUZ_A;

                    -- Si aparece emergencia en EO durante amarillo, vuelve a RVEXT/Verde
                    if (e_eo = '1') then
                        estado_sig <= RVEXT;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(50, N));
                        l_ns       <= LUZ_R;
                        l_eo       <= LUZ_V;
                    -- Fin de amarillo: Z * /E_EO -> Pasa a VR
                    elsif (z = '1' and e_eo = '0') then
                        estado_sig <= VR;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(50, N));
                        l_ns       <= LUZ_V;
                        l_eo       <= LUZ_R;
                  
                    end if;

                
                -- Estado VR: Norte-Sur en Verde, Este-Oeste en Rojo (50 s)
                
                when VR =>
                    l_ns <= LUZ_V;
                    l_eo <= LUZ_R;
                    if (z = '1' or e_eo = '1') and e_ns = '0' then
                        if s_ns = '1' then
                            -- (Z + E_EO) * S_NS * /E_NS -> Pasa a VREXT
                            estado_sig <= VREXT;
                            c          <= '1';
                            q          <= std_logic_vector(to_unsigned(50, N));
                            l_ns       <= LUZ_V;
                            l_eo       <= LUZ_R;
                        else
                            -- (Z + E_EO) * /S_NS * /E_NS -> Pasa a AR
                            estado_sig <= AR;
                            c          <= '1';
                            q          <= std_logic_vector(to_unsigned(10, N));
                            l_ns       <= LUZ_A;
                            l_eo       <= LUZ_R;
                        end if;
                    end if;

                
                -- Estado VREXT: Extensión de Verde Norte-Sur por cruce peatonal
                
                when VREXT =>
                    l_ns <= LUZ_V;
                    l_eo <= LUZ_R;

                    -- Transición a AR: Z * /E_NS
                    if (z = '1' and e_ns = '0') then
                        estado_sig <= AR;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(10, N));
                        l_ns       <= LUZ_A;
                        l_eo       <= LUZ_R;
                        res_ns     <= '1';
                    
                    end if;

                
                -- Estado AR: Norte-Sur en Amarillo, Este-Oeste en Rojo (10 s)
                
                when AR =>
                    l_ns <= LUZ_A;
                    l_eo <= LUZ_R;

                    -- Si aparece emergencia en NS durante amarillo, vuelve a VREXT/Verde
                    if (e_ns = '1') then
                        estado_sig <= VREXT;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(50, N));
                        l_ns       <= LUZ_V;
                        l_eo       <= LUZ_R;
                    -- Fin de amarillo: Z * /E_NS -> Pasa a RV
                    elsif (z = '1' and e_ns = '0') then
                        estado_sig <= RV;
                        c          <= '1';
                        q          <= std_logic_vector(to_unsigned(50, N));
                        l_ns       <= LUZ_R;
                        l_eo       <= LUZ_V;
                    
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;


-- 4. ENTIDAD TOP-LEVEL: INTERCONEXIÓN SEGÚN EL DIAGRAMA DE BLOQUES

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity semaforo is
    generic (
        FCK : positive := 2; -- Frecuencia de reloj (ej. 10 Hz para simulación rápida)
        NP  : positive := 4;  -- Bits del prescaler
        N   : positive := 7   -- Bits del temporizador (hasta 50 s)
    );
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        p_ns  : in  std_logic;
        p_eo  : in  std_logic;
        e_ns  : in  std_logic;
        e_eo  : in  std_logic;
        l_ns  : out std_logic_vector(2 downto 0); -- [2]=Rojo, [1]=Amarillo, [0]=Verde
        l_eo  : out std_logic_vector(2 downto 0)  -- [2]=Rojo, [1]=Amarillo, [0]=Verde
    );
end entity semaforo;

architecture estructural of semaforo is

    -- Señales internas para la interconexión de los bloques
    signal s_ns, s_eo     : std_logic;
    signal res_ns, res_eo : std_logic;
    signal c, z           : std_logic;
    signal q              : std_logic_vector(N-1 downto 0);
    signal cp, zp         : std_logic;
    signal qp             : std_logic_vector(NP-1 downto 0);

    -- Reinicio combinado para los bloques "Cruce" (reset global o confirmación del control)
    signal reset_cruce_ns : std_logic;
    signal reset_cruce_eo : std_logic;

begin

    reset_cruce_ns <= reset or res_ns;
    reset_cruce_eo <= reset or res_eo;

    -- Instancia Cruce Norte-Sur
    u_cruce_ns : entity work.cruce
        port map (
            clk   => clk,
            reset => reset_cruce_ns,
            p     => p_ns,
            s     => s_ns
        );

    -- Instancia Cruce Este-Oeste
    u_cruce_eo : entity work.cruce
        port map (
            clk   => clk,
            reset => reset_cruce_eo,
            p     => p_eo,
            s     => s_eo
        );

    -- Instancia Control Principal
    u_control : entity work.control
        generic map (
            N => N
        )
        port map (
            clk    => clk,
            reset  => reset,
            s_ns   => s_ns,
            s_eo   => s_eo,
            e_ns   => e_ns,
            e_eo   => e_eo,
            z      => z,
            l_ns   => l_ns,
            l_eo   => l_eo,
            c      => c,
            q      => q,
            res_ns => res_ns,
            res_eo => res_eo
        );

    -- Instancia MEF Temporizador (Segundos)
    u_temporizador : entity work.mef_temporizador
        generic map (
            N => N
        )
        port map (
            clk => clk,
            c   => c,
            hab => zp,
            q   => q,
            z   => z
        );

    -- Compuerta OR del diagrama para recargar el Prescaler: Cp = C OR Zp
    cp <= c or zp;

    -- Constante de entrada al prescaler: Qp = fck - 1
    qp <= std_logic_vector(to_unsigned(FCK - 1, NP));

    -- Instancia MEF Temporizador Prescaler
    u_prescaler : entity work.mef_temporizador
        generic map (
            N => NP
        )
        port map (
            clk => clk,
            c   => cp,
            hab => '1',
            q   => qp,
            z   => zp
        );

end architecture estructural;
-- ============================================================================
-- LIBRERÍAS
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all; -- Tipos lógicos estándar (std_logic, std_logic_vector)
use ieee.numeric_std.all;    -- Necesaria para convertir vectores a enteros en los mensajes de error

-- ============================================================================
-- ENTIDAD DEL BANCO DE PRUEBAS (TESTBENCH)
-- ============================================================================
-- Un testbench no tiene puertos (ni entradas ni salidas) porque es un entorno
-- cerrado de simulación: él mismo genera los estímulos y verifica los resultados.
entity alu_tb is
end entity alu_tb;

-- ============================================================================
-- ARQUITECTURA DE SIMULACIÓN
-- ============================================================================
architecture sim of alu_tb is
    -- Constante que define el ancho de bits con el que se va a probar la ALU (4 bits)
    constant W : positive := 4;

    -- Señales internas para conectarse a los puertos de la ALU.
    -- Las entradas se inicializan en cero para evitar estados indefinidos ('U') al arrancar.
    signal sel_fn : std_logic_vector(3 downto 0) := (others => '0');
    signal A      : std_logic_vector(W-1 downto 0) := (others => '0');
    signal B      : std_logic_vector(W-1 downto 0) := (others => '0');
    signal Y      : std_logic_vector(W-1 downto 0); -- Salida a observar
    signal Z      : std_logic;                      -- Salida a observar
begin

    -- ========================================================================
    -- INSTANCIACIÓN DEL DUT (Device Under Test / Dispositivo Bajo Prueba)
    -- ========================================================================
    -- Crea una instancia de la entidad "alu" compilada en la librería "work"
    -- y conecta sus parámetros (generic map) y puertos (port map) a las señales locales.
    dut : entity work.alu
        generic map (
            W => W -- Le pasa W = 4 a la ALU
        )
        port map (
            sel_fn => sel_fn,
            A      => A,
            B      => B,
            Y      => Y,
            Z      => Z
        );

    -- ========================================================================
    -- PROCESO DE ESTÍMULOS Y VERIFICACIÓN AUTOMÁTICA
    -- ========================================================================
    -- No tiene lista de sensibilidad porque se controla con sentencias "wait".
    stim_proc : process

        -- Procedimiento auxiliar para no repetir código en cada caso de prueba.
        -- Recibe las entradas (fn_in, a_in, b_in), los valores esperados (y_exp, z_exp)
        -- y un texto descriptivo (nombre) para identificar fácilmente qué prueba falló.
        procedure check_op(
            constant fn_in  : in std_logic_vector(3 downto 0);
            constant a_in   : in std_logic_vector(W-1 downto 0);
            constant b_in   : in std_logic_vector(W-1 downto 0);
            constant y_exp  : in std_logic_vector(W-1 downto 0);
            constant z_exp  : in std_logic;
            constant nombre : in string
        ) is
        begin
            -- 1. Aplica los valores de prueba a las entradas de la ALU
            sel_fn <= fn_in;
            A      <= a_in;
            B      <= b_in;

            -- 2. Espera 10 nanosegundos para que las señales se propaguen y la ALU calcule Y y Z
            wait for 10 ns;

            -- 3. Verifica que la salida Y coincida con la esperada.
            -- Si la condición (Y = y_exp) es FALSA, imprime el mensaje de error en consola.
            assert Y = y_exp
                report "FALLO [" & nombre & "] Y esperado=" &
                       integer'image(to_integer(unsigned(y_exp))) & -- Convierte a entero y luego a texto
                       ", obtenido=" &
                       integer'image(to_integer(unsigned(Y)))
                severity error;

            -- 4. Verifica que la bandera Z coincida con la esperada.
            assert Z = z_exp
                report "FALLO [" & nombre & "] Z esperado=" &
                       std_logic'image(z_exp) & -- Convierte el bit ('0' o '1') a texto
                       ", obtenido=" &
                       std_logic'image(Z)
                severity error;
        end procedure;

    begin
        -- ====================================================================
        -- BATERÍA DE PRUEBAS (Verifica todas las operaciones y la bandera Z)
        -- ====================================================================

        -- 0000: Suma (A + B)
        check_op("0000", "0010", "0101", "1000", '0', "ADD 2+5");
        check_op("0000", "1100", "0100", "0000", '1', "ADD overflow a 0"); -- 12+4=16 -> en 4 bits da 0, Z='1'

        -- 0001: Resta (A - B)
        check_op("0001", "0101", "0011", "0010", '0', "SUB 5-3");
        check_op("0001", "0111", "0111", "0000", '1', "SUB 7-7"); -- Resultado 0, Z='1'

        -- 001-: Desplazamiento lógico a la izquierda (prueba ambas variantes: 0010 y 0011)
        check_op("0010", "0011", "0010", "1100", '0', "SLL 3<<2 (sel=0010)");
        check_op("0011", "0011", "0100", "0000", '1', "SLL 3<<4 (sel=0011)"); -- Desplaza todo fuera, da 0

        -- 010-: Comparación menor que en Complemento a 2 (con signo)
        check_op("0100", "1111", "0001", "0001", '0', "SLT -1 < +1 (sel=0100)"); -- -1 < 1 es verdadero (1)
        check_op("0101", "0001", "1111", "0000", '1', "SLT +1 < -1 (sel=0101)"); -- 1 < -1 es falso (0)

        -- 011-: Comparación menor que en Binario natural (sin signo)
        check_op("0110", "1111", "0001", "0000", '1', "SLTU 15 < 1 (sel=0110)"); -- 15 < 1 es falso (0)
        check_op("0111", "0001", "1111", "0001", '0', "SLTU 1 < 15 (sel=0111)"); -- 1 < 15 es verdadero (1)

        -- 100-: XOR bit a bit
        check_op("1000", "1010", "1100", "0110", '0', "XOR (sel=1000)");
        check_op("1001", "1010", "1010", "0000", '1', "XOR igual (sel=1001)"); -- A xor A siempre es 0

        -- 1010: Desplazamiento lógico a la derecha (rellena con ceros)
        check_op("1010", "1000", "0010", "0010", '0', "SRL 8>>2");
        check_op("1010", "1000", "0100", "0000", '1', "SRL 8>>4");

        -- 1011: Desplazamiento aritmético a la derecha (conserva el bit de signo)
        check_op("1011", "1000", "0010", "1110", '0', "SRA -8>>2 = -2"); -- Negativo: rellena con '1'
        check_op("1011", "0100", "0010", "0001", '0', "SRA +4>>2 = +1"); -- Positivo: rellena con '0'
        check_op("1011", "0010", "0010", "0000", '1', "SRA +2>>2 = 0");

        -- 110-: OR bit a bit
        check_op("1100", "1010", "0101", "1111", '0', "OR (sel=1100)");
        check_op("1101", "0000", "0000", "0000", '1', "OR ceros (sel=1101)");

        -- 111-: AND bit a bit
        check_op("1110", "1011", "1101", "1001", '0', "AND (sel=1110)");
        check_op("1111", "1010", "0101", "0000", '1', "AND cero (sel=1111)");

        -- Mensaje informativo al terminar todas las pruebas
        report "Todas las pruebas de la ALU pasaron correctamente." severity note;

        -- Detiene el proceso indefinidamente para que no vuelva a empezar en bucle
        wait;
    end process;

end architecture sim;
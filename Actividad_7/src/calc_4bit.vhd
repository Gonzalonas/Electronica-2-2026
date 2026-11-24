library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_4bit is
    port (
        clk     : in  std_logic;                    -- Reloj de 12 MHz (pin 94)
        x       : in  std_logic_vector(7 downto 0); -- Panel de 8 interruptores
        display : out std_logic_vector(7 downto 0)  -- 7 segmentos + punto decimal (Z)
    );
end entity calc_4bit;

architecture rtl of calc_4bit is
    -- Registros de la calculadora
    signal reg_a : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_b : std_logic_vector(3 downto 0) := (others => '0');

    -- Salidas de la ALU
    signal alu_y : std_logic_vector(3 downto 0);
    signal alu_z : std_logic;

    -- Señal de 4 bits a mostrar en el display (A o B)
    signal hex_val : std_logic_vector(3 downto 0);
    signal seg_7   : std_logic_vector(6 downto 0);

    -- Sincronizador y antirrebote (~10 ms a 12 MHz = 120.000 ciclos) para x(6 downto 4)
    constant DEB_MAX : natural := 120000;
    signal deb_cnt   : natural range 0 to DEB_MAX := 0;
    signal sw_sync1  : std_logic_vector(2 downto 0) := (others => '0');
    signal sw_sync2  : std_logic_vector(2 downto 0) := (others => '0');
    signal sw_clean  : std_logic_vector(2 downto 0) := (others => '0');
    signal sw_prev   : std_logic_vector(2 downto 0) := (others => '0');
begin

    
    -- INSTANCIA DE LA ALU DE 4 BITS (Parte 1)
    
    u_alu : entity work.alu
        generic map (
            W => 4
        )
        port map (
            sel_fn => x(3 downto 0),
            A      => reg_a,
            B      => reg_b,
            Y      => alu_y,
            Z      => alu_z
        );

    
    -- REGISTROS SINCRÓNICOS Y DETECCIÓN DE FLANCO ASCENDENTE (12 MHz)
    
    process(clk)
    begin
        if rising_edge(clk) then
            -- Doble flip-flop para sincronizar entradas asíncronas x(6 downto 4)
            sw_sync1 <= x(6 downto 4);
            sw_sync2 <= sw_sync1;

            -- Muestreo cada ~10 ms para eliminar rebotes mecánicos
            if deb_cnt = DEB_MAX then
                deb_cnt  <= 0;
                sw_prev  <= sw_clean;
                sw_clean <= sw_sync2;
            else
                deb_cnt <= deb_cnt + 1;
            end if;

            -- Detección de flanco ascendente en los interruptores de control:
            -- x(4) -> sw_clean(0): A <- x(3 downto 0)
            if sw_clean(0) = '1' and sw_prev(0) = '0' and deb_cnt = 0 then
                reg_a <= x(3 downto 0);
            end if;

            -- x(5) -> sw_clean(1): B <- x(3 downto 0)
            if sw_clean(1) = '1' and sw_prev(1) = '0' and deb_cnt = 0 then
                reg_b <= x(3 downto 0);
            end if;

            -- x(6) -> sw_clean(2): A <- Y (resultado de la ALU)
            if sw_clean(2) = '1' and sw_prev(2) = '0' and deb_cnt = 0 then
                reg_a <= alu_y;
            end if;
        end if;
    end process;

    
    -- MULTIPLEXOR DE DISPLAY: x(7) = '0' -> A, x(7) = '1' -> B
    
    hex_val <= reg_a when x(7) = '0' else reg_b;

    
    -- DECODIFICADOR HEXADECIMAL A 7 SEGMENTOS (orden: gfedcba, activo en alto)
    
    with hex_val select
        seg_7 <= "0111111" when "0000", -- 0
                 "0000110" when "0001", -- 1
                 "1011011" when "0010", -- 2
                 "1001111" when "0011", -- 3
                 "1100110" when "0100", -- 4
                 "1101101" when "0101", -- 5
                 "1111101" when "0110", -- 6
                 "0000111" when "0111", -- 7
                 "1111111" when "1000", -- 8
                 "1101111" when "1001", -- 9
                 "1110111" when "1010", -- A
                 "1111100" when "1011", -- b
                 "0111001" when "1100", -- C
                 "1011110" when "1101", -- d
                 "1111001" when "1110", -- E
                 "1110001" when "1111", -- F
                 "0000000" when others;

    -- display(7) = punto decimal (salida Z de la ALU), display(6 downto 0) = g..a
    display <= alu_z & seg_7;

end architecture rtl;
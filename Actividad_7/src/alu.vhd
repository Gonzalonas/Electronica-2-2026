library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        W : positive := 4
    );
    port (
        sel_fn : in  std_logic_vector(3 downto 0);
        A      : in  std_logic_vector(W-1 downto 0);
        B      : in  std_logic_vector(W-1 downto 0);
        Y      : out std_logic_vector(W-1 downto 0);
        Z      : out std_logic
    );
end entity alu;

architecture arch of alu is
--constant W:natural := integer(ceil(log2(real(W)))); -- poco desplazamiento
    signal y_int : std_logic_vector(W-1 downto 0);
begin

    process(sel_fn, A, B)
        variable shift_amt : natural;
    begin
        -- Evita desbordamiento de integer al convertir B para anchos W grandes
        if unsigned(B) >= W then
            shift_amt := W;
        else
            shift_amt := to_integer(unsigned(B));
        end if;

        case sel_fn is
            when "0000" => -- A + B
                y_int <= std_logic_vector(unsigned(A) + unsigned(B));

            when "0001" => -- A - B
                y_int <= std_logic_vector(unsigned(A) - unsigned(B));

            when "0010" | "0011" => -- A << B (desplazamiento lógico a la izquierda)
                y_int <= std_logic_vector(shift_left(unsigned(A), shift_amt));

            when "0100" | "0101" => -- A < B (complemento a 2)
                if signed(A) < signed(B) then
                    y_int <= std_logic_vector(to_unsigned(1, W));
                else
                    y_int <= (others => '0');
                end if;

            when "0110" | "0111" => -- A < B (binario natural)
                if unsigned(A) < unsigned(B) then
                    y_int <= std_logic_vector(to_unsigned(1, W));
                else
                    y_int <= (others => '0');
                end if;

            when "1000" | "1001" => -- A XOR B
                y_int <= A xor B;

            when "1010" => -- A >> B (binario natural / desplazamiento lógico)
                y_int <= std_logic_vector(shift_right(unsigned(A), shift_amt));

            when "1011" => -- A >> B (complemento a 2 / desplazamiento aritmético)
                y_int <= std_logic_vector(shift_right(signed(A), shift_amt));

            when "1100" | "1101" => -- A OR B
                y_int <= A or B;

            when "1110" | "1111" => -- A AND B
                y_int <= A and B;

            when others =>
                y_int <= (others => '0');
        end case;
    end process;

    Y <= y_int;
    Z <= '1' when unsigned(y_int) = 0 else '0';

end architecture arch;
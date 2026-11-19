library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end entity alu_tb;

architecture sim of alu_tb is
    constant W : positive := 4;

    signal sel_fn : std_logic_vector(3 downto 0) := (others => '0');
    signal A      : std_logic_vector(W-1 downto 0) := (others => '0');
    signal B      : std_logic_vector(W-1 downto 0) := (others => '0');
    signal Y      : std_logic_vector(W-1 downto 0);
    signal Z      : std_logic;
begin

    dut : entity work.alu
        generic map (
            W => W
        )
        port map (
            sel_fn => sel_fn,
            A      => A,
            B      => B,
            Y      => Y,
            Z      => Z
        );

    stim_proc : process
        procedure check_op(
            constant fn_in  : in std_logic_vector(3 downto 0);
            constant a_in   : in std_logic_vector(W-1 downto 0);
            constant b_in   : in std_logic_vector(W-1 downto 0);
            constant y_exp  : in std_logic_vector(W-1 downto 0);
            constant z_exp  : in std_logic;
            constant nombre : in string
        ) is
        begin
            sel_fn <= fn_in;
            A      <= a_in;
            B      <= b_in;
            wait for 10 ns;

            assert Y = y_exp
                report "FALLO [" & nombre & "] Y esperado=" &
                       integer'image(to_integer(unsigned(y_exp))) &
                       ", obtenido=" &
                       integer'image(to_integer(unsigned(Y)))
                severity error;

            assert Z = z_exp
                report "FALLO [" & nombre & "] Z esperado=" &
                       std_logic'image(z_exp) &
                       ", obtenido=" &
                       std_logic'image(Z)
                severity error;
        end procedure;
    begin
        -- 0000: A + B
        check_op("0000", "0011", "0101", "1000", '0', "ADD 3+5");
        check_op("0000", "1100", "0100", "0000", '1', "ADD overflow a 0");

        -- 0001: A - B
        check_op("0001", "0101", "0011", "0010", '0', "SUB 5-3");
        check_op("0001", "0111", "0111", "0000", '1', "SUB 7-7");

        -- 001-: A << B
        check_op("0010", "0011", "0010", "1100", '0', "SLL 3<<2 (sel=0010)");
        check_op("0011", "0011", "0100", "0000", '1', "SLL 3<<4 (sel=0011)");

        -- 010-: A < B (Complemento a 2)
        check_op("0100", "1111", "0001", "0001", '0', "SLT -1 < +1 (sel=0100)");
        check_op("0101", "0001", "1111", "0000", '1', "SLT +1 < -1 (sel=0101)");

        -- 011-: A < B (Binario natural)
        check_op("0110", "1111", "0001", "0000", '1', "SLTU 15 < 1 (sel=0110)");
        check_op("0111", "0001", "1111", "0001", '0', "SLTU 1 < 15 (sel=0111)");

        -- 100-: A XOR B
        check_op("1000", "1010", "1100", "0110", '0', "XOR (sel=1000)");
        check_op("1001", "1010", "1010", "0000", '1', "XOR igual (sel=1001)");

        -- 1010: A >> B (Binario natural / lógico)
        check_op("1010", "1000", "0010", "0010", '0', "SRL 8>>2");
        check_op("1010", "1000", "0100", "0000", '1', "SRL 8>>4");

        -- 1011: A >> B (Complemento a 2 / aritmético)
        check_op("1011", "1000", "0010", "1110", '0', "SRA -8>>2 = -2");
        check_op("1011", "0100", "0010", "0001", '0', "SRA +4>>2 = +1");
        check_op("1011", "0010", "0010", "0000", '1', "SRA +2>>2 = 0");

        -- 110-: A OR B
        check_op("1100", "1010", "0101", "1111", '0', "OR (sel=1100)");
        check_op("1101", "0000", "0000", "0000", '1', "OR ceros (sel=1101)");

        -- 111-: A AND B
        check_op("1110", "1011", "1101", "1001", '0', "AND (sel=1110)");
        check_op("1111", "1010", "0101", "0000", '1', "AND cero (sel=1111)");

        report "Todas las pruebas de la ALU pasaron correctamente." severity note;
        wait;
    end process;

end architecture sim;
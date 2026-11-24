#include <stdio.h>
#include "alu.h"

static void probar(uint8_t sel_fn, uint8_t A, uint8_t B, const char *desc) {
    alu_out_t r = alu_eval(sel_fn, A, B);
    printf("%-22s | sel=0x%X A=0x%X B=0x%X -> Y=0x%X Z=%d\n",
           desc, sel_fn, A, B, r.Y, r.Z);
}

int main(void) {
    probar(0x0, 0x2, 0x5, "ADD 2 + 5");
    probar(0x0, 0xC, 0x4, "ADD 12 + 4 (overflow)");
    probar(0x1, 0x5, 0x3, "SUB 5 - 3");
    probar(0x2, 0x3, 0x2, "SLL 3 << 2");
    probar(0x4, 0xF, 0x1, "SLT -1 < +1");
    probar(0x6, 0xF, 0x1, "SLTU 15 < 1");
    probar(0x8, 0xA, 0xC, "XOR A ^ C");
    probar(0xA, 0x8, 0x2, "SRL 8 >> 2");
    probar(0xB, 0x8, 0x2, "SRA -8 >> 2");
    probar(0xC, 0xA, 0x5, "OR A | 5");
    probar(0xE, 0xB, 0xD, "AND B & D");
    return 0;
}
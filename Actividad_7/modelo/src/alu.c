#include "alu.h"

// Convierte un número de 4 bits (0..15) a entero con signo en complemento a 2 (-8..+7)
static int8_t to_signed4(uint8_t val) {
    val &= 0x0F;
    if (val & 0x08) {
        return (int8_t)(val | 0xF0); // Extiende el bit de signo
    }
    return (int8_t)val;
}

alu_out_t alu_eval(uint8_t sel_fn, uint8_t A, uint8_t B) {
    alu_out_t res = {0, false};

    sel_fn &= 0x0F;
    A &= 0x0F;
    B &= 0x0F;

    uint8_t shift = (B >= 4) ? 4 : B;
    uint8_t y = 0;

    switch (sel_fn) {
        case 0x0: // 0000: A + B
            y = (A + B) & 0x0F;
            break;

        case 0x1: // 0001: A - B
            y = (A - B) & 0x0F;
            break;

        case 0x2: // 0010: A << B
        case 0x3: // 0011: A << B
            y = (shift >= 4) ? 0 : ((A << shift) & 0x0F);
            break;

        case 0x4: // 0100: A < B (Complemento a 2)
        case 0x5: // 0101: A < B (Complemento a 2)
            y = (to_signed4(A) < to_signed4(B)) ? 1 : 0;
            break;

        case 0x6: // 0110: A < B (Binario natural)
        case 0x7: // 0111: A < B (Binario natural)
            y = (A < B) ? 1 : 0;
            break;

        case 0x8: // 1000: A XOR B
        case 0x9: // 1001: A XOR B
            y = (A ^ B) & 0x0F;
            break;

        case 0xA: // 1010: A >> B (Binario natural / lógico)
            y = (shift >= 4) ? 0 : (A >> shift);
            break;

        case 0xB: // 1011: A >> B (Complemento a 2 / aritmético)
            y = (uint8_t)(to_signed4(A) >> shift) & 0x0F;
            break;

        case 0xC: // 1100: A OR B
        case 0xD: // 1101: A OR B
            y = (A | B) & 0x0F;
            break;

        case 0xE: // 1110: A AND B
        case 0xF: // 1111: A AND B
            y = (A & B) & 0x0F;
            break;
    }

    res.Y = y;
    res.Z = (y == 0);
    return res;
}
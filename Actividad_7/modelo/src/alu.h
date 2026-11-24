#ifndef ALU_H
#define ALU_H

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    uint8_t Y;  // Resultado de 4 bits (0 a 15)
    bool Z;     // Bandera de cero (true si Y == 0)
} alu_out_t;

// Ejecuta la operación de la ALU de 4 bits según sel_fn
alu_out_t alu_eval(uint8_t sel_fn, uint8_t A, uint8_t B);

#endif
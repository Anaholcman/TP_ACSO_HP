.text
movz X1, 0x5, lsl #0
cbnz X1, etiqueta_saltar
movz X0, 0  // No debería ejecutarse si X1 no es cero
HLT 0

movz X0, 1  // Esto se ejecuta si X1 ≠ 0

HLT 0
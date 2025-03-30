.text
movz X1, 0x5, lsl #0
movz X2, 0x3, lsl #0

// cmp_ext
cmp X1, X2  // Compara X1 y X2
movz X0, 1  // No igual
movz X0, 0  // Igual

// cmp_imm
cmp X1, #5  // Compara X1 con 5
movz X0, 1
movz X0, 0

HLT 0
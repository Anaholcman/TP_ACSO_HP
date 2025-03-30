.text
movz X0, 0x1000
lsl X0, X0, 16       // X0 = 0x10000000 (dirección de memoria válida)
movz X1, 0x100, lsl #0
stur X1, [X0, #0]    // Guarda 0x100 en memoria[0x10000000]
ldur X2, [X0, #0]    // Carga desde memoria[0x10000000] → X2 = 0x100

HLT 0

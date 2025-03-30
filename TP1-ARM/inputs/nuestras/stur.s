.text
movz X1, 0xABCD, lsl #0
stur X1, [X0, #0]  // Almacena X1 en la dirección X0
ldur X2, [X0, #0]  // Carga valor almacenado en X2

HLT 0
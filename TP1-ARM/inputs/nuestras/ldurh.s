.text
movz X1, 0xABCD, lsl #0
sturh W1, [X0, #0]  // Almacena la mitad inferior de X1 en X0 + 0
ldurh W2, [X0, #0]  // Carga la mitad inferior de X0 + 0 en X2

HLT 0
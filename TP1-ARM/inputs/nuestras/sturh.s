.text
movz X1, 0xABCD, lsl #0
sturh W1, [X0, #0]  // Almacena la mitad inferior de X1
ldurh W2, [X0, #0]  // Recupera la mitad inferior de X1 en X2

HLT 0
movz X1, 0xABCD, lsl #0
sturh W1, [X0, #0]  // Almacena la mitad inferior de X1
ldurh W2, [X0, #0]  // Recupera la mitad inferior de X1 en X2
mov W3, W2          // Mueve el valor recuperado a W3 para futuras operaciones
cmp W3, #0          // Compara el valor recuperado con 0

ldr X4, [X0, #2]    // Carga el valor de la siguiente dirección en X4
add W3, W3, W4      // Realiza una operación con el valor recuperado
ldr X5, [X0, #4]    // Carga el valor de la siguiente dirección en X5
str X5, [X0, #6]    // Almacena el valor en la siguiente dirección

HLT 0
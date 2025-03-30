.text
movz X10, 0xF0F0, lsl #0
movz X11, 0x0F0F, lsl #0
orr X0, X10, X11  // ORR entre X10 y X11, resultado en X0

HLT 0
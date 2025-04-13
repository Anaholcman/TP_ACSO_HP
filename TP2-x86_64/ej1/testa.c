#include <stdio.h>
#include "ej1.h"

int main() {
    void* lista = string_proc_list_create_asm();

    printf("🧪 Dirección devuelta por ASM: %p\n", lista);

    return 0;
}

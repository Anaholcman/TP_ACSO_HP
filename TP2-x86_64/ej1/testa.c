#include <stdio.h>
#include "ej1.h"

int main() {
    string_proc_list* lista = string_proc_list_create_asm();

    printf("🧪 Dirección devuelta por string_proc_list_create_asm: %p\n", (void*)lista);

    if (!lista) {
        printf("❌ ERROR: lista es NULL\n");
        return 1;
    }

    printf("✅ Lista creada correctamente.\n");
    printf("   list->first: %p\n", (void*)lista->first);
    printf("   list->last:  %p\n", (void*)lista->last);

    return 0;
}

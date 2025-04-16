; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
    mov rdi, 16
    call malloc
    test rax, rax
    je return_null_list

    mov qword [rax], 0
    mov qword [rax + 8], 0
    ret

return_null_list:
    xor rax, rax
    ret                     ; devuelve NULL

string_proc_node_create_asm:
    mov rdx, rsi
    movzx ecx, dil

    mov rdi, 32
    call malloc
    test rax, rax
    je return_null_node

    xor r8, r8
    mov [rax], r8
    mov [rax + 8], r8
    mov byte [rax + 16], cl
    mov [rax + 24], rdx
    ret

return_null_node:
    xor rax, rax
    ret                  

string_proc_list_add_node_asm:
    ; rdi = puntero a lista
    ; sil = type (uint8_t)
    ; rdx = puntero a cadena (hash)

    test rdi, rdi              ; si list == NULL → return
    je .return_add_node
 ; ss
    ; === Guardar argumentos para crear nodo ===
    ; dil ← type, rsi ← hash
    mov dil, sil               ; copiar el type (sil → dil)
    mov rsi, rdx               ; copiar hash (rdx → rsi)
    call string_proc_node_create_asm
    mov r11, rax               ; r11 ← puntero al nuevo nodo

    test r11, r11              ; si no se creó el nodo → return
    je .return_add_node

    ; === Verificar si la lista está vacía ===
    mov rax, [rdi]             ; rax ← list->first
    test rax, rax
    jne .not_empty_list

    ; === Caso lista vacía ===
    mov [rdi], r11             ; list->first = new_node
    mov [rdi + 8], r11         ; list->last  = new_node
    ret

.not_empty_list:
    mov rax, [rdi + 8]         ; rax ← list->last
    mov [r11 + 8], rax         ; new_node->previous = list->last
    mov [rax], r11             ; list->last->next = new_node
    mov [rdi + 8], r11         ; list->last = new_node

.return_add_node:
    ret


string_proc_list_concat_asm:

    mov r8, rdi        ; r8 = list
    mov r9d, esi     ; r9d = type (zero-extend)
    mov r10, rdx       ; r10 = hash

    ; === if (list == NULL || list->first == NULL) ===
    test r8, r8
    je .copy_only_hash
    
    mov rax, [r8]      ; rax = list->first
    test rax, rax
    je .copy_only_hash

    ; === new_hash = str_concat("", hash) ===
    mov rdi, empty_string
    mov rsi, r10
    call str_concat
    mov r11, rax       ; r11 = new_hash

    ; === Bucle: current = list->first ===
    mov r12, [r8]      ; r12 = current

.loop:
    test r12, r12
    je .done

    ; Comparar current->type con type
    movzx eax, byte [r12 + 16]  ; current->type → eax
    cmp eax, r9d
    jne .next_node

    ; temp = str_concat(new_hash, current->hash)
    mov rdi, r11             ; new_hash
    mov rsi, [r12 + 24]      ; current->hash
    call str_concat
    mov r13, rax             ; temp = str_concat(new_hash, current->hash)

    ; free(new_hash), new_hash = temp
    mov rdi, r11
    call free

    mov r11, r13             ; new_hash = temp

.next_node:
    mov r12, [r12]           ; current = current->next
    jmp .loop

.done:
    mov rax, r11             ; return new_hash
    ret

.copy_only_hash:
    ; str_concat("", hash)
    mov rdi, empty_string
    mov rsi, r10
    call str_concat
    ret

section .rodata
empty_string: db 0
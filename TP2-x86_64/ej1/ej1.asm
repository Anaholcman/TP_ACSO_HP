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
    mov rdi, 16              ; rdi ← tamaño a pedir: 16 bytes
    call malloc              ; malloc(16)
    test rax, rax            ; malloc devolvió NULL?
    je .return_null          ;  salta a .return_null

    mov qword [rax], 0       ; *(list->first) ← NULL
    mov qword [rax + 8], 0   ; *(list->last)  ← NULL
    ret                      ; devuelve puntero (rax)

.return_null:
    mov rax, 0               ; rax ← NULL
    ret                      ; devuelve NULL

string_proc_node_create_asm:
    movzx rdx, dil ; guardo el type
    mov r10, rsi    ; guardo el puntero hash en rcx

    mov rdi, 32    ; 2 punteros = 16, char = 8, type = 1 y padding = 7
    call malloc

    test rax, rax
    je .return_null

    mov qword [rax], 0       ; sig en null
    mov qword [rax + 8], 0   ; anterior en null
    mov byte [rax + 16], dl ;
    mov qword [rax + 24], rcx
    ret

.return_null:
    mov rax, 0               ; rax ← NULL
    ret                      ;

string_proc_list_add_node_asm:
    ; rdi =puntero a lista, sil = type(uint_8), rdx = puntero a cadena
    test rdi, rdi
    je .return

    ; copio los punteros y el type pra no perderlo con el malloc
    mov r8, rdi       
    movzx r9d, sil     
    mov r10, rdx       

    ;-- creo nodo
    mov dil, r9b
    mov rsi, r10
    call string_proc_node_create_asm
    mov r11, rax

    ;-- si no se crea
    test r11, r11
    je .return

    ; if list->first == NULL
    mov rax, [r8]
    test rax, rax
    jne .not_empty

    ; caso lista vacia
    mov [r8], r11
    mov [r8 + 8], r11
    ret

.not_empty:
    mov rax, [r8 + 8]     ; rax ← list->last
    mov [r11 + 8], rax    ; new_node->previous = list->last

    mov [rax], r11
    mov [r8+8], r11

.return:
    ret

string_proc_list_concat_asm:

    mov r8, rdi      ; r8 ← list
    movzx r9d, sil   ; r9d ← type (extendido a 32 bits)
    mov r10, rdx     ; r10 ← hash

    ; ==== if (list == NULL || list->first == NULL) ====
    test r8, r8
    je .copy_and_return

    mov rax, [r8]      ; list->first
    test rax, rax
    je .copy_and_return

    ; ==== Copiar el hash inicial en new_hash ====
    mov rdi, r10       ; strlen(hash)
    call strlen
    inc rax            ; +1 para el '\0'
    mov rdi, rax
    call malloc
    test rax, rax
    je .return_null

    ; Copiar hash original
    mov rsi, r10       ; src
    mov rdi, rax       ; dest
    call strcpy

    ; r12 ← new_hash
    mov r12, rax

    ; ==== current = list->first ====
    mov r13, [r8]      ; r13 ← current_node

.loop:
    test r13, r13
    je .done           ; fin del while

    ; Comparar current_node->type con type
    movzx eax, byte [r13 + 16]  ; current->type (offset 16)
    cmp al, r9b
    jne .next

    ; Si coincide → concatenar
    mov rdi, r12           ; str_concat(new_hash,
    mov rsi, [r13 + 24]    ; current->hash (offset 24)
    call str_concat
    test rax, rax
    je .return_null

    ; liberar old new_hash
    mov rdi, r12
    call free

    ; actualizar new_hash
    mov r12, rax

.next:
    ; avanzar: current = current->next
    mov r13, [r13]     ; current = current->next
    jmp .loop

.done:
    ; retorno: r12 = new_hash
    mov rax, r12
    ret

.copy_and_return:
    ; strlen(hash)
    mov rdi, r10
    call strlen
    inc rax            ; +1 para '\0'

    ; malloc(strlen + 1)
    mov rdi, rax
    call malloc
    test rax, rax
    je .return_null

    ; strcpy(dest, hash)
    mov rsi, r10
    mov rdi, rax
    call strcpy
    ret

.return_null:
    xor rax, rax
    ret
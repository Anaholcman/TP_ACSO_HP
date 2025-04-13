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

   mov r8, rdi        ; r8 = list
    movzx r9d, sil     ; r9d = type (zero-extend)
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

    ; free(new_hash), new_hash = temp
    mov rdi, r11
    call free
    mov r11, rax             ; new_hash = temp

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

section .data
empty_string: db 0
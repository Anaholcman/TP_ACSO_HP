; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data
empty_string: db 0

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
    je return_null_list_create

    mov qword [rax], 0
    mov qword [rax + 8], 0
    ret

return_null_list_create:
    xor rax, rax
    ret                     ; devuelve NULL

string_proc_node_create_asm:
    mov rdx, rsi
    movzx ecx, dil

    mov rdi, 32
    call malloc
    test rax, rax
    je return_null_node_create

    xor r8, r8
    mov [rax], r8
    mov [rax + 8], r8
    mov byte [rax + 16], cl
    mov [rax + 24], rdx
    ret

return_null_node_create:
    xor rax, rax
    ret                  

string_proc_list_add_node_asm:
    test rdi, rdi              ; if list == NULL → return
    je .return_add_node

    push rdi                   ; save list pointer
    push rsi                   ; save type
    push rdx                   ; save hash

    mov dil, sil               ; set type arg
    mov rsi, rdx               ; set hash arg
    call string_proc_node_create_asm
    mov r11, rax               ; save new node

    pop rdx                    ; restore hash
    pop rsi                    ; restore type
    pop rdi                    ; restore list pointer

    test r11, r11              ; if node creation failed
    je .return_add_node

    ; Check if list is empty
    cmp qword [rdi], 0         ; list->first == NULL?
    jne .not_empty_list

    ; Empty list case
    mov [rdi], r11             ; list->first = new_node
    mov [rdi + 8], r11         ; list->last = new_node
    ret

.not_empty_list:
    mov rax, [rdi + 8]         ; rax = list->last
    mov [r11 + 8], rax         ; new_node->prev = list->last
    mov [rax], r11             ; list->last->next = new_node
    mov [rdi + 8], r11         ; list->last = new_node

.return_add_node:
    ret


string_proc_list_concat_asm:
    push r12
    push r13
    push r14

    mov r14, rdi               ; save list
    mov r13d, esi              ; save type
    mov r12, rdx               ; save initial hash

    ; First concat with empty string
    mov rdi, empty_string
    mov rsi, r12
    call str_concat
    test rax, rax
    jz .concat_failed
    mov r11, rax               ; new_hash

    test r14, r14              ; if list == NULL
    jz .return_result
    mov r12, [r14]             ; current = list->first
    test r12, r12              ; if list->first == NULL
    jz .return_result

.loop:
    movzx eax, byte [r12 + 16] ; current->type
    cmp eax, r13d              ; compare with target type
    jne .next_node

    mov rdi, r11
    mov rsi, [r12 + 24]        ; current->hash
    call str_concat
    test rax, rax
    jz .concat_failed

    mov rdi, r11               ; free old string
    mov r11, rax               ; update new_hash
    call free

.next_node:
    mov r12, [r12]             ; current = current->next
    test r12, r12
    jnz .loop

.return_result:
    mov rax, r11
    jmp .cleanup

.concat_failed:
    xor rax, rax               ; return NULL on failure

.cleanup:
    pop r14
    pop r13
    pop r12
    ret
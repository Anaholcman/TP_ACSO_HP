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
    ret                     

string_proc_node_create_asm:
    test rsi, rsi
    je return_null_node_create

    mov rdx, rsi             
    movzx ecx, dil       
  
    mov rdi, 32              
    call malloc
    test rax, rax
    je return_null_node_create

    xor r8, r8
    mov [rax], r8            ; next
    mov [rax + 8], r8        ; prev
    mov byte [rax + 16], cl  ; type
    mov [rax + 24], rdx      ; hash

    ret

return_null_node_create:
    xor rax, rax
    ret


string_proc_list_add_node_asm:
    test rdi, rdi
    je .return

    push rbx
    mov rbx, rdi              

    movzx edi, sil
    mov rsi, rdx
    call string_proc_node_create_asm
    test rax, rax
    je .pop_and_return

    ; si lista vacía → first y last apuntan al nuevo nodo
    cmp qword [rbx], 0
    jne .not_empty

    mov [rbx], rax            ; list->first = nodo
    mov [rbx + 8], rax        ; list->last = nodo
    jmp .pop_and_return

.not_empty:
    mov rcx, [rbx + 8]        ; rcx = last
    mov [rax + 8], rcx        ; new->prev = last
    mov [rcx], rax            ; last->next = new
    mov [rbx + 8], rax        ; list->last = new

.pop_and_return:
    pop rbx
.return:
    ret
    


string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi         ; r12 ← list
    movzx r13d, sil      ; r13 ← type (aseguramos 0-255 sin signo)
    mov r14, rdx         ; r14 ← hash

    ; if (list == NULL || list->first == NULL)
    test r12, r12
    jz .dup_hash
    mov rax, [r12]
    test rax, rax
    jz .dup_hash

    ; malloc(strlen(hash) + 1)
    mov rdi, r14
    call strlen
    add rax, 1
    mov rdi, rax
    call malloc
    test rax, rax
    jz .return_null
    mov r15, rax          ; r15 ← new_hash

    ; strcpy(new_hash, hash)
    mov rdi, r15
    mov rsi, r14
    call strcpy

    mov rcx, [r12]        ; rcx ← current_node (list->first)
.loop:
    test rcx, rcx
    jz .concat_done

    movzx eax, byte [rcx + 16] ; eax ← current_node->type
    cmp eax, r13d
    jne .next

    mov rdi, r15                ; rdi ← current new_hash
    mov rsi, [rcx + 24]         ; rsi ← current_node->hash
    call str_concat
    test rax, rax
    jz .next
    mov rdi, r15
    call free
    mov r15, rax                ; new_hash ← temp

.next:
    mov rcx, [rcx]              ; rcx = current_node->next
    jmp .loop

.concat_done:
    mov rax, r15
    jmp .restore_and_return

.dup_hash:
    ; return strdup(hash) → malloc + strcpy
    mov rdi, r14
    call strlen
    add rax, 1
    mov rdi, rax
    call malloc
    test rax, rax
    jz .return_null
    mov rdi, rax
    mov rsi, r14
    call strcpy
    mov rax, rdi
    jmp .restore_and_return

.return_null:
    xor rax, rax

.restore_and_return:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret

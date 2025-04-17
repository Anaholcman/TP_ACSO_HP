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
    je .return_no_push

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
    ret
.return_no_push:
    ret
    


string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp, 8

    mov r12, rdi          ; r12 ← list
    movzx r13d, sil       ; r13 ← type
    mov r14, rdx          ; r14 ← hash

    ; if (list == NULL || list->first == NULL)
    test r12, r12
    jz .dup_hash
    mov rax, [r12]        ; list->first
    test rax, rax
    jz .dup_hash

    ; strlen(hash)
    mov rdi, r14
    xor rcx, rcx
    dec rcx
.count_len:
    inc rcx
    cmp byte [rdi + rcx], 0
    jne .count_len

    ; alloc new string (len + 1)
    lea rdi, [rcx + 1]
    call malloc
    test rax, rax
    jz .return_null
    mov r15, rax         ; new_hash = r15

    ; strcpy(new_hash, hash)
    mov rsi, r14
    mov rdi, r15
.copy_hash:
    lodsb
    stosb
    test al, al
    jnz .copy_hash

    ; Iterate through list
    mov rbx, [r12]        ; current_node = list->first

.loop:
    test rbx, rbx
    jz .concat_done

    ; if (current_node->type == type)
    movzx eax, byte [rbx + 16]
    cmp eax, r13d
    jne .next

    ; if (current_node->hash != NULL)
    mov rsi, [rbx + 24]
    test rsi, rsi
    jz .next

    ; str_concat(new_hash, current_node->hash)
    mov rdi, r15
    call str_concat
    test rax, rax
    jz .next
    mov rdi, r15
    mov r15, rax          ; new_hash = result
    call free

.next:
    mov rbx, [rbx]        ; current_node = current_node->next
    jmp .loop

.concat_done:
    mov rax, r15
    jmp .restore_and_return

.dup_hash:
    ; strlen(hash)
    mov rdi, r14
    xor rcx, rcx
    dec rcx
.count_dup:
    inc rcx
    cmp byte [rdi + rcx], 0
    jne .count_dup

    ; alloc new string (len + 1)
    lea rdi, [rcx + 1]
    call malloc
    test rax, rax
    jz .return_null
    mov rbx, rax

    ; strcpy(copy, hash)
    mov rsi, r14
    mov rdi, rbx
.copy_dup:
    lodsb
    stosb
    test al, al
    jnz .copy_dup
    jmp .return_copy

.return_null:
    xor rax, rax
    jmp .restore_and_return

.return_copy:
    mov rax, rbx

.restore_and_return:
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
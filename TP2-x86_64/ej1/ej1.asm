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

    ; calcular largo del string
    mov rdi, rsi             ; rdi = string original
    xor rcx, rcx
.count:
    mov al, byte [rdi + rcx]
    test al, al
    jz .alloc_copy
    inc rcx
    jmp .count

.alloc_copy:
    mov rdi, rcx
    inc rdi                  ; incluir null terminator
    call malloc
    test rax, rax
    jz return_null_node_create
    mov r8, rax              ; r8 = copia de string

    ; copiar string
    mov rsi, rdx             ; string original
    mov rdi, r8
    xor rcx, rcx
.copy:
    mov al, byte [rsi + rcx]
    mov byte [rdi + rcx], al
    test al, al
    jz .continuar
    inc rcx
    jmp .copy

.continuar:
    mov rdi, 32              ; malloc nodo
    call malloc
    test rax, rax
    jz .free_and_return_null

    xor rcx, rcx
    mov [rax], rcx           ; next
    mov [rax + 8], rcx       ; prev
    mov byte [rax + 16], dil ; type
    mov [rax + 24], r8       ; hash = copia

    ret

.free_and_return_null:
    mov rdi, r8
    call free
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
    mov rsi, r14
    xor rcx, rcx
.count_len:
    mov al, byte [rsi + rcx]
    test al, al
    jz .alloc_hash
    inc rcx
    jmp .count_len

.alloc_hash:
    mov rdi, rcx
    inc rdi              ; +1 para null terminator
    call malloc
    test rax, rax
    jz .return_null
    mov r15, rax         ; new_hash = r15

    ; strcpy(new_hash, hash)
    mov rsi, r14
    mov rdi, r15
    xor rcx, rcx
.copy_hash:
    mov al, byte [rsi + rcx]
    mov byte [rdi + rcx], al
    test al, al
    jz .start_loop
    inc rcx
    jmp .copy_hash

.start_loop:
    mov rcx, [r12]        ; current_node = list->first

.loop:
    test rcx, rcx
    jz .concat_done

    ; if (current_node->type == type)
    movzx eax, byte [rcx + 16]
    cmp eax, r13d
    jne .next

    ; str_concat(new_hash, current_node->hash)
    mov rdi, r15
    mov rsi, [rcx + 24]      ; current_node->hash
    test rsi, rsi            ; NULL check
    jz .next
    call str_concat
    test rax, rax
    jz .next
    mov rdi, r15
    call free
    mov r15, rax             ; new_hash = result

.next:
    mov rcx, [rcx]           ; current_node = current_node->next
    jmp .loop

.concat_done:
    mov rax, r15
    jmp .restore_and_return

.dup_hash:
    ; strlen(hash)
    mov rsi, r14
    xor rcx, rcx
.count_dup:
    mov al, byte [rsi + rcx]
    test al, al
    jz .alloc_dup
    inc rcx
    jmp .count_dup

.alloc_dup:
    mov rdi, rcx
    inc rdi
    call malloc
    test rax, rax
    jz .return_null
    mov rbx, rax

    ; strcpy(copy, hash)
    mov rsi, r14
    mov rdi, rbx
    xor rcx, rcx
.copy_dup:
    mov al, byte [rsi + rcx]
    mov byte [rdi + rcx], al
    test al, al
    jz .return_copy
    inc rcx
    jmp .copy_dup

.return_copy:
    mov rax, rbx
    jmp .restore_and_return

.return_null:
    xor rax, rax

.restore_and_return:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
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

    mov qword [rax], 0    ; first = NULL
    mov qword [rax + 8], 0 ; last = NULL
    ret

return_null_list_create:
    xor rax, rax
    ret

; New function to free the entire list
string_proc_list_free_asm:
    push rbx
    push r12
    mov rbx, rdi          ; Save list pointer
    
    test rbx, rbx
    jz .end_free          ; If list is NULL, nothing to free
    
    mov r12, [rbx]        ; Get first node
.node_loop:
    test r12, r12
    jz .free_list
    
    ; Save next pointer before freeing
    mov rdi, r12
    mov r12, [r12]        ; next = current->next
    
    ; Free the node's hash string
    mov rsi, [rdi + 24]   ; Get hash pointer
    test rsi, rsi
    jz .free_node
    push rdi
    mov rdi, rsi
    call free
    pop rdi
    
.free_node:
    ; Free the node itself
    call free
    jmp .node_loop
    
.free_list:
    ; Free the list structure
    mov rdi, rbx
    call free
    
.end_free:
    pop r12
    pop rbx
    ret                    

string_proc_node_create_asm:
    test rsi, rsi          ; Verificar si hash es NULL
    je return_null_node_create

    push rbx
    push r12
    push r13
    
    mov rbx, rsi           ; rbx = hash original
    mov r12d, edi          ; r12d = type

    ; Calcular longitud de hash
    xor rcx, rcx
.strlen_loop:
    cmp byte [rbx + rcx], 0
    je .strlen_done
    inc rcx
    jmp .strlen_loop
.strlen_done:
    
    ; Asignar memoria para el string duplicado
    lea rdi, [rcx + 1]     ; +1 para el byte NULL
    call malloc
    test rax, rax
    je .cleanup_and_return_null
    
    mov r13, rax           ; r13 = hash duplicado
    
    ; Copiar hash original al nuevo
    mov rdi, r13
    mov rsi, rbx
.copy_loop:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .copy_loop
    
    ; Crear nodo
    mov rdi, 32            ; tamaño del nodo
    call malloc
    test rax, rax
    je .free_hash_and_return_null
    
    ; Inicializar campos del nodo
    mov qword [rax], 0     ; next = NULL
    mov qword [rax + 8], 0 ; prev = NULL
    mov byte [rax + 16], r12b ; type
    mov [rax + 24], r13    ; hash
    
    jmp .cleanup_registers
    
.free_hash_and_return_null:
    mov rdi, r13
    call free
    
.cleanup_and_return_null:
    xor rax, rax
    
.cleanup_registers:
    pop r13
    pop r12
    pop rbx
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

    mov r12, rdi          ; r12 ← list
    movzx r13d, sil       ; r13 ← type
    mov r14, rdx          ; r14 ← hash

    ; if (list == NULL || list->first == NULL)
    test r12, r12
    jz dup_hash_only
    mov rax, [r12]        ; list->first
    test rax, rax
    jz dup_hash_only

    ; Duplicate the initial hash
    ; Calculate length of hash
    mov rdi, r14
    xor rcx, rcx
count_len:
    cmp byte [rdi + rcx], 0
    je alloc_hash
    inc rcx
    jmp count_len

alloc_hash:
    inc rcx               ; +1 for null terminator
    mov rdi, rcx
    call malloc
    test rax, rax
    jz return_null
    mov r15, rax         ; new_hash = r15

    ; Copy hash to new allocation
    mov rsi, r14
    mov rdi, r15
copy_hash:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz copy_hash

    ; Start iterating through the list
    mov rbx, [r12]       ; current_node = list->first

concat_loop:
    test rbx, rbx
    jz concat_done

    ; Check if node type matches
    movzx eax, byte [rbx + 16]
    cmp eax, r13d
    jne next_node

    ; Prepare arguments for str_concat
    mov rdi, r15         ; current concatenated string
    mov rsi, [rbx + 24]  ; node's hash string
    test rsi, rsi
    jz next_node         ; skip if node's hash is NULL

    ; Call str_concat
    call str_concat
    test rax, rax
    jz concat_failed     ; if str_concat failed

    ; Free old string and update pointer
    mov rdi, r15
    mov r15, rax         ; update with new concatenated string
    call free

next_node:
    mov rbx, [rbx]       ; current_node = current_node->next
    jmp concat_loop

concat_failed:
    ; Free the string we were building
    mov rdi, r15
    call free
    xor rax, rax
    jmp restore_and_return

concat_done:
    mov rax, r15         ; return the concatenated string
    jmp restore_and_return

dup_hash_only:
    ; Handle case where list is empty - just duplicate the input hash
    mov rdi, r14
    xor rcx, rcx
count_dup:
    cmp byte [rdi + rcx], 0
    je alloc_dup
    inc rcx
    jmp count_dup

alloc_dup:
    inc rcx
    mov rdi, rcx
    call malloc
    test rax, rax
    jz return_null
    mov r15, rax

    ; Copy the hash
    mov rsi, r14
    mov rdi, r15
copy_dup:
    mov al, byte [rsi]
    mov byte [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz copy_dup

    mov rax, r15
    jmp restore_and_return

return_null:
    xor rax, rax

restore_and_return:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret


global string_proc_list_destroy

string_proc_list_destroy:
    jmp string_proc_list_free_asm

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

; string_proc_node_create_asm corregido
string_proc_node_create_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    test rsi, rsi             ; Verificar si hash es NULL
    je .return_null

    mov rbx, rdi              ; Preservar type (primer parámetro)
    mov r12, rsi              ; Preservar hash (segundo parámetro)

    mov rdi, 32               ; Tamaño del nodo
    call malloc
    test rax, rax
    je .return_null

    ; Inicializar nodo
    mov qword [rax], 0        ; next = NULL
    mov qword [rax + 8], 0    ; prev = NULL
    mov byte [rax + 16], bl   ; type (usar bl que contiene el byte bajo de rbx)
    mov [rax + 24], r12       ; hash

    pop r12
    pop rbx
    leave
    ret

.return_null:
    pop r12
    pop rbx
    leave
    xor rax, rax
    ret

string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi              ; list
    movzx r13d, sil           ; type (extender a 32 bits con ceros)
    mov r14, rdx              ; hash inicial

    ; Verificar si list es NULL o está vacía
    test r12, r12
    jz .duplicate_hash
    mov rax, [r12]            ; list->first
    test rax, rax
    jz .duplicate_hash

    ; Calcular longitud del hash inicial
    mov rdi, r14
    xor rcx, rcx
    dec rcx
.strlen_loop:
    inc rcx
    cmp byte [rdi + rcx], 0
    jne .strlen_loop

    ; Reservar memoria para nuevo string
    lea rdi, [rcx + 1]        ; longitud + null terminator
    call malloc
    test rax, rax
    jz .return_null
    mov r15, rax              ; nuevo string

    ; Copiar hash inicial al nuevo string
    mov rsi, r14
    mov rdi, r15
.copy_loop:
    lodsb
    stosb
    test al, al
    jnz .copy_loop

    ; Iterar sobre la lista
    mov rbx, [r12]            ; current = list->first
.concat_loop:
    test rbx, rbx
    jz .concat_done

    ; Verificar type
    movzx eax, byte [rbx + 16]
    cmp eax, r13d
    jne .next_node

    ; Verificar que hash no sea NULL
    mov rsi, [rbx + 24]
    test rsi, rsi
    jz .next_node

    ; Concatenar
    mov rdi, r15
    call str_concat
    test rax, rax
    jz .next_node
    mov rdi, r15              ; Liberar string anterior
    mov r15, rax              ; Nuevo string
    call free

.next_node:
    mov rbx, [rbx]            ; current = current->next
    jmp .concat_loop

.concat_done:
    mov rax, r15
    jmp .return

.duplicate_hash:
    ; Calcular longitud del hash
    mov rdi, r14
    xor rcx, rcx
    dec rcx
.dup_strlen:
    inc rcx
    cmp byte [rdi + rcx], 0
    jne .dup_strlen

    ; Reservar memoria
    lea rdi, [rcx + 1]
    call malloc
    test rax, rax
    jz .return_null
    mov rbx, rax

    ; Copiar string
    mov rsi, r14
    mov rdi, rbx
.dup_copy:
    lodsb
    stosb
    test al, al
    jnz .dup_copy
    mov rax, rbx
    jmp .return

.return_null:
    xor rax, rax

.return:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
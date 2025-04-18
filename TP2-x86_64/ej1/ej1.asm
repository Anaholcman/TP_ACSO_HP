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
extern strlen


; ===========string_proc_list_create_asm===========
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

; ===========string_proc_node_create_asm===========

string_proc_node_create_asm:
    test rsi, rsi
    je .return_null_node_create

    push rbx
    push r12

    mov r12d, edi       
    mov rbx, rsi       

    mov rdi, 32
    call malloc
    test rax, rax
    je .error_malloc

    mov qword [rax], 0         
    mov qword [rax + 8], 0     
    mov byte [rax + 16], r12b  
    mov [rax + 24], rbx        

    pop r12
    pop rbx
    ret

.error_malloc:
    xor rax, rax
    pop r12
    pop rbx
    ret

.return_null_node_create:
    xor rax, rax
    ret

; ===========string_proc_list_add_node_asm===========

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

    cmp qword [rbx], 0
    jne .not_empty

    mov [rbx], rax            
    mov [rbx + 8], rax        
    jmp .pop_and_return

.not_empty:
    mov rcx, [rbx + 8]        
    mov [rax + 8], rcx        
    mov [rcx], rax            
    mov [rbx + 8], rax        

.pop_and_return:
    pop rbx
    ret
.return_no_push:
    ret

; ===========string_proc_list_concat_asm===========


string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi            
    movzx r13d, sil         
    mov r14, rdx            

    test r14, r14
    jz .return_null_concat

    mov rdi, r14
    call strlen
    inc rax
    mov rdi, rax
    call malloc
    test rax, rax
    jz .return_null_concat
    mov r15, rax            

    mov rsi, r14
    mov rdi, r15
.copy_hash:
    lodsb
    stosb
    test al, al
    jnz .copy_hash

    test r12, r12
    jz .done_iter
    mov rbx, [r12]
    test rbx, rbx
    jz .done_iter

.concat_loop:
    test rbx, rbx
    jz .done_iter

    movzx eax, byte [rbx + 16]
    cmp eax, r13d
    jne .next_node

    mov rsi, [rbx + 24]
    test rsi, rsi
    jz .next_node

    mov rdi, r15
    call str_concat
    test rax, rax
    jz .concat_failed

    mov rdi, r15
    mov r15, rax
    call free

.next_node:
    mov rbx, [rbx]
    jmp .concat_loop

.done_iter:
    mov rdi, r12
    movzx esi, r13b
    mov rdx, r15
    call string_proc_list_add_node_asm

    mov rax, r15
    jmp .restore_list

.concat_failed:
    mov rdi, r15
    call free
    xor rax, rax

.restore_list:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret

.return_null_concat:
    xor rax, rax
    jmp .restore_list

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

    test rdi, rdi              
    je .return_add_node

    push rbx
    mov rbx, rdi                 

    movz eax, sil 
    mov rcx, rsi 

    mov rdi, eax        
    mov rsi, rcx       
    call string_proc_node_create_asm
    test rax, rax
    jz .add_node_cleanup

    cmp qword [rbx], 0         
    jne .not_empty

    ; Empty list case
    mov [rbx], rax             
    mov [rbx + 8], rax         
    jmp .add_node_cleanup

.not_empty:
    mov rcx, [rbx + 8]         
    mov [rax + 8], rcx         
    mov [rcx], rax            
    mov [rbx + 8], rax         

.add_node_cleanup:
    pop rbx
.return_add_node:
    ret


string_proc_list_concat_asm:
    push r12
    push r13
    push r14
    push r15

    mov r14, rdi               
    mov r15d, esi              
    mov r13, rdx               

    mov rdi, empty_string
    mov rsi, r13
    call str_concat
    test rax, rax
    jz .concat_failed
    mov r12, rax               

    test r14, r14              
    jz .return_result
    mov r11, [r14]             
    test r11, r11             
    jz .return_result

.loop:
    movzx eax, byte [r11 + 16] 
    cmp eax, r15d              
    jne .next_node

    mov rdi, r12
    mov rsi, [r11 + 24] 
    test rsi, rsi
    jz .next_node     
    call str_concat
    test rax, rax
    jz .concat_failed

    mov rdi, r12              
    mov r12, rax               
    call free

.next_node:
    mov r11, [r11]             
    test r11, r11
    jnz .loop

.return_result:
    mov rax, r12
    jmp .cleanup

.concat_failed:
    xor rax, rax               

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    ret
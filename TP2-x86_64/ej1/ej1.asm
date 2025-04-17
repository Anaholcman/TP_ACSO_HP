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

    push rdi                   
    push rsi                   
    push rdx                   

    mov dil, sil               
    mov rsi, rdx               
    call string_proc_node_create_asm
    mov r11, rax               

    pop rdx                    
    pop rsi                    
    pop rdi                    

    test r11, r11              
    je .return_add_node

    cmp qword [rdi], 0         
    jne .not_empty_list

    mov [rdi], r11             
    mov [rdi + 8], r11         
    ret

.not_empty_list:
    mov rax, [rdi + 8]         
    mov [r11 + 8], rax         
    mov [rax], r11             
    mov [rdi + 8], r11         

.return_add_node:
    ret


string_proc_list_concat_asm:
    push r12
    push r13
    push r14

    mov r14, rdi               
    mov r13d, esi              
    mov r12, rdx               

    mov rdi, empty_string
    mov rsi, r12
    call str_concat
    test rax, rax
    jz .concat_failed
    mov r11, rax               

    test r14, r14              
    jz .return_result
    mov r12, [r14]             
    test r12, r12             
    jz .return_result

.loop:
    movzx eax, byte [r12 + 16] 
    cmp eax, r13d              
    jne .next_node

    mov rdi, r11
    mov rsi, [r12 + 24]        
    call str_concat
    test rax, rax
    jz .concat_failed

    mov rdi, r11               
    mov r11, rax               
    call free

.next_node:
    mov r12, [r12]             
    test r12, r12
    jnz .loop

.return_result:
    mov rax, r11
    jmp .cleanup

.concat_failed:
    xor rax, rax               

.cleanup:
    pop r14
    pop r13
    pop r12
    ret
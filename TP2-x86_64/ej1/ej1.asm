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
    mov rdx, rsi             ; rdx ← hash
    movzx ecx, dil           ; ecx ← type (convertido a 32 bits sin signo)

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
    jz .add_node_done
    
    push rbp
    mov rbp, rsp
    push r12
    push r13
    
    mov r12, rdi              
    mov r13, rdx              
    
    movzx edi, sil            
    mov rsi, r13              
    call string_proc_node_create_asm
    test rax, rax
    jz .add_cleanup
    
    ; Add to list
    cmp qword [r12], 0        
    jne .not_empty
    
    ; Empty list case
    mov [r12], rax            ; first = node
    mov [r12+8], rax          ; last = node
    jmp .add_cleanup
    
.not_empty:
    mov rcx, [r12+8]          
    mov [rax+8], rcx          ; node->prev = last
    mov [rcx], rax            ; last->next = node
    mov [r12+8], rax          ; list->last = node
    
.add_cleanup:
    pop r13
    pop r12
    leave
    
.add_node_done:
    ret
    


string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi              
    mov r13d, esi             
    mov r14, rdx              
    
    ; Start with empty string + initial hash
    mov rdi, empty_string
    mov rsi, r14
    call str_concat
    mov r15, rax              
    
    ; Check if list exists and not empty
    test r12, r12
    jz .concat_done
    mov rcx, [r12]            
    test rcx, rcx
    jz .concat_done
    
.concat_loop:
    ; Check node type
    movzx eax, byte [rcx+16]
    cmp eax, r13d
    jne .next_node
    
    ; Concat if type matches
    mov rdi, r15
    mov rsi, [rcx+24]         
    test rsi, rsi
    jz .next_node             
    
    call str_concat
    mov r15, rax              
    
.next_node:
    mov rcx, [rcx]            ; Move to next node
    test rcx, rcx
    jnz .concat_loop
    
.concat_done:
    mov rax, r15              
    
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
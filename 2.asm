    .model tiny
    .code
    .186
    org 100h
    
start:    
    jmp main    
    msg	db "I have set",13, 10, "$"
    is_set dw 0
    old_handler dd ?
    int_segment dw ?
    int_handler proc near
        push ds
        mov dx, cs
        mov ds, dx
        ;mov ax, is_set
        ;call print_number
        
        cmp is_set, 0h
        jne cs:do_old_handler
        
        mov dx, offset msg
        mov	ah, 9h
        int	21h
        mov is_set, 1h  
        
        pop ds                
        iret
        
        do_old_handler:
            pop ds
            jmp cs:old_handler
    int_handler endp
    
print_number:
    pusha
    mov cx, 0
    cycle:
        mov dx, 0
        mov bx, 10
        div bx
        mov bx, ax       
        add dl, 30h
        push dx
        mov ax, bx
        inc cx
        
        cmp ax, 0
        je print_number_ret
        jmp cycle
    print_number_ret:
        pop dx
        mov ah, 02h
        int 21h
        loop print_number_ret
        mov dl, 10
        int 21h
        mov dl, 13
        int 21h
        popa
        ret
    
resident_end:
main:
    push es
    mov ax, 352fh
    int 21h
    mov word ptr old_handler, bx
    mov word ptr old_handler+2, es
    pop es
    
    mov ax, word ptr old_handler+2
    call print_number
    mov ax, word ptr old_handler
    call print_number
    
    mov ax, 252fh
    mov dx, cs    
    mov ds, dx
    mov int_segment, dx
    mov dx, offset int_handler
    int 21h
    
    mov ax, cs
    call print_number
    mov ax, offset int_handler
    call print_number
    
    mov dx, offset resident_end + 15
    shr dx, 4
    mov ax, 3100h
    int 21h
    
    ret
end start
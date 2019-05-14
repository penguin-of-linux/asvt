    .model tiny
    .code
    .186
    org 100h
main:
    mov ax, 3509h
    int 21h
    mov word ptr old_handler, bx
    mov word ptr old_handler + 2, es
    
    mov ax, 2509h
    mov dx, offset int_handler
    int 21h
    _loop:
        cmp is_interrupt_occured, 0
        je _loop
        xor ah, ah
        xor bx, bx
        
        mov bl, tall_pointer
        add bx, offset array
        mov al, byte ptr [bx]
        
        ; scan
        cmp al, 1 ; esc
        je _loop_end        
        call print_number
        
        ; /r/n
        mov ah, 02h
        mov dl, 13
        int 21h
        mov dl, 10
        int 21h        
        
        mov bl, tall_pointer
        call inc_pointer
        mov tall_pointer, bl
        
        mov al, tall_pointer
        mov ah, head_pointer
        cmp al, ah
        jne _loop ; если не дошли до головы - is_interrupt_occured = true
        
        mov is_interrupt_occured, 0
    jmp _loop
    _loop_end:
    
    mov ax, 2509h
    mov dx, word ptr old_handler + 2
    mov ds, dx
    mov dx, word ptr cs:old_handler
    int 21h
    
    ret

; ax - number
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
        popa
        ret
        
int_handler proc far
        pushf
        call cs:old_handler
        
        pusha
        
        xor bx, bx
        in al, 60h
        mov bl, cs:head_pointer
        add bx, offset array 
        mov byte ptr [bx], al
        mov bl, cs:head_pointer
        call cs:inc_pointer
        mov cs:head_pointer, bl        
        mov cs:is_interrupt_occured, 1
                        
        popa
        iret
        int_handler endp
        
inc_pointer proc far ; bl
        inc bl
        cmp bl, cs:array_len
        jne _inc_pointer_ret
        xor bl, bl
        _inc_pointer_ret:
        ret
        inc_pointer endp
        
array db 255, 255, 255, 255
head_pointer db 0
tall_pointer db 0
is_interrupt_occured db 0
array_len db 4        
old_handler dd ?
end main

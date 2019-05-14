    .model tiny
    .code
    .186
    org 100h
main:
    mov ah, 09
    lea dx, msg
    int 21h
    
    _loop:
        xor ah, ah
        int 16h
        
        ; scancode
        mov bx, ax
        mov al, ah
        xor ah, ah
        cmp al, 1 ; esc
        je _ret
        call print_number
        
        ; space
        mov ah, 02h
        mov dl, 20h
        int 21h
        
        ; ascii code
        xor ah, ah
        mov al, bl
        call print_number
        
        ; space
        mov ah, 02h
        mov dl, 20h
        int 21h
        
        mov dl, bl
        mov ah, 02h
        int 21h
        
        mov dl, 13
        int 21h
        mov dl, 10
        int 21h
    jmp _loop
    _ret:
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
        
msg db "scancode, ascii code, asymbol", 13, 10, "$"
end main

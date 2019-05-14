    .model tiny
    .code
    .386
    org 80h
    cmd_len db ?
    cmd_args db ?
    org 100h
main:
    call parse_mode
    call parse_page
    call set_start_position
    cmp start_x, 0
    je print_usage
    call print_data
    ret

print_data:
    mov ah, 0h ; установка режима
    mov al, screen_mode
    int 10h
    
    mov cx, 10h
    mov al, 0h
    mov dh, start_y
    _loop2:
        cmp cx, 1h
        je _print_last
        cmp cx, 0dh
        je _print_medium
        cmp cx, 0fh
        je _print_first
        call print_line
        jmp _continue2
        _print_first:
            call print_first
            jmp _continue2
        _print_medium:
            call print_medium
            jmp _continue2
        _print_last:
            call print_last
            jmp _continue2
        
        _continue2:
            inc dh
            add al, 10h
        loop _loop2
    
    wait_press_key:
        mov ah, 0bh
        int 21h
        cmp al, 0
        je  wait_press_key
    
    ret

;;;;
; Attention - говнокод. В след задаче сделано нормально, через передачу ссылки на рисователь, т.е. без дублирования
;;;;

print_line:
; al - begin symbol
; dh - line number   
    pusha
    mov ah, 02h ; ставим курсор
    mov bh, 0 ; dh - line number
    mov dl, start_x
    int 10h
    
    mov cx, 20h
    _loop:    
        push cx
        mov ah, 09h
        mov bh, 0 ;al - symbol
        ; меняем bl
        mov bl, 00111010b
        ;
        mov cx, 01h
        int 10h
        pop cx
        dec cx
        mov ah, 02h ; ставим курсор
        inc dl
        int 10h  

        push ax
        mov ah, 09h
        mov al, 20h
        int 10h
        pop ax
        
        inc dl
        inc al ; следующий символ     
        loop _loop
        
    popa
    ret
    
print_medium:
pusha
    mov ah, 02h ; ставим курсор
    mov bh, 0 ; dh - line number
    mov dl, start_x
    int 10h
    
    mov cx, 20h
    _loop5:    
        push cx
        mov ah, 09h
        mov bh, 0 ;al - symbol
        push ax
        ; меняем цвета фона
        mov bl, 00000000b
        call get_random
        and al, 01110000b
        or bl, al
        ; закончили менять
        pop ax
        mov cx, 01h
        int 10h
        pop cx
        dec cx
        mov ah, 02h ; ставим курсор
        inc dl
        int 10h  

        push ax
        mov ah, 09h
        mov al, 20h
        int 10h
        pop ax
        
        inc dl
        inc al ; следующий символ     
        loop _loop5
        
    popa
    ret
    
print_last:
    pusha
    mov ah, 02h ; ставим курсор
    mov bh, 0 ; dh - line number
    mov dl, start_x
    int 10h
    
    push ax
    ; меняем цвета буквы и фона
    call get_random
    and al, 00000111b
    mov bl, 10000000b
    or bl, al
    call get_random
    and al, 01110000b
    or bl, al
    ; закончили менять
    pop ax
    
    mov cx, 20h
    _loop7:    
        push cx
        mov ah, 09h
        mov bh, 0 ;al - symbol
        mov cx, 01h
        int 10h
        pop cx
        dec cx
        mov ah, 02h ; ставим курсор
        inc dl
        int 10h  

        push ax
        mov ah, 09h
        mov al, 20h
        int 10h
        pop ax
        
        inc dl
        inc al ; следующий символ     
        loop _loop7
        
    popa
    ret
    
print_first:
    pusha
    mov ah, 02h ; ставим курсор
    mov bh, 0 ; dh - line number
    mov dl, start_x
    int 10h
    
    mov cx, 20h
    _loop4:    
        push cx
        mov ah, 09h
        mov bh, 0 ;al - symbol
        push ax
        ; меняем цвета буквы и фона
        call get_random
        and al, 01110111b
        mov bl, 00000000b
        or bl, al
        ; закончили менять
        pop ax
        mov cx, 01h
        int 10h
        pop cx
        dec cx
        mov ah, 02h ; ставим курсор
        inc dl
        int 10h  

        push ax
        mov ah, 09h
        mov al, 20h
        int 10h
        pop ax
        
        inc dl
        inc al ; следующий символ     
        loop _loop4
        
    popa
    ret
    
parse_page:
    mov ah, 70h ; p
    call get_arg_by_key
    mov bl, bh ; запись значения из bh в bl
    xor bh, bh
    mov ax, [bx]    
    sub al, 30h ; zero
    mov page_number, al
    ret
    
parse_mode:
    mov ah, 6dh ; m
    call get_arg_by_key
    mov bl, bh ; запись значения из bh в bl
    xor bh, bh
    mov ax, [bx]
    sub al, 30h ; zero
    mov screen_mode, al
    ret
    
get_arg_by_key: ; ah - key (char), return: bl - len, bh - position
    xor al, al ; позиция - начало аргумента
    xor cx, cx
    lea bx, cmd_args + 1 ;space
    mov cl, cmd_len
    dec cl
    _loop3:
        cmp al, 0
        jne _else3
            cmp byte ptr [bx], 2fh ; /
            jne _continue3
            cmp byte ptr [bx+1], ah
            jne _continue3
            ; нашли ключ
            sub cx, 2
            add bx, 2
            mov al, bl
            
            jmp _continue3
        _else3:        
            cmp cx, 1
            je _handle_end
            cmp byte ptr [bx], 20h ; space
            jne _continue3
            jmp _ret3
            _handle_end:
                inc bx
            _ret3:
                xor ah, ah
                xor bh, bh
                inc al ; там был посчитан лишний проблеьчик
                sub bl, al
                mov bh, al
                ret
            
    _continue3:
    inc bx
    loop _loop3
    
    ret
    
get_random: ; eax - result (0-9999)
    push edx
    db 0Fh, 31h ; rdtsc (read time stamp counter)
    pop edx
    ret
    
set_start_position:
    cmp screen_mode, 0
    je _set_40x25
    cmp screen_mode, 1
    je _set_40x25
    cmp screen_mode, 2
    je _set_80x25
    cmp screen_mode, 3
    je _set_80x25
    cmp screen_mode, 7
    je _set_80x25
    ret
    _set_40x25:
        mov start_x, 4
        mov start_y, 5
        ret
    _set_80x25:
        mov start_x, 20
        mov start_y, 5
        ret

print_usage:    
    mov	dx, offset usage_msg
    push ax
    mov	ah, 9
    int	21h
    pop ax
    ret
;data

screen_mode db ?
page_number db ?
start_x db 0
start_y db 0
usage_msg db "Specify mode (0, 1, 2, 3, 7) and page (0, 1, 2, 3)", 13, 10, "$"

;end data  

end main
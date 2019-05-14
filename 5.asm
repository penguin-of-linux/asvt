    .model tiny
    .code
    .386
    org 80h
    cmd_len db ?
    cmd_args db ?
    org 100h
main:
    call parse_blinking
    call parse_mode
    ;call parse_page
    call set_start_position
    cmp start_x, 0
    je print_usage
    call print_data
    ret

print_data:
    mov ah, 0fh
    int 10h ; al - текущий видеорежим, bh - текущая страница
    push ax
    push bx
    
    mov ah, 0h ; установка режима
    mov al, screen_mode
    mov bl, 1
    int 10h
    
    pop bx
    pop ax
    call draw_previous_mode_and_page
    
    cmp blinking, 0
    jne _without_blinking_set
    mov ax, 1003h
    mov bl, blinking
    int 10h
    _without_blinking_set:
    
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
        mov symbol_drawer_pointer, offset cs:simple_line_symbol_drawer
        call print_line
        jmp _continue2
        _print_first:
            mov symbol_drawer_pointer, offset cs:first_line_symbol_drawer
            call print_line
            jmp _continue2
        _print_medium:
            mov symbol_drawer_pointer, offset cs:medium_line_symbol_drawer
            call print_line
            jmp _continue2
        _print_last:
            mov symbol_drawer_pointer, offset cs:last_line_symbol_drawer
            call print_line
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
    
draw_previous_mode_and_page:
; al - текущий видеорежим, bh - текущая страница
    ;mode 
    push bx
    lea cx, mode_string
    mov current_string_addr, cx
    
    mov cx, mode_string_len
    mov current_string_len, cx
    
    lea cx, mode_value
    mov current_value_addr, cx
    
    call fill_data
    mov dh, 0
    call draw_data
    pop bx
    
    ;page 
    mov al, bh
    lea cx, page_string
    mov current_string_addr, cx
    
    mov cx, page_string_len
    mov current_string_len, cx
    
    lea cx, page_value
    mov current_value_addr, cx
    
    call fill_data
    mov dh, 1
    call draw_data
    
draw_data:
    mov ah, 13h
    mov al, 0
    mov cx, current_string_len
    mov bl, 00111010b
    mov dl, byte ptr start_x
    mov bp, current_string_addr
    int 10h
    
    mov cx, 2
    mov dl, byte ptr start_x
    add dx, current_string_len
    mov bp, current_value_addr
    int 10h
    ret
fill_data:
    pusha
    xor ah, ah
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
        _loop4:
            pop ax
            mov bx, current_value_addr
            add bx, cx
            mov byte ptr [bx], al
        loop _loop4
        popa
        ret

print_line:
; al - begin symbol
; dh - line number 
    pusha  
    push ax
    mov ax, line_length 
    mul dh
    add ax, start_x
    mov bx, ax    
    pop ax 
        
    push ds
    mov cx, 0B800h     ; сегментный адрес видеопамяти
    mov ds, cx 
    mov cx, 20h    
    _loop:
        mov dx, word ptr cs:symbol_drawer_pointer ; cs нужен, потому что мы меняем ds (все через ж)
        call dx
                
        dec cx
        
        mov byte ptr ds:[bx], 20h ; space
        inc bx
        mov byte ptr ds:[bx], 00111010b
        inc bx
        
        inc al ; следующий символ     
        loop _loop
        
    pop cx
    mov ds, cx
    popa
    ret
    
simple_line_symbol_drawer:
    mov byte ptr ds:[bx], al
    inc bx
    mov byte ptr ds:[bx], 00111010b
    inc bx    
    ret
    
first_line_symbol_drawer:
    push cx
    push ax
    ; меняем цвета буквы и фона
    call get_random
    and al, 01110111b
    mov cl, 00000000b
    or cl, al
    ; закончили менять
    pop ax
    
    mov byte ptr ds:[bx], al
    inc bx
    mov byte ptr ds:[bx], cl
    inc bx  

    pop cx    
    ret
    
medium_line_symbol_drawer:
    push cx
    push ax
    ; меняем цвета фона
    mov cl, 00000000b
    call get_random
    and al, 01110000b
    or cl, al
    ; закончили менять
    pop ax
    
    mov byte ptr ds:[bx], al
    inc bx
    mov byte ptr ds:[bx], cl
    inc bx  

    pop cx    
    ret
    
last_line_symbol_drawer:
    cmp cs:last_line_symbol_attribute, 0
    jne _draw
    
    push ax
    ; меняем цвета буквы и фона
    call get_random
    and al, 00000111b
    mov cs:last_line_symbol_attribute, 10000000b
    or cs:last_line_symbol_attribute, al
    call get_random
    and al, 01110000b
    or cs:last_line_symbol_attribute, al
    ; закончили менять   
    pop ax
    
    _draw:
    push cx
    mov cl, cs:last_line_symbol_attribute
    
    mov byte ptr ds:[bx], al
    inc bx
    
    mov byte ptr ds:[bx], cl
    inc bx 

    pop cx
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
    
parse_blinking:
    mov ah, 62h ; b
    call get_arg_by_key
    mov bl, bh ; запись значения из bh в bl
    xor bh, bh
    mov ax, [bx]
    sub al, 30h ; zero
    mov blinking, al
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
        mov word ptr start_x, 8 ; увеличено в 2 раза
        mov byte ptr start_y, 5
        mov word ptr line_length, 80 ; увеличено в 2 раза
        ret
    _set_80x25:
        mov word ptr start_x, 40 ; увеличено в 2 раза
        mov byte ptr start_y, 5
        mov word ptr line_length, 160 ; увеличено в 2 раза
        ret

print_usage:    
    mov	dx, offset usage_msg
    push ax
    mov	ah, 9
    int	21h
    pop ax
    ret
    
;data
screen_mode db 1
page_number db 0
blinking db 1

start_x dw 0
start_y db 0
line_length dw 0

symbol_drawer_pointer dw 0
last_line_symbol_attribute db 0

usage_msg db "Specify mode (0, 1, 2, 3, 7) and page (0, 1, 2, 3)", 13, 10, "$"

mode_string db "Mode "
page_string db "Page "

mode_string_len dw 5
page_string_len dw 5

mode_value db "00000"
page_value db "00000"

current_string_addr dw 0
current_string_len dw 0
current_value_addr dw 0
;end data  
end main
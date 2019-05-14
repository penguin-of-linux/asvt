    .model tiny
    .code
    .386
    org 80h
    cmd_len db ?
    cmd_args db ?
    org 100h
main:
    call parse_selfintersecting
    call parse_help
    
    cmp help_usage, 0
    jne print_help
    
    call init_state
    
    ; set new handler
    mov ax, 3509h
    int 21h
    mov word ptr old_handler, bx
    mov word ptr old_handler + 2, es
    
    mov ax, 2509h
    mov dx, offset int_handler
    int 21h
    mov ah, 0h ; установка режима
    mov al, screen_mode
    mov bl, 1
    int 10h
    
    _loop:
        cmp snake_length, 0
        je _loop_end
        call handle_keydown
        cmp al, 1
        je _loop_end        
        
        cmp is_pause, 0ffh
        je _loop
        
        call round
        
        cmp crashed, 0
        jne _loop_end
        
        call draw_field
        
        call pause
        jmp _loop
        _loop_end:
        
    mov ax, 2509h
    mov dx, word ptr old_handler + 2
    mov ds, dx
    mov dx, word ptr cs:old_handler
    int 21h
    
    call draw_end
    call wait_press_key
    
    ret
    
print_help:    
    lea	dx, help_msg
    push ax
    mov	ah, 9
    int	21h
    pop ax
    ret

; return al - code (1 if quit)
handle_keydown:   
    xor ah, ah
    mov al, key    
    
    cmp old_key, al
    je _handle_keydown_ret
    
    _handle_keydown_case:
        cmp al, 1
        je _quit_game
        cmp al, 75
        je _handle_keydown_case_75
        cmp al, 80
        je _handle_keydown_case_80
        cmp al, 77
        je _handle_keydown_case_77
        cmp al, 72
        je _handle_keydown_case_72
        cmp al, 59
        je _handle_keydown_case_59
        
        jmp _handle_keydown_case_end
        
        _handle_keydown_case_80: ; down
            cmp direction, 2
            je _handle_keydown_case_end
            mov direction, 0
            jmp _handle_keydown_case_end
        _handle_keydown_case_77: ; right            
            cmp direction, 3
            je _handle_keydown_case_end
            mov direction, 1
            jmp _handle_keydown_case_end
        _handle_keydown_case_72: ; up
            cmp direction, 0
            je _handle_keydown_case_end
            mov direction, 2
            jmp _handle_keydown_case_end
        _handle_keydown_case_75: ; left
            cmp direction, 1
            je _handle_keydown_case_end
            mov direction, 3
            jmp _handle_keydown_case_end
        _handle_keydown_case_59: ; F1
            not is_pause
            ;call change_page
            call draw_help
            jmp _handle_keydown_case_end
    _handle_keydown_case_end:
    
    _handle_keydown_ret:
    mov key, 255
    ret
    
    _quit_game:
    mov al, 1
    ret
    
draw_field:
    pusha
    
    mov cx, field_size
    dec cx
    _draw_field_loop:  
        ; set cursor
        mov ax, cx
        mov bh, 80
        div bh
        mov dh, al ; row
        mov dl, ah ; column
        mov bh, 0
        mov ah, 2
        int 10h      
        
        ; draw cell
        lea bx, field
        add bx, cx
        mov al, byte ptr [bx]
        mov ah, al
        
        lea bx, symbol_table
        xlat
        xchg ah, al ; в ah запомнили сиивол для печати, в al снова символ из field
        push ax
        lea bx, attribute_table
        xlat
        mov bl, al ; запомнили аттрибут для печати
        pop ax
        
        mov bh, 0
        push cx
        mov cx, 1
        mov al, ah
        mov ah, 09
        int 10h
        pop cx
        
        loop _draw_field_loop
    
    popa
    ret
    
draw_help:
    pusha
    
    mov ah, 0h
    mov al, screen_mode
    mov bl, 1
    int 10h
    
    lea bp, _control_by_arrows_string
    mov ah, 13h
    mov al, 1
    mov cx, 17
    mov bl, 00001010b
    mov bh, 0
    push cs
    pop es
    mov dh, 1
    mov dl, 1
    int 10h
    
    lea bp, _game_speed_control_string
    mov cx, 19
    mov bl, 00001010b
    mov dh, 2
    int 10h
    
    lea bp, _teleport_wall_string
    mov cx, 13
    mov bl, 00011010b
    mov dh, 3
    int 10h
    
    lea bp, _mirror_wall_string
    mov cx, 11
    mov bl, 01111010b
    mov dh, 4
    int 10h
    
    lea bp, _stone_wall_string
    mov cx, 10
    mov bl, 01001010b
    mov dh, 5
    int 10h
    
    lea bp, _apple_string
    mov cx, 5
    mov bl, 01011010b
    mov dh, 6
    int 10h
    
    lea bp, _stop_signal_string
    mov cx, 11
    mov bl, 01001010b
    mov dh, 7
    int 10h
    
    lea bp, _burger_string
    mov cx, 6
    mov bl, 00111010b
    mov dh, 8
    int 10h
    
    popa
    ret
    
draw_end:
    mov ah, 0h
    mov al, 3
    mov bl, 1
    int 10h
    
    ; write length 
    lea bp, _snake_length_string
    mov ah, 13h
    mov al, 0
    mov cx, 13
    mov bl, 00001010b
    mov bh, 0
    push cs
    pop es
    mov dh, 10
    mov dl, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 10
    mov dl, 15
    int 10h
    
    xor ah, ah
    mov al, cs:snake_length
    mov cl, 10
    div cl
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 10
    mov dl, 16
    int 10h
    
    xor ah, ah
    mov al, cs:snake_length
    mov cl, 10
    div cl
    mov al, ah
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    ; write score
    
    lea bp, _score_string
    mov ah, 13h
    mov al, 0
    mov cx, 6
    mov bl, 00001010b
    mov bh, 0
    push cs
    pop es
    mov dh, 11
    mov dl, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 11
    mov dl, 8
    int 10h
    
    xor ah, ah
    mov al, cs:score
    mov cl, 10
    div cl
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 11
    mov dl, 9
    int 10h
    
    xor ah, ah
    mov al, cs:score
    mov cl, 10
    div cl
    mov al, ah
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    ; write burgers
    
    lea bp, _burger_count_string
    mov ah, 13h
    mov al, 0
    mov cx, 8
    mov bl, 00001010b
    mov bh, 0
    push cs
    pop es
    mov dh, 12
    mov dl, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 12
    mov dl, 10
    int 10h
    
    xor ah, ah
    mov al, cs:burger_count
    mov cl, 10
    div cl
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 12
    mov dl, 11
    int 10h
    
    xor ah, ah
    mov al, cs:burger_count
    mov cl, 10
    div cl
    mov al, ah
    add al, 48
    mov ah, 9
    mov bh, 0
    mov bl, 00001010b
    mov cx, 1
    int 10h
    
    ; write the end
    
    lea bp, _the_end_string
    mov ah, 13h
    mov al, 0
    mov cx, 7
    mov bl, 00001010b
    mov bh, 0
    push cs
    pop es
    mov dh, 14
    mov dl, 37
    int 10h
    
    mov ah, 02
    mov bh, 0
    mov dh, 250
    mov dl, 250
    int 10h
    
    ret
    
change_page:
    pusha
    
    mov ah, 0fh
    int 10h
        
    _change_page_case:
        cmp bh, 0
        je _change_page_case_zero
        cmp bh, 1
        je _change_page_case_one
        
        jmp _change_page_case_end
        
        _change_page_case_zero:
            mov al, 1
            jmp _change_page_case_end
        _change_page_case_one:
            mov al, 0
            jmp _change_page_case_end
    _change_page_case_end:
    
    mov ah, 05h
    int 10h
    
    popa
    ret
    
round:
    pusha
    
    call move_snake
    _round_case:
        cmp cl, 6
        je _apple_case
        cmp cl, 4
        je _teleport_case
        cmp cl, 3
        je _stone_case
        cmp cl, 5
        je _mirror_case
        cmp cl, 7
        je _burger_case
        cmp cl, 8
        je _stop_signal_case
        cmp cl, 1
        je _snake_case
        
        jmp _round_case_end
        
        _apple_case:
            ; удлинняем змейку
            mov cl, 1 ; snake
            call set_field_cell
            mov cl, snake_length
            call set_snake_cell
            inc cl
            mov snake_length, cl
            call generate_apple
            call generate_stop_signal
            mov al, score
            inc al
            mov score, al
            jmp _round_case_end
        _teleport_case:
            lea bx, snake
            mov ax, word ptr [bx] ; ax - head cords
            push ax
            call get_teleport_cords ; ax - teleport cords
            mov word ptr [bx], ax ; equals set_snake_cell with cl = 0
            mov cl, 1 ; snake body
            call set_field_cell
            pop ax
            mov cl, 4 ; teleport
            call set_field_cell ; восстановили "съеденную стену"
            jmp _round_case_end
        _stone_case:
            not crashed
            jmp _round_case_end
        _mirror_case:
            mov cl, snake_length
            call set_snake_cell
            mov cl, 1 ; snake
            call set_field_cell
            lea bx, snake
            mov ax, [bx]
            push ax
        
            xor ch, ch
            mov cl, snake_length
            lea si, snake
            lea di, snake
            add di, cx
            add di, cx
            _mirror_case_loop:
                cmp si, di
                jge _mirror_case_loop_end
                
                mov ax, [si]
                mov cx, [di]
                mov [di], ax
                mov [si], cx
                
                inc si
                inc si
                dec di
                dec di
                jmp _mirror_case_loop
            _mirror_case_loop_end:
            pop ax
            mov cl, 5 ; mirror
            call set_field_cell
            mov cl, snake_length
            mov ax, 0
            call set_snake_cell
            
            xor ah, ah
            mov al, direction
            add al, 2
            mov cl, 4
            div cl
            mov direction, ah
            jmp _round_case_end
        _burger_case:
            lea bx, snake
            xor cx, cx
            mov cl, snake_length
            add bx, cx
            add bx, cx
            sub bx, 2
            mov ax, [bx]
            mov cl, 0
            call set_field_cell
            mov cl, snake_length
            dec cl
            mov snake_length, cl
            xor ax, ax
            call set_snake_cell
            call generate_burger
            mov al, burger_count
            inc al
            mov burger_count, al
            jmp _round_case_end
        _stop_signal_case:
            not crashed
            jmp _round_case_end
        _snake_case:
            cmp crash_if_intersect, 0
            je _round_case_end
            not crashed                        
            jmp _round_case_end
            
    _round_case_end:
        
    _round_ret:
    popa
    ret

; translate ax to teleport (OX axe)
get_teleport_cords:
    get_teleport_cords_case:    
        cmp ah, 0
        je get_teleport_cords_case_left
        cmp ah, 79
        je get_teleport_cords_case_right
        
        jmp get_teleport_cords_case_end
    
        get_teleport_cords_case_left:
            mov ah, 78
            jmp get_teleport_cords_case_end
        get_teleport_cords_case_right:
            mov ah, 1
            jmp get_teleport_cords_case_end
    get_teleport_cords_case_end:
    
    ret

; ax - tail cords
; cl - object ate
; return:   
move_snake:    
    lea bx, snake
    mov ax, word ptr [bx]
    mov dx, ax
    mov cl, direction
    
    _move_snake_case:
        cmp cl, 0
        je _inc_y
        cmp cl, 1
        je _inc_x
        cmp cl, 2
        je _dec_y
        cmp cl, 3
        je _dec_x
        
        jmp _move_snake_case_end
        
        _inc_x:
            inc ah
            jmp _move_snake_case_end
        _dec_x:
            dec ah
            jmp _move_snake_case_end
        _inc_y:
            inc al
            jmp _move_snake_case_end
        _dec_y:
            dec al
            jmp _move_snake_case_end        
    _move_snake_case_end:
    
    ; берем объект по координатам ax, чтобы вернуть его из функции
    call get_field_cell
    xor ch, ch
    push cx
    ;
    
    mov cl, 1
    call set_field_cell
    push ax
    
    xor cx, cx
    mov cl, snake_length
    lea bx, snake
    add bx, cx
    add bx, cx ; bx - адрес первой пустой клетки
    _move_snake_loop:    
            sub bx, 2 ; word len
            mov ax, [bx] ; snake[i - 1]
            add bx, 2
            mov [bx], ax ; snake[i] = snake[i  - 1]
            sub bx, 2
        loop _move_snake_loop
    
    pop ax
    mov cl, 0
    call set_snake_cell
    
    ; del tail
    xor cx, cx
    mov cl, snake_length
    lea bx, snake
    add bx, cx
    add bx, cx ; bx - адрес посленней клетки (лишней)
    mov ax, [bx] ; tail cords
    push ax
    mov cl, 0
    call set_field_cell
    xor ax, ax
    mov cl, snake_length
    call set_snake_cell
    
    _move_snake_ret:
    pop ax ; адрес хвоста
    pop cx ; cl - "съеденный" объект
    ret
    
generate_apple:
    pusha
    
    _generate_apple_again:
    call get_random
    push ax
    ; 80x25 - screen size in 3td mode
    mov al, ah
    xor ah, ah
    mov cl, 78
    div cl
    mov dh, ah
    inc dh
    pop ax
    xor ah, ah
    mov cl, 23
    div cl
    mov dl, ah
    inc dl
    xchg ax, dx
    
    call get_field_cell
    cmp cl, 1 ; snake
    je _generate_apple_again

    mov cl, 6 ; apple
    call set_field_cell
    
    popa
    ret
    
generate_burger:
    pusha
    
    _generate_burger_again:
    call get_random    
    push ax
    ; 80x25 - screen size in 3td mode
    mov al, ah
    xor ah, ah
    mov cl, 78
    div cl
    mov dh, ah
    inc dh
    pop ax
    xor ah, ah
    mov cl, 23
    div cl
    mov dl, ah
    inc dl
    xchg ax, dx

    call get_field_cell
    cmp cl, 1 ; snake
    je _generate_burger_again
    
    mov cl, 7 ; burger
    call set_field_cell
    
    _generate_burger_ret:
    popa
    ret
    
generate_stop_signal:
    pusha
    
    _generate_stop_signal_again:
    call get_random    
    push ax
    ; 80x25 - screen size in 3td mode
    mov al, ah
    xor ah, ah
    mov cl, 78
    div cl
    mov dh, ah
    inc dh
    pop ax
    xor ah, ah
    mov cl, 23
    div cl
    mov dl, ah
    inc dl
    xchg ax, dx

    call get_field_cell
    cmp cl, 1 ; snake
    je _generate_stop_signal_again


    push ax
    mov ax, stop_signal
    mov cl, 0
    call set_field_cell
    pop ax
    mov cl, 8 ; stop signal
    call set_field_cell
    mov stop_signal, ax
    
    popa
    ret
    
get_random: ; eax - result (0-9999)
    push edx
    db 0Fh, 31h ; rdtsc (read time stamp counter)
    pop edx
    ret
    
; ax - cords, cl - byte
; ah - x, al - y
set_field_cell:
    pusha
    
    push cx
    mov dx, ax
    lea bx, field
    mov cl, 80 ; line len   
    mul cl
    add bx, ax
    xor ax, ax
    mov al, dh
    add bx, ax
    pop cx
    mov byte ptr [bx], cl
    
    popa
    ret
    
; ax - coords
; return cl - value
get_field_cell:
    push ax
    push bx
    push dx
    
    mov dx, ax
    lea bx, field
    mov cl, 80 ; line len   
    mul cl
    add bx, ax
    xor ax, ax
    mov al, dh
    add bx, ax
    
    mov cl, byte ptr [bx]
    
    pop dx
    pop bx
    pop ax
    ret
    
; ax - cords, cl - cell cord
set_snake_cell:
    pusha
    
    xor ch, ch
    lea bx, snake
    add bx, cx
    add bx, cx
    mov word ptr [bx], ax
    
    popa
    ret
    
pause:
    mov cx, 0010h ; 1 sec
    sub cl, game_speed
    mov dx, 0000h
    mov ah, 86h
    int 15h
    ret
    
init_state:
    pusha
    
    mov ax, 0707h
    mov cl, 1
    call set_field_cell
    mov cl, 0
    call set_snake_cell
    
    mov ax, 0706h
    mov cl, 1
    call set_field_cell
    mov cl, 1
    call set_snake_cell
    
    mov ax, 0705h
    mov cl, 1
    call set_field_cell
    mov cl, 2
    call set_snake_cell
    
    mov ax, 0202h
    mov cl, 6
    call set_field_cell
    
    mov ax, 00
    xor ch, ch
    mov cl, 23
    _init_state_loop:
        mov al, cl
        push cx
        mov ah, 0
        mov cl, 4 ; teleport wall
        call set_field_cell
        mov ah, 79
        call set_field_cell
        pop cx
    loop _init_state_loop
    
    mov ax, 0023h
    xor ch, ch
    mov cl, 78
    _init_state_loop2:
        mov ah, cl
        mov al, 24
        push cx
        mov cl, 3 ; stone
        call set_field_cell
        mov al, 0
        mov cl, 5 ; mirror
        call set_field_cell
        pop cx
    loop _init_state_loop2
    
    call generate_burger
    
    popa
    ret
    
int_handler proc far
    pushf
    call cs:old_handler
    
    pusha
    cli
    
    xor bx, bx
    in al, 60h ; new code
    xor ah, ah
    cmp ax, 128
    jge _iret
    
    _int_handler_case:
        cmp al, 12
        je _int_handler_case_12
        cmp al, 13
        je _int_handler_case_13
        cmp al, 57
        je _int_handler_case_57
        
        jmp _int_handler_case_end
    
        _int_handler_case_12: ; minus
            mov ah, cs:game_speed
            cmp ah, 0
            je _int_handler_case_end
            dec ah
            mov cs:game_speed, ah
            jmp _int_handler_case_end
        _int_handler_case_13: ; plus
            mov ah, cs:game_speed
            cmp ah, 0fh
            je _int_handler_case_end
            inc ah
            mov cs:game_speed, ah
            jmp _int_handler_case_end
        _int_handler_case_57: ; space
            not cs:is_pause
            jmp _int_handler_case_end
    _int_handler_case_end:
    
    cmp al, cs:key
    je _iret
    
    mov ah, cs:key
    mov cs:old_key, ah
    mov cs:key, al

    _iret:
    popa
    sti
    iret
    int_handler endp
    
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
        
wait_press_key:
    pusha
    
    _wait_press_key_loop:
        mov ah, 0bh
        int 21h
        cmp al, 0
        je  _wait_press_key_loop
    
    popa
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
    
parse_selfintersecting:
    mov ah, 99 ; c
    call get_arg_by_key
    mov bl, bh
    xor bh, bh
    cmp bx, 80h
    jl _parse_selfintersecting_ret
    
    mov crash_if_intersect, 1
    
    _parse_selfintersecting_ret:
    ret
    
parse_help:
    mov ah, 104 ; h
    call get_arg_by_key
    mov bl, bh
    xor bh, bh
    cmp bx, 80h
    jl _parse_help_ret
    
    mov help_usage, 1
    
    _parse_help_ret:
    ret

; variables

screen_mode db 3
old_handler dd ?
key db 255
old_key db 255

snake dw 100 DUP (0)
snake_length db 3
field db 2000 DUP (0) ; 80*25
field_size dw 2000
symbol_table db "         "
attribute_table db 0, 32, 0, 68, 17, 119, 90, 51, 68
direction db 0 ; 0 - down, 1 - right, 2 - up, 3 - left
game_speed db 13
is_pause db 0
crashed db 0
stop_signal dw 0
score db 0
burger_count db 0
crash_if_intersect db 0
help_usage db 0

_control_by_arrows_string db 'Control by arrows'
_game_speed_control_string db 'Change speed by -/+'
_teleport_wall_string db 'Teleport wall'
_mirror_wall_string db 'Mirror wall'
_stone_wall_string db 'Stone wall'
_apple_string db 'Apple'
_stop_signal_string db 'Stop signal'
_burger_string db 'Burger'
_the_end_string db 'The end'
_snake_length_string db 'Snake length:'
_score_string db 'Score:'
_burger_count_string db 'Burgers:'
help_msg db '[c] - snake will be crashed when intersect itself', 13, 10, '[h] - print this message', 13, 10, 'F1 in game will show help', 13, 10, '$'

; end variables

; const
; 0 - empty
; 1 - snake
; 2 - reserved
; 3 - stone wall
; 4 - teleport wall
; 5 - mirror wall
; 6 - apple (+)
; 7 - burger (-)
; 8 - end of game artifact

end main
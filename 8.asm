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
        xor ah, ah
        xor bx, bx
        mov bl, head_pointer
        add bx, offset array
        dec bx
        mov al, byte ptr [bx]        
        
        cmp al, 1 ; esc
        je _loop_end
        
        cmp al, 57 ; space
        je easter_egg_sherlock
        
        cmp al, 255 ; empty
        je _loop_no_sound
        
        sub al, 16 ; q
        add al, al
        xor bx, bx
        mov bl, al
        add bx, offset notes
        mov ax, word ptr [bx]
        
        call sound
        jmp _loop
        
        _loop_no_sound:
            call no_sound
        
    jmp _loop
    _loop_end:
    
    mov ax, 2509h
    mov dx, word ptr old_handler + 2
    mov ds, dx
    mov dx, word ptr cs:old_handler
    int 21h
    
    ret
    
easter_egg_sherlock:
    call easter_egg_notes_sherlock
    jmp _loop_end
    
sound:
    mov	dx, 12h		; минимально допустимая частота (18 Гц)
    cmp	ax, dx		; если AX <= 18 Гц,
    jbe	sound_ret		; то на выход, чтобы избежать переполнения при делении
    xchg cx, ax		; CX = частота
    in	al, 61h		; получаем значение из управляющего регистра порта B PPI (контроллера 8255)
    or	al, 3		; устанавливаем биты 0 и 1 (включить спикер и использовать 2-й канал для генерации импульсов спикера)
    out	61h, al		; выводим значение в управляющий регистр
    mov	al, 10110110b	; управляющее слово таймера: канал 2; сначала записать младший байт, затем старший; режим 3 (прямоугольный генератор импульсов); двоичное слово
    out	43h, al		; выводим значение в порт таймера
    mov	ax, 34DDh	; DX:AX = 1193181 - частота работы таймера
    div	cx		; значение счётчика таймера AX = DX:AX / CX
    out	42h, al		; выводим младший байт счетчика во 2-й канал таймера
    mov	al ,ah
    out	42h, al		; выводим старший байт
    
    sound_ret:
    ret
    
no_sound:
    in	al, 61h		; получаем значение из управляющего регистра порта B PPI (контроллера 8255)
    and	al, not 3	; сбрасываем биты 0 и 1 (отключить спикер и использование 2-го канала таймера для генерации импульсов спикера)
    out	61h, al		; выводим значение в управляющий регистр порта B PPI (контроллера 8255)
    ret
        
pause16:
    mov cx, 0002h
    mov dx, 0500h
    mov ah, 86h
    int 15h
    ret
    
pause8:
    mov cx, 0005h
    mov dx, 0000h
    mov ah, 86h
    int 15h
    ret
    
pause4:
    mov cx, 0010h
    mov dx, 0000h
    mov ah, 86h
    int 15h
    ret
    
pause2:
    mov cx, 0020h
    mov dx, 0000h
    mov ah, 86h
    int 15h
    ret    
    
pause1:
    mov cx, 0040h
    mov dx, 0000h
    mov ah, 86h
    int 15h
    ret
        
int_handler proc far
        pushf
        call cs:old_handler
        
        pusha
        cli
        
        xor bx, bx
        in al, 60h ; new code
        mov bl, cs:head_pointer
        dec bl
        add bx, offset array ; old code address
        mov ah, byte ptr [bx] ; old code
        
        cmp al, 57 ; space
        je _write_new_code
        
        cmp al, ah
        je _iret
        cmp al, 1 ; esc
        je _write_new_code
        
        xor ah, ah ; надо, иначе cmp не работает
        cmp ax, 16 ; q (press)
        jl _iret        
        cmp ax, 41 ; 40 - '(э) (press)
        jl _write_new_code        
        cmp ax, 144 ; q (up)
        jl _iret
        cmp ax, 169 ; 168 - '(э) (up)
        jl _delete_code
        jmp _iret
        
        _write_new_code:
            inc bx
            mov byte ptr [bx], al
            inc cs:head_pointer
            jmp _iret
            
        _delete_code:
            sub al, 128
            xor ch, ch
            mov cl, array_len
            add cx, 2 ; костыль - первые 2 элемента массива всегда пустые
            lea bx, array
            mov cs:head_pointer, 1
            _delete_code_loop:
                cmp byte ptr [bx], al
                jne _delete_code_set_header
                
                mov byte ptr [bx], 255
                    
                _delete_code_set_header:
                cmp byte ptr [bx], 255
                je _delete_code_loop_continue
                
                push bx
                sub bx, offset array
                mov cs:head_pointer, bl
                inc cs:head_pointer
                pop bx
                
                _delete_code_loop_continue:
                inc bx                
            loop _delete_code_loop
  
        _iret:
        popa
        sti
        iret
        int_handler endp
        
array db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ; 12
head_pointer db 1 ; указывает на следущее пустое значение
array_len db 10 
old_handler dd ?
;         q    w    e    r    t    y    u    i   o    p    [     ]           entr  ?  a     s     d     f     g     h     j     k     l     ;     '
;notes dw 523, 554, 587, 622, 659, 698, 740, 784, 831, 880, 932, 988,        1046, 0, 1109, 1175, 1244, 1318, 1397, 1480, 1568, 1661, 1720, 1865, 1975
notes:
    do1 dw 523
    do_sharp1 dw 554
    re1 dw 587
    re_sharp1 dw 622
    mi1 dw 659
    fa1 dw 698
    fa_sharp1 dw 740
    sol1 dw 784
    sol_sharp1 dw 831
    la1 dw 880
    la_sharp1 dw 932
    si1 dw 988

    do2 dw 1046
    zero dw 0
    do_sharp2 dw 1109
    re2 dw 1175
    re_sharp2 dw 1244
    mi2 dw 1318
    fa2 dw 1397
    fa_sharp2 dw 1480
    sol2 dw 1568
    sol_sharp2 dw 1661
    la2 dw 1720
    la_sharp2 dw 1865
    si2 dw 1975
    
easter_egg_notes_sherlock:
    mov ax, do1 ; 1 такт
    call sound
    call pause8
    call no_sound
    
    mov ax, sol1
    call sound
    call pause8
    call no_sound
    
    call pause8
    
    mov ax, sol1
    call sound
    call pause8
    call no_sound
    
    mov ax, fa_sharp1
    call sound
    call pause16
    call no_sound
    
    mov ax, sol1
    call sound
    call pause16
    call no_sound
    
    mov ax, sol_sharp1
    call sound
    call pause8
    call pause16
    call no_sound
    
    call pause16
    
    mov ax, sol1
    call sound
    call pause8
    call no_sound
    
    mov ax, fa1 ; 2 такт
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause2
    call no_sound
    
    call pause16
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, fa1 ; 3 такт
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    call pause8
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, si1
    call sound
    call pause16
    call no_sound
    
    mov ax, do2
    call sound
    call pause16
    call no_sound
    
    mov ax, re2
    call sound
    call pause4
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, re_sharp2 ; 4 такт
    call sound
    call pause2
    call no_sound
    
    call pause8
    
    mov bx, 2
    repriza:
    dec bx
    
    mov ax, sol2 ; 5 такт
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    call pause8
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, re2
    call sound
    call pause8
    call no_sound
    
    mov ax, re_sharp2
    call sound
    call pause8
    call no_sound
    
    mov ax, re2
    call sound
    call pause16
    call no_sound
    
    mov ax, re_sharp2
    call sound
    call pause16
    call no_sound
    
    mov ax, re2
    call sound
    call pause16
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause16
    call no_sound
    
    mov ax, fa2 ; 6 такт 
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    call pause8
    
    call pause4
    
    mov ax, do2
    call sound
    call pause16
    call no_sound
    
    mov ax, re2
    call sound
    call pause16
    call no_sound
    
    mov ax, re_sharp2 ; 7 такт 
    call sound
    call pause8
    call no_sound
    
    mov ax, re_sharp2
    call sound
    call pause16
    call no_sound
    
    mov ax, fa2
    call sound
    call pause16
    call no_sound
    
    mov ax, re2
    call sound
    call pause8
    call no_sound
    
    mov ax, re2
    call sound
    call pause16
    call no_sound
    
    mov ax, re_sharp2
    call sound
    call pause16
    call no_sound
    
    mov ax, do2
    call sound
    call pause8
    call no_sound
    
    mov ax, do2
    call sound
    call pause16
    call no_sound
    
    mov ax, re2
    call sound
    call pause16
    call no_sound
    
    mov ax, si1
    call sound
    call pause8
    call no_sound
    
    mov ax, sol_sharp1
    call sound
    call pause16
    call no_sound
    
    mov ax, sol1
    call sound
    call pause16
    call no_sound
    
    mov ax, do2 ; 8 такт
    call sound
    call pause2
    call no_sound
    
    cmp bx, 0
    jne call_repriza
    
    ret
    
    call_repriza:
        call repriza
        ret
end main
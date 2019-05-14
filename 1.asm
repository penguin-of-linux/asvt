    .model tiny
    .code
    org	80h
    cmd_len db ?
    cmd_line db ?
    org 100h
    
start:
    jmp main
    msg	db "Hello TASM",10,13, '$'
resident_end:
    usage_msg db "Specify t or f parameter (f - use function, i - use interrupt)",10,13, '$'
    func_using_msg db "Made resident by func", 10, 13, '$'
    int_using_msg db "Made resident by int", 10, 13, '$'
main:
    cmp cmd_len, 2
    jne print_usage
    
    cld    
    mov di, offset cmd_line          
    inc di
    mov si,di 
    lodsb
    
    cmp al, 102                     ; 'f'
        je make_resident_by_func
    cmp al, 105                     ; 'i'
        je make_resident_by_int
        
    jmp print_usage
    
    make_resident_by_int:
        mov dx, offset int_using_msg
        call print
        mov dx, offset resident_end
        int 27h
        
    make_resident_by_func:
        mov dx, offset func_using_msg
        call print
        mov dx, offset resident_end
        shr dx, 4
        mov ax, 3100h
        int 21h
    
print_usage:
    mov	dx, offset usage_msg
    call print
    ret
    
print:
    push ax
    mov	ah, 9
    int	21h
    pop ax
    ret
end start
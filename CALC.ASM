.model small
.stack 100h
.data
head db "Interest Calculator",13,10, "$"
options db "1. Simple Interest",13,10,"2. Compound Interest",13,10,"3. Exit$"
question db "Options: $"
opt1 db "Yes its 1. Simple Interest$"
opt2 db "Compounding Interest with monthly contribution$"
principal_qt db "What is the principal: $"
monthly_qt db "What is the monthly contribution: $"
rate_qt db "What is the annual interest rate (percentage): $"
term_qt db "What is the term (year): $"
compound_qt db "What is the compound frequency: $"

; buffer for compound
;12 maximum number allowed ;0 current length ;12 space reservation
pbuf db 12,0,12 dup(?)
mbuf db 12,0,12 dup(?)
rbuf db 12,0,12 dup(?)
tbuf db 12,0,12 dup(?)
cbuf db 12,0,12 dup(?)
; numeric
nm dd ?, ?, ?, ?, ? ; p,m,r,t,c
rt dd ?,?,? ; ct,
.code
begin:
    mov ax, @data
    mov ds, ax

    mov ah, 09h
    mov dx, offset head
    int 21h
mainloop:
    mov ah,09h ; print options
    mov dx, offset options
    int 21h

    call nl ; new line

    mov ah,09h ; p
    mov dx, offset question
    int 21h
    
    mov ah, 01h ; ask user for one char
    int 21h
    mov bl, al

    cmp bl, '1' ; if entered 1 call simple interest calculator
    je simple

    cmp bl, '2' ; if entered 2 call simple compounding interest calculator
    je compound

    cmp bl, '3' ; if entered 3 call exits the app
    je exitapp

    jmp mainloop ; if entered none of the option jump to mainloop

nl PROC ; create new line
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret
nl ENDP

exitapp PROC
    mov ah, 4ch
    int 21h
    ret
exitapp ENDP

simple PROC
    call nl
    mov ah, 09h
    mov dx, offset opt1
    int 21h

    call nl

    jmp mainloop
simple ENDP

compound PROC
    call nl
    mov ah, 09h
    mov dx, offset opt2
    int 21h

    call nl
    ; PRINCIPAL
    mov ah, 09h
    mov dx, offset principal_qt ; print
    int 21h

    mov ah, 0Ah; ask for input
    mov dx, offset pbuf ; place the length at pbuf+1 and chars +2
    int 21h
    ; Monthly
    call nl
    mov ah, 09h
    mov dx, offset monthly_qt; print
    int 21h
    
    mov ah, 0Ah
    mov dx, offset mbuf
    int 21h
    call nl
    ; RATE
    mov ah, 09h 
    mov dx, offset rate_qt  ; print
    int 21h
    
    mov ah, 0Ah
    mov dx, offset rbuf
    int 21h
    call nl
    mov ah, 09h
    mov dx, offset term_qt ; print
    int 21h
    ; Term
    mov ah, 0Ah
    mov dx, offset tbuf
    int 21h
    call nl
    mov ah, 09h 
    mov dx, offset compound_qt ; print
    int 21h
    ; Compount
    mov ah, 0Ah
    mov dx, offset cbuf
    int 21h

    call nl
    ; storing the value to var at .data
    mov cl, pbuf+1
    lea si, pbuf+2 ; load effective address
    
    call asciiToDigit ; convert ascii to digit
    mov word ptr nm, ax ; store low bit at ax
    mov word ptr nm+2,dx ; high bit at dx

    mov cl, mbuf+1
    lea si, mbuf+2
    
    call asciiToDigit
    mov word ptr nm+4, ax
    mov word ptr nm+6, dx

    mov cl, rbuf+1
    lea si, rbuf+2
    
    call asciiToDigit
    mov word ptr nm+8, ax
    mov word ptr nm+10, dx

    mov cl, tbuf+1
    lea si, tbuf+2
    
    call asciiToDigit
    mov word ptr nm+12, ax
    mov word ptr nm+14, dx

    mov cl, cbuf+1
    lea si, cbuf+2
    
    call asciiToDigit
    mov word ptr nm+16, ax
    mov word ptr nm+18, dx

    ; get term * compounding
    mov ax, word ptr nm+12 ; ax = time
    mul word ptr nm+16 ; T x C

    ; store the output

    mov word ptr rt, ax ; store ct lower bit
    mov word ptr rt+2, dx ; store ct higher bit

    ; P (1+i/c) ^ct
    mov ax, word ptr nm+8 ; get rate
    mov bx, 100
    mul bx ; multiply by 9999
    xor dx,dx
    div word ptr nm+16


    add ax, 10000 ; this is 1 in formula but scaled by 10000

    mov bx,ax ; current
    mov ax,10000 ; base
    xor dx,dx

    mov si, word ptr rt ; get (C)(T)
    mov di, word ptr rt+2

exponential_growth:

    ; 32-bit multiply
    mul bx                ; DX:AX = result * base

    ; ----- safe 32-bit / 10000 -----
    push ax               ; save low

    mov ax,dx             ; divide high word
    xor dx,dx
    mov cx,10000
    div cx                ; AX = high quotient, DX = remainder

    mov bp,ax             ; store high quotient
    pop ax                ; restore low

    div cx                ; divide low word with remainder

    mov dx,bp             ; rebuild DX:AX quotient
    ; --------------------------------

    sub si,1
    sbb di,0

    cmp di,0
    jne exponential_growth
    cmp si,0
    jne exponential_growth

    mov word ptr rt+4, ax; store (1+i/c)^ct for other use lower bit
    mov word ptr rt+6, dx; store (1+i/c)^ct for other use higher bit

    mov bx, word ptr nm
    mul bx
    mov bx, 10000
    call divider

    mov ax, word ptr nm
    mov dx, word ptr nm+2
    mov bx, 100
    call multiplier

    call printAXDX
    call nl

    jmp mainloop
compound ENDP


; returns ax as digit (32 bit)
asciiToDigit PROC
    xor ax,ax
    xor dx,dx          ; DX:AX = 0

convert:
    mov bl,[si]
    sub bl,'0'
    xor bh,bh          ; BX = digit

    ; save current value
    mov bp,ax
    mov di,dx

    ; DX:AX = value * 2
    shl ax,1
    rcl dx,1

    ; BP:DI = value * 8
    shl bp,1
    rcl di,1
    shl bp,1
    rcl di,1
    shl bp,1
    rcl di,1

    ; DX:AX = value * 10
    add ax,bp
    adc dx,di

    ; add digit
    add ax,bx
    adc dx,0

    inc si
    loop convert
    ret
asciiToDigit ENDP

; print ax only not dx (16bit)
printAX PROC
    mov cx, 0
    mov bx,10
    mov di,si

convert_loop:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne convert_loop

print_loop:
    pop ax
    add al, '0'
    mov [si], al
    inc si
    loop print_loop

    mov byte ptr [si], '$'

    mov dx,di
    mov ah, 09h
    int 21h

    ret

printAX ENDP

;print ax and dx (32bit)
printAXDX PROC
    mov bx,10
    xor cx,cx
    mov di,si          ; save buffer start

convert_loop2:
    push ax            ; save low word

    mov ax,dx
    xor dx,dx
    div bx             ; divide high word
                       ; AX = high quotient
                       ; DX = remainder

    mov bp,ax          ; save high quotient
    pop ax             ; restore low word

    div bx             ; divide low word with remainder
                       ; AX = low quotient
                       ; DX = digit remainder

    push dx
    inc cx

    mov dx,bp          ; rebuild DX:AX quotient

    cmp dx,0
    jne convert_loop2
    cmp ax,0
    jne convert_loop2

print_loop2:
    pop dx
    add dl,'0'
    mov [si],dl
    inc si
    loop print_loop2

    mov byte ptr [si],'$'

    mov dx,di
    mov ah,09h
    int 21h
    ret
printAXDX ENDP
;32 bit divider usage (dx:ax) / bx
divider PROC

    push bx
    push cx
    push bp

    push ax          ; save low word

    mov ax,dx        ; divide high word
    xor dx,dx
    div bx           ; AX = high quotient, DX = remainder

    mov bp,ax        ; store high quotient
    pop ax           ; restore low word

    div bx           ; divide low with remainder

    mov dx,bp        ; rebuild 32-bit quotient

    pop bp
    pop cx
    pop bx
    ret

divider ENDP
; 32 bit multiplier usage (dx:ax) * bx
multiplier PROC
    ; input:
    ;   DX:AX = 32-bit value
    ;   BX    = multiplier
    ; output:
    ;   DX:AX = result (low 32 bits)

    push ax
    push dx
    push cx

    mov cx,ax        ; save low word

    mov ax,dx        ; high * BX
    mul bx           ; DX:AX
    mov dx,ax        ; high contribution
    mov ax,cx        ; restore low

    mul bx           ; low * BX → DX:AX

    add dx,dx        ; combine high parts
    adc dx,0

    pop cx
    pop dx
    pop ax
    ret
multiplier ENDP


end begin
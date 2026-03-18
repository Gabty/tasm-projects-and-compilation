; A semi 32 bit calculator that runs in assembly
.model small
.stack 100h
.data

;Header
head db "Interest Calculator",13,10, "$"

;Options Begin
question db "Options: $"
options db "1. Future Value of Simple Interest",13,10
        db "2. Future Value of Compounding Interest",13,10
        db "3. Logout$"
choice db "Choice: $"

;Response on call
opt1 db "Future Value of Simple Interest$"
opt2 db "Future Value of Compounding Interest$"
opt3 db "Logging out...$"


;Request user inputs
principal_qt db "What is the principal: $"
rate_qt db "What is the annual interest rate (percentage): $"
term_qt db "What is the term (year): $"
compound_qt db "What is the compound frequency: $"
answer_cmp db "Future Value: $"
error_msg db ">>> ERROR: Invalid option! <<<",13,10
          db "Please choose 1, 2, or 3 only.",13,10,"$"

; Login handler
login_prompt db "======= LOGIN REQUIRED =======",13,10
             db " ",13,10
             db "Username: $"
password_prompt db "Password: $"
login_success db "Login successful!",13,10,"$"
login_failed db "Invalid credentials! Access denied.",13,10,"$"
welcome_msg db "Welcome to the Interest Calculator!",13,10,"$"
try_again db "Press any key to try again...$"

; Input validation messages
invalid_input_msg db ">>> ERROR: Invalid input! Please enter a positive number.",13,10,"$"
empty_input_msg db ">>> ERROR: Input cannot be empty!",13,10,"$"
space_input_msg db ">>> ERROR: Input cannot be spaces only!",13,10,"$"

; Username/password buffers
userbuf db 20,0,21 dup(?)  ; 20 char max for username
passbuf db 20,0,21 dup(?)  ; 20 char max for password

; Hardcoded credentials
valid_username db "root",0  
valid_password db "admin",0 


; Principal buffer: max 7 chars, actual length, 8 bytes storage: we limit max numbers to avoid overflow
pbuf db 7,0,8 dup(?)

; Rate buffer: max 2 chars (0-99%), actual length, 3 bytes storage
rbuf db 2,0,3 dup(?)

; Term buffer: max 3 chars (0-99 years), actual length, 4 bytes storage
tbuf db 3,0,4 dup(?)

; Compound frequency buffer: max 3 chars, actual length, 4 bytes storage
cbuf db 3,0,4 dup(?)

; Numeric holders: 4 doublewords for principal, rate, term, compound
nm dd ?, ?, ?, ?

; Runtime storage: 3 doublewords for calculations
rt dd ?, ?, ?
.code

begin:
    mov ax, @data
    mov ds, ax

    ; Print header (once at startup)
    call title_header
    
    ; REQUIRE LOGIN BEFORE ACCESSING CALCULATOR
    call login         ; Will loop until successful login

mainloop:
    call nl
    mov ah,09h
    mov dx, offset question
    int 21h

    call nl
    mov ah,09h
    mov dx, offset options
    int 21h

    call nl
    mov ah,09h
    mov dx, offset choice
    int 21h

    mov ah, 01h
    int 21h
    mov bl, al ;no another 21h coz no need to wait for another user input


    ;Base if statement
    cmp bl, '1' ; if entered 1 call simple interest calculator
    jne compound_block ;jump to next if statement
    jmp simple

compound_block:
    cmp bl, '2' ; if entered 2 call simple compounding interest calculator
    jne exit_block ;jump to next if statement
    jmp compound

exit_block:
    cmp bl, '3' ; if entered 3, logout
    jne invalid_choice
    jmp logout
    
logout PROC
    call nl
    mov ah, 09h
    mov dx, offset opt3
    int 21h
    call nl
    call nl
    
    ; Clear buffers for next login
    mov byte ptr [userbuf+1], 0
    mov byte ptr [passbuf+1], 0
    
    ; Return to login screen
    call login
    jmp mainloop
logout ENDP
    
invalid_choice:
    call nl
    mov ah, 09h
    mov dx, offset error_msg
    int 21h
    jmp mainloop

title_header PROC
    ; Print top line
    call nl     
    call liner   
    call nl      

    ; Print title
    mov ah, 09h       ; Set DOS string function
    mov dx, offset head
    int 21h           ; Print "Interest Calculator" + CR+LF

    ; Print bottom line
    call liner   
    call nl   
title_header ENDP

login PROC
    ; Save registers
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
login_attempt:
    call nl
    call nl
    
    ; Print login header
    mov ah, 09h
    mov dx, offset login_prompt
    int 21h
    
    ; Get username
    mov ah, 0Ah
    mov dx, offset userbuf
    int 21h

    call nl
    
    ; Get password (with asterisks)
    mov ah, 09h
    mov dx, offset password_prompt
    int 21h
    
    ; Custom password input (shows * instead of characters)
    call get_password
    
    call nl
    
    ; Validate credentials
    call validate_login
    cmp ax, 1          ; 1 = success, 0 = failure
    je login_successful
    
    ; LOGIN FAILED - Show error and try again
    call nl
    mov ah, 09h
    mov dx, offset login_failed
    int 21h
    
    mov ah, 09h
    mov dx, offset try_again
    int 21h
    
    ; Wait for key press
    mov ah, 01h
    int 21h
    
    jmp login_attempt  ; Try again
    
login_successful:
    call nl
    mov ah, 09h
    mov dx, offset login_success
    int 21h
    
    ; Restore registers
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    call welcome_handler
    jmp mainloop              
login ENDP

; Custom password input (shows *)
get_password PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, offset passbuf+2  ; Where to store password
    xor cx, cx                 ; Character counter
    
get_char:
    mov ah, 08h                ; DOS function: read without echo
    int 21h
    
    cmp al, 13                 ; Enter key?
    je password_done
    
    cmp al, 8                  ; Backspace?
    je handle_backspace
    
    ; Store character
    mov [si], al
    inc si
    inc cx
    
    ; Print asterisk
    mov ah, 02h
    mov dl, '*'
    int 21h
    
    jmp get_char
    
handle_backspace:
    cmp cx, 0                  ; Nothing to delete?
    je get_char
    
    dec si
    dec cx
    
    ; Move cursor back, print space, move back again
    mov ah, 02h
    mov dl, 8                  ; Backspace
    int 21h
    mov dl, ' '                ; Space (erase the *)
    int 21h
    mov dl, 8                  ; Backspace again
    int 21h
    
    jmp get_char
    
password_done:
    mov byte ptr [si], 0       ; Null terminate
    mov al, cl
    mov [passbuf+1], al        ; Store length
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
get_password ENDP

; Validate username and password
validate_login PROC
    push bx
    push cx
    push si
    push di
    
    ; Clean the input strings first
    lea si, userbuf+2
    call strip_crlf
    
    lea si, passbuf+2
    call strip_crlf
    
    ; Check username
    lea si, userbuf+2          ; Entered username
    lea di, valid_username     ; Valid username
    call compare_strings
    cmp ax, 0
    jne validate_fail          ; Username mismatch
    
    ; Check password
    lea si, passbuf+2          ; Entered password
    lea di, valid_password     ; Valid password
    call compare_strings
    cmp ax, 0
    jne validate_fail
    
    ; Login successful
    mov ax, 1
    jmp validate_done
    
validate_fail:
    xor ax, ax                 ; AX = 0 (failure)
    
validate_done:
    pop di
    pop si
    pop cx
    pop bx
    ret
validate_login ENDP

; Compare two null-terminated strings
; SI = string1, DI = string2
; Returns AX = 0 if equal, 1 if different
compare_strings PROC
    push si
    push di
    push cx
    
compare_loop:
    mov al, [si]
    mov bl, [di]
    
    cmp al, bl
    jne strings_different
    
    cmp al, 0                  ; End of string?
    je strings_equal
    
    inc si
    inc di
    jmp compare_loop
    
strings_different:
    mov ax, 1
    jmp compare_done
    
strings_equal:
    xor ax, ax                 ; AX = 0
    
compare_done:
    pop cx
    pop di
    pop si
    ret
compare_strings ENDP

; Strip carriage return and line feed from string
; SI = string to clean
strip_crlf PROC
    push ax
    push si
    
strip_loop:
    mov al, [si]
    cmp al, 13        ; Carriage return?
    je strip_replace
    cmp al, 10        ; Line feed?
    je strip_replace
    cmp al, 0         ; End of string?
    je strip_done
    inc si
    jmp strip_loop
    
strip_replace:
    mov byte ptr [si], 0  ; Replace with null terminator
    
strip_done:
    pop si
    pop ax
    ret
strip_crlf ENDP

; Validate if string contains only digits
; SI = pointer to string, CL = length
; Returns AL = 0 if valid, 1 if empty, 2 if invalid chars
validate_input PROC
    push bx
    push cx
    push si
    
    ; Check if empty
    cmp cl, 0
    je input_empty
    
    ; Check for spaces only
    push cx
    push si
    mov ch, 0
check_spaces:
    mov al, [si]
    cmp al, ' '        ; Space character
    jne has_digits
    inc si
    loop check_spaces
    pop si
    pop cx
    ; If we get here, all were spaces
    jmp input_spaces
    
has_digits:
    pop si
    pop cx
    
    ; Check each character is a digit
    mov ch, 0
    mov bx, si
    
check_digits:
    mov al, [bx]
    
    ; Allow digits 0-9 only
    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit
    
    inc bx
    loop check_digits
    
    ; All characters are digits
    pop si
    pop cx
    pop bx
    mov al, 0        ; Valid
    ret
    
not_digit:
    pop si
    pop cx
    pop bx
    mov al, 2        ; Contains non-digit
    ret
    
input_empty:
    pop si
    pop cx
    pop bx
    mov al, 1        ; Empty
    ret
    
input_spaces:
    pop si
    pop cx
    pop bx
    mov al, 3        ; Only spaces
    ret
validate_input ENDP

welcome_handler PROC
    ; Print top line
    call nl
    call nl     
    call liner   
    call nl    

    ; Print message
    mov ah, 09h
    mov dx, offset welcome_msg
    int 21h

    ; Print bottom line
    call liner   
welcome_handler ENDP

nl PROC ; create new line
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret
nl ENDP

;Exiter, ceased to use but maybe in the future so we'll preserve this here
exitapp PROC
    call nl
    mov ah, 09h
    mov dx, offset opt3
    int 21h
    mov ah, 4ch
    int 21h
    ret
exitapp ENDP

simple PROC
    call nl
    call nl
    call nl
    call liner ; liner ============
    call nl
    mov ah, 09h
    mov dx, offset opt1 ; HEADER
    int 21h
    call nl ; NEW LINE
    call liner ; liner ============
    call nl

    ;PRINCIPAL - WITH VALIDATION
get_principal:
    mov ah, 09h
    mov dx, offset principal_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset pbuf
    int 21h
    call nl
    
    ; Validate principal
    mov cl, pbuf+1
    lea si, pbuf+2
    call validate_input
    
    cmp al, 0
    je principal_ok
    cmp al, 1
    je principal_empty
    cmp al, 3
    je principal_spaces
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_principal
    
principal_empty:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_principal
    
principal_spaces:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_principal
    
principal_ok:
    ; Convert principal
    mov cl, pbuf+1
    lea si, pbuf+2
    call asciiToDigit
    mov word ptr nm, ax
    mov word ptr nm+2, dx

    ;RATE - WITH VALIDATION
get_rate:
    mov ah, 09h
    mov dx, offset rate_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset rbuf
    int 21h
    call nl
    
    ; Validate rate
    mov cl, rbuf+1
    lea si, rbuf+2
    call validate_input
    
    cmp al, 0
    je rate_ok
    cmp al, 1
    je rate_empty
    cmp al, 3
    je rate_spaces
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_rate
    
rate_empty:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_rate
    
rate_spaces:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_rate
    
rate_ok:
    ; Convert rate
    mov cl, rbuf+1
    lea si, rbuf+2
    call asciiToDigit
    mov word ptr nm+4, ax
    mov word ptr nm+6, dx

    ; TERM - WITH VALIDATION
get_term:
    mov ah, 09h
    mov dx, offset term_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset tbuf
    int 21h
    call nl
    
    ; Validate term
    mov cl, tbuf+1
    lea si, tbuf+2
    call validate_input
    
    cmp al, 0
    je term_ok
    cmp al, 1
    je term_empty
    cmp al, 3
    je term_spaces
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_term
    
term_empty:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_term
    
term_spaces:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_term
    
term_ok:
    ; Convert term
    mov cl, tbuf+1
    lea si, tbuf+2
    call asciiToDigit
    mov word ptr nm+8, ax
    mov word ptr nm+10, dx

    ; process - scaling rate in 100
    ; getting Rate x Time
    
    ; get the ax, dx of rate
    mov ax, word ptr nm+4 ; lower bit
    mov dx, word ptr nm+6 ; higher bit
    mov bx, 100 ; scaler
    call multiplier; rate is now scaled; output = Rate*100
    
    mov bx, word ptr nm+8
    call multiplier ; multiply it with time; output = Rate*100*Time
    
    mov bx, 10000
    call adder ; add 100 ; output = 100 + Rate*100*Time

    ; saving the output = 100 + Rate*100*Time in rt
    mov word ptr rt, ax
    mov word ptr rt+2, dx

    ; load principal
    mov ax, word ptr nm
    mov dx, word ptr nm+2

    mov bx, word ptr rt ; load the (1+rt) scaled to 100
    call multiplier ; output = P(100+100RT)
    mov bx,10000
    call divider ; remove the scaler and return to normal

    ;save it in rt+4
    mov word ptr rt+4, ax
    mov word ptr rt+6, dx

    ; outputting now
    call nl
    call liner
    call nl

    mov ah, 09h
    mov dx, offset answer_cmp
    int 21h

    mov ax, word ptr rt+4
    mov dx, word ptr rt+6

    call printAXDX
    call nl
    call liner
    call nl
    jmp mainloop
simple ENDP

compound PROC
    call nl
    call nl
    call nl
    call liner ; liner ============
    call nl
    mov ah, 09h
    mov dx, offset opt2
    int 21h
    call nl
    call liner ; liner ============
    call nl
    
    ; PRINCIPAL - WITH VALIDATION
get_principal_c:
    mov ah, 09h
    mov dx, offset principal_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset pbuf
    int 21h
    call nl
    
    ; Validate principal
    mov cl, pbuf+1
    lea si, pbuf+2
    call validate_input
    
    cmp al, 0
    je principal_ok_c
    cmp al, 1
    je principal_empty_c
    cmp al, 3
    je principal_spaces_c
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_principal_c
    
principal_empty_c:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_principal_c
    
principal_spaces_c:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_principal_c
    
principal_ok_c:
    ; Convert principal
    mov cl, pbuf+1
    lea si, pbuf+2
    call asciiToDigit
    mov word ptr nm, ax
    mov word ptr nm+2, dx

    ; RATE - WITH VALIDATION
get_rate_c:
    mov ah, 09h
    mov dx, offset rate_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset rbuf
    int 21h
    call nl
    
    ; Validate rate
    mov cl, rbuf+1
    lea si, rbuf+2
    call validate_input
    
    cmp al, 0
    je rate_ok_c
    cmp al, 1
    je rate_empty_c
    cmp al, 3
    je rate_spaces_c
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_rate_c
    
rate_empty_c:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_rate_c
    
rate_spaces_c:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_rate_c
    
rate_ok_c:
    ; Convert rate
    mov cl, rbuf+1
    lea si, rbuf+2
    call asciiToDigit
    mov word ptr nm+4, ax
    mov word ptr nm+6, dx

    ; TERM - WITH VALIDATION
get_term_c:
    mov ah, 09h
    mov dx, offset term_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset tbuf
    int 21h
    call nl
    
    ; Validate term
    mov cl, tbuf+1
    lea si, tbuf+2
    call validate_input
    
    cmp al, 0
    je term_ok_c
    cmp al, 1
    je term_empty_c
    cmp al, 3
    je term_spaces_c
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_term_c
    
term_empty_c:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_term_c
    
term_spaces_c:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_term_c
    
term_ok_c:
    ; Convert term
    mov cl, tbuf+1
    lea si, tbuf+2
    call asciiToDigit
    mov word ptr nm+8, ax
    mov word ptr nm+10, dx

    ; COMPOUND FREQUENCY - WITH VALIDATION
get_compound_c:
    mov ah, 09h
    mov dx, offset compound_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset cbuf
    int 21h
    call nl
    
    ; Validate compound frequency
    mov cl, cbuf+1
    lea si, cbuf+2
    call validate_input
    
    cmp al, 0
    je compound_ok_c
    cmp al, 1
    je compound_empty_c
    cmp al, 3
    je compound_spaces_c
    
    ; Invalid characters
    mov ah, 09h
    mov dx, offset invalid_input_msg
    int 21h
    jmp get_compound_c
    
compound_empty_c:
    mov ah, 09h
    mov dx, offset empty_input_msg
    int 21h
    jmp get_compound_c
    
compound_spaces_c:
    mov ah, 09h
    mov dx, offset space_input_msg
    int 21h
    jmp get_compound_c
    
compound_ok_c:
    ; Convert compound frequency
    mov cl, cbuf+1
    lea si, cbuf+2
    call asciiToDigit
    mov word ptr nm+12, ax
    mov word ptr nm+14, dx

    ; get term * compounding
    mov ax, word ptr nm+8 ; ax = time
    mov dx, word ptr nm+10 ; ax = time
    mov bx, word ptr nm+12
    call multiplier
    ; store the output

    mov word ptr rt, ax ; store ct lower bit
    mov word ptr rt+2, dx ; store ct higher bit

    ; P (1+i/c) ^ct
    mov ax, word ptr nm+4 ; get rate
    mov dx, word ptr nm+6 ; get rate
    mov bx, 100
    call multiplier

    mov bx, word ptr nm+12
    call divider

    mov bx, 10000  ;this is 1 in formula but scaled by 10000
    mov cx, 0 ; 0 as bx is only 10000
    call adder; adder uses cx:bx and

    mov bx,ax ; store the current result to bx to used in multiplier

    mov cx, bx ; store a copy of current result
    mov ax,10000 ; new base

    mov si, word ptr rt ; get (C)(T)
    mov di, word ptr rt+2

exponential_growth:
    ; 32-bit multiply
    mov bx, cx
    call multiplier ; base * result

    mov bx,10000
    call divider ; (base*result) / 10000 returns a new result
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
    call multiplier; multiply it by principal
    mov bx, 10000
    call divider ; remove the scale

    mov word ptr rt+4, ax 
    mov word ptr rt+6, dx ; store it first so printing cliner and answer_cmp can use it

    call nl
    call liner ; LINE -------------
    call nl 

    mov ah, 09h
    mov dx, offset answer_cmp ; moving dx to offset answer_cmp

    int 21h
    ; restore the dx:ax
    mov ax, word ptr rt+4
    mov dx, word ptr rt+6

    call printAXDX
    call nl
    call liner ; LINE -------------
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
;print ax and dx (32bit)
printAXDX PROC
    mov bx,10   ; divisor for operation
    xor cx,cx   ;clear cx
    mov di,si   ; save buffer start

convert_loop2:
    push ax     ; save low word

    mov ax,dx
    xor dx,dx
    div bx      ; divide high word by 10 (bx)

    mov bp,ax   ; save high quotient
    pop ax      ; restore low word

    div bx      ; divide low word by 10 (bx)

    push dx     ; save remainder
    inc cx      ; increment counter

    mov dx,bp   ; rebuild DX:AX quotient

    cmp dx,0
    jne convert_loop2
    cmp ax,0
    jne convert_loop2

print_loop2:
    pop dx              ; get the remainder in reverse order
    add dl,'0'          ;convert to ascii
    mov [si],dl         ; store in buffer
    inc si
    loop print_loop2    ; repeat for all digits

    mov byte ptr [si],'$'   ; place terminator

    mov dx,di       ; point to start of string
    mov ah,09h
    int 21h         ; print the string
    ret
printAXDX ENDP
;32 bit divider usage (dx:ax) / bx
divider PROC
    ;save registers
    push bx
    push cx
    push bp

    push ax   ; save low word

    mov ax,dx   ; move high to ax
    xor dx,dx   ; remove value of dx
    div bx      ; divide high word by bx
                ; AX = high quotient
                ; DX = remainder

    mov bp,ax   ; store high quotient in bp
    pop ax      ; restore low word

    div bx      ; divide low with remainder

    mov dx,bp   ; combine the result
    ; restore the registers then return
    pop bp
    pop cx
    pop bx
    ret

divider ENDP
; 32 bit multiplier usage (dx:ax) * bx; returns new dx:ax
multiplier PROC
    ; preserve the content
    push cx 
    push si
    ; save low word
    mov si,ax        

    mov ax,dx   ; mov high first to mul
    mul bx      ; high * BX
    mov cx,ax   ; store partial

    mov ax,si   ; get the low word
    mul bx      ; low * BX

    add dx,cx   ; add partial to high part
    ; restore registers then return
    pop si
    pop cx
    ret
multiplier ENDP
; 32 bit adder usage (dx:ax) + (cx:bx)
adder PROC

    add ax,bx ; add bx and store to ax
    adc dx,cx ; add cx and store dx

    ret
adder ENDP
; this creates 205 char for 50 times
liner PROC
    mov cx,50
line:
    mov ah, 02h
    mov dl, 205
    int 21h
    loop line
    ret
liner ENDP  

end begin

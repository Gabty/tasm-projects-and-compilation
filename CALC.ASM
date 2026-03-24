; SEMI 32-BIT INTEREST CALCULATOR
; ============================================================

.model small
.stack 100h
.data

; ========== DISPLAY STRINGS ==========
head db "Interest Calculator",13,10, "$"

; ========== MENU OPTIONS ==========
question db "Options: $"
options db "1. Future Value of Simple Interest",13,10
        db "2. Future Value of Compounding Interest",13,10
        db "3. Logout$"
choice db "Choice: $"

; ========== OPTION HEADERS ==========
opt1 db "Future Value of Simple Interest$"
opt2 db "Future Value of Compounding Interest$"
opt3 db "Logging out...$"

; ========== INPUT PROMPTS ==========
principal_qt db "What is the principal: $"
rate_qt db "What is the annual interest percentage rate (0-9): $"
term_qt db "What is the year term (0-99): $"
compound_qt db "What is the compound frequency (0-9): $"
answer_cmp db "Future Value: $"

; ========== ERROR MESSAGES ==========
error_msg db ">>> ERROR: Invalid option! <<<",13,10
          db "Please choose 1, 2, or 3 only.",13,10,"$"

; ========== LOGIN MESSAGES ==========
login_prompt db "======= LOGIN REQUIRED =======",13,10
             db " ",13,10
             db "Username: $"
password_prompt db "Password: $"
login_success db "Login successful!",13,10,"$"
login_failed db "Invalid credentials! Access denied.",13,10,"$"
welcome_msg db "Welcome to the Interest Calculator!",13,10,"$"
try_again db "Press any key to try again...$"

; ========== INPUT VALIDATION MESSAGES ==========
invalid_input_msg db ">>> ERROR: Invalid input! Please enter a positive number.",13,10,"$"
empty_input_msg db ">>> ERROR: Input cannot be empty!",13,10,"$"
space_input_msg db ">>> ERROR: Input cannot be spaces only!",13,10,"$"

; ========== INPUT BUFFERS ==========
userbuf db 20,0,21 dup(?)      ; Username buffer
passbuf db 20,0,21 dup(?)      ; Password buffer

; ========== HARDCODED CREDENTIALS ==========
valid_username db "root",0  
valid_password db "admin",0 

; ========== NUMBER INPUT BUFFERS ==========
pbuf db 7,0,8 dup(?)    ; Principal buffer (max 7 digits)
rbuf db 2,0,3 dup(?)    ; Rate buffer (max 2 digits)
tbuf db 3,0,4 dup(?)    ; Term buffer (max 3 digits)
cbuf db 3,0,4 dup(?)    ; Compound frequency buffer

; ========== STORAGE VARIABLES ==========
nm dd ?, ?, ?, ?        ; Stores principal, rate, term, compound
rt dd ?, ?, ?           ; Runtime storage for calculations

.code

; ========== PROGRAM ENTRY POINT ==========
begin:
    mov ax, @data
    mov ds, ax

    call title_header    ; Display program title
    call login           ; Require login before proceeding

; ========== MAIN MENU LOOP ==========
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

    mov ah, 01h          ; Get user choice (1,2,3)
    int 21h
    mov bl, al

    ; ========== MENU SELECTION (IF STATEMENTS) ==========
    cmp bl, '1'          ; Check for option 1
    jne compound_block
    jmp simple

compound_block:
    cmp bl, '2'          ; Check for option 2
    jne exit_block
    jmp compound

exit_block:
    cmp bl, '3'          ; Check for option 3 (logout)
    jne invalid_choice
    jmp logout

; ========== LOGOUT HANDLER ==========
logout PROC
    call nl
    mov ah, 09h
    mov dx, offset opt3
    int 21h
    call nl
    call nl
    
    mov byte ptr [userbuf+1], 0    ; Clear username buffer
    mov byte ptr [passbuf+1], 0    ; Clear password buffer
    
    call login          ; Return to login screen
    jmp mainloop
logout ENDP

; ========== INVALID MENU CHOICE HANDLER ==========
invalid_choice:
    call nl
    mov ah, 09h
    mov dx, offset error_msg
    int 21h
    jmp mainloop

; ========== TITLE HEADER DISPLAY ==========
title_header PROC
    call nl     
    call liner   
    call nl      

    mov ah, 09h
    mov dx, offset head
    int 21h

    call liner   
    call nl   
title_header ENDP

; ========== LOGIN SYSTEM ==========
login PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
login_attempt:
    call nl
    call nl
    
    mov ah, 09h
    mov dx, offset login_prompt
    int 21h
    
    mov ah, 0Ah          ; Get username input
    mov dx, offset userbuf
    int 21h
    call nl
    
    mov ah, 09h
    mov dx, offset password_prompt
    int 21h
    
    call get_password    ; Get password with asterisks
    call nl
    
    call validate_login  ; Check credentials
    cmp ax, 1
    je login_successful
    
    ; ========== LOGIN FAILED HANDLER ==========
    call nl
    mov ah, 09h
    mov dx, offset login_failed
    int 21h
    
    mov ah, 09h
    mov dx, offset try_again
    int 21h
    
    mov ah, 01h          ; Wait for key press
    int 21h
    
    jmp login_attempt    ; Try again
    
login_successful:
    call nl
    mov ah, 09h
    mov dx, offset login_success
    int 21h
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    call welcome_handler
    jmp mainloop              
login ENDP

; ========== PASSWORD INPUT WITH ASTERISKS ==========
get_password PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, offset passbuf+2
    xor cx, cx
    
get_char:
    mov ah, 08h          ; Read char without echo
    int 21h
    
    cmp al, 13           ; Enter key?
    je password_done
    
    cmp al, 8            ; Backspace?
    je handle_backspace
    
    mov [si], al         ; Store character
    inc si
    inc cx
    
    mov ah, 02h          ; Print asterisk
    mov dl, '*'
    int 21h
    
    jmp get_char
    
handle_backspace:
    cmp cx, 0
    je get_char
    
    dec si
    dec cx
    
    mov ah, 02h
    mov dl, 8            ; Backspace
    int 21h
    mov dl, ' '
    int 21h
    mov dl, 8
    int 21h
    
    jmp get_char
    
password_done:
    mov byte ptr [si], 0
    mov al, cl
    mov [passbuf+1], al
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
get_password ENDP

; ========== CREDENTIAL VALIDATION ==========
validate_login PROC
    push bx
    push cx
    push si
    push di
    
    lea si, userbuf+2
    call strip_crlf      ; Clean username
    
    lea si, passbuf+2
    call strip_crlf      ; Clean password
    
    lea si, userbuf+2
    lea di, valid_username
    call compare_strings ; Check username
    cmp ax, 0
    jne validate_fail
    
    lea si, passbuf+2
    lea di, valid_password
    call compare_strings ; Check password
    cmp ax, 0
    jne validate_fail
    
    mov ax, 1            ; Login success
    jmp validate_done
    
validate_fail:
    xor ax, ax           ; Login failed
    
validate_done:
    pop di
    pop si
    pop cx
    pop bx
    ret
validate_login ENDP

; ========== STRING COMPARISON (CASE SENSITIVE) ==========
compare_strings PROC
    push si
    push di
    push cx
    
compare_loop:
    mov al, [si]
    mov bl, [di]
    
    cmp al, bl
    jne strings_different
    
    cmp al, 0
    je strings_equal
    
    inc si
    inc di
    jmp compare_loop
    
strings_different:
    mov ax, 1
    jmp compare_done
    
strings_equal:
    xor ax, ax
    
compare_done:
    pop cx
    pop di
    pop si
    ret
compare_strings ENDP

; ========== REMOVE CARRIAGE RETURN FROM STRING ==========
strip_crlf PROC
    push ax
    push si
    
strip_loop:
    mov al, [si]
    cmp al, 13
    je strip_replace
    cmp al, 10
    je strip_replace
    cmp al, 0
    je strip_done
    inc si
    jmp strip_loop
    
strip_replace:
    mov byte ptr [si], 0
    
strip_done:
    pop si
    pop ax
    ret
strip_crlf ENDP

; ========== INPUT VALIDATION (DIGITS ONLY) ==========
validate_input PROC
    push bx
    push cx
    push si
    
    cmp cl, 0
    je input_empty
    
    push cx
    push si
    mov ch, 0
check_spaces:
    mov al, [si]
    cmp al, ' '
    jne has_digits
    inc si
    loop check_spaces
    pop si
    pop cx
    jmp input_spaces
    
has_digits:
    pop si
    pop cx
    
    mov ch, 0
    mov bx, si
    
check_digits:
    mov al, [bx]
    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit
    
    inc bx
    loop check_digits
    
    pop si
    pop cx
    pop bx
    mov al, 0            ; Valid input
    ret
    
not_digit:
    pop si
    pop cx
    pop bx
    mov al, 2            ; Contains non-digit
    ret
    
input_empty:
    pop si
    pop cx
    pop bx
    mov al, 1            ; Empty input
    ret
    
input_spaces:
    pop si
    pop cx
    pop bx
    mov al, 3            ; Only spaces
    ret
validate_input ENDP

; ========== WELCOME MESSAGE DISPLAY ==========
welcome_handler PROC
    call nl
    call nl     
    call liner   
    call nl    

    mov ah, 09h
    mov dx, offset welcome_msg
    int 21h

    call liner   
welcome_handler ENDP

; ========== NEW LINE UTILITY ==========
nl PROC
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret
nl ENDP

; ========== PROGRAM EXIT (UNUSED) ==========
exitapp PROC
    call nl
    mov ah, 09h
    mov dx, offset opt3
    int 21h
    mov ah, 4ch
    int 21h
    ret
exitapp ENDP

; ========== SIMPLE INTEREST CALCULATOR ==========
simple PROC
    call nl
    call nl
    call nl
    call liner
    call nl
    mov ah, 09h
    mov dx, offset opt1
    int 21h
    call nl
    call liner
    call nl

; ========== GET PRINCIPAL WITH VALIDATION ==========
get_principal:
    mov ah, 09h
    mov dx, offset principal_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset pbuf
    int 21h
    call nl
    
    mov cl, pbuf+1
    lea si, pbuf+2
    call validate_input
    
    cmp al, 0
    je principal_ok
    cmp al, 1
    je principal_empty
    cmp al, 3
    je principal_spaces
    
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
    mov cl, pbuf+1
    lea si, pbuf+2
    call asciiToDigit
    mov word ptr nm, ax
    mov word ptr nm+2, dx

; ========== GET RATE WITH VALIDATION ==========
get_rate:
    mov ah, 09h
    mov dx, offset rate_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset rbuf
    int 21h
    call nl
    
    mov cl, rbuf+1
    lea si, rbuf+2
    call validate_input
    
    cmp al, 0
    je rate_ok
    cmp al, 1
    je rate_empty
    cmp al, 3
    je rate_spaces
    
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
    mov cl, rbuf+1
    lea si, rbuf+2
    call asciiToDigit
    mov word ptr nm+4, ax
    mov word ptr nm+6, dx

; ========== GET TERM WITH VALIDATION ==========
get_term:
    mov ah, 09h
    mov dx, offset term_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset tbuf
    int 21h
    call nl
    
    mov cl, tbuf+1
    lea si, tbuf+2
    call validate_input
    
    cmp al, 0
    je term_ok
    cmp al, 1
    je term_empty
    cmp al, 3
    je term_spaces
    
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
    mov cl, tbuf+1
    lea si, tbuf+2
    call asciiToDigit
    mov word ptr nm+8, ax
    mov word ptr nm+10, dx

; ========== SIMPLE INTEREST CALCULATION ==========
    ; Formula: FV = P * (1 + RT)
    ; All values scaled by 10000 to handle decimals
    
    mov ax, word ptr nm+4    ; Get rate
    mov dx, word ptr nm+6
    mov bx, 100              ; Scale rate
    call multiplier
    
    mov bx, word ptr nm+8    ; Multiply by term
    call multiplier
    
    mov bx, 10000            ; Add 1 (scaled as 10000)
    call adder

    mov word ptr rt, ax      ; Store (10000 + Rate*100*Term)
    mov word ptr rt+2, dx

    mov ax, word ptr nm      ; Get principal
    mov dx, word ptr nm+2

    mov bx, word ptr rt      ; Multiply principal * (10000 + ...)
    call multiplier
    mov bx, 10000            ; Divide to remove scaling
    call divider

    mov word ptr rt+4, ax    ; Store final result
    mov word ptr rt+6, dx

; ========== DISPLAY RESULT ==========
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

; ========== COMPOUND INTEREST CALCULATOR ==========
compound PROC
    call nl
    call nl
    call nl
    call liner
    call nl
    mov ah, 09h
    mov dx, offset opt2
    int 21h
    call nl
    call liner
    call nl
    
; ========== GET PRINCIPAL (COMPOUND) ==========
get_principal_c:
    mov ah, 09h
    mov dx, offset principal_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset pbuf
    int 21h
    call nl
    
    mov cl, pbuf+1
    lea si, pbuf+2
    call validate_input
    
    cmp al, 0
    je principal_ok_c
    cmp al, 1
    je principal_empty_c
    cmp al, 3
    je principal_spaces_c
    
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
    mov cl, pbuf+1
    lea si, pbuf+2
    call asciiToDigit
    mov word ptr nm, ax
    mov word ptr nm+2, dx

; ========== GET RATE (COMPOUND) ==========
get_rate_c:
    mov ah, 09h
    mov dx, offset rate_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset rbuf
    int 21h
    call nl
    
    mov cl, rbuf+1
    lea si, rbuf+2
    call validate_input
    
    cmp al, 0
    je rate_ok_c
    cmp al, 1
    je rate_empty_c
    cmp al, 3
    je rate_spaces_c
    
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
    mov cl, rbuf+1
    lea si, rbuf+2
    call asciiToDigit
    mov word ptr nm+4, ax
    mov word ptr nm+6, dx

; ========== GET TERM (COMPOUND) ==========
get_term_c:
    mov ah, 09h
    mov dx, offset term_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset tbuf
    int 21h
    call nl
    
    mov cl, tbuf+1
    lea si, tbuf+2
    call validate_input
    
    cmp al, 0
    je term_ok_c
    cmp al, 1
    je term_empty_c
    cmp al, 3
    je term_spaces_c
    
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
    mov cl, tbuf+1
    lea si, tbuf+2
    call asciiToDigit
    mov word ptr nm+8, ax
    mov word ptr nm+10, dx

; ========== GET COMPOUND FREQUENCY ==========
get_compound_c:
    mov ah, 09h
    mov dx, offset compound_qt
    int 21h
    
    mov ah, 0Ah
    mov dx, offset cbuf
    int 21h
    call nl
    
    mov cl, cbuf+1
    lea si, cbuf+2
    call validate_input
    
    cmp al, 0
    je compound_ok_c
    cmp al, 1
    je compound_empty_c
    cmp al, 3
    je compound_spaces_c
    
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
    mov cl, cbuf+1
    lea si, cbuf+2
    call asciiToDigit
    mov word ptr nm+12, ax
    mov word ptr nm+14, dx

; ========== COMPOUND INTEREST CALCULATION ==========
    ; Formula: FV = P * (1 + r/c)^(c*t)
    ; All values scaled by 10000 to handle decimals
    
    ; Calculate c*t (compounding periods)
    mov ax, word ptr nm+8    ; Get term
    mov dx, word ptr nm+10
    mov bx, word ptr nm+12   ; Multiply by compound frequency
    call multiplier
    mov word ptr rt, ax      ; Store c*t
    mov word ptr rt+2, dx

    ; Calculate (1 + r/c)
    mov ax, word ptr nm+4    ; Get rate
    mov dx, word ptr nm+6
    mov bx, 100              ; Scale rate
    call multiplier
    mov bx, word ptr nm+12   ; Divide by c
    call divider
    mov bx, 10000            ; Add 1 (scaled)
    mov cx, 0
    call adder

    ; Calculate (1 + r/c)^(c*t) using loop
    mov bx, ax               ; Store base
    mov cx, bx               ; Copy base
    mov ax, 10000            ; Start with 1 (scaled)
    
    mov si, word ptr rt      ; Get c*t (low word)
    mov di, word ptr rt+2    ; Get c*t (high word)

exponential_growth:
    mov bx, cx               ; Multiply current result by base
    call multiplier
    mov bx, 10000            ; Divide to keep scaling
    call divider

    sub si, 1                ; Decrement counter
    sbb di, 0

    cmp di, 0
    jne exponential_growth
    cmp si, 0
    jne exponential_growth

    mov word ptr rt+4, ax    ; Store (1+r/c)^(c*t)
    mov word ptr rt+6, dx

    ; Multiply by principal
    mov bx, word ptr nm
    call multiplier
    mov bx, 10000
    call divider

    mov word ptr rt+4, ax    ; Store final result
    mov word ptr rt+6, dx

; ========== DISPLAY RESULT ==========
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
compound ENDP

; ========== ASCII TO 32-BIT INTEGER CONVERTER ==========
asciiToDigit PROC
    xor ax,ax
    xor dx,dx          ; DX:AX = 0

convert:
    mov bl,[si]
    sub bl,'0'         ; Convert ASCII to number
    xor bh,bh          ; BX = digit

    ; Multiply current value by 10
    mov bp,ax          ; Save current value
    mov di,dx

    shl ax,1           ; Value * 2
    rcl dx,1

    shl bp,1           ; Value * 8
    rcl di,1
    shl bp,1
    rcl di,1
    shl bp,1
    rcl di,1

    add ax,bp          ; Value * 10
    adc dx,di

    add ax,bx          ; Add digit
    adc dx,0

    inc si
    loop convert
    ret
asciiToDigit ENDP

; ========== 32-BIT NUMBER DISPLAY ==========
printAXDX PROC
    mov bx,10          ; Divisor for decimal conversion
    xor cx,cx          ; Clear counter
    mov di,si          ; Save buffer start

convert_loop2:
    push ax            ; Save low word

    mov ax,dx          ; Process high word
    xor dx,dx
    div bx
    mov bp,ax          ; Save high quotient
    pop ax             ; Restore low word

    div bx             ; Divide low word

    push dx            ; Save remainder
    inc cx

    mov dx,bp          ; Rebuild quotient

    cmp dx,0
    jne convert_loop2
    cmp ax,0
    jne convert_loop2

print_loop2:
    pop dx             ; Get digits in reverse order
    add dl,'0'         ; Convert to ASCII
    mov [si],dl
    inc si
    loop print_loop2

    mov byte ptr [si],'$'   ; String terminator

    mov dx,di          ; Print string
    mov ah,09h
    int 21h
    ret
printAXDX ENDP

; ========== 32-BIT DIVISION HANDLER ==========
; Divides DX:AX by BX, returns result in DX:AX
divider PROC
    push bx
    push cx
    push bp

    push ax            ; Save low word

    mov ax,dx          ; Move high word to AX
    xor dx,dx          ; Clear DX
    div bx             ; Divide high word
    mov bp,ax          ; Save high quotient
    pop ax             ; Restore low word

    div bx             ; Divide low word with remainder

    mov dx,bp          ; Combine result

    pop bp
    pop cx
    pop bx
    ret
divider ENDP

; ========== 32-BIT MULTIPLICATION HANDLER ==========
; Multiplies DX:AX by BX, returns result in DX:AX
multiplier PROC
    push cx 
    push si
    
    mov si,ax          ; Save low word

    mov ax,dx          ; Multiply high word first
    mul bx             ; High * BX
    mov cx,ax          ; Store partial result

    mov ax,si          ; Get low word
    mul bx             ; Low * BX

    add dx,cx          ; Add partial to high part

    pop si
    pop cx
    ret
multiplier ENDP

; ========== 32-BIT ADDITION HANDLER ==========
; Adds CX:BX to DX:AX, returns result in DX:AX
adder PROC
    add ax,bx          ; Add low words
    adc dx,cx          ; Add high words with carry
    ret
adder ENDP

; ========== LINE DISPLAY UTILITY ==========
; Prints 205 characters (extended ASCII line)
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

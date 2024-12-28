org 0x0
bits 16


%define ENDL 0x0D, 0x0A


start:
    mov si, msg_hello
    call print_string

    mov si, msg_welcome
    call print_string

.halt:
    cli
    hlt


;
;   Prints a string to the screen using BIOS interrupts
;
;   USES:
;       SI: Output string
;
print_string:
    ; Save the stack
    push si
    push ax
    push bx

    jmp .print_loop

.print_loop:
    lodsb ; Load byte from SI into AL
    or al, al ; Check if its a null character
    jz .print_done

    mov ah, 0xE ; Display char code
    mov bh, 0 ; we want page number 0
    int 0x10

    jmp .print_loop ; Since its not a null character, go back to start

.print_done:
    ; Restore the stack
    ; Stack grows downward so we want to restore in reverse
    pop bx
    pop ax
    pop si

    ret

msg_hello: db 'Loading stage 2', ENDL, 0
msg_welcome: db 'HELLO WORLD FROM STAGE 2!! (SEPARATE BIN FILE)', ENDL, 0
message_ok: db 'OK', ENDL, 0
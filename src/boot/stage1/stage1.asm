org 0x7C00
bits 16

start:
    jmp main

;
;   Prints a string to the screen using BIOS interrupts
;
;   USES:
;       SI: Output string
;
print_string:
    ; Save the stack
    push ax

    lodsb ; Load byte from SI into AL
    or al, al ; Check if its a null character
    jz .print_done

    mov ah, 0xE ; Display char code
    int 0x10

    jmp print_string ; Since its not a null character, go back to start

.print_done:
    pop ax

    ret

main:
    mov si, message_hello
    call print_string
    hlt

; 0D 0A (Carrige Return) (Line Feed)

message_hello: db 'Hello, world!', 0x0D, 0x0A, 'This is a new line that hopefully works', 0x0D, 0x0A, 'Heres another line', 0x0D, 0x0A, 'And finally heres a super duper ultra mega long line', 0x0D, 0x0A, 0 ; Null termination

times 510 - ($ - $$) db 0
dw 0xAA55

bits 16

section _ENTRY class=CODE

extern _stage2_cmain_

%define ENDL 0x0D, 0x0A

global entry
entry:
    ; Setup stack
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    mov si, message_hello
    call print_string

    mov si, message_transitioning
    call print_string


    ; We should have the boot drive in DL
    xor dh, dh
    push dx
    call _stage2_cmain_

    cli
    hlt

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

message_hello: db 'Loading stage 2', ENDL, 0
message_transitioning: db 'Transitioning to C...', ENDL, ENDL, 0
message_ok: db 'OK', ENDL, 0

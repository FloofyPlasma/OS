bits 16

section _TEXT class=CODE

global _x86_Print_String
_x86_Print_String:
    ; make new call frame
    enter 0, 0

    push bx

    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    pop bx

    leave
    ret
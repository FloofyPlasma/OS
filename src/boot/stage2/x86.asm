extern load_GDT

%macro x86_Enter_Real_Mode 0
    [bits 32]
    jmp word 18h:.protected_mode16

.protected_mode16:
    [bits 16]
    ; disable protected mode
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    jmp word 00h:.real_mode

.real_mode:
    mov ax, 0
    mov ds, ax
    mov ss, ax

    sti

%endmacro

%macro x86_Enter_Protected_Mode 0
    cli

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp dword 08h:.protected_mode

.protected_mode:
    [bits 32]

    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

global x86_Print_String
x86_Print_String:
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
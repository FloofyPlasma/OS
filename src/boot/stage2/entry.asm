bits 16

section .entry

extern __bss_start
extern __end

%define ENDL 0x0D, 0x0A

extern stage2_cmain_

global entry
entry:
    [bits 16]
    cli
    mov [boot_drive], dl

    ; Setup stack
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    mov si, message_hello
    call print_string

    mov si, message_transitioning
    call print_string

    ; switch to protected mode
    cli
    call enable_A20
    call load_GDT

    ; protection enable flag
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; Jump to protected mode
    jmp dword 08h:.protected_mode

.protected_mode:
    [bits 32]
    ; segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    ; clear bss
    mov edi, __bss_start
    mov ecx, __end
    sub ecx, edi
    mov al, 0
    cld
    rep stosb

    ; We should have the boot drive in DL
    xor edx, edx
    mov dl, [boot_drive]
    push edx
    call stage2_cmain_

    cli
    hlt


enable_A20:
    [bits 16]
    ; disable keyboard
    call wait_in_A20
    mov al, KeyboardControllerDisableKeyboard
    out KeyboardControllerCommandPort, al

    ; read output port
    call wait_in_A20
    mov al, KeyboardControllerReadControlOutputPort
    out KeyboardControllerCommandPort, al

    call wait_out_A20
    in al, KeyboardControllerDataPort
    push eax

    ; write control port
    call wait_in_A20
    mov al, KeyboardControllerWriteControlOutputPort
    out KeyboardControllerCommandPort, al

    call wait_in_A20
    pop eax
    or al, 2 ; bit 2 (A20 bit)
    out KeyboardControllerDataPort, al

    ; enable keyboard
    call wait_in_A20
    mov al, KeyboardControllerEnableKeyboard
    out KeyboardControllerCommandPort, al

    call wait_in_A20
    ret

wait_in_A20:
    [bits 16]
    ; Wait until status bit 2 is 0
    in al, KeyboardControllerCommandPort
    test al, 2
    jnz wait_in_A20
    ret

wait_out_A20:
    [bits 16]
    ; Wait until status bit 1 is 0
    in al, KeyboardControllerCommandPort
    test al, 1
    jz wait_out_A20
    ret

global load_GDT
load_GDT:
    [bits 16]
    lgdt [GDT_descriptor]

    ret
;
;   Prints a string to the screen using BIOS interrupts
;
;   USES:
;       SI: Output string
;
print_string:
    [bits 16]
    ; Save the stack
    push si
    push ax
    push bx

    jmp .print_loop

.print_loop:
    [bits 16]
    lodsb ; Load byte from SI into AL
    or al, al ; Check if its a null character
    jz .print_done

    mov ah, 0xE ; Display char code
    mov bh, 0 ; we want page number 0
    int 0x10

    jmp .print_loop ; Since its not a null character, go back to start

.print_done:
    [bits 16]
    ; Restore the stack
    ; Stack grows downward so we want to restore in reverse
    pop bx
    pop ax
    pop si

    ret

message_hello: db 'Loading stage 2', ENDL, 0
message_transitioning: db 'Transitioning to Protected Mode...', ENDL, ENDL, 0


;
;   https://wiki.osdev.org/Global_Descriptor_Table
;
GDT:
    ; Null descriptor
    dq 0

    ; 32-bit code segment
    dw 0FFFFh ; limit (0xFFFFF) full 4 gb address space
    dw 0 ; base
    db 0 ; base part 2
    db 10011010b ; access: present, ring 0, code segment, executable, direction 0, readable
    db 11001111b ; flags: 4k pages, 32-bit page mode. + limit
    db 0 ; base part 3

    ; 32-bit data segment
    dw 0FFFh; limit (0xFFFFF) full 4 gb address space
    dw 0 ; base
    db 0; base part 2
    db 10010010b ; access: present, ring 0, data segment, executable, direction 0, writable
    db 11001111b ; flags: 4k pages, 32-bit page mode. + limit
    db 0 ; base part 3

    ; 16-bit code segment
    dw 0FFFFh ; limit (0xFFFFF)
    dw 0 ; base
    db 0 ; base part 2
    db 10011010b ; access: present, ring 0, code segment, executable, direction 0, readable
    db 00001111b ; flags: 1b pages, 16-bit page mode. + limit
    db 0 ; base part 3

    ; 16-bit data segment
    dw 0FFFFh ; limit (0xFFFFF)
    dw 0 ; base
    db 0 ; base part 2
    db 10010010b ; accses: present, ring 0, data segment, executable, direction 0, writable
    db 00001111b ; flags: 1b pages, 16-bit page mode. + limit
    db 0 ; base part 3

GDT_descriptor:
    dw GDT_descriptor - GDT - 1 ; size
    dd GDT ; address

KeyboardControllerDataPort equ 0x60
KeyboardControllerCommandPort equ 0x64
KeyboardControllerDisableKeyboard equ 0xAD
KeyboardControllerEnableKeyboard equ 0xAE
KeyboardControllerReadControlOutputPort equ 0xD0
KeyboardControllerWriteControlOutputPort equ 0xD1

boot_drive: db 0
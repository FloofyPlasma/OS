org 0x7C00
bits 16

jmp short start
nop

;
; BPB (BIOS Parameter Block)
; http://wiki.osdev.org/FAT#BPB_(BIOS_Parameter_Block)
;
BPB_OEM: db 'mkfs.fat' ; TODO: Update
BPB_BytesPerSector dw 512
BPB_SectorsPerCluster db 4
BPB_ReservedSectors dw 4
BPB_FATCount db 2
BPB_RootDirecetoryEntries dw 512
BPB_TotalSectors dw 65535
BPB_MediaDescriptor db 0F8h ; Fixed disk
BPB_SectorPerTrack dw 64
BPB_SectorCount dw 65535
BPB_Heads dw 32
BPB_HiddenSectors dd 4
BPB_LargeSectorCount dd 0

;
; EBR (Extended Boot Record)
; http://wiki.osdev.org/FAT#Extended_Boot_Record
;
EBR_DriveNumber db 080h ; Hard disk
db 0 ; Reserved for Windows NT (lmao thanks microsoft)
EBR_Signature db 029h ; Either this or 0x29.
EBR_SerialNumber db 87h, 65h, 43h, 21h
EBR_VolumeLabel db 'OS      ' ; TODO: Better name...
EBR_SystemIdentifier db 'FAT16   ' ; Do not trust this (lol)


; Boot code

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
    push si
    push ax
    jmp .print_loop

.print_loop:
    lodsb ; Load byte from SI into AL
    or al, al ; Check if its a null character
    jz .print_done

    mov ah, 0xE ; Display char code
    int 0x10

    jmp .print_loop ; Since its not a null character, go back to start

.print_done:
    pop si
    pop ax

    ret

main:
    mov si, message_hello
    call print_string
    hlt

; 0D 0A (Carrige Return) (Line Feed)

message_hello: db 'Hello, world!', 0x0D, 0x0A, 'This is a new line that hopefully works', 0x0D, 0x0A, 'Heres another line', 0x0D, 0x0A, 'And finally heres a super duper ultra mega long line', 0x0D, 0x0A, 0 ; Null termination

times 510 - ($ - $$) db 0

; Bootable partition signature

dw 0xAA55

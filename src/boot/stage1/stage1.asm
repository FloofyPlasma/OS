org 0x7C00
bits 16

jmp short main
nop

;
;   TODO: Verify all this filesystem stuff is correct
;

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
BPB_SectorsPerFat dw 64
BPB_SectorsPerTrack dw 65535
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


main:
    ; Setup data registers
    mov ax, 0
    mov ds, ax
    mov es, ax

    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00 ; stack grows downward

    ; Some BIOS' load to 0x7c0:0x0000, fix that
    push es
    jmp word .enforced
    retf

.enforced:
    ; bios should set DL to the disk drive number we want
    mov [EBR_DriveNumber], dl

    ; print our loading message
    mov si, message_loading
    call print_string

    ; read disk data from BIOS instead of
    ; relying on the formatted data
    push es
    mov ah, 08h
    int 13h
    jc disk_failure
    pop es

    and cl, 0x3F ; chop 2 bits
    xor ch, ch
    mov [BPB_SectorsPerTrack], cx

    inc dh
    mov [BPB_Heads], dh ; Head count

    ; compute start sector of root directory (reserved + fats * sectorsPerFat)
    mov ax, [BPB_SectorsPerFat]
    mov bl, [BPB_FATCount]
    xor bh, bh
    mul bx ; ax = (fats * sectors per fat)
    add ax, [BPB_ReservedSectors] ; ax = start sector of root directory
    push ax

    ; compute size of root directory (32 * number of entires) / bytes per sector
    mov ax, [BPB_RootDirecetoryEntries]
    shl ax, 5 ; ax *= 32
    xor dx, dx ; dx = 0
    div word [BPB_BytesPerSector] ; number of sectors we need to read

    test dx, dx
    jz .root_dir_ready
    inc ax

.root_dir_ready:
    ; read root dir
    mov cl, al ; cl = number of sectors to read = root directory size
    pop ax ; sector number of root dir
    mov dl, [EBR_DriveNumber]
    mov bx, buffer_data
    call read_disk

    ; search for stage2.bin
    xor bx, bx
    mov di, buffer_data

.search_stage_2:
    mov si, file_stage_2
    mov cx, 11 ; compare 11 characters
    push di
    repe cmpsb
    pop di
    je .stage_2_found

    add di, 32 ; size of a directory entry (i think?)
    inc bx
    cmp bx, [BPB_RootDirecetoryEntries]
    jl .search_stage_2

    ; stage 2 couldnt be found
    jmp stage_2_not_found

.stage_2_found:
    ; di should have the address of the entry
    mov ax, [di + 26] ; first logical cluster
    mov [stage2_cluster], ax

    ; load the FAT from disk
    mov ax, [BPB_ReservedSectors]
    mov bx, buffer_data
    mov cl, [BPB_SectorsPerFat]
    mov dl, [EBR_DriveNumber]
    call read_disk

    ; read stage 2 and process FAT chain
    mov bx, STAGE_2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE_2_LOAD_OFFSET

.stage_2_loop:
    ; Read next cluster
    mov ax, [stage2_cluster]
    sub ax, 2 

    movzx cx, byte [BPB_SectorsPerCluster]
    mul cx

    add ax, 164 ; Magic numbers (do not ask...)
    
    mov cl, 1
    mov dl, [EBR_DriveNumber]
    call read_disk

    add bx, [BPB_BytesPerSector]

    ; Compute location of next cluster
    mov ax, [stage2_cluster]
    mov bx, 2
    mul bx
    
    mov si, buffer_data
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    cmp ax, 0xFFF8
    jae .stage_2_read_finish

    mov [stage2_cluster], ax
    jmp .stage_2_loop

.stage_2_read_finish:
    ; jump to stage 2
    mov dl, [EBR_DriveNumber]

    mov ax, STAGE_2_LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp STAGE_2_LOAD_SEGMENT:STAGE_2_LOAD_OFFSET

    jmp key_reboot ; should never happen...

    cli
    hlt

stage_2_not_found:
    mov si, message_not_found
    call print_string
    jmp key_reboot

;
;   Read sectors from the disk
;   USES:
;       ax: sector address
;       cl: sectors to read (up to 128)
;       dl: drive number
;       es:bx memory to store read data
;
read_disk:
    ; Save the stack
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call sector_address_to_chs
    pop ax

    mov ah, 02h
    mov di, 3 ; retry count

.read_retry:
    pusha
    stc ; carry flag
    int 13h ; carry flag cleared means it worked
    jnc .read_done

    ; read failed
    popa
    call disk_reset

    dec di ; decrement retry count
    test di, di
    jnz .read_retry

.read_fail:
    ; no more retries
    jmp disk_failure

.read_done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    
    ret

;
;   Converts a sector address to a CHS address
;   USES:
;       AX: sector address
;   RETURNS:
;       cx [bits 0-5]: sector number
;       cx [bits 6-15]: cylinder
;       dh: head
;
sector_address_to_chs:
    push ax
    push dx

    xor dx, dx ; dx to 0
    div word [BPB_SectorsPerTrack] ; ax = address / sectorspertrack
    ; dx = address % sectorspertrack

    inc dx ; dx = (address % sectors per track + 1) = sector
    mov cx, dx ; cx = sector

    xor dx, dx ; dx to 0
    div word [BPB_Heads] ; ax = (address / sectors per track) / heads = cylinder
    ; dx = (address / sectors per track) % heads = head

    mov dh, dl ; dh = head
    mov ch, al ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah ; put upper 2 bits of cylinder in cl

    pop ax
    mov dl, al ; restore dl
    pop ax
    ret


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

disk_failure:
    mov si, message_error
    call print_string
    jmp key_reboot

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc disk_failure
    popa
    ret

key_reboot:
    mov ah, 0 
    int 16h ; read keypress
    jmp 0xFFFF:0 ; jump to start, reboots (?)

%define ENDL 0x0D, 0x0A

; 0D 0A (Carrige Return) (Line Feed)

message_loading: db 'Loading stage 1', ENDL, 0
message_error: db 'Disk read failed', ENDL, 0
message_not_found: db 'Stage 2 not found', ENDL, 0
file_stage_2: db 'STAGE2  BIN'
stage2_cluster dw 0

; Magic numbers
STAGE_2_LOAD_SEGMENT equ 0x2000
STAGE_2_LOAD_OFFSET equ 0

times 510 - ($ - $$) db 0

; Bootable partition signature

dw 0xAA55

;
; Extra space outside the 512 bytes
;
buffer_data:
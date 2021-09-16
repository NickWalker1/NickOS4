; 3 Pages beneath 1MiB mark where kernel is loaded

PD_BASE equ 0x00FFD000
PT_I_BASE equ 0x00FFE000
PT_K_BASE equ 0x00FFF000

PG_SIZE equ 0x1000

KERNEL_BASE equ 0x00100000 ; 1MiB address

; 1 4k page table is able to cover 4MiB of virtual addresses 
; as 1024 entries each pointing to a different 4k page.

clear_tables:
    mov eax,0

    ;.clear_loop
    ;mov [PD_BASE+eax], byte 0
    ;inc eax

    ;cmp eax, PG_SIZE 
    ;jl .clear_loop

    ret

    

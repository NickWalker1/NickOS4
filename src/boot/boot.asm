; Declare constants for the multiboot header.
MBALIGN  equ  1 << 0            ; align loaded modules on page boundaries
MEMINFO  equ  1 << 1            ; provide memory map
FLAGS    equ  MBALIGN | MEMINFO ; this is the Multiboot 'flag' field
MAGIC    equ  0x1BADB002        ; 'magic number' lets bootloader find the header
CHECKSUM equ -(MAGIC + FLAGS)   ; checksum of above, to prove we are multiboot
 

section .multiboot.data
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
 

section .multiboot.text
%include "src/boot/gdt.asm"

; 3 Pages beneath 1MiB mark where kernel is loaded, fingers crossed it's not used for anything
KERN_STACK_TOP equ 0x00FFC000
PD_BASE equ 0x00FFD000
PT_I_BASE equ 0x00FFE000
PT_K_BASE equ 0x00FFF000

PG_SIZE equ 0x1000

KERNEL_BASE equ 0x00100000 ; 1MiB address
KERNEL_VIRT_BASE equ 0xC0000000 ; 3GiB address

; 1 4k page table is able to cover 4MiB of virtual addresses 
; as 1024 entries each pointing to a different 4k page.

clear_tables:
    pusha 
    mov eax,0

    .clear_loop:
    mov [PD_BASE+eax], byte 0
    inc eax

    cmp eax, PG_SIZE * 3
    jl .clear_loop

    
    popa


    
    ret

create_page_directory:
    pusha
    ;add the identity table entry
    mov eax, PT_I_BASE
    or dword eax, 3
    mov [PD_BASE], eax

    ;add kernel mapping
    mov eax, PT_K_BASE
    or dword eax, 3
    
    ;get PT_K_BASE offset in ebx
    mov ebx, KERNEL_VIRT_BASE
    shr ebx, 22

    mov [PD_BASE+ ebx*4], eax

    popa
    ret

create_identity_page_table:
    pusha
    ; index
    mov eax, 0

    ; phys address start
    mov ebx, 0

    .indentity_loop:
    mov ecx, ebx
    or dword ecx, 3

    ;move ecx into that memory location
    mov [PT_I_BASE+eax*4], ecx

    add ebx, 0x1000 ;point to next physical page
    inc eax


    popa
    ret

create_kernel_page_table:
    pusha
    ; index
    mov eax, 0

    ; phys address
    mov ebx, 0

    .kernel_loop:
    mov ecx, ebx
    or dword ecx, 3

    mov [PT_K_BASE+eax*4], ecx

    add ebx, 0x1000
    inc eax

    cmp eax, 0x400
    jl .kernel_loop
    popa
    ret

enable_paging:
    pusha 
    ; Set address of the directory table
    mov eax, PD_BASE
    mov cr3, eax

    ; Enable paging
    mov eax, cr0
    or eax, 0x80000020
    mov cr0, eax

    jmp .branch
    nop
    nop
    nop
    nop
    nop
    .branch:

    popa
    ret

global _start:function (_start.end - _start)
_start:
    
	;mov esp, KERN_STACK_TOP
	
	lgdt [gdt_descriptor]

    call clear_tables

    call create_page_directory
    
    call create_identity_page_table

    call create_kernel_page_table

    call enable_paging


	jmp higher
.end:

section .text
higher:


    extern kernel_main
    call kernel_main

	cli
.hang:	hlt
	jmp .hang



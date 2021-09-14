; Declare constants for the multiboot header.
MBALIGN  equ  1 << 0            ; align loaded modules on page boundaries
MEMINFO  equ  1 << 1            ; provide memory map
FLAGS    equ  MBALIGN | MEMINFO ; this is the Multiboot 'flag' field
MAGIC    equ  0x1BADB002        ; 'magic number' lets bootloader find the header
CHECKSUM equ -(MAGIC + FLAGS)   ; checksum of above, to prove we are multiboot
 

section .multiboot
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
 

section .bss
align 16
stack_bottom:
resb 4096 ; 16 KiB
stack_top:



section .text
%include "src/boot/gdt.asm"
%include "src/boot/paging.asm"
global _start:function (_start.end - _start)
_start:

	mov esp, stack_top
	
	lgdt [gdt_descriptor]

	call clear_page_directory
	call clear_page_tables

	call create_page_directory
	call create_identity_page_table
	call create_kernel_page_table

	call enable_paging

	extern kernel_main
	call kernel_main

	cli
.hang:	hlt
	jmp .hang
.end:
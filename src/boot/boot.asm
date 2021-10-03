bits 32

; Definitions
KERNEL_CS equ 0x08
KERNEL_DS equ 0x10
USERMODE_CS equ 0x18
USERMODE_DS equ 0x20

STACK_SIZE          equ 0x1000 ; 4KB stack
THREAD_CONTEXT_SIZE equ 0x1000 ; 4KB just for thread struct

MBOOT_PAGE_ALIGN    equ 0x1
MBOOT_MEM_INFO      equ 0x2
MBOOT_USE_GFX       equ 0x4
MBOOT_HDR_MAGIC     equ 0x1BADB002
MBOOT_HDR_FLAGS     equ MBOOT_PAGE_ALIGN | MBOOT_MEM_INFO
MBOOT_CHECKSUM      equ -(MBOOT_HDR_MAGIC + MBOOT_HDR_FLAGS)

; 3GB offset for translating physical to virtual addresses
KERNEL_VIRTUAL_BASE equ 0xC0000000
; Page directory idx of kernel's 4MB PTE
KERNEL_PAGE_NUM     equ (KERNEL_VIRTUAL_BASE >> 22)

section .data
align 0x1000
; This PDE identity-maps the first 4MB of 32-bit physical address space
; bit 7: PS - kernel page is 4MB
; bit 1: RW - kernel page is R/W
; bit 0: P  - kernel page is present
boot_page_directory:
    dd 0x00000083   ; First 4MB, which will be unmapped later
    times (KERNEL_PAGE_NUM - 1) dd 0    ; Pages before kernel
    dd 0x00000083   ; Kernel 4MB at 3GB offset
    times (1024 - KERNEL_PAGE_NUM - 1) dd 0 ; Pages after kernel


section .text
align 4
; start of kernel image:
; Multiboot header
; note: you don't need Multiboot AOUT Kludge for an ELF kernel
multiboot:
    dd MBOOT_HDR_MAGIC
    dd MBOOT_HDR_FLAGS
    dd MBOOT_CHECKSUM
    ; Mem info (only valid if aout kludge flag set or ELF kernel)
    ;dd 0x00000000   ; header address
    ;dd 0x00000000   ; load address
    ;dd 0x00000000   ; load end address
    ;dd 0x00000000   ; bss end address
    ;dd 0x00000000   ; entry address
    ; Graphics requests (only valid if graphics flag set)
    ;dd 0x00000000   ; linear graphics
    ;dd 0            ; width
    ;dd 0            ; height
    ;dd 32           ; set to 32


extern kernel_main
global start
start:
    mov ecx, (boot_page_directory - KERNEL_VIRTUAL_BASE)
    mov cr3, ecx    ; Load page directory

    mov ecx, cr4
    or ecx, 0x00000010  ; Set PSE bit in CR4 to enable 4MB pages
    mov cr4, ecx

    mov ecx, cr0
    or ecx, 0x80000000  ; Set PG bit in CR0 to enable paging
    mov cr0, ecx

    ; EIP currently holds physical address, so we need a long jump to
    ; the correct virtual address to continue execution in kernel space
    lea ecx, [start_higher_half]
    jmp ecx     ; Absolute jump!!

start_higher_half:
    ; Unmap identity-mapped first 4MB of physical address space
    mov dword [boot_page_directory], 0
    invlpg [0]

    mov esp, kernel_stack_top ; set up stack pointer
    push eax    ; push header magic
    add ebx, KERNEL_VIRTUAL_BASE    ; make multiboot header pointer virtual
    push ebx    ; push header pointer (TODO: hopefully this isn't at an addr > 4MB)
    cli         ; disable interrupts
    
    call kernel_main

    cli
.hang:
    hlt
    jmp .hang


section .bss
global kernel_stack_bottom
global kernel_stack_top
global main_thread_addr
main_thread_addr:
    resb THREAD_CONTEXT_SIZE    ; reserve 4KB for main kernel thread struct
kernel_stack_bottom:
    resb STACK_SIZE     ; reserve 4KB for kernel stack
kernel_stack_top:
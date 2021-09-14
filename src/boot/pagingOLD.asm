%define PAGE_DIRECTORY_BASE 0x000E0000 ; 1 MiB in hex - 32 Pages
%define PAGE_TABLES_BASE    0x000E1000 ; 1 MiB - 31 Pages
%define PAGES_COUNT         6

; Output: nothing
clear_page_directory:
    ; Index
    mov eax, 0

    clear_page_directory_loop:
    ; Clear entry
    mov [PAGE_DIRECTORY_BASE + eax], byte 0

    ; Increment index
    inc eax

    ; Leave loop if we cleared all entries
    cmp eax, 0x1000
    jl clear_page_directory_loop

    ret


; Input: nothing
; Output: nothing
clear_page_tables:
    ; Index
    mov eax, 0

    clear_page_tables_loop:
    ; Clear entry
    mov [PAGE_TABLES_BASE + eax], byte 0

    ; Increment index
    inc eax

    ; Leave loop if we cleared all entries
    cmp eax, PAGES_COUNT * 0x1000 
    jl clear_page_tables_loop

    ret


; Input: nothing
; Output: nothing
create_page_directory:
    ; Page definition macro
    %macro page_directory_definition 3
    mov eax, %1 + 3
    mov [%2 + %3], eax
    %endmacro
    
    ; Add temporary identity entry (physical address: 0x00100000, virtual address: 0x00000000, 24 MB)
    %assign i 0 
    %rep    PAGES_COUNT 
    page_directory_definition PAGE_TABLES_BASE + (i * 0x1000), PAGE_DIRECTORY_BASE, i * 4
    %assign i i+1 
    %endrep


    ; Add entry to pd for the kernel pt (as one pt can reference 4Mb which is enough for now)
    ;page_directory_definition PAGE_TABLES_BASE + 1, PAGE_DIRECTORY_BASE + 0xC00, 0

    ; Add kernel entry (physical address: 0x00100000, virtual address: 0xC0100000, 24 MB)
    %assign i 0 
    %rep    PAGES_COUNT 
    page_directory_definition PAGE_TABLES_BASE + 0x00300000 + (i * 0x1000), PAGE_DIRECTORY_BASE + 0xC00, i * 4
    %assign i i+1 
    %endrep

    ret


; Input: nothing
; Output: nothing
create_identity_page_table:
    ; Entry index
    mov eax, 0

    ; Physical address
    mov ebx, 0x100000 ;1MB

    fill_identity_page_table_loop:
    ; Set flags: read/write, present
    mov ecx, ebx
    or ecx, 3
    
    ; Set entry
    mov [PAGE_TABLES_BASE + eax*4], ecx

    ; Go to the next entry
    add ebx, 0x1000
    inc eax

    ; Leave loop if we filled all entries for the first 6 megabytes
    cmp eax, PAGES_COUNT * 0x1000
    jl fill_identity_page_table_loop

    ret


; Input: nothing
; Output: nothing
create_kernel_page_table:
    ; Entry index
    mov eax, 0

    ; Entry physical address
    mov ebx, 0x100000 ;1MB

    fill_kernel_page_table_loop:
    ; Set flags: read/write, present
    mov ecx, ebx
    or ecx, 3
    
    ; Set entry
    mov [PAGE_TABLES_BASE + 0x00300000 + eax*4], ecx

    ; Go to the next entry
    add ebx, 0x1000
    inc eax

    ; Leave loop if we filled all entries for the first megabyte
    cmp eax, PAGES_COUNT * 0x1000
    jl fill_kernel_page_table_loop

    ret

; Input: nothing
; Output: nothing
enable_paging:
    ; Set address of the directory table
    mov eax, PAGE_DIRECTORY_BASE
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

    ret
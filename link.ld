ENTRY(start)
OUTPUT_FORMAT(elf32-i386)
INPUT
(
    bin/boot.o 
    src/kernel/kernel.o
    src/drivers/low_level.o
    src/lib/int.o
    src/lib/memory.o
    src/lib/screen.o
    src/lib/smap.o
)
OUTPUT
(
    os.bin
)


phys = 0x100000;
offset = 0xC0000000;
virt = offset + phys;

SECTIONS
{
    . = virt;

    .text : AT(ADDR(.text) - offset) {
        g_code = .;
        *(.text)
        *(.rodata)
        . = ALIGN(0x1000);
    }

    .data : AT(ADDR(.data) - offset) {
        g_data = .;
        *(.data)
        . = ALIGN(0x1000);
    }

    .bss : AT(ADDR(.bss) - offset) {
        g_bss = .;
        *(COMMON)
        *(.bss)
        . = ALIGN(0x1000);
    }

    g_end = .;

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note.gnu.build-id)
    }
}
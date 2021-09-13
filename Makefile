all: os.iso


run: all
	qemu-system-i386 -cdrom os.iso

os.iso: os.bin
	cp $< isodir/boot/os.bin
	grub-mkrescue -o $@ isodir

os.bin: boot.o kernel.o
	i386-elf-gcc -T link.ld -o os.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

boot.o : 
	nasm -felf32 boot.asm  -o boot.o

kernel.o : 
	i386-elf-gcc kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra


clean:
	rm -f *.iso *.bin 
	rm -f *.o
	rm -f isodir/boot/*.bin
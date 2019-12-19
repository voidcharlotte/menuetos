#rm -rf bootsect
rm -rf kernel
#fasm  bootmf32.asm  bootsect
fasm  KERNEL.ASM  kernel

#mformat -C -B bootsect -f 1440 -v floppy -i floppy.img ::
#mcopy -i floppy.img kernel ::root/kernel
	#cat kernel $1 > floppy.img
mcopy -i menuet.IMG kernel ::kernel.mnt

qemu-system-x86_64 -fda menuet.IMG


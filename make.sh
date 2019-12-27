#rm -rf bootsect
rm -rf kernel
#fasm  bootmf32.asm  bootsect
fasm  KERNEL.ASM  kernel
fasm  LAUNCHER.ASM  LAUNCHER
fasm  gaspardlauncher.asm  A
fasm  initg.asm  INITG
#fasm  KEYBOARDMAPDONTOPEN.asm  FRKEYBOARD

#mformat -C -B bootsect -f 1440 -v floppy -i floppy.img ::
#mcopy -i floppy.img kernel ::root/kernel
	#cat kernel $1 > floppy.img
mcopy -i menuet.IMG kernel ::kernel.mnt 

mcopy -i menuet.IMG LAUNCHER ::LAUNCHER
mcopy -i menuet.IMG RDBOOT.DAT ::RDBOOT.DAT
mcopy -i menuet.IMG A ::A
mcopy -i menuet.IMG INITG ::INITG 

#mcopy -i menuet.IMG FRKEYBOARD ::FRKEYBOARD

qemu-system-x86_64 -fda menuet.IMG


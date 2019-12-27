;KEYBOARDMAPDONTOPEN.asm


; programme qui met le clavier en francais avec un kernel call
; attention : ne pas l'ouvrir sous linix avec geany ou notepad preferez windows

use32

    org  0x0

    db   'MENUET01'             ; Header id
    dd   0x01                   ; Version
    dd   START                  ; Start of code
    dd   I_END                  ; Size of image
    dd   0x100000               ; Memory for app
    dd   0x7fff0                ; Esp
    dd   0x0,0x0                ; I_Param,I_Icon

START:                          ; Start of execution

	call configsystem
	
configsystem:

    mov  eax,21
    mov  ebx,2
    mov  ecx,1
    mov  edx,fr_keymap
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,2
    mov  edx,fr_keymap_shift
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,3
    mov  edx,fr_keymap_alt_gr
    int  0x40
    mov  eax,21
    mov  ebx,2
    mov  ecx,9
    mov  edx,5
    int  0x40

 
fr_keymap:
   
     db   '6',27
     db   '&Œ"',39,'(-Õ_”–)=',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm“',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   
   
   
fr_keymap_shift:
   
   
     db   '6',27
     db   '1234567890+',8,9
     db   'AZERTYUIOP’‘',13
     db   '~QSDFGHJKLM%',0,'÷WXCVBN?./',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB>D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   

fr_keymap_alt_gr:
   
   
     db   '6',27
     db   28,'~#{[|ÿ\^@]}',8,9
     db   'azertyuiop^$',13
     db   '~qsdfghjklm“',0,0,'*wxcvbn,;:!',0,'45 '
     db   '@234567890123',180,178,184,'6',176,'7'
     db   179,'8',181,177,183,185,182
     db   'AB<D',255,'FGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
     db   'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   


I_END:
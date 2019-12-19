;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                ;;
;;   Bootloader v0.3 for MenuetOS                                 ;;
;;                                                                ;;
;;   License: GPL / See file COPYING for details.                 ;;
;;   Bootloader comes with ABSOLUTELY NO WARRANTY.                ;;
;;   Copyright by Ville Turjanmaa, villemt@itu.jyu.fi             ;;
;;                                                                ;;
;;   Default setup: Floppy Fat12 bootsector which loads           ;;
;;   kernel.mnt from first partition of primary master harddisk   ;;
;;   with Fat32 filesystem and executes 16 bit jmp 0x1000:0x0000  ;;
;;                                                                ;;
;;   Note: Kernel.mnt must be located in the first cluster of     ;;
;;         root directory                                         ;;
;;                                                                ;;
;;   Compile with fasm 1.30+                                      ;;
;;   1) fasm thisfile.asm bootm                                   ;;
;;   2) copy bootm to target                                      ;;
;;   3) possibly disable /fd/1/config.dat read                    ;;
;;      (set boot_media to hd at kernel/bootcode.inc)             ;;
;;                                                                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


partition_start_cluster  equ  data_area+0 
fat_start_cluster        equ  data_area+4 
root_start_block         equ  data_area+8 
number_of_fats           equ  data_area+12
fat_size                 equ  data_area+16
block_start_cluster      equ  data_area+20
sectors_per_cluster      equ  data_area+24
in_cache                 equ  data_area+28

Debug                    equ  0
Fat12                    equ  1
Fat32                    equ  2

; SETUP
                         ; Load image from:
                         ;
hdbase   equ  0x1f0      ; 0x1f0 for primary device
                         ; 0x170 for secondary device
                         ;
hdid     equ  0x00       ; 0x00 for master hd
                         ; 0x10 for slave hd

                         ; Install bootsector to: 
                         ;
Header   equ  Fat12      ; Fat12:
                         ; Floppy installation can be used as such.
                         ;
                         ; Fat32:
                         ; Harddisk installation requires modification
                         ; of the Fat32 header, or you'll lose everything
                         ; on the target partition.
                         ;
                         ; Debug:
                         ; No Header. Use for debugging with floppy only !!
                         ; Messages at low left corner during boot:
                         ; 1 : bootsector loaded
                         ; 2 : file not found
                         ; 3 : file found - load starts
                         ; 4 : jump to kernel


                   jmp start_program
                   nop

if Header = Fat12
   
oemname            db 'MENUETOS'
bytespersector     dw 512
sectorspercluster  db 1
ressectors         dw 1
numcopiesfat       db 2
maxallocrootdir    dw 224
maxsectors         dw 2880 ;for 1.44 mbytes disk
mediadescriptor    db 0f0h ;fd = 2 sides 18 sectors
sectorsperfat      dw 9
sectorspertrack    dw 18
heads              dw 2
hiddensectors      dd 0
hugesectors        dd 0 ;if sectors > 65536
drivenumber        db 0
                   db 0
bootsignature      db 029h ;extended boot signature
volumeid           dd 0
volumelabel        db 'TEST       '
filesystemtype     db 'FAT12   '

end if


if Header = Fat32

Id                 db  'MSWIN4.1'
BytesPerSector     dw  200h
SectorsPerCluster  db  8
ReservedSector     dw  20h
NumberOfFATs       db  2
RootEntries        dw  0
TotalSectors       dw  0
MediaDescriptor    db  0F8h ; hd
SectorsPerFAT      dw  0   
SectorsPerTrack    dw  63
Heads              dw  255
HiddenSectors      dd  63
BigTotalSectors    db  0xbf,0x64,0x9c,0x00  
BigSectorsPerFat   db  0x10,0x27,0x00,0x00
ExtFlags           dw  0
FS_Version         dw  0
RootDirStrtClus    dd  2
FSInfoSec          dw  0x01         ; at 0x30
BkUpBootSec        dw  0x06
Reserved           dw  0,0,0,0,0,0
Drive              db  80h          ; at 0x40
HeadTemp           db  0
Signature          db  29h
SerialNumber       db  0x07,0x16,0x1a,0x39
VolumeLabel        db  'TEST       '
FileSystemID       db  'FAT32   '

end if

; 0x2000:0xfff0   - stack set at start
; es(0x1000+):0   - data read from hd

start_program:

  cli
  cld

  mov  ax,0x1000
  mov  es,ax
  mov  ax,0x2000
  mov  ss,ax
  mov  sp,0xfff0
  push cs
  pop  ds

if Header = Debug

  mov  ax,0xb800
  mov  gs,ax
  mov  [gs:80*24*2],byte '1'

end if

  xor  eax,eax
  call hd_read

  mov  eax,[es:0x1c6]                 
  mov  [partition_start_cluster],eax

  call hd_read

  mov  [in_cache],dword 0          ; clear fat cache

  movzx ecx,word [es:0xe]          ; fat start cluster
  mov  [fat_start_cluster],ecx

  movzx ecx,byte [es:0x10]         ; number of fats
  mov  [number_of_fats],ecx

  mov  ecx,[es:0x24]               ; fat size
  mov  [fat_size],ecx

  mov  eax,[number_of_fats]         ; block start cluster =
  imul eax,[fat_size]               ; number_of_fats*fat_size
  add  eax,[fat_start_cluster]      ; +fat_start_cluster
  mov  [block_start_cluster],eax

  movzx ecx,byte [es:0xd]           ; sectors per cluster
  mov  [sectors_per_cluster],ecx

  mov  eax,[block_start_cluster]      ; assumes that root starts at
  add  eax,[partition_start_cluster]  ; block number 2

new_file_cluster_search:

  mov  edi,[sectors_per_cluster]

new_file_search:

  call hd_read

  mov  esi,0
 .newn:
  cmp  [es:esi],dword 'KERN'
  jne  .not_found
  cmp  [es:esi+8],word 'MN'
  jne  .not_found
  jmp  .found
 .not_found:
  add  esi,32
  cmp  esi,512
  jne  .newn
  inc  eax
  dec  edi
  jnz  new_file_search

  if Header = Debug
     mov  [gs:80*24*2],byte '2'
  end if

  jmp  $

 .found:

  if Header = Debug
   mov  [gs:80*24*2],byte '3'
  end if

  mov  ax,[es:esi+20]              ; first cluster of file data
  shl  eax,16
  mov  ax,[es:esi+26]

  sub  eax,2                       ; eax has the first cluster of file 

new_cluster_of_file:

  push eax

  imul eax,[sectors_per_cluster]
  add  eax,[block_start_cluster]
  add  eax,[partition_start_cluster]

  mov  ecx,[sectors_per_cluster]
 newbr:
  call hd_read

  mov  dx,es
  add  dx,512 / 16
  mov  es,dx

  inc  eax
  dec  ecx
  jnz  newbr

  pop  eax
  call find_next_cluster_from_fat

  cmp  eax,0xf000000
  jb   new_cluster_of_file

  mov  ax,0x1000
  mov  es,ax

  sti

if Header = Debug

   mov  [gs:80*24*2],byte '4'

end if

if Header = Fat12

  mov  dx,0x3f2                  ; turn floppy motor off
  mov  al,0
  out  dx,al

end if

  jmp  0x1000:0000 

   
find_next_cluster_from_fat:

  push es
  mov  bx,0x1000-512/16
  mov  es,bx

  add  eax,2
  shl  eax,2
   
  mov  ecx,eax
  shr  eax,9             ; cluster no

  add  eax,[fat_start_cluster]
  add  eax,[partition_start_cluster]

  cmp  eax,[in_cache]    ; check cache
  je   no_read
  call hd_read
  mov  [in_cache],eax
 no_read:
   
  and  ecx,511           ; in cluster
  mov  eax,[es:ecx]
  sub  eax,2

  pop  es
   
  ret



hd_read:      ; eax block to read

    pushad 
    push  eax

  newhdread:
   
    mov   edx,hdbase
    inc   edx
    mov   al,0
    out   dx,al

    inc   edx
    mov   al,1
    out   dx,al

    inc   edx
    pop   ax
    out   dx,al

    inc   edx
    shr   ax,8
    out   dx,al

    inc   edx
    pop   ax
    out   dx,al

    inc   edx
    shr   ax,8
    and   al,1+2+4+8
    add   al,hdid
    add   al,128+64+32
    out   dx,al

    inc   edx
    mov   al,20h
    out   dx,al
   
  .hdwait:
   
    in    al,dx
    test  al,128
    jnz   .hdwait

    mov   edi,0x0 
    mov   ecx,256
    mov   edx,hdbase
    cld
    rep   insw

    popad

    ret
   
times ((0x1fe-$) and 0xff) db 00h

  db 55h,0aah ;boot signature

data_area:



; gasparcd systsem kernel call thanks DHCP.asm for the dhcp impnetation the dhcp socket part is a direct inspiration from 'DHCP.ASM'
gaspard:
		;cli test
		;jmp   $ test
		;ethernet ?maintenant 
		cmp ebx,0 ;0 = activer ethernet
		jnz addiptostack
		call ash_eth_enable
		ret
		
		
addiptostack:

	cmp ebx,1
	jnz no1gaspard
;	call setipadressint ; l'adresse ip est dans ecx
	ret

	
no1gaspard: 
		ret

;dhcp.asm



;;;;;;;;;;;;;;;;;;;;;;GASPARD INIT
dhcpkernelinit:

	call contactDHCPServer

;;;;;;;;;;;;;;;GASPARD



parseResponse:
    mov     edx, dhcpMsg

    mov     eax, [edx+16]
    mov     [dhcpClientIP], eax

    ; Scan options

    add     edx, 240        ; Point to first option

pr001:
    ; Get option id
    mov     al, [edx]
    cmp     al, 0xff        ; End of options?
    je      pr_exit

    cmp     al, 53          ; Msg type is a single byte option
    jne     pr002

    mov     al, [edx+2]
    mov     [dhcpMsgType], al
    add     edx, 3
    jmp     pr001           ; Get next option

pr002:
    ; All other (accepted) options are 4 bytes in length
    inc     edx
    movzx   ecx, byte [edx]
    inc     edx             ; point to data

    cmp     al, 54          ; server id
    jne     pr0021
    mov     eax, [edx]      ; All options are 4 bytes, so get it
    mov     [dhcpServerIP], eax
    jmp     pr003

pr0021:
    cmp     al, 51          ; lease
    jne     pr0022
    mov     eax, [edx]      ; All options are 4 bytes, so get it
    mov     [dhcpLease], eax
    jmp     pr003

pr0022:
    cmp     al, 1           ; subnet mask
    jne     pr0023
    mov     eax, [edx]      ; All options are 4 bytes, so get it
    mov     [dhcpSubnet], eax
    jmp     pr003

pr0023:
    cmp     al, 6           ; dns ip
    jne     pr0024
    mov     eax, [edx]      ; All options are 4 bytes, so get it
    mov     [dhcpDNSIP], eax

pr0024:
    cmp     al, 3           ; gateway ip
    jne     pr003
    mov     eax, [edx]      ; All options are 4 bytes, so get it
    mov     [dhcpGateway], eax

pr003:
    add     edx, ecx
    jmp     pr001

pr_exit:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CONSTRUIRE

buildRequest:
    ; Clear dhcpMsg to all zeros
    xor     eax,eax
    mov     edi,dhcpMsg
    mov     ecx,512
    cld
    rep     stosb

    mov     edx, dhcpMsg

    mov     [edx], byte 0x01                ; Boot request
    mov     [edx+1], byte 0x01              ; Ethernet
    mov     [edx+2], byte 0x06              ; Ethernet h/w len
    mov     [edx+4], dword 0x11223344       ; xid
    mov     [edx+10], byte 0x80             ; broadcast flag set
    mov     [edx+236], dword 0x63538263     ; magic number

    ; option DHCP msg type
    mov     [edx+240], word 0x0135
    mov     al, [dhcpMsgType]
    mov     [edx+240+2], al

    ; option Lease time = infinity
    mov     [edx+240+3], word 0x0433
    mov     eax, [dhcpLease]
    mov     [edx+240+5], eax

    ; option requested IP address
    mov     [edx+240+9], word 0x0432
    mov     eax, [dhcpClientIP]
    mov     [edx+240+11], eax

    ; option request list
    mov     [edx+240+15], word 0x0437
    mov     [edx+240+17], dword 0x0f060301

    ; Check which msg we are sending
    cmp     [dhcpMsgType], byte 0x01
    jne     br001

    ; "Discover" options
    ; end of options marker
    mov     [edx+240+21], byte 0xff

    mov     [dhcpMsgLen], dword 262
    jmp     br_exit

br001:
    ; "Request" options

    ; server IP
    mov     [edx+240+21], word 0x0436
    mov     eax, [dhcpServerIP]
    mov     [edx+240+23], eax

    ; end of options marker
    mov     [edx+240+27], byte 0xff

    mov     [dhcpMsgLen], dword 268

br_exit:
    ret



;;;;;;;;;;;;;;;;;;;;;CONSTRUIRE

;;;;;;;;;;;;;;;reseaux 

contactDHCPServer:
    ; First, open socket
    mov     ecx, 68                 ; local port dhcp client
    mov     edx, 67                 ; remote port - dhcp server
    mov     esi, 0xffffffff         ; broadcast
    call socket_open
    
    mov     [socketNum], eax

    ; Setup the first msg we will send
    mov     [dhcpMsgType], byte 0x01 ; DHCP discover
    mov     [dhcpLease], dword 0xffffffff
    mov     [dhcpClientIP], dword 0
    mov     [dhcpServerIP], dword 0

    call    buildRequest
	
ctr000:
    ; write to socket ( send broadcast request )
    mov     ecx, [socketNum]
    mov     edx, [dhcpMsgLen]
    mov     esi, dhcpMsg
	call socket_write
    ; Setup the DHCP buffer to receive response

    mov     eax, dhcpMsg
    mov     [dhcpMsgLen], eax      ; Used as a pointer to the data

    ; now, we wait for
    ; UI redraw
    ; UI close
    ; or data from remote

ctr001:


    ; Any data in the UDP receive buffer?
    mov     ecx, [socketNum]
	call socket_poll
    cmp     eax, 0
    je      ctr001

    ; we have data - this will be the response
ctr002:
    mov     ecx, [socketNum]
	call socket_read
    ; Store the data in the response buffer
    mov     eax, [dhcpMsgLen]
    mov     [eax], bl
    inc     dword [dhcpMsgLen]

  
    mov     ecx, [socketNum]
	call socket_poll

    cmp     eax, 0
    jne     ctr002              ; yes, so get it

    ; depending on which msg we sent, handle the response
    ; accordingly.
    ; If the response is to a dhcp discover, then:
    ;  1) If response is DHCP OFFER then
    ;  1.1) record server IP, lease time & IP address.
    ;  1.2) send a request packet
    ;  2) else exit ( display error )
    ; If the response is to a dhcp request, then:
    ;  1) If the response is DHCP ACK then
    ;  1.1) extract the DNS & subnet fields. Set them in the stack
    ;  2) else exit ( display error )


    cmp     [dhcpMsgType], byte 0x01    ; did we send a discover?
    je      ctr007
    cmp     [dhcpMsgType], byte 0x03    ; did we send a request?
    je      ctr008

    ; should never get here - we only send discover or request
    jmp     ctr006

ctr007:
    call    parseResponse

    ; Was the response an offer? It should be
    cmp     [dhcpMsgType], byte 0x02
    jne     ctr006                  ; NO - so quit

    ; send request
    mov     [dhcpMsgType], byte 0x03 ; DHCP request
    call    buildRequest
    jmp     ctr000

ctr008:
    call    parseResponse

    ; Was the response an ACK? It should be
    cmp     [dhcpMsgType], byte 0x05
    jne     ctr006                  ; NO - so quit

    ; Set or display addresses here...

ctr006:
  
    mov     ecx, [socketNum]
	call socket_close
    mov     [socketNum], dword 0xFFFF


    jmp     ctr001

ctr003:                         ; redraw
    jmp     ctr001

ctr004:                         ; key

    jmp     ctr001

ctr005:                         ; button
  

    ; close socket

    mov     ecx, [socketNum]
	call socket_close
    mov     [socketNum], dword 0xFFFF


    ret






;;;;RESEAUX;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





socketNum:      dd  0xFFFF ; dd variebel numero de socket
dhcpMsgType:    db  0
dhcpLease:      dd  0
dhcpClientIP:   dd  0
dhcpServerIP:   dd  0
dhcpDNSIP:      dd  0
dhcpSubnet:     dd  0
dhcpGateway:    dd  0

dhcpMsgLen:     dd  0
dhcpMsg:

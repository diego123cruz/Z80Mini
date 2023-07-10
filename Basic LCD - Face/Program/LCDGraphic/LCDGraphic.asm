; -----------------------------------------------------------------------------
;   LCD DRIVER
; -----------------------------------------------------------------------------
; INIT_LCD - Inicia o lcd em mode texto
; lcd_setPixel - Liga um pixel (0 - 8191) pixel address em HL
; lcd_clearPixel - Desliga um pixel (0 - 8191) pixel address em HL
; lcd_clear - Limpa buffer do lcd
; enable_grafic - Coloca o LCD em modo grafico
; print_image - Coloca o conteudo de HL (128x64 bits) no LCD
; cls_TXT - Limpa LCD mode text
; cls_GRAPHIC - Limpa LCD modo grafico

INIT_LCD:
    ;Initialisation
	ld a, 30H
	call lcd_send_command

	ld a, 0b00100000
	call lcd_send_command

	ld a, 30H
	call lcd_send_command

	ld a, 0CH
	call lcd_send_command

	ld a, 01H
	call lcd_send_command_clear ;; clear

	ld a, 02H
	call lcd_send_command
    RET



INIT_TXT_LCD:
    ld a, 0
    ld (LCD_TXT_X), a
    ld (LCD_TXT_Y), a
    ld (LCD_DELETE_CHAR), a
    ld (LCD_AUTO_X), a
    ld hl, 0
    ld (LCD_TXT_X_TMP), hl
    inc hl
    ld (LCD_TXT_Y_TMP), hl
    RET


DISPLAY_SCROLL_UP:
    ; cada linha tem 128 bytes
    ; temos 8 linhas
    ; total 1024 bytes

    ; display lines 0 to 7
    ; move line 1 to 0
    ld hl, DISPLAY+128
    ld de, DISPLAY
    ld bc, 127
    ldir

    ; move line 2 to 1
    ld hl, DISPLAY+256
    ld de, DISPLAY+128
    ld bc, 127
    ldir

    ; move line 3 to 2
    ld hl, DISPLAY+384
    ld de, DISPLAY+256
    ld bc, 127
    ldir

    ; move line 4 to 3
    ld hl, DISPLAY+512
    ld de, DISPLAY+384
    ld bc, 127
    ldir

    ; move line 5 to 4
    ld hl, DISPLAY+640
    ld de, DISPLAY+512
    ld bc, 127
    ldir

    ; move line 6 to 5
    ld hl, DISPLAY+768
    ld de, DISPLAY+640
    ld bc, 127
    ldir

    ; move line 7 to 6
    ld hl, DISPLAY+896
    ld de, DISPLAY+768
    ld bc, 127
    ldir

    ; clear line 7
    ; 896 to 1024
    ld hl, DISPLAY+896
    ld e,l
    ld d,h
    inc de
    ld (hl), 0
    ld bc, 127
    ldir
    RET

;---------------
; OUTPUT A SPACE
;---------------
OUTSP:  LD    A, ' '
       CALL  PRINTCHAR
       RET

;-------------      
; OUTPUT CRLF (NEW LINE)
;------------
TXCRLF: LD   A,CR
       CALL PRINTCHAR   
       RET
       

DELETE_CHAR:
    POP HL ; retorno do call
    LD A, 0
    LD (LCD_DELETE_CHAR), A
    LD A, (LCD_TXT_X)
    DEC A
    LD (LCD_TXT_X), A

    LD A, $FF
    LD (LCD_AUTO_X), A

    POP AF
    LD A, ' '
    LD (LCD_CHAR), A
    PUSH AF
    PUSH HL ; call
    RET


; Print char in buffer and show to lcd
; char in A
PRINTCHAR:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    CALL PrintBufferChar
    LD HL, DISPLAY
    CALL print_image
    POP HL
    POP DE
    POP BC
    POP AF
    RET


; Print char in buffer lcd (without show to lcd)
; char in A
PrintBufferChar:
    LD (LCD_CHAR), A ; save char to print

    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    PUSH AF
    LD A, $0
    LD (LCD_AUTO_X), A
    POP AF


ver_delete:
    PUSH AF
    LD A, (LCD_DELETE_CHAR)
    or a
    CP $FF
    call z, DELETE_CHAR
    POP AF
    or a
    CP $0
    jr nz, ver_enter
    LD A, $FF ; delete proximo char
    LD (LCD_DELETE_CHAR), A
    jp print_char_fim

    ; Verificar Enter, clear, etc... SEM PERDER O reg. A
ver_enter:       

                ; trata dados para o lcd
                CP      CR                     ; compara com ENTER
                jr      nz, ver_limpa

                LD A,0
                LD (LCD_TXT_X), A ; ajusta X para o inicio da linha

                LD A, (LCD_TXT_Y)
                inc a
                cp 8
                jp nz, ver_enter_incYOK
                
                CALL DISPLAY_SCROLL_UP
                ;ld hl, DISPLAY
                ;CALL print_image <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                
                jp print_char_fim

ver_enter_incYOK:
                ld (LCD_TXT_Y), a
                jp print_char_fim


ver_limpa:
                CP      $0C                     ; compara com limpar tela
                jr      NZ, ver_line
                
                ;call    clear_lcd_screen
                ;call    show_lcd_screen
                call lcd_clear
                ;ld hl, DISPLAY
                ;call print_image <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                LD A, 0
                LD (LCD_TXT_X), A
                LD (LCD_TXT_Y), A

                JP print_char_fim

ver_line:
                CP      LF                     ; retorna começo da linha
                jr      NZ, print_lcd      

                    ;----- verificar se precisa add algo aqui
                ;call    shift_lcd_up
                ;call    show_lcd_screen
                JP print_char_fim

print_lcd:
    ; pega o ponteiro para o caracter e salva em LCD_CHAR_POINT
    ld H, 0
    ld L, A
    ADD HL, HL ; hl x 8
    ADD HL, HL
    ADD HL, HL

    LD D, H
    LD E, L
    ld hl, TABLE
    add hl, de
    ld (LCD_CHAR_POINT), HL ; table


    ; ajusta X
    ld b, 6
    ld a, (LCD_TXT_X)
    or A
    jp z, ajustX
    ld c, a
    call multiplication
    jp ajustXOK
    
ajustX:
    ld hl, 0
ajustXOK:
    ld (LCD_TXT_X_TMP), HL 



    ; ajuste Y
    ld d, 4
    ld e, 0 ; = 128x8 proxima linha
    ld hl, (LCD_TXT_Y_TMP)
    ld a, (LCD_TXT_Y)
    or a
    JP Z, multYfim
    ld hl, 0
    ld b, a
multY:
    add hl, de
    DJNZ multY

    ld (LCD_TXT_Y_TMP), HL
    jp multYfimok

multYfim:
    ld hl, 0
    ld (LCD_TXT_Y_TMP), HL

multYfimok:

    ld hl, (LCD_TXT_Y_TMP)
    ld de, (LCD_TXT_X_TMP)

    add hl, de  ; hl tem pos do pix 0-8191

    ld (LCD_TMP_POINT), hl


    ld a, 8 ; altura do caracter
    ld (LCD_CHAR_H), a
printchar_loopH:
    ld hl, (LCD_CHAR_POINT)
    ld a, (HL)
    ld (LCD_TEMP), a

    ld a, 6 ; largura do caracter
    ld (LCD_CHAR_W), a
printchar_loopW:
    ld a, (LCD_TEMP)
    and 128
    cp 0
    jp z, printchar_loopWC
    ld hl, (LCD_TMP_POINT)
    call lcd_setPixel
    JP printchar_loopWE

printchar_loopWC:
    ld hl, (LCD_TMP_POINT)
    call lcd_clearPixel

printchar_loopWE:
    ld a, (LCD_TEMP)
    sla a
    ld (LCD_TEMP), a
    
    ld hl, (LCD_TMP_POINT)
    inc hl
    ld (LCD_TMP_POINT), hl

    ld a, (LCD_CHAR_W)
    dec A
    ld (LCD_CHAR_W), a
    cp 0
    JP NZ, printchar_loopW


    ld hl, (LCD_TMP_POINT)
    dec hl
    dec hl
    dec hl
    dec hl
    dec hl
    dec hl

    ld d, 0
    ld e, 128
    add hl, de
    ld (LCD_TMP_POINT), HL

    ld hl, (LCD_CHAR_POINT)
    inc hl
    ld (LCD_CHAR_POINT), hl


    ld a, (LCD_CHAR_H)
    dec A
    ld (LCD_CHAR_H), a
    cp 0
    jp NZ, printchar_loopH

    ;ld hl, DISPLAY
    ;call print_image <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


    ; check auto x
    LD A, (LCD_AUTO_X)
    OR A
    CP $FF
    JP Z, print_char_fim

    ; increment X, Y
    ld a, (LCD_TXT_X)
    inc a
    cp 21
    jp nz, incXOK
    ld a, 0
    ld (LCD_TXT_X), a
    ld a, (LCD_TXT_Y)
    inc a
    cp 8
    jp nz, incYOK
    CALL DISPLAY_SCROLL_UP
    ;ld hl, DISPLAY
    ;CALL print_image <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ld a, 0
    ld (LCD_TXT_X), a
    jp print_char_fim

incYOK:
    ld (LCD_TXT_Y), a
    jp print_char_fim

incXOK:
    ld (LCD_TXT_X), a

print_char_fim:
    ;ld hl, DISPLAY
    ;CALL print_image
    POP HL
    POP DE
    POP BC
    POP AF
    RET
;-------- FIM PRINTCHAR ------------------




; =========================================================
; Delay
; =========================================================
delay:
	push bc                       ; 2.75 us
    ld b, 1                     ; 1.75 us
delay_loop_b:
	ld c, 255                     ; 1.75 us
delay_loop:
	dec c                         ; 1 us
    jp nz, delay_loop             ; true = 3 us, false 1.75 us
    dec b                         ; 1 us
    jp nz, delay_loop_b           ; true = 3 us, false 1.75 us
    pop bc                        ; 2.50 us
    ret   




; pixel index in HL
lcd_setPixel:
    push hl
    push bc
    push de
    push af
    xor A
    ld (LCD_BIT_INDEX), A
    ld (LCD_BYTE_INDEX), A

    ld d, 8
    call Div_HL_D
    ld (LCD_BIT_INDEX), A
    ld (LCD_BYTE_INDEX), HL
    ld BC, (LCD_BYTE_INDEX)
    ld hl, DISPLAY
    add hl, bc
    
    ld b, 128 ; 1000 0000
    ld a, (LCD_BIT_INDEX) ;
    cp 0
    jp z, lcd_setPixel_fim
lcd_setPixel_bit:
    srl B
    dec A
    jp z, lcd_setPixel_fim
    
    jp lcd_setPixel_bit
lcd_setPixel_fim
    ld a, (hl)
    or b
    ld (hl), a

    pop af
    pop bc
    pop de
    pop hl
    ret

;===============================
; pixel index in HL
lcd_clearPixel:
    push hl
    push bc
    push de
    push af
    xor A
    ld (LCD_BIT_INDEX), A
    ld (LCD_BYTE_INDEX), A
    ld d, 8
    call Div_HL_D
    ld (LCD_BIT_INDEX), A
    ld (LCD_BYTE_INDEX), HL
    ld BC, (LCD_BYTE_INDEX)
    ld hl, DISPLAY
    add hl, bc
    
    ld b, 128 ; 1000 0000
    ld a, (LCD_BIT_INDEX) ;
    cp 0
    jp z, lcd_clearPixel_fim
lcd_clearPixel_bit:
    srl B
    dec A
    jp z, lcd_clearPixel_fim
    
    jp lcd_clearPixel_bit
lcd_clearPixel_fim
    ld a, b
    cpl     ; NOT B
    ld b, a

    ld a, (hl)
    and b
    ld (hl), a

    pop af
    pop bc
    pop de
    pop hl
    ret


;;--------------------------------------------------
lcd_clear:
    ;; HL = start address of block
    ld hl, DISPLAY

    ;; DE = HL + 1
    ld e,l
    ld d,h
    inc de

    ;; initialise first byte of block
    ;; with data byte (&00)
    ld (hl), 0
        
    ;; BC = length of block in bytes
    ;; HL+BC-1 = end address of block

    ld bc, 1024

    ;; fill memory
    ldir
    ret


;===================

; grafic mode - enable
enable_grafic:
	ld a, 30H
	call lcd_send_command
	call delayLCD
	
	ld a, 34H
	call lcd_send_command
	call delayLCD
	
	ld a, 36H
	call lcd_send_command
	call delayLCD
    ret


;==========================
print_image:
PLOT_TO_LCD:	
        LD HL, DISPLAY
        LD C, 80H
PLOT_ROW:	
        LD A, C
        AND 9FH
        OUT (LCDCTRL), A ;Vertical
        CALL DELAY_US
        LD A, 80H
        BIT 5, C
        JR Z, $ + 4
        OR 08H
        OUT (LCDCTRL), A ;Horizontal
        CALL DELAY_US
        
        LD B, 10H 		;send eight double bytes (16 bytes)
PLOT_COLUMN:	
        LD A, (HL)
        OUT (LCDDATA), A ;Byte 1
        CALL DELAY_US
        INC HL
        DJNZ PLOT_COLUMN
        INC C
        BIT 6, C 		;Is Row = 64?
        JR Z, PLOT_ROW
        RET
        
; Delay for LCD write
DELAY_US:	
        LD DE, $0004 ;DELAY BETWEEN, was 0010H
DELAY_MS:	
        DEC DE 			;EACH BYTE
        LD A, D 		;AS PER
        OR E 			;LCD MANUFACTER'S
        JR NZ, DELAY_MS ;INSTRUCTIONS
        RET

print_image2:						; LOAD 128*64 bits (16*8 Byte) of data into the LCD screen
									; HL content the data address
    push af
	push de
	push bc


; premiere partie : X de 0 à 127 / Y de 0 à 32

	ld a,32
	ld d,a							; boucle Y
	ld a,0
	ld e,a
	
boucle_colonne:
		ld a,$80					; coordonnée Y (0)
		add a,e
		call lcd_send_command
		
		ld a,$80					; coordonnée X (0)		
		call lcd_send_command
		
		ld a,8
		ld b,a						; boucle X
		
boucle_ligne:	
			ld a,(hl)
			call lcd_send_data
			inc hl
			ld a,(hl)
			call lcd_send_data		; auto-increment on screen address
			inc hl
			dec b
			XOR a
			OR b
			jp nz,boucle_ligne		; tant qu'on a pas fait 7 
		
		dec d
		inc e
		XOR a
		OR d
		jp nz,boucle_colonne
		

; seconde partie : X de 128 à 255 / Y de 0 à 32

	ld a,32
	ld d,a							; boucle Y
	ld a,0
	ld e,a
	
boucle_colonne2:
		ld a,$80					; coordonnée Y (0)
		add a, e
		call lcd_send_command
		
		ld a,$88					; coordonnée X (8)		
		call lcd_send_command
		
		ld a,8
		ld b,a						; boucle X
		
boucle_ligne2:	
			ld a,(hl)
			call lcd_send_data
			inc hl
			ld a,(hl)
			call lcd_send_data		; auto-increment on screen address
			inc hl
			dec b
			XOR a
			OR b
			jp nz,boucle_ligne2		; tant qu'on a pas fait 7 
		
		dec d
		inc e
		XOR a
		OR d
		jp nz,boucle_colonne2

	pop bc
	pop de
    pop af

    ret



; ======================
cls_TXT:
	; # CLEAR DISPLAY IN TEXT MODE # 
	ld a,%00000001 					; CLEAR DISPLAY -> " $01 "
	call lcd_send_command_clear		; CLEAR DISPLAY	
    ret

; ========================

cls_GRAPHIC:		;   Fill entire Graphical screen with value 0
					;	Graphic RAM (GDRAM) use :
					;	1. Set vertical address (Y) for GDRAM
					;	2. Set horizontal address (X) for GDRAM
					;	3. Write D15~D8 to GDRAM (first byte)
					;	4. Write D7~D0 to GDRAM (second byte)
	push bc
	push de

	ld e,$20						; e = 32 
	ld d,$0							; d = 0
Boucle32X:
		ld a,d
		OR $80
		call lcd_send_command
		
		ld a,$80					; Set horizontal address（X） for GDRAM = 0 ($80)
		call lcd_send_command
		
		xor a							 	
		ld b,$10							; b = 17
		
Boucle16X:	 
			call lcd_send_data 			; Write D15〜D8 to GDRAM (first byte)
			call lcd_send_data 			; Write D7〜D0 to GDRAM (second byte)
											; Address counter will automatically increase by one for the next two-byte data												
			djnz Boucle16X					; b = b -1 ; jump to label if b not 0
		
		dec e 
		inc d
		xor a							; a = 0
		or e
		jp nz,Boucle32X

	pop de
	pop bc
	
    ret



;******************
;Send a command byte to the LCD
;Entry: A= command byte
;Exit: All preserved
;******************
lcd_send_command:
	push bc				;Preserve
	ld c, LCDCTRL   	;Command port
	
	call delayLCD
	
	out (c),a			;Send command
	pop bc				;Restore
	ret


;******************
;Send a command byte to the LCD
;Entry: A= command byte
;Exit: All preserved
;******************
lcd_send_command_clear:
	push bc				;Preserve
	
	call delayLCDclear
	
    ld c, LCDCTRL   	;Command port
	out (c),a			;Send command
	pop bc				;Restore
	ret
	
;******************
;Send a data byte to the LCD
;Entry: A= data byte
;Exit: All preserved
;******************
lcd_send_data:
	push bc				;Preserve
	
    ;Busy wait
	call delayLCD

	ld c, LCDDATA	;Data port $71
	out (c),a			;Send data
	pop bc				;Restore
	ret




;******************
;Send an asciiz string to the LCD
;Entry: HL=address of string
;Exit: HL=address of ending zero of the string. All others preserved
;******************
lcd_send_asciiz:
	push af
	push bc				;Preserve
lcd_asciiz_char_loop:
	ld c, LCDCTRL   	;Command port
	
lcd_asciiz_wait_loop:	;Busy wait
	call delayLCD
	
	ld a,(hl)			;Get character
	and a				;Is it zero?
	jr z,lcd_asciiz_done	;If so, we're done
	
	ld c, LCDDATA	;Data port
	out (c),a			;Send data
	inc hl				;Next char
	jr lcd_asciiz_char_loop
	
lcd_asciiz_done:
	pop bc				;Restore
	pop af
	ret

; =========================================================
; Delay LCD
; =========================================================
delayLCD:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ret

delayLCDclear:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ret

;-----------------------------------------
; SEND AN ASCII STRING OUT LCD
;-----------------------------------------
; 
; SENDS A ZERO TERMINATED STRING OR 
; 128 CHARACTERS MAX. OUT LCD
;
;      ENTRY : HL = POINTER TO 00H TERMINATED STRING
;      EXIT  : NONE
;
;       MODIFIES : A,B,C
;          
SNDLCDMSG: LD    B,128         ;128 CHARS MAX
SDLCDMSG1: LD    A,(HL)        ;GET THE CHAR
       CP    00H          ;ZERO TERMINATOR?
       JR    Z,SDLCDMSG2      ;FOUND A ZERO TERMINATOR, EXIT  
       CALL PrintBufferChar         ;TRANSMIT THE CHAR
       INC   HL
       DJNZ  SDLCDMSG1        ;128 CHARS MAX!    
SDLCDMSG2: 
    LD HL, DISPLAY
    CALL print_image
RET


















TABLE:
.db $00, $00, $00, $00, $00, $00, $00, $00 ; NUL
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SOH
.db $00, $00, $00, $00, $00, $00, $00, $00 ; STX
.db $00, $00, $00, $00, $00, $00, $00, $00 ; ETX
.db $00, $00, $00, $00, $00, $00, $00, $00 ; EOT
.db $00, $00, $00, $00, $00, $00, $00, $00 ; ENQ
.db $00, $00, $00, $00, $00, $00, $00, $00 ; ACK
.db $00, $00, $00, $00, $00, $00, $00, $00 ; BEL
.db $00, $00, $00, $00, $00, $00, $00, $00 ; BS
.db $00, $00, $00, $00, $00, $00, $00, $00 ; TAB
.db $00, $00, $00, $00, $00, $00, $00, $00 ; LF
.db $00, $00, $00, $00, $00, $00, $00, $00 ; VT
.db $00, $00, $00, $00, $00, $00, $00, $00 ; FF
.db $00, $00, $00, $00, $00, $00, $00, $00 ; CR
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SO
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SI
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DLE
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DC1
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DC2
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DC3
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DC4
.db $00, $00, $00, $00, $00, $00, $00, $00 ; NAK
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SYN
.db $00, $00, $00, $00, $00, $00, $00, $00 ; ETB
.db $00, $00, $00, $00, $00, $00, $00, $00 ; CAN
.db $00, $00, $00, $00, $00, $00, $00, $00 ; EM
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SUB
.db $00, $00, $00, $00, $00, $00, $00, $00 ; ESC
.db $00, $00, $00, $00, $00, $00, $00, $00 ; FS
.db $00, $00, $00, $00, $00, $00, $00, $00 ; GS
.db $00, $00, $00, $00, $00, $00, $00, $00 ; RS
.db $00, $00, $00, $00, $00, $00, $00, $00 ; US

; DEC 32
.db $00, $00, $00, $00, $00, $00, $00, $00 ; SPACE
.db $20, $20, $20, $20, $20, $00, $20, $00 ; !
.db $50, $50, $50, $00, $00, $00, $00, $00 ; "
.db $50, $50, $F8, $50, $F8, $50, $50, $00 ; #
.db $20, $78, $A0, $70, $28, $F0, $20, $00 ; $
.db $C0, $C8, $10, $20, $40, $98, $18, $00 ; %
.db $60, $90, $A0, $40, $A8, $90, $68, $00 ; &
.db $20, $20, $20, $00, $00, $00, $00, $00 ; '
.db $10, $20, $40, $40, $40, $20, $10, $00 ; (
.db $40, $20, $10, $10, $10, $20, $40, $00 ; )
.db $00, $20, $A8, $70, $A8, $20, $00, $00 ; *
.db $00, $20, $20, $F8, $20, $20, $00, $00 ; +
.db $00, $00, $00, $00, $60, $20, $40, $00 ; ,
.db $00, $00, $00, $F8, $00, $00, $00, $00 ; -
.db $00, $00, $00, $00, $00, $60, $60, $00 ; .
.db $00, $00, $08, $10, $20, $40, $80, $00 ; /
.db $70, $88, $98, $A8, $C8, $88, $70, $00 ; 0
.db $20, $60, $20, $20, $20, $20, $70, $00 ; 1
.db $70, $88, $08, $10, $20, $40, $F8, $00 ; 2
.db $F8, $10, $20, $10, $08, $88, $70, $00 ; 3
.db $10, $30, $50, $90, $F8, $10, $10, $00 ; 4
.db $F8, $80, $F0, $08, $08, $88, $70, $00 ; 5
.db $30, $40, $80, $F0, $88, $88, $70, $00 ; 6
.db $F8, $08, $10, $20, $40, $40, $40, $00 ; 7
.db $70, $88, $88, $70, $88, $88, $70, $00 ; 8
.db $70, $88, $88, $78, $08, $10, $60, $00 ; 9
.db $00, $00, $30, $30, $00, $30, $30, $00 ; :
.db $00, $30, $30, $00, $30, $10, $20, $00 ; ;
.db $10, $20, $40, $80, $40, $20, $10, $00 ; <
.db $00, $00, $F8, $00, $F8, $00, $00, $00 ; =
.db $40, $20, $10, $08, $10, $20, $40, $00 ; >
.db $30, $48, $08, $10, $20, $00, $20, $00 ; ?
.db $70, $88, $08, $68, $A8, $A8, $70, $00 ; @

; DEC 65 Maiusculas
.db $20, $50, $88, $88, $F8, $88, $88, $00 ; A
.db $F0, $88, $88, $F0, $88, $88, $F0, $00 ; B
.db $70, $88, $80, $80, $80, $88, $70, $00 ; C
.db $E0, $90, $88, $88, $88, $90, $E0, $00 ; D
.db $F8, $80, $80, $F0, $80, $80, $F8, $00 ; E
.db $F8, $80, $80, $F0, $80, $80, $80, $00 ; F
.db $70, $88, $80, $80, $B8, $88, $70, $00 ; G
.db $88, $88, $88, $F8, $88, $88, $88, $00 ; H
.db $70, $20, $20, $20, $20, $20, $70, $00 ; I
.db $08, $08, $08, $08, $88, $88, $70, $00 ; J
.db $88, $90, $A0, $C0, $A0, $90, $88, $00 ; K
.db $80, $80, $80, $80, $80, $80, $F8, $00 ; L
.db $88, $D8, $A8, $88, $88, $88, $88, $00 ; M
.db $88, $88, $C8, $A8, $98, $88, $88, $00 ; N
.db $70, $88, $88, $88, $88, $88, $70, $00 ; O
.db $F0, $88, $88, $F0, $80, $80, $80, $00 ; P
.db $70, $88, $88, $88, $A8, $98, $70, $00 ; Q
.db $F0, $88, $88, $F0, $88, $88, $88, $00 ; R
.db $70, $88, $80, $70, $08, $88, $70, $00 ; S
.db $F8, $20, $20, $20, $20, $20, $20, $00 ; T
.db $88, $88, $88, $88, $88, $88, $70, $00 ; U
.db $88, $88, $88, $88, $88, $50, $20, $00 ; V
.db $88, $88, $88, $88, $A8, $D8, $88, $00 ; W
.db $88, $88, $50, $20, $50, $88, $88, $00 ; X
.db $88, $88, $50, $20, $20, $20, $20, $00 ; Y
.db $F8, $08, $10, $20, $40, $80, $F8, $00 ; Z

; DEC 91
.db $30, $20, $20, $20, $20, $20, $30, $00 ; [
.db $00, $80, $40, $20, $10, $08, $00, $00 ; \
.db $60, $20, $20, $20, $20, $20, $60, $00 ; ]
.db $20, $50, $88, $00, $00, $00, $00, $00 ; ^
.db $00, $00, $00, $00, $00, $00, $F8, $00 ; _
.db $40, $20, $10, $00, $00, $00, $00, $00 ; `

; DEC 97 "Minusculas"
.db $20, $50, $88, $88, $F8, $88, $88, $00 ; A
.db $F0, $88, $88, $F0, $88, $88, $F0, $00 ; B
.db $70, $88, $80, $80, $80, $88, $70, $00 ; C
.db $E0, $90, $88, $88, $88, $90, $E0, $00 ; D
.db $F8, $80, $80, $F0, $80, $80, $F8, $00 ; E
.db $F8, $80, $80, $F0, $80, $80, $80, $00 ; F
.db $70, $88, $80, $80, $B8, $88, $70, $00 ; G
.db $88, $88, $88, $F8, $88, $88, $88, $00 ; H
.db $70, $20, $20, $20, $20, $20, $70, $00 ; I
.db $08, $08, $08, $08, $88, $88, $70, $00 ; J
.db $88, $90, $A0, $C0, $A0, $90, $88, $00 ; K
.db $80, $80, $80, $80, $80, $80, $F8, $00 ; L
.db $88, $D8, $A8, $88, $88, $88, $88, $00 ; M
.db $88, $88, $C8, $A8, $98, $88, $88, $00 ; N
.db $70, $88, $88, $88, $88, $88, $70, $00 ; O
.db $F0, $88, $88, $F0, $80, $80, $80, $00 ; P
.db $70, $88, $88, $88, $A8, $98, $70, $00 ; Q
.db $F0, $88, $88, $F0, $88, $88, $88, $00 ; R
.db $70, $88, $80, $70, $08, $88, $70, $00 ; S
.db $F8, $20, $20, $20, $20, $20, $20, $00 ; T
.db $88, $88, $88, $88, $88, $88, $70, $00 ; U
.db $88, $88, $88, $88, $88, $50, $20, $00 ; V
.db $88, $88, $88, $88, $A8, $D8, $88, $00 ; W
.db $88, $88, $50, $20, $50, $88, $88, $00 ; X
.db $88, $88, $50, $20, $20, $20, $20, $00 ; Y
.db $F8, $08, $10, $20, $40, $80, $F8, $00 ; Z

; DEC 123
.db $10, $20, $20, $40, $20, $20, $10, $00 ; {
.db $20, $20, $20, $20, $20, $20, $20, $00 ; |
.db $40, $20, $20, $10, $20, $20, $40, $00 ; }
.db $00, $00, $50, $A0, $00, $00, $00, $00 ; ~
.db $00, $00, $00, $00, $00, $00, $00, $00 ; DEL
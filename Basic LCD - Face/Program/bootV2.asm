; Diego Cruz - Nov 2022
; 
; bootV2: 
;         - CPU Z80@4Mhz
;         - Lcd Grafico 128x64
;         - Keyboard 40 keys + Shift
;         - Ram 32k
;         - Rom 32k
;
;         - Ports:
;               - Keyboard: 40H
;               - Display:  70H (LCDCTRL), 71H (LCDDATA)
;               - User IN/OUT: C0H
;
; -----------------------------------------------------------------------------
LCDCTRL	    .EQU    70H
LCDDATA     .EQU    71H
KEY_IN      .EQU    40H
KEY_OUT     .EQU    40H

CTRLC       .EQU    03H             ; Control "C"
CTRLG       .EQU    07H             ; Control "G"
BKSP        .EQU    08H             ; Back space
LF          .EQU    0AH             ; Line feed
VT          .equ    0BH             ; 
CS          .EQU    0CH             ; Clear screen
CR          .EQU    0DH             ; Carriage return [Enter]
CTRLO       .EQU    0FH             ; Control "O"
CTRLQ	    .EQU	11H		        ; Control "Q"
CTRLR       .EQU    12H             ; Control "R"
CTRLS       .EQU    13H             ; Control "S"
CTRLU       .EQU    15H             ; Control "U"
ESC         .EQU    1BH             ; Escape
DEL         .EQU    7FH             ; Delete

BASIC       .EQU    $6000           ; inicio basic 6000H, workspace 9000H
;
; BAUD RATE CONSTANTS
;
B300:	.EQU	0220H	;300 BAUD
B1200:	.EQU	0080H	;1200 BAUD
B2400:	.EQU	003FH	;2400 BAUD
B4800:	.EQU	001BH	;4800 BAUD
B9600:	.EQU	000BH	;9600 BAUD

BAUD:	 .EQU	0FFC0H	 ;BAUD RATE
PUTCH:   .EQU   0FFAAH   ;OUTPUT A CHARACTER TO SERIAL
GETCH:   .EQU   0FFACH   ;WAIT FOR A CHARACTER FROM SERIAL

SERIAL_RX_PORT:          .EQU $C0             ; Serial RX port - bit7
SERIAL_TX_PORT:          .EQU $C0             ; Serial TX Port - bit6


; LCD TEXT MODE
LCD_LINE1   .EQU    80H
LCD_LINE2   .EQU    90H
LCD_LINE3   .EQU    88H
LCD_LINE4   .EQU    98H


; RAM MAP



LCD_CHAR            .EQU    $8000   ; 1 byte char ex: 'A'
LCD_CHAR_POINT      .EQU    $8001   ; 2 bytes ponteiro para o mapa de caracteres
LCD_TXT_X           .EQU    $8003   ; 1 byte  0-20 (21 col)
LCD_TXT_Y           .EQU    $8004   ; 1 byte  0-7  (8 row)
LCD_BYTE_INDEX      .EQU    $8005   ; 2 bytes pointer pixel(8)
LCD_BIT_INDEX       .EQU    $8007   ; 1 byte pointer pixel(1)
LCD_TXT_X_TMP       .EQU    $8008   ; 2 bytes = LCD_TXT_X * 6
LCD_TXT_Y_TMP       .EQU    $800A   ; 2 bytes = LCD_TXT_Y * 128
LCD_CHAR_H          .EQU    $800C   ; 1 byte altura do char
LCD_CHAR_W          .EQU    $800D   ; 1 byte largura do char
LCD_TMP_POINT       .EQU    $800E   ; 2 bytes ponteiro do pixel altural do print
LCD_DELETE_CHAR     .EQU    $800F   ; 1 byte, 0 não, ff delete proximo char
LCD_AUTO_X          .EQU    $8010   ; 1 byte, 0 sim, ff nao

DISPLAY             .EQU    $8500

LCD_TEMP        .EQU    $8110
LCD_COOX        .EQU    $8102 ; 1 byte, local onde vai printar
LCD_COOY        .EQU    $8103 ; 1 byte
LCD_PRINT_H     .EQU    $8104 ; 1 byte, tamanho do que vai printar
LCD_PRINT_W     .EQU    $8105 ; 1 byte
LCD_PRINT_IMAGE .EQU    $8106 ; 2 bytes


        .ORG 0
RST00	DI
        JP  INICIO
						
        .ORG     0008H
RST08   JP  PRINTCHAR

        .ORG 0010H
RST10   JP KEYREADINIT

        .ORG 0018H ; check break
RST18   ;LD	A, 0
        ;CP	0
        ;RET
	JP CHKKEY

KEYMAP:
.BYTE   "1234567890"
.BYTE   "QWERTYUIOP"
.BYTE   "ASDFGHJKL", CR
.BYTE   CTRLC, "ZXCVBNM ", DEL

SHIFTKEYMAP:
.BYTE   "!@#$%^&*()"
.BYTE   "`~-_=+;:'"
.BYTE   22h
.BYTE   "{}[]|",$5C,"<>?/"
.BYTE   CTRLC, ",.     ", VT, LF











; -----------------------------------------------------------------------------
;   INICIO
; -----------------------------------------------------------------------------
INICIO:
    LD  SP, $8FFF

    ; init serial
    CALL  DELONE     ;WAIT A SEC SO THE HOST SEES TX HIGH  
    LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE
    
    LD	HL,B4800
	LD	(BAUD),HL	;DEFAULT SERIAL=9600 BAUD

    LD HL, WELLCOME
    CALL SNDMSG

    ; CALL INCH
    ; CALL OUTCH

    ; Init LCD hardware
    CALL INIT_LCD
    call delay

    call cls_TXT
    call delay

    CALL enable_grafic
    call delay

    call cls_GRAPHIC
    call delay

    call lcd_clear

    ld hl, DISPLAY
    call print_image

    call delay

    ; Init LCD logical
    call INIT_TXT_LCD ; set cursor X Y to 0

    LD HL, MGS_INIT_BASIC
    CALL SNDMSG

    JP BASIC

KEY:
    ;CALL KEYREADINIT
    ;CALL PRINTCHAR
    JP  KEY



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


; char in A
PRINTCHAR:
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

                ;call    shift_lcd_up
                ;call    show_lcd_screen

                LD A,0
                LD (LCD_TXT_X), A ; ajusta X para o inicio da linha

                LD A, (LCD_TXT_Y)
                inc a
                cp 8
                jp nz, ver_enter_incYOK
                
                CALL DISPLAY_SCROLL_UP
                ld hl, DISPLAY
                CALL print_image
                
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
                ld hl, DISPLAY
                call print_image
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

    ld hl, DISPLAY
    call print_image


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
    ld a, 0
    ld (LCD_TXT_X), a
    ld (LCD_TXT_Y), a
    jp print_char_fim

incYOK:
    ld (LCD_TXT_Y), a
    jp print_char_fim

incXOK:
    ld (LCD_TXT_X), a

print_char_fim:
    POP HL
    POP DE
    POP BC
    POP AF
    RET
;-------- FIM PRINTCHAR ------------------



; ----------------------------------

; INPUT: THE VALUES IN REGISTER B EN C
; OUTPUT: HL = B * C
; CHANGES: AF,DE,HL,B
;
multiplication:
	LD HL,0
	LD A,B
	OR A
	RET Z
	LD D,0
	LD E,C
multiplicationLOOP:	ADD HL,DE
	DJNZ multiplicationLOOP
	RET 

;-----------------------------------

Div_HL_D:
;Inputs:
;   HL and D
;Outputs:
;   HL is the quotient (HL/D)
;   A is the remainder
;   B is 0
;   C,D,E are preserved
    xor a         ; Clear upper eight bits of AHL
    ld b,16       ; Sixteen bits in dividend
_loop:
    add hl,hl     ; Do a "SLA HL". If the upper bit was 1, the c flag is set
    rla           ; This moves the upper bits of the dividend into A
    jr c,_overflow; If D is allowed to be >128, then it is possible for A to overflow here. (Yes future Zeda, 128 is "safe.")
    cp d          ; Check if we can subtract the divisor
    jr c,_skip    ; Carry means A < D
_overflow:
    sub d         ; Do subtraction for real this time
    inc l         ; Set the next bit of the quotient (currently bit 0)
_skip:
    djnz _loop
    ret


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
	call lcd_send_command

	ld a, 02H
	call lcd_send_command
    RET


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

print_image:						; LOAD 128*64 bits (16*8 Byte) of data into the LCD screen
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
	call lcd_send_command		; CLEAR DISPLAY	
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
	
lcd_command_wait_loop:	;Busy wait
	call delayLCD
	
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
	ld c, LCDCTRL	    ;Command port
	
    ;Busy wait
	call delayLCD
	
	ld c, LCDDATA	;Data port
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
	NOP ; KO
	NOP
    NOP
    ret

	
; =========================================================
; Delay
; =========================================================
delay:
	push bc                       ; 2.75 us
    ld b, 255                     ; 1.75 us
delay_loop_b:
	ld c, 255                     ; 1.75 us
delay_loop:
	dec c                         ; 1 us
    jp nz, delay_loop             ; true = 3 us, false 1.75 us
    dec b                         ; 1 us
    jp nz, delay_loop_b           ; true = 3 us, false 1.75 us
    pop bc                        ; 2.50 us
    ret   


; Check break key
CHKKEY: LD  A, $40
	OUT (KEY_OUT), A ; line 4
	IN  A, (KEY_IN)
	CP  1
	JP  NZ, GRET
	LD  A, CTRLC
	CP	0
	RET
GRET:
	LD  A, 0
	CP 0
	RET




; -----------------------------------------------------------------------------
;   KEYREAD - KEY In A
; -----------------------------------------------------------------------------
KEYREADINIT:
    PUSH    BC
	PUSH	DE
	PUSH    HL
	LD      E, 0                    ; E will be the last pressed key
READKEY:        
    LD      H, 1                    ; H is the line register, start with second
	LD      B, 0                    ; Count lines for later multiplication	
	LD      D, 0                    ; DE will be the adress for mask
						
NEXTKEY:        
    LD      A, H						
    CP      0                       ; All lines tried? 
    JP      Z, KEYOUT               ; Then check if there was a key pressed
	OUT     (KEY_OUT), A		    ; Put current line to register
	IN      A, (KEY_IN)		        ; Input Keys
	AND     $1F                     ; only 5 bits
	SLA     H                       ; Next line
    INC     B
    CP      0                       ; Was key zero?
    JP      Z, NEXTKEY              ; Then try again with next lines
    LD      D, 0                    ; In D will be the number of the key
LOGARITHM:      
    INC     D	                    ; Add one per shift
    SRL     A                       ; Shift key right
    JP      NZ, LOGARITHM		    ; If not zero shift again
    DEC     D                       ; Was too much
	IN      A, (KEY_IN)
    AND     $80                     ; Check if first bit set (shift key pressed)
    JP      NZ, LOADSHIFT		    ; Then jump to read with shift
    LD      A, D                    ; Put read key into accu
    ADD     A, KEYMAP               ; Add base of key map array
    JP      ADDOFFSET               ; Jump to load key
LOADSHIFT:
    LD      A, D
    ADD     A, SHIFTKEYMAP          ; In this case add the base for shift		
ADDOFFSET:
    ADD     A, 5                    ; Add 5 for every line
    DJNZ    ADDOFFSET               ; Jump back (do while loop)
	SUB     5                       ; Since do while is one too much
TRANSKEY:
    XOR     B                       ; Empty B
	LD      C, A                    ; A will be address in BC
	LD      A, (BC)	                ; Load key
	CP      E                       ; Same key?
	JP      Z, READKEY              ; Then from beginning
	LD      E, A                    ; Otherwise save new key
	JP      READKEY	                ; And restart
KEYOUT:
    LD      A, E
    LD      E, 0                    ; empty it
    OR      A	                    ; Was a key read?
    JP      Z, READKEY              ; If not restart
    POP     HL
    POP     DE
    POP     BC
    RET





;-----------------------------------------
; SEND AN ASCII STRING OUT THE SERIAL PORT
;-----------------------------------------
; 
; SENDS A ZERO TERMINATED STRING OR 
; 128 CHARACTERS MAX. OUT THE SERIAL PORT
;
;      ENTRY : HL = POINTER TO 00H TERMINATED STRING
;      EXIT  : NONE
;
;       MODIFIES : A,B,C
;          
SNDMSG: LD    B,128         ;128 CHARS MAX
SDMSG1: LD    A,(HL)        ;GET THE CHAR
       CP    00H          ;ZERO TERMINATOR?
       JR    Z,SDMSG2      ;FOUND A ZERO TERMINATOR, EXIT  
       CALL  OUTCH         ;TRANSMIT THE CHAR
       INC   HL
       DJNZ  SDMSG1        ;128 CHARS MAX!    
SDMSG2: RET



;-----------------------------------
; OUTPUT A CHARACTER TO THE TERMINAL
;-----------------------------------       
OUTCH:  LD   IX,(PUTCH)
       JP   (IX)
;------------------------------------
; INPUT A CHARACTER FROM THE TERMINAL
;------------------------------------
INCH:  LD   IX,(GETCH)
      JP   (IX)



;------------------------
; SERIAL TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TXDATA:	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD	HL,(BAUD)
	LD	C,A
;
; TRANSMIT START BIT
;
	XOR	A
	OUT	(SERIAL_TX_PORT),A
	CALL	BITIME
;
; TRANSMIT DATA
;
	LD	B,08H
	RRC	C
NXTBIT:	RRC	C	;SHIFT BITS TO D6,
	LD	A,C	;LSB FIRST AND OUTPUT
	AND	40H	;THEM FOR ONE BIT TIME.
	OUT	(SERIAL_TX_PORT),A
	CALL	BITIME
	DJNZ	NXTBIT
;
; SEND STOP BITS
;
	LD	A,40H
	OUT	(SERIAL_TX_PORT),A
	CALL	BITIME
	CALL	BITIME
	POP	HL
	POP	BC
	POP	AF
	RET
;-----------------------
; SERIAL RECEIVE ROUTINE
;-----------------------
;RECEIVE SERIAL BYTE FROM DIN
;
; ENTRY : NONE
;  EXIT : A= RECEIVED BYTE IF CARRY CLEAR
;
; REGISTERS MODIFIED A AND F
;
RXDATA:	PUSH	BC
	PUSH	HL
;
; WAIT FOR START BIT 
;
RXDAT1: IN	A,(SERIAL_RX_PORT)
	    BIT	7,A
	    JR	NZ,RXDAT1	;NO START BIT
;
; DETECTED START BIT
;
	LD	HL,(BAUD)
	SRL	H
	RR	L 	;DELAY FOR HALF BIT TIME
	CALL 	BITIME
	IN	A,(SERIAL_RX_PORT)
	BIT	7,A
	JR	NZ,RXDAT1	;START BIT NOT VALID
;
; DETECTED VALID START BIT,READ IN DATA
;
	LD	B,08H
RXDAT2:	LD	HL,(BAUD)
	CALL	BITIME	;DELAY ONE BIT TIME
	IN	A,(SERIAL_RX_PORT)
	RL	A
	RR	C	;SHIFT BIT INTO DATA REG
	DJNZ	RXDAT2
	LD	A,C
	OR	A	;CLEAR CARRY FLAG
    POP	HL
	POP	BC
	RET
;---------------
; BIT TIME DELAY
;---------------
;DELAY FOR ONE SERIAL BIT TIME
;ENTRY : HL = DELAY TIME
; NO REGISTERS MODIFIED
;
BITIME:	PUSH	HL
	PUSH	DE
	LD	DE,0001H
BITIM1:	SBC	HL,DE
	JP	NC,BITIM1
	POP	DE
	POP	HL
	RET



;-----------------
; ONE SECOND DELAY
;-----------------
;
; ENTRY : NONE
; EXIT : FLAG REGISTER MODIFIED
;
DELONE:	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	DE,0001H
	LD	HL,0870H
DELON1:	LD	B,92H
DELON2:	DJNZ	DELON2	;INNER LOOP
	SBC	HL,DE
	JP	NC,DELON1	;OUTER LOOP
	POP	HL
	POP	DE
	POP	BC
	RET


WELLCOME: .db CR, CR, LF,"Z80 Mini Iniciado", CR, LF, 00H
MGS_INIT_BASIC: .db CR, CR, LF,"Iniciando MS Basic", CR, LF, 00H

.end

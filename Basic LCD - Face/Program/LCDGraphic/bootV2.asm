; Diego Cruz - Nov 2022
; 
; bootV2: 
;         - CPU Z80@4Mhz
;         - Lcd Grafico 128x64
;         - Keyboard 40 keys + Shift
;         - Rom 32k 0000h - 7FFFh
;         - Ram 32k 8000h - FFFFh
;         
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

KLEFT       .EQU    $B4             ; Key Left
KRIGHT      .EQU    $B7             ; Key Right
KUP         .EQU    $B5             ; Key Up
KDOWN       .EQU    $B6             ; Key Down
KF1         .EQU    $80             ; Key F1
KF2         .EQU    $81             ; Key F2
KF3         .EQU    $82             ; Key F3
KF4         .EQU    $83             ; Key F4
KF5         .EQU    $84             ; Key F5 (SHIFT)
KF6         .EQU    $85             ; Key F6 (SHIFT)
KF7         .EQU    $86             ; Key F7 (SHIFT)
KF8         .EQU    $87             ; Key F8 (SHIFT)

kCPUClock:  .EQU 4000000       ;CPU clock speed in Hz
kDelayOH:   .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:   .EQU 26             ;Inner loop time in Tcycles
kDelayTA:   .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:   .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:  .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop

BASIC       .EQU    $6000           ; inicio basic 6000H, workspace 9000H
;
; BAUD RATE CONSTANTS
;
B300:	.EQU	0220H	;300 BAUD
B1200:	.EQU	0080H	;1200 BAUD
B2400:	.EQU	003FH	;2400 BAUD
B4800:	.EQU	001BH	;4800 BAUD
B9600:	.EQU	000BH	;9600 BAUD

SYSTEM:	.EQU 	0F000H	;INITIAL STACK POINTER
I2CDATA .EQU    0D000H 

I2CA_BLOCK: .EQU $AE            ;I2C device addess: 24LC256 (Copy from/to Mem)
TIMEOUT:    .EQU 10000          ;Timeout loop counter

ADDR:       .EQU 0FEB0H   ;THE ADDRESS  2 bytes
ADDR_FROM   .EQU 0FEB2H   ;THE ADDRESS FROM  2 bytes
ADDR_TO     .EQU 0FEB4H   ;THE ADDRESS TO 2 bytes
ADDR_SIZE   .EQU 0FEB6H   ;THE ADDRESS SIZE 2 bytes
DATA:       .EQU 0FEB8H   ;THE DATA
MSGBUF:     .EQU 0FE00H   ;STRING HANDLING AREA

PORT_SET        .EQU 0FFB0H ; 1 byte - Define port (input/output) Default 0xC0(onboard)
PORT_OUT_VAL    .EQU 0FFB1H ; 1 byte - save value out port
LCD_DATA        .EQU 0FFB2H ; 1byte

I2C_ADDR        .EQU $FFC0 ; 1 byte - device address
I2C_RR          .EQU $FFC1 ; 1 byte - register
I2C_DD          .EQU $FFC2 ; 1 byte - data


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



LCD_CHAR            .EQU    $E000   ; 1 byte char ex: 'A'
LCD_CHAR_POINT      .EQU    $E001   ; 2 bytes ponteiro para o mapa de caracteres
LCD_TXT_X           .EQU    $E003   ; 1 byte  0-20 (21 col)
LCD_TXT_Y           .EQU    $E004   ; 1 byte  0-7  (8 row)
LCD_BYTE_INDEX      .EQU    $E005   ; 2 bytes pointer pixel(8)
LCD_BIT_INDEX       .EQU    $E007   ; 1 byte pointer pixel(1)
LCD_TXT_X_TMP       .EQU    $E008   ; 2 bytes = LCD_TXT_X * 6
LCD_TXT_Y_TMP       .EQU    $E00A   ; 2 bytes = LCD_TXT_Y * 128
LCD_CHAR_H          .EQU    $E00C   ; 1 byte altura do char
LCD_CHAR_W          .EQU    $E00D   ; 1 byte largura do char
LCD_TMP_POINT       .EQU    $E00E   ; 2 bytes ponteiro do pixel altural do print
LCD_DELETE_CHAR     .EQU    $E00F   ; 1 byte, 0 não, ff delete proximo char
LCD_AUTO_X          .EQU    $E010   ; 1 byte, 0 sim, ff nao

DISPLAY             .EQU    $E500   ; 1024 bytes

LCD_TEMP        .EQU    $E110
LCD_COOX        .EQU    $E102 ; 1 byte, local onde vai printar
LCD_COOY        .EQU    $E103 ; 1 byte
LCD_PRINT_H     .EQU    $E104 ; 1 byte, tamanho do que vai printar
LCD_PRINT_W     .EQU    $E105 ; 1 byte
LCD_PRINT_IMAGE .EQU    $E106 ; 2 bytes


        .ORG 0
RST00	DI
        JP  INICIO
						
        .ORG     0008H
RST08   JP  PRINTCHAR

        .ORG 0010H
RST10   JP KEYREADINIT

        .ORG 0018H ; check break
RST18   JP CHKKEY

        .ORG 0030H
RST30   JP APIHandler


KEYMAP:
.BYTE   "12345",KF1,"67890"
.BYTE   KF2,"QWERT",KF3,"YUIOP"
.BYTE   KF4,"ASDFG",KLEFT,"HJKL", CR
.BYTE   KDOWN,CTRLC, "ZXCV",KRIGHT,"BNM ", DEL, KUP

SHIFTKEYMAP:
.BYTE   "!@#$%",KF5,"^&*()"
.BYTE   KF6,"`~-_=",KF7,"+;:'" 
.BYTE 22h,
.BYTE   KF8,"{}[]|",KLEFT,$5C,"<>?", CR
.BYTE   KDOWN,ESC,"/,. ",KRIGHT,"    ", DEL, KUP




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





; -----------------------------------------------------------------------------
;   INICIO
; -----------------------------------------------------------------------------
INICIO:
    LD  SP, SYSTEM

    LD A, 0
    LD (PORT_OUT_VAL), A

    LD A, $c0
    LD (PORT_SET), A

    ; init serial
    CALL  DELONE     ;WAIT A SEC SO THE HOST SEES TX HIGH  
    LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE
    
    LD	HL,B4800
	LD	(BAUD),HL	;DEFAULT SERIAL=9600 BAUD

    LD A, $FF
    OUT (SERIAL_TX_PORT), A

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

    ;call lcd_clear

    ;ld hl, DISPLAY
    ;call print_image

    ;call delay
RESET_WARM:
    call lcd_clear

    ; Init LCD logical
    call INIT_TXT_LCD ; set cursor X Y to 0

    LD HL, MSG_MONITOR
    CALL SNDLCDMSG

    LD A, '>'
    CALL PRINTCHAR

KEY:
    CALL KEYREADINIT

    CP 'H'
    CALL Z, SHOWHELP

    CP KF1
    JP Z, $8000

    CP KF2
    JP Z, INTEL_HEX

    CP 'B'
    JP Z, BASIC

    CP 'G'
    CALL Z, GOJUMP

    CP 'M'
    CALL Z, MODIFY

    CP 'D'
    CALL Z, DSPLAY

    CP 'O'
    CALL Z, OUTPORT

    CP 'I'
    CALL Z, INPORT

    CP '1'
    CALL Z, I2CLIST

    CP '2'
    CALL Z, I2CCPUTOMEM

    CP '3'
    CALL Z, I2CMEMTOCPU

    CP '4'
    CALL Z, I2C_WR_DD

    CP '5'
    CALL Z, I2C_WR_RR_DD

    CP '6'
    CALL Z, I2C_RD

    CP '7'
    CALL Z, I2C_RD_RR

    







    LD A, CR 
    CALL PRINTCHAR
    LD A, '>' 
    CALL PRINTCHAR

    JP  KEY


; **********************************************************************
; **  API - Public functions                                          **
; **********************************************************************
; API: Main entry point
;   On entry: C = Function number
;             A, DE = Parameters (as specified by function)
;   On exit:  AF,BC,DE,HL = Return values (as specified by function)
;             IX IY I AF' BC' DE' HL' preserved
; This handler modifies: F, B, HL but preserves A, C, DE
; Other registers depend on API function called
APIHandler: LD   HL,APITable    ;Start of function address table
            LD   B,A            ;Preserve A
            LD   A,C            ;Get function number
            CP   kAPILast+1     ;Supported function?
            RET  NC             ;No, so abort
            LD   A,B            ;Restore A
            LD   B,0
            ADD  HL,BC          ;Calculate table pointer..
            ADD  HL,BC
            LD   B,(HL)         ;Read function address from table..
            INC  HL
            LD   H,(HL)
            LD   L,B
            JP   (HL)           ;Jump to function address


; API: Function address table (function in C)
; This table contains a list of addresses, one for each API function. 
; Each is the address of the subroutine for the relevant function.
APITable:   .DW  SysReset           ; 0x00 = System reset
            .DW  InputCharKey       ; 0x01 = Input character KeyboardOnboard (Char in A)
            .DW  OutLcdChar         ; 0x02 = Output character LCD (Char in A)
            .DW  OutLcdNewLine      ; 0x03 = Output new line LCD
            .DW  H_Delay            ; 0x04 = Delay in milliseconds
            .DW  PrtSet             ; 0x05 = Set Port (Default C0)
            .DW  PrtOWr             ; 0x06 = Write to output port
            .DW  PrtORd             ; 0x07 = Read from output port
            .DW  PrtIRd             ; 0x08 = Read from input port
            .DW  PrintBufferChar    ; 0x09 = Print char to display buffer, with out show LCD (Chat in A)
            .DW  DisplayImage128x64 ; 0x0A = Print image (Pointer in DE), 128x64, 1024 bytes
            .DW  ClearDisplayBuffer ; 0x0B = Clear display buffer (A=$00 without show LCD, A > $00 show to LCD)
            .DW  ShowBufferDisplay  ; 0x0C = Show DISPLAY buffer to LCD
            .DW  LcdSetCXY          ; 0x0D = LCD Cursor X (0-20), Y (0-7) value in D(X) E(Y)
            .DW  SysReset           ; 0x0E = Reserved
            .DW  SysReset           ; 0x0F = Reserved
            .DW  I2COpen            ; 0x10 = Start i2c (Device address in A)
            .DW  I2CClose           ; 0x11 = Close i2c 
            .DW  I2CRead            ; 0x12 = I2C Read
            .DW  I2CWrite           ; 0x13 = I2C Write
kAPILast:   .EQU $13                ;Last API function number







SysReset:
    JP INICIO

InputCharKey:
    JP KEYREADINIT

OutLcdChar:
    JP PRINTCHAR

OutLcdNewLine:
    LD A, CR
    JP PRINTCHAR

PrtSet:
    LD (PORT_SET), A ; define a porta padrão de entrada e saida
    RET

PrtOWr:
    LD B, A
    LD A, (PORT_SET)
    LD C, A
    LD A, B
    LD (PORT_OUT_VAL), A
    out (C), A
    RET

PrtORd: ; Return value from output port
    LD A, (PORT_OUT_VAL)
    RET

PrtIRd: ; Return value from input
    LD A, (PORT_SET)
    LD C, A
    in A, (C)
    RET

DisplayImage128x64:
    LD H, D
    LD L, E
    JP print_image

ClearDisplayBuffer:
    PUSH AF
    CALL lcd_clear
    POP AF
    OR A
    CP $00
    JP Z, ClearDisplayBufferEnd
    LD HL, DISPLAY
    JP print_image
ClearDisplayBufferEnd:
    RET

ShowBufferDisplay:
    LD HL, DISPLAY
    JP print_image

I2COpen:
    JP I2C_Open

I2CClose:
    JP I2C_Close

I2CRead:
    JP I2C_Read

I2CWrite:
    JP I2C_Write

LcdSetCXY:
    PUSH AF
    LD A, D
    LD (LCD_TXT_X), A

    LD A, E
    LD (LCD_TXT_Y), A
    POP AF
    RET






OUTPORT:
    LD A, 'O'
    CALL PrintBufferChar
    CALL OUTSP ; space and show lcd

    CALL  GETCHR 
    RET   C
    LD C, A

    CALL OUTSP

    CALL  GETCHR 
    RET   C
    OUT (C), A
    RET


INPORT:
    LD A, 'I'
    CALL PrintBufferChar
    CALL OUTSP ; space and show lcd

    CALL  GETCHR 
    RET   C
    LD C, A

    IN A, (C)

    LD B, A
    PUSH BC
    LD A, CR
    CALL PRINTCHAR
    POP BC
    LD A, B

    CALL CONV_A_HEX
    RET






;----------------
;CONVERT A TO ASCII (HEX) AND SHOW LCD
;----------------
;
;CONVERT A BYTE TO ASCII 
;
CONV_A_HEX: PUSH  AF          ;SAVE A FOR SECOND NYBBLE 
       RRCA              ;SHIFT HIGH NYBBLE ACROSS
       RRCA
       RRCA
       RRCA
       CALL CONV_A_HEX_NYBASC       ;CALL NYBBLE CONVERTER 
       POP AF            ;RESTORE LOW NYBBLE
;           
; CONVERT A NYBBLE TO ASCII
;
CONV_A_HEX_NYBASC: AND   0FH         ;MASK OFF HIGH NYBBLE 
       ADD   A,90H       ;CONVERT TO
       DAA               ;ASCII
       ADC   A,40H
       DAA
;            
; Print inlcd
;
    CALL PRINTCHAR
    RET 


; **********************************************************************
; Delay by DE milliseconds
;   On entry: DE = Delay time in milliseconds
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
H_Delay:    PUSH AF
            PUSH BC
            PUSH DE
; 1 ms loop, DE times...        ;[=36]   [=29]    Overhead for each 1ms
LoopDE:    LD   BC, kDelayCnt   ;[10]    [9]
; Inner loop, BC times...       ;[=26]   [=20]    Loop time in Tcycles
LoopBC:    DEC  BC             ;[6]     [4]
            LD   A,C            ;[4]     [4]
            OR   B              ;[4]     [4]
            JP   NZ,LoopBC     ;[12/7]  [8/6] 
; Have we looped once for each millisecond requested?
            DEC  DE             ;[6]     [4]
            LD   A,E            ;[4]     [4]
            OR   D              ;[4]     [4]
            JR   NZ, LoopDE     ;[12/7]  [8/6]
            POP  DE
            POP  BC
            POP  AF
            RET

;--------------------------
; D DISPLAY MEMORY LOCATION
;--------------------------
DSPLAY: LD A, 'D'
        CALL PRINTCHAR
        CALL  OUTSP       ;A SPACE
       CALL  GETCHR
       RET   C         
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; WAIT FOR CR OR ESC
;
DPLAY1: CALL  KEYREADINIT
       CP    ESC
       RET   Z
       CP    CR
       JR    NZ,DPLAY1          
       CALL  TXCRLF      ;NEWLINE
;
; DISPLAY THE LINE
;
DPLAY2: CALL  DPLINE
       LD    (ADDR),DE   ;SAVE THE NEW ADDRESS
;
; DISPLAY MORE LINES OR EXIT
;       
DPLAY3: CALL  KEYREADINIT
       JR    C,DPLAY3   
       CP    CR        ;ENTER DISPLAYS THE NEXT LINE
       JR    Z,DPLAY2
       CP    ESC         ;ESC EXITS (SHIFT + C)
       JR    NZ,DPLAY3     
       RET   
;-------------------------
; DISPLAY A LINE OF MEMORY
;-------------------------      
DPLINE: LD    DE,(ADDR)   ;ADDRESS TO BE DISPLAYED
       LD    HL,MSGBUF   ;HL POINTS TO WHERE THE OUTPUT STRING GOES
;
; DISPLAY THE ADDRESS
;         
       CALL  WRDASC     ;CONVERT ADDRESS IN DE TO ASCII
       CALL  SPCBUF        
;
; DISPLAY 4 BYTES
;
       LD    B,4 ;16
DLINE1: LD    A,(DE)
       CALL  BYTASC
       CALL  SPCBUF
       INC   DE        
       DJNZ  DLINE1
       ;CALL  SPCBUF
;
; NOW DISPLAY THE ASCII CHARACTER
; IF YOU ARE DISPLAYING NON-MEMORY AREAS THE BYTES READ AND THE ASCII COULD
; BE DIFFERENT BETWEEN THE TWO PASSES!
;
       LD    DE,(ADDR)    
       LD    B,4 ;16
DLINE2: LD    A,(DE)   
       CP    20H
       JR    C,DOT
       CP    7FH
       JR    NC,DOT
       JP    NDOT
DOT:    LD    A,'.'
NDOT:   CALL  INBUF
       INC   DE       
       DJNZ  DLINE2
;         
;TERMINATE AND DISPLAY STRING
;       
       CALL  BCRLF
       LD    A,00H
       LD    (HL),A
       LD    HL,MSGBUF
       CALL  SNDLCDMSG
       RET


;
; PUT A SPACE IN THE BUFFER
;
SPCBUF: LD    A, 8 ;20H(32dec)
INBUF:  LD    (HL),A
       INC   HL
       RET
;
; PUT A CR LF IN THE BUFFER
;        
BCRLF:  ;LD    A,CR  
       ;CALL  INBUF  ;Display add CR automaticamente quando chegar na coluna 21
       RET



; --------------------------------------
; I2C - Write one byte
; --------------------------------------
I2C_WR_DD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_WR_DD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_WR_DD_LOOP:
    ; Get Data
    CALL GET_DEV_DD   ; get data

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_DD)  ; Data
    CALL I2C_Write
 
    CALL I2C_Close  ; Close

    JR I2C_WR_DD_LOOP

    RET



; --------------------------------------
; I2C - Write register one byte
; --------------------------------------
I2C_WR_RR_DD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_WR_RR_DD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_WR_RR_DD_LOOP:
    ; Get register
    CALL GET_DEV_RR ; get address

    ; Get Data
    CALL GET_DEV_DD   ; get data

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_RR)  ; register
    CALL I2C_Write

    LD A, (I2C_DD)  ; Data
    CALL I2C_Write

    CALL I2C_Close  ; Close

    JR I2C_WR_RR_DD_LOOP

    RET


; --------------------------------------
; I2C - Read one byte
; --------------------------------------
I2C_RD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_RD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address
    CALL TXCRLF ; new line

I2C_RD_LOOP:
    ; Send
    LD A, (I2C_ADDR) ; Open
    INC A ; To read address + 1 (flag)
    CALL I2C_Open

    CALL I2C_Read      ; Read
    PUSH AF

    CALL I2C_Close     ; Close

    ; Show
    POP AF
    CALL CONV_A_HEX ; Show A to (HEX) LCD
    CALL TXCRLF ; new line

    CALL KEYREADINIT
    CP CTRLC
    JP Z, RESET_WARM

    JR I2C_RD_LOOP
    RET


; --------------------------------------
; I2C - Read register one byte
; --------------------------------------
I2C_RD_RR:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_RD_RR
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_RD_RR_LOOP:
    ; Get register
    CALL GET_DEV_RR ; get address
    CALL TXCRLF ; new line

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_RR)
    CALL I2C_Write ; Register to read

    LD A, (I2C_ADDR) ; Open
    INC A ; To read address + 1 (flag)
    CALL I2C_Open

    CALL I2C_Read ; Read register
    PUSH AF

    CALL I2C_Close ; Close

    ; Show
    POP AF
    CALL CONV_A_HEX ; Show A to (HEX) LCD

    JR I2C_RD_RR_LOOP
    RET


GET_DEV_ADDR:
    LD HL, MSG_DEV_ADDR
    CALL SNDLCDMSG
    CALL  GETCHR 
    RET   C
    LD (I2C_ADDR), A
    RET

GET_DEV_DD:
    LD HL, MSG_DEV_DATA
    CALL SNDLCDMSG

    CALL  GETCHR 
    RET   C
    LD (I2C_DD), A
    RET

GET_DEV_RR:
    LD HL, MSG_DEV_REG
    CALL SNDLCDMSG

    CALL  GETCHR 
    RET   C
    LD (I2C_RR), A
    RET




I2CMEMTOCPU:
    ; Get parameters to copy a block from I2C memory to CPU memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved

    LD HL, MSG_MEM2CPU
    CALL SNDLCDMSG

    CALL GET_FROM_TO_SIZE

;    DE = First address in I2C memory
;    HL = First address in CPU memory
;    BC = Number of bytes to be copied

    LD DE, (ADDR_FROM)
    LD HL, (ADDR_TO)
    LD BC, (ADDR_SIZE)
    CALL I2C_MemRd  

    JP Z, I2CMEMTOCPU_OK
    LD HL, MSG_COPYFAIL
    CALL SNDLCDMSG
    RET
I2CMEMTOCPU_OK:
    LD HL, MSG_COPYOK
    CALL SNDLCDMSG
    RET


I2CCPUTOMEM:
; Get parameters to copy a block from CPU memory to I2C memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
; The 24LC64 requires blocks of data to be written in 64 byte (or less)
; pages.
    LD HL, MSG_CPU2MEM
    CALL SNDLCDMSG

    CALL GET_FROM_TO_SIZE

;    DE = First address in I2C memory
;    HL = First address in CPU memory
;    BC = Number of bytes to be copied

    LD HL, (ADDR_FROM)
    LD DE, (ADDR_TO)
    LD BC, (ADDR_SIZE)
    CALL I2C_MemWr
    
    JP Z, I2CCPUTOMEM_OK
    LD HL, MSG_COPYFAIL
    CALL SNDLCDMSG
    RET
I2CCPUTOMEM_OK:
    LD HL, MSG_COPYOK
    CALL SNDLCDMSG
    RET






GET_FROM_TO_SIZE:
    ; FROM
    LD HL, MSG_FROM
    CALL SNDLCDMSG
    ;
    ;GET THE ADDRESS  FROM
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_FROM+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_FROM),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR Z, GET_FROM_TO_SIZE_TO
    LD A, CR
    CALL PRINTCHAR
    JP GET_FROM_TO_SIZE

GET_FROM_TO_SIZE_TO:
    ; TO
    LD HL, MSG_TO
    CALL SNDLCDMSG
    ;
    ;GET THE ADDRESS  TO
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_TO+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_TO),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR NZ, GET_FROM_TO_SIZE_TO

GET_FROM_TO_SIZE_SIZE:
    ; SIZE
    LD HL, MSG_SIZE
    CALL SNDLCDMSG
    ;
    ;GET THE SIZE
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_SIZE+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_SIZE),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR NZ, GET_FROM_TO_SIZE_SIZE
    RET


INTEL_HEX:
    CALL INTHEX
    CALL delay
    CALL delay
    JP INICIO

SHOWHELP:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    LD HL, MSG_MENU0
    CALL SNDLCDMSG

    LD HL, MSG_MENU1
    CALL SNDLCDMSG

    LD HL, MSG_MENU2
    CALL SNDLCDMSG

    LD HL, MSG_MENU3
    CALL SNDLCDMSG

    LD HL, MSG_MENU4
    CALL SNDLCDMSG

    LD HL, MSG_MENU5
    CALL SNDLCDMSG

    LD HL, MSG_MENU6
    CALL SNDLCDMSG

    LD HL, MSG_MENU7
    CALL SNDLCDMSG

    LD HL, MSG_MENU8
    CALL SNDLCDMSG

    LD HL, MSG_MENU9
    CALL SNDLCDMSG

    LD HL, MSG_MENU10
    CALL SNDLCDMSG

    LD HL, MSG_MENU11
    CALL SNDLCDMSG

    LD HL, MSG_MENU12
    CALL SNDLCDMSG

    LD HL, MSG_MENU13
    CALL SNDLCDMSG

    LD HL, MSG_MENU14
    CALL SNDLCDMSG

    RET


;----------------------------
; M DISPLAY AND MODIFY MEMORY
;----------------------------
MODIFY: LD A, 'M'
        CALL PRINTCHAR
     CALL  OUTSP
;
;GET THE ADDRESS        
;
       CALL  GETCHR 
       RET   C        
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; DISPLAY ON A NEW LINE
;       
MDIFY1: CALL  TXCRLF       
       LD    DE,(ADDR)    
       LD    HL,MSGBUF   
       CALL  WRDASC      ;CONVERT ADDRESS IN DE TO ASCII
       LD    HL,MSGBUF
       CALL  WRDOUT      ;OUTPUT THE ADDRESS
       CALL  OUTSP    
;      
;GET THE DATA AT THE ADDRESS        
;
        LD   HL,(ADDR)       
        LD   A,(HL)
;
; DISPLAY THE DATA
;        
       LD    HL,MSGBUF
       CALL  BYTASC     ;CONVERT THE DATA BYTE IN A TO ASCII
       LD    HL,MSGBUF
       CALL  BYTOUT      ;OUTPUT THE BYTE
       CALL  OUTSP
;
; GET NEW DATA,EXIT OR CONTINUE
;
       CALL  GETCHR
       RET   C
       LD    B,A         ;SAVE IT FOR LATER
       LD    HL,(ADDR)
       LD    (HL),A      ;PUT THE BYTE AT THE CURRENT ADDRESS
       LD    A,B
       CP    (HL)
       JR    Z,MDIFY2
       LD    A,'?'
       CALL  PRINTCHAR       ;NOT THE SAME DATA, PROBABLY NO RAM THERE      
;
; INCREMENT THE ADDRESS
;
MDIFY2: INC   HL
       LD    (ADDR),HL
       JP    MDIFY1



;------------------------------
; GO <ADDR>
; TRANSFERS EXECUTION TO <ADDR>
;------------------------------
GOJUMP_new:
    LD A, CR
    CALL PRINTCHAR

    LD A, '>'
    CALL PRINTCHAR

GOJUMP: LD A, 'G'
        CALL PRINTCHAR
       CALL  OUTSP       
       CALL  GETCHR      ;GET ADDRESS HIGH BYTE
       RET   C
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR      ;GET ADDRESS LOW BYTE
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; WAIT FOR A CR OR ESC
;       
GOJMP1: CALL  KEYREADINIT
       CP    ESC         ;ESC KEY?
       RET   Z
       CP    CR
       ;JR    NZ,GOJMP1
       JR NZ, GOJUMP_new
       CALL  TXCRLF
       POP   HL          ;POP THE UNUSED MENU RETURN ADDRESS FROM THE STACK
       LD    HL,(ADDR)
       JP    (HL)        ;GOOD LUCK WITH THAT!


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

;-----------------------------
; GET A BYTE FROM THE TERMINAL
;-----------------------------
GETCHR: CALL KEYREADINIT ; read key
       CP    ESC
       JR    Z,GETOUT
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A                ;SAVE TO ECHO      
       CALL  ASC2HEX
       JR    NC,GETCHR          ;REJECT NON HEX CHARS    
       LD    HL,DATA
       LD    (HL),A 
       LD    A,B         
       CALL  PRINTCHAR             ;ECHO VALID HEX
       
GETNYB: CALL  KEYREADINIT
       CP    ESC
       JR    Z,GETOUT
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A               ;SAVE TO ECHO
       CALL  ASC2HEX
       JR    NC,GETNYB         ;REJECT NON HEX CHARS
       RLD
       LD    A,B
       CALL  PRINTCHAR             ;ECHO VALID HEX
       LD    A,(HL)
       CALL  GETOUT            ;MAKE SURE WE CLEAR THE CARRY BY SETTING IT,
       CCF                    ;AND THEN COMPLEMENTING IT
       RET   
GETOUT: SCF                    ;SET THE CARRY FLAG TO EXIT BACK TO MENU
       RET


;----------------------------------------
; CONVERT ASCII CHARACTER INTO HEX NYBBLE
;----------------------------------------
; THIS ROUTINE IS FOR MASKING OUT KEYBOARD
; ENTRY OTHER THAN HEXADECIMAL KEYS
;
;CONVERTS ASCII 0-9,A-F INTO HEX LSN
;ENTRY : A= ASCII 0-9,A-F
;EXIT  : CARRY =  1
;          A= HEX 0-F IN LSN    
;      : CARRY = 0
;          A= OUT OF RANGE CHARACTER & 7FH
; A AND F REGISTERS MODIFIED
;
ASC2HEX: AND   7FH        ;STRIP OUT PARITY
       CP    30H
       JR    C,AC2HEX3    ;LESS THAN 0
       CP    3AH
       JR    NC,AC2HEX2   ;MORE THAN 9
AC2HEX1: SCF               ;SET THE CARRY - IS HEX
       RET
;     
AC2HEX2: CP    41H
       JR    C,AC2HEX3    ;LESS THAN A
       CP    47H
       JR    NC,AC2HEX3   ;MORE THAN F
       SUB   07H        ;CONVERT TO NYBBLE
       JR    AC2HEX1  
AC2HEX3: AND   0FFH        ;RESET THE CARRY - NOT HEX
       RET


;----------------------     
; SEND ASCII HEX VALUES        
;----------------------
;
; OUTPUT THE 4 BYTE, WRDOUT
; THE 2 BYTE, BYTOUT
; OR THE SINGLE BYTE, NYBOUT
; ASCII STRING AT HL TO THE SERIAL PORT
;
WRDOUT: CALL  BYTOUT
BYTOUT: CALL  NYBOUT
NYBOUT: LD    A,(HL)
       CALL  PRINTCHAR
       INC   HL
       RET       
;----------------
;CONVERT TO ASCII 
;----------------
;
; CONVERT A WORD,A BYTE OR A NYBBLE TO ASCII
;
;         ENTRY :  A = BINARY TO CONVERT
;                  HL = CHARACTER BUFFER ADDRESS   
;        EXIT   :  HL = POINTS TO LAST CHARACTER+1
;   
;        MODIFIES : DE

WRDASC: LD    A,D         ;CONVERT AND
       CALL  BYTASC      ;OUTPUT D
       LD    A,E         ;THEN E
;
;CONVERT A BYTE TO ASCII 
;
BYTASC: PUSH  AF          ;SAVE A FOR SECOND NYBBLE 
       RRCA              ;SHIFT HIGH NYBBLE ACROSS
       RRCA
       RRCA
       RRCA
       CALL NYBASC       ;CALL NYBBLE CONVERTER 
       POP AF            ;RESTORE LOW NYBBLE

;           
; CONVERT A NYBBLE TO ASCII
;
NYBASC: AND   0FH         ;MASK OFF HIGH NYBBLE 
       ADD   A,90H       ;CONVERT TO
       DAA               ;ASCII
       ADC   A,40H
       DAA
;            
; SAVE IN STRING
;
INSBUF: LD    (HL),A
       INC   HL 
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
	call lcd_send_command_clear ;; clear

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
	AND     $3F                     ; only 6 bits
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
    ADD     A, 6                    ; Add 6 for every line
    DJNZ    ADDOFFSET               ; Jump back (do while loop)
	SUB     6                       ; Since do while is one too much
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


;-----------------------
; RECEIVE INTEL HEX FILE
;-----------------------       
INTHEX: 
       LD HL, MSG_ILOAD
       CALL  SNDLCDMSG

       LD HL, MSG_ILOAD
       CALL  SNDMSG
       

       CALL  INTELH
       JR    NZ,ITHEX1      

       LD    HL,FILEOK
       CALL  SNDLCDMSG   ;GOT FILE OK LCD
       LD    HL,FILEOK
       CALL  SNDMSG      ;GOT FILE OK Serial
       
       RET
ITHEX1: LD    HL,CSUMERR
       CALL  SNDLCDMSG

       LD    HL,CSUMERR
       CALL  SNDMSG      ;CHECKSUM ERROR
       
       RET  





;-----------------------
; RECEIVE INTEL HEX FILE
;-----------------------
INTELH:	LD	IX,SYSTEM	;POINT TO SYSTEM VARIABLES
;
; WAIT FOR RECORD MARK
;
INTEL1:	XOR	A
	LD	(IX+3),A	;CLEAR CHECKSUM
	CALL	RXDATA	;WAIT FOR THE RECORD MARK
	CP	':'	;TO BE TRANSMITTED
	JR	NZ,INTEL1	;NOT RECORD MARK
;
; GET RECORD LENGTH
;
	CALL	GETBYT
	LD	(IX+0),A	;NUMBER OF DATA BYTES
;
; GET ADDRESS FIELD
;
	CALL	GETBYT
	LD	(IX+2),A	;LOAD ADDRESS HIGH BYTE
	CALL	GETBYT
	LD	(IX+1),A	;LOAD ADDRESS LOW BYTE
;
; GET RECORD TYPE
;
	CALL	GETBYT
	JR	NZ,INTEL4	;END OF FILE RECORD
;
; READ IN THE DATA
;
	LD	B,(IX+0)	;NUMBER OF DATA BYTES
	LD	H,(IX+2)	;LOAD ADDRESS HIGH BYTE
	LD	L,(IX+1)	;LOAD ADDRESS LOW BYTE

INTEL2:	CALL	GETBYT	;GET DATA BYTE
	LD	(HL),A	;STORE DATA BYTE
	INC	HL
	DJNZ	INTEL2	;LOAD MORE BYTES
;
; GET CHECKSUM AND COMPARE
;
	LD	A,(IX+3)	;CONVERT CHECKSUM TO
	NEG		;TWO'S COMPLEMENT
	LD	(IX+4),A	;SAVE COMPUTED CHECKSUM
	CALL	GETBYT
	LD	(IX+3),A	;SAVE RECORD CHECKSUM
	CP	(IX+4)	;COMPARE CHECKSUM
	JR	Z,INTEL1	;CHECKSUM OK,NEXT RECORD
    RET             ;NZ=CHECKSUM ERROR
;
; END OF FILE RECORD
;
INTEL4:	LD	A,(IX+3)	;CONVERT CHECKSUM TO
	NEG		;TWO'S COMPLEMENT
	LD	(IX+4),A	;SAVE COMPUTED CHECKSUM
	CALL	GETBYT
	LD	(IX+3),A	;SAVE EOF CHECKSUM
	CP	(IX+4)	;COMPARE CHECKSUM
	RET  	    ;NZ=CHECKSUM ERROR
;--------------------------
; GET BYTE FROM SERIAL PORT
;--------------------------
GETBYT:	PUSH	BC
	CALL	RXDATA
	BIT	6,A
	JR	Z,GETBT1
	ADD	A,09H
GETBT1:	AND	0FH
	SLA 	A
	SLA	A
	SLA	A
	SLA	A
	LD	C,A
;
; GET LOW NYBBLE
;
	CALL	RXDATA
	BIT	6,A
	JR	Z,GETBT2
	ADD	A,09H
GETBT2:	AND	0FH
	OR	C
	LD	B,A
	ADD	A,(IX+3)
	LD	(IX+3),A	;ADD TO CHECKSUM
	LD	A,B
	AND	A	;CLEAR CARRY
    POP	BC
	RET

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







; **********************************************************************
; List devices found on the I2C bus
;
; Test each I2C device address and reports any that acknowledge

I2CLIST:       LD   DE,LISTMsg        ;Address of message string
            CALL StrOut         ;Output string
            LD   D,0            ;First I2C device address to test
LISTLOOP:      PUSH DE             ;Preserve DE
            LD   A,D            ;Get device address to be tested
            CALL LISTTEST          ;Test if device is present
            POP  DE             ;Restore DE
            JR   NZ,LISTNEXT       ;Skip if no acknowledge
            LD   A,D            ;Get address of device tested
            CALL HexOut         ;Output as two character hex 
            CALL SpaceOut       ;Output space character
LISTNEXT:      INC  D              ;Get next write address
            INC  D
            LD   A,D            ;Address of next device to test
            OR   A              ;Have we tested all addresses?
            JR   NZ,LISTLOOP       ;No, so loop again
            CALL LineOut        ;Output new line
            RET

; Test if device at I2C address A acknowledges
;   On entry: A = I2C device address (8-bit, bit 0 = lo for write)
;   On exit:  Z flagged if device acknowledges
;             NZ flagged if devices does not acknowledge
LISTTEST:      CALL I2C_Open       ;Open I2C device for write
            RET  NZ             ;Abort if failed to open
            CALL I2C_Close      ;Close I2C device 
            XOR  A              ;Return with Z flagged
            RET




; Copy a block from I2C memory to CPU memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
I2C_MemRd:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
I2C_MemRdRepeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,I2C_MemRdReady       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,I2C_MemRdRepeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
I2C_MemRdReady:     POP  BC             ;Restore byte counter
            LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,I2CA_BLOCK+1 ;I2C device to be read from
            CALL I2C_Open       ;Open for read
            RET  NZ             ;Abort if error
I2C_MemRdRead:      DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Last byte to be read?
            CALL I2C_Read       ;Read byte with no ack on last byte
            LD   (HL),A         ;Write byte in CPU memory
            INC  HL             ;Increment CPU memory pointer
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,I2C_MemRdRead       ;No, so go read next byte
            CALL I2C_Stop       ;Generate I2C stop
            XOR  A              ;Return with success (Z flagged)
            RET


; Copy a block from CPU memory to I2C memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
; The 24LC64 requires blocks of data to be written in 64 byte (or less)
; pages.
I2C_MemWr:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
I2C_MemWrRepeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,I2C_MemWrReady       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,I2C_MemWrRepeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
I2C_MemWrReady:     POP  BC             ;Restore byte counter
I2C_MemWrBlock:     LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
I2C_MemWrWrite:     LD   A,(HL)         ;Get data byte from CPU memory
            CALL I2C_Write      ;Read byte from I2C memory
            INC  HL             ;Increment CPU memory pointer
            INC  DE             ;Increment I2C memory pointer
            DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Finished?
            JR   Z,I2C_MemWrStore       ;Yes, so go store this page
            LD   A,E            ;Get address in I2C memory (lo byte)
            AND  63             ;64 byte page boundary?
            JR   NZ,I2C_MemWrWrite      ;No, so go write another byte
I2C_MemWrStore:     CALL I2C_Stop       ;Generate I2C stop
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,I2C_MemWr   ;No, so go write some more
            RET   










; Display test result
;   On entry: DE = Address of null terminated string
;             H = First value ($H)
;             L = Second value ($L)
;   On exit:  HL IX IY preserved
Result:     
            JP   String         ;Output result string to console


; Character output to console
;   On entry: A = Character to be output
;   On exit:  BC DE HL IX IY preserved
CharOut:    JP   API_Cout

; New line output to console
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved
LineOut:    JP   API_Lout

; Space character ouput to console
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved
SpaceOut:   LD   A,$20
            JP   API_Cout

; String output to console
;   On entry: DE = Address of string
;   On exit:  BC DE HL IX IY preserved
StrOut:     JP   API_Sout


; Delay by DE milliseconds (approx)
;   On entry: DE = Delay time in milliseconds
;   On exit:  BC DE HL IX IY preserved
API_Delay:  PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            CALL delay
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET


; Character output to console device
;   On entry: A = Character to be output
;   On exit:  BC DE HL IX IY preserved
API_Cout:   PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            CALL $0008
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET


; New line output to console device
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved
API_Lout:   PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            LD A, CR ; enter char
            CALL $0008
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET


; String output to console device
;   On entry: DE = Address of string
;   On exit:  BC DE HL IX IY preserved
API_Sout:   PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            LD H, D
            LD L, E
            CALL SNDLCDMSG
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET


; Hex byte output to console
;   On entry: A = Byte to be output in hex
;   On exit:  BC DE HL IX IY preserved
HexOut:     PUSH AF             ;Preserve byte to be output
            RRA                 ;Shift top nibble to
            RRA                 ;  botom four bits..
            RRA
            RRA
            AND  $0F           ;Mask off unwanted bits
            CALL HexOutHex           ;Output hi nibble
            POP  AF             ;Restore byte to be output
            AND  $0F           ;Mask off unwanted bits
; Output nibble as ascii character
HexOutHex:       CP   $0A           ;Nibble > 10 ?
            JR   C,HexOutSkip        ;No, so skip
            ADD  A,7            ;Yes, so add 7
HexOutSkip:      ADD  A,$30         ;Add ASCII '0'
            JP   API_Cout       ;Write character


; Output string at DE with substitutions
;   On entry: A = Address of device on I2C bus (write address)
;             DE = Address of null terminated string
;             H = Value to substitute for $H
;             L = Value to substitute for $L
;             B = Value to substitute for $B
;   On exit:  DE = Address of next location after this string
;             IX IY preserved
String:     LD   A,(DE)         ;Get character from string
            INC  DE             ;Point to next character in string
            OR   A              ;Null ?
            RET  Z              ;Yes, so we're done
            CP   '$'            ;Substitue value?
            JR   Z,StringSubst       ;Yes, so go handle substitution
            CALL CharOut        ;Output character to console
            JR   String         ;Go get next character from string
StringSubst:     LD   A,(DE)         ;Get character from string
            INC  DE             ;Point to next character in string
            OR   A              ;Null ?
            RET  Z              ;Yes, so we're done
            CP   'H'            ;Register H
            JR   NZ,StringNotH       ;No, so skip
            LD   A,H            ;Get value 'H'
            JR   StringGotIt         ;Go output it in hex
StringNotH:      CP   'L'            ;Register L
            JR   NZ,StringNotL       ;No, so skip
            LD   A,L            ;Get value 'L'
            JR   StringGotIt         ;Go output it in hex
StringNotL:      CP   'B'            ;Register B
            JR   NZ,StringNotB       ;No, so skip
            LD   A,B            ;Get value 'L'
            ;JR   @GotIt        ;Go output it in hex
StringGotIt:     CALL HexOut         ;Output write address in hex
StringNotB:      JR   String         ;Go get next character from string


; **********************************************************************
; I2C support functions

; I2C bus open device
;   On entry: A = Device address (bit zero is read flag)
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             BC DE HL IX IY preserved
I2C_Open:   PUSH AF
            CALL I2C_Start      ;Output start condition
            POP  AF
            JR   I2C_Write      ;Write data byte


; I2C bus close device
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  If successfully A=0 and Z flagged
;             If unsuccessfully A=Error and NZ flagged
;             SCL = hi, SDA = hi
;             BC DE HL IX IY preserved
I2C_Close:  JP   I2C_Stop       ;Output stop condition


; **********************************************************************
; **********************************************************************
; I2C bus master driver
; **********************************************************************
; **********************************************************************

; Functions provided are:
;     I2C_Start
;     I2C_Stop
;     I2C_Read
;     I2C_Write
;
; This code has delays between all I/O operations to ensure it works
; with the slowest I2C devices
;
; I2C transfer sequence
;   +-------+  +---------+  +---------+     +---------+  +-------+
;   | Start |  | Address |  | Data    | ... | Data    |  | Stop  |
;   |       |  | frame   |  | frame 1 |     | frame N |  |       |
;   +-------+  +---------+  +---------+     +---------+  +-------+
;
;
; Start condition                     Stop condition
; Output by master device             Output by master device
;       ----+                                      +----
; SDA       |                         SDA          |
;           +-------                        -------+
;       -------+                                +-------
; SCL          |                      SCL       |
;              +----                        ----+
;
;
; Address frame
; Clock and data output from master device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | A 7 | A 6 | A 5 | A 4 | A 3 | A 2 | A 1 | R/W | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;
; Data frame 
; Clock output by master device
; Data output by transmitting device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | D 7 | D 6 | D 5 | D 4 | D 3 | D 2 | D 1 | D 0 | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;


; **********************************************************************
; I2C constants


; I2C bus master interface
; The default device option is for SC126 or compatible

I2C_PORT:   .EQU $21           ;Host I2C port address
I2C_SDA_WR: .EQU 7              ;Host I2C write SDA bit number
I2C_SDA_RD: .EQU 7              ;Host I2C read SDA bit number
I2C_SCL_WR: .EQU 0              ;Host I2C write SCL bit number
I2C_SCL_RD: .EQU 0              ;Host I2C read SCL bit number 
I2C_QUIES:  .EQU 0b10000001     ;Host I2C output port quiescent value


; I2C support constants
ERR_NONE:   .EQU 0              ;Error = None
ERR_JAM:    .EQU 1              ;Error = Bus jammed [not used]
ERR_NOACK:  .EQU 2              ;Error = No ackonowledge
ERR_TOUT:   .EQU 3              ;Error = Timeout


; **********************************************************************
; Hardware dependent I2C bus functions


; I2C bus transmit frame (address or data)
;   On entry: A = Data byte, or
;                 Address byte (bit zero is read flag)
;             SCL = low, SDA = low
;   On exit:  If successful A=0 and Z flagged
;                SCL = lo, SDA = lo
;             If unsuccessful A=Error and NZ flagged
;                SCL = high, SDA = high, I2C closed
;             BC DE HL IX IY preserved
I2C_Write:  PUSH BC             ;Preserve registers
            PUSH DE
            LD   D,A            ;Store byte to be written
            LD   B,8            ;8 data bits, bit 7 first
I2C_WriteWr_Loop:   RL   D              ;Test M.S.Bit
            JR   C,I2C_WriteBit_Hi      ;High, so skip
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = data bit)
            JR   I2C_WriteBit_Clk
I2C_WriteBit_Hi:    CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA = data bit)
I2C_WriteBit_Clk:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = data bit)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = data bit)
            DJNZ I2C_WriteWr_Loop
; Test for acknowledge from slave (receiver)
; On arriving here, SCL = lo, SDA = data bit
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/ack)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/ack)
            CALL I2C_RdPort     ;Read SDA input
            LD   B,A
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = hi)
            BIT  I2C_SDA_RD,B
            JR   NZ,I2C_WriteNoAck      ;Skip if no acknowledge
            POP  DE             ;Restore registers
            POP  BC
            XOR  A              ;Return success A=0 and Z flagged
            RET
; I2C STOP required as no acknowledge
; On arriving here, SCL = lo, SDA = hi
I2C_WriteNoAck:     CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = lo)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA = hi)
            POP  DE             ;Restore registers
            POP  BC
            LD   A,ERR_NOACK    ;Return error = No Acknowledge
            OR   A              ;  and NZ flagged
            RET


; I2C bus receive frame (data)
;   On entry: A = Acknowledge flag
;               If A != 0 the read is acknowledged
;             SCL low, SDA low
;   On exit:  If successful A = data byte and Z flagged
;               SCL = low, SDA = low
;             If unsuccessul* A = Error and NZ flagged
;               SCL = low, SDA = low
;             BC DE HL IX IY preserved
; *This function always returns successful
I2C_Read:   PUSH BC             ;Preserve registers
            PUSH DE
            LD   E,A            ;Store acknowledge flag
            LD   B,8            ;8 data bits, 7 first
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/input)
I2C_ReadRd_Loop:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/input)
            CALL I2C_RdPort     ;Read SDA input bit
            SCF                 ;Set carry flag
            BIT  I2C_SDA_RD,A   ;SDA input high?
            JR   NZ, I2C_ReadRotate     ;Yes, skip with carry flag set
            CCF                 ;Clear carry flag
I2C_ReadRotate:    RL   D              ;Rotate result into D
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA hi/input)
            DJNZ  I2C_ReadRd_Loop       ;Repeat for all 8 bits
; Acknowledge input byte
; On arriving here, SCL = lo, SDA = hi/input
            LD   A,E            ;Get acknowledge flag
            OR   A              ;A = 0? (indicates no acknowledge)
            JR   Z, I2C_ReadNoAck       ;Yes, so skip acknowledge
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA lo)
I2C_ReadNoAck:     CALL I2C_SCL_HI     ;SCL hi    (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            LD   A,D            ;Get data byte received
            POP  DE             ;Restore registers
            POP  BC
            CP   A              ;Return success Z flagged
            RET


; I2C bus start
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = low, SDA = low
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are high
I2C_Start:  CALL I2C_INIT       ;Initialise I2C control port
;           CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA ??)
;           CALL I2C_SDA_HI     ;SDA high  (SCL hi, SDA hi)
; Generate I2C start condition
            CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; I2C bus stop 
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = high, SDA = high
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are low
I2C_Stop:   CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
; Generate stop condition
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA hi)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; **********************************************************************
; I2C bus simple I/O functions
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved

I2C_INIT:   LD   A,I2C_QUIES    ;I2C control port quiescent value
            JR   I2C_WrPort

I2C_SCL_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SCL_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SDA_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SDA_WR,A
            JR   I2C_WrPort

I2C_SDA_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SDA_WR,A
            ;JR   I2C_WrPort

I2C_WrPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            OUT  (C),A          ;Write A to I2C I/O port
            LD   (I2C_RAMCPY),A ;Write A to RAM copy
            POP  BC             ;Restore registers
            RET

I2C_RdPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            IN   A,(C)          ;Read A from I/O port
            POP  BC             ;Restore registers
            RET



WELLCOME: .db CS, CR, CR, LF,"Z80 Mini Iniciado", CR, LF, 00H
MSG_MONITOR .db "Z80 MINI, H TO HELP",CR, 00H

MSG_MENU0  .db "F1 RUN (JP $8000)",CR, 00H
MSG_MENU1  .db "F2 Intel hex loader",CR, 00H
MSG_MENU2  .db "B - Basic",CR, 00H
MSG_MENU3  .db "D AAAA - DISPLAY",CR,00H
MSG_MENU4  .db "M AAAA - MODIFY",CR,00H
MSG_MENU5  .db "G AAAA - GO TO",CR, 00H
MSG_MENU6  .db "O Out AA DD",CR, 00H
MSG_MENU7  .db "I In AA",CR, 00H
MSG_MENU8  .db "1 I2C Scan",CR, 00H
MSG_MENU9  .db "2 I2C PC -> MEM",CR, 00H
MSG_MENU10 .db "3 I2C MEM -> PC",CR, 00H
MSG_MENU11 .db "4 I2C WRITE DD",CR, 00H
MSG_MENU12 .db "5 I2C WRITE RR DD",CR, 00H
MSG_MENU13 .db "6 I2C READ ONE BYTE",CR, 00H
MSG_MENU14 .db "7 I2C READ RR BYTE", 00H ; ultimo não tem CR (nova linha)



LISTMsg:    .DB  CS,"I2C device found at:",CR,0
MSG_MEM2CPU .db CS,"COPY I2C MEM TO CPU",CR, 00H
MSG_CPU2MEM .db CS,"COPY CPU TO I2C MEM",CR, 00H

MSG_I2C_WR_DD    .db CS,"WRITE ONE BYTE",CR, 00H
MSG_I2C_WR_RR_DD .db CS,"WRITE REG ONE BYTE",CR, 00H
MSG_I2C_RD       .db CS,"READ ONE BYTE",CR, 00H
MSG_I2C_RD_RR    .db CS,"READ REG ONE BYTE",CR, 00H

MSG_FROM    .db "FROM: ", 00H
MSG_TO      .db CR,"TO: ", 00H
MSG_SIZE    .db CR,"SIZE(BYTES): ", 00H
MSG_COPYOK  .db CR,"COPY OK", 00H
MSG_COPYFAIL  .db CR,"COPY FAIL", 00H

MSG_DEV_ADDR  .db CR,"DEVICE ADDR(AA): ", 00H
MSG_DEV_REG   .db CR,"REGISTER(RR): ", 00H
MSG_DEV_DATA  .db CR,"DATA(DD): ", 00H


MSG_ILOAD .db $0C, "Intel HEX loader...", CR, 00H
FILEOK    .DB      "FILE RECEIVED OK",CR,00H
CSUMERR   .DB    "CHECKSUM ERROR",CR,00H



; **********************************************************************
; I2C workspace / variables in RAM

            .ORG  I2CDATA

I2C_RAMCPY: .DB  0              ;RAM copy of output port

RESULTS:    .DB  0              ;Large block of results can start here

.end
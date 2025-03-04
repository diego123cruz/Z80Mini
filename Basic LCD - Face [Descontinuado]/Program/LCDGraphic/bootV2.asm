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
;               - Leds: 00H (Red B0-B3, Green B4-B7)
;
;
;         Compiler: https://k1.spdns.de/Develop/Projects/zasm/Distributions/
;         Command line: ./zasm --z80 -w --bin  bootV2.asm
;               
;         INTEL HEX      ./zasm --z80 -w -x bootV2.asm 
;
;
;         GRAVAÇÃO (32kb):
;	  minipro -p AT28C256 -w bootV2.rom -s	
;
;
; -----------------------------------------------------------------------------
; PORTS
; -----------------------------------------------------------------------------
LCDCTRL	    .EQU    70H
LCDDATA     .EQU    71H
KEY_IN      .EQU    40H
KEY_OUT     .EQU    40H

; -----------------------------------------------------------------------------
; CONTROL KEYS
; -----------------------------------------------------------------------------
CTRLC       .EQU    03H             ; Control "C"
CTRLG       .EQU    07H             ; Control "G"
BKSP        .EQU    08H             ; Back space
LF          .EQU    0AH             ; Line feed
VT          .equ    0BH             ; 
CS          .EQU    0CH             ; Clear screen
CR          .EQU    0DH             ; Carriage return [Enter]
CTRLO       .EQU    0FH             ; Control "O"
CTRLQ	    .EQU    11H		    ; Control "Q"
CTRLR       .EQU    12H             ; Control "R"
CTRLS       .EQU    13H             ; Control "S"
CTRLU       .EQU    15H             ; Control "U"
ESC         .EQU    1BH             ; Escape
DEL         .EQU    7FH             ; Delete

; -----------------------------------------------------------------------------
; KEYS MAP
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; H_Delay CONFIG
; -----------------------------------------------------------------------------
kCPUClock:  .EQU 4000000       ;CPU clock speed in Hz
kDelayOH:   .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:   .EQU 26             ;Inner loop time in Tcycles
kDelayTA:   .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:   .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:  .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop

; -----------------------------------------------------------------------------
; MS BASIC ENTRY POINT
; -----------------------------------------------------------------------------
BASIC       .EQU    $6000           ; inicio basic 6000H, workspace 9000H
BASIC_W     .EQU    BASIC+2

; -----------------------------------------------------------------------------
; SOFTWARE SERIAL
; -----------------------------------------------------------------------------
;
; BAUD RATE CONSTANTS
;
B300:	.EQU	0220H	;300 BAUD
B1200:	.EQU	0080H	;1200 BAUD
B2400:	.EQU	003FH	;2400 BAUD
B4800:	.EQU	001BH	;4800 BAUD
B9600:	.EQU	000BH	;9600 BAUD

SERIAL_RX_PORT:          .EQU $C0             ; Serial RX port - bit7
SERIAL_TX_PORT:          .EQU $C0             ; Serial TX Port - bit6

; -----------------------------------------------------------------------------
; SYSTEM SETTINGS
; -----------------------------------------------------------------------------
SYSTEM:	.EQU 	$FFF0	;INITIAL STACK POINTER

; -----------------------------------------------------------------------------
; I2C SETTINGS
; -----------------------------------------------------------------------------
I2CA_BLOCK: .EQU $AE            ;I2C device addess: 24LC256 (Copy from/to Mem)
TIMEOUT:    .EQU 10000          ;Timeout loop counter

; -----------------------------------------------------------------------------
; LCD CONSTANTS
; -----------------------------------------------------------------------------
    ; LCD TEXT MODE
LCD_LINE1   .EQU    80H
LCD_LINE2   .EQU    90H
LCD_LINE3   .EQU    88H
LCD_LINE4   .EQU    98H

; -----------------------------------------------------------------------------
; MEMORY MAP
; -----------------------------------------------------------------------------
; $0000 - 7FFF ROM (Monitor)
; $8000 - EFFF USER RAM
; $F000 - FFFF SYSTEM MONITOR

DISPLAY             .EQU    $F000   ; 1024 bytes - Display buffer
MSGBUF:             .EQU    $F401   ; 32 bytes - STRING HANDLING AREA
DATABYTE:           .EQU    $F420   ; 1 byte - THE DATA
I2C_RAMCPY:         .EQU    $F421   ; 1 byte - RAM copy of output port
I2C_ADDR            .EQU    $F422   ; 1 byte - device address
I2C_RR              .EQU    $F423   ; 1 byte - register
I2C_DD              .EQU    $F424   ; 1 byte - data
ADDR:               .EQU    $F425   ; 2 bytes - THE ADDRESS
ADDR_FROM           .EQU    $F427   ; 2 bytes - THE ADDRESS FROM
ADDR_TO             .EQU    $F429   ; 2 bytes - THE ADDRESS TO
ADDR_SIZE           .EQU    $F42B   ; 2 bytes - THE ADDRESS SIZE
PORT_SET            .EQU    $F42D   ; 1 byte - Define port (input/output) Default 0xC0(onboard)
PORT_OUT_VAL        .EQU    $F42E   ; 1 byte - save value out port
LCD_DATA            .EQU    $F42F   ; 1 byte
BAUD:	            .EQU    $F430   ;2 bytes - BAUD RATE
PUTCH:              .EQU    $F432   ;2 bytes - OUTPUT A CHARACTER TO SERIAL
GETCH:              .EQU    $F434   ;2 bytes - WAIT FOR A CHARACTER FROM SERIAL
LCD_CHAR            .EQU    $F435   ; 1 byte char ex: 'A'
LCD_CHAR_POINT      .EQU    $F436   ; 2 bytes ponteiro para o mapa de caracteres
LCD_TXT_X           .EQU    $F438   ; 1 byte  0-20 (21 col)
LCD_TXT_Y           .EQU    $F439   ; 1 byte  0-7  (8 row)
LCD_BYTE_INDEX      .EQU    $F43A   ; 2 bytes pointer pixel(8)
LCD_BIT_INDEX       .EQU    $F43C   ; 1 byte pointer pixel(1)
LCD_TXT_X_TMP       .EQU    $F43D   ; 2 bytes = LCD_TXT_X * 6
LCD_TXT_Y_TMP       .EQU    $F43F   ; 2 bytes = LCD_TXT_Y * 128
LCD_CHAR_H          .EQU    $F441   ; 1 byte altura do char
LCD_CHAR_W          .EQU    $F442   ; 1 byte largura do char
LCD_TMP_POINT       .EQU    $F443   ; 2 bytes ponteiro do pixel altural do print
LCD_DELETE_CHAR     .EQU    $F445   ; 1 byte, 0 não, ff delete proximo char
LCD_AUTO_X          .EQU    $F446   ; 1 byte, 0 sim, ff nao
LCD_TEMP            .EQU    $F447   ; 1 byte
LCD_COOX            .EQU    $F448   ; 1 byte, local onde vai printar
LCD_COOY            .EQU    $F449   ; 1 byte
LCD_PRINT_H         .EQU    $F44A   ; 1 byte, tamanho do que vai printar
LCD_PRINT_W         .EQU    $F44B   ; 1 byte
LCD_PRINT_IMAGE     .EQU    $F44C   ; 2 bytes


        .ORG 0
RST00	DI
        JP  START_MONITOR
						
        .ORG     0008H
RST08   JP  PRINTCHAR

        .ORG 0010H
RST10   JP KEYREADINIT

        .ORG 0018H ; check break
RST18   JP CHKKEY

RST20   .ORG 0020H
        RET

RST28   .ORG 0028H
        RET

        .ORG 0030H
RST30   JP APIHandler

RST38   .ORG 0038H ; INT - MASKABLE INTERRUPT MODE-1
        RETI

RST66   .ORG 0066H ; NMI - Non­maskable Interrupt 
        RETN


; Não remover daqui...
KEYMAP:
.BYTE   "12345",KF1,"67890"
.BYTE   KF2,"QWERT",KF3,"YUIOP"
.BYTE   KF4,"ASDFG",KLEFT,"HJKL", CR
.BYTE   KDOWN,CTRLC, "ZXCV",KRIGHT,"BNM ", DEL, KUP

SHIFTKEYMAP:
.BYTE   "!@#$%",KF5,"^&*()"
.BYTE   KF6,"`~-_=",KF7,"+;:'" 
.BYTE   22h
.BYTE   KF8,"{}[]|",KLEFT,$5C,"<>?", CR
.BYTE   KDOWN,ESC,"/,. ",KRIGHT,"    ", DEL, KUP


API     .ORG 0100H ; API POINTER
#include "API.asm" ; manter essa ordem...
#include "Keyboard.asm"
#include "LCDGraphic.asm"
#include "LoaderIntel.asm"
#include "I2C.asm"
#include "SoftSerial.asm"
#include "Monitor.asm"
#include "Utils.asm"
#include "Strings.asm"
#include "basicV2.asm"
.end

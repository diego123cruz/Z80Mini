;   Z80Mini Julho 2024
;   
;   ============== COMPILADOR ===================
;
;   Compilador (https://k1.spdns.de/Develop/Projects/zasm/Distributions/):
;
;       Win(CMD):           zasm.exe --z80 -w -u --bin  Z80Mini.asm
;       Win(Powershell):    ./zasm.exe --z80 -w -u --bin  Z80Mini.asm
;       Macos:              ./zasm --z80 -w -u --bin  Z80Mini.asm
;
;
;   =============== GRAVAÇÃO ====================
;
;     GRAVAÇÃO (32kb) (TL866 2 Plus - MacOS):
;	    minipro -p AT28C256 -w Z80Mini.rom -s	
;
;
;   =============== HARDWARE ====================
;         - CPU Z80@7.37280Mhz
;         - Lcd Grafico 128x64
;         - Keyboard 40 keys + Shift
;         - Rom 32k 0000h - 7FFFh
;         - Ram 32k 8000h - FFFFh
;         
;         - Ports:
;               - Keyboard: 40H
;               - Display:  70H (LCDCTRL), 71H (LCDDATA)
;               - User IN/OUT: C0H
;               - Leds: 00H (Red B0-B3, Green B4-B7)
;
;
;   =============== LCD LIB ======================
;   ; Graphical LCD 128 x 64 Library
;   ------------------------------
;   By B. Chiha May-2023
;   https://github.com/bchiha/Z80_LCD_128x64_Graphics_Library/tree/
;
;
;
; -----------------------------------------------------------------------------
; PORTS
; -----------------------------------------------------------------------------
LCDCTRL	    .EQU    70H
LCDDATA     .EQU    71H
KEY_IN      .EQU    40H
KEY_OUT     .EQU    40H
LEDS_ONBOARD .EQU   10H

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
KF5         .EQU    $84             ; Key F5

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
; H_Delay CONFIG
; -----------------------------------------------------------------------------
kCPUClock:  .EQU 7372800       ;CPU clock speed in Hz
kDelayOH:   .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:   .EQU 26             ;Inner loop time in Tcycles
kDelayTA:   .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:   .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:  .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop

; -----------------------------------------------------------------------------
; SIO/2 - SERIAL
; -----------------------------------------------------------------------------
SIOA_D		.EQU	$00
SIOA_C		.EQU	$02
SIOB_D		.EQU	$01 ; Não usado
SIOB_C		.EQU	$03 ; Não usado

; -----------------------------------------------------------------------------
; SYSTEM SETTINGS
; -----------------------------------------------------------------------------
SYSTEM_SP:	.EQU 	$FFF0	;INITIAL STACK POINTER

; -----------------------------------------------------------------------------
; I2C SETTINGS
; -----------------------------------------------------------------------------
I2CA_BLOCK: .EQU $AE            ;I2C device addess: 24LC256 (Copy from/to Mem)
TIMEOUT:    .EQU 10000          ;Timeout loop counter


        .ORG 0
RST00	DI
        JP  START_SYSTEM
						
        .ORG     0008H
RST08   JP  LCD_PRINT_A

        .ORG 0010H
RST10   JP KEYREADINIT

        .ORG 0018H ; check break
RST18   JP CHKKEY

RST20   .ORG 0020H
        RET

RST28   .ORG 0028H
        RET

        .ORG 0030H
RST30   RET

RST38   .ORG 0038H ; INT - MASKABLE INTERRUPT MODE-1
        RETI

RST66   .ORG 0066H ; NMI - Non­maskable Interrupt 
        RETN


line1 db ESC,"1234567890=",DEL
line2 db 09H,"qwertyuiop[]"
line3 db 0,"asdfghjkl'",CR,CR
line4 db 0,"-zxcvbnm,.",KUP,";"
line5 db KF1,KF2,KF3,KF4,KF5,"  ",$5c,"-/",KLEFT,KDOWN,KRIGHT
line1_shift db ESC,"!@#$%^&*()+",DEL
line2_shift db 09H,"QWERTYUIOP{}"
line3_shift db 0,"ASDFGHJKL",$22,CR, CR
line4_shift db 0,"-ZXCVBNM<>",KUP,":"
line5_shift db KF1,KF2,KF3,KF4,KF5,"  |_?", KLEFT, KDOWN, KRIGHT

API     .ORG 0100H ; API POINTER
; **********************************************************************
; **  API - Public functions                                          **
; **********************************************************************
; LCD
    JP INIT_LCD             ;Initalise the LCD
    JP CLEAR_GBUF           ;Clear the Graphics Buffer
    JP CLEAR_GR_LCD         ;Clear the Graphics LCD Screen
    JP CLEAR_TXT_LCD        ;Clear the Text LCD Screen
    JP SET_GR_MODE          ;Set Graphics Mode
    JP SET_TXT_MODE         ;Set Text Mode
    JP DRAW_BOX             ;Draw a rectangle between two points
    JP DRAW_LINE            ;Draw a line between two points
    JP DRAW_CIRCLE          ;Draw a circle from Mid X,Y to Radius
    JP DRAW_PIXEL           ;Draw one pixel at X,Y
    JP FILL_BOX             ;Draw a filled rectangle between two points
    JP FILL_CIRCLE          ;Draw a filled circle from Mid X,Y to Radius
    JP PLOT_TO_LCD          ;Display the Graphics Buffer to the LCD Screen
    JP PRINT_STRING         ;Print Text on the screen in a given row
    JP PRINT_CHARS          ;Print Characters on the screen in a given row and column
    JP DELAY_US             ;Microsecond delay for LCD updates
    JP DELAY_MS             ;Millisecond delay for LCD updates
    JP SET_BUF_CLEAR        ;Clear the Graphics buffer on after Plotting to the screen
    JP SET_BUF_NO_CLEAR     ;Retain the Graphics buffer on after Plotting to the screen
    JP CLEAR_PIXEL          ;Remove a Pixel at X,Y
    JP FLIP_PIXEL           ;Flip a Pixel On/Off at X,Y
    JP LCD_INST             ;Send a parallel or serial instruction to LCD
    JP LCD_DATA             ;Send a parallel or serial datum to LCD
    JP SER_SYNC             ;Send serial synchronise byte to LCD
    JP DRAW_GRAPHIC         ;Draw an ASCII charcter or Sprite to the LCD
    JP INV_GRAPHIC          ;Inverse graphics printing
    JP INIT_TERMINAL        ;Initialize the LCD for terminal emulation
    JP SEND_CHAR_TO_GLCD    ;Send an ASCII Character to the LCD
    JP SEND_STRING_TO_GLCD  ;Send an ASCII String to the LCD
    JP SEND_A_TO_GLCD       ;Send register A to the LCD
    JP SEND_HL_TO_GLCD      ;Send register HL to the LCD
    JP SET_CURSOR           ;Set the graphics cursor
    JP GET_CURSOR           ;Get the current cursor
    JP DISPLAY_CURSOR       ;Set Cursor on or off
; I2C Board
    JP I2C_Open              ;Start i2c (Device address in A)
    JP I2C_Close             ;Close i2c 
    JP I2C_Read              ;I2C Read
    JP I2C_Write             ;I2C Write
; SERIAL Soft
    JP TXDATA               ; OUTPUT A CHARACTER TO THE TERMINAL, Char in A
    JP RXDATA               ; INPUT A CHARACTER FROM THE TERMINAL, Char in A
    JP SNDSTR               ; SEND AN ASCII STRING OUT THE SERIAL PORT (Max 128 chars), HL = POINTER TO 00H TERMINATED STRING
    JP INTELLOADER          ; Start load intel hex
; KEYBOARD
    JP KEYREADINIT          ;Input character KeyboardOnboard (Char in A), loop until release key
    JP KEYREAD              ;Input character KeyboardOnboard (Char in A), WITHOUT loop until release key
    JP CHKKEY               ;Check BK press
; UTIL
    JP H_Delay              ;Delay in milliseconds (DE in millis)
    JP LED_RED              ;Half byte in A (4 bits)
    JP LED_GREEN            ;Half byte in A (4 bits)


START_SYSTEM:
    ; init RAM
    LD A, 1 ; capslock = on
    LD (KEY_CAPS), A
    
    XOR A
    LD (LED_ONBOARD), A
    LD (BDEL), A
RESET_WARM:
    ; Set stack pointer
    LD SP, SYSTEM_SP

    LD DE, $0064 ; 100ms
    CALL H_Delay

    ; Init serial
    CALL INIT_SERIAL

    ; Init LCD
    CALL INIT_TERMINAL
    CALL SET_GR_MODE
    CALL SET_BUF_NO_CLEAR

    ; Show init string
    LD BC, $0000
    CALL SET_CURSOR
    LD DE, WELLCOME_LCD
    ; set cursor ON
    LD A, 0
    LD (CURSOR_ON), A
    ; send cursor
    LD A, 0
    CALL SEND_STRING_TO_GLCD


LOOP_MONITOR:
    CALL KEYREADINIT

    CP 'H'
    CALL Z, SHOW_MENU

    CP KF1
    JP Z, $8000

    CP KF2
    JP Z, INTELLOADER

    CP 'B'
    JP Z, START_BASIC

    CP 'G'
    CALL Z, GOJUMP

    CP 'M'
    CALL Z, MODIFY

    CP 'D'
    CALL Z, DSPLAY

    CP 'O'
    CALL Z, OUTPORT

    CP 'I'
    CALL Z, INPORT_MON

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

    CP '8'
    CALL Z, READ_MEM_FILES

    CALL SEND_CHAR_TO_GLCD

    JP  LOOP_MONITOR

BASIC:
    JP $6000
BASIC_W:
    JP $6003


#include "LCD.asm"
#include "I2C.asm"
#include "Serial.asm"
#include "Keyboard.asm"
#include "Utils.asm"
#include "Menu.asm"
#include "Monitor.asm"








WELLCOME: .db CS, CR, CR, LF,"Z80 Mini Iniciado", CR, LF, 00H
WELLCOME_LCD: .db "Z80 Mini Iniciado", CR, 00H

MSG_MENU0  .db "F1 RUN (JP $8000)",CR, 00H
MSG_MENU1  .db "F2 Intel hex loader",CR, 00H
MSG_MENU2  .db "F3 LIVRE",CR, 00H
MSG_MENU3  .db "F4 LIVRE",CR, 00H
MSG_MENU4  .db "F5 LIVRE",CR, 00H

MSG_MENU8  .db "B - Basic",CR, 00H
MSG_MENU9  .db "D AAAA - DISPLAY",CR,00H
MSG_MENU10 .db "M AAAA - MODIFY",CR,00H
MSG_MENU11 .db "G AAAA - GO TO",CR, 00H
MSG_MENU12 .db "O Out AA DD",CR, 00H
MSG_MENU13 .db "I In AA",CR, 00H
MSG_MENU14 .db "1 I2C Scan",CR, 00H
MSG_MENU15 .db "2 I2C PC -> MEM",CR, 00H
MSG_MENU16 .db "3 I2C MEM -> PC",CR, 00H
MSG_MENU17 .db "4 I2C WRITE DD",CR, 00H
MSG_MENU18 .db "5 I2C WRITE RR DD",CR, 00H
MSG_MENU19 .db "6 I2C READ ONE BYTE",CR, 00H
MSG_MENU20 .db "7 I2C READ RR BYTE", CR, 00H 
MSG_MENU21 .db "8 Read Memory", CR, 00H 

I2C_LIST_MSG:    .DB "I2C device found at:",CR,0

MSG_ILOAD   .db  "Intel HEX loader...",CR, 00H
FILEOK      .DB  "FILE RECEIVED OK",CR, 00H
CSUMERR     .DB  "CHECKSUM ERROR",CR, 00H

MSG_BASIC .db "(C)old or (w)arm ?",CR, 00H

MSG_READFILE_EXE .db "_EXE", 00H
MSG_READFILE_IMG .db "_IMG", 00H
MSG_READFILE_TXT .db "_TXT", 00H

MSG_FROM    .db "FROM: ", 00H
MSG_TO      .db "TO: ", 00H
MSG_SIZE    .db "SIZE(BYTES): ", 00H
MSG_COPYOK  .db "COPY OK", 00H
MSG_COPYFAIL  .db "COPY FAIL", 00H
MSG_EOF  .db " - - - FIM - - - ", 00H

MSG_DEV_ADDR  .db "DEVICE ADDR(AA): ", 00H
MSG_DEV_REG   .db "REGISTER(RR): ", 00H
MSG_DEV_DATA  .db "DATA(DD): ", 00H

MSG_CPU2MEM .db "COPY CPU TO I2C MEM",CR, 00H
MSG_MEM2CPU .db "COPY I2C MEM TO CPU",CR, 00H
MSG_I2C_WR_DD    .db "WRITE ONE BYTE",CR, 00H
MSG_I2C_WR_RR_DD .db "WRITE REG ONE BYTE",CR, 00H
MSG_I2C_RD       .db "READ ONE BYTE",CR, 00H
MSG_I2C_RD_RR    .db "READ REG ONE BYTE",CR, 00H


#include "MSBasic.asm"

; RAM Locations - Move this section to RAM if necessary
;---------------

.ORG $F000              ;Start location
        
SBUF:   EQU 16 * $78     ;Scroll Buffer size  16 * 60 = 960 byte (10 lines), change to 20 lines (16 * 120($78))
        DS SBUF         ;Scroll Buffer space abover GBUF 
GBUF:   DS 0400H        ;Graphics Buffer 16 * 64 = 1024 byte
TGBUF:  EQU GBUF        ;Terminal GBUF
VPORT:  DW GBUF         ;View port start address
TBUF:   DW GBUF         ;Top of Buffer pointer
ENDPT:  DW 0000H        ;End Point for Line
SX:     DB 00H          ;Sign of X
SY:     DB 00H          ;Sign of Y
DX:     DW 0000H        ;Change of X
DY:     DW 0000H        ;Change of Y
ERR:    DW 0000H        ;Error Rate
RAD:    DW 0000H        ;Radius
CLRBUF: DB 00H          ;Clear Buffer Flag on LCD Displaying
CURSOR_XY: DW 0000H     ;Cursor Address X,Y
CURSOR_Y: EQU CURSOR_XY   ;Cursor Y
CURSOR_X: EQU CURSOR_XY+1 ;Cursor X
CURSOR_YS: DB 00H       ;Start Y row for new line
CURSOR_ON: DB 00H       ;Cursor on/off flag
INVERSE: DB 00H         ;Inverse Flag
PIXEL_X: DB 00H         ;Pixel X length

BAUD:   DW  0000H       ; Serial baud
PUTCH:  DW  0000H       ; Serial
GETCH:  DW  0000H       ; Serial

LED_ONBOARD:  DB 00H      ; Led onboard

BDEL:     DB    00H  ; Flag to delete char MSBasic

I2C_RAMCPY:         .DB    $00   ; 1 byte - RAM copy of output port
I2C_ADDR            .DB    $00   ; 1 byte - device address
I2C_RR              .DB    $00   ; 1 byte - register
I2C_DD              .DB    $00   ; 1 byte - data

ADDR_FROM    DW  0000H
ADDR_TO      DW  0000H
ADDR_SIZE    DW  0000H

MSGBUF:      DS  20H ; 32 bytes...   
DATABYTE:    DB  00H
ADDR:        DW  0000H

KEY_SHIFT:   DB  00H
KEY_CAPS:    DB  00H
KEY_READ:    DB  00H

.end

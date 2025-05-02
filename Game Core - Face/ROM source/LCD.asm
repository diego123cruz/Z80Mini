; Graphical LCD 128 x 64 Library
; ------------------------------
; By B. Chiha May-2023
;
; This is a native Z80 Graphics library to be used with 128x64 Graphical LCD Screens
;
; There are a few variants of these LCD screens, but they must all must use the ST7920
; LCD Controller.  The LCD Screen that I used is the QC12864B.  This screen has two
; ST7921 Panels (128 x 32) stacked one above the other.  Other LCD boards might not do
; this.  If so the PLOT_TO_LCD function will need to be modified. (future work)
;
; These screens have DDRAM (Graphics) and CGRAM (Text) areas.  Both RAM areas can 
; be displayed at the same time.
;
; The Pinout for the QC12864B board is as follows:
;
; Pin	Name	Desc                    Serial  Parallel
; ---   ----    -------------           ------  -------------
; 1     VSS     Ground                  GND     GND
; 2     VDD     Power                   5v      5v
; 3     V0      Contrast                N/A     N/A
; 4     D/I     IR/DR (CS)              5v      A7
; 5     R/W     R/W (SID)               D0      RD (inverted)
; 6     E       Enable (SCLK)           D1      Port 7 (inverted)
; 7     DB0     Data                    N/A     D0
; 8     DB1     Data                    N/A     D1
; 9     DB2     Data                    N/A     D2
; 10    DB3     Data                    N/A     D3
; 11    DB4     Data                    N/A     D4
; 12    DB5     Data                    N/A     D5
; 13    DB6     Data                    N/A     D6
; 14    DB7     Data                    N/A     D7
; 15    PSB     Serial/Para             GND     5v
; 16    NC
; 17    RST     Reset                   RST     RST
; 18    VEE     LCD Drive               N/A     N/A
; 19    A       Backlight               5v/NC   5v/NC
; 20    K       Backlight               GND/NC  GND/NC
;
;
;        ORG 2000H               ;Start location
        
; Modifiable values.  Thse three values can be modified to suit your own set up
; LCD_IR and LCD_DR are the output ports to send an Instruction or Data value.
; V_DELAY_US is the minimum delay needed for a command to be processed by the
; LCD board.  If only some of the data is being sent, make this value larger
        
;Port 7 on TEC is connected to LCD Enable (Pin 6)
;A7 is connected to Register select (Pin 4).  (A7=0 for Instruction, A7=1 for Data)
LCD_IR:	EQU 70H         ;Instruction Register
LCD_DR:	EQU 71H         ;Data Register (A7)
LCD_SER: EQU 00H        ;Serial Port if used
V_DELAY_US: EQU $0010   ;Delay for 76us on your system $0004

;Serial or Parallel communications to the LCD Screen.  Comment one of 
;the labels below based on the LCD connections. 00H = FALSE, 01H = TRUE
;COMMS_MODE: EQU 00H     ;Using PARALLEL Data connection
;COMMS_MODE: EQU 01H     ;Using SERIAL Data connection

; Dont need to modify anything else below.
SER_BT: EQU 11111000B           ;Serial Synchronisation Byte
UP:     EQU $B5                 ; Up Arrow, change Z80 Mini
DN:     EQU $B6                 ; Down Arrow, change Z80Mini
BKSP:   EQU 08H                 ; Back space 08H
TAB:    EQU 09H                 ; Horizontal TAB
LF:     EQU 0AH                 ; Line feed
CS:     EQU 0CH                 ; Clear screen
CR:     EQU 0DH                 ; Carriage return
SPACE:  EQU 20H                 ; Space
CURSOR: EQU 8FH                 ; Cursor
DEL     EQU    7FH              ; Delete


;-----------------
; LCD_PRINT_STRING
; Entry: HL
; String terminada com 0
;-----------------
LCD_PRINT_STRING:
        PUSH AF
	PUSH BC
        PUSH DE
        PUSH HL
        LD A, 0 ; terminador da string..
        LD DE, HL
	CALL SEND_STRING_TO_GLCD
        POP HL
        POP DE
        POP BC 
        POP AF
	RET


;-----------------
; LCD_IMAGE_128x64 - Print image 128x64, CURSOR 0,0
; Entry: HL
;-----------------
LCD_IMAGE_128x64: 
        PUSH AF
	PUSH BC
        PUSH DE
        PUSH HL
        LD BC, $0000
        CALL SET_CURSOR
        LD B, 128
        LD C, 64
	CALL PLOT_GRAPHIC
        CALL PLOT_TO_LCD
        POP HL
        POP DE
        POP BC 
        POP AF
	RET



; Initialise LCD
INIT_LCD:
        LD HL, INIT_BASIC       ;POINT HL TO LCD INITIALIZE TABLE
        LD B, 06H               ;B=4 BYTES
NEXT_CMD:
        LD A, (HL)
        CALL LCD_INST
        INC HL
        DJNZ NEXT_CMD
        LD DE, $0280            ;1.6 ms $0140@4Mhz
        CALL DELAY_MS
        
        CALL CLEAR_GR_LCD
        
; Clears the Graphics Memory Buffer
CLEAR_GBUF:
        LD HL, (VPORT)
        LD DE, (VPORT)
        INC DE
        XOR A
        LD (HL), A
        LD BC, 03FFH
        LDIR
        RET
        
; Clears the Graphics LCD Buffer
CLEAR_GR_LCD:
        CALL SET_GR_MODE
        LD C, 00H
CLR_X:
        LD A, 80H
        OR C
        CALL LCD_INST
        LD A, 80H
        CALL LCD_INST
        LD A, 02H 
        CALL SER_SYNC           ;Data Block Sync
        XOR A                   ;Clear Byte
        LD B, 10H
CLR_Y:
        CALL LCD_DATA
        CALL LCD_DATA
        DJNZ CLR_Y
        INC C
        LD A, C
        CP 20H
        JR NZ, CLR_X        
        RET

; Clears the ASCII Text LCD
CLEAR_TXT_LCD:
        CALL SET_TXT_MODE
        LD A, 80H
        CALL LCD_INST
        LD A, 02H 
        CALL SER_SYNC           ;Data Block Sync
        LD B, 40H
CLR_ROWS:
        LD A,  " "
        CALL LCD_DATA
        DJNZ CLR_ROWS
        RET
        
; Set Graphics Mode
SET_GR_MODE:
        LD A, 34H
        CALL LCD_INST
        LD A, 36H
        JP LCD_INST
        
; Set Text Mode
SET_TXT_MODE:
        LD A, 30H
        JP LCD_INST
        
;Draw Box
;Inputs: BC = X0,Y0
;        DE = X1,Y1
;Destroys: HL
DRAW_BOX:
        PUSH BC
GTOP:
        CALL DRAW_PIXEL
        LD A, D
        INC B
        CP B
        JR NC, GTOP
        POP BC
        
        PUSH BC
        LD C, E
GBOTTOM:
        CALL DRAW_PIXEL
        LD A, D
        INC B
        CP B
        JR NC, GBOTTOM
        POP BC
        
        PUSH BC
GLEFT:
        CALL DRAW_PIXEL
        LD A, E
        INC C
        CP C
        JR NC, GLEFT
        POP BC
        
        PUSH BC
        LD B, D
GRIGHT:
        CALL DRAW_PIXEL
        LD A, E
        INC C
        CP C
        JR NC, GRIGHT
        POP BC
        RET
        
;Fill Box
;Draws vertical lines from X0,Y0 to X0,Y1 and increase X0 to X1 until X0=X1
;Inputs: BC = X0,Y0
;        DE = X1,Y1
;Destroys: HL
FILL_BOX:
        PUSH BC
NEXT_PIXEL:
        CALL DRAW_PIXEL
        LD A, E
        INC C
        CP C
        JR NC, NEXT_PIXEL
        POP BC
        LD A, D
        INC B
        CP B
        JR NC, FILL_BOX
        RET
        
;Draw a line between two points using Bresenham Line Algorithm
; void plotLine(int x0, int y0, int x1, int y1)
; {
;    int dx =  abs(x1-x0), sx = x0<x1 ? 1 : -1;
;    int dy = -abs(y1-y0), sy = y0<y1 ? 1 : -1;
;    int err = dx+dy, e2; /* error value e_xy */
        
;    for(;;){  /* loop */
;       setPixel(x0,y0);
;       if (x0==x1 && y0==y1) break;
;       e2 = 2*err;
;       if (e2 >= dy) { err += dy; x0 += sx; } /* e_xy+e_x > 0 */
;       if (e2 <= dx) { err += dx; y0 += sy; } /* e_xy+e_y < 0 */
;    }
; }
;Inputs: BC = X0,Y0
;        DE = X1,Y1
DRAW_LINE:
;check that points are in range
        LD A, C
        CP 40H
        RET NC
        LD A, B
        CP 80H
        RET NC
        LD A, E
        CP 40H
        RET NC
        LD A, D
        CP 80H
        RET NC
        
;sx = x0<x1 ? 1 : -1
        LD H, 01H
        LD A, B
        CP D
        JR C, $ + 4
        LD H, 0FFH
        LD A, H
        LD (SX), A
        
;sy = y0<y1 ? 1 : -1
        LD H, 01H
        LD A, C
        CP E
        JR C, $ + 4
        LD H, 0FFH
        LD A, H
        LD (SY), A
        
        ld (ENDPT), DE
        
;dx =  abs(x1-x0)
        PUSH BC
        LD L, D
        LD H, 0
        LD C, B
        LD B, 0
        OR A
        SBC HL, BC
        CALL ABSHL
        LD (DX), HL
        POP BC
        
;dy = -abs(y1-y0)
        PUSH BC
        LD L, E
        LD H, 0
        LD B, 0
        OR A
        SBC HL, BC
        CALL ABSHL
        XOR A
        SUB L
        LD L, A
        SBC A, A
        SUB H
        LD H, A
        LD (DY), HL
        POP BC
        
;err = dx+dy,
        LD DE, (DX)
        ADD HL, DE
        LD (ERR), HL
        
LINE_LOOP:
;setPixel(x0,y0)
        CALL DRAW_PIXEL
        
;if (x0==x1 && y0==y1) break;
        LD A, (ENDPT + 1)
        CP B
        JR NZ, $ + 7
        LD A, (ENDPT)
        CP C
        RET Z
        
;e2 = 2*err;
        LD HL, (ERR)
        ADD HL, HL              ;E2
        
;if (e2 >= dy)  err += dy; x0 += sx;
        LD DE, (DY)
        OR A
        SBC HL, DE
        ADD HL, DE
        JP M, LL2
        
        PUSH HL
        LD HL, (ERR)
        ADD HL, DE
        LD (ERR), HL
        LD A, (SX)
        ADD A, B
        LD B, A
        POP HL
        
LL2:
;if (e2 <= dx)  err += dx; y0 += sy;
        LD DE, (DX)
        OR A
        SBC HL, DE
        ADD HL, DE
        JR Z, LL3
        JP P, LINE_LOOP
LL3:
        LD HL, (ERR)
        ADD HL, DE
        LD (ERR), HL
        LD A, (SY)
        ADD A, C
        LD C, A
        
        JR LINE_LOOP
        
ABSHL:
        BIT 7, H
        RET Z
        XOR A
        SUB L
        LD L, A
        SBC A, A
        SUB H
        LD H, A
        RET
        
;Draw a circle from a midpoint to a radius using Bresenham Line Algorithm
; void plotCircle(int xm, int ym, int r)
; {
;    int x = -r, y = 0, err = 2-2*r, i = 0; /* II. Quadrant */
;    printf("Midpoint = (%X,%X), Radius = %X\n", xm, ym, r);
;    do {
;       printf("(%X,%X) ", xm-x, ym+y); /*   I. Quadrant */
;       printf("(%X,%X) ", xm-y, ym-x); /*  II. Quadrant */
;       printf("(%X,%X) ", xm+x, ym-y); /* III. Quadrant */
;       printf("(%X,%X) ", xm+y, ym+x); /*  IV. Quadrant */
;       r = err;
;       if (r <= y) err += ++y*2+1;           /* e_xy+e_y < 0 */
;       if (r > x || err > y) err += ++x*2+1; /* e_xy+e_x > 0 or no 2nd y-step */
;       printf("x = %d, r = %d, y = %d, err =%d\n", x, r, y, err);
;    } while (x < 0);
; }
;Inputs BC = xm,ym (Midpoint)
;       E = radius
DRAW_CIRCLE:
;   int x = -r, err = 2-2*r; /* II. Quadrant */
        XOR A
        SUB E
        LD (SX), A              ;x
;   y = 0
        XOR A
        LD (SY), A              ;y
;   RAD = r
        LD D, 00H
        LD A, E
        LD (RAD), DE            ;r
;   err = 2-2*r
        EX DE, HL
        ADD HL, HL
        EX DE, HL
        LD HL, 0002H
        OR A
        SBC HL, DE              ;err
        LD (ERR), HL
        
CIRCLE_LOOP:
;       setPixel(xm-x, ym+y); /*   I. Quadrant */
        PUSH BC
        LD A, (SX)
        NEG
        ADD A, B
        LD B, A
        LD A, (SY)
        ADD A, C
        LD C, A
        CALL DRAW_PIXEL
        POP BC
;       setPixel(xm+x, ym-y); /* III. Quadrant */
        PUSH BC
        LD A, (SX)
        ADD A, B
        LD B, A
        LD A, (SY)
        NEG
        ADD A, C
        LD C, A
        CALL DRAW_PIXEL
        POP BC
;       setPixel(xm-y, ym-x); /*  II. Quadrant */
        PUSH BC
        LD A, (SY)
        NEG
        ADD A, B
        LD B, A
        LD A, (SX)
        NEG
        ADD A, C
        LD C, A
        CALL DRAW_PIXEL
        POP BC
;       setPixel(xm+y, ym+x); /*  IV. Quadrant */
        PUSH BC
        LD A, (SY)
        ADD A, B
        LD B, A
        LD A, (SX)
        ADD A, C
        LD C, A
        CALL DRAW_PIXEL
        POP BC
;       r = err;
        LD HL, (ERR)
        LD (RAD), HL
;       if (r <= y) err += ++y*2+1;           /* e_xy+e_y < 0 */
        LD A, (SY)
        LD E, A
        LD D, 0
        OR A
        SBC HL, DE
        ADD HL, DE
        JR Z, $ + 5
        JP P, DS1
        LD A, (SY)
        INC A
        LD (SY), A
        ADD A, A
        INC A
        LD E, A
        LD D, 0
        LD HL, (ERR)
        ADD HL, DE
        LD (ERR), HL
;       if (r > x || err > y) err += ++x*2+1; /* e_xy+e_x > 0 or no 2nd y-step */
DS1:
        LD HL, (RAD)
        LD A, (SX)
        LD D, 0FFH
        LD E, A
        OR A
        SBC HL, DE
        ADD HL, DE
        JR Z, $ + 5
        JP P, DS2
        LD HL, (ERR)
        LD A, (SY)
        LD D, 0
        LD E, A
        OR A
        SBC HL, DE
        ADD HL, DE
        JR Z, DS3
        JP M, DS3
DS2:
        LD A, (SX)
        INC A
        LD (SX), A
        ADD A, A
        INC A
        LD E, A
        LD D, 0FFH
        LD HL, (ERR)
        ADD HL, DE
        LD (ERR), HL
;   } while (x < 0);
DS3:
        LD A, (SX)
        OR A
        JP NZ, CIRCLE_LOOP
        RET
        
;Fill Circle
;Fills a circle by increasing radius until Radius = Original Radius E
;Inputs BC = xm,ym (Midpoint)
;       E = radius
FILL_CIRCLE:
        LD D, 01H               ;Start radius
NEXT_CIRCLE:
        PUSH DE                 ;Save end Radius
        LD E, D
        CALL DRAW_CIRCLE
        POP DE                  ;Restore Radius
        LD A, E
        INC D
        CP D
        JR NC, NEXT_CIRCLE
        RET
        
;Draw Pixel in position X Y
;Input B = column/X (0-127), C = row/Y (0-63)
;destroys HL
DRAW_PIXEL:
        LD A, C
        CP 40H
        RET NC
        LD A, B
        CP 80H
        RET NC
        
        PUSH DE
        CALL SET_GBUF

        LD A, D
        OR (HL)
        LD (HL), A
        POP DE
        RET

;Clear Pixel in position X Y
;Input B = column/X (0-127), C = row/Y (0-63)
;destroys HL
CLEAR_PIXEL:
        LD A, C
        CP 40H
        RET NC
        LD A, B
        CP 80H
        RET NC
        
        PUSH DE
        CALL SET_GBUF

        LD A, D
        CPL
        AND (HL)
        LD (HL), A
        POP DE
        RET

;Flip Pixel in position X Y
;Input B = column/X (0-127), C = row/Y (0-63)
;destroys HL
FLIP_PIXEL:
        LD A, C
        CP 40H
        RET NC
        LD A, B
        CP 80H
        RET NC
        
        PUSH DE
        CALL SET_GBUF

        LD A, D
        XOR (HL)
        LD (HL), A
        POP DE
        RET

;Helper routine to set HL to the correct GBUF address given X and Y
;Input B = column/X (0-127), C = row/Y (0-63)
;Output HL = address of GBUF X,Y byte, D = Byte with Pixel Bit Set
;Destroys E
SET_GBUF:
        LD L, C
        LD H, 00H
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        LD DE, (VPORT)
        DEC DE
        ADD HL, DE
        
        LD A, B
        LD D, 08H
BASE_COL:
        INC HL
        SUB D
        JR NC, BASE_COL
        
        CPL
        LD D, 01H
        OR A
        RET Z
SHIFT_BIT:
        SLA D
        DEC A
        JR NZ, SHIFT_BIT
        RET

;Main draw routine.  Moves GBUF to LCD and clears buffer
;Destroys all
PLOT_TO_LCD:
        LD HL, (VPORT)
        LD C, 80H
PLOT_ROW:
        LD A, C
        AND 9FH
        CALL LCD_INST           ;Vertical
        LD A, 80H
        BIT 5, C
        JR Z, $ + 4
        OR 08H
        CALL LCD_INST           ;Horizontal
        LD A, 02H 
        CALL SER_SYNC           ;Data Block Sync
        LD B, 10H               ;send eight double bytes (16 bytes)
PLOT_COLUMN:
        LD A, (HL)
        CALL LCD_DATA
        LD A, (CLRBUF)
        OR A
        JR Z, $ + 4
        LD (HL), 00H            ;Clear Buffer if CLRBUF is non zero
        INC HL
        DJNZ PLOT_COLUMN
        INC C
        BIT 6, C                ;Is Row = 64?
        JR Z, PLOT_ROW
        RET
        
; Print ASCII text on a given row
; Inputs: A = 0 to 3 Row Number
;         DB "String" on next line, terminate with 0
; EG:
;   LD A,2
;   CALL PRINT_STRING
;   DB "This Text",0
;
PRINT_STRING:
        LD B, A
        CALL SET_TXT_MODE
        LD HL, ROWS
        LD A, B
        ADD A, L
        JR NC, $ + 3
        INC H
        LD L, A
        LD A, (HL)
        CALL LCD_INST
        LD A, 02H 
        CALL SER_SYNC           ;Data Block Sync
        POP HL
DS_LOOP:
        LD A, (HL)
        INC HL
        OR A
        JR Z, DS_EXIT
        CALL LCD_DATA
        JR DS_LOOP
DS_EXIT:
        JP (HL)
        
;Print Characters at a position X,Y
;Eventhough there are 16 columns, only every second column can be written
;to and two characters are to be printed.  IE: if you want to print one
;character in column 2, then you must set B=0 and print " x", putting
;a space before the chracter.
;Input B = column/X (0-7), C = row/Y (0-3)
;      HL = Start address of text to display, terminate with 0
PRINT_CHARS:
        CALL SET_TXT_MODE
        LD DE, ROWS
        LD A, C
        ADD A, E
        JR NC, $ + 3
        INC D
        LD E, A
        LD A, (DE)
        ADD A, B
        CALL LCD_INST
        LD A, 02H 
        CALL SER_SYNC           ;Data Block Sync
PC_LOOP:
        LD A, (HL)
        INC HL
        OR A
        RET Z
        CALL LCD_DATA
        JR PC_LOOP
        
; Delay for LCD write
DELAY_US:
        LD DE, V_DELAY_US       ;DELAY BETWEEN, was 0010H
DELAY_MS:
        DEC DE                  ;EACH BYTE
        LD A, D                 ;AS PER
        OR E                    ;LCD MANUFACTER'S
        JR NZ, DELAY_MS         ;INSTRUCTIONS
        RET
        
; Set Buffer Clearing after outputting to LCD
; Input: A = 0 Buffer to be cleared, A <> 0 Buffer kept
SET_BUF_CLEAR:
        LD A, 0FFH
        LD (CLRBUF), A
        JP CLEAR_GBUF
        
SET_BUF_NO_CLEAR:
        XOR A
        LD (CLRBUF), A
        RET

;Initialise the GLCD Terminal
;Clears the GBUF, sets cursor to top left and displays cursor.
;This must be called prior to any Terminal routine.  This routine
;will as call INIT_LCD.
INIT_TERMINAL:
        LD HL,TGBUF              ;Reset VPORT and BUFF_TOP to TGBUF
        LD (VPORT),HL           ;to GBUF
        LD (TBUF),HL
        CALL INIT_LCD           ;Clear LCD GBUF
        LD BC,0000H
        CALL SET_CURSOR         ;Move cursor to top left
        JR DRAW_CURSOR          ;Draw Cursor and exit

;Send or handle ASCII characters to the GLCD screen.  This routines displays
;ASCII charcters to the GLCD screen and handles some special control characters
;It also handles srolling history of 10 lines.  Characters are drawn at the 
;current cursor position.  Cursor increments if characger is drawn.
;       CR / 0DH = will move the cursor down and reset it column
;       LF / 0AH = is ignored
;       FF / 0CH = clears the terminal (restarts)
;       BS / 08H = will delete the character at the cursor and move cursor back one
;       HT / 09H = will TAB 4 spaces
;       UP / 05H = will scroll up one line if any
;       DN / 06H = will scroll down one line if any
;Input: A = ASCII charcter to send to the GLCD screen.
;       A = 0  cursor drawn only
SEND_CHAR_TO_GLCD:
        ;Check for special characters
        OR A                    ;Zero?
        JR Z,DRAW_CURSOR
DO_SCRL_UP:
        CP UP                   ;Up Arrow
        JR NZ,DO_SCRL_DN
        XOR A
        CALL MOVE_VPORT
        JP PLOT_TO_LCD
DO_SCRL_DN:
        CP DN                   ;Down Arrow
        JR NZ,DO_CR
        LD A,1
        JR $-12                 ;Move VPORT above
DO_CR:
        ;Key is now a drawing character, reset VPORT first
        LD HL,TGBUF
        LD (VPORT),HL
        CP LF      ;LF
        RET Z
        CP CR      ;CR
        JR NZ,DO_FF
        LD A,SPACE              ;Clear Cursor
        CALL DRAW_GRAPHIC
        CALL INC_ROW
        LD (CURSOR_YS),A        ;Save start row
        JR DRAW_CURSOR
DO_FF:
        CP CS                   ;Form Feed / Clear Screen
        JR Z,INIT_TERMINAL      ;Reset All.
DO_BS:
        CP DEL                 ;Backspace BKSP
        JR NZ,DO_TAB
        LD A,SPACE              ;Space
        CALL DRAW_GRAPHIC
        CALL DEC_CURSOR
        JR DRAW_CURSOR
DO_TAB:
        CP TAB                  ;Horizontal Tab
        JR NZ,DO_CHAR
        LD A,SPACE              ;Space
        CALL DRAW_GRAPHIC
        CALL INC_CURSOR
        CALL INC_CURSOR
        CALL INC_CURSOR
        CALL INC_CURSOR
        JR DRAW_CURSOR
DO_CHAR:
        CALL DRAW_GRAPHIC
        CALL INC_CURSOR
DRAW_CURSOR:
        LD A,(CURSOR_ON)
        OR A
        LD A,SPACE              ;Space
        JR NZ,$+4               ;Skip cursor draw
        LD A,CURSOR             ;Cursor
        CALL DRAW_GRAPHIC
        JP PLOT_TO_LCD          ;Plot screen and exit



;Send a string of characters to the GLCD.  Prints a string pointed 
;by DE.  It stops printing and returns when either a CR is printed or
;when the next byte is the same as what is in register A
;Inputs: DE = address of string to print
;        A = character to stop printing.
;Destroy: All
SEND_STRING_TO_GLCD:
        LD B,A                  ;Save cp in B
PS1:
        LD A,(DE)               ;Get character
        INC DE                  ;Move pointer
        CP B                    ;Same as B?
        JR Z,DRAW_CURSOR        ;Yes exit and plot LCD screen
        CP CR                   ;Is it a CR?
        JR Z,DO_CR              ;Yes do a CR and plot LCD screen and exit
        CP CS                   ;Is it a FF?
        JR Z,DO_FF              ;Yes do a Form Feed and plot LCD screen and exit
        EXX                     ;Save bulk registers
        CALL DRAW_GRAPHIC       ;Draw the character
        CALL INC_CURSOR         ;Move cursor by one
        EXX                     ;Restore bulk registers
        JR PS1                  ;Repeat for next character
        RET     

;Display the register A in ASCII on the GLCD
;Input: A = value to convert and display
SEND_A_TO_GLCD:
        CALL DRAW_A             ;Do the conversion
        JR DRAW_CURSOR          ;exit and plot LCD screen
DRAW_A:
        PUSH AF                 ;Save AF
        RRCA                    ;move high
        RRCA                    ;nibble to low nibble
        RRCA
        RRCA
        CALL NIBBLE_TO_GLCD     ;Convert and display
        POP AF                  ;Restore AF
NIBBLE_TO_GLCD:
        AND 0FH                 ;mask out high nibble
        ADD A,90H               ;convert to 
        DAA                     ;ASCII
        ADC A,40H               ;using this
        DAA                     ;amazing routine
        CALL DRAW_GRAPHIC       ;Draw the character
        CALL INC_CURSOR         ;Move cursor by one
        RET

;Display the register HL in ASCII on the GLCD
;Input: HL = value to convert and display
SEND_HL_TO_GLCD:
        PUSH HL                 ;Save HL
        LD A,H                  ;get H
        CALL DRAW_A             ;Do the conversion
        POP HL
        LD A,L                  ;get L
        CALL DRAW_A             ;Do the conversion
        JR DRAW_CURSOR          ;exit and plot LCD screen

;Set the Graphic cursor position
;Inputs: BC = X,Y where X = 0..127, Y = 0..63
;Ignores update if one of the X,Y values are out of range
;Destroys: A
SET_CURSOR:
        ;Check range. Exit if X,Y out of range
        LD A, C
        CP 40H
        RET NC
        LD A, B
        CP 80H
        RET NC
        ;Set Cursor and initial start row
        LD (CURSOR_XY),BC       ;Save cursor
        LD A,C
        LD (CURSOR_YS),A        ;And initial Y Start
        RET

;Increment the cursor by one font character
;A Font Character is 6x6 Pixels.  Move column 6 across until it can't then reset
;column back to 0 and move 6 down.
;If can't go down any further then keep on last row but move column back to 0
;Font Characters maximum 20 across and 10 down
;Output: Carry Set = No screen overflow
;Destroys: A
INC_CURSOR:
        LD A,(CURSOR_X)         ;Get X
        ADD A,6                 ;Add 6
        CP 126                  ;Is it >= 126?
        JR NC,INC_ROW           ;Yes, reset column and increment row
        LD (CURSOR_X),A         ;Save new column
        RET
INC_ROW:
        XOR A
        LD (CURSOR_X),A         ;reset column to 0
        LD A,(CURSOR_Y)         ;get row
        ADD A,6                 ;Add 6
        CP 60                   ;Is it >= 60
        JR C,SAVE_ROW           ;No, save new row
        PUSH AF
        CALL SHIFT_BUFFER       ;Shift buffer up one row
        POP AF
        SUB 6                   ;overflow, just leave the same
SAVE_ROW:
        LD (CURSOR_Y),A         ;Save new row
        RET

;Shift the graphics buffer (GBUF) into the scroll buffer (SBUF) by
;one row (6 lines).  Move the top buffer address to the new top of 
;the scroll buffer
SHIFT_BUFFER:
        ;Check if anymore buffer left
        LD HL,(TBUF)        ;Get top buffer address
        LD DE,TGBUF-SBUF    ;Get scroll buffer address
        OR A                ;Clear carry
        SBC HL,DE           ;TBUF-SBUF
        JR Z,SKIP_TBUF
        ADD HL,DE           ;restore HL
        LD DE,16*6          ;Six pixel rows
        SBC HL,DE           ;Move TBUF down by 6 rows
        LD (TBUF),HL        ;Save new TBUF
SKIP_TBUF:
        LD HL,TGBUF-SBUF+(16*6) ;Top of scroll buffer less one row
        LD DE,TGBUF-SBUF    ;Top of scroll buffer
        LD BC,16*6*29       ;19 rows (change to 20 lines 19 to 29 (+10)) Z80 Mini
        LDIR
        LD HL,TGBUF+0360H   ;clear last row (9*16)
        LD DE,TGBUF+0361H
        LD BC,5FH
        XOR A
        LD (HL),A
        LDIR
        ;Move Y Start up one row
        LD A,(CURSOR_YS)    ;Get Y Start row
        SUB 6
        RET C               ;Ignore if less than zero
        LD (CURSOR_YS),A    
        RET

;Move the VPORT vertically between TBUF and end of GBUB.  VPORT will be 
;shifted by a standard termial row of 6 lines.
;input: A = 0 shift up else shift down
MOVE_VPORT:
        LD HL,(VPORT)       ;get viewport
        EX DE,HL
        OR A                ;check move
        JR NZ,MOVE_DOWN     ;shift down
MOVE_UP:
        LD HL,(TBUF)        ;get top of buffer
        SBC HL,DE           ;
        RET Z               ;if the same, then at top already
        LD HL,0-60H         ;one row up 60
SAVE_VPORT:
        ADD HL,DE           ;get new VPORT value
        LD (VPORT),HL
        RET
MOVE_DOWN:
        LD HL,TGBUF         ;get top of graphics buffer
        SBC HL,DE           ;
        RET Z               ;if the same, then at top already
        LD HL,60H           ;one row down 60
        JR SAVE_VPORT

;Decrement the cursor by one font character up to the current row start
;Used to help with Backspace character or left arrow?
;Destroys: A
DEC_CURSOR:
        LD A,(CURSOR_X)         ;Get X
        SUB 6                   ;subract 6
SAVE_COL:
        LD (CURSOR_X),A         ;Save new column
        ;if < 0 then just make 0 or 20 depending on Y Start
        RET NC
        PUSH BC
        LD A,(CURSOR_YS)        ;Get Y Start
        LD B,A
        LD A,(CURSOR_Y)         ;Get Y
        SUB B
        POP BC
        LD A,0                  ;reset to 0
        JR Z,SAVE_COL
        LD A,6*20               ;last column 20
        LD (CURSOR_X),A         ;Save new column
        LD A,(CURSOR_Y)
        SUB 6                   ;move row one line up
        LD (CURSOR_Y),A         ;Save new row
        RET

;Get cursor position
;Outputs: BC = X,Y where X = 0..127, Y = 0..63
GET_CURSOR:
        LD BC,(CURSOR_XY)
        RET

;Display Cursor
;Input: A = 0, Turn cursor on, A = non zero, Turn cursor off
;Default is Cursor ON
DISPLAY_CURSOR:
        LD (CURSOR_ON),A
        RET

;Inverse Graphic Drawing
;Initial state is normal.  Calling this routine will TOGGLE the inverse drawing flag
;Destroys: A
INV_GRAPHIC:
        LD A,(INVERSE)
        CPL                 ;flip bits
        LD (INVERSE),A
        RET

;Draw Graphic at the current cursor.  Draw either an ASCII character or
;a custom sprite/picture
;Input: A = ASCII number or 
;    if A=0 Then 
;       HL = Address of graphic data
;       B = width of graphic in pixels (1-128)
;       C = height of graphic in pixels (1-64)
;Destroys: All
DRAW_GRAPHIC:
        OR A                ;is A=0
        JR Z,PLOT_GRAPHIC   ;yes, use data pointing to HL
        ;Use internal font table and index it to value in A
        DEC A               ;fix for A = 0..255
        LD H,0
        LD L,A
        ADD HL,HL           ;Multipy A by 2
        LD D,H
        LD E,L              ;Save in DE
        ADD HL,HL           ;Multipy A by 4
        ADD HL,DE           ;Multiply by 6
        LD DE,FONT_DATA     ;Font Table
        ADD HL,DE           ;Add index (A*8) to HL
        LD BC,0606H         ;Six pixels across, Six pixels down
PLOT_GRAPHIC:
        LD D,B              ;D=Column pixel count
        LD A,D
        LD (PIXEL_X),A      ;Save original pixel length
        LD E,C              ;E=Row pixel count
        LD BC,(CURSOR_XY)   ;Get graphics cursor position
PLOT_BYTE:
        LD A,D              ;Get column bit count
        SUB 8
        LD D,A
        PUSH DE        
        LD D,8
        LD E,(HL)           ;get pixel data
        JR NC,INV_BIT
        ADD A,D             ;Restore column bit count
        LD D,A
        LD A,D
        ;D = Rotate adjust count
        RRC E               ;rotate it to get first bit in bit 7
        DEC D
        JR NZ,$-3
        LD D,A              ;reset D to actual bit count
INV_BIT:
        LD A, 0      ;check inverse flag
        XOR E               ;flip bits
        LD E,A              ;save new data
PLOT_BIT:
        RLC E
        PUSH HL
        JR NC,REMOVE_PIXEL
        CALL DRAW_PIXEL
        JR $+5
REMOVE_PIXEL:
        CALL CLEAR_PIXEL
        POP HL
        INC B               ;move X to the right by one
        DEC D
        JR NZ,PLOT_BIT
        ;All bits are plotted check if D <= 0
        INC HL              ;move to next pixel byte
        POP DE              ;restore Column/Row bit count
        LD A,D
        OR A                ;check for zero or lessor
        JR Z,$+5
        JP P,PLOT_BYTE      ;its greater or zero, do next byte
        ;Move down a row and set column to the start
        DEC E               ;move column pixel count down by one
        RET Z               ;if its zero no more to do, just exit
        INC C               ;move down a row
        LD A,(CURSOR_X)
        LD B,A              ;reset column
        LD A,(PIXEL_X)
        LD D,A              ;reset pixel length per row
        JR PLOT_BYTE

;Serial/Paralled Communication routines
;Send information to the LCD screen via SERIAL or PARALLEL connection.  Parallel is straight
;forward.  Just send the Byte in the Accumilator to the relevante Instruction or Data port.
;Then call a delay for that byte to be processed by the LCD.
;For Serial communication, three Bytes are to be sent using the SPI protocol.
;The first byte is a synchronise/configuration byte.  This sets
;the Data/Instruction register bit.  The second and third bytes is the actual data to send.
;It is split into two bytes with 4 bits of data set at the upper nibble and zeros for the rest.
;A maximum of 256 Bytes of Data information can be send with only one Synchronise Byte.  The
;LCD Data routine doesn't send the sync byte.  It needs to be done prior by calling SER_SYNC first.
;
;The two routines to use are:
;LCD_DATA, Sends Data information.  Along with SER_SYNC called prior and
;LCD_INST, Sends Instruction information

;Send to LCD Instruction register
;If serial connection it will send the byte with a synchronise byte.
;If parallel byte is sent to the Instruction register port and a delay is triggered
;Input: A = Byte to send
LCD_INST:
;IF COMMS_MODE
;        PUSH AF
;        XOR A
;        CALL SER_SYNC
;        POP AF
;        JP SER_BYTE
;ELSE
        OUT (LCD_IR), A
        JP DELAY_US
;ENDIF

;Send to LCD Data register
;If serial connection it will send the byte with no synchronise byte.  The
;synchronise byte is to be sent separately.
;If parallel byte is sent to the Data register port and a delay is triggered
;Input: A = Byte to send
LCD_DATA:
;IF COMMS_MODE
;        JP SER_BYTE
;ELSE
        OUT (LCD_DR), A
        JP DELAY_US
;ENDIF

;Serial Byte Send
;Send a Byte in two halfs,  First half is the upper nibble with 4 zeros and second
;byte is the lower nibble shifted to the upper nibble with 4 zeros.
;   EG: if Byte to send is 10010110B, then
;   BYTE 1 = 10010000b and
;   BYTE 2 = 01100000b
;Input: A = byte to send
SER_BYTE:
        PUSH AF
        CALL SEND_PART
        POP AF
        RLCA
        RLCA
        RLCA
        RLCA
SEND_PART:
        AND 0F0H                ;Mask out lower nibble
        JP SPI_WR               ;Send First Half of Command/Data byte

;Serial Synchronise Byte
;Send 5 consecutive '1's then '000's for instruction or '010' for data.
;Input: A = 0x00 for instruction register and 0x02 if data register
SER_SYNC:
;IF COMMS_MODE
;        OR SER_BT
;ELSE
        RET
;ENDIF

;SPI Write Routine.
;Send a byte to the LCD using the SPI protocol
;Inputs: A = Byte to be sent
SPI_WR:
        PUSH BC
        LD B, 08H       ;Eight Bits to send
        LD C, A         ;SPI Byte
        XOR A           ;Clear A
CLK_LOOP:
        RLC C           ;Put Bit 7 in Carry Flag
        ADC A,A         ;Set Bit 0 with Carry Flag
        OR 02H          ;Set SCLK high (pulse clock)
        OUT (LCD_SER),A ;Output to LCD
        XOR A           ;Set SCLK low (and SID)
        OUT (LCD_SER),A ;Output to LCD
        DJNZ CLK_LOOP   ;Get next Bit
        POP BC
        RET

; Contstants
ROWS:   DB      80H,90H,88H,98H ;Text Row start position
        
INIT_BASIC:
        DB  30H
        DB  20H
        DB  30H
        DB  0CH
        DB  01H
        DB  02H
        ;fim




        DB      30H             ;8 Bit interface, basic instruction
        DB      0CH             ;display on, cursor & blink off
        DB      06H             ;cursor move to right ,no shift
        DB      01H             ;clear RAM

;General Graphic Data
;Byte 1 = X pixel length, Byte 2 = Y pixel length
;Byte n = Pixel data where bits represent pixels.  Read from LSB
FONT_DATA:
        ;001
        DB 00011110b   ;  ####
        DB 00100001b   ; #    #
        DB 00100001b   ; #    #
        DB 00100001b   ; #    #
        DB 00100001b   ; #    #
        DB 00011110b   ;  ####
        ;002
        DB 00011110b   ;  ####
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00011110b   ;  ####
        ;003 Up Arrow
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00111111b   ; ######
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;004 Down Arrow
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00111111b   ; ######
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        ;005 Left Arrow
        DB 00001000b   ;   #
        DB 00011000b   ;  ##
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00011000b   ;  ##
        DB 00001000b   ;   #
        ;006 Right Arrow
        DB 00000100b   ;    #
        DB 00000110b   ;    ##
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00000110b   ;    ##
        DB 00000100b   ;    #
        ;007 Up Hat
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00111111b   ; ######
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;008 Down Hat
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00111111b   ; ######
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        ;009 Left Hat
        DB 00001000b   ;   #
        DB 00011000b   ;  ##
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00011000b   ;  ##
        DB 00001000b   ;   #
        ;010 Right Hat
        DB 00000100b   ;    #
        DB 00000110b   ;    ##
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000110b   ;    ##
        DB 00000100b   ;    #
        ;011 Note 1
        DB 00000100b   ;    #
        DB 00000100b   ;    # 
        DB 00000100b   ;    # 
        DB 00011100b   ;  ###
        DB 00111100b   ; ####
        DB 00011000b   ;  ##
        ;012 Note 2
        DB 00000100b   ;    #
        DB 00000110b   ;    ## 
        DB 00000101b   ;    # #
        DB 00011100b   ;  ###
        DB 00111100b   ; ####
        DB 00011000b   ;  ##
        ;013 Rocket
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00110011b   ; ##  ##
        ;014 Bomb
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00011110b   ;  ####
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        ;015 Explosion
        DB 00001100b   ;   ##
        DB 00111111b   ; ######
        DB 00000110b   ;    ##
        DB 00001100b   ;   ##
        DB 00011000b   ;  ##
        DB 00001100b   ;   ##
        ;016
        DB 00110110b   ; ## ##
        DB 00100100b   ; #  #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;017
        DB 00110110b   ; ## ##
        DB 00010010b   ;  #  #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;018
        DB 00001110b   ;   ###
        DB 00010010b   ;  #  #
        DB 00111000b   ; ###
        DB 00010010b   ;  #  #
        DB 00111110b   ; #####
        DB 00000000b   ;
        ;019
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00101010b   ; # # #
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;020
        DB 00111110b   ; #####
        DB 00110100b   ; ## #
        DB 00110100b   ; ## #
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00000000b   ;
        ;021
        DB 00011100b   ;  ###
        DB 00011000b   ;  ##
        DB 00100100b   ; #  #
        DB 00011000b   ;  ##
        DB 00111000b   ; ###
        DB 00000000b   ;
        ;022
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00000010b   ;     #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;023
        DB 00010100b   ;  # #
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;024
        DB 00010100b   ;  # #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00011100b   ;  ###
        DB 00100010b   ; #   # 
        DB 00000000b   ;
        ;025
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00011000b   ;  ##
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;026
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;027
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00111110b   ; #####
        DB 00000110b   ;    ##
        DB 00000110b   ;    ##
        DB 00000000b   ;
        ;028
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00111110b   ; #####
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;029
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00111110b   ; #####
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;030
        DB 00010100b   ;  # #
        DB 00111110b   ; #####
        DB 00111110b   ; #####
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;031
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00111110b   ; #####
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;032 Space
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;033 !
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;034 "
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;035 #
        DB 00010100b   ;  # #
        DB 00111110b   ; #####
        DB 00010100b   ;  # #
        DB 00111110b   ; #####
        DB 00010100b   ;  # #
        DB 00000000b   ;
        ;036 $
        DB 00011110b   ;  ####
        DB 00101000b   ; # #
        DB 00011100b   ;  ###
        DB 00001010b   ;   # #
        DB 00111100b   ; ####
        DB 00000000b   ;
        ;037 %
        DB 00110010b   ; ##  #
        DB 00110100b   ; ## #
        DB 00001000b   ;   #
        DB 00010110b   ;  # ##
        DB 00100110b   ; #  ##
        DB 00000000b   ;
        ;038 &
        DB 00011000b   ;  ##
        DB 00100100b   ; #  #
        DB 00011010b   ;  ## #
        DB 00100100b   ; #  #
        DB 00011010b   ;  ## #
        DB 00000000b   ;
        ;039 '
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;040 (
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00000000b   ;
        ;041 )
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;042 *
        DB 00101010b   ; # # #
        DB 00011100b   ;  ###
        DB 00111110b   ; #####
        DB 00011100b   ;  ###
        DB 00101010b   ; # # #
        DB 00000000b   ;
        ;043 +
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00000000b   ;
        ;044 ,
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;045 -
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00011100b   ;  ###
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;046 .
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;047 /
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;048 0
        DB 00011100b   ;  ###
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;049 1
        DB 00001000b   ;   #
        DB 00011000b   ;  ##
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;050 2
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00011100b   ;  ###
        DB 00010000b   ;  #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;051 3
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00001100b   ;   ##
        DB 00000100b   ;    #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;052 4
        DB 00010000b   ;  #
        DB 00010000b   ;  #
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00000000b   ;
        ;053 5
        DB 00011100b   ;  ###
        DB 00010000b   ;  #
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;054 6
        DB 00011000b   ;  ##
        DB 00010000b   ;  #
        DB 00011100b   ;  ###
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;055 7
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;056 8
        DB 00011100b   ;  ###
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;057 9
        DB 00011100b   ;  ###
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000100b   ;    #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;058 :
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00000000b   ;
        ;059 ;
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;060 <
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00000000b   ;
        ;061 =
        DB 00000000b   ;
        DB 00011100b   ;  ###
        DB 00000000b   ;
        DB 00011100b   ;  ###
        DB 00000000b   ;
        DB 00000000b   ;
        ;062 >
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00000000b   ;
        ;063 ?
        DB 00011100b   ;  ###
        DB 00100010b   ; #   # 
        DB 00001100b   ;   ##
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;064 @
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100110b   ; #  ##
        DB 00101010b   ; # # # 
        DB 00001100b   ;   ##
        DB 00000000b   ;
        ;065 A
        DB 00011000b   ;  ##
        DB 00100100b   ; #  #
        DB 00100010b   ; #   #
        DB 00111110b   ; #####
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;066 B
        DB 00111000b   ; ###
        DB 00100100b   ; #  #
        DB 00111100b   ; ####
        DB 00100010b   ; #   #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;067 C
        DB 00011100b   ;  ###
        DB 00100010b   ; #   # 
        DB 00100000b   ; #
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;068 D
        DB 00111100b   ; ####
        DB 00100110b   ; #  ##
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00111100b   ; ####
        DB 00000000b   ;
        ;069 E
        DB 00111110b   ; #####
        DB 00100000b   ; #
        DB 00111100b   ; ####
        DB 00100000b   ; #
        DB 00111110b   ; #####
        DB 00000000b   ;
        ;070 F
        DB 00111110b   ; #####
        DB 00100000b   ; #
        DB 00111100b   ; ####
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00000000b   ;
        ;071 G
        DB 00011100b   ;  ###
        DB 00100000b   ; #    
        DB 00100110b   ; #  ##
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;072 H
        DB 00100100b   ; #  #
        DB 00100010b   ; #   #
        DB 00111110b   ; #####
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00000000b   ;
        ;073 I
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;074 J
        DB 00001100b   ;   ##
        DB 00000100b   ;    #
        DB 00000100b   ;    #
        DB 00010100b   ;  # #
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;075 K
        DB 00100100b   ; #  #
        DB 00101000b   ; # #
        DB 00110000b   ; ##
        DB 00101000b   ; # #
        DB 00100100b   ; #  #
        DB 00000000b   ;
        ;076 L
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;077 M
        DB 00100010b   ; #   #
        DB 00110110b   ; ## ##
        DB 00101010b   ; # # #
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;078 N
        DB 00100010b   ; #   #
        DB 00110010b   ; ##  #
        DB 00101010b   ; # # #
        DB 00100110b   ; #  ##
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;079 O
        DB 00011100b   ;  ###
        DB 00100110b   ; #  ## 
        DB 00100010b   ; #   #
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;080 P
        DB 00111000b   ; ###
        DB 00100100b   ; #  #
        DB 00111000b   ; ###
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00000000b   ; 
        ;081 Q
        DB 00011100b   ;  ###
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   #
        DB 00100110b   ; #  ## 
        DB 00011110b   ;  ####
        DB 00000000b   ; 
        ;082 R
        DB 00111000b   ; ###
        DB 00100100b   ; #  #
        DB 00111000b   ; ###
        DB 00101000b   ; # #
        DB 00100100b   ; #  #
        DB 00000000b   ; 
        ;083 S
        DB 00011110b   ;  ####
        DB 00100000b   ; #
        DB 00011100b   ;  ###
        DB 00000010b   ;     #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;084 T
        DB 00111110b   ; #####
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;085 U
        DB 00100100b   ; #  #
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;086 V
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;087 W
        DB 00100100b   ; #  #
        DB 00100010b   ; #   #
        DB 00101010b   ; # # #
        DB 00101010b   ; # # #
        DB 00010100b   ;  # #
        DB 00000000b   ; 
        ;088 X
        DB 00100010b   ; #   #
        DB 00010100b   ;  # #
        DB 00001000b   ;   #
        DB 00010100b   ;  # #
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;089 Y
        DB 00100010b   ; #   #
        DB 00010100b   ;  # #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;090 Z
        DB 00111110b   ; #####
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00111110b   ; #####
        DB 00000000b   ; 
        ;091 [
        DB 00001100b   ;   ##
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001100b   ;   ##
        DB 00000000b   ; 
        ;092 \
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00000000b   ; 
        ;093 ]
        DB 00011000b   ;  ##
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00011000b   ;  ##
        DB 00000000b   ; 
        ;094 ^
        DB 00001000b   ;   #
        DB 00010100b   ;  # #
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;095 _
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111110b   ; #####
        DB 00000000b   ; 
        ;096 `
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        DB 00000000b   ;
        ;097 a
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100110b   ; #  ##
        DB 00011010b   ;  ## #
        DB 00000000b   ; 
        ;098 b
        DB 00100000b   ; #
        DB 00111100b   ; ####
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;099 c
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00100000b   ; #   
        DB 00100000b   ; #   
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;100 d
        DB 00000010b   ;     #
        DB 00011110b   ;  ####
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00011110b   ;  ####
        DB 00000000b   ; 
        ;101 e
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00111100b   ; ####
        DB 00100000b   ; #
        DB 00011110b   ;  ####
        DB 00000000b   ; 
        ;102 f
        DB 00001110b   ;   ###
        DB 00010000b   ;  # 
        DB 00111100b   ; ####
        DB 00010000b   ;  # 
        DB 00010000b   ;  # 
        DB 00000000b   ; 
        ;103 g
        DB 00011110b   ;  ####
        DB 00100010b   ; #   #
        DB 00011110b   ;  ####
        DB 00000010b   ;     #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;104 h
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00111100b   ; ####
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;105 i
        DB 00001000b   ;   #
        DB 00000000b   ; 
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;106 j
        DB 00000100b   ;    # 
        DB 00000000b   ; 
        DB 00000100b   ;    # 
        DB 00000100b   ;    # 
        DB 00011000b   ;  ##
        DB 00000000b   ; 
        ;107 k
        DB 00100000b   ; #
        DB 00100100b   ; #  #
        DB 00101000b   ; # #
        DB 00110100b   ; ## #
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;108 l
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00001100b   ;   ##
        DB 00000000b   ; 
        ;109 m
        DB 00000000b   ; 
        DB 00010100b   ;  # #
        DB 00101010b   ; # # #
        DB 00101010b   ; # # #
        DB 00101010b   ; # # #
        DB 00000000b   ; 
        ;110 n
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;111 o
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;112 p
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00111100b   ; ####
        DB 00100000b   ; #
        DB 00000000b   ; 
        ;113 q
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00011110b   ;  ####
        DB 00000010b   ;     #
        DB 00000000b   ; 
        ;114 r
        DB 00000000b   ; 
        DB 00101100b   ; # ##
        DB 00110000b   ; ##
        DB 00100000b   ; #
        DB 00100000b   ; #
        DB 00000000b   ; 
        ;115 s
        DB 00011100b   ;  ###
        DB 00100000b   ; #
        DB 00011100b   ;  ###
        DB 00000010b   ;     #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;116 t
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00000000b   ; 
        ;117 u
        DB 00000000b   ; 
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;118 v
        DB 00000000b   ; 
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   # 
        DB 00010100b   ;  # # 
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;119 w
        DB 00000000b   ; 
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   # 
        DB 00101010b   ; # # # 
        DB 00110110b   ; ## ##
        DB 00000000b   ; 
        ;120 x
        DB 00000000b   ; 
        DB 00100010b   ; #   # 
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00100010b   ; #   # 
        DB 00000000b   ; 
        ;121 y
        DB 00100010b   ; #   # 
        DB 00100010b   ; #   # 
        DB 00011110b   ;  ####
        DB 00000010b   ;     #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;122 z
        DB 00000000b   ; 
        DB 00111100b   ; #### 
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00111100b   ; #### 
        DB 00000000b   ; 
        ;123 {
        DB 00001100b   ;   ##
        DB 00001000b   ;   #
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00001100b   ;   ##
        DB 00000000b   ; 
        ;124 |
        DB 00001000b   ;   # 
        DB 00001000b   ;   # 
        DB 00001000b   ;   # 
        DB 00001000b   ;   # 
        DB 00001000b   ;   # 
        DB 00000000b   ; 
        ;125 }
        DB 00011000b   ;  ##
        DB 00001000b   ;   #
        DB 00000100b   ;    #
        DB 00001000b   ;   #
        DB 00011000b   ;  ##
        DB 00000000b   ; 
        ;126 ~
        DB 00010100b   ;  # #
        DB 00101000b   ; # #
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;127 
        DB 00101010b   ; # # #
        DB 00010101b   ;  # # #
        DB 00101010b   ; # # #
        DB 00010101b   ;  # # #
        DB 00101010b   ; # # #
        DB 00010101b   ;  # # #
        ;128
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;129
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;130
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;131
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;132
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        ;133
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        ;134
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        ;135
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        ;136
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        ;137
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        ;138
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        ;139
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        ;140
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        ;141
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        ;142
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00000111b   ;    ###
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        ;143
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        ;144
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;145
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;146
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00001111b   ;   ####
        DB 00001111b   ;   ####
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;147
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001111b   ;   ####
        DB 00000111b   ;    ###
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;148
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;149
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;150
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000111b   ;    ###
        DB 00001111b   ;   ####
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;151
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00001111b   ;   ####
        DB 00001111b   ;   ####
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;152
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111100b   ; ####
        DB 00111100b   ; ####
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;153
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00111100b   ; ####
        DB 00111000b   ; ###
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;154
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;155
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;156
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111000b   ; ###
        DB 00111100b   ; ####
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;157
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00111100b   ; ####
        DB 00111100b   ; ####
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;158
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;159
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00111111b   ; ######
        DB 00111111b   ; ######
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        ;160
        DB 00000000b   ; 
        DB 00010010b   ;  #  #
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00010010b   ;  #  #
        DB 00000000b   ; 
        ;161
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;162
        DB 00000000b   ; 
        DB 00001111b   ;   ####
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00001111b   ;   ####
        DB 00000000b   ; 
        ;163
        DB 00010010b   ;  #  #
        DB 00010011b   ;  #  ##
        DB 00010000b   ;  #
        DB 00010000b   ;  #
        DB 00001111b   ;   ####
        DB 00000000b   ; 
        ;164
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        ;165
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        DB 00010010b   ;  #  #
        ;166
        DB 00000000b   ; 
        DB 00001111b   ;   ####
        DB 00010000b   ;  #
        DB 00010000b   ;  #
        DB 00010011b   ;  #  ##
        DB 00010010b   ;  #  #
        ;167
        DB 00010010b   ;  #  #
        DB 00010011b   ;  #  ##
        DB 00010000b   ;  #
        DB 00010000b   ;  #
        DB 00010011b   ;  #  ##
        DB 00010010b   ;  #  #
        ;168
        DB 00000000b   ; 
        DB 00111100b   ; ####
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;169
        DB 00010010b   ;  #  #
        DB 00110010b   ; ##  #
        DB 00000010b   ;     #
        DB 00000010b   ;     #
        DB 00111100b   ; ####
        DB 00000000b   ; 
        ;170
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00000000b   ; 
        ;171
        DB 00010010b   ;  #  #
        DB 00110011b   ; ##  ##
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00000000b   ; 
        ;172
        DB 00000000b   ; 
        DB 00111100b   ; ####
        DB 00000010b   ;     #
        DB 00000010b   ;     #
        DB 00110010b   ; ##  #
        DB 00010010b   ;  #  #
        ;173
        DB 00010010b   ;  #  #
        DB 00110010b   ; ##  #
        DB 00000010b   ;     #
        DB 00000010b   ;     #
        DB 00110010b   ; ##  #
        DB 00010010b   ;  #  #
        ;174
        DB 00000000b   ; 
        DB 00111111b   ; ######
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00110011b   ; ##  ##
        DB 00010010b   ;  #  #
        ;175
        DB 00010010b   ;  #  #
        DB 00110011b   ; ##  ##
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00110011b   ; ##  ##
        DB 00010010b   ;  #  #
        ;176
        DB 00001100b   ;   ##
        DB 00011000b   ;  ##
        DB 00110000b   ; ##
        DB 00100000b   ; #
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;177
        DB 00001100b   ;   ##
        DB 00000110b   ;    ##
        DB 00000011b   ;     ##
        DB 00000001b   ;      #
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;178
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000001b   ;      #
        DB 00000011b   ;     ##
        DB 00000110b   ;    ##
        DB 00001100b   ;   ##
        ;179
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00100000b   ; #
        DB 00110000b   ; ##
        DB 00011000b   ;  ##
        DB 00001100b   ;   ##
        ;180
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00110011b   ; ##  ##
        DB 00100001b   ; #    # 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;181
        DB 00001100b   ;   ##
        DB 00000110b   ;    ##
        DB 00000011b   ;     ##
        DB 00000011b   ;     ##
        DB 00000110b   ;    ##
        DB 00001100b   ;   ##
        ;182
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00100001b   ; #    # 
        DB 00110011b   ; ##  ##
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        ;183
        DB 00001100b   ;   ##
        DB 00011000b   ;  ##
        DB 00110000b   ; ##
        DB 00110000b   ; ##
        DB 00011000b   ;  ##
        DB 00001100b   ;   ##
        ;184
        DB 00001100b   ;   ##
        DB 00011000b   ;  ##
        DB 00110001b   ; ##   #
        DB 00100011b   ; #   ##
        DB 00000110b   ;    ##
        DB 00001100b   ;   ##
        ;185
        DB 00001100b   ;   ##
        DB 00000110b   ;    ##
        DB 00100011b   ; #   ##
        DB 00110001b   ; ##   #
        DB 00011000b   ;  ##
        DB 00001100b   ;   ##
        ;186
        DB 00001100b   ;   ##
        DB 00011110b   ;  ####
        DB 00110011b   ; ##  ##
        DB 00110011b   ; ##  ##
        DB 00011110b   ;  ####
        DB 00001100b   ;   ##
        ;187
        DB 00110011b   ; ##  ##
        DB 00110011b   ; ##  ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00110011b   ; ##  ##
        DB 00110011b   ; ##  ##
        ;188
        DB 00000011b   ;     ##
        DB 00000011b   ;     ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00110000b   ; ##
        DB 00110000b   ; ##
        ;189
        DB 00110000b   ; ##
        DB 00110000b   ; ##
        DB 00001100b   ;   ##
        DB 00001100b   ;   ##
        DB 00000011b   ;     ##
        DB 00000011b   ;     ##
        ;190
        DB 00101010b   ; # # #
        DB 00010100b   ;  # #
        DB 00101010b   ; # # #
        DB 00010100b   ;  # #
        DB 00101010b   ; # # #
        DB 00000000b   ; 
        ;191
        DB 00010100b   ;  # #
        DB 00101010b   ; # # #
        DB 00010100b   ;  # #
        DB 00101010b   ; # # #
        DB 00010100b   ;  # #
        DB 00000000b   ; 
        ;192
        DB 00000000b   ; 
        DB 00011010b   ;  ## #
        DB 00100100b   ; #  #
        DB 00100100b   ; #  #
        DB 00011010b   ;  ## #
        DB 00000000b   ; 
        ;193
        DB 00011000b   ;  ##
        DB 00100100b   ; #  #
        DB 00101100b   ; # ##
        DB 00100010b   ; #   #
        DB 00101100b   ; # ##
        DB 00000000b   ; 
        ;194
        DB 00000000b   ; 
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;195
        DB 00011100b   ;  ###
        DB 00110000b   ; ##
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00011100b   ;  ### 
        DB 00000000b   ; 
        ;196
        DB 00001110b   ;   ### 
        DB 00110000b   ; ##
        DB 00111100b   ; ####
        DB 00110000b   ; ##
        DB 00001110b   ;   ###
        DB 00000000b   ; 
        ;197
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00111110b   ; #####
        DB 00100010b   ; #   #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;198
        DB 00100000b   ; #
        DB 00010000b   ;  #
        DB 00001000b   ;   #
        DB 00010100b   ;  # #
        DB 00100010b   ; #   # 
        DB 00000000b   ; 
        ;199
        DB 00100100b   ; #  #
        DB 00100100b   ; #  #
        DB 00111000b   ; ###
        DB 00100000b   ; #
        DB 00100000b   ; # 
        DB 00000000b   ; 
        ;200
        DB 00000000b   ; 
        DB 00111110b   ; #####
        DB 00010100b   ;  # #
        DB 00010100b   ;  # #
        DB 00100100b   ; #  #
        DB 00000000b   ; 
        ;201
        DB 00000000b   ; 
        DB 00011110b   ;  ####
        DB 00110100b   ; ## #
        DB 00110100b   ; ## #
        DB 00011000b   ;  ##
        DB 00000000b   ; 
        ;202
        DB 00000110b   ;    ##
        DB 00011100b   ;  ###
        DB 00110110b   ; ## ##
        DB 00011100b   ;  ###
        DB 00110000b   ; ##
        DB 00000000b   ; 
        ;203
        DB 00000110b   ;    ##
        DB 00000100b   ;    #
        DB 00110110b   ; ## ##
        DB 00011100b   ;  ###
        DB 00110000b   ; ##
        DB 00000000b   ; 
        ;204
        DB 00110010b   ; ##  #
        DB 00011100b   ;  ###
        DB 00001100b   ;   ##
        DB 00010110b   ;  # ##
        DB 00100010b   ; #   #
        DB 00000000b   ; 
        ;205
        DB 00000000b   ; 
        DB 00010100b   ;  # #
        DB 00100010b   ; #   #
        DB 00101010b   ; # # #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;206
        DB 00111110b   ; #####
        DB 00010010b   ;  #  #
        DB 00001000b   ;   #
        DB 00010010b   ;  #  #
        DB 00111110b   ; #####
        DB 00000000b   ; 
        ;207
        DB 00011100b   ;  ###
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00010100b   ;  # #
        DB 00110110b   ; ## ##
        DB 00000000b   ; 
        ;208
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00001010b   ;   # #
        DB 00011100b   ;  ###
        DB 00101000b   ; # #
        DB 00001000b   ;   #
        ;209
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00101000b   ; # #
        DB 00011100b   ;  ###
        DB 00001010b   ;   # #
        DB 00001000b   ;   #
        ;210
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00101010b   ; # # #
        DB 00011100b   ;  ###
        DB 00001000b   ;   # 
        DB 00001000b   ;   #
        ;211
        DB 00011100b   ;  ###
        DB 00011100b   ;  ###
        DB 00001000b   ;   # 
        DB 00011100b   ;  ###
        DB 00101010b   ; # # #
        DB 00001000b   ;   #
        ;212
        DB 00010100b   ;  # # 
        DB 00000000b   ; 
        DB 00010100b   ;  # # 
        DB 00010100b   ;  # # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;213
        DB 00010100b   ;  # # 
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00010100b   ;  # # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;214
        DB 00010100b   ;  # # 
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00010100b   ;  # # 
        DB 00011110b   ;  ####
        DB 00000000b   ; 
        ;215
        DB 00010100b   ;  # # 
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00010100b   ;  # # 
        DB 00010100b   ;  # # 
        DB 00000000b   ; 
        ;216
        DB 00101000b   ; # #
        DB 00101100b   ; # ## 
        DB 00111110b   ; ##### 
        DB 00001100b   ;   ## 
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;217
        DB 00001010b   ;   # #
        DB 00011010b   ;  ## #
        DB 00111110b   ; #####
        DB 00011000b   ;  ## 
        DB 00001000b   ;   #
        DB 00000000b   ; 
        ;218
        DB 00001000b   ;   #
        DB 00011100b   ;  ###
        DB 00001000b   ;   #
        DB 00000000b   ;  
        DB 00011100b   ;  ###
        DB 00000000b   ;
        ;219
        DB 00001000b   ;   #
        DB 00000000b   ; 
        DB 00111110b   ; #####
        DB 00000000b   ;
        DB 00001000b   ;   #
        DB 00000000b   ;
        ;220
        DB 00000100b   ;    #
        DB 00001000b   ;   # 
        DB 00010000b   ;  #
        DB 00001000b   ;   # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;221
        DB 00010000b   ;  #
        DB 00001000b   ;   # 
        DB 00000100b   ;    #
        DB 00001000b   ;   # 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;222
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        ;223
        DB 00000110b   ;    ## 
        DB 00000100b   ;    # 
        DB 00110100b   ; ## #
        DB 00010100b   ;  # # 
        DB 00001000b   ;   # 
        DB 00000000b   ; 
        ;224
        DB 00011110b   ;  #### 
        DB 00001110b   ;   ### 
        DB 00001110b   ;   ### 
        DB 00010010b   ;  #  #
        DB 00100000b   ; # 
        DB 00000000b   ; 
        ;225
        DB 00100000b   ; #
        DB 00010010b   ;  #  #
        DB 00001110b   ;   ###
        DB 00001110b   ;   ###
        DB 00011110b   ;  ####
        DB 00000000b   ; 
        ;226
        DB 00000010b   ;      #
        DB 00100100b   ;  #  #
        DB 00111000b   ;  ###
        DB 00111000b   ;  ###
        DB 00111100b   ;  #### 
        DB 00000000b   ; 
        ;227
        DB 00111100b   ; ####
        DB 00111000b   ; ###
        DB 00111000b   ; ###
        DB 00100100b   ; #  # 
        DB 00000010b   ;     #
        DB 00000000b   ; 
        ;228
        DB 00111110b   ; #####
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00100010b   ; #   #
        DB 00111110b   ; #####
        DB 00000000b   ; 
        ;229
        DB 00111110b   ; #####
        DB 00100110b   ; #  ##
        DB 00101010b   ; # # #
        DB 00110010b   ; ##  #
        DB 00111110b   ; #####
        DB 00000000b   ; 
        ;230
        DB 00001000b   ;   # 
        DB 00010010b   ;  #  #
        DB 00100100b   ; #  #
        DB 00010010b   ;  #  #
        DB 00001000b   ;   # 
        DB 00000000b   ; 
        ;231
        DB 00001000b   ;   # 
        DB 00100100b   ; #  #
        DB 00010010b   ;  #  #
        DB 00100100b   ; #  #
        DB 00001000b   ;   # 
        DB 00000000b   ; 
        ;232 TEC-1G
        DB 00011101b   ;  ### #
        DB 00001000b   ;   #
        DB 00001001b   ;   #  #
        DB 00001000b   ;   #
        DB 00001001b   ;   #  #
        DB 00000000b   ; 
        ;233 TEC-1G
        DB 00110111b   ; ## ###
        DB 00000100b   ;    #
        DB 00110100b   ; ## #
        DB 00000100b   ;    #
        DB 00110111b   ; ## ###
        DB 00000000b   ; 
        ;234 TEC-1G
        DB 00000000b   ; 
        DB 00000001b   ;      #
        DB 00011100b   ;  ###
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;235 TEC-1G
        DB 00101110b   ; # ###
        DB 00101000b   ; # #
        DB 00101010b   ; # # #
        DB 00101010b   ; # # #
        DB 00101110b   ; # ###
        DB 00000000b   ; 
        ;236 Z80
        DB 00011101b   ;  ### #
        DB 00000101b   ;    # #
        DB 00001001b   ;   #  #
        DB 00010001b   ;  #   #
        DB 00011101b   ;  ### #
        DB 00000000b   ; 
        ;237 Z80
        DB 00110111b   ; ## ###
        DB 00010101b   ;  # # #
        DB 00110101b   ; ## # #
        DB 00010101b   ;  # # #
        DB 00110111b   ; ## ###
        DB 00000000b   ; 
        ;238 CPU
        DB 00011101b   ;  ### #
        DB 00010001b   ;  #   #
        DB 00010001b   ;  #   #
        DB 00010001b   ;  #   #
        DB 00011101b   ;  ### #
        DB 00000000b   ; 
        ;239 CPU
        DB 00110101b   ; ## # #
        DB 00010101b   ;  # # #
        DB 00110101b   ; ## # #
        DB 00000101b   ;    # #
        DB 00000111b   ;    ###
        DB 00000000b   ; 
        ;240
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;241
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;242
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;243
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;244
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;245
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;246
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;247
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;248
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;249
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;250
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;251
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;252
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;253
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;254
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;255
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        ;256
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000000b   ; 
        DB 00000001b   ;      #
        

;    JP INIT_LCD             ;Initalise the LCD
;    JP CLEAR_GBUF           ;Clear the Graphics Buffer
;    JP CLEAR_GR_LCD         ;Clear the Graphics LCD Screen
;    JP CLEAR_TXT_LCD        ;Clear the Text LCD Screen
;    JP SET_GR_MODE          ;Set Graphics Mode
;    JP SET_TXT_MODE         ;Set Text Mode
;    JP DRAW_BOX             ;Draw a rectangle between two points
;    JP DRAW_LINE            ;Draw a line between two points
;    JP DRAW_CIRCLE          ;Draw a circle from Mid X,Y to Radius
;    JP DRAW_PIXEL           ;Draw one pixel at X,Y
;    JP FILL_BOX             ;Draw a filled rectangle between two points
;    JP FILL_CIRCLE          ;Draw a filled circle from Mid X,Y to Radius
;    JP PLOT_TO_LCD          ;Display the Graphics Buffer to the LCD Screen
;    JP PRINT_STRING         ;Print Text on the screen in a given row
;    JP PRINT_CHARS          ;Print Characters on the screen in a given row and column
;    JP DELAY_US             ;Microsecond delay for LCD updates
;    JP DELAY_MS             ;Millisecond delay for LCD updates
;    JP SET_BUF_CLEAR        ;Clear the Graphics buffer on after Plotting to the screen
;    JP SET_BUF_NO_CLEAR     ;Retain the Graphics buffer on after Plotting to the screen
;    JP CLEAR_PIXEL          ;Remove a Pixel at X,Y
;    JP FLIP_PIXEL           ;Flip a Pixel On/Off at X,Y
;    JP LCD_INST             ;Send a parallel or serial instruction to LCD
;    JP LCD_DATA             ;Send a parallel or serial datum to LCD
;    JP SER_SYNC             ;Send serial synchronise byte to LCD
;    JP DRAW_GRAPHIC         ;Draw an ASCII charcter or Sprite to the LCD
;    JP INV_GRAPHIC          ;Inverse graphics printing
;    JP INIT_TERMINAL        ;Initialize the LCD for terminal emulation
;    JP SEND_CHAR_TO_GLCD    ;Send an ASCII Character to the LCD
;    JP SEND_STRING_TO_GLCD  ;Send an ASCII String to the LCD
;    JP SEND_A_TO_GLCD       ;Send register A to the LCD
;    JP SEND_HL_TO_GLCD      ;Send register HL to the LCD
;    JP SET_CURSOR           ;Set the graphics cursor
;    JP GET_CURSOR           ;Get the current cursor
;    JP DISPLAY_CURSOR       ;Set Cursor on or off
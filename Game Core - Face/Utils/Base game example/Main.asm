; **********************************************************************
; **  Z80 Mini GameCore - API - Public functions                      **
; **********************************************************************
;----------------------------------------------------------------------------------------------------------
;	Display LCD
;----------------------------------------------------------------------------------------------------------
INIT_LCD			        .EQU	$0100			;Initalise the LCD
CLEAR_GBUF			        .EQU	$0103			;Clear the Graphics Buffer
CLEAR_GR_LCD			    .EQU	$0106			;Clear the Graphics LCD Screen
CLEAR_TXT_LCD			    .EQU	$0109			;Clear the Text LCD Screen
SET_GR_MODE			        .EQU	$010C			;Set Graphics Mode
SET_TXT_MODE			    .EQU	$010F			;Set Text Mode
DRAW_BOX			        .EQU	$0112			;Draw a rectangle between two points
DRAW_LINE			        .EQU	$0115			;Draw a line between two points
DRAW_CIRCLE			        .EQU	$0118			;Draw a circle from Mid X,Y to Radius
DRAW_PIXEL			        .EQU	$011B			;Draw one pixel at X,Y
FILL_BOX			        .EQU	$011E			;Draw a filled rectangle between two points
FILL_CIRCLE			        .EQU	$0121			;Draw a filled circle from Mid X,Y to Radius
PLOT_TO_LCD			        .EQU	$0124			;Display the Graphics Buffer to the LCD Screen
PRINT_STRING			    .EQU	$0127			;Print Text on the screen in a given row
PRINT_CHARS			        .EQU	$012A			;Print Characters on the screen in a given row and column
DELAY_US			        .EQU	$012D			;Microsecond delay for LCD updates
DELAY_MS             		.EQU	$0130			;Millisecond delay for LCD updates
SET_BUF_CLEAR			    .EQU	$0133			;Clear the Graphics buffer on after Plotting to the screen
SET_BUF_NO_CLEAR     		.EQU	$0136			;Retain the Graphics buffer on after Plotting to the screen
CLEAR_PIXEL          		.EQU	$0139			;Remove a Pixel at X,Y
FLIP_PIXEL			        .EQU	$013C			;Flip a Pixel On/Off at X,Y
LCD_INST             		.EQU	$013F			;Send a parallel or serial instruction to LCD
LCD_DATA             		.EQU	$0142			;Send a parallel or serial datum to LCD
SER_SYNC             		.EQU	$0145			;Send serial synchronise byte to LCD
DRAW_GRAPHIC         		.EQU	$0148			;Draw an ASCII charcter or Sprite to the LCD
INV_GRAPHIC          		.EQU	$014B			;Inverse graphics printing
INIT_TERMINAL        		.EQU	$014E			;Initialize the LCD for terminal emulation
SEND_CHAR_TO_GLCD    		.EQU	$0151			;Send an ASCII Character to the LCD
SEND_STRING_TO_GLCD 		.EQU	$0154			;Send an ASCII String to the LCD
SEND_A_TO_GLCD       		.EQU	$0157			;Send register A to the LCD
SEND_HL_TO_GLCD      		.EQU	$015A			;Send register HL to the LCD
SET_CURSOR           		.EQU	$015D			;Set the graphics cursor
GET_CURSOR           		.EQU	$0160			;Get the current cursor
DISPLAY_CURSOR       		.EQU	$0163			;Set Cursor on or off
;----------------------------------------------------------------------------------------------------------
;	UTIL
;----------------------------------------------------------------------------------------------------------
H_Delay              		.EQU	$0166			;Delay in milliseconds (DE in millis)
LCD_PRINT_STRING            .EQU    $0169           ;Print string HL, end with 0 EX: "Test", $00
;----------------------------------------------------------------------------------------------------------
;	I2C Board
;----------------------------------------------------------------------------------------------------------
I2C_Open     			    .EQU	$016C			;Start i2c (Device address in A)
I2C_Close             		.EQU	$016F			;Close i2c 
I2C_Read              		.EQU	$0172			;I2C Read (data in A)
I2C_Write 			        .EQU	$0175			;I2C Write (data in A)
I2CLIST                     .EQU    $0178           ;I2C List devices on lcd

CLEAR_COLLISION             .EQU    $017B           ; lampa a flag de colisao
CHECK_COLLISION             .EQU    $017E           ; JP Z, SEM_COLISAO. JP NZ, COLISAO.

INIT_GAME_WAIT_START        .EQU   $0181        ; Chamar no setup, aguarda press start e returna, dar um (LD HL, setup) e (PUSH HL).
CHECK_GAMEOVER_WAIT_START   .EQU    $0184   ; Chamar no loop para verificar gameover e depois aguarda press start e ret para o inicio
SET_GAMEOVER                .EQU    $0187                 ; Seta a flag de gameover....


;----------------------------------------------------------------------------------------------------------
;	FIM
;----------------------------------------------------------------------------------------------------------


;         - Ports:
;               - Onboard IN/OUT: 40H
;					- Controle - pullDown (Input)
;						- bit0 - A
;						- bit1 - B
;						- bit2 - Start
;						- bit3 - Select
;						- bit4 - Right
;						- bit5 - Down
;						- bit6 - Left
;						- bit7 - Up


.org $8000

init:
    LD hl, init
    PUSH HL ; back to here on gameover

    XOR A
    LD (cursor_x), A
    LD (cursor_y), A

    CALL CLEAR_GBUF
    CALL INIT_GAME_WAIT_START

loop:
    CALL CLEAR_GBUF

; Draw p2 16x16
    LD BC, $1000
    CALL SET_CURSOR

    LD A, 0
    LD BC, $0F0F
    LD HL, img_p2_16x16
    CALL DRAW_GRAPHIC

; Draw p1
    LD A, (cursor_x)
    LD B, A
    LD A, (cursor_y)
    LD C, A
    CALL SET_CURSOR

    CALL CLEAR_COLLISION

    LD A, 0
    LD BC, $0808
    LD HL, img_p1
    CALL DRAW_GRAPHIC

    CALL CHECK_COLLISION
    CALL NZ, SET_GAMEOVER

    CALL PLOT_TO_LCD

    CALL read_keys

    CALL CHECK_GAMEOVER_WAIT_START

    jp loop

read_keys:
    in A, ($40)

    bit 7, A
    jp nz, btnUp

    bit 5, A
    jp nz, btnDown

    bit 6, A
    jp nz, btnLeft

    bit 4, A
    jp nz, btnRight
    ret

btnUp:
    ld a, (cursor_y)
    dec A
    ld (cursor_y), a
    ret

btnDown:
    ld a, (cursor_y)
    inc A
    ld (cursor_y), a
    ret

btnLeft:
    ld a, (cursor_x)
    dec A
    ld (cursor_x), a
    ret

btnRight:
    ld a, (cursor_x)
    inc A
    ld (cursor_x), a
    ret

cursor_x:   .db 0x00
cursor_y:   .db 0x00

img_p1: .db 0xAB, 0x81, 0x01, 0x24, 0x00, 0x10, 0x44, 0x78

img_p2_16x16: .db 0x7F, 0xFE, 0x80, 0x01, 0x80, 0x01, 0x80, 0x01, 0x00, 0x00, 0x18, 0x60, 0x18, 0x60, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x03, 0x00, 0x00, 0x00, 0x20, 0x10, 0x10, 0x20, 0x0F, 0xC0, 0x00, 0x00
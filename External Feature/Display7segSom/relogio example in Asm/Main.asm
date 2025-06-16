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
inicio:
    ;liga display
    ld a, 0x0e
    call I2C_Open
    ld a, 0x00
    call I2C_Write
    ld a, 0x03
    call I2C_Write
    call I2C_Close


loop:
    ; le ricoh223 - segundos
    ld a, 0x64
    call I2C_Open
    ld a, 0x00 ; segundos
    call I2C_Write
    ld a, 0x64+1 ; read is addrr + 1
    call I2C_Open
    call I2C_Read
    ld (segundos), a
    call I2C_Close
    
    ld de, $0032
    call H_Delay
    
    ; le ricoh223 - minutos
    ld a, 0x64
    call I2C_Open
    ld a, 0x10 ; minutos
    call I2C_Write
    ld a, 0x64+1 ; read is addrr + 1
    call I2C_Open
    call I2C_Read
    and 0b01111111
    ld (minutos), a
    call I2C_Close
    
    ld de, $0032
    call H_Delay
    
    ; le ricoh223 - hora
    ld a, 0x64
    call I2C_Open
    ld a, 0x20 ; hora
    call I2C_Write
    ld a, 0x64+1 ; read is addrr + 1
    call I2C_Open
    call I2C_Read
    and 0b00011111
    ld (horas), a
    call I2C_Close

    ld de, $0032
    call H_Delay


    ;display escreve low
    ld a, 0x0e
    call I2C_Open
    ld a, 0x01
    call I2C_Write
    ld a, (minutos)
    call I2C_Write
    call I2C_Close
    
    ld de, $0032
    call H_Delay
    
    ;display escreve high
    ld a, 0x0e
    call I2C_Open
    ld a, 0x02
    call I2C_Write
    ld a, (horas)
    call I2C_Write
    call I2C_Close
    
    ld de, $0396
    call H_Delay

    ; pisca ponto :
    ; (XX:XX) > (XX XX) > (XX:XX) > (XX XX)
    ld a, 0x0e
    call I2C_Open
    ld a, 0x00
    call I2C_Write
    ld a, (status)
    xor 4
    ld (status), a
    call I2C_Write
    call I2C_Close
    
    jp loop

status .db 0x03
horas .db 0x00
minutos .db 0x00
segundos .db 0x00


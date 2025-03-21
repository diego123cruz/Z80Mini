; **********************************************************************
; **  Z80 Mini API - Public functions                                          **
; **********************************************************************

;----------------------------------------------------------------------------------------------------------
;	Display LCD
;----------------------------------------------------------------------------------------------------------
INIT_LCD:			        EQU	$0100			;Initalise the LCD
CLEAR_GBUF:			        EQU	$0103			;Clear the Graphics Buffer
CLEAR_GR_LCD:			    EQU	$0106			;Clear the Graphics LCD Screen
CLEAR_TXT_LCD:			    EQU	$0109			;Clear the Text LCD Screen
SET_GR_MODE:			        EQU	$010C			;Set Graphics Mode
SET_TXT_MODE:			    EQU	$010F			;Set Text Mode
DRAW_BOX:			        EQU	$0112			;Draw a rectangle between two points
DRAW_LINE:			        EQU	$0115			;Draw a line between two points
DRAW_CIRCLE:			        EQU	$0118			;Draw a circle from Mid X,Y to Radius
DRAW_PIXEL:			        EQU	$011B			;Draw one pixel at X,Y
FILL_BOX:			        EQU	$011E			;Draw a filled rectangle between two points
FILL_CIRCLE:			        EQU	$0121			;Draw a filled circle from Mid X,Y to Radius
PLOT_TO_LCD:			        EQU	$0124			;Display the Graphics Buffer to the LCD Screen
PRINT_STRING:			    EQU	$0127			;Print Text on the screen in a given row
PRINT_CHARS:			        EQU	$012A			;Print Characters on the screen in a given row and column
DELAY_US:			        EQU	$012D			;Microsecond delay for LCD updates
DELAY_MS:             		EQU	$0130			;Millisecond delay for LCD updates
SET_BUF_CLEAR:			    EQU	$0133			;Clear the Graphics buffer on after Plotting to the screen
SET_BUF_NO_CLEAR:     		EQU	$0136			;Retain the Graphics buffer on after Plotting to the screen
CLEAR_PIXEL:          		EQU	$0139			;Remove a Pixel at X,Y
FLIP_PIXEL:			        EQU	$013C			;Flip a Pixel On/Off at X,Y
LCD_INST:             		EQU	$013F			;Send a parallel instruction to LCD
LCD_DATA:             		EQU	$0142			;Send a parallel datum to LCD
SER_SYNC:             		EQU	$0145			;Send serial synchronise byte to LCD
DRAW_GRAPHIC:         		EQU	$0148			;Draw an ASCII charcter or Sprite to the LCD
INV_GRAPHIC:          		EQU	$014B			;Inverse graphics printing
INIT_TERMINAL:        		EQU	$014E			;Initialize the LCD for terminal emulation
SEND_CHAR_TO_GLCD:    		EQU	$0151			;Send an ASCII Character to the LCD
SEND_STRING_TO_GLCD: 		EQU	$0154			;Send an ASCII String to the LCD
SEND_A_TO_GLCD:       		EQU	$0157			;Send register A to the LCD
SEND_HL_TO_GLCD:      		EQU	$015A			;Send register HL to the LCD
SET_CURSOR:           		EQU	$015D			;Set the graphics cursor
GET_CURSOR:           		EQU	$0160			;Get the current cursor
DISPLAY_CURSOR:       		EQU	$0163			;Set Cursor on or off
;----------------------------------------------------------------------------------------------------------
;	I2C Board
;----------------------------------------------------------------------------------------------------------
I2C_Open:     			    EQU	$0166			;Start i2c (Device address in A)
I2C_Close:             		EQU	$0169			;Close i2c 
I2C_Read:              		EQU	$016C			;I2C Read
I2C_Write: 			        EQU	$016F			;I2C Write
;----------------------------------------------------------------------------------------------------------
;	SERIAL 
;----------------------------------------------------------------------------------------------------------
TXDATA:               		EQU	$0172			;OUTPUT A CHARACTER TO THE TERMINAL, Char in A
RXDATA:               		EQU	$0175			;INPUT A CHARACTER FROM THE TERMINAL, Char in A
SNDSTR:               		EQU	$0178			;SEND AN ASCII STRING OUT THE SERIAL PORT (Max 128 chars), HL = POINTER TO 00H TERMINATED STRING
INTELLOADER:          		EQU	$017B			;Start load intel hex to $8000 (RAM)
;----------------------------------------------------------------------------------------------------------
;	KEYBOARD
;----------------------------------------------------------------------------------------------------------
KEYREADINIT:          		EQU	$017E			;Input character KeyboardOnboard (Char in A), loop until release key
KEYREAD:              		EQU	$0181			;Input character KeyboardOnboard (Char in A), WITHOUT loop until release key
CHKKEY:               		EQU	$0184			;Check BK press
;----------------------------------------------------------------------------------------------------------
;	UTIL
;----------------------------------------------------------------------------------------------------------
H_Delay:              		EQU	$0187			;Delay in milliseconds (DE in millis)
LED_RED:			    	    EQU	$018A			;Half byte in A (4 bits)
LED_GREEN:            		EQU	$018D			;Half byte in A (4 bits)
;----------------------------------------------------------------------------------------------------------
;	FIM
;----------------------------------------------------------------------------------------------------------


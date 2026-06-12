;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.0 #15242 (Linux)
;--------------------------------------------------------
	.module Z80Mini
	
	.optsdcc -mz80 sdcccall(1)
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _delay500ms
	.globl _delay
	.globl _I2C_Open
	.globl _I2C_Close
	.globl _I2C_Read
	.globl _I2C_Write
	.globl _keyboardIsEsc
	.globl _keyboardWaitA
	.globl _keyboardA
	.globl _setDefaultSerialA
	.globl _setDefaultSerialB
	.globl _serialPrintA
	.globl _serialInputA
	.globl _serialPrintStr
	.globl _serialCRLF
	.globl _serialHexA
	.globl _serialHexHL
	.globl _serialInHexA
	.globl _serialInHexHL
	.globl _initLCD
	.globl _clearGBUF
	.globl _clearGrLCD
	.globl _clearTxtLCD
	.globl _setGrMode
	.globl _setTxtMode
	.globl _drawBox
	.globl _drawLine
	.globl _fillBox
	.globl _drawCircle
	.globl _fillCircle
	.globl _drawPixel
	.globl _clearPixel
	.globl _flipPixel
	.globl _plotToLCD
	.globl _printString
	.globl _printChars
	.globl _setBufClear
	.globl _setBufNoClear
	.globl _drawGraphic
	.globl _invGraphic
	.globl _initTerminal
	.globl _sendCharToLCD
	.globl _sendStringToLCD
	.globl _sendRegToLCD
	.globl _sendHLToLCD
	.globl _setCursor
	.globl _getCursor
	.globl _displayCursor
	.globl _autoLF
	.globl _underline
	.globl _plotAlways
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;../Z80Mini.c:11: void delay500ms(void) __naked
;	---------------------------------
; Function delay500ms
; ---------------------------------
_delay500ms::
;../Z80Mini.c:16: __endasm;
	call	0x0100
	ret
;../Z80Mini.c:17: }
;../Z80Mini.c:19: void delay(uint16_t ms) __naked __sdcccall(1)
;	---------------------------------
; Function delay
; ---------------------------------
_delay::
;../Z80Mini.c:29: __endasm;
	ex	de,hl
	call	0x0103
	ret
;../Z80Mini.c:30: }
;../Z80Mini.c:36: void I2C_Open(uint8_t addr) __naked __sdcccall(1)
;	---------------------------------
; Function I2C_Open
; ---------------------------------
_I2C_Open::
;../Z80Mini.c:43: __endasm;
	call	0x0106
	ret
;../Z80Mini.c:44: }
;../Z80Mini.c:46: void I2C_Close(void) __naked
;	---------------------------------
; Function I2C_Close
; ---------------------------------
_I2C_Close::
;../Z80Mini.c:51: __endasm;
	call	0x0109
	ret
;../Z80Mini.c:52: }
;../Z80Mini.c:54: uint8_t I2C_Read(void) __naked
;	---------------------------------
; Function I2C_Read
; ---------------------------------
_I2C_Read::
;../Z80Mini.c:59: __endasm;
	call	0x010C
	ret
;../Z80Mini.c:60: }
;../Z80Mini.c:62: void I2C_Write(uint8_t data) __naked __sdcccall(1)
;	---------------------------------
; Function I2C_Write
; ---------------------------------
_I2C_Write::
;../Z80Mini.c:69: __endasm;
	call	0x010F
	ret
;../Z80Mini.c:70: }
;../Z80Mini.c:76: uint8_t keyboardIsEsc(void) __naked
;	---------------------------------
; Function keyboardIsEsc
; ---------------------------------
_keyboardIsEsc::
;../Z80Mini.c:81: __endasm;
	call	0x0112
	ret
;../Z80Mini.c:82: }
;../Z80Mini.c:84: uint8_t keyboardWaitA(void) __naked
;	---------------------------------
; Function keyboardWaitA
; ---------------------------------
_keyboardWaitA::
;../Z80Mini.c:89: __endasm;
	call	0x0115
	ret
;../Z80Mini.c:90: }
;../Z80Mini.c:92: uint8_t keyboardA(void) __naked
;	---------------------------------
; Function keyboardA
; ---------------------------------
_keyboardA::
;../Z80Mini.c:97: __endasm;
	call	0x0118
	ret
;../Z80Mini.c:98: }
;../Z80Mini.c:104: void setDefaultSerialA(void) __naked
;	---------------------------------
; Function setDefaultSerialA
; ---------------------------------
_setDefaultSerialA::
;../Z80Mini.c:109: __endasm;
	call	0x011B
	ret
;../Z80Mini.c:110: }
;../Z80Mini.c:112: void setDefaultSerialB(void) __naked
;	---------------------------------
; Function setDefaultSerialB
; ---------------------------------
_setDefaultSerialB::
;../Z80Mini.c:117: __endasm;
	call	0x011E
	ret
;../Z80Mini.c:118: }
;../Z80Mini.c:120: void serialPrintA(uint8_t c) __naked __sdcccall(1)
;	---------------------------------
; Function serialPrintA
; ---------------------------------
_serialPrintA::
;../Z80Mini.c:127: __endasm;
	call	0x0121
	ret
;../Z80Mini.c:128: }
;../Z80Mini.c:130: uint8_t serialInputA(void) __naked
;	---------------------------------
; Function serialInputA
; ---------------------------------
_serialInputA::
;../Z80Mini.c:135: __endasm;
	call	0x0124
	ret
;../Z80Mini.c:136: }
;../Z80Mini.c:138: void serialPrintStr(char *s) __naked __sdcccall(1)
;	---------------------------------
; Function serialPrintStr
; ---------------------------------
_serialPrintStr::
;../Z80Mini.c:145: __endasm;
	call	0x0127
	ret
;../Z80Mini.c:146: }
;../Z80Mini.c:148: void serialCRLF(void) __naked
;	---------------------------------
; Function serialCRLF
; ---------------------------------
_serialCRLF::
;../Z80Mini.c:153: __endasm;
	call	0x012A
	ret
;../Z80Mini.c:154: }
;../Z80Mini.c:156: void serialHexA(uint8_t v) __naked __sdcccall(1)
;	---------------------------------
; Function serialHexA
; ---------------------------------
_serialHexA::
;../Z80Mini.c:163: __endasm;
	call	0x012D
	ret
;../Z80Mini.c:164: }
;../Z80Mini.c:166: void serialHexHL(uint16_t v) __naked __sdcccall(1)
;	---------------------------------
; Function serialHexHL
; ---------------------------------
_serialHexHL::
;../Z80Mini.c:173: __endasm;
	call	0x0130
	ret
;../Z80Mini.c:174: }
;../Z80Mini.c:176: uint8_t serialInHexA(void) __naked
;	---------------------------------
; Function serialInHexA
; ---------------------------------
_serialInHexA::
;../Z80Mini.c:181: __endasm;
	call	0x0133
	ret
;../Z80Mini.c:182: }
;../Z80Mini.c:184: uint16_t serialInHexHL(void) __naked
;	---------------------------------
; Function serialInHexHL
; ---------------------------------
_serialInHexHL::
;../Z80Mini.c:189: __endasm;
	call	0x0136
	ret
;../Z80Mini.c:190: }
;../Z80Mini.c:196: void initLCD(void) __naked
;	---------------------------------
; Function initLCD
; ---------------------------------
_initLCD::
;../Z80Mini.c:201: __endasm;
	call	0x0139
	ret
;../Z80Mini.c:202: }
;../Z80Mini.c:204: void clearGBUF(void) __naked
;	---------------------------------
; Function clearGBUF
; ---------------------------------
_clearGBUF::
;../Z80Mini.c:211: __endasm;
	call	0x013C
	ret
;../Z80Mini.c:212: }
;../Z80Mini.c:214: void clearGrLCD(void) __naked
;	---------------------------------
; Function clearGrLCD
; ---------------------------------
_clearGrLCD::
;../Z80Mini.c:219: __endasm;
	call	0x013F
	ret
;../Z80Mini.c:220: }
;../Z80Mini.c:222: void clearTxtLCD(void) __naked
;	---------------------------------
; Function clearTxtLCD
; ---------------------------------
_clearTxtLCD::
;../Z80Mini.c:227: __endasm;
	call	0x0142
	ret
;../Z80Mini.c:228: }
;../Z80Mini.c:230: void setGrMode(void) __naked
;	---------------------------------
; Function setGrMode
; ---------------------------------
_setGrMode::
;../Z80Mini.c:235: __endasm;
	call	0x0145
	ret
;../Z80Mini.c:236: }
;../Z80Mini.c:238: void setTxtMode(void) __naked
;	---------------------------------
; Function setTxtMode
; ---------------------------------
_setTxtMode::
;../Z80Mini.c:243: __endasm;
	call	0x0148
	ret
;../Z80Mini.c:244: }
;../Z80Mini.c:250: void drawBox(
;	---------------------------------
; Function drawBox
; ---------------------------------
_drawBox::
;../Z80Mini.c:277: __endasm;
	ld	b, a
	ld	c, l
	pop	hl
	ex	(sp), hl
	ld	d, l
	ld	e, h
	call	0x014B
	ret
;../Z80Mini.c:278: }
;../Z80Mini.c:280: void drawLine(
;	---------------------------------
; Function drawLine
; ---------------------------------
_drawLine::
;../Z80Mini.c:306: __endasm;
	ld	b, a
	ld	c, l
	pop	hl
	ex	(sp), hl
	ld	d, l
	ld	e, h
	call	0x014E
	ret
;../Z80Mini.c:307: }
;../Z80Mini.c:309: void fillBox(
;	---------------------------------
; Function fillBox
; ---------------------------------
_fillBox::
;../Z80Mini.c:336: __endasm;
	ld	b, a
	ld	c, l
	pop	hl
	ex	(sp), hl
	ld	d, l
	ld	e, h
	call	0x0157
	ret
;../Z80Mini.c:337: }
;../Z80Mini.c:339: void drawCircle(
;	---------------------------------
; Function drawCircle
; ---------------------------------
_drawCircle::
;../Z80Mini.c:365: __endasm;
	ld	b, a
	ld	c, l
	pop	hl
	pop	de
	push	de
	inc	sp
	push	hl
	call	0x0151
	ret
;../Z80Mini.c:366: }
;../Z80Mini.c:368: void fillCircle(
;	---------------------------------
; Function fillCircle
; ---------------------------------
_fillCircle::
;../Z80Mini.c:394: __endasm;
	ld	b, a
	ld	c, l
	pop	hl
	pop	de
	push	de
	inc	sp
	push	hl
	call	0x015A
	ret
;../Z80Mini.c:395: }
;../Z80Mini.c:397: void drawPixel(
;	---------------------------------
; Function drawPixel
; ---------------------------------
_drawPixel::
;../Z80Mini.c:413: __endasm;
	ld	b, a
	ld	c, l
	call	0x0154
	ret
;../Z80Mini.c:414: }
;../Z80Mini.c:416: void clearPixel(
;	---------------------------------
; Function clearPixel
; ---------------------------------
_clearPixel::
;../Z80Mini.c:432: __endasm;
	ld	b, a
	ld	c, l
	call	0x0172
	ret
;../Z80Mini.c:433: }
;../Z80Mini.c:435: void flipPixel(
;	---------------------------------
; Function flipPixel
; ---------------------------------
_flipPixel::
;../Z80Mini.c:451: __endasm;
	ld	b, a
	ld	c, l
	call	0x0175
	ret
;../Z80Mini.c:452: }
;../Z80Mini.c:454: void plotToLCD(void) __naked
;	---------------------------------
; Function plotToLCD
; ---------------------------------
_plotToLCD::
;../Z80Mini.c:459: __endasm;
	call	0x015D
	ret
;../Z80Mini.c:460: }
;../Z80Mini.c:466: void printString(uint8_t line, char *txt)
;	---------------------------------
; Function printString
; ---------------------------------
_printString::
;../Z80Mini.c:480: __endasm;
;	A = line
;	HL = txt
	call	0x0160
	ret
;../Z80Mini.c:481: }
;../Z80Mini.c:483: void printChars(
;	---------------------------------
; Function printChars
; ---------------------------------
_printChars::
;../Z80Mini.c:503: __endasm;
	ld	b, a
	ld	c, l
	ex	de, hl
	call	0x0163
	ret
;../Z80Mini.c:504: }
;../Z80Mini.c:510: void setBufClear(void) __naked
;	---------------------------------
; Function setBufClear
; ---------------------------------
_setBufClear::
;../Z80Mini.c:515: __endasm;
	call	0x016C
	ret
;../Z80Mini.c:516: }
;../Z80Mini.c:518: void setBufNoClear(void) __naked
;	---------------------------------
; Function setBufNoClear
; ---------------------------------
_setBufNoClear::
;../Z80Mini.c:523: __endasm;
	call	0x016F
	ret
;../Z80Mini.c:524: }
;../Z80Mini.c:530: void drawGraphic(
;	---------------------------------
; Function drawGraphic
; ---------------------------------
_drawGraphic::
;../Z80Mini.c:551: __endasm;
;	A = chr
;	HL = data
;	DE = w/h
	call	0x0178
	ret
;../Z80Mini.c:552: }
;../Z80Mini.c:554: void invGraphic(void) __naked
;	---------------------------------
; Function invGraphic
; ---------------------------------
_invGraphic::
;../Z80Mini.c:559: __endasm;
	call	0x017B
	ret
;../Z80Mini.c:560: }
;../Z80Mini.c:566: void initTerminal(void) __naked
;	---------------------------------
; Function initTerminal
; ---------------------------------
_initTerminal::
;../Z80Mini.c:571: __endasm;
	call	0x017E
	ret
;../Z80Mini.c:572: }
;../Z80Mini.c:574: void sendCharToLCD(uint8_t c)
;	---------------------------------
; Function sendCharToLCD
; ---------------------------------
_sendCharToLCD::
;../Z80Mini.c:582: __endasm;
	call	0x0181
	ret
;../Z80Mini.c:583: }
;../Z80Mini.c:585: void sendStringToLCD(
;	---------------------------------
; Function sendStringToLCD
; ---------------------------------
_sendStringToLCD::
;../Z80Mini.c:598: __endasm;
	ex	de, hl
	ld	a, #0
	call	0x0184
	ret
;../Z80Mini.c:599: }
;../Z80Mini.c:601: void sendRegToLCD(uint8_t v)
;	---------------------------------
; Function sendRegToLCD
; ---------------------------------
_sendRegToLCD::
;../Z80Mini.c:609: __endasm;
	call	0x0187
	ret
;../Z80Mini.c:610: }
;../Z80Mini.c:612: void sendHLToLCD(uint16_t v)
;	---------------------------------
; Function sendHLToLCD
; ---------------------------------
_sendHLToLCD::
;../Z80Mini.c:620: __endasm;
	call	0x018A
	ret
;../Z80Mini.c:621: }
;../Z80Mini.c:623: void setCursor(
;	---------------------------------
; Function setCursor
; ---------------------------------
_setCursor::
;../Z80Mini.c:638: __endasm;
	ld	b, a
	ld	c, l
	call	0x018D
	ret
;../Z80Mini.c:639: }
;../Z80Mini.c:641: uint16_t getCursor(void) __naked
;	---------------------------------
; Function getCursor
; ---------------------------------
_getCursor::
;../Z80Mini.c:652: __endasm;
	call	0x0190
	ld	d, b
	ld	e, c
	ret
;../Z80Mini.c:653: }
;../Z80Mini.c:655: void displayCursor(uint8_t v)
;	---------------------------------
; Function displayCursor
; ---------------------------------
_displayCursor::
;../Z80Mini.c:663: __endasm;
	call	0x0193
	ret
;../Z80Mini.c:664: }
;../Z80Mini.c:666: void autoLF(uint8_t v)
;	---------------------------------
; Function autoLF
; ---------------------------------
_autoLF::
;../Z80Mini.c:674: __endasm;
	call	0x0196
	ret
;../Z80Mini.c:675: }
;../Z80Mini.c:677: void underline(void) __naked
;	---------------------------------
; Function underline
; ---------------------------------
_underline::
;../Z80Mini.c:682: __endasm;
	call	0x0199
	ret
;../Z80Mini.c:683: }
;../Z80Mini.c:685: void plotAlways(uint8_t v)
;	---------------------------------
; Function plotAlways
; ---------------------------------
_plotAlways::
;../Z80Mini.c:693: __endasm;
	call	0x019C
	ret
;../Z80Mini.c:694: }
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

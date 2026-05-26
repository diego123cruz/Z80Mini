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
;Z80Mini.c:11: void delay500ms(void) __naked
;	---------------------------------
; Function delay500ms
; ---------------------------------
_delay500ms::
;Z80Mini.c:16: __endasm;
	call	0x0100
	ret
;Z80Mini.c:17: }
;Z80Mini.c:19: void delay(uint16_t ms) __naked __sdcccall(1)
;	---------------------------------
; Function delay
; ---------------------------------
_delay::
;Z80Mini.c:27: __endasm;
	ex	de,hl
	call	0x0103
	ret
;Z80Mini.c:28: }
;Z80Mini.c:34: void I2C_Open(uint8_t addr) __naked __sdcccall(1)
;	---------------------------------
; Function I2C_Open
; ---------------------------------
_I2C_Open::
;Z80Mini.c:41: __endasm;
	call	0x0106
	ret
;Z80Mini.c:42: }
;Z80Mini.c:44: void I2C_Close(void) __naked
;	---------------------------------
; Function I2C_Close
; ---------------------------------
_I2C_Close::
;Z80Mini.c:49: __endasm;
	call	0x0109
	ret
;Z80Mini.c:50: }
;Z80Mini.c:52: uint8_t I2C_Read(void) __naked
;	---------------------------------
; Function I2C_Read
; ---------------------------------
_I2C_Read::
;Z80Mini.c:57: __endasm;
	call	0x010C
	ret
;Z80Mini.c:58: }
;Z80Mini.c:60: void I2C_Write(uint8_t data) __naked __sdcccall(1)
;	---------------------------------
; Function I2C_Write
; ---------------------------------
_I2C_Write::
;Z80Mini.c:67: __endasm;
	call	0x010F
	ret
;Z80Mini.c:68: }
;Z80Mini.c:74: uint8_t keyboardIsEsc(void) __naked
;	---------------------------------
; Function keyboardIsEsc
; ---------------------------------
_keyboardIsEsc::
;Z80Mini.c:79: __endasm;
	call	0x0112
	ret
;Z80Mini.c:80: }
;Z80Mini.c:82: uint8_t keyboardWaitA(void) __naked
;	---------------------------------
; Function keyboardWaitA
; ---------------------------------
_keyboardWaitA::
;Z80Mini.c:87: __endasm;
	call	0x0115
	ret
;Z80Mini.c:88: }
;Z80Mini.c:90: uint8_t keyboardA(void) __naked
;	---------------------------------
; Function keyboardA
; ---------------------------------
_keyboardA::
;Z80Mini.c:95: __endasm;
	call	0x0118
	ret
;Z80Mini.c:96: }
;Z80Mini.c:102: void setDefaultSerialA(void) __naked
;	---------------------------------
; Function setDefaultSerialA
; ---------------------------------
_setDefaultSerialA::
;Z80Mini.c:107: __endasm;
	call	0x011B
	ret
;Z80Mini.c:108: }
;Z80Mini.c:110: void setDefaultSerialB(void) __naked
;	---------------------------------
; Function setDefaultSerialB
; ---------------------------------
_setDefaultSerialB::
;Z80Mini.c:115: __endasm;
	call	0x011E
	ret
;Z80Mini.c:116: }
;Z80Mini.c:118: void serialPrintA(uint8_t c) __naked __sdcccall(1)
;	---------------------------------
; Function serialPrintA
; ---------------------------------
_serialPrintA::
;Z80Mini.c:125: __endasm;
	call	0x0121
	ret
;Z80Mini.c:126: }
;Z80Mini.c:128: uint8_t serialInputA(void) __naked
;	---------------------------------
; Function serialInputA
; ---------------------------------
_serialInputA::
;Z80Mini.c:133: __endasm;
	call	0x0124
	ret
;Z80Mini.c:134: }
;Z80Mini.c:136: void serialPrintStr(char *s) __naked __sdcccall(1)
;	---------------------------------
; Function serialPrintStr
; ---------------------------------
_serialPrintStr::
;Z80Mini.c:143: __endasm;
	call	0x0127
	ret
;Z80Mini.c:144: }
;Z80Mini.c:146: void serialCRLF(void) __naked
;	---------------------------------
; Function serialCRLF
; ---------------------------------
_serialCRLF::
;Z80Mini.c:151: __endasm;
	call	0x012A
	ret
;Z80Mini.c:152: }
;Z80Mini.c:154: void serialHexA(uint8_t v) __naked __sdcccall(1)
;	---------------------------------
; Function serialHexA
; ---------------------------------
_serialHexA::
;Z80Mini.c:161: __endasm;
	call	0x012D
	ret
;Z80Mini.c:162: }
;Z80Mini.c:164: void serialHexHL(uint16_t v) __naked __sdcccall(1)
;	---------------------------------
; Function serialHexHL
; ---------------------------------
_serialHexHL::
;Z80Mini.c:171: __endasm;
	call	0x0130
	ret
;Z80Mini.c:172: }
;Z80Mini.c:174: uint8_t serialInHexA(void) __naked
;	---------------------------------
; Function serialInHexA
; ---------------------------------
_serialInHexA::
;Z80Mini.c:179: __endasm;
	call	0x0133
	ret
;Z80Mini.c:180: }
;Z80Mini.c:182: uint16_t serialInHexHL(void) __naked
;	---------------------------------
; Function serialInHexHL
; ---------------------------------
_serialInHexHL::
;Z80Mini.c:187: __endasm;
	call	0x0136
	ret
;Z80Mini.c:188: }
;Z80Mini.c:194: void initLCD(void) __naked
;	---------------------------------
; Function initLCD
; ---------------------------------
_initLCD::
;Z80Mini.c:199: __endasm;
	call	0x0139
	ret
;Z80Mini.c:200: }
;Z80Mini.c:202: void clearGBUF(void) __naked
;	---------------------------------
; Function clearGBUF
; ---------------------------------
_clearGBUF::
;Z80Mini.c:207: __endasm;
	call	0x013C
	ret
;Z80Mini.c:208: }
;Z80Mini.c:210: void clearGrLCD(void) __naked
;	---------------------------------
; Function clearGrLCD
; ---------------------------------
_clearGrLCD::
;Z80Mini.c:215: __endasm;
	call	0x013F
	ret
;Z80Mini.c:216: }
;Z80Mini.c:218: void clearTxtLCD(void) __naked
;	---------------------------------
; Function clearTxtLCD
; ---------------------------------
_clearTxtLCD::
;Z80Mini.c:223: __endasm;
	call	0x0142
	ret
;Z80Mini.c:224: }
;Z80Mini.c:226: void setGrMode(void) __naked
;	---------------------------------
; Function setGrMode
; ---------------------------------
_setGrMode::
;Z80Mini.c:231: __endasm;
	call	0x0145
	ret
;Z80Mini.c:232: }
;Z80Mini.c:234: void setTxtMode(void) __naked
;	---------------------------------
; Function setTxtMode
; ---------------------------------
_setTxtMode::
;Z80Mini.c:239: __endasm;
	call	0x0148
	ret
;Z80Mini.c:240: }
;Z80Mini.c:246: void drawBox(
;	---------------------------------
; Function drawBox
; ---------------------------------
_drawBox::
;Z80Mini.c:273: __endasm;
	ld	b, a
	ld	c, l
	ld	hl, #2
	add	hl, sp
	ld	d, (hl)
	inc	hl
	ld	e, (hl)
	call	0x014B
	ret
;Z80Mini.c:274: }
;Z80Mini.c:276: void drawLine(
;	---------------------------------
; Function drawLine
; ---------------------------------
_drawLine::
;Z80Mini.c:303: __endasm;
	ld	b, a
	ld	c, l
	ld	hl, #2
	add	hl, sp
	ld	d, (hl)
	inc	hl
	ld	e, (hl)
	call	0x014E
	ret
;Z80Mini.c:304: }
;Z80Mini.c:306: void fillBox(
;	---------------------------------
; Function fillBox
; ---------------------------------
_fillBox::
;Z80Mini.c:333: __endasm;
	ld	b, a
	ld	c, l
	ld	hl, #2
	add	hl, sp
	ld	d, (hl)
	inc	hl
	ld	e, (hl)
	call	0x0157
	ret
;Z80Mini.c:334: }
;Z80Mini.c:336: void drawCircle(
;	---------------------------------
; Function drawCircle
; ---------------------------------
_drawCircle::
;Z80Mini.c:359: __endasm;
	ld	b, a
	ld	c, l
	ld	hl, #2
	add	hl, sp
	ld	e, (hl)
	call	0x0151
	ret
;Z80Mini.c:360: }
;Z80Mini.c:362: void fillCircle(
;	---------------------------------
; Function fillCircle
; ---------------------------------
_fillCircle::
;Z80Mini.c:385: __endasm;
	ld	b, a
	ld	c, l
	ld	hl, #2
	add	hl, sp
	ld	e, (hl)
	call	0x015A
	ret
;Z80Mini.c:386: }
;Z80Mini.c:388: void drawPixel(
;	---------------------------------
; Function drawPixel
; ---------------------------------
_drawPixel::
;Z80Mini.c:404: __endasm;
	ld	b, a
	ld	c, l
	call	0x0154
	ret
;Z80Mini.c:405: }
;Z80Mini.c:407: void clearPixel(
;	---------------------------------
; Function clearPixel
; ---------------------------------
_clearPixel::
;Z80Mini.c:423: __endasm;
	ld	b, a
	ld	c, l
	call	0x0172
	ret
;Z80Mini.c:424: }
;Z80Mini.c:426: void flipPixel(
;	---------------------------------
; Function flipPixel
; ---------------------------------
_flipPixel::
;Z80Mini.c:442: __endasm;
	ld	b, a
	ld	c, l
	call	0x0175
	ret
;Z80Mini.c:443: }
;Z80Mini.c:445: void plotToLCD(void) __naked
;	---------------------------------
; Function plotToLCD
; ---------------------------------
_plotToLCD::
;Z80Mini.c:450: __endasm;
	call	0x015D
	ret
;Z80Mini.c:451: }
;Z80Mini.c:457: void printString(uint8_t line, char *txt)
;	---------------------------------
; Function printString
; ---------------------------------
_printString::
;Z80Mini.c:471: __endasm;
;	A = line
;	HL = txt
	call	0x0160
	ret
;Z80Mini.c:472: }
;Z80Mini.c:474: void printChars(
;	---------------------------------
; Function printChars
; ---------------------------------
_printChars::
;Z80Mini.c:494: __endasm;
	ld	b, a
	ld	c, l
	ex	de, hl
	call	0x0163
	ret
;Z80Mini.c:495: }
;Z80Mini.c:501: void setBufClear(void) __naked
;	---------------------------------
; Function setBufClear
; ---------------------------------
_setBufClear::
;Z80Mini.c:506: __endasm;
	call	0x016C
	ret
;Z80Mini.c:507: }
;Z80Mini.c:509: void setBufNoClear(void) __naked
;	---------------------------------
; Function setBufNoClear
; ---------------------------------
_setBufNoClear::
;Z80Mini.c:514: __endasm;
	call	0x016F
	ret
;Z80Mini.c:515: }
;Z80Mini.c:521: void drawGraphic(
;	---------------------------------
; Function drawGraphic
; ---------------------------------
_drawGraphic::
;Z80Mini.c:542: __endasm;
;	A = chr
;	HL = data
;	DE = w/h
	call	0x0178
	ret
;Z80Mini.c:543: }
;Z80Mini.c:545: void invGraphic(void) __naked
;	---------------------------------
; Function invGraphic
; ---------------------------------
_invGraphic::
;Z80Mini.c:550: __endasm;
	call	0x017B
	ret
;Z80Mini.c:551: }
;Z80Mini.c:557: void initTerminal(void) __naked
;	---------------------------------
; Function initTerminal
; ---------------------------------
_initTerminal::
;Z80Mini.c:562: __endasm;
	call	0x017E
	ret
;Z80Mini.c:563: }
;Z80Mini.c:565: void sendCharToLCD(uint8_t c)
;	---------------------------------
; Function sendCharToLCD
; ---------------------------------
_sendCharToLCD::
;Z80Mini.c:573: __endasm;
	call	0x0181
	ret
;Z80Mini.c:574: }
;Z80Mini.c:576: void sendStringToLCD(
;	---------------------------------
; Function sendStringToLCD
; ---------------------------------
_sendStringToLCD::
;Z80Mini.c:590: __endasm;
	ex	de, hl
	ld	a, #0
	call	0x0184
	ret
;Z80Mini.c:591: }
;Z80Mini.c:593: void sendRegToLCD(uint8_t v)
;	---------------------------------
; Function sendRegToLCD
; ---------------------------------
_sendRegToLCD::
;Z80Mini.c:601: __endasm;
	call	0x0187
	ret
;Z80Mini.c:602: }
;Z80Mini.c:604: void sendHLToLCD(uint16_t v)
;	---------------------------------
; Function sendHLToLCD
; ---------------------------------
_sendHLToLCD::
;Z80Mini.c:612: __endasm;
	call	0x018A
	ret
;Z80Mini.c:613: }
;Z80Mini.c:615: void setCursor(
;	---------------------------------
; Function setCursor
; ---------------------------------
_setCursor::
;Z80Mini.c:631: __endasm;
	ld	b, a
	ld	c, l
	call	0x018D
	ret
;Z80Mini.c:632: }
;Z80Mini.c:634: uint16_t getCursor(void) __naked
;	---------------------------------
; Function getCursor
; ---------------------------------
_getCursor::
;Z80Mini.c:645: __endasm;
	call	0x0190
	ld	d, b
	ld	e, c
	ret
;Z80Mini.c:646: }
;Z80Mini.c:648: void displayCursor(uint8_t v)
;	---------------------------------
; Function displayCursor
; ---------------------------------
_displayCursor::
;Z80Mini.c:656: __endasm;
	call	0x0193
	ret
;Z80Mini.c:657: }
;Z80Mini.c:659: void autoLF(uint8_t v)
;	---------------------------------
; Function autoLF
; ---------------------------------
_autoLF::
;Z80Mini.c:667: __endasm;
	call	0x0196
	ret
;Z80Mini.c:668: }
;Z80Mini.c:670: void underline(void) __naked
;	---------------------------------
; Function underline
; ---------------------------------
_underline::
;Z80Mini.c:675: __endasm;
	call	0x0199
	ret
;Z80Mini.c:676: }
;Z80Mini.c:678: void plotAlways(uint8_t v)
;	---------------------------------
; Function plotAlways
; ---------------------------------
_plotAlways::
;Z80Mini.c:686: __endasm;
	call	0x019C
	ret
;Z80Mini.c:687: }
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

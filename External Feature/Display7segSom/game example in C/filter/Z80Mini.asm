;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler 
; Version 4.4.1 #14901 (MINGW64)
;--------------------------------------------------------
	.module Z80Mini
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _lcd_clear_buffer
	.globl _lcd_show_buffer
	.globl _lcd_set_xy
	.globl _lcd_drawpixel
	.globl _lcd_print_char
	.globl _lcd_print_string
	.globl _lcd_cursor_on
	.globl _lcd_cursor_off
	.globl _lcd_print_byte_to_ascii
	.globl _lcd_print_int_to_ascii
	.globl _lcd_draw_line
	.globl _lcd_draw_circle
	.globl _lcd_draw_placar
	.globl _i2c_open
	.globl _i2c_close
	.globl _i2c_read
	.globl _i2c_write
	.globl _delay_ms
	.globl _pinOut
	.globl _portOut
	.globl _pinIn
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
;../Z80Mini.c:3: void lcd_clear_buffer(void) {
;	---------------------------------
; Function lcd_clear_buffer
; ---------------------------------
_lcd_clear_buffer::
;../Z80Mini.c:8: __endasm;
	call	#0x0103 ; delay_ms in DE
;../Z80Mini.c:9: }
	ret
;../Z80Mini.c:11: void lcd_show_buffer(void) {
;	---------------------------------
; Function lcd_show_buffer
; ---------------------------------
_lcd_show_buffer::
;../Z80Mini.c:16: __endasm;
	call	#0x0124 ; delay_ms in DE
;../Z80Mini.c:17: }
	ret
;../Z80Mini.c:19: void lcd_set_xy(byte x, byte y) {
;	---------------------------------
; Function lcd_set_xy
; ---------------------------------
_lcd_set_xy::
;../Z80Mini.c:26: __endasm;
	LD	B, A
	LD	C, L
	CALL	#0x015D
;../Z80Mini.c:27: }
	ret
;../Z80Mini.c:29: void lcd_drawpixel(byte x, byte y) {
;	---------------------------------
; Function lcd_drawpixel
; ---------------------------------
_lcd_drawpixel::
;../Z80Mini.c:36: __endasm;
	LD	B, A
	LD	C, L
	CALL	#0X011B
;../Z80Mini.c:37: }
	ret
;../Z80Mini.c:39: void lcd_print_char(byte a) {
;	---------------------------------
; Function lcd_print_char
; ---------------------------------
_lcd_print_char::
;../Z80Mini.c:42: __endasm;
	call	#0x0151
;../Z80Mini.c:43: }
	ret
;../Z80Mini.c:45: void lcd_print_string(const char* s) {
;	---------------------------------
; Function lcd_print_string
; ---------------------------------
_lcd_print_string::
;../Z80Mini.c:53: __endasm;
	LD	A, #0
	LD	D, H
	LD	E, L
	CALL	#0x0154
;../Z80Mini.c:54: }
	ret
;../Z80Mini.c:56: void lcd_cursor_on(void) {
;	---------------------------------
; Function lcd_cursor_on
; ---------------------------------
_lcd_cursor_on::
;../Z80Mini.c:60: __endasm;
	LD	A, #0
	CALL	#0x0163
;../Z80Mini.c:61: }
	ret
;../Z80Mini.c:64: void lcd_cursor_off(void) {
;	---------------------------------
; Function lcd_cursor_off
; ---------------------------------
_lcd_cursor_off::
;../Z80Mini.c:68: __endasm;
	LD	A, #1
	CALL	#0x0163
;../Z80Mini.c:69: }
	ret
;../Z80Mini.c:71: void lcd_print_byte_to_ascii(byte a) {
;	---------------------------------
; Function lcd_print_byte_to_ascii
; ---------------------------------
_lcd_print_byte_to_ascii::
;../Z80Mini.c:76: __endasm;
	call	#0x0157
;../Z80Mini.c:77: }
	ret
;../Z80Mini.c:80: void lcd_print_int_to_ascii(int hl) {
;	---------------------------------
; Function lcd_print_int_to_ascii
; ---------------------------------
_lcd_print_int_to_ascii::
;../Z80Mini.c:85: __endasm;
	call	#0x015A
;../Z80Mini.c:86: }
	ret
;../Z80Mini.c:90: void lcd_draw_line(byte x0, byte y0, byte x1, byte y1) {
;	---------------------------------
; Function lcd_draw_line
; ---------------------------------
_lcd_draw_line::
;../Z80Mini.c:106: __endasm;
	LD	B, A
	LD	C, L
	ld	iy, #2
	add	iy, sp
	ld	d, (iy)
	ld	iy, #3
	add	iy, sp
	ld	e, (iy)
	CALL	#0x0115
;../Z80Mini.c:107: }
	pop	hl
	pop	af
	jp	(hl)
;../Z80Mini.c:110: void lcd_draw_circle(byte x, byte y, byte r) {
;	---------------------------------
; Function lcd_draw_circle
; ---------------------------------
_lcd_draw_circle::
;../Z80Mini.c:122: __endasm;
	LD	B, A
	LD	C, L
	ld	iy, #2
	add	iy, sp
	ld	e, (iy)
	CALL	#0x0118
;../Z80Mini.c:123: }
	pop	hl
	inc	sp
	jp	(hl)
;../Z80Mini.c:126: void lcd_draw_placar(byte p) {
;	---------------------------------
; Function lcd_draw_placar
; ---------------------------------
_lcd_draw_placar::
;../Z80Mini.c:134: __endasm;
	PUSH	AF
	LD	BC, #0x0000
	call	0x015D
	POP	AF
	daa
	CALL	0x0157
;../Z80Mini.c:135: }
	ret
;../Z80Mini.c:138: void i2c_open(byte device) {
;	---------------------------------
; Function i2c_open
; ---------------------------------
_i2c_open::
;../Z80Mini.c:143: __endasm;
	call	#0x016C
;../Z80Mini.c:144: }
	ret
;../Z80Mini.c:146: void i2c_close(void) {
;	---------------------------------
; Function i2c_close
; ---------------------------------
_i2c_close::
;../Z80Mini.c:151: __endasm;
	call	#0x016F
;../Z80Mini.c:152: }
	ret
;../Z80Mini.c:154: byte i2c_read(void) {
;	---------------------------------
; Function i2c_read
; ---------------------------------
_i2c_read::
;../Z80Mini.c:159: __endasm;
	call	#0x0172
;../Z80Mini.c:160: }
	ret
;../Z80Mini.c:162: void i2c_write(byte b) {
;	---------------------------------
; Function i2c_write
; ---------------------------------
_i2c_write::
;../Z80Mini.c:167: __endasm;
	call	#0x0175
;../Z80Mini.c:168: }
	ret
;../Z80Mini.c:170: void delay_ms(int time)  {
;	---------------------------------
; Function delay_ms
; ---------------------------------
_delay_ms::
;../Z80Mini.c:176: __endasm;
	ex	de, hl
	call	#0x0166 ; delay_ms in DE
;../Z80Mini.c:177: }
	ret
;../Z80Mini.c:179: void pinOut(byte pin, byte state)  {
;	---------------------------------
; Function pinOut
; ---------------------------------
_pinOut::
;../Z80Mini.c:187: __endasm;
	ld	c, a
	ld	a, l
	out(c),	a
;../Z80Mini.c:188: }
	ret
;../Z80Mini.c:190: void portOut(byte port, byte outByte) {
;	---------------------------------
; Function portOut
; ---------------------------------
_portOut::
;../Z80Mini.c:199: __endasm;
	ld	c, a
	ld	a, l
	out(c),	a
;../Z80Mini.c:200: }
	ret
;../Z80Mini.c:202: byte pinIn(byte pin) {
;	---------------------------------
; Function pinIn
; ---------------------------------
_pinIn::
;../Z80Mini.c:210: __endasm;
	ld	c, a
	in	a, (c)
;../Z80Mini.c:211: }
	ret
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler 
; Version 4.4.1 #14901 (MINGW64)
;--------------------------------------------------------
	.module main
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _pinIn
	.globl _delay_ms
	.globl _i2c_write
	.globl _i2c_close
	.globl _i2c_open
	.globl _lcd_draw_circle
	.globl _lcd_draw_line
	.globl _lcd_cursor_off
	.globl _lcd_show_buffer
	.globl _lcd_clear_buffer
	.globl _pontos
	.globl _new_ball
	.globl _incPontos
	.globl _showPontos
	.globl _showVidas
	.globl _hitSound
	.globl _gameoverSound
	.globl _fireInvSound
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
_pontos::
	.ds 1
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
;main.c:15: int main(void) {
;	---------------------------------
; Function main
; ---------------------------------
_main::
	call	___sdcc_enter_ix
	ld	hl, #-6
	add	hl, sp
	ld	sp, hl
;main.c:16: byte px=60;
	ld	-6 (ix), #0x3c
;main.c:18: byte count=0;
	ld	-5 (ix), #0x00
;main.c:19: pontos=0;
	xor	a, a
	ld	(_pontos+0), a
;main.c:20: byte erros=3;
	ld	-4 (ix), #0x03
;main.c:22: byte bx=60;
	ld	-3 (ix), #0x3c
;main.c:23: byte by=3;
	ld	-2 (ix), #0x03
;main.c:25: lcd_cursor_off();
	call	_lcd_cursor_off
;main.c:27: lcd_clear_buffer();
	call	_lcd_clear_buffer
;main.c:30: i2c_open(0x0E);
	ld	a, #0x0e
	call	_i2c_open
;main.c:31: i2c_write(0x00);
	xor	a, a
	call	_i2c_write
;main.c:32: i2c_write(0x01); // Liga somente o display LOW (3 e 4)
	ld	a, #0x01
	call	_i2c_write
;main.c:33: i2c_close();
	call	_i2c_close
;main.c:35: showPontos(pontos);
	ld	a, (_pontos)
	call	_showPontos
;main.c:36: showVidas(erros);
	ld	a, #0x03
	call	_showVidas
;main.c:38: while(TRUE) {
00123$:
;main.c:40: byte read = pinIn(#0x40);
	ld	a, #0x40
	call	_pinIn
	ld	e, a
;main.c:42: byte input = 0;
	ld	-1 (ix), #0x00
;main.c:43: if (read != 0) {
	ld	a, e
	or	a, a
	jr	Z, 00102$
;main.c:44: input = read;
	ld	-1 (ix), e
00102$:
;main.c:48: if (count >= 10) {
	ld	a, -5 (ix)
	sub	a, #0x0a
	jp	C, 00121$
;main.c:54: if (input == 0x40) {
	ld	a, -1 (ix)
	sub	a, #0x40
	jr	NZ, 00106$
;main.c:55: if (px > 2) {
	ld	a, #0x02
	sub	a, -6 (ix)
	jr	NC, 00106$
;main.c:56: px = px - 3;
	ld	a, -6 (ix)
	add	a, #0xfd
	ld	-6 (ix), a
00106$:
;main.c:60: if (input == 0x10) {
	ld	a, -1 (ix)
	sub	a, #0x10
	jr	NZ, 00110$
;main.c:61: if (px < 116) {
	ld	a, -6 (ix)
	sub	a, #0x74
	jr	NC, 00110$
;main.c:62: px = px + 3;
	ld	a, -6 (ix)
	add	a, #0x03
	ld	-6 (ix), a
00110$:
;main.c:67: lcd_clear_buffer();
	call	_lcd_clear_buffer
;main.c:68: lcd_draw_line(px, py, px+10, py);
	ld	a, -6 (ix)
	ld	-1 (ix), a
	add	a, #0x0a
	ld	h, #0x3c
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	l, #0x3c
	ld	a, -6 (ix)
	call	_lcd_draw_line
;main.c:69: lcd_draw_circle(bx, by, 1);
	ld	a, #0x01
	push	af
	inc	sp
	ld	l, -2 (ix)
	ld	a, -3 (ix)
	call	_lcd_draw_circle
;main.c:70: lcd_show_buffer();
	call	_lcd_show_buffer
;main.c:74: if (py == by) {
	ld	a, -2 (ix)
	sub	a, #0x3c
	jr	NZ, 00115$
;main.c:75: if (bx+1 >= px && bx <= px+10) {
	ld	c, -3 (ix)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	inc	hl
	ld	e, -6 (ix)
	xor	a, a
	ld	d, a
	sbc	hl, de
	jr	C, 00115$
	ld	hl, #0x000a
	add	hl, de
	ld	a, l
	sub	a, c
	ld	a, h
	sbc	a, b
	jp	PO, 00217$
	xor	a, #0x80
00217$:
	jp	M, 00115$
;main.c:76: incPontos();
	call	_incPontos
;main.c:77: showPontos(pontos);
	ld	a, (_pontos)
	call	_showPontos
;main.c:78: bx = new_ball();
	call	_new_ball
	ld	-3 (ix), a
;main.c:79: by = 1;
	ld	-2 (ix), #0x01
;main.c:80: hitSound();
	call	_hitSound
00115$:
;main.c:84: if (by > 65) {
	ld	a, #0x41
	sub	a, -2 (ix)
	jr	NC, 00117$
;main.c:85: bx = new_ball();
	call	_new_ball
	ld	-3 (ix), a
;main.c:86: by = 1;
	ld	-2 (ix), #0x01
;main.c:87: erros = erros - 1;
;main.c:88: showVidas(erros);
	dec	-4 (ix)
	ld	a, -4 (ix)
	call	_showVidas
;main.c:89: fireInvSound();
	call	_fireInvSound
00117$:
;main.c:92: if (erros == 0) {
	ld	a, -4 (ix)
	or	a, a
	jr	NZ, 00119$
;main.c:93: erros = 3;
	ld	-4 (ix), #0x03
;main.c:94: pontos = 0;
;main.c:96: showPontos(pontos);
	xor	a, a
	ld	(_pontos+0), a
	call	_showPontos
;main.c:97: showVidas(erros);
	ld	a, #0x03
	call	_showVidas
;main.c:98: gameoverSound();
	call	_gameoverSound
00119$:
;main.c:100: by=by+1;
	inc	-2 (ix)
;main.c:101: count=0;
	ld	-5 (ix), #0x00
00121$:
;main.c:103: count = count + 1;
	inc	-5 (ix)
;main.c:104: delay_ms(1);
	ld	hl, #0x0001
	call	_delay_ms
;main.c:106: }
	jp	00123$
;main.c:108: byte new_ball() {
;	---------------------------------
; Function new_ball
; ---------------------------------
_new_ball::
;main.c:109: while(1) {
00105$:
;main.c:110: byte x = rand();
	call	_rand
	ld	a, e
;main.c:111: if (x > 3 && x < 124) {
	cp	a, #0x04
	jr	C, 00105$
	cp	a, #0x7c
	jr	NC, 00105$
;main.c:112: return x;
;main.c:115: }
	ret
;main.c:117: void incPontos(void) __naked {
;	---------------------------------
; Function incPontos
; ---------------------------------
_incPontos::
;main.c:124: __endasm;
	ld	a, (_pontos) ; carrega o valor atual em A
	add	a, #1 ; incrementa 1
	daa	; ajusta para BCD
	ld	(_pontos), a ; salva de volta
	ret
;main.c:125: }
;main.c:127: void showPontos(byte p) {
;	---------------------------------
; Function showPontos
; ---------------------------------
_showPontos::
	ld	c, a
;main.c:128: i2c_open(0x0E);
	push	bc
	ld	a, #0x0e
	call	_i2c_open
	ld	a, #0x01
	call	_i2c_write
	pop	bc
;main.c:130: i2c_write(p);
	ld	a, c
	call	_i2c_write
;main.c:131: i2c_close();
;main.c:132: }
	jp	_i2c_close
;main.c:134: void showVidas(byte v) {
;	---------------------------------
; Function showVidas
; ---------------------------------
_showVidas::
	ld	c, a
;main.c:135: i2c_open(0x0E);
	push	bc
	ld	a, #0x0e
	call	_i2c_open
	ld	a, #0x03
	call	_i2c_write
	pop	bc
;main.c:137: i2c_write(v);
	ld	a, c
	call	_i2c_write
;main.c:138: i2c_close();
;main.c:139: }
	jp	_i2c_close
;main.c:141: void hitSound() {
;	---------------------------------
; Function hitSound
; ---------------------------------
_hitSound::
;main.c:142: i2c_open(0x0E);
	ld	a, #0x0e
	call	_i2c_open
;main.c:143: i2c_write(0x05);
	ld	a, #0x05
	call	_i2c_write
;main.c:144: i2c_write(0x12);
	ld	a, #0x12
	call	_i2c_write
;main.c:145: i2c_close();
;main.c:146: }
	jp	_i2c_close
;main.c:148: void gameoverSound() {
;	---------------------------------
; Function gameoverSound
; ---------------------------------
_gameoverSound::
;main.c:149: i2c_open(0x0E);
	ld	a, #0x0e
	call	_i2c_open
;main.c:150: i2c_write(0x05);
	ld	a, #0x05
	call	_i2c_write
;main.c:151: i2c_write(0x10);
	ld	a, #0x10
	call	_i2c_write
;main.c:152: i2c_close();
;main.c:153: }
	jp	_i2c_close
;main.c:155: void fireInvSound() {
;	---------------------------------
; Function fireInvSound
; ---------------------------------
_fireInvSound::
;main.c:156: i2c_open(0x0E);
	ld	a, #0x0e
	call	_i2c_open
;main.c:157: i2c_write(0x05);
	ld	a, #0x05
	call	_i2c_write
;main.c:158: i2c_write(0x01);
	ld	a, #0x01
	call	_i2c_write
;main.c:159: i2c_close();
;main.c:160: }
	jp	_i2c_close
	.area _CODE
	.area _INITIALIZER
__xinit__pontos:
	.db #0x00	; 0
	.area _CABS (ABS)

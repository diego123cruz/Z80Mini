;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.0 #15242 (Linux)
;--------------------------------------------------------
	.module main
	
	.optsdcc -mz80 sdcccall(1)
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _displayCursor
	.globl _plotToLCD
	.globl _drawCircle
	.globl _drawLine
	.globl _clearGBUF
	.globl _keyboardA
	.globl _I2C_Write
	.globl _I2C_Close
	.globl _I2C_Open
	.globl _delay
	.globl _by
	.globl _bx
	.globl _erros
	.globl _count
	.globl _py
	.globl _px
	.globl _input
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
_pontos::
	.ds 1
_input::
	.ds 1
_px::
	.ds 1
_py::
	.ds 1
_count::
	.ds 1
_erros::
	.ds 1
_bx::
	.ds 1
_by::
	.ds 1
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
;main.c:22: int main(void) {
;	---------------------------------
; Function main
; ---------------------------------
_main::
;main.c:24: pontos=0;
	xor	a, a
	ld	(#_pontos),a
;main.c:25: px=60;
	ld	hl, #_px
	ld	(hl), #0x3c
;main.c:26: py=60;
	ld	hl, #_py
	ld	(hl), #0x3c
;main.c:27: count=0;
	xor	a, a
	ld	(#_count),a
;main.c:28: erros=3;
	ld	hl, #_erros
	ld	(hl), #0x03
;main.c:29: bx=60;
	ld	hl, #_bx
	ld	(hl), #0x3c
;main.c:30: by=3;
	ld	hl, #_by
	ld	(hl), #0x03
;main.c:32: displayCursor(1);
	ld	a, #0x01
	call	_displayCursor
;main.c:34: clearGBUF();
	call	_clearGBUF
;main.c:37: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:38: I2C_Write(0x00);
	xor	a, a
	call	_I2C_Write
;main.c:39: I2C_Write(0x01); // Liga somente o display LOW (3 e 4)
	ld	a, #0x01
	call	_I2C_Write
;main.c:40: I2C_Close();
	call	_I2C_Close
;main.c:42: showPontos(pontos);
	ld	a, (_pontos)
	call	_showPontos
;main.c:43: showVidas(erros);
	ld	a, (_erros)
	call	_showVidas
;main.c:45: while(TRUE) {
00121$:
;main.c:47: input = keyboardA();
	call	_keyboardA
	ld	(#_input),a
;main.c:49: if (count >= 10) {
	ld	a, (#_count)
	sub	a, #0x0a
	jp	C, 00119$
;main.c:52: if (input == 'a') {
	ld	a, (#_input)
	sub	a, #0x61
	jr	NZ, 00104$
;main.c:53: if (px > 2) {
	ld	a, #0x02
	ld	hl, #_px
	sub	a, (hl)
	jr	NC, 00104$
;main.c:54: px = px - 3;
	ld	a, (hl)
	add	a, #0xfd
	ld	(hl), a
00104$:
;main.c:58: if (input == 'd') {
	ld	a, (#_input)
	sub	a, #0x64
	jr	NZ, 00108$
;main.c:59: if (px < 116) {
	ld	hl, #_px
;main.c:60: px = px + 3;
	ld	a,(hl)
	cp	a,#0x74
	jr	NC, 00108$
	add	a, #0x03
	ld	(hl), a
00108$:
;main.c:65: clearGBUF();
	call	_clearGBUF
;main.c:67: drawLine(px, py, px+10, py);
	ld	a, (_px)
	add	a, #0x0a
	ld	hl, #_py
	ld	h, (hl)
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	a, (_py)
	ld	l, a
	ld	a, (_px)
	call	_drawLine
;main.c:69: drawCircle(bx, by, 1);
	ld	a, #0x01
	push	af
	inc	sp
	ld	a, (_by)
	ld	l, a
	ld	a, (_bx)
	call	_drawCircle
;main.c:71: plotToLCD();
	call	_plotToLCD
;main.c:73: if (py == by) {
	ld	a, (#_py)
	ld	hl, #_by
	sub	a, (hl)
	jr	NZ, 00113$
;main.c:74: if (bx+1 >= px && bx <= px+10) {
	ld	a, (_bx)
	ld	c, a
	ld	b, #0x00
	ld	l, c
	ld	h, b
	inc	hl
	ld	a, (_px)
	ld	e, a
	xor	a, a
	ld	d, a
	sbc	hl, de
	jr	C, 00113$
	ld	hl, #0x000a
	add	hl, de
	xor	a, a
	sbc	hl, bc
	jr	C, 00113$
;main.c:75: incPontos();
	call	_incPontos
;main.c:76: showPontos(pontos);
	ld	a, (_pontos)
	call	_showPontos
;main.c:77: bx = new_ball();
	call	_new_ball
	ld	(#_bx),a
;main.c:78: by = 1;
	ld	hl, #_by
	ld	(hl), #0x01
;main.c:79: hitSound();
	call	_hitSound
00113$:
;main.c:83: if (by > 65) {
	ld	a, #0x41
	ld	hl, #_by
	sub	a, (hl)
	jr	NC, 00115$
;main.c:84: bx = new_ball();
	call	_new_ball
	ld	(#_bx),a
;main.c:85: by = 1;
	ld	hl, #_by
	ld	(hl), #0x01
;main.c:86: erros = erros - 1;
	ld	a, (_erros)
	dec	a
;main.c:87: showVidas(erros);
	ld	(#_erros),a
	call	_showVidas
;main.c:88: fireInvSound();
	call	_fireInvSound
00115$:
;main.c:91: if (erros == 0) {
	ld	hl, #_erros
	ld	a, (hl)
	or	a, a
	jr	NZ, 00117$
;main.c:92: erros = 3;
	ld	(hl), #0x03
;main.c:93: pontos = 0;
;main.c:95: showPontos(pontos);
	xor	a, a
	ld	(#_pontos), a
	call	_showPontos
;main.c:96: showVidas(erros);
	ld	a, (_erros)
	call	_showVidas
;main.c:97: gameoverSound();
	call	_gameoverSound
00117$:
;main.c:99: by=by+1;
	ld	a, (_by)
	inc	a
	ld	(#_by),a
;main.c:100: count=0;
	xor	a, a
	ld	(#_count),a
00119$:
;main.c:102: count = count + 1;
	ld	a, (_count)
	inc	a
	ld	(#_count),a
;main.c:103: delay(1);
	ld	hl, #0x0001
	call	_delay
;main.c:105: }
	jp	00121$
;main.c:107: byte new_ball() {
;	---------------------------------
; Function new_ball
; ---------------------------------
_new_ball::
;main.c:108: while(1) {
00105$:
;main.c:109: byte x = rand();
	call	_rand
	ld	a, e
;main.c:110: if (x > 3 && x < 124) {
	cp	a, #0x04
	jr	C, 00105$
	cp	a, #0x7c
	jr	NC, 00105$
;main.c:111: return x;
;main.c:114: }
	ret
;main.c:116: void incPontos(void) __naked {
;	---------------------------------
; Function incPontos
; ---------------------------------
_incPontos::
;main.c:123: __endasm;
	ld	a, (_pontos) ; carrega o valor atual em A
	add	a, #1 ; incrementa 1
	daa	; ajusta para BCD
	ld	(_pontos), a ; salva de volta
	ret
;main.c:124: }
;main.c:126: void showPontos(byte p) {
;	---------------------------------
; Function showPontos
; ---------------------------------
_showPontos::
	call	___sdcc_enter_ix
	dec	sp
	ld	-1 (ix), a
;main.c:127: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:128: I2C_Write(0x01);
	ld	a, #0x01
	call	_I2C_Write
;main.c:129: I2C_Write(p);
	ld	a, -1 (ix)
	call	_I2C_Write
;main.c:130: I2C_Close();
	call	_I2C_Close
;main.c:131: }
	inc	sp
	pop	ix
	ret
;main.c:133: void showVidas(byte v) {
;	---------------------------------
; Function showVidas
; ---------------------------------
_showVidas::
	call	___sdcc_enter_ix
	dec	sp
	ld	-1 (ix), a
;main.c:134: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:135: I2C_Write(0x03);
	ld	a, #0x03
	call	_I2C_Write
;main.c:136: I2C_Write(v);
	ld	a, -1 (ix)
	call	_I2C_Write
;main.c:137: I2C_Close();
	call	_I2C_Close
;main.c:138: }
	inc	sp
	pop	ix
	ret
;main.c:140: void hitSound() {
;	---------------------------------
; Function hitSound
; ---------------------------------
_hitSound::
;main.c:141: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:142: I2C_Write(0x05);
	ld	a, #0x05
	call	_I2C_Write
;main.c:143: I2C_Write(0x12);
	ld	a, #0x12
	call	_I2C_Write
;main.c:144: I2C_Close();
;main.c:145: }
	jp	_I2C_Close
;main.c:147: void gameoverSound() {
;	---------------------------------
; Function gameoverSound
; ---------------------------------
_gameoverSound::
;main.c:148: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:149: I2C_Write(0x05);
	ld	a, #0x05
	call	_I2C_Write
;main.c:150: I2C_Write(0x10);
	ld	a, #0x10
	call	_I2C_Write
;main.c:151: I2C_Close();
;main.c:152: }
	jp	_I2C_Close
;main.c:154: void fireInvSound() {
;	---------------------------------
; Function fireInvSound
; ---------------------------------
_fireInvSound::
;main.c:155: I2C_Open(0x0E);
	ld	a, #0x0e
	call	_I2C_Open
;main.c:156: I2C_Write(0x05);
	ld	a, #0x05
	call	_I2C_Write
;main.c:157: I2C_Write(0x01);
	ld	a, #0x01
	call	_I2C_Write
;main.c:158: I2C_Close();
;main.c:159: }
	jp	_I2C_Close
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

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
	.globl _setCursor
	.globl _sendStringToLCD
	.globl _plotToLCD
	.globl _drawBox
	.globl _clearGBUF
	.globl _delay
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
;main.c:5: void main(void) {
;	---------------------------------
; Function main
; ---------------------------------
_main::
	call	___sdcc_enter_ix
	push	af
;main.c:7: byte x = 3;
;main.c:8: byte y = 3;
	ld	bc, #0x303
;main.c:9: sbyte vx=2;
	ld	-2 (ix), #0x02
;main.c:10: sbyte vy=2;
	ld	-1 (ix), #0x02
;main.c:13: while(TRUE) {
00110$:
;main.c:14: clearGBUF();
	push	bc
	call	_clearGBUF
;main.c:15: drawBox(0,0,127,63);
	ld	hl, #0x3f7f
	push	hl
	xor	a, a
	ld	l, a
	call	_drawBox
	pop	bc
;main.c:16: setCursor(x, y);
	push	bc
	ld	l, b
	ld	a, c
	call	_setCursor
;main.c:17: sendStringToLCD("Z80Mini");
	ld	hl, #___str_0
	call	_sendStringToLCD
	pop	bc
;main.c:20: if(x > 84) {
	ld	a, #0x54
	sub	a, c
	jr	NC, 00102$
;main.c:21: vx=-2;
	ld	-2 (ix), #0xfe
00102$:
;main.c:23: if (y > 55) {
	ld	a, #0x37
	sub	a, b
	jr	NC, 00104$
;main.c:24: vy=-2;
	ld	-1 (ix), #0xfe
00104$:
;main.c:26: if(x < 2) {
	ld	a, c
	sub	a, #0x02
	jr	NC, 00106$
;main.c:27: vx=2;
	ld	-2 (ix), #0x02
00106$:
;main.c:29: if(y < 2) {
	ld	a, b
	sub	a, #0x02
	jr	NC, 00108$
;main.c:30: vy=2;
	ld	-1 (ix), #0x02
00108$:
;main.c:33: plotToLCD();
	push	bc
	call	_plotToLCD
;main.c:35: delay(10);
	ld	hl, #0x000a
	call	_delay
	pop	bc
;main.c:37: x = x+vx;
	ld	a, c
	add	a, -2 (ix)
	ld	c, a
;main.c:38: y = y+vy;
	ld	a, b
	add	a, -1 (ix)
	ld	b, a
	jr	00110$
;main.c:41: }
	pop	af
	pop	ix
	ret
___str_0:
	.ascii "Z80Mini"
	.db 0x00
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

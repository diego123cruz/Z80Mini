#include "Z80Mini.h"

void lcd_clear_buffer(void) {
    __asm

	call	#_CLEAR_GBUF			; delay_ms in DE 

	__endasm;
}

void lcd_show_buffer(void) {
    __asm

	call	#_PLOT_TO_LCD			; delay_ms in DE 

	__endasm;
}

void lcd_set_xy(byte x, byte y) {
    __asm
    
    LD B, A
    LD C, L
    CALL    #_SET_CURSOR 

	__endasm;
}

void lcd_drawpixel(byte x, byte y) {
    __asm
    
    LD B, A
    LD C, L
    CALL    #_DRAW_PIXEL 

	__endasm;
}

void lcd_print_char(byte a) {
    __asm
    call #_SEND_CHAR_TO_GLCD
    __endasm;
}

void lcd_print_string(const char* s) {
    __asm

    LD A, #0
    LD D, H
    LD E, L
    CALL    #_SEND_STRING_TO_GLCD 

	__endasm;
}

void lcd_cursor_on(void) {
    __asm
    LD A, #0
    CALL #_DISPLAY_CURSOR
    __endasm;
}


void lcd_cursor_off(void) {
    __asm
    LD A, #1
    CALL #_DISPLAY_CURSOR
    __endasm;
}

void lcd_print_byte_to_ascii(byte a) {
    __asm

    call #_SEND_A_TO_GLCD

    __endasm;
}


void lcd_print_int_to_ascii(int hl) {
    __asm

    call #_SEND_HL_TO_GLCD

    __endasm;
}

//Inputs: BC = X0,Y0
//        DE = X1,Y1
void lcd_draw_line(byte x0, byte y0, byte x1, byte y1) {
    __asm

    LD B, A
    LD C, L

    ld iy, #2
	add iy, sp
	ld d, (iy)

    ld iy, #3
	add iy, sp
	ld e, (iy)

    CALL #_DRAW_LINE
   
    __endasm;
}

// BC = xm,ym (Midpoint) E = radius
void lcd_draw_circle(byte x, byte y, byte r) {
    __asm

    LD B, A
    LD C, L

    ld iy, #2
	add iy, sp
	ld e, (iy)

    CALL #_DRAW_CIRCLE

    __endasm;
}


void lcd_draw_placar(byte p) {
    __asm
    PUSH AF
    LD BC, #0x0000
    call _SET_CURSOR
    POP AF
    daa
    CALL _SEND_A_TO_GLCD
    __endasm;
}


void i2c_open(byte device) {
    __asm

    call #_I2C_Open

    __endasm;
}

void i2c_close(void) {
    __asm

    call #_I2C_Close

    __endasm;
}

byte i2c_read(void) {
    __asm

    call #_I2C_Read

    __endasm;
}

void i2c_write(byte b) {
    __asm

    call #_I2C_Write

    __endasm;
}

void delay_ms(int time)  {
    __asm

	ex de, hl
	call	#_DELAY_MS			; delay_ms in DE

	__endasm;
}

void pinOut(byte pin, byte state)  {
    // A - pin, L - state
    __asm

    ld c, a
    ld a, l
    out(c), a

    __endasm;
}

void portOut(byte port, byte outByte) {
    // A - port, L - outByte
    __asm

    ld c, a
    ld a, l
    out(c), a
    

    __endasm;
}

byte pinIn(byte pin) {
    // input pin - A
    // return in A
    __asm

    ld c, a 
    in a, (c)

    __endasm;
}
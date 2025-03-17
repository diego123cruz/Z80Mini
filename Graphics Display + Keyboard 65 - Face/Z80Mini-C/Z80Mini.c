#include "Z80Mini.h"


void lcd_clear_buffer(void) __naked {
    __asm

	call	#_CLEAR_GBUF			; delay_ms in DE
	ret 

	__endasm;
}

void lcd_show_buffer(void) __naked {
    __asm

	call	#_PLOT_TO_LCD			; delay_ms in DE
	ret 

	__endasm;
}

void lcd_set_xy(byte x, byte y) __naked {
    __asm
    
    LD B, A
    LD C, L
    CALL    #_SET_CURSOR
	ret 

	__endasm;
}

void lcd_print_char(byte a) __naked {
    __asm
    call #_SEND_CHAR_TO_GLCD
    ret
    __endasm;
}

void lcd_print_string(const char* s) __naked {
    __asm

    LD A, #0
    LD D, H
    LD E, L
    CALL    #_SEND_STRING_TO_GLCD
	ret 

	__endasm;
}

void lcd_cursor_on(void) __naked {
    __asm
    LD A, #0
    CALL #_DISPLAY_CURSOR
    RET
    __endasm;
}


void lcd_cursor_off(void) __naked {
    __asm
    LD A, #1
    CALL #_DISPLAY_CURSOR
    RET
    __endasm;
}

void lcd_print_byte_to_ascii(byte a) __naked {
    __asm

    call #_SEND_A_TO_GLCD
    ret

    __endasm;
}

void lcd_print_int_to_ascii(int hl) __naked {
    __asm

    call #_SEND_HL_TO_GLCD
    ret

    __endasm;
}

void i2c_open(byte device) __naked {
    __asm

    call #_I2C_Open
    ret

    __endasm;
}

void i2c_close(void) __naked {
    __asm

    call #_I2C_Close
    ret

    __endasm;
}

byte i2c_read(void) __naked {
    __asm

    call #_I2C_Read
    ret

    __endasm;
}

void i2c_write(byte b) __naked {
    __asm

    call #_I2C_Write
    ret

    __endasm;
}

byte key_read_wait_press(void) __naked {
    __asm

    call #_KEYREADINIT
    ret

    __endasm;
}

byte key_read(void) __naked {
    __asm

    call #_KEYREAD
    ret

    __endasm;
}


void delay_ms(int time) __naked {
    __asm

	ex de, hl
	call	#_DELAY_MS			; delay_ms in DE
	ret 

	__endasm;
}

void pinOut(byte pin, byte state) __naked {
    // A - pin, L - state
    __asm

    ld c, a
    ld a, l
    out(c), a
    ret

    __endasm;
}

void portOut(byte port, byte outByte) __naked {
    // A - port, L - outByte
    __asm

    ld c, a
    ld a, l
    out(c), a
    ret

    __endasm;
}

byte pinIn(byte pin) __naked {
    // input pin - A
    // return in A
    __asm

    ld c, a 
    in a, (c)
    ret

    __endasm;
}
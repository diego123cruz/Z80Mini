/* =========================================================
   z80mini.c
   ========================================================= */

#include "Z80Mini.h"

/* =========================================================
   DELAY
   ========================================================= */

void delay500ms(void) __naked
{
__asm
    call 0x0100
    ret
__endasm;
}

void delay(uint16_t ms) __naked __sdcccall(1)
{
    ms;

__asm

    ex de,hl
    call 0x0103

    ret
__endasm;
}

/* =========================================================
   I2C
   ========================================================= */

void I2C_Open(uint8_t addr) __naked __sdcccall(1)
{
    addr;

__asm
    call 0x0106
    ret
__endasm;
}

void I2C_Close(void) __naked
{
__asm
    call 0x0109
    ret
__endasm;
}

uint8_t I2C_Read(void) __naked
{
__asm
    call 0x010C
    ret
__endasm;
}

void I2C_Write(uint8_t data) __naked __sdcccall(1)
{
    data;

__asm
    call 0x010F
    ret
__endasm;
}

/* =========================================================
   KEYBOARD
   ========================================================= */

uint8_t keyboardIsEsc(void) __naked
{
__asm
    call 0x0112
    ret
__endasm;
}

uint8_t keyboardWaitA(void) __naked
{
__asm
    call 0x0115
    ret
__endasm;
}

uint8_t keyboardA(void) __naked
{
__asm
    call 0x0118
    ret
__endasm;
}

/* =========================================================
   SERIAL
   ========================================================= */

void setDefaultSerialA(void) __naked
{
__asm
    call 0x011B
    ret
__endasm;
}

void setDefaultSerialB(void) __naked
{
__asm
    call 0x011E
    ret
__endasm;
}

void serialPrintA(uint8_t c) __naked __sdcccall(1)
{
    c;

__asm
    call 0x0121
    ret
__endasm;
}

uint8_t serialInputA(void) __naked
{
__asm
    call 0x0124
    ret
__endasm;
}

void serialPrintStr(char *s) __naked __sdcccall(1)
{
    s;

__asm
    call 0x0127
    ret
__endasm;
}

void serialCRLF(void) __naked
{
__asm
    call 0x012A
    ret
__endasm;
}

void serialHexA(uint8_t v) __naked __sdcccall(1)
{
    v;

__asm
    call 0x012D
    ret
__endasm;
}

void serialHexHL(uint16_t v) __naked __sdcccall(1)
{
    v;

__asm
    call 0x0130
    ret
__endasm;
}

uint8_t serialInHexA(void) __naked
{
__asm
    call 0x0133
    ret
__endasm;
}

uint16_t serialInHexHL(void) __naked
{
__asm
    call 0x0136
    ret
__endasm;
}

/* =========================================================
   LCD
   ========================================================= */

void initLCD(void) __naked
{
__asm
    call 0x0139
    ret
__endasm;
}

void clearGBUF(void) __naked
{
__asm

    call 0x013C

    ret
__endasm;
}

void clearGrLCD(void) __naked
{
__asm
    call 0x013F
    ret
__endasm;
}

void clearTxtLCD(void) __naked
{
__asm
    call 0x0142
    ret
__endasm;
}

void setGrMode(void) __naked
{
__asm
    call 0x0145
    ret
__endasm;
}

void setTxtMode(void) __naked
{
__asm
    call 0x0148
    ret
__endasm;
}

/* =========================================================
   DESENHO
   ========================================================= */

void drawBox(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1)
{
    x0;
    y0;
    x1;
    y1;

__asm

    ld  b, a
    ld  c, l

    ld  hl, #2
    add hl, sp

    ld  d, (hl)
    inc hl
    ld  e, (hl)

    call 0x014B
    
    pop hl      ; retorno
    pop de      ; remove x1/y1
    push hl     ; restaura retorno

    ret

__endasm;
}

void drawLine(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1)
{
    x0;
    y0;
    x1;
    y1;

__asm

    ld  b, a
    ld  c, l

    ld  hl, #2
    add  hl, sp

    ld   d, (hl)
    inc  hl
    ld  e, (hl)

    call 0x014E

    pop hl      ; retorno
    pop de      ; remove x1/y1
    push hl     ; restaura retorno

    ret

__endasm;
}

void fillBox(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1)
{
    x0;
    y0;
    x1;
    y1;

__asm

    ld  b, a
    ld  c, l

    ld  hl, #2
    add  hl, sp

    ld   d, (hl)
    inc  hl
    ld  e, (hl)

    call 0x0157

    pop hl      ; retorno
    pop de      ; remove x1/y1
    push hl     ; restaura retorno
    
    ret

__endasm;
}

void drawCircle(
    uint8_t x,
    uint8_t y,
    uint8_t radius
) __naked __sdcccall(1)
{
    x;
    y;
    radius;

__asm

    ld  b, a
    ld  c, l

    ld  hl, #2
    add hl, sp

    ld  e, (hl)

    call 0x0151

    pop hl      ; retorno
    pop de      ; remove x1/y1
    push hl     ; restaura retorno

    ret

__endasm;
}

void fillCircle(
    uint8_t x,
    uint8_t y,
    uint8_t radius
) __naked __sdcccall(1)
{
    x;
    y;
    radius;

__asm

    ld  b, a
    ld  c, l

    ld  hl, #2
    add hl, sp

    ld  e, (hl)

    call 0x015A

    pop hl      ; retorno
    pop de      ; remove x1/y1
    push hl     ; restaura retorno

    ret

__endasm;
}

void drawPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1)
{
    x;
    y;

__asm

    ld b, a
    ld c, l

    call 0x0154
    ret

__endasm;
}

void clearPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1)
{
    x;
    y;

__asm

    ld b, a
    ld c, l

    call 0x0172
    ret

__endasm;
}

void flipPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1)
{
    x;
    y;

__asm

    ld b, a
    ld c, l

    call 0x0175
    ret

__endasm;
}

void plotToLCD(void) __naked
{
__asm
    call 0x015D
    ret
__endasm;
}

/* =========================================================
   TEXTO
   ========================================================= */

void printString(uint8_t line, char *txt)
__naked __sdcccall(1)
{
    line;
    txt;

__asm

    ; A = line
    ; HL = txt

    call 0x0160
    ret

__endasm;
}

void printChars(
    uint8_t x,
    uint8_t y,
    char *txt
) __naked __sdcccall(1)
{
    x;
    y;
    txt;

__asm

    ld b, a
    ld c, l

    ex de, hl

    call 0x0163
    ret

__endasm;
}

/* =========================================================
   BUFFER
   ========================================================= */

void setBufClear(void) __naked
{
__asm
    call 0x016C
    ret
__endasm;
}

void setBufNoClear(void) __naked
{
__asm
    call 0x016F
    ret
__endasm;
}

/* =========================================================
   GRAFICOS
   ========================================================= */

void drawGraphic(
    uint8_t chr,
    void *data,
    uint8_t w,
    uint8_t h
) __naked __sdcccall(1)
{
    chr;
    data;
    w;
    h;

__asm

    ; A = chr
    ; HL = data
    ; DE = w/h

    call 0x0178
    ret

__endasm;
}

void invGraphic(void) __naked
{
__asm
    call 0x017B
    ret
__endasm;
}

/* =========================================================
   TERMINAL GLCD
   ========================================================= */

void initTerminal(void) __naked
{
__asm
    call 0x017E
    ret
__endasm;
}

void sendCharToLCD(uint8_t c)
__naked __sdcccall(1)
{
    c;

__asm
    call 0x0181
    ret
__endasm;
}

void sendStringToLCD(
    char *txt
) __naked __sdcccall(1)
{
    txt;

__asm
    ex de, hl
    ld a, #0

    call 0x0184
    ret

__endasm;
}

void sendRegToLCD(uint8_t v)
__naked __sdcccall(1)
{
    v;

__asm
    call 0x0187
    ret
__endasm;
}

void sendHLToLCD(uint16_t v)
__naked __sdcccall(1)
{
    v;

__asm
    call 0x018A
    ret
__endasm;
}

void setCursor(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1)
{
    x;
    y;

__asm
    ld b, a
    ld c, l

    call 0x018D
    ret

__endasm;
}

uint16_t getCursor(void) __naked
{
__asm

    call 0x0190

    ld d, b
    ld e, c

    ret

__endasm;
}

void displayCursor(uint8_t v)
__naked __sdcccall(1)
{
    v;

__asm
    call 0x0193
    ret
__endasm;
}

void autoLF(uint8_t v)
__naked __sdcccall(1)
{
    v;

__asm
    call 0x0196
    ret
__endasm;
}

void underline(void) __naked
{
__asm
    call 0x0199
    ret
__endasm;
}

void plotAlways(uint8_t v)
__naked __sdcccall(1)
{
    v;

__asm
    call 0x019C
    ret
__endasm;
}

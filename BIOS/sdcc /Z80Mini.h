/* =========================================================
   Z80Mini.h
   API COMPLETA Z80Mini para SDCC (__sdcccall(1))
   ========================================================= */

#ifndef Z80MINI_H
#define Z80MINI_H

#include <stdint.h>

/* =========================================================
 * Constantes úteis
 * ========================================================= */

#define I2C_WRITE_FLAG  0x00
#define I2C_READ_FLAG   0x01

#define LCD_LINE0   0
#define LCD_LINE1   1
#define LCD_LINE2   2
#define LCD_LINE3   3

#define CURSOR_ON   0
#define CURSOR_OFF  1

#define AUTOLF_ON   0
#define AUTOLF_OFF  1

#define PLOT_ALWAYS 0
#define PLOT_MANUAL 1

#define byte        uint8_t
#define sbyte       int8_t
#define word        uint16_t
#define TRUE 		0x01
#define FALSE 		0x00
#define HIGH        0x01
#define LOW         0x00

/* =========================================================
   DELAY
   ========================================================= */

void delay500ms(void) __naked;
void delay(uint16_t ms) __naked __sdcccall(1);

/* =========================================================
   I2C
   ========================================================= */

void I2C_Open(uint8_t addr) __naked __sdcccall(1);
void I2C_Close(void) __naked;
uint8_t I2C_Read(void) __naked;
void I2C_Write(uint8_t data) __naked __sdcccall(1);

/* =========================================================
   KEYBOARD
   ========================================================= */

uint8_t keyboardIsEsc(void) __naked;
uint8_t keyboardWaitA(void) __naked;
uint8_t keyboardA(void) __naked;

/* =========================================================
   SERIAL
   ========================================================= */

void setDefaultSerialA(void) __naked;
void setDefaultSerialB(void) __naked;

void serialPrintA(uint8_t c) __naked __sdcccall(1);
uint8_t serialInputA(void) __naked;

void serialPrintStr(char *s) __naked __sdcccall(1);

void serialCRLF(void) __naked;

void serialHexA(uint8_t v) __naked __sdcccall(1);
void serialHexHL(uint16_t v) __naked __sdcccall(1);

uint8_t serialInHexA(void) __naked;
uint16_t serialInHexHL(void) __naked;

/* =========================================================
   LCD
   ========================================================= */

void initLCD(void) __naked;

void clearGBUF(void) __naked;
void clearGrLCD(void) __naked;
void clearTxtLCD(void) __naked;

void setGrMode(void) __naked;
void setTxtMode(void) __naked;

/* =========================================================
   DESENHO
   ========================================================= */

void drawBox(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1);

void drawLine(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1);

void fillBox(
    uint8_t x0,
    uint8_t y0,
    uint8_t x1,
    uint8_t y1
) __naked __sdcccall(1);

void drawCircle(
    uint8_t x,
    uint8_t y,
    uint8_t radius
) __naked __sdcccall(1);

void fillCircle(
    uint8_t x,
    uint8_t y,
    uint8_t radius
) __naked __sdcccall(1);

void drawPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1);

void clearPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1);

void flipPixel(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1);

void plotToLCD(void) __naked;

/* =========================================================
   TEXTO
   ========================================================= */

void printString(uint8_t line, char *txt)
    __naked __sdcccall(1);

void printChars(
    uint8_t x,
    uint8_t y,
    char *txt
) __naked __sdcccall(1);

/* =========================================================
   BUFFER
   ========================================================= */

void setBufClear(void) __naked;
void setBufNoClear(void) __naked;

/* =========================================================
   GRAFICOS
   ========================================================= */

void drawGraphic(
    uint8_t chr,
    void *data,
    uint8_t w,
    uint8_t h
) __naked __sdcccall(1);

void invGraphic(void) __naked;

/* =========================================================
   TERMINAL GLCD
   ========================================================= */

void initTerminal(void) __naked;

void sendCharToLCD(uint8_t c)
    __naked __sdcccall(1);

void sendStringToLCD(
    char *txt
) __naked __sdcccall(1);

void sendRegToLCD(uint8_t v)
    __naked __sdcccall(1);

void sendHLToLCD(uint16_t v)
    __naked __sdcccall(1);

void setCursor(
    uint8_t x,
    uint8_t y
) __naked __sdcccall(1);

uint16_t getCursor(void) __naked;

void displayCursor(uint8_t v)
    __naked __sdcccall(1);

void autoLF(uint8_t v)
    __naked __sdcccall(1);

void underline(void) __naked;

void plotAlways(uint8_t v)
    __naked __sdcccall(1);

#endif

#include <stdio.h>
#include <string.h>
#include "../Z80Mini.h"

byte new_ball();
void incPontos(void);
void showPontos(byte p);
void showVidas(byte v);
void fireInvSound();
void gameoverSound();
void hitSound();

byte pontos;
byte input;
byte px;
byte py;
byte count;
byte erros;
byte bx;
byte by;

int main(void) {

    pontos=0;
 	px=60;
 	py=60;
 	count=0;
 	erros=3;
 	bx=60;
 	by=3;
    
    displayCursor(1);

    clearGBUF();

    // Liga display i2c
    I2C_Open(0x0E);
    I2C_Write(0x00);
    I2C_Write(0x01); // Liga somente o display LOW (3 e 4)
    I2C_Close();

    showPontos(pontos);
    showVidas(erros);

    while(TRUE) {

		input = keyboardA();
		
        if (count >= 10) {
  
            // Left
            if (input == 'a') {
                if (px > 2) {
                    px = px - 3;
                }
            }
            // Right
            if (input == 'd') {
                if (px < 116) {
                    px = px + 3;
                }
            }
            

            clearGBUF();
            
            drawLine(px, py, px+10, py);

            drawCircle(bx, by, 1);
            
            plotToLCD();
            
            if (py == by) {
                if (bx+1 >= px && bx <= px+10) {
                    incPontos();
                    showPontos(pontos);
                    bx = new_ball();
                    by = 1;
                    hitSound();
                }
            }

            if (by > 65) {
                bx = new_ball();
                by = 1;
                erros = erros - 1;
                showVidas(erros);
                fireInvSound();
            }

            if (erros == 0) {
                erros = 3;
                pontos = 0;

                showPontos(pontos);
                showVidas(erros);
                gameoverSound();
            }
            by=by+1;
            count=0;
        }
        count = count + 1;
        delay(1);
    }
}

byte new_ball() {
    while(1) {
        byte x = rand();
        if (x > 3 && x < 124) {
            return x;
        }
    }
}

void incPontos(void) __naked {
    __asm
        ld a, (_pontos)   ; carrega o valor atual em A
        add a, #1          ; incrementa 1
        daa               ; ajusta para BCD
        ld (_pontos), a   ; salva de volta
        ret
    __endasm;
}

void showPontos(byte p) {
    I2C_Open(0x0E);
    I2C_Write(0x01);
    I2C_Write(p);
    I2C_Close();
}

void showVidas(byte v) {
    I2C_Open(0x0E);
    I2C_Write(0x03);
    I2C_Write(v);
    I2C_Close();
}

void hitSound() {
    I2C_Open(0x0E);
    I2C_Write(0x05);
    I2C_Write(0x12);
    I2C_Close();
}

void gameoverSound() {
    I2C_Open(0x0E);
    I2C_Write(0x05);
    I2C_Write(0x10);
    I2C_Close();
}

void fireInvSound() {
    I2C_Open(0x0E);
    I2C_Write(0x05);
    I2C_Write(0x01);
    I2C_Close();
}

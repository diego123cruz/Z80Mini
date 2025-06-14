#include <stdio.h>
#include <string.h>
#include "../Z80Mini.h"

byte new_ball();
void incPontos(void);
void showPontos(byte p);
void showVidas(byte v);

byte pontos=0;

int main(void) {
    byte px=60;
    byte py=60;
    byte count=0;
    pontos=0;
    byte erros=3;

    byte bx=60;
    byte by=3;

    lcd_cursor_off();

    lcd_clear_buffer();

    // Liga display i2c
    i2c_open(0x0E);
    i2c_write(0x00);
    i2c_write(0x01); // Liga somente o display LOW (3 e 4)
    i2c_close();

    showPontos(pontos);
    showVidas(erros);

    while(TRUE) {

        byte read = pinIn(#0x40);

        byte input = 0;
        if (read != 0) {
            input = read;
        }
        

        if (count >= 10) {
            // A
            if (input == 0x01) {
      
            }
            // Left
            if (input == 0x40) {
                if (px > 2) {
                    px = px - 3;
                }
            }
            // Right
            if (input == 0x10) {
                if (px < 116) {
                    px = px + 3;
                }
            }
            input = 0;

            lcd_clear_buffer();
            lcd_draw_line(px, py, px+10, py);
            lcd_draw_circle(bx, by, 1);
            lcd_show_buffer();
            
            

            if (py == by) {
                if (bx+1 >= px && bx <= px+10) {
                    incPontos();
                    showPontos(pontos);
                    bx = new_ball();
                    by = 1;

                    i2c_open(0x0E);
                    i2c_write(0x05);
                    i2c_write(0x12);
                    i2c_close();
                }
            }

            if (by > 65) {
                bx = new_ball();
                by = 1;
                erros = erros - 1;
                showVidas(erros);
                delay_ms(200);

                i2c_open(0x0E);
                i2c_write(0x05);
                i2c_write(0x01);
                i2c_close();
            }

            if (erros == 0) {
                erros = 3;
                pontos = 0;
                delay_ms(1000);

                showPontos(pontos);
                delay_ms(100);
                showVidas(erros);
                delay_ms(100);
                
                i2c_open(0x0E);
                i2c_write(0x05);
                i2c_write(0x10);
                i2c_close();
            }
            by=by+1;
            count=0;
        }
        count = count + 1;
        delay_ms(1);
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
    i2c_open(0x0E);
    i2c_write(0x01);
    i2c_write(p);
    i2c_close();
}

void showVidas(byte v) {
    i2c_open(0x0E);
    i2c_write(0x03);
    i2c_write(v);
    i2c_close();
}
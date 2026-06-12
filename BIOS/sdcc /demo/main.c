#include "../Z80Mini.h"

    byte x = 1;
    byte y = 1;
    sbyte vx=1;
    sbyte vy=1;

void main(void) {

    x = 3;
    y = 3;
    vx=2;
    vy=2;
    

    while(TRUE) {
        clearGBUF();
        drawBox(0,0,127,63);
        setCursor(x, y);
        sendStringToLCD("Z80Mini");


        if(x > 84) {
            vx=-2;
        }
        if (y > 55) {
            vy=-2;
        }
        if(x < 2) {
            vx=2;
        }
        if(y < 2) {
            vy=2;
        }

        plotToLCD();
        
        delay(10);

        x = x+vx;
        y = y+vy;
    }

}

#include "../Z80Mini.c"

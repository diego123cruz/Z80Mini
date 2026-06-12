#include "../Z80Mini.h"

    

void main(void) {

    byte x = 3;
    byte y = 3;
    sbyte vx=2;
    sbyte vy=2;
    

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


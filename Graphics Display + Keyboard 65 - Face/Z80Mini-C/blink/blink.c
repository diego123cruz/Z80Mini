#include <stdio.h>
#include <string.h>
#include "../Z80Mini.h"


int main(void) {
    byte count = 10;
    byte out = 0;
    while(TRUE) {
        byte input = pinIn(#0xC0);
        portOut(#0xC0, ~input);
        
        if(count < 1) {
            out ^= 1;
            pinOut(0x10, out);
            count = 10;
        }

        count--;  
        delay_ms(50);      
    }
}

#include "../Z80Mini.c"
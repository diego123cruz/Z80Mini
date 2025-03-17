#include <stdio.h>
#include <string.h>
#include "../Z80Mini.h"


int main(void) {

    lcd_cursor_off();

    lcd_clear_buffer();

    lcd_set_xy(32,16);

    lcd_print_string("Diego\0");

    lcd_show_buffer();

    byte x, y = 0;

    byte count = 10;
    byte out = 0;
    while(TRUE) {
        byte input = pinIn(#0xC0);
        portOut(#0xC0, ~input);
        
        if(count < 1) {
            out ^= 1;
            pinOut(0x10, out);
            count = 10;

            
            lcd_clear_buffer();
            lcd_set_xy(0,0);
            lcd_print_byte_to_ascii(~input);
            lcd_show_buffer();
        }

        count--;  
        delay_ms(50);      
    }
}

#include "../Z80Mini.c"
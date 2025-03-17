#define byte        unsigned char
#define TRUE 		0x01
#define FALSE 		0x00
#define HIGH        0x01
#define LOW         0x00


// Z80 Mini API
#define _DELAY_MS               0x0187      // var input in DE 
#define _CLEAR_GBUF             0x0103
#define _PLOT_TO_LCD            0x0124  
#define _SET_CURSOR             0x015D
#define _SEND_CHAR_TO_GLCD      0x0151
#define _SEND_STRING_TO_GLCD    0x0154
#define _DISPLAY_CURSOR         0x0163
#define _SEND_A_TO_GLCD         0x0157
#define _SEND_HL_TO_GLCD        0x015A
#define _I2C_Open               0x0166
#define _I2C_Close              0x0169
#define _I2C_Read               0x016C
#define _I2C_Write              0x016F
#define _KEYREADINIT            0x017E
#define _KEYREAD                0x0181


void lcd_clear_buffer(void);
void lcd_show_buffer(void);
void lcd_set_xy(byte x, byte y);
void lcd_print_char(byte a);
void lcd_print_string(const char* s);
void lcd_cursor_on(void);
void lcd_cursor_off(void);
void lcd_print_byte_to_ascii(byte a);
void lcd_print_int_to_ascii(int hl);

void i2c_open(byte device);
void i2c_close(void);
byte i2c_read(void);
void i2c_write(byte b);

byte key_read_wait_press(void);
byte key_read(void);

void delay_ms(int time);
void pinOut(byte pin, byte state);
void portOut(byte port, byte outByte);
byte pinIn(byte pin);
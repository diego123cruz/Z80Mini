#include "../Z80MiniAPI.asm"

ArduBox		.equ	$08

    ORG $8000

loop:
    LD A, ArduBox
    CALL I2C_OpenWrite
    
    LD A, $01
    CALL I2C_Write
    
    LD A, ArduBox
    CALL I2C_OpenRead
    
    CALL I2C_Read
    
    PUSH AF
    
    CALL I2C_Close
    
    CALL clearGBUF
    LD BC, $0000
    CALL setCursor
    
    POP AF
    
    CALL sendRegToLCD
    CALL plotToLCD
    
    JP loop

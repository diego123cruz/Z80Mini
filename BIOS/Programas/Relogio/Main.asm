#include "../Z80MiniAPI.asm"
    ORG 8000H

inicio:
    ; liga display
    LD A, 0EH
    CALL I2C_Open
    LD A, 00H
    CALL I2C_Write
    LD A, 03H
    CALL I2C_Write
    CALL I2C_Close

loop:
    ; le ricoh223 - segundos
    LD A, 64H
    CALL I2C_Open
    LD A, 00H           ; segundos
    CALL I2C_Write
    LD A, 65H           ; read = addr + 1
    CALL I2C_Open
    CALL I2C_Read
    LD (segundos), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; le ricoh223 - minutos
    LD A, 64H
    CALL I2C_Open
    LD A, 10H           ; minutos 
    CALL I2C_Write
    LD A, 65H
    CALL I2C_Open
    CALL I2C_Read
    AND 01111111B
    LD (minutos), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; le ricoh223 - hora
    LD A, 64H
    CALL I2C_Open
    LD A, 20H           ; hora
    CALL I2C_Write
    LD A, 65H
    CALL I2C_Open
    CALL I2C_Read
    AND 00111111B
    LD (horas), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; display escreve low (minutos)
    LD A, 0EH
    CALL I2C_Open
    LD A, 01H
    CALL I2C_Write
    LD A, (minutos)
    CALL I2C_Write
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; display escreve high (horas)
    LD A, 0EH
    CALL I2C_Open
    LD A, 02H
    CALL I2C_Write
    LD A, (horas)
    CALL I2C_Write
    CALL I2C_Close

    LD DE, 0396H
    CALL delay

    ; pisca ponto ':'
    LD A, 0EH
    CALL I2C_Open
    LD A, 00H
    CALL I2C_Write
    LD A, (status)
    XOR 04H
    LD (status), A
    CALL I2C_Write
    CALL I2C_Close

    JP loop

status   DB 03H
horas    DB 00H
minutos  DB 00H
segundos DB 00H

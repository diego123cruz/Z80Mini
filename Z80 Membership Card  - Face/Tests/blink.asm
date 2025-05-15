INT_VEC     .equ    $FF2D   ;(2) vector int38


.org $8000
    LD HL, start
    LD (INT_VEC), HL

    LD A, $1  ;(3.25)

inicio:
    OUT ($C0), A ;(2.75)
    XOR $1    ;(1.75)
    JP inicio ;(2.50)

start:
    DI  ;(1) 
    LD B, $BE ;(1.75)  192(DEC)
    OUT ($40), A ;(2.75)
loop:
    NOP     ;(1)
    NOP     ;(1)
    DJNZ loop ;if B!=0 (3.25), if B=0 (2)
    EI  ;(1)
    RETI ;(3.50)


.end

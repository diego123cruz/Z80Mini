.org $8000


    ;LD A, $10
    ;CALL $0DFA ; I2C open, device id in A
    
    ;LD A, $07  ; register
    ;CALL $0E04 ;I2C Write, value in A
    
    ;LD A, $FF  ; comand
    ;CALL $0E04 ;I2C Write, value in A
    
    ;CALL $0E41 ; I2C Read, return in A
    
    ;CALL $0E01 ; I2C Close
    
    
    
    ;LD A, '-'
    ;CALL $0804 ; send A to display
    
loop:
    LD A, $10 ; To read is equal address +1
    CALL $0DFA ; I2C open, device id in A
    
    LD A, $04  ; register
    CALL $0E04 ;I2C Write, value in A
    
    LD A, $10+1 ; To read is equal address +1
    CALL $0DFA ; I2C open, device id in A
    
    CALL $0E41 ; I2C Read, return in A
    
    PUSH AF
    
    CALL $0E01 ; I2C Close
    
    POP AF
    
    CALL lcd_print_data ; send A to display
    LD A, $0d
    CALL $0804 ; send ENTER 
    
    JP loop
    
    
lcd_print_data:
	push bc
    push af
    ld b, a
    and 11110000b
    rlca
    rlca
    rlca
    rlca
    add a, '0'
    cp '9' + 1
    jr c, print_12
    add a, 'A' - '0' - 10
print_12:
    CALL $0804 ; send to lcd
    ld a, b
    and 00001111b
    add a, '0'
    cp '9' + 1
    jr c, print_22
    add a, 'A' - '0' - 10
print_22:
    CALL $0804 ; send to lcd
    pop bc
    pop af
    ret





:108000003E10CDFA0D3E04CD040E3E11CDFA0DCD3D
:10801000410EF5CD010EF1CD22803E0DCD0408C3F9
:108020000080C5F547E6F007070707C630FE3A3877
:1080300002C607CD040878E60FC630FE3A3802C6FD
:0780400007CD0408C1F1C9DE
:00000001FF
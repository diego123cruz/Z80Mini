#include "../../Z80MiniAPI.asm"

.org $8000

init:
    LD A, 1
    LD (gameover), A ; Gameover

    XOR A
    LD (cursor_x), A
    LD (cursor_y), A
    ld (bomb_alive), A
    LD IX, predios
    LD BC, 0x132E
    LD (IX), BC
    LD BC, 0x193F
    LD (IX+2), BC
    LD BC, 0x2e33
    LD (IX+4), BC
    LD BC, 0x343F
    LD (IX+6), BC
    LD BC, 0x4630
    LD (IX+8), BC
    LD BC, 0x4c3F
    LD (IX+10), BC
    LD BC, 0x582E
    LD (IX+12), BC
    LD BC, 0x5e3F
    LD (IX+14), BC
    LD BC, 0x6a33
    LD (IX+16), BC
    LD BC, 0x703F
    LD (IX+18), BC

loop:
    CALL ler_gamepad
    call update_bomb
    call update_airplane
    call update_predios
    call update_screen

    ; Check GameOver
    LD A, (gameover)
    CP 0
    JP Z, loop

    LD BC, $1E2B
    CALL setCursor
    LD A, 0
    LD DE, msg_start
    CALL sendStringToLCD
loop_enter:
    call keyboardA
    cp CR
    Jr NZ, loop_enter
    LD A, 0
    LD (gameover), A
    jp loop


inc_bc:
    INC BC
    INC BC
    INC BC
    INC BC
    ret

inc_b:
    inc B
    inc B
    inc B
    inc B
    inc B
    inc B
    inc B
    ret

update_predios:
    LD A, (bomb_alive)
    cp 0
    RET Z
    LD IX, predios
p1:
    ld bc, (IX)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p2
    ld a, (bomb_y)
    cp c
    jp NC, p2
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p2
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p2
    CALL inc_bc
    LD (IX), bc
    xor a
    ld (bomb_alive), a

p2:
    ld bc, (IX+4)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p3
    ld a, (bomb_y)
    cp c
    jp NC, p3
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p3
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p3
    CALL inc_bc
    LD (IX+4), bc
    xor a
    ld (bomb_alive), a

p3:
    ld bc, (IX+8)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p4
    ld a, (bomb_y)
    cp c
    jp NC, p4
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p4
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p4
    CALL inc_bc
    LD (IX+8), bc
    xor a
    ld (bomb_alive), a

p4
    ld bc, (IX+12)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p5
    ld a, (bomb_y)
    cp c
    jp NC, p5
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p5
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p5
    CALL inc_bc
    LD (IX+12), bc
    xor a
    ld (bomb_alive), a

p5
    ld bc, (IX+16)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p6
    ld a, (bomb_y)
    cp c
    jp NC, p6
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p6
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p6
    CALL inc_bc
    LD (IX+16), bc
    xor a
    ld (bomb_alive), a
p6:
    RET


ler_gamepad:
    call keyboardA
    
    cp SPACE
    jp z, bomb_fire

    CP ESC
    JP Z, quit

    RET

quit:
    jp 0

update_screen:
    CALL clearGBUF

; Draw predios
    LD IX, predios
    ld bc, (IX)
    ld de, (IX+2)
    call fillBox

    ld bc, (IX+4)
    ld de, (IX+6)
    call fillBox

    ld bc, (IX+8)
    ld de, (IX+10)
    call fillBox

    ld bc, (IX+12)
    ld de, (IX+14)
    call fillBox

    ld bc, (IX+16)
    ld de, (IX+18)
    call fillBox


; Draw airplane
    LD A, (cursor_x)
    LD B, A
    LD A, (cursor_y)
    LD C, A
    CALL setCursor
    LD A, 0
    LD BC, $0F08
    LD HL, airplane
    CALL drawGraphic


    ; Draw bomb
    ld A, (bomb_alive)
    cp 0
    JP Z, fim_bomb
    LD A, (bomb_x)
    LD B, A
    LD A, (bomb_y)
    LD C, A
    CALL setCursor
    LD A, 14 ; bomb
    CALL drawGraphic
fim_bomb:

    CALL plotToLCD
    ret


btnUp:
    ld a, (cursor_y)
    dec A
    ld (cursor_y), a
    RET

btnDown:
    ld a, (cursor_y)
    inc A
    ld (cursor_y), a
    RET

btnLeft:
    ld a, (cursor_x)
    dec A
    ld (cursor_x), a
    RET

btnRight:
    ld a, (cursor_x)
    inc A
    ld (cursor_x), a
    RET




update_bomb:
    ld a, (bomb_alive)
    cp 0
    RET Z
    ; x
    ld a, (bomb_x)
    add a, 2
    ld (bomb_x), A
    ; y
    ld a, (bomb_y)
    add a, 3
    ld (bomb_y), A
    cp 64
    JP NC, bomb_alive_zera

    ld a, (bomb_x)
    cp 124
    JP NC, bomb_alive_zera
    ret

bomb_alive_zera:
    xor A
    ld (bomb_alive), A
    ret




update_airplane:
    ld a, (cursor_x)
    add a, 2
    cp 126
    JP NC, update_airplane_zero
    ld (cursor_x), A
    ld a, (cursor_y)
    cp 50
    JP NC, fim_de_jogo

    RET
update_airplane_zero:
    xor a
    ld (cursor_x), A
    LD A, (cursor_y)
    ADD A, 8
    LD (cursor_y), A
    RET

fim_de_jogo:
    LD BC, $1E2B
    CALL setCursor

    LD A, 0
    LD DE, msg_gameover
    CALL sendStringToLCD
fim_de_jogo_loop:
    call keyboardA
    cp CR
    jr nz, fim_de_jogo_loop
    bit 2, A
    JP Z, fim_de_jogo_loop
    JP init


bomb_fire:
    ld a, (bomb_alive)
    cp 0
    RET NZ
    ld a, (cursor_x)
    cp 120
    ret NC
    ld a, 1
    ld (bomb_alive), A
    ld a, (cursor_x)
    add a, 4
    ld (bomb_x), A
    ld a, (cursor_y)
    add a, 2
    ld (bomb_y), A
    RET

msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER",0

gameover:   .db 0x00
cursor_x:   .db 0x00
cursor_y:   .db 0x00
bomb_x:     .db 0x00
bomb_y:     .db 0x00
bomb_alive  .db 0x00
;predios XY
predios     .dw 0x132E, 0x193F, 0x2e33, 0x343F, 0x4630, 0x4c3F, 0x582E, 0x5e3F, 0x6a33, 0x703F

airplane: .db 0x01, 0x00, 0x00, 0xC0, 0xC0, 0xC0, 0x7F, 0xFE, 0x1F, 0xFF, 0x01, 0x80, 0x01, 0x80, 0x03, 0x00

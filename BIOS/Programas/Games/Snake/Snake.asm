#include "../../Z80MiniAPI.asm"

; direções
DIR_UP      .EQU    1
DIR_DOWN    .EQU    2
DIR_LEFT    .EQU    3
DIR_RIGHT   .EQU    4

TELA_X      .EQU    $7F ; 0-127 = 128
TELA_Y      .EQU    $3F ; 0-63 = 64

VTELA_X     .EQU    $3F ; Tela virtal 
VTELA_Y     .EQU    $1F ; Tela virtal 

.org $8000
    ; Setup ram
    LD A, 1
    LD (gameover), A ; Gameover

start_game:
    ; Direção inicial
    LD A, 4
    LD (direction), A

    LD A, 15
    LD (food_x), A
    LD (food_y), A

    ; seed to random
    LD A, $82
    LD HL, seed1
    LD (HL), A
    INC HL
    LD (HL), A
    LD A, $76
    LD HL, seed2
    LD (HL), A
    INC HL
    LD (HL), A

    ; Tamanho inicial
    LD A, 4
    LD (size), A

    ; Posição inicial
    LD A, 10
    
    LD (head_y+3), A    ;X
    LD (head_y+1), A    ;X
    LD (head_y+5), A    ;X
    LD (head_y+7), A    ;X
    INC A
    LD (head_y), A      ;Y
    INC A
    LD (head_y+2), A    ;Y
    INC A
    LD (head_y+4), A    ;Y
    INC A
    LD (head_y+6), A    ;Y
    

loop:
    CALL atualiza_jogo
    CALL atualiza_display

    LD B, $62
delay_loop:
    call keyboardA
    JP NC, delay_loop_skip
    LD (read_keys), A
delay_loop_skip:
    LD DE, $0001
    CALL delay
    DJNZ delay_loop
    
    ; Check GameOver
    LD A, (gameover)
    CP 0
    JP Z, loop

    ; Cursor OFF
    LD A, 1
    CALL displayCursor

    ; Set cursor XY
    ;Inputs: BC = X,Y where X = 0..127, Y = 0..63
    LD BC, $1E2B
    CALL setCursor

    LD A, 0
    LD DE, msg_start
    CALL sendStringToLCD
loop_enter:
    call keyboardA
    cp CR
    JP NZ, loop_enter
    LD A, 0
    LD (gameover), A
    jp loop


atualiza_jogo:
    CALL ler_teclado
    CALL atualiza_corpo
    CALL atualiza_head
    CALL check_colisao
    CALL check_food
    RET


check_food:
    ; if head_x == food_x E head_y == food_y = comer
    LD HL, (head_y)
    LD A, (food_x)
    CP H
    RET NZ
    LD A, (food_y)
    CP L 
    RET NZ
    CALL comer
    RET

comer:
    LD A, (size)
    INC A
    LD (size), A
    CALL new_food
    RET

new_food:
    ld a, (count)
    adc a, 1
    daa
    ld (count), a
    CALL randomHL
    LD A, H
    LD (food_x), A
    LD A, L
    LD (food_y), A
    RET

fim_de_jogo:
    LD BC, $1E2B
    CALL setCursor

    LD A, 0
    LD DE, msg_gameover
    CALL sendStringToLCD
    LD A, (count)
    CALL sendCharToLCD
fim_de_jogo_loop:
    call keyboardA
    CP CR
    JP NZ, fim_de_jogo_loop
    JP start_game
    

check_colisao:
    ; colisão com Paredes
    ; if head_x < 1 ou head_x > 63 = fim de jogo
    ; if head_y < 1 ou head_y > 31 = fim de jogo
    LD HL, (head_y) ; H=X, L=Y
    LD A, H
    CP 1
    JP C, fim_de_jogo ; if x < 1
    CP VTELA_X
    JP NC, fim_de_jogo ; fi x >= 63

    LD A, L
    CP 1
    JP C, fim_de_jogo ; if y < 1
    CP VTELA_Y
    JP NC, fim_de_jogo ; if y >= 31
    RET



atualiza_corpo:
    LD A, (size)

    LD      C, A 
    LD      B, 0 
    SLA     C ; Multiplicar por 2

    LD A, C
    PUSH AF

    LD HL, head_y
    ADD HL, BC ; HL ultimo segmento HL
    PUSH HL

    LD HL, head_y+2 ; depois do ultimo DE
    ADD HL, BC
    LD D, H
    LD E, L

    POP HL

    POP AF
    LD B, A
atualiza_corpo_loop:
    LD A, (HL)
    LD (DE), A
    DEC HL
    DEC DE
    DJNZ atualiza_corpo_loop
    LD A, (HL)
    LD (DE), A
    RET


atualiza_head:
    LD A, (direction)
    CP DIR_UP
    JP Z, HEAD_UP
    CP DIR_DOWN
    JP Z, HEAD_DOWN
    CP DIR_LEFT
    JP Z, HEAD_LEFT
    CP DIR_RIGHT
    JP Z, HEAD_RIGHT
    RET


HEAD_UP:
    LD A, (head_y)
    DEC A
    LD (head_y), A
    RET

HEAD_DOWN:
    LD A, (head_y)
    INC A
    LD (head_y), A
    RET

HEAD_LEFT:
    LD A, (head_x)
    DEC A
    LD (head_x), A
    RET

HEAD_RIGHT:
    LD A, (head_x)
    INC A
    LD (head_x), A
    RET





ler_teclado:
    LD A, (read_keys)
    LD B, A

    LD A, 0
    LD (read_keys), A

    LD A, B

    cp 'w'
    JP Z, TRY_UP

    cp 's'
    JP Z, TRY_DOWN

    cp 'a'
    JP Z, TRY_LEFT

    cp 'd'
    JP Z, TRY_RIGHT

    cp ESC
    JP Z, 0 ; Back to Monitor
    RET

TRY_UP:
    LD A, (direction)
    CP DIR_DOWN
    RET Z
    LD A, DIR_UP
    LD (direction), A
    RET

TRY_DOWN:
    LD A, (direction)
    CP DIR_UP
    RET Z
    LD A, DIR_DOWN
    LD (direction), A
    RET

TRY_LEFT:
    LD A, (direction)
    CP DIR_RIGHT
    RET Z
    LD A, DIR_LEFT
    LD (direction), A
    RET

TRY_RIGHT:
    LD A, (direction)
    CP DIR_LEFT
    RET Z
    LD A, DIR_RIGHT
    LD (direction), A
    RET


desenha_food;
    LD A, (food_x)
    LD B, A
    LD A, (food_y)
    LD C, A
    CALL set_pixel_bc
    RET


desenha_snake:
    LD A, (size)
    LD B, A
    LD HL, head_y
desenha_snake_loop:
    PUSH BC

    LD C, (HL)
    INC HL
    LD B, (HL)
    
    PUSH HL
    CALL set_pixel_bc
    POP HL
    POP BC

    INC HL

    DJNZ desenha_snake_loop
    RET

set_pixel_bc:
    ; Desenha pixel
    ; Input B = column/X (0-127), C = row/Y (0-63)

    SLA B
    SLA C
    PUSH BC 
    ; *-
    ; --
    CALL PIXEL_BC_DRAW ; Main pixel

    ; **
    ; --
    INC B
    CALL PIXEL_BC_DRAW

    ; **
    ; *-
    POP BC
    INC C
    CALL PIXEL_BC_DRAW

    ; **
    ; **
    INC B
    CALL PIXEL_BC_DRAW
    RET

PIXEL_BC_DRAW:
    PUSH BC
    CALL drawPixel
    POP BC
    RET

atualiza_display:
    ; Limpa buffer display
    CALL clearGBUF

    CALL desenha_food

    CALL desenha_snake

    ; Desenha limites
    LD BC, $0000
    LD D, TELA_X
    LD E, TELA_Y
    CALL drawBox

    ; Atualiza display
    CALL plotToLCD
    RET

randomHL:
    ; 3F = 126/2
    ; 1F = 62/2
    CALL prng16
    LD A, H
    AND VTELA_X-1
    CP 0
    JP Z, randomHL
    LD H, A

    LD A, L
    AND VTELA_Y-1
    CP 0
    JP Z, randomHL
    LD L, A
    RET


prng16:
; Site: https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random
;Inputs:
;   (seed1) contains a 16-bit seed value
;   (seed2) contains a NON-ZERO 16-bit seed value
;Outputs:
;   HL is the result
;   BC is the result of the LCG, so not that great of quality
;   DE is preserved
;Destroys:
;   AF
;cycle: 4,294,901,760 (almost 4.3 billion)
;160cc
;26 bytes
    ld hl,(seed1)
    ld b,h
    ld c,l
    add hl,hl
    add hl,hl
    inc l
    add hl,bc
    ld (seed1),hl
    ld hl,(seed2)
    add hl,hl
    sbc a,a
    and %00101101
    xor l
    ld l,a
    ld (seed2),hl
    add hl,bc
    ret

msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER ",0
count       .db $00
read_keys   .db $00
gameover    .db $00
seed1       .dw 1234
seed2       .dw 8765
direction   .db $01
size        .db $01
food_y      .db $01
food_x      .db $01
head_y      .db $01
head_x      .db $01

#include "../../Z80MiniAPI.asm"


    .org $8000
    
    ; Setup ram
    LD A, 1
    LD (gameover), A ; Gameover

inicio:
    LD HL, inicio
    PUSH HL
    
    xor a
    ld (box_x), a
    ld (box_y), a
    ld (box2_x), a
    ld (box2_y), a
    ld a, $30
    ld (player_x),a
    ld (player_y),a
    call clearGBUF
    
    call new_fruit
    XOR A
    LD (count), A
loop:
    
    call ler_teclado
    call clearGBUF
    
    
    ; print fruit
    LD A, (fruit_x)
    ld b, a
    ld a, (fruit_y)
    ld c, a
    LD E, 1
    call fillCircle
    
    
    ; DRAW BOX to RIGHT
    ; set cursor 
    LD A, (box_x)
    ld b, a
    ld a, (box_y)
    ld c, a
    call setCursor
    
    ; print imageR
    LD A, 0
    LD BC, $0808
    LD HL, imageR
    call drawGraphic
    
    
    ; DRAW BOX to DOWN
    ; set cursor 
    LD A, (box2_x)
    ld b, a
    ld a, (box2_y)
    ld c, a
    call setCursor
    
    ; print imageD
    LD A, 0
    LD BC, $0808
    LD HL, imageD
    call drawGraphic
    

    ; DRAW PLAYER
    call resetCollisionPixel
    ; set cursor
    LD A, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call setCursor
    
    ; print player
    LD A, 0
    LD BC, $0808
    LD HL, player
    call drawGraphic
    
    CALL checkCollisionPixel
    CALL NZ, check_collision_object


    ;DRAW pontos
    LD BC, $0000
    call setCursor
    LD A, (count)
    CALL sendRegToLCD
    

    call plotToLCD


    call update_box 
    call update_box2

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
    
   

; # Algoritmo de Colisão AABB (Axis-Aligned Bounding Box)
;*   **Retângulo A:** (Ax, Ay, Aw, Ah)
;*   **Retângulo B:** (Bx, By, Bw, Bh)

; Calculamos as coordenadas das bordas direita e inferior:
;   ARight = Ax + Aw
;   ABottom = Ay + Ah
;   BRight = Bx + Bw
;   BBottom = By + Bh

; Os retângulos **NÃO** colidem se **QUALQUER** uma das seguintes condições for verdadeira:
; 1.  A está totalmente à esquerda de B: `ARight <= Bx`
; 2.  A está totalmente à direita de B: `Ax >= BRight`
; 3.  A está totalmente acima de B: `ABottom <= By`
; 4.  A está totalmente abaixo de B: `Ay >= BBottom`
check_collision_object:
    ld a, (fruit_x)
    dec a
    ld b, a
    ld a, (player_x)
    add a, 8
    cp b
    JP C, check_collision_object_end
    
    ld a, (fruit_x)
    dec a
    add a, 3
    ld b, a
    ld a, (player_x)
    cp b
    JP NC, check_collision_object_end
    
    ld a, (fruit_y)
    dec a
    ld b, a
    ld a, (player_y)
    add a, 8
    cp b
    JP C, check_collision_object_end
    
    ld a, (fruit_y)
    dec a
    add a, 3
    ld b,a
    ld a, (player_y)
    cp b
    JP NC, check_collision_object_end
    
    call new_fruit
    ret
    
check_collision_object_end:
    LD BC, $1E2B
    CALL setCursor

    LD A, 0
    LD DE, msg_gameover
    CALL sendStringToLCD
fim_de_jogo_loop:
    call keyboardA
    CP CR
    JP NZ, fim_de_jogo_loop
    JP inicio

    
    
new_fruit:
    call randomHL
    LD A, H
    LD (fruit_x), A
    LD A, L
    LD (fruit_y), A
    
    LD A, (count)
    adc a, 1
    daa
    LD (count), A
    ret
    
    
    

update_box:
    ld a, (box_x)
    add a, 2
    cp $80
    JP NC, inc_y
    ld (box_x), a
    ret
    
inc_y:
    ld a, (box_y)
    add a, 8
    cp $40
    jp NC, res_box
    ld (box_y),a
    xor a
    ld (box_x), a
    ret
    
res_box:
    xor a
    ld (box_x),a
    ld (box_y), a
    ret
    
    
update_box2:
    ld a, (box2_y)
    add a, 2
    cp $40
    JP NC, inc_x
    ld (box2_y), a
    ret
    
inc_x:
    ld a, (box2_x)
    add a, 12
    cp $80
    jp NC, res_box2
    ld (box2_x),a
    xor a
    ld (box2_y), a
    ret
    
res_box2:
    xor a
    ld (box2_x),a
    ld (box2_y), a
    ret
    
    
    
ler_teclado:
    call keyboardA

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
    ld a, (player_y)
    dec a
    cp 1
    ret C
    ld (player_y), a
    ret
    
TRY_DOWN:
    ld a, (player_y)
    inc a
    cp 56
    ret NC
    ld (player_y), a
    ret
    
TRY_LEFT:
    ld a, (player_x)
    dec a
    cp 1
    ret C
    ld (player_x), a
    ret
    
TRY_RIGHT:
    ld a, (player_x)
    inc a
    cp 120
    ret NC
    ld (player_x), a
    ret
    
    

    

VTELA_X     .EQU    $7E ; Tela virtal 
VTELA_Y     .EQU    $3E ; Tela virtal

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


seed1       .dw 1234
seed2       .dw 8765

count       .db 0x00    

fruit_x     .db 0x00
fruit_y     .db 0x00

box_x:    .db 0x00
box_y:    .db 0x00

box2_x:    .db 0x00
box2_y:    .db 0x00
    
player_x: .db 0x0A
player_y: .db 0x0A

msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER ",0
gameover    .db $00

imageR: .db 0xFF, 0xFE, 0x7C, 0x7F, 0x7F, 0x7C, 0xFE, 0xFF
imageD: .db 0xC3, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xDB, 0x99
player: .db 0x1C, 0x1C, 0x14, 0x08, 0x3E, 0x08, 0x08, 0x36

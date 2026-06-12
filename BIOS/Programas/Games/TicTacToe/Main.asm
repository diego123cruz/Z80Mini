#include "../../Z80MiniAPI.asm"


    .org $8000
    ; Setup ram
    LD A, 1
    LD (gameover), A ; Gameover

setup:
    ld hl, setup
    push hl
    
    call clearGBUF
    
    ld a, 1
    ld (jogador), a
    
    xor a
    ld (cursor_x), a
    ld (cursor_y), a

    ; zera tabuleiro
    ld b, 9
    ld hl, tabuleiro
zera_tab:
    ld a, $0A
    ld (hl), a
    inc hl
    DJNZ zera_tab

loop:
    call clearGBUF
    
    call ler_controle
    call desenha_tabuleiro
    call desenha_cursor
    call desenha_jogadas
    call desenha_jogador_atual
    call verifica_vencedor
    
    call plotToLCD
    
    
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
    
    
fim_de_jogo:
    LD BC, $1E2B
    CALL setCursor

    LD A, 0
    LD DE, msg_gameover
    CALL sendStringToLCD
fim_de_jogo_loop:
    call keyboardA
    CP CR
    JP NZ, fim_de_jogo_loop
    JP setup
    
    
verifica_velha:
    ld b, 9
    ld hl, tabuleiro
verifica_velha_loop:
    ld a, (hl)
    cp $0A
    RET Z
    inc hl
    DJNZ verifica_velha_loop
    JP deu_velha
    ret
    
verifica_vencedor:
    ld ix, tabuleiro
    
    ; ---
    ; ...
    ; ...
    ld a, (ix)
    ld b, (ix+1)
    ld c, (ix+2)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ...
    ; ---
    ; ...
    ld a, (ix+3)
    ld b, (ix+4)
    ld c, (ix+5)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ...
    ; ...
    ; ---
    ld a, (ix+6)
    ld b, (ix+7)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; -..
    ; -..
    ; -..
    ld a, (ix)
    ld b, (ix+3)
    ld c, (ix+6)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; .-.
    ; .-.
    ; .-.
    ld a, (ix+1)
    ld b, (ix+4)
    ld c, (ix+7)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ..-
    ; ..-
    ; ..-
    ld a, (ix+2)
    ld b, (ix+5)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; -..
    ; .-.
    ; ..-
    ld a, (ix)
    ld b, (ix+4)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ..-
    ; .-.
    ; -..
    ld a, (ix+2)
    ld b, (ix+4)
    ld c, (ix+6)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    call verifica_velha
    ret

ganhouX:
    LD BC, $2800
    CALL setCursor
    
    ld de, msg_winX
    LD A, 0
    call sendStringToLCD
    call fim_de_jogo
    ret
   
ganhouO:
    LD BC, $2800
    CALL setCursor
    
    ld de, msg_winO
    LD A, 0
    call sendStringToLCD
    call fim_de_jogo
    ret 
    
deu_velha:
    LD BC, $2800
    CALL setCursor
    
    ld de, msg_velha
    LD A, 0
    call sendStringToLCD
    call fim_de_jogo
    ret 
    
    
ler_controle:
    call keyboardA
    cp 'w'
    JP Z, KUP
    
    cp 's'
    JP Z, KDOWN
    
    cp 'a'
    JP Z, KLEFT
    
    cp 'd'
    JP Z, KRIGHT
    
    cp SPACE
    JP Z, KA
    
    cp ESC
    jp Z, 0

    RET
    

KUP:
    call delay_150ms
    ld a, (cursor_y)
    cp 0
    RET Z
    dec a
    ld (cursor_y), a
    RET
    
KDOWN:
    call delay_150ms
    ld a, (cursor_y)
    cp 2
    ret z
    inc a
    ld (cursor_y), a
    RET
    
KLEFT:
    call delay_150ms
    ld a, (cursor_x)
    cp 0
    ret z
    dec a
    ld (cursor_x), a
    RET
    
KRIGHT:
    call delay_150ms
    ld a, (cursor_x)
    cp 2
    ret z
    inc a
    ld (cursor_x), a
    RET
    
    
getline0:
    ld hl, tabuleiro
    ret
    
getline1:
    ld hl, tabuleiro+3
    ret
    
getline2:
    ld hl, tabuleiro+6
    ret
    
    
KA:
    ld a, (cursor_y)
    cp 0
    call z, getline0
    cp 1
    call z, getline1
    cp 2
    call z, getline2
    ld a, (cursor_x)
    ld bc, $0000
    ld c, a
    add hl, bc
    ld a, (hl)
    cp $0A
    ret nz
    ld a, (jogador)
    ld (hl), a
    call proximo_jogador
    ret
    

proximo_jogador:
    ld a, (jogador)
    cp 1
    jp z, proximo_jogador2
    ld a, 1
    ld (jogador), a
    ret
proximo_jogador2:
    ld a,2
    ld (jogador),a
    ret
    
    
    
delay_150ms:
    LD DE, $0096
    call delay
    ret
    
ajuste_cursor:   
    cp 1
    jp z, add10
    cp 2
    jp z, add19
    ret
    
add10:
    add a, 10
    ret

add19:
    add a, 19
    ret
    
    
desenha_jogador_atual:
    ld bc, $0028
    call setCursor
    
    ld a, (jogador)
    cp 1
    jp z, mostra_jogador1
    cp 2
    jp z, mostra_jogador2
    ret

mostra_jogador1:
    xor a
    ld bc, $0808
    ld hl, dx
    call drawGraphic
    ret


mostra_jogador2:
    xor a
    ld bc, $0808
    ld hl, do
    call drawGraphic
    ret

desenha_cursor:
    LD a, (cursor_x)
    cp 0
    call nz, ajuste_cursor
    LD B, A
    add a, 8
    ld d, a
    
    ld a, (cursor_y)
    cp 0
    call nz, ajuste_cursor
    ld c, a
    add a, 8
    ld e, a
    call fillBox
    RET
    
    
    
desenha_jogadas:
    LD B, 9
    LD HL, tabuleiro 
    LD DE, $0000 ; cursor
desenha_jogadas_loop:
    ld a, (hl)
    cp 1
    call z, draw_X
    cp 2 
    call z, draw_O
    inc HL
    ld a, d
    add a,11
    ld d, a
    
    ld a, b
    cp 7
    jp nz, $+8
    xor a
    ld d, a
    add a, 11
    ld e, a
    
    ld a, b
    cp 4
    jp nz, $+8
    xor a
    ld d, a
    add a, 22
    ld e, a
    

    DJNZ desenha_jogadas_loop
    ret
    
draw_X:
    push af
    push bc
    push de
    push hl
    
    push de
    pop bc
    call setCursor
    
    LD BC, $0808
    LD HL, dx
    xor a
    call drawGraphic
    
    pop hl
    pop de
    pop bc
    pop af
    ret
    
draw_O:
    push af
    push bc
    push de
    push hl
    
    push de
    pop bc
    call setCursor
    
    LD BC, $0808
    LD HL, do
    xor a
    call drawGraphic
    
    pop hl
    pop de
    pop bc
    pop af
    ret
    
desenha_tabuleiro:
    LD BC, $0A00
    ld DE, $0A1E
    call drawLine
    
    LD BC, $1400
    ld DE, $141E
    call drawLine
    
    LD BC, $000A
    ld DE, $1E0A
    call drawLine
    
    LD BC, $0014
    ld DE, $1E14
    call drawLine
    RET
    
    

msg_winX:    .db "X - GANHOU!!!",0
msg_winO:    .db "O - GANHOU!!!",0
msg_velha:   .db "DEU VELHA!!!",0
msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER ",0
gameover    .db $00
dx: .db     0xC3, 0xC3, 0x24, 0x18, 0x18, 0x24, 0xC3, 0xC3
do: .db     0x3C, 0x42, 0x81, 0x81, 0x81, 0x81, 0x42, 0x3C

cursor_x:   .db 0x00
cursor_y:   .db 0x00
jogador:    .db 0x01

; 0x01 = X
; 0x02 = O
tabuleiro:  .db 0x0A, 0x0A, 0x0A
            .db 0x0A, 0x0A, 0x0A 
            .db 0x0A, 0x0A, 0x0A
    

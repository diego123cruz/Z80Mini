;   API Z80Mini:
delay500ms          equ     0x0100  ;   Delay 500ms
delay               equ     0x0103  ;   On entry: DE = Delay time in milliseconds
I2C_Open            equ     0x0106  ;   On entry: A = Device address (bit zero is read flag)
I2C_Close           equ     0x0109  ;   Close
I2C_Read            equ     0x010C  ;   On exit: If successful A = data byte and Z flagged
I2C_Write           equ     0x010F  ;   On entry: A = Data byte, or Address byte (bit zero is read flag)
keyboardIsEsc       equ     0x0112  ;   Verifica se ESC foi precionada. On exit: If press A = CTRLC and NZ flagged
keyboardWaitA       equ     0x0115  ;   Aguarda tecla, letra em A. (BC DE HL preserved)
keyboardA           equ     0x0118  ;   Lê teclado, Se tecla Carry=1. Letra em A. (BC DE HL preserved)
setDefaultSerialA   equ     0x011B  ;   Seta terminal padrao porta A, Quando reinicia volta para A.
setDefaultSerialB   equ     0x011E  ;   Seta terminal padrao porta B (P2), Quando reinicia volta para A.
serialPrintA        equ     0x0121  ;   Imprime char in A no terminal setado.
serialInputA        equ     0x0124  ;   Aguarda receber char no terminal setado. Retorno em A.
serialPrintStr      equ     0x0127  ;   Imprime string (HL) terminado em 0 no terminal setado. MAX 128 chars. MODIFIES : A,B,C
serialCRLF          equ     0x012A  ;   Imprime CR e LF no terminal setado.
serialHexA          equ     0x012D  ;   Imprime byte em A no formato HEX, no terminal setado. Ex: 'D' = 44
serialHexHL         equ     0x0130  ;   Imprime HL como 4 digitos hexadecimais, no terminal setado. Ex: HL=$80FF -> imprime "80FF"
serialInHexA        equ     0x0133  ;   Pegar 2 caracteres ASCII (0-9 A-F), do terminal setado e converte em um byte em A. SEM ECHO
serialInHexHL       equ     0x0136  ;   Pegar 4 caracteres ASCII (0-9 A-F), do terminal setado e converte em HL. SEM ECHO

initLCD             equ     0x0139  ;   Inicializa GLCD
clearGBUF           equ     0x013C  ;   Limpa buffer da memoria de grafico. Precisa do plotToLCD para refletir no lcd.
clearGrLCD          equ     0x013F  ;   Limpa memoria grafico do GLCD. Sem o plotToLCD.
clearTxtLCD         equ     0x0142  ;   Limpar caracteres do LCD
setGrMode           equ     0x0145  ;   Seta modo Grafico. 128x64
setTxtMode          equ     0x0148  ;   Seta mode Text. 16x4 equivalente
drawBox             equ     0x014B  ;   Desenha caixa. Entradas: BC = X0,Y0 - DE = X1,Y1    Destroys: HL
drawLine            equ     0x014E  ;   Desenha linha.  Entradas: BC = X0,Y0 - DE = X1,Y1
drawCircle          equ     0x0151  ;   Desenha circulo. Entradas BC = xm,ym (Ponro do Meio) - E = radius
drawPixel           equ     0x0154  ;   Desenha um pixel em X Y.  Entrada B = column/X (0-127), C = row/Y (0-63)   Destroys: HL
fillBox             equ     0x0157  ;   Desenha caixa preenchida. Entradas: BC = X0,Y0 - DE = X1,Y1    Destroys: HL
fillCircle          equ     0x015A  ;   Desenha circulo preenchido. Entradas BC = xm,ym (Ponro do Meio) - E = radius
plotToLCD           equ     0x015D  ;   Rotina principal de desenho. Move GBUF para o LCD e limpa o buffer ou não (setBufClear, setBufNoClear).  Destroys: ALL
printString         equ     0x0160  ;   Imprimir texto ASCII em uma determinada linha. Entradas: A = 0 a 3 Número da linha. .db "String" na próxima linha, terminar com 0
printChars          equ     0x0163  ;   (Ver detalhes) Imprimir caracteres na posição X,Y. Entrada B = coluna/X (0-7), C = linha/Y (0-3). HL = Endereço inicial do texto a ser exibido, termina com 0
setInt38            equ     0x0166  ;   Seta vetor de interrupcao int38. Entradas HL = RST38_ADDR
setint66            equ     0x0169  ;   Seta vetor de interrupcao int66. Entradas HL = RST66_ADDR
setBufClear         equ     0x016C  ;   Configura limpeza do buffer após a saída para o LCD e vai para clearGBUF.
setBufNoClear       equ     0x016F  ;   Configura para não limpar o buffer após a saída para o LCD.
clearPixel          equ     0x0172  ;   Limpa um pixel X Y.  Input B = column/X (0-127), C = row/Y (0-63)    Destroy HL
flipPixel           equ     0x0175  ;   Inverte um pixel X Y.  Input B = column/X (0-127), C = row/Y (0-63)    Destroy HL
drawGraphic         equ     0x0178  ;   Desenha no buffer. Entrada: A = número ASCII ou se A=0 Então  HL = Endereço dos dados gráficos. B = largura do gráfico em pixels (1-128). C = altura do gráfico em pixels (1-64). Destroy: ALL
invGraphic          equ     0x017B  ;   Altera a flag de desenho inverso. (não inverte grafico atual) Destroy A
initTerminal        equ     0x017E  ;   Inicializa o Terminal GLCD. Cursor 0,0 e limpa buffer.
sendCharToLCD       equ     0x0181  ;   Envia ou manipula caracteres ASCII para a tela GLCD (Terminal). Entrada: A = caractere ASCII a ser enviado para a tela GLCD. A = somente cursor desenhado.
sendStringToLCD     equ     0x0184  ;   Imprime string no terminal GLCD. DE = inicio da string. A = caractere para parar a impressão. A impressão para e retorna quando um CR é impresso. Destroy ALL
sendRegToLCD        equ     0x0187  ;   Imprime byte em A no formato HEX, no GLCD. Ex: 'D' = 44
sendHLToLCD         equ     0x018A  ;   Imprime HL como 4 digitos hexadecimais, no GLCD. Ex: HL=$80FF -> imprime "80FF"
setCursor           equ     0x018D  ;   Define a posição do cursor gráfico. Entradas: BC = X,Y onde X = 0..127, Y = 0..63   Destroy A
getCursor           equ     0x0190  ;   Obter a posição do cursor. Saídas: BC = X,Y onde X = 0..127, Y = 0..63
displayCursor       equ     0x0193  ;   Exibir Cursor. Entrada: A = 0, Ativar cursor, A = diferente de zero, Desativar cursor.
autoLF              equ     0x0196  ;   Avanço de linha automático quando o cursor atinge o final da linha (Terminal). Entrada: A = 0, Avanço de linha automático; A = diferente de zero, Sem avanço de linha automático. Padrao LIGADO.
underline           equ     0x0199  ;   Exibir sublinhado no caractere (Terminal). O estado inicial é sem sublinhado. Chamar esta rotina irá ALTERAR/DESLIGAR o sinalizador de sublinhado.
plotAlways          equ     0x019C  ;   Quando sendCharToLCD é chamado, Atualiza GLCD ou não. Se Desativado plotToLCD deve ser chamado atualizar o GLCD. Entrada: A=0, Plotar sempre; A>0, Não plotar. O padrão é Plotar sempre.

; -------- Constantes gerais --------
CR:       EQU   0DH
BKS:      EQU   08H
DEL:      EQU   7FH
ESC:      EQU   1BH
SPACE:    EQU   20H


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
    

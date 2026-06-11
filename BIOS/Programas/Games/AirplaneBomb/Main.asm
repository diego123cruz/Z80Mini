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

CR:     EQU 0DH                 ; Carriage return
SPACE:  EQU 20H                 ; Space
ESC:	EQU 1BH			; Esc

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

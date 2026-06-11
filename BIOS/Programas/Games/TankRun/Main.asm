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
resetCollisionPixel equ     0x0294  ;   Limpa flag de colisao
checkCollisionPixel equ     0x0299  ;   Check se um pixel ja estava ligado quando tenta ligar. JP Z, SEM_COLISAO. JP NZ, COLISAO.

; -------- Constantes gerais --------
CR:       EQU   0DH
BKS:      EQU   08H
ESC:      EQU   1BH
SPACE:    EQU   20H


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

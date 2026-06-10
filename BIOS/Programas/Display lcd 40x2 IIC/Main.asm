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



; ============================================================
;  LCD 40x2 via I2C - Z80 Assembly
;  Sintaxe: ZASM
;  Módulo I2C: PCF8574 @ $4E
;  Controlador LCD: HD44780 compatível, modo 4 bits

;
;  Pinagem PCF8574 -> HD44780:
;    P0 = RS  (0=cmd, 1=dado)
;    P1 = RW  (sempre 0)
;    P2 = EN  (pulso de enable)
;    P3 = BL  (backlight, sempre 1)
;    P4 = DB4
;    P5 = DB5
;    P6 = DB6
;    P7 = DB7
;
;  DDRAM LCD 40x2:
;    Linha 1: $00..$27  (Set DDRAM = $80..$A7)
;    Linha 2: $40..$67  (Set DDRAM = $C0..$E7)
; ============================================================


LCD_I2C     equ  $4E

; bits PCF8574
BL          equ  $08            ; P3 backlight
EN          equ  $04            ; P2 enable
RS_DAT      equ  $01            ; P0 RS=1 dado

; comandos HD44780
CMD_CLEAR   equ  $01
CMD_ENTRY   equ  $06
CMD_DISP_ON equ  $0C
CMD_FUNC4   equ  $28
CMD_L1      equ  $80            ; DDRAM linha 1 col 0
CMD_L2      equ  $C0            ; DDRAM linha 2 col 0

; ============================================================
            .org $8000

; ============================================================
;  MAIN
; ============================================================
MAIN:
            call LCD_Init

            ld   a, CMD_L1
            call LCD_SetPos
            ld   hl, STR_L1
            call LCD_Print

            ld   a, CMD_L2
            call LCD_SetPos
            ld   hl, STR_L2
            call LCD_Print

            ;Vai para monitor
            jp 0

LOOP:
            jr   LOOP

; ============================================================
;  Strings terminadas em $00
; ============================================================
STR_L1:
            .text "  Z80 + LCD 40x2 I2C  PCF8574 @ 0x4E    "
            .byte 0
STR_L2:
            .text "  HD44780  4-bit mode  Assembly  ZASM    "
            .byte 0

; ============================================================
;  LCD_Init — inicializa HD44780 em modo 4 bits
; ============================================================
LCD_Init:
            ld   de, 50         ; >40ms power-on
            call delay

            ; reset por software: 3x nibble $3 (simula 8-bit)
            call RESET_PULSE
            ld   de, 5
            call delay

            call RESET_PULSE
            ld   de, 1
            call delay

            call RESET_PULSE
            ld   de, 1
            call delay

            ; entra em modo 4 bits
            ld   a, $20
            call NIB_CMD
            ld   de, 1
            call delay

            ; configuração em 4 bits
            ld   a, CMD_FUNC4   ; Function Set: 4-bit, 2 linhas, 5x8
            call CMD4

            ld   a, $08         ; Display OFF
            call CMD4

            ld   a, CMD_CLEAR   ; Clear Display
            call CMD4
            ld   de, 2          ; >1.6ms
            call delay

            ld   a, CMD_ENTRY   ; Entry Mode
            call CMD4

            ld   a, CMD_DISP_ON ; Display ON, cursor OFF
            call CMD4

            ret

; ============================================================
;  LCD_SetPos — posiciona cursor pelo endereço DDRAM
;  Entrada: A = endereço (ex: CMD_L1 + coluna)
; ============================================================
LCD_SetPos:
            or   $80            ; bit 7 = Set DDRAM Address
            call CMD4
            ret

; ============================================================
;  LCD_GotoXY — posiciona por coluna e linha
;  Entrada: H = coluna (0..39), L = linha (0 ou 1)
; ============================================================
LCD_GotoXY:
            ld   a, l
            or   a
            ld   a, $00
            jr   z, GXY_SET
            ld   a, $40         ; linha 2 base
GXY_SET:
            add  a, h
            or   $80
            call CMD4
            ret

; ============================================================
;  LCD_Clear
; ============================================================
LCD_Clear:
            ld   a, CMD_CLEAR
            call CMD4
            ld   de, 2
            call delay
            ret

; ============================================================
;  LCD_Print — imprime string terminada em $00
;  Entrada: HL = ponteiro
; ============================================================
LCD_Print:
            ld   a, (hl)
            or   a
            ret  z
            call LCD_Char
            inc  hl
            jr   LCD_Print

; ============================================================
;  LCD_Char — imprime um caractere
;  Entrada: A = ASCII
; ============================================================
LCD_Char:
            call DAT4
            ret

; ============================================================
;  RESET_PULSE — pulso nibble $3 em modo 8-bit
;  Byte: $30 | BL = $38, com EN = $3C
; ============================================================
RESET_PULSE:
            ld   a, $38         ; nibble $3 | BL,  EN=0
            call PCF_Send
            ld   a, $3C         ; nibble $3 | BL | EN
            call PCF_Send
            ld   a, $38         ; nibble $3 | BL,  EN=0
            call PCF_Send
            ret

; ============================================================
;  NIB_CMD — envia nibble alto de A como COMANDO (RS=0)
;  Entrada: A = nibble nos bits 7-4  (bits 3-0 = 0)
; ============================================================
NIB_CMD:
            and  $F0
            or   BL             ; + backlight, RS=0, EN=0
            call PCF_Send
            or   EN             ; EN=1
            call PCF_Send
            xor  EN             ; EN=0
            call PCF_Send
            ret

; ============================================================
;  NIB_DAT — envia nibble alto de A como DADO (RS=1)
;  Entrada: A = nibble nos bits 7-4  (bits 3-0 = 0)
; ============================================================
NIB_DAT:
            and  $F0
            or   BL             ; + backlight
            or   RS_DAT         ; RS=1, EN=0
            call PCF_Send
            or   EN             ; EN=1
            call PCF_Send
            xor  EN             ; EN=0
            call PCF_Send
            ret

; ============================================================
;  CMD4 — envia byte de COMANDO em modo 4-bit (RS=0)
;  Entrada: A = byte de comando
; ============================================================
CMD4:
            push bc
            ld   b, a

            and  $F0            ; nibble alto
            call NIB_CMD

            ld   a, b           ; nibble baixo → bits 7-4
            rlca
            rlca
            rlca
            rlca
            and  $F0
            call NIB_CMD

            pop  bc
            ret

; ============================================================
;  DAT4 — envia byte de DADO em modo 4-bit (RS=1)
;  Entrada: A = byte de dado (ASCII)
; ============================================================
DAT4:
            push bc
            ld   b, a

            and  $F0            ; nibble alto
            call NIB_DAT

            ld   a, b           ; nibble baixo → bits 7-4
            rlca
            rlca
            rlca
            rlca
            and  $F0
            call NIB_DAT

            pop  bc
            ret

; ============================================================
;  PCF_Send — envia 1 byte ao PCF8574 via I2C
;  Entrada:  A = byte
;  Preserva: AF BC DE HL
; ============================================================
PCF_Send:
            push af
            push bc
            push de
            push hl

            ld   b, a           ; guarda byte em B
                                ; ROM preserva BC → B está seguro

            ld   a, LCD_I2C
            call I2C_Open       ; START + endereço

            ld   a, b           ; recupera byte
            call I2C_Write      ; envia

            call I2C_Close      ; STOP

            pop  hl
            pop  de
            pop  bc
            pop  af
            ret

; ============================================================
;  LCD_PrintNum8 — imprime número 0-255 em decimal
;  Entrada: A = número
; ============================================================
LCD_PrintNum8:
            push bc
            push de
            ld   c, a
            ld   b, 0           ; flag zero-suppress

            ld   d, 100
            call DIGIT
            ld   d, 10
            call DIGIT

            ld   a, c           ; unidades (sempre imprime)
            add  a, '0'
            call DAT4

            pop  de
            pop  bc
            ret

DIGIT:
            ld   a, c
            ld   e, 0
DG_LOOP:
            cp   d
            jr   c, DG_DONE
            sub  d
            inc  e
            jr   DG_LOOP
DG_DONE:
            ld   c, a
            ld   a, e
            or   a
            jr   z, DG_ZERO
            ld   b, 1
            add  a, '0'
            call DAT4
            ret
DG_ZERO:
            ld   a, b
            or   a
            ret  z
            ld   a, '0'
            call DAT4
            ret

; ============================================================
            .end MAIN

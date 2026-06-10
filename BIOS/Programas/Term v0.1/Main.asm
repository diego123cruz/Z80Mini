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
LF:       EQU   0AH
BKS:      EQU   08H
DEL:      EQU   7FH
ESC:      EQU   1BH
SPACE:    EQU   20H
NUL:      EQU   00H
FF:       EQU   0CH                 ; Form Feed -> Limpa lcd

; -----------------------------------------------------------------------------
; SIO/2 - SERIAL
; -----------------------------------------------------------------------------
SIOA_D:   EQU   $00
SIOA_C:   EQU   $02
SIOB_D:   EQU   $01   ; Conector P2
SIOB_C:   EQU   $03   ; Conector P2

SER_BUFSIZE     .EQU  $200    ; 512 bytes
SER_FULLSIZE    .EQU  $80
SER_EMPTYSIZE   .EQU  5

PLOT_EVERY  EQU  3      ; plota a cada N chars recebidos
        org $8000

;------------------------------------------------------------------------------
; Inicializacao
;------------------------------------------------------------------------------
inicio:
        ; Initialise SIO/2 B - Printer (P2 conector)
        LD      A,$04
        OUT     (SIOB_C),A
        LD      A,$C4
        OUT     (SIOB_C),A

        LD      A,$03
        OUT     (SIOB_C),A
        LD      A,$E1
        OUT     (SIOB_C),A

        LD      A,$05
        OUT     (SIOB_C),A
        LD      A,$68
        OUT     (SIOB_C),A

        ; WR1 = interrupção em todos os caracteres recebidos
        LD      A,1
        OUT     (SIOB_C),A
        LD      A,%00011000
        OUT     (SIOB_C),A

        ; Inicializa buffer serial B
        LD      HL,$0000
        LD      (serBBufUsed),HL
        LD      HL,serBBuf
        LD      (serBInPtr),HL
        LD      (serBRdPtr),HL


        XOR     A
        LD      (plotCounter), A


        ; Configura serial B como padrao
        CALL    setDefaultSerialB

        ; Configura ISR serial B via INT38
        LD      HL,serialInt
        CALL    setInt38
        IM      1
        EI

        LD      A,FF
        CALL    sendCharToLCD

        LD      DE,msg
        CALL    sendStringToLCD

;------------------------------------------------------------------------------
; Loop principal — le byte do buffer e exibe no LCD
;------------------------------------------------------------------------------
LOOP:
        CALL    coninB
        CALL    PUTCHAR
        JP      LOOP

;------------------------------------------------------------------------------
; ISR Serial B
; O trampolim em $0038 faz PUSH HL antes de saltar aqui,
; por isso o primeiro POP HL é obrigatório para desfazer esse push.
;------------------------------------------------------------------------------
serialInt:
        POP     HL              ; desfaz PUSH HL do trampolim em $0038

        PUSH    AF
        PUSH    HL
        PUSH    BC

serialIntB:
        ; Grava na posição atual, incrementa depois
        LD      HL,(serBInPtr)
        IN      A,(SIOB_D)      ; lê byte UMA vez
        LD      (HL),A          ; grava no buffer

        ; Avança serBInPtr com wrap por comparação de endereço
        INC     HL
        LD      BC,serBBuf + SER_BUFSIZE
        LD      A,H
        CP      B
        JR      NZ,notBWrap
        LD      A,L
        CP      C
        JR      NZ,notBWrap
        LD      HL,serBBuf      ; wrap: volta ao início
notBWrap:
        LD      (serBInPtr),HL

        ; Incrementa contador (16 bits)
        LD      HL,(serBBufUsed)
        INC     HL
        LD      (serBBufUsed),HL

        POP     BC
        POP     HL
        POP     AF
        EI
        RETI

;------------------------------------------------------------------------------
; coninB — aguarda e retorna um byte do buffer serial B em A
; Também verifica teclado: se tecla pressionada, chama getLine
;------------------------------------------------------------------------------
coninB:
waitForCharB:
        CALL    keyboardA
        CALL    C,getLine       ; tecla pressionada: envia linha via serial

        ; Verifica se buffer tem dados (16 bits)
        LD      HL,(serBBufUsed)
        LD      A,H
        OR      L
        JR      Z,waitForCharB  ; vazio, aguarda

        ; Lê byte na posição atual de leitura
        LD      HL,(serBRdPtr)
        LD      A,(HL)          ; lê o byte
        PUSH    AF              ; preserva byte lido

        ; Avança serBRdPtr com wrap
        INC     HL
        LD      BC,serBBuf + SER_BUFSIZE
        LD      A,H
        CP      B
        JR      NZ,notRdWrapB
        LD      A,L
        CP      C
        JR      NZ,notRdWrapB
        LD      HL,serBBuf      ; wrap: volta ao início
notRdWrapB:
        DI
        LD      (serBRdPtr),HL

        ; Decrementa contador (16 bits)
        LD      HL,(serBBufUsed)
        DEC     HL
        LD      (serBBufUsed),HL
        EI

        POP     AF              ; byte lido de volta em A
        RET

;------------------------------------------------------------------------------
; getLine — captura linha do teclado e envia pela serial
;------------------------------------------------------------------------------
getLine:
        CALL    GETLINE_KEY
        RET

;------------------------------------------------------------------------------
; PUTCHAR — exibe o caractere em A no LCD e atualiza display
;------------------------------------------------------------------------------
PUTCHAR:
        PUSH    BC
        PUSH    DE
        PUSH    HL

        PUSH    AF
        LD      A, 1
        CALL    plotAlways      ; desativa plot automático
        POP     AF

        CALL    sendCharToLCD   ; só grava no buffer, não plota

        ; Força plot se for CR
        CP      CR
        JR      Z, PUTCHARdoPlot
        CP      LF
        JR      Z, PUTCHARdoPlot

        ; Incrementa contador
        LD      A, (plotCounter)
        INC     A
        LD      (plotCounter), A
        CP      PLOT_EVERY
        JR      C, PUTCHARskip        ; ainda não chegou em N

PUTCHARdoPlot:
        XOR     A
        LD      (plotCounter), A
        CALL    plotToLCD

PUTCHARskip:
        POP     HL
        POP     DE
        POP     BC
        RET


PUTCHAR_NOW:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    sendCharToLCD
        CALL    plotToLCD
        POP     HL
        POP     DE
        POP     BC
        RET

;------------------------------------------------------------------------------
; GETLINE_KEY — lê linha do teclado com eco no LCD, envia pela serial ao Enter
;------------------------------------------------------------------------------
GETLINE_KEY:
        LD      HL,LINEBUF
        LD      B,255           ; máx 255 chars + NUL
GETLINE_LOOP_KEY:
        CALL    keyboardWaitA
        CP      CR
        JR      Z,GETLINE_DONE_KEY
        CP      BKS
        JR      Z,GETLINE_KEY_DEL
        LD      C,A
        LD      A,B
        CP      0
        JR      Z,GETLINE_LOOP_KEY  ; buffer cheio, ignora
        LD      A,C
        LD      (HL),A
        INC     HL
        DEC     B
        CALL    PUTCHAR_NOW             ; eco no LCD
        JR      GETLINE_LOOP_KEY
GETLINE_DONE_KEY:
        LD      (HL),CR
        INC     HL
        LD      (HL),NUL            ; termina string
        LD      HL,LINEBUF
        CALL    serialPrintStr      ; envia pela serial
        RET
GETLINE_KEY_DEL:
        LD      D,A             ; salva A
        LD      A,B
        CP      255             ; buffer vazio? (nenhum char digitado)
        JR      Z,GETLINE_LOOP_KEY  ; sim, ignora backspace
        DEC     HL
        LD      (HL),BKS
        INC     B
        LD      A,D             ; restaura A
        CALL    PUTCHAR_NOW
        JR      GETLINE_LOOP_KEY

;------------------------------------------------------------------------------
; Dados
;------------------------------------------------------------------------------
msg:    db      "Term v0.1", CR, 0

;------------------------------------------------------------------------------
; RAM
;------------------------------------------------------------------------------
LINEBUF:        DS      255
serBBuf:        .ds     SER_BUFSIZE
serBInPtr:      .ds     2
serBRdPtr:      .ds     2
serBBufUsed:    .ds     2
plotCounter:    .ds     1
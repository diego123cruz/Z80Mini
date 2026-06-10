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

    ORG 8000H

inicio:
    ; liga display
    LD A, 0EH
    CALL I2C_Open
    LD A, 00H
    CALL I2C_Write
    LD A, 03H
    CALL I2C_Write
    CALL I2C_Close

loop:
    ; le ricoh223 - segundos
    LD A, 64H
    CALL I2C_Open
    LD A, 00H           ; segundos
    CALL I2C_Write
    LD A, 65H           ; read = addr + 1
    CALL I2C_Open
    CALL I2C_Read
    LD (segundos), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; le ricoh223 - minutos
    LD A, 64H
    CALL I2C_Open
    LD A, 10H           ; minutos 
    CALL I2C_Write
    LD A, 65H
    CALL I2C_Open
    CALL I2C_Read
    AND 01111111B
    LD (minutos), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; le ricoh223 - hora
    LD A, 64H
    CALL I2C_Open
    LD A, 20H           ; hora
    CALL I2C_Write
    LD A, 65H
    CALL I2C_Open
    CALL I2C_Read
    AND 00111111B
    LD (horas), A
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; display escreve low (minutos)
    LD A, 0EH
    CALL I2C_Open
    LD A, 01H
    CALL I2C_Write
    LD A, (minutos)
    CALL I2C_Write
    CALL I2C_Close

    LD DE, 0032H
    CALL delay

    ; display escreve high (horas)
    LD A, 0EH
    CALL I2C_Open
    LD A, 02H
    CALL I2C_Write
    LD A, (horas)
    CALL I2C_Write
    CALL I2C_Close

    LD DE, 0396H
    CALL delay

    ; pisca ponto ':'
    LD A, 0EH
    CALL I2C_Open
    LD A, 00H
    CALL I2C_Write
    LD A, (status)
    XOR 04H
    LD (status), A
    CALL I2C_Write
    CALL I2C_Close

    JP loop

status   DB 03H
horas    DB 00H
minutos  DB 00H
segundos DB 00H

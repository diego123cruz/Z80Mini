; Z80Mini   -   Maio de 2026

; Sistema Monitor basico v1
;
; Z80 @7.372800Mhz
; ROM 32Kb @28C256      0000-7FFF
; RAM 32kb @62256       8000-FFFF
;
; Teclado Mecânico :) Custom    -   0x40 (Read/Write)
; I2C EEPROM (Drivers A: B: etc...)
; I2C RTC - ricoh223    -   0x64
; I2C Display 4x 7seg, Leds(5), Sons   -   0x0E
; In/Out generic    -   0xC0 (Read/Write)
; Leds  -   0x10
; GLCD 128x64   -   0x70
; USB-SERIAL SIO/2 A    -   0x00
; P2-SERIAL (Printer) SIO/2 B   -   0x00
;
;
; Compilação: zasm --z80 -w -u --bin  Main.asm
;
;
;   Comandos suportados:
;       H / ?       -   Mostra menu de ajuda, listando os comandos.
;       CLS         -   Limpa a tela lcd.
;       IHEX        -   Aguarda recebimento intel hex via serial_A (USB-SERIAL) Ex: :0C800000CDF4.........
;       OUT         -   Escreve byte na saida. (OUT 10 01) Liga led 1 da porta 0x10
;       IN          -   Lê byte da entrada. (IN 0c) Lê byte da entrada 0xC0
;       JUMP        -   Desvia PC para endereço. (JUMP 8000)
;       CALL        -   Salva monitor como retorno e desvia para endereço. (CALL 8000) o programa pode use RET e voltar para o Monitor.
;       DUMP        -   Mostra 40 bytes a partir do endereço atual da ram. (DUMP 8000)
;       WRITE       -   Escreve bytes a partir do endereço. (WRITE 8000) Linha vazia para inserção.
;       EDIT        -   Edita bytes a partir do endereço. (EDIT 8000) Linha vazia não alterar valor atual, "." para edição.
;       I2CLIST     -   Lista dispositivos i2c conectados no barramento.
;       FORMAT      -   Formata eeprom no drive atual.
;       DIR         -   Lista arquivos do driver atual.
;       LOAD        -   Carrega arquivo do drive atual. (LOAD NAME)
;       EXEC        -   Carrega e execulta arquivo do drive atual. (EXEC NAME)
;       DEL         -   Deleta arquivo no drive atual. (DEL NAME)
;       SAVE        -   Salva arquivo no drive atual. Name max 8 chars. (SAVE NAME RAM_ADDR_XXXX SIZE_XXXX) -> save blink 8000 004f
;       
;
;   API Z80Mini:
;       delay500ms          equ     0x0100  ;   Delay 500ms
;       delay               equ     0x0103  ;   On entry: DE = Delay time in milliseconds
;       I2C_Open            equ     0x0106  ;   On entry: A = Device address (bit zero is read flag)
;       I2C_Close           equ     0x0109  ;   Close
;       I2C_Read            equ     0x010C  ;   On exit: If successful A = data byte and Z flagged
;       I2C_Write           equ     0x010F  ;   On entry: A = Data byte, or Address byte (bit zero is read flag)
;       keyboardIsEsc       equ     0x0112  ;   Verifica se ESC foi precionada. On exit: If press A = CTRLC and NZ flagged
;       keyboardWaitA       equ     0x0115  ;   Aguarda tecla, letra em A. (BC DE HL preserved)
;       keyboardA           equ     0x0118  ;   Lê teclado, Se tecla Carry=1. Letra em A. (BC DE HL preserved)
;       setDefaultSerialA   equ     0x011B  ;   Seta terminal padrao porta A, Quando reinicia volta para A.
;       setDefaultSerialB   equ     0x011E  ;   Seta terminal padrao porta B (P2), Quando reinicia volta para A.
;       serialPrintA        equ     0x0121  ;   Imprime char in A no terminal setado.
;       serialInputA        equ     0x0124  ;   Aguarda receber char no terminal setado. Retorno em A.
;       serialPrintStr      equ     0x0127  ;   Imprime string (HL) terminado em 0 no terminal setado. MAX 128 chars. MODIFIES : A,B,C
;       serialCRLF          equ     0x012A  ;   Imprime CR e LF no terminal setado.
;       serialHexA          equ     0x012D  ;   Imprime byte em A no formato HEX, no terminal setado. Ex: 'D' = 44
;       serialHexHL         equ     0x0130  ;   Imprime HL como 4 digitos hexadecimais, no terminal setado. Ex: HL=$80FF -> imprime "80FF"
;       serialInHexA        equ     0x0133  ;   Pegar 2 caracteres ASCII (0-9 A-F), do terminal setado e converte em um byte em A. SEM ECHO
;       serialInHexHL       equ     0x0136  ;   Pegar 4 caracteres ASCII (0-9 A-F), do terminal setado e converte em HL. SEM ECHO

;       initLCD             equ     0x0139  ;   Inicializa GLCD
;       clearGBUF           equ     0x013C  ;   Limpa buffer da memoria de grafico. Precisa do plotToLCD para refletir no lcd.
;       clearGrLCD          equ     0x013F  ;   Limpa memoria grafico do GLCD. Sem o plotToLCD.
;       clearTxtLCD         equ     0x0142  ;   Limpar caracteres do LCD
;       setGrMode           equ     0x0145  ;   Seta modo Grafico. 128x64
;       setTxtMode          equ     0x0148  ;   Seta mode Text. 16x4 equivalente
;       drawBox             equ     0x014B  ;   Desenha caixa. Entradas: BC = X0,Y0 - DE = X1,Y1    Destroys: HL
;       drawLine            equ     0x014E  ;   Desenha linha.  Entradas: BC = X0,Y0 - DE = X1,Y1
;       drawCircle          equ     0x0151  ;   Desenha circulo. Entradas BC = xm,ym (Ponro do Meio) - E = radius
;       drawPixel           equ     0x0154  ;   Desenha um pixel em X Y.  Entrada B = column/X (0-127), C = row/Y (0-63)   Destroys: HL
;       fillBox             equ     0x0157  ;   Desenha caixa preenchida. Entradas: BC = X0,Y0 - DE = X1,Y1    Destroys: HL
;       fillCircle          equ     0x015A  ;   Desenha circulo preenchido. Entradas BC = xm,ym (Ponro do Meio) - E = radius
;       plotToLCD           equ     0x015D  ;   Rotina principal de desenho. Move GBUF para o LCD e limpa o buffer ou não (setBufClear, setBufNoClear).  Destroys: ALL
;       printString         equ     0x0160  ;   Imprimir texto ASCII em uma determinada linha. Entradas: A = 0 a 3 Número da linha. .db "String" na próxima linha, terminar com 0
;       printChars          equ     0x0163  ;   (Ver detalhes) Imprimir caracteres na posição X,Y. Entrada B = coluna/X (0-7), C = linha/Y (0-3). HL = Endereço inicial do texto a ser exibido, termina com 0
;       delayUS             equ     0x0166  ;   Delay lcd...
;       delayMS             equ     0x0169  ;   Delay lcd...
;       setBufClear         equ     0x016C  ;   Configura limpeza do buffer após a saída para o LCD e vai para clearGBUF.
;       setBufNoClear       equ     0x016F  ;   Configura para não limpar o buffer após a saída para o LCD.
;       clearPixel          equ     0x0172  ;   Limpa um pixel X Y.  Input B = column/X (0-127), C = row/Y (0-63)    Destroy HL
;       flipPixel           equ     0x0175  ;   Inverte um pixel X Y.  Input B = column/X (0-127), C = row/Y (0-63)    Destroy HL
;       drawGraphic         equ     0x0178  ;   Desenha no buffer. Entrada: A = número ASCII ou se A=0 Então  HL = Endereço dos dados gráficos. B = largura do gráfico em pixels (1-128). C = altura do gráfico em pixels (1-64). Destroy: ALL
;       invGraphic          equ     0x017B  ;   Altera a flag de desenho inverso. (não inverte grafico atual) Destroy A
;       initTerminal        equ     0x017E  ;   Inicializa o Terminal GLCD. Cursor 0,0 e limpa buffer.
;       sendCharToLCD       equ     0x0181  ;   Envia ou manipula caracteres ASCII para a tela GLCD (Terminal). Entrada: A = caractere ASCII a ser enviado para a tela GLCD. A = somente cursor desenhado.
;       sendStringToLCD     equ     0x0184  ;   Imprime string no terminal GLCD. DE = inicio da string. A = caractere para parar a impressão. A impressão para e retorna quando um CR é impresso. Destroy ALL
;       sendRegToLCD        equ     0x0187  ;   Imprime byte em A no formato HEX, no GLCD. Ex: 'D' = 44
;       sendHLToLCD         equ     0x018A  ;   Imprime HL como 4 digitos hexadecimais, no GLCD. Ex: HL=$80FF -> imprime "80FF"
;       setCursor           equ     0x018D  ;   Define a posição do cursor gráfico. Entradas: BC = X,Y onde X = 0..127, Y = 0..63   Destroy A
;       getCursor           equ     0x0190  ;   Obter a posição do cursor. Saídas: BC = X,Y onde X = 0..127, Y = 0..63
;       displayCursor       equ     0x0193  ;   Exibir Cursor. Entrada: A = 0, Ativar cursor, A = diferente de zero, Desativar cursor.
;       autoLF              equ     0x0196  ;   Avanço de linha automático quando o cursor atinge o final da linha (Terminal). Entrada: A = 0, Avanço de linha automático; A = diferente de zero, Sem avanço de linha automático. Padrao LIGADO.
;       underline           equ     0x0199  ;   Exibir sublinhado no caractere (Terminal). O estado inicial é sem sublinhado. Chamar esta rotina irá ALTERAR/DESLIGAR o sinalizador de sublinhado.
;       plotAlways          equ     0x019C  ;   Quando sendCharToLCD é chamado, Atualiza GLCD ou não. Se Desativado plotToLCD deve ser chamado atualizar o GLCD. Entrada: A=0, Plotar sempre; A>0, Não plotar. O padrão é Plotar sempre.




; -----------------------------------------------------------------------------
; H_Delay CONFIG
; -----------------------------------------------------------------------------
kCPUClock:          .EQU 7372800       ;CPU clock speed in Hz
kDelayOH:           .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:           .EQU 26             ;Inner loop time in Tcycles
kDelayTA:           .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:           .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:          .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop


; -----------------------------------------------------------------------------
; SYSTEM SETTINGS
; -----------------------------------------------------------------------------
SYSTEM_SP:	        .EQU 	$FFF0	;INITIAL STACK POINTER

; -----------------------------------------------------------------------------
; SIO/2 - SERIAL
; -----------------------------------------------------------------------------
SIOA_D		        .EQU	$00
SIOA_C		        .EQU	$02
SIOB_D		        .EQU	$01 ; Conector P2
SIOB_C		        .EQU	$03 ; Conector P2


; -----------------------------------------------------------------------------
; I2C SETTINGS
; -----------------------------------------------------------------------------
TIMEOUT:        .EQU    10000      ; Timeout loop counter
EEDRIVE_A       .EQU    $A0        ; Drive A
EEDRIVE_B       .EQU    $AE        ; Drive B

; -----------------------------------------------------------------------------
; PORTS
; -----------------------------------------------------------------------------
GLCD_INST           .EQU    $70
GLCD_DATA           .EQU    $71

KEYBOARD		    .EQU	$40




BKSP:   EQU 08H                 ; Back space 08H
TAB:    EQU 09H                 ; Horizontal TAB
LF:     EQU 0AH                 ; Line feed
CS:     EQU 0CH                 ; Clear screen
CR:     EQU 0DH                 ; Carriage return
SPACE:  EQU 20H                 ; Space
CURSOR: EQU 8FH                 ; Cursor



    .ORG $0000
    JP INICIO

    .ORG $0008
RST08:	JP	CONOUT

    .ORG $0010
RST10:	JP	CONIN

    .ORG 0018H ; check break - BASIC
RST18   JP CHKKEY

    .ORG $0100
    ;   Delay
    JP DELAY_500MS
    JP H_Delay
    ;   I2C
    JP I2C_Open
    JP I2C_Close
    JP I2C_Read
    JP I2C_Write
    ;   Keyboard
    JP CHKKEY
    JP CONIN
    JP CONIN_NOT_LOOP
    ;   Serial
    JP SET_DEFAULT_SERIAL_A
    JP SET_DEFAULT_SERIAL_B
    JP OUTCH
    JP INCH
    JP SNDSTR
    JP SERIAL_A_TXCRLF
    JP SERIAL_A_PRINT_A_HEX
    JP SERIAL_A_PRINT_HL_HEX
    JP SERIAL_GET_HEX_A
    JP SERIAL_GET_HEX_HL
    ;   GLCD
    JP initLCD
    JP clearGBUF
    JP clearGrLCD
    JP clearTxtLCD
    JP setGrMode
    JP setTxtMode
    JP drawBox
    JP drawLine
    JP drawCircle
    JP drawPixel
    JP fillBox
    JP fillCircle
    JP plotToLCD
    JP printString
    JP printChars
    JP delayUS
    JP delayMS
    JP setBufClear
    JP setBufNoClear
    JP clearPixel
    JP flipPixel
    JP drawGraphic
    JP invGraphic
    JP initTerminal
    JP sendCharToLCD
    JP sendStringToLCD
    JP sendRegToLCD
    JP sendHLToLCD
    JP setCursor
    JP getCursor
    JP displayCursor
    JP autoLF
    JP underline
    JP plotAlways












; ============================================================
; KEYMAPS
; ============================================================

;	$FF - Capsloock
;	$FE - Shift left
;	$FD - Ctrl left
;	$FC - Windows
;	$FB - Alt left
;	$FA - Alt Gr    (Load intel hex - Serial A)
;	$F9 - LUZ   (CALL 8000H)
;	$F8 - Shift Right   (Display Scroll UP)
;	$F7 - Ctrl Right    (Display Scroll DOWN)
;	$F6 - Fn
;	$F5 - 
;	$F4 - 

KEYMAP_NORMAL:
    DB  $1B,  $09,  $FF,  $FE,  $FD,  $FC,  $FB,  $20
    DB   '1', 'q',  'a',  '\',  $00,  $FA,  $F6,  $F9
    DB   '3', 'e',  'd',  'x',  ',',  'l',  'o',  '9'
    DB   '4', 'r',  'f',  'c',  '.',  'ç',  'p',  '0'
    DB   '6', 'y',  'h',  'b',  $F8,  $F7,  0x0D, 0x08
    DB   '5', 't',  'g',  'v',  ';',  '~', 	'`',  '-'
    DB   '7', 'u',  'j',  'n',  '/',  ']',  '[',  '='
    DB   '2', 'w',  's',  'z',  'm',  'k',  'i',  '8'
    
KEYMAP_SHIFT:
    DB  $1B,  $09,  $FF,  $FE,  $FD,  $FC,  $FB,  $20
    DB   '!', 'Q',  'A',  '|',  $00,  $FA,  $F6,  $F9
    DB   '#', 'E',  'D',  'X',  '<',  'L',  'O',  '('
    DB   '$', 'R',  'F',  'C',  '>',  'Ç',  'P',  ')'
    DB   '¨', 'Y',  'H',  'B',  $F8,  $F7,  0x0D, 0x08
    DB   '%', 'T',  'G',  'V',  ':',  '^', 	$22,  '_'
    DB   '&', 'U',  'J',  'N',  '?',  '}',  '{',  '+'
    DB   '@', 'W',  'S',  'Z',  'M',  'K',  'I',  '*'


INICIO:
    ; Set defult I2C device addess: 24LC256 (Copy from/to Mem)
    LD A, EEDRIVE_A
    LD (I2CA_BLOCK), A        

    ;CALL FS_CHK_SIG
    ;JP Z, INICIO1
    ;LD HL, str_notfmt
    ;CALL PUTS
INICIO1:

    LD SP, SYSTEM_SP

    LD DE, $0064 ; 100ms
    CALL H_Delay

    ;Init Serial
    CALL initSerial

    ;Init Teclado
    LD      A, 0xFF
    OUT     (KEYBOARD), A           ; Todas as colunas desativadas

    ; Init LCD
    CALL initTerminal
    CALL setGrMode
    CALL setBufNoClear


    ; Show init string
    LD BC, $0000
    CALL setCursor
    LD DE, WELLCOME_LCD
    ; set cursor ON
    LD A, 0
    LD (CURSOR_ON), A
    ; send cursor
    CALL sendStringToLCD


MAIN_LOOP:
    CALL showCurrentDriver

    CALL GETLINE             ; Lê linha em LINEBUF
    CALL PARSE_CMD           ; Interpreta e executa

    JP      MAIN_LOOP


showCurrentDriver:
    LD A, (I2CA_BLOCK)
    CP EEDRIVE_A  ; Drive A
    JR Z, showDriveA
    CP EEDRIVE_B  ; Drive B
    JR Z, showDriveB
    RET
showDriveA:
    LD A, 'A'
    CALL sendCharToLCD
    JR showCursor
showDriveB:
    LD A, 'B'
    CALL sendCharToLCD
    JR showCursor
showCursor:
    LD A, ':'
    CALL sendCharToLCD
    RET




; **********************************************************************
; Delay by DE milliseconds
;   On entry: DE = Delay time in milliseconds
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
H_Delay:    PUSH AF
            PUSH BC
            PUSH DE
; 1 ms loop, DE times...        ;[=36]   [=29]    Overhead for each 1ms
LoopDE:    LD   BC, kDelayCnt   ;[10]    [9]
; Inner loop, BC times...       ;[=26]   [=20]    Loop time in Tcycles
LoopBC:    DEC  BC             ;[6]     [4]
            LD   A,C            ;[4]     [4]
            OR   B              ;[4]     [4]
            JP   NZ,LoopBC     ;[12/7]  [8/6] 
; Have we looped once for each millisecond requested?
            DEC  DE             ;[6]     [4]
            LD   A,E            ;[4]     [4]
            OR   D              ;[4]     [4]
            JR   NZ, LoopDE     ;[12/7]  [8/6]
            POP  DE
            POP  BC
            POP  AF
            RET































#include "TECLADO.asm"
#include "GLCD.asm"
#include "SERIAL.asm"
#include "COMANDOS.asm"
#include "IHEX.asm"
#include "I2C.asm"
#include "FS.asm"
#include "API.asm"



WELLCOME: .db CR, LF, "Z80 Mini Iniciado", CR, LF, 00H
WELLCOME_LCD: .db "Z80 Mini - Monitor v1", CR, 00H


#include "MSBASIC.asm"



; RAM AREA
.ORG $F000              ;Start location

; DISPLAY GRAFICO
SBUF:   EQU 16 * $78     ;Scroll Buffer size  16 * 60 = 960 byte (10 lines), change to 20 lines (16 * 120($78))
        DS SBUF         ;Scroll Buffer space abover GBUF 
GBUF:   DS 0400H        ;Graphics Buffer 16 * 64 = 1024 byte
TGBUF:  EQU GBUF        ;Terminal GBUF
VPORT:  DW GBUF         ;View port start address
TBUF:   DW GBUF         ;Top of Buffer pointer
ENDPT:  DW 0000H        ;End Point for Line
SX:     DB 00H          ;Sign of X
SY:     DB 00H          ;Sign of Y
DX:     DW 0000H        ;Change of X
DY:     DW 0000H        ;Change of Y
ERR:    DW 0000H        ;Error Rate
RAD:    DW 0000H        ;Radius
CLRBUF: DB 00H          ;Clear Buffer Flag on LCD Displaying
CURSOR_XY: DW 0000H     ;Cursor Address X,Y
CURSOR_Y: EQU CURSOR_XY   ;Cursor Y
CURSOR_X: EQU CURSOR_XY+1 ;Cursor X
CURSOR_YS: DB 00H       ;Start Y row for new line
CURSOR_ON: DB 00H       ;Cursor on/off flag
INVERSE: DB 00H         ;Inverse Flag
PIXEL_X: DB 00H         ;Pixel X length
ULINE: DB 00H   ;Underline flag
AUTO_LF: DB 00H   ;Auto line feed flag
PLOT_ALWAYS: DB 00H   ;Plot always flag

; PORTA SERIAL
PUTCH:  DW  0000H       ; Serial
GETCH:  DW  0000H       ; Serial

; TECLADO
MEN_SHIFT: DB 00H
KEY_PRESS: DB 00H

; COMANDOS
LINEBUF:    DS 80          ; Buffer de linha de comando
HEXBUF:     DS 6           ; Buffer temporário hex
ADDR_TMP:   DW $0000       ; Endereço temporário de trabalho

; IHEX
LOAD_FIRST_FLAG:    .DB    $FF   ; FF=virgem  01=primeira linha  00=demais
LOAD_START_ADDR:    .DW    $0000 ; Endereco inicial do carregamento
LOAD_END_ADDR:      .DW    $0000 ; Endereco final do carregamento

; I2C
I2CA_BLOCK:         .DB    $00   ; I2C device addess: 24LC256 (Copy from/to Mem) dir, del, save, load
I2C_RAMCPY:         .DB    $00   ; 1 byte - RAM copy of output port
I2C_ADDR            .DB    $00   ; 1 byte - device address
I2C_RR              .DB    $00   ; 1 byte - register
I2C_DD              .DB    $00   ; 1 byte - data

; FS
FS_CUR:     .DB $00         ; 1b: entrada corrente do dir
FS_WRKBUF:  .DS $20         ; 32b: buffer entrada dir
FS_NAMBUF:  .DS $0A         ; 9b: nome digitado
FS_TMP1:    .DB $00         ; 1b: uso geral
FS_TMPSZ:   .DW $0000       ; 2b: tamanho restante
FS_TMPRAM:  .DW $0000       ; 2b: ponteiro RAM atual
FS_CURPG:   .DB $00         ; 1b: pagina corrente
FS_SLOTBK:  .DB $00         ; 1b: backup slot dir
FS_BMPADDR: .DB $00         ; 1b: endereco EEPROM do byte do bitmap
FS_INFOTMP: .DB $00         ; 1b: temp para FS_INFO (paginas livres)
; Buffer de pagina em RAM (256 bytes) - longe do codigo
PG_BUF:     .DS $FF

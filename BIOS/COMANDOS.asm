
; -------- Constantes gerais --------
CR          EQU  0DH
LF          EQU  0AH
BkS          EQU  08H
DEL         EQU  7FH
ESC         EQU  1BH
SPACE       EQU  20H
NUL         EQU  00H



; ============================================================
;  PARSE_CMD  -  Analisa LINEBUF e despacha comando
; ============================================================
PARSE_CMD:
            LD   HL, LINEBUF
            CALL SKIP_SPACES
            ; Verifica linha vazia
            LD   A, (HL)
            CP   CR
            RET  Z
            CP   NUL
            RET  Z

            ; Copia token do comando para comparação (uppercase)
            CALL UPCASE_TOKEN        ; HL aponta após token, DE=token

            ; Compara com cada comando conhecido
            LD   HL, CMD_TABLE
CMD_SCAN:
            LD   A, (HL)
            CP   NUL
            JP   Z, CMD_UNKNOWN
            ; Compara string
            PUSH HL
            LD   DE, HEXBUF          ; token gravado aqui por UPCASE_TOKEN
            CALL STRCMP
            POP  HL
            JR   Z, CMD_DISPATCH
            ; Avança para próxima entrada da tabela
            ; Formato: [str NUL] [addr 2 bytes]
SKIP_ENTRY:
            LD   A, (HL)
            INC  HL
            CP   NUL
            JR   NZ, SKIP_ENTRY
            INC  HL                  ; pula high byte do endereço
            INC  HL                  ; pula low  byte do endereço
            JP   CMD_SCAN

CMD_DISPATCH:
            ; Pula string do nome para chegar ao endereço
            LD   A, (HL)
            INC  HL
            CP   NUL
            JR   NZ, CMD_DISPATCH
            ; (HL) = low byte do handler, (HL+1) = high byte
            LD   A, (HL)
            INC  HL
            LD   H, (HL)
            LD   L, A
            ; HL = endereço do handler; HL aponta para resto da linha
            ; Precisamos salvar o ponteiro de argumento
            ; Reposiciona ponteiro de argumento
            LD   DE, LINEBUF		 ; Inicio o buffer
            CALL SKIP_COMMAND_DE	 ; pula comando e DE aponta para o primeiro espaço
            CALL SKIP_SPACES_DE      ; DE aponta para args
            JP   (HL)                ; chama handler

CMD_UNKNOWN:
            LD   HL, MSG_UNKNOWN
            CALL PUTS
            RET

; -------- Tabela de comandos --------
CMD_TABLE:
            DB   "CLS",  NUL
            DW   CLS_CMD
            DB   "DUMP", NUL
            DW   DUMP_CMD
            DB   "WRITE", NUL
            DW   LOAD_CMD
            DB   "EDIT", NUL
            DW   EDIT_CMD
            DB   "OUT",  NUL
            DW   OUT_CMD
            DB   "IN",   NUL
            DW   IN_CMD
            DB   "JUMP",    NUL
            DW   GO_CMD
            DB   "CALL",    NUL
            DW   CALL_CMD
            DB   "H",    NUL
            DW   HELP_CMD
            DB   "?",    NUL
            DW   HELP_CMD
            DB   "IHEX",    NUL
            DW   LOAD_HEX_CMD
            DB   "I2CLIST",    NUL
            DW   I2CLIST
            DB   "DIR",    NUL
            DW   FS_DIR
            DB   "EXEC",    NUL
            DW   FS_EXEC
            DB   "SAVE",    NUL
            DW   FS_SAVE
            DB   "DEL",    NUL
            DW   FS_ERASE
            DB   "FORMAT",    NUL
            DW   FS_FORMAT
            DB   "LOAD",    NUL
            DW   FS_LOAD_CMD
            DB   "BASIC",    NUL
            DW   COLD
            DB   "WBASIC",    NUL
            DW   WARM
            DB   "A:",    NUL
            DW   CHANGE_DRIVE_A
            DB   "B:",    NUL
            DW   CHANGE_DRIVE_B

            DB   NUL                 ; fim da tabela


; ============================================================
;  CHANGE_DRIVE_A  -  Altera drive para device A - EEDRIVE_A
; ============================================================
CHANGE_DRIVE_A:
    LD A, EEDRIVE_A
    LD (I2CA_BLOCK), A
    RET

; ============================================================
;  CHANGE_DRIVE_B  -  Altera drive para device B - EEDRIVE_B
; ============================================================
CHANGE_DRIVE_B:
    LD A, EEDRIVE_B
    LD (I2CA_BLOCK), A
    RET

; ============================================================
;  LOAD_HEX_CMD  -  Carrega intel hex pela porta serial
; ============================================================
LOAD_HEX_CMD;
    CALL loadInit
    RET

; ============================================================
;  CALL_8000  - Atalho - Call 8000H
; ============================================================
CALL_8000:
    LD DE, MAIN_LOOP ; endereço de retorno do CALL
    PUSH DE
    JP  $8000


; ============================================================
;  CLS_CMD  -  Limpa tela via sequência ANSI
; ============================================================
CLS_CMD:
            LD A, 0CH ; FF
            CALL sendCharToLCD
            RET

; ============================================================
;  DUMP_CMD  -  Dump hex+ASCII
;  Sintaxe: DUMP xxxx
; ============================================================
DUMP_CMD:
            ; DE aponta para argumentos
            CALL PARSE_HEX16_DE      ; HL = endereço
            JR   C, DUMP_BAD_ADDR
            LD   (ADDR_TMP), HL

            LD   B, 8               ; 8 linhas de 5 bytes

DUMP_LINE:
            PUSH BC
            ; Exibe endereço
            LD   HL, (ADDR_TMP)
            CALL PRINT_HEX16
            LD   A, ':'
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR

            ; Exibe 16 bytes hex
            LD   HL, (ADDR_TMP)
            LD   C, 5
DUMP_HEX:
            LD   A, (HL)
            CALL PRINT_HEX8
            LD   A, SPACE
            CALL PUTCHAR
            INC  HL
            DEC  C
            JR   NZ, DUMP_HEX

            ;CALL CRLF
            ; Avança endereço base
            LD   HL, (ADDR_TMP)
            LD   DE, 5
            ADD  HL, DE
            LD   (ADDR_TMP), HL
            POP  BC
            DJNZ DUMP_LINE
            RET

DUMP_BAD_ADDR:
            LD   HL, MSG_BAD_ADDR
            CALL PUTS
            RET

; ============================================================
;  LOAD_CMD  -  Carrega bytes hex em endereço
;  Sintaxe: LOAD xxxx
;  Digitar pares hex separados por espaço; linha vazia encerra
; ============================================================
LOAD_CMD:
            CALL PARSE_HEX16_DE
            JR   C, LOAD_BAD
            LD   (ADDR_TMP), HL
            LD   HL, MSG_LOAD_HINT
            CALL PUTS

LOAD_LOOP:
            ; Exibe endereço atual
            LD   HL, (ADDR_TMP)
            CALL PRINT_HEX16
            LD   A, ':'
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR

            CALL GETLINE             ; Lê linha
            LD   HL, LINEBUF
            CALL SKIP_SPACES

            ; Linha vazia = fim
            LD   A, (HL)
            CP   CR
            RET  Z
            CP   NUL
            RET  Z

            ; Processa pares hex na linha
LOAD_BYTE:
            CALL PARSE_HEX8_HL       ; A = byte, HL avança
            JR   C, LOAD_NEXT_LINE
            ; Grava byte
            LD   DE, (ADDR_TMP)
            LD   (DE), A
            INC  DE
            LD   (ADDR_TMP), DE
            CALL SKIP_SPACES_HL
            LD   A, (HL)
            CP   CR
            JR   Z, LOAD_LOOP
            CP   NUL
            JR   Z, LOAD_LOOP
            JR   LOAD_BYTE

LOAD_NEXT_LINE:
            JR   LOAD_LOOP

LOAD_BAD:
            LD   HL, MSG_BAD_ADDR
            CALL PUTS
            RET

; ============================================================
;  EDIT_CMD  -  Edita memória byte a byte
;  Sintaxe: EDIT xxxx
;  Exibe: XXXX: AA  _  (digitar novo valor ou Enter p/ manter)
;  '.' encerra
; ============================================================
EDIT_CMD:
            CALL PARSE_HEX16_DE
            JR   C, EDIT_BAD
            LD   (ADDR_TMP), HL

EDIT_LOOP:
            LD   HL, (ADDR_TMP)
            CALL PRINT_HEX16
            LD   A, ':'
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR
            LD   A, (HL)             ; Valor atual
            CALL PRINT_HEX8
            LD   A, SPACE
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR

            ; Lê até 3 chars (2 hex + CR)
            CALL GETLINE
            LD   HL, LINEBUF
            CALL SKIP_SPACES

            LD   A, (HL)
            CP   '.'                 ; '.' = sair
            RET  Z
            CP   CR
            JR   Z, EDIT_KEEP       ; Enter = mantém byte
            CP   NUL
            JR   Z, EDIT_KEEP

            ; Tenta parsear novo byte
            CALL PARSE_HEX8_HL
            JR   C, EDIT_LOOP       ; Hex inválido: repete

            ; Grava novo byte
            LD   DE, (ADDR_TMP)
            LD   (DE), A

EDIT_KEEP:
            LD   HL, (ADDR_TMP)
            INC  HL
            LD   (ADDR_TMP), HL
            JR   EDIT_LOOP

EDIT_BAD:
            LD   HL, MSG_BAD_ADDR
            CALL PUTS
            RET

; ============================================================
;  OUT_CMD  -  Escreve byte em porta de I/O
;  Sintaxe: OUT pp dd   (porta pp, dado dd, ambos em hex)
; ============================================================
OUT_CMD:
            ; DE → argumentos
            CALL PARSE_HEX8_DE       ; A = número da porta
            JR   C, OUT_BAD
            LD   C, A                ; C = porta

            CALL SKIP_SPACES_DE
            CALL PARSE_HEX8_DE       ; A = dado
            JR   C, OUT_BAD

            ; OUT (C), A
            OUT  (C), A
            LD   HL, MSG_OK
            CALL PUTS
            RET

OUT_BAD:
            LD   HL, MSG_SYNTAX
            CALL PUTS
            RET

; ============================================================
;  IN_CMD  -  Lê byte de porta de I/O
;  Sintaxe: IN pp
; ============================================================
IN_CMD:
            CALL PARSE_HEX8_DE
            JR   C, IN_BAD
            LD   C, A
            IN   A, (C)
            CALL PRINT_HEX8
            CALL CRLF
            RET

IN_BAD:
            LD   HL, MSG_SYNTAX
            CALL PUTS
            RET

; ============================================================
;  GO_CMD  -  Executa código a partir de endereço
;  Sintaxe: G xxxx
; ============================================================
GO_CMD:
            CALL PARSE_HEX16_DE
            JR   C, GO_BAD
            JP   (HL)                ; Salta para endereço

GO_BAD:
            LD   HL, MSG_BAD_ADDR
            CALL PUTS
            RET


; ============================================================
;  CALL_CMD  -  Executa código a partir de endereço
;  Sintaxe: CALL xxxx
; ============================================================
CALL_CMD:
            CALL PARSE_HEX16_DE
            JR   C, CALL_BAD
            LD DE, MAIN_LOOP ; endereço de retorno do CALL
            PUSH DE
            JP   (HL)                ; Salta para endereço

CALL_BAD:
            LD   HL, MSG_BAD_ADDR
            CALL PUTS
            RET


; ============================================================
;  HELP_CMD  -  Exibe ajuda
; ============================================================
HELP_CMD:
            LD   DE, MSG_HELP_L0
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L1
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L2
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L3
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L4
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L5
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L6
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L7
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L8
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L9
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L10
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L11
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L12
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L13
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L14
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L15
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L16
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L17
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L18
            CALL sendStringToLCD
            RET


LCD_SCROLL:
    CALL PUTCHAR
    JR GETLINE_LOOP


; --- GETLINE: Lê linha para LINEBUF; eco local ---
;     Termina em CR. Suporta BS/DEL para apagar.
GETLINE:
            LD   HL, LINEBUF
            LD   B, 79               ; Máx 79 chars + NUL
GETLINE_LOOP:
            CALL CONIN
            CP   CR
            JR   Z, GETLINE_DONE
            CP   $F8    ; ignora scroll up - GLCD
            JR   Z, LCD_SCROLL
            CP   $F7    ; ignora scroll down - GLCD
            JR   Z, LCD_SCROLL
            CP   LF
            JR   Z, GETLINE_LOOP    ; Ignora LF
            CP   BkS
            JR   Z, GETLINE_BS
            CP   DEL
            JR   Z, GETLINE_BS
            CP   $FA ; AltGr
            JP   Z, CALL_IHEX
            CP   $F9 ; LUZ
            JP   Z, CALL_8000
            LD   C, A
            LD   A, B
            CP   0
            JR   Z, GETLINE_LOOP    ; Buffer cheio
            LD   A, C
            LD   (HL), A
            INC  HL
            DEC  B
            CALL PUTCHAR             ; Eco
            JR   GETLINE_LOOP
GETLINE_BS:
            LD   A, B
            CP   79
            JR   Z, GETLINE_LOOP    ; Início: ignora BS
            DEC  HL
            INC  B
            LD   A, BkS
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR
            LD   A, BkS
            CALL PUTCHAR
            JR   GETLINE_LOOP
GETLINE_DONE:
            LD   (HL), NUL           ; Termina string
            CALL CRLF
            RET

; ============================================================
;  SUBROTINAS DE PARSE
; ============================================================
; --- SKIP_COMMAND_DE: Avança DE até o proximo espaço ---
SKIP_COMMAND_DE:
			LD A, (DE)
			CP SPACE
			RET Z
			INC DE
			JR SKIP_COMMAND_DE


; --- SKIP_SPACES: Avança HL sobre espaços ---
SKIP_SPACES:
            LD   A, (HL)
            CP   SPACE
            RET  NZ
            INC  HL
            JR   SKIP_SPACES

; --- SKIP_SPACES_DE: Avança DE sobre espaços ---
SKIP_SPACES_DE:
            LD   A, (DE)
            CP   SPACE
            RET  NZ
            INC  DE
            JR   SKIP_SPACES_DE

; --- SKIP_SPACES_HL: Avança HL sobre espaços ---
SKIP_SPACES_HL:
            LD   A, (HL)
            CP   SPACE
            RET  NZ
            INC  HL
            JR   SKIP_SPACES_HL

; --- IS_HEX: testa se A é dígito hex; retorna dígito em A (0-15), CY se inválido ---
IS_HEX:
            CP   '0'
            JR   C, IS_HEX_BAD
            CP   '9'+1
            JR   C, IS_HEX_DIG      ; '0'-'9'
            AND  0DFH               ; Uppercase
            CP   'A'
            JR   C, IS_HEX_BAD
            CP   'F'+1
            JR   NC, IS_HEX_BAD
            SUB  'A'-10             ; 'A'→10 ... 'F'→15
            RET
IS_HEX_DIG:
            SUB  '0'
            RET
IS_HEX_BAD:
            SCF
            RET

; --- PARSE_HEX8_HL: parseia 2 dígitos hex em (HL), resultado em A; HL avança 2 ---
;     Carry = erro
PARSE_HEX8_HL:
            LD   A, (HL)
            CALL IS_HEX
            RET  C
            RRCA
            RRCA
            RRCA
            RRCA
            AND  0F0H
            LD   B, A
            INC  HL
            LD   A, (HL)
            CALL IS_HEX
            JR   C, PHX8_ERR
            OR   B
            INC  HL
            RET
PHX8_ERR:
            DEC  HL
            SCF
            RET

; --- PARSE_HEX8_DE: igual mas com DE ---
PARSE_HEX8_DE:
            LD   A, (DE)
            CALL IS_HEX
            RET  C
            RRCA
            RRCA
            RRCA
            RRCA
            AND  0F0H
            LD   B, A
            INC  DE
            LD   A, (DE)
            CALL IS_HEX
            JR   C, PHX8D_ERR
            OR   B
            INC  DE
            RET
PHX8D_ERR:
            DEC  DE
            SCF
            RET

; --- PARSE_HEX16_DE: parseia 4 dígitos hex em (DE), resultado em HL; DE avança 4 ---
PARSE_HEX16_DE:
            CALL PARSE_HEX8_DE
            RET  C
            LD   H, A
            CALL PARSE_HEX8_DE
            RET  C
            LD   L, A
            RET

; --- UPCASE_TOKEN: copia token de (HL) em maiúscula para HEXBUF; HL avança após token ---
UPCASE_TOKEN:
            LD   DE, HEXBUF
            LD   B, 10
UPCASE_LOOP:
            LD   A, (HL)
            CP   SPACE
            JR   Z, UPCASE_DONE
            CP   CR
            JR   Z, UPCASE_DONE
            CP   NUL
            JR   Z, UPCASE_DONE
            CP   'a'
            JR   C, UPCASE_STORE
            CP   'z'+1
            JR   NC, UPCASE_STORE
            AND  0DFH               ; Converte para maiúscula
UPCASE_STORE:
            LD   (DE), A
            INC  HL
            INC  DE
            DJNZ UPCASE_LOOP
UPCASE_DONE:
            LD   A, NUL
            LD   (DE), A
            RET

; --- STRCMP: compara (HL) com (DE), Z=1 se iguais ---
STRCMP:
            LD   A, (HL)
            LD   B, A
            LD   A, (DE)
            CP   B
            RET  NZ
            CP   NUL
            RET  Z
            INC  HL
            INC  DE
            JR   STRCMP

; ============================================================
;  SUBROTINAS DE SAÍDA HEX
; ============================================================

; --- PRINT_HEX8: Imprime byte em A como 2 dígitos hex ---
PRINT_HEX8:
            PUSH AF
            RRCA
            RRCA
            RRCA
            RRCA
            CALL PRINT_NIBBLE
            POP  AF
            CALL PRINT_NIBBLE
            RET

PRINT_NIBBLE:
            AND  0FH
            ADD  A, '0'
            CP   '9'+1
            JR   C, PN_DONE
            ADD  A, 07H              ; 'A'-'9'-1
PN_DONE:
            CALL PUTCHAR
            RET

; --- PRINT_HEX16: Imprime HL como 4 dígitos hex ---
PRINT_HEX16:
            LD   A, H
            CALL PRINT_HEX8
            LD   A, L
            CALL PRINT_HEX8
            RET

; ============================================================
;  STRINGS
; ============================================================

MSG_PROMPT:
            DB   CR, LF, "> ", NUL

MSG_UNKNOWN:
            DB   "Comando desconhecido. Digite H.", CR, NUL

MSG_BAD_ADDR:
            DB   "Endereco invalido.", CR, NUL

MSG_SYNTAX:
            DB   "Erro de sintaxe.", CR, NUL

MSG_OK:
            DB   "OK", CR, NUL

MSG_LOAD_HINT:
            DB   "Digite bytes hex por linha. Linha vazia para encerrar.", CR, NUL

MSG_HELP_L0:    DB   "Comandos:", CR
MSG_HELP_L1:    DB   " H / ?", CR
MSG_HELP_L2:    DB   " CLS", CR
MSG_HELP_L3:    DB   " DUMP xxxx", CR
MSG_HELP_L4:    DB   " WRITE xxxx", CR
MSG_HELP_L5:    DB   " EDIT xxxx", CR
MSG_HELP_L6:    DB   " OUT pp dd", CR
MSG_HELP_L7:    DB   " IN  pp", CR
MSG_HELP_L8:    DB   " JUMP xxxx", CR
MSG_HELP_L9:    DB   " CALL xxxx", CR
MSG_HELP_L10:   DB   " . (no EDIT)", CR
MSG_HELP_L11:   DB   " IHEX - Load Serial", CR
MSG_HELP_L12:   DB   " I2CLIST - List Devs", CR
MSG_HELP_L13:   DB   " DIR - List files", CR
MSG_HELP_L14:   DB   " EXEC - Exec file", CR
MSG_HELP_L15:   DB   " SAVE - Save file", CR
MSG_HELP_L16:   DB   " DEL - Delete file", CR
MSG_HELP_L17:   DB   " FORMAT - Format eeprom", CR
MSG_HELP_L18:   DB   " LOAD - Load file", CR
MSG_HELP_L19:   DB   " BASIC - Cold basic", CR
MSG_HELP_L20:   DB   " WBASIC - Warm basic", CR


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
            DB   "G",    NUL
            DW   GO_CMD
            DB   "CALL",    NUL
            DW   CALL_CMD
            DB   "C",    NUL
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
            DB   "RUN",    NUL
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
            DB   "C:",    NUL
            DW   CHANGE_DRIVE_C
            DB   "D:",    NUL
            DW   CHANGE_DRIVE_D
            DB   "E:",    NUL
            DW   CHANGE_DRIVE_E
            DB   "F:",    NUL
            DW   CHANGE_DRIVE_F
            DB   "G:",    NUL
            DW   CHANGE_DRIVE_G
            DB   "Z:",    NUL
            DW   CHANGE_DRIVE_Z
            DB   "I2C", NUL
            DW   I2C_CMD
            DB   "MKDIR", NUL
            DW   FS_MKDIR
            DB   "RMDIR", NUL
            DW   FS_RMDIR
            DB   "CD", NUL
            DW   FS_CD
            DB   "FDISK", NUL
            DW   FS_INFO

            DB   NUL                 ; fim da tabela





; ============================================================
;  CHANGE_DRIVE_A  -  Altera drive para device A - EEDRIVE_A
; ============================================================
CHANGE_DRIVE_A:
    LD A, EEDRIVE_A
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_B  -  Altera drive para device B - EEDRIVE_B
; ============================================================
CHANGE_DRIVE_B:
    LD A, EEDRIVE_B
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_C  -  Altera drive para device C - EEDRIVE_C
; ============================================================
CHANGE_DRIVE_C:
    LD A, EEDRIVE_C
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_D  -  Altera drive para device D - EEDRIVE_D
; ============================================================
CHANGE_DRIVE_D:
    LD A, EEDRIVE_D
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_E  -  Altera drive para device E - EEDRIVE_E
; ============================================================
CHANGE_DRIVE_E:
    LD A, EEDRIVE_E
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_F  -  Altera drive para device F - EEDRIVE_F
; ============================================================
CHANGE_DRIVE_F:
    LD A, EEDRIVE_F
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET

; ============================================================
;  CHANGE_DRIVE_G  -  Altera drive para device G - EEDRIVE_G
; ============================================================
CHANGE_DRIVE_G:
    LD A, EEDRIVE_G
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
    RET


; ============================================================
;  CHANGE_DRIVE_Z  -  Altera drive para device Z - EEDRIVE_Z
; ============================================================
CHANGE_DRIVE_Z:
    LD A, EEDRIVE_Z
    LD (I2CA_BLOCK), A
    CALL CHECK_DISK_FORMAT
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

            LD   DE, MSG_HELP_L19
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L20
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L21
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L22
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L23
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L24
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L25
            CALL sendStringToLCD

            LD   DE, MSG_HELP_L26
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
            CP   ESC
            JR   Z, GETLINE_LOOP    ; Ignora
            CP   $FF ;capslock Ignora
            JP   Z, GETLINE_LOOP
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
            ;LD   A, SPACE
            ;CALL PUTCHAR
            ;LD   A, BkS
            ;CALL PUTCHAR
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
; I2C_CMD - Testes rapidos no barramento I2C
;
; Sintaxe: I2C aa [Wdd] [Rnn] [Wdd] [Rnn] ...
;   aa  = endereco do device, 7 bits, hex, SEM o bit R/W
;   Wdd = escreve o byte dd (hex)
;   Rnn = le nn bytes (hex) e imprime cada um em hex
;
; Exemplos:
;   I2C 20 WFF           -> PCF8574: open(write), write FF, close
;   I2C 50 W10 W20 R04    -> EEPROM : open(write), write 10, write 20,
;                             open(read, repeated start), read 4, close
;
; O comando reabre o device (I2C_Open de novo, sem fechar antes) toda
; vez que a direcao muda de W para R ou de R para W - isso gera um
; repeated start, igual o I2C_MemRd ja faz internamente.
;
; Dentro de um bloco Rnn, todo byte manda ACK pro slave, exceto o
; ultimo, que manda NACK (fim da leitura) - mesma logica do I2C_MemRd.
;
; No primeiro NACK (falha de escrita/open), a sequencia e abortada,
; o barramento e fechado (STOP) para nao ficar travado, e uma
; mensagem de erro e impressa.
;
; Requer de I2C.asm: I2C_Open, I2C_Write, I2C_Read, I2C_Close
; ============================================================

I2C_CMD:
    ; DE -> argumentos (endereco DEc apos "I2C ")
    CALL PARSE_HEX8_DE     ; A = endereco do device (7 bits)
    JP  C, I2C_BAD_SYNTAX
    LD  (I2C_ADDR7), A
    XOR A
    LD  (I2C_STATE), A     ; 0 = fechado

I2C_LOOP:
    CALL SKIP_SPACES_DE
    LD  A, (DE)
    CP  CR
    JP  Z, I2C_DONE
    CP  NUL
    JP  Z, I2C_DONE

    ; Le o operador (W ou R)
    LD  A, (DE)
    AND 0DFH                ; forca maiuscula
    INC DE
    CP  'W'
    JR  Z, I2C_DO_WRITE
    CP  'R'
    JR  Z, I2C_DO_READ
    JP  I2C_BAD_SYNTAX

; -------- WRITE --------
I2C_DO_WRITE:
    CALL PARSE_HEX8_DE      ; A = byte a escrever
    JP  C, I2C_BAD_SYNTAX
    LD  C, A                ; guarda o byte

    LD  A, (I2C_STATE)
    CP  1
    JR  Z, I2C_WRITE_GO      ; ja aberto em modo write

    LD  A, (I2C_ADDR7)
    RLCA                     ; addr << 1
    AND 0FEH                 ; bit0 = 0 (write)
    CALL I2C_Open
    JR  NZ, I2C_NOACK
    LD  A, 1
    LD  (I2C_STATE), A

I2C_WRITE_GO:
    LD  A, C
    CALL I2C_Write
    JR  NZ, I2C_NOACK
    JR  I2C_LOOP

; -------- READ --------
I2C_DO_READ:
    CALL PARSE_HEX8_DE       ; A = quantidade de bytes a ler
    JR  C, I2C_BAD_SYNTAX
    LD  B, A
    LD  A, B
    OR  A
    JR  Z, I2C_LOOP           ; R00 = nada a fazer

    LD  A, (I2C_STATE)
    CP  2
    JR  Z, I2C_READ_GO         ; ja aberto em modo read

    LD  A, (I2C_ADDR7)
    RLCA
    OR  01H                    ; bit0 = 1 (read)
    CALL I2C_Open
    JR  NZ, I2C_NOACK
    LD  A, 2
    LD  (I2C_STATE), A

I2C_READ_GO:
    LD  A, B
    CP  1
    JR  Z, I2C_READ_LASTBYTE
    LD  A, 0FFH                 ; ACK - ainda tem mais bytes
    JR  I2C_READ_DOIT
I2C_READ_LASTBYTE:
    XOR A                        ; NACK - ultimo byte do bloco
I2C_READ_DOIT:
    CALL I2C_Read                ; A = byte lido
    PUSH BC
    CALL PRINT_HEX8
    LD  A, SPACE
    CALL PUTCHAR
    POP BC
    DEC B
    LD  A, B
    OR  A
    JR  NZ, I2C_READ_GO
    JP  I2C_LOOP

; -------- Erro / fim --------
I2C_NOACK:
    PUSH AF
    CALL I2C_Close               ; garante que o barramento nao trava
    XOR A
    LD  (I2C_STATE), A
    POP AF
    LD  HL, MSG_I2C_NOACK
    CALL PUTS
    RET

I2C_DONE:
    LD  A, (I2C_STATE)
    OR  A
    JR  Z, I2C_OK
    CALL I2C_Close
    XOR A
    LD  (I2C_STATE), A
I2C_OK:
    LD  HL, MSG_OK
    CALL PUTS
    RET

I2C_BAD_SYNTAX:
    LD  HL, MSG_SYNTAX
    CALL PUTS
    RET
















; ============================================================
;  STRINGS
; ============================================================

MSG_I2C_NOACK:
    DB "I2C: sem ACK do device.", CR, NUL

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
MSG_HELP_L8:    DB   " G/JUMP xxxx", CR
MSG_HELP_L9:    DB   " C/CALL xxxx", CR
MSG_HELP_L10:   DB   " . (no EDIT)", CR
MSG_HELP_L11:   DB   " IHEX - Load Serial", CR
MSG_HELP_L12:   DB   " I2CLIST - List Devs", CR
MSG_HELP_L13:   DB   " DIR - List files", CR
MSG_HELP_L14:   DB   " RUN - Exec file", CR
MSG_HELP_L15:   DB   " SAVE - Save file", CR
MSG_HELP_L16:   DB   " DEL - Delete file", CR
MSG_HELP_L17:   DB   " FORMAT - Format eeprom", CR
MSG_HELP_L18:   DB   " LOAD - Load file", CR
MSG_HELP_L19:   DB   " BASIC - Cold basic", CR
MSG_HELP_L20:   DB   " WBASIC - Warm basic", CR
MSG_HELP_L21:   DB   " I2C aa [Wdd][Rnn]..", CR
MSG_HELP_L22:   DB   " MKDIR folderName", CR
MSG_HELP_L23:   DB   " RMDIR folderName", CR
MSG_HELP_L24:   DB   " CD folderName", CR
MSG_HELP_L25:   DB   " CD ~  Back to Home", CR
MSG_HELP_L26:   DB   " FDISK InfoDsk I2C", CR
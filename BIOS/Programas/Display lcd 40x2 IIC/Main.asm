#include "../Z80MiniAPI.asm"

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

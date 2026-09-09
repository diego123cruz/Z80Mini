#include "../Z80MiniAPI.asm"
; ============================================================
;  SSD1309_TEXT.asm - Driver SSD1309 (128x64) + texto na tela
;                      "Z80Mini", Z80Mini, SPI bit-bang
;
;  Porta $C0 (saida):
;     bit0 = SCK
;     bit1 = MOSI
;     bit2 = CS    (ativo em nivel baixo)
;     bit3 = DC    (0 = comando, 1 = dado)
;     bit4 = RES   (ativo em nivel baixo)
;
;  Montar:  zasm --z80 -w -u --bin SSD1309_TEXT.asm
;  Rodar:   G 8000
; ============================================================

        org     $8000

PORT_OUT    equ $C0

BIT_SCK     equ 0
BIT_MOSI    equ 1
BIT_CS      equ 2
BIT_DC      equ 3
BIT_RES     equ 4

M_SCK       equ (1 << BIT_SCK)
M_MOSI      equ (1 << BIT_MOSI)
M_CS        equ (1 << BIT_CS)
M_DC        equ (1 << BIT_DC)
M_RES       equ (1 << BIT_RES)

; ------------------------------------------------------------
; PONTO DE ENTRADA
; ------------------------------------------------------------
START:
        call    OLED_RESET
        call    OLED_INIT
        call    OLED_CLEAR

        ld      hl, MSG
        ld      d, 3            ; pagina 3 (meio da tela, linhas 24-31)
        ld      e, 44           ; coluna inicial (centraliza ~7 chars x 6px=42)
        call    OLED_DRAWSTR
        ret

MSG:    db      "Z80Mini", 0

; ------------------------------------------------------------
; OLED_RESET
; ------------------------------------------------------------
OLED_RESET:
        ld      a, M_CS | M_RES
        ld      (SHADOW), a
        out     (PORT_OUT), a
        call    DELAY_MS1

        ld      a, (SHADOW)
        and     $FF ^ M_RES
        ld      (SHADOW), a
        out     (PORT_OUT), a
        call    DELAY_MS1

        ld      a, (SHADOW)
        or      M_RES
        ld      (SHADOW), a
        out     (PORT_OUT), a
        call    DELAY_MS1
        ret

; ------------------------------------------------------------
; OLED_INIT
; ------------------------------------------------------------
OLED_INIT:
        ld      hl, INIT_SEQ
INIT_LOOP:
        ld      a, (hl)
        cp      $FF
        ret     z
        call    OLED_CMD
        inc     hl
        jr      INIT_LOOP

INIT_SEQ:
        db      $AE
        db      $D5, $A0
        db      $A8, $3F
        db      $D3, $00
        db      $40
        db      $A1
        db      $C8
        db      $DA, $12
        db      $81, $DF
        db      $D9, $82
        db      $DB, $34
        db      $A4
        db      $A6
        db      $AF
        db      $FF

; ------------------------------------------------------------
; OLED_CLEAR - zera as 8 paginas x 128 colunas
; ------------------------------------------------------------
OLED_CLEAR:
        ld      b, 8
        ld      c, 0
CLR_PAGE:
        push    bc
        ld      a, c
        ld      e, 0
        call    OLED_SET_POS
        ld      b, 128
CLR_COL:
        push    bc
        xor     a
        call    OLED_DATA
        pop     bc
        djnz    CLR_COL
        pop     bc
        inc     c
        djnz    CLR_PAGE
        ret

; ------------------------------------------------------------
; OLED_SET_POS - posiciona pagina e coluna
; entrada: A = pagina (0-7), E = coluna (0-127)
; ------------------------------------------------------------
OLED_SET_POS:
        push    af
        or      $B0                     ; set page
        call    OLED_CMD
        ld      a, e
        and     $0F                     ; column low nibble
        call    OLED_CMD
        ld      a, e
        rrca
        rrca
        rrca
        rrca
        and     $0F
        or      $10                     ; column high nibble
        call    OLED_CMD
        pop     af
        ret

; ------------------------------------------------------------
; OLED_DRAWSTR - desenha string terminada em 0
; entrada: HL = ponteiro string, D = pagina, E = coluna inicial
; ------------------------------------------------------------
OLED_DRAWSTR:
        ld      a, (hl)
        or      a
        ret     z
        push    hl
        call    OLED_DRAWCHAR
        pop     hl
        inc     hl
        ld      a, e
        add     a, 6                    ; 5 colunas de glifo + 1 de espaco
        ld      e, a
        jr      OLED_DRAWSTR

; ------------------------------------------------------------
; OLED_DRAWCHAR - desenha um caractere (5x7) na posicao D,E
; entrada: A = caractere, D = pagina, E = coluna
; ------------------------------------------------------------
OLED_DRAWCHAR:
        push    de
        call    GET_GLYPH               ; retorna HL = ponteiro p/ 5 bytes
        pop     de
        push    hl
        ld      a, d
        call    OLED_SET_POS
        pop     hl

        ld      b, 5
DC_LOOP:
        ld      a, (hl)
        call    OLED_DATA
        inc     hl
        djnz    DC_LOOP

        ld      a, 0
        call    OLED_DATA               ; coluna de espaco entre caracteres
        ret

; ------------------------------------------------------------
; GET_GLYPH - busca glifo do caractere em A na FONT_TABLE
; saida: HL = ponteiro para 5 bytes do glifo (BLANK se nao achar)
; ------------------------------------------------------------
GET_GLYPH:
        push    af
        ld      hl, FONT_TABLE
GG_LOOP:
        ld      a, (hl)
        cp      $FF
        jr      z, GG_NOTFOUND
        pop     af
        push    af
        cp      (hl)
        jr      z, GG_FOUND
        ld      de, 6
        add     hl, de
        jr      GG_LOOP
GG_FOUND:
        inc     hl
        pop     af
        ret
GG_NOTFOUND:
        pop     af
        ld      hl, BLANK_GLYPH
        ret

; Fonte 5x7, formato coluna (bit0 = topo, bit6 = base), 1 byte por coluna
FONT_TABLE:
        db      'Z', $61, $51, $49, $45, $43
        db      '8', $36, $49, $49, $49, $36
        db      '0', $3E, $51, $49, $45, $3E
        db      'M', $7F, $02, $0C, $02, $7F
        db      'i', $00, $44, $7D, $40, $00
        db      'n', $7C, $08, $04, $04, $78
        db      $FF

BLANK_GLYPH:
        db      $00, $00, $00, $00, $00

; ------------------------------------------------------------
; OLED_CMD / OLED_DATA / SPI_SEND
; ------------------------------------------------------------
OLED_CMD:
        push    af
        ld      a, (SHADOW)
        and     $FF ^ M_DC
        ld      (SHADOW), a
        out     (PORT_OUT), a
        pop     af
        call    SPI_SEND
        ret

OLED_DATA:
        push    af
        ld      a, (SHADOW)
        or      M_DC
        ld      (SHADOW), a
        out     (PORT_OUT), a
        pop     af
        call    SPI_SEND
        ret

SPI_SEND:
        push    bc
        ld      c, a

        ld      a, (SHADOW)
        and     $FF ^ M_CS
        ld      (SHADOW), a
        out     (PORT_OUT), a

        ld      b, 8
SPI_BITLOOP:
        ld      a, (SHADOW)
        and     $FF ^ (M_MOSI | M_SCK)
        rlc     c
        jr      nc, SPI_BIT0
        or      M_MOSI
SPI_BIT0:
        ld      (SHADOW), a
        out     (PORT_OUT), a

        or      M_SCK
        ld      (SHADOW), a
        out     (PORT_OUT), a

        djnz    SPI_BITLOOP

        ld      a, (SHADOW)
        and     $FF ^ M_SCK
        or      M_CS
        ld      (SHADOW), a
        out     (PORT_OUT), a

        pop     bc
        ret

; ------------------------------------------------------------
; DELAY_MS1
; ------------------------------------------------------------
DELAY_MS1:
        push    bc
        ld      bc, 1200
DLY_LOOP:
        dec     bc
        ld      a, b
        or      c
        jr      nz, DLY_LOOP
        pop     bc
        ret

; ------------------------------------------------------------
; VARIAVEIS
; ------------------------------------------------------------
SHADOW: db      0

        end

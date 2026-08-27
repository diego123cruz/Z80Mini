#include "../Z80MiniAPI.asm"

; ============================================================
; MAX7219.asm — Driver para modulo(s) MAX7219 (matriz LED 8x8)
; Z80Mini — porta de saida 0xC0, bit-bang SPI
; Compilar:  zasm --z80 -w -u --bin MAX7219.asm
; Executar:  G 8000
;
; Pinagem assumida no byte de saida (porta 0xC0):
;   bit0 = DIN   (dado serial)
;   bit1 = CLK   (clock)
;   bit2 = CS/LD (ativo baixo durante envio, pulso alto = latch)
; ============================================================

    org 8000h

; ---- porta e mascaras de bits ----
PORT_MAX    equ $C0

BIT_DIN     equ 00000001b
BIT_CLK     equ 00000010b
BIT_CS      equ 00000100b

; ---- registradores do MAX7219 ----
REG_NOOP    equ $00
REG_DIG0    equ $01      ; digitos/linhas 1-8 = 01h..08h
REG_DECODE  equ $09
REG_INTENS  equ $0A
REG_SCANLIM equ $0B
REG_SHUTDN  equ $0C
REG_DISPTST equ $0F

; ---- numero de modulos em cascata (1 = so um modulo) ----
NUM_MODULES equ 1

; ============================================================
; PONTO DE ENTRADA — demo padrao: inicializa e desenha um "X"
; ============================================================
START:
    call MAX_INIT
    call MAX_CLEAR
    
    ;ld   hl,PATTERN_X
    ;call MAX_DRAW
    JP DEMO_SCROLL
    ret

; demos alternativas (chame na monitor com G <endereco> se quiser
; testar uma coisa de cada vez em vez do START completo):
;   DEMO_BRIGHT_LOOP  -> varre o brilho de 0 a 15 e volta
;   DEMO_SLEEP_WAKE   -> pisca o display via shutdown/wake
;   DEMO_TEST         -> acende tudo via modo de teste do chip
;   DEMO_MIRROR       -> desenha o X e mostra o espelho horizontal
;   DEMO_ROTATE       -> desenha o X e mostra rotacionado 90 graus
;   DEMO_SCROLL       -> faz scroll da mensagem "OI"

; ============================================================
; MAX_INIT — sequencia de inicializacao do MAX7219
; ============================================================
MAX_INIT:
    xor  a
    ld   (SHADOW_PORT),a       ; estado inicial do latch: tudo em 0

    ld   b,REG_SHUTDN
    ld   c,01h                 ; sai do modo shutdown (liga o chip)
    call MAX_SEND

    ld   b,REG_DECODE
    ld   c, $00                 ; sem decode BCD — modo matriz de LED
    call MAX_SEND

    ld   b,REG_SCANLIM
    ld   c, $07                 ; varre os 8 digitos (linhas)
    call MAX_SEND

    ld   b,REG_INTENS
    ld   c, $08                 ; brilho medio (00h..0Fh)
    call MAX_SEND

    ld   b,REG_DISPTST
    ld   c, $00                 ; desliga modo de teste
    call MAX_SEND
    ret

; ============================================================
; MAX_CLEAR — apaga todas as 8 linhas
; ============================================================
MAX_CLEAR:
    ld   b,REG_DIG0
    ld   e,8
MAX_CLEAR_LOOP:
    push bc
    ld   c,$00
    call MAX_SEND
    pop  bc
    inc  b
    dec  e
    jr   nz,MAX_CLEAR_LOOP
    ret

; ============================================================
; MAX_DRAW — desenha um padrao de 8 bytes (um por linha)
; entrada: HL = ponteiro para buffer de 8 bytes (linha 1..8)
; ============================================================
MAX_DRAW:
    ld   b,REG_DIG0
    ld   e,8
MAX_DRAW_LOOP:
    push bc
    push hl
    ld   a,(hl)
    ld   c,a
    call MAX_SEND
    pop  hl
    pop  bc
    inc  hl
    inc  b
    dec  e
    jr   nz,MAX_DRAW_LOOP
    ret

; ============================================================
; MAX_SEND — envia um frame de 16 bits (registrador+dado)
; para UM modulo (uso normal, NUM_MODULES=1)
; entrada: B = numero do registrador, C = dado
; ============================================================
MAX_SEND:
    ld   a,(SHADOW_PORT)
    and  ~BIT_CS & $FF
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a

    ld   a,b
    call MAX_SENDBYTE

    ld   a,c
    call MAX_SENDBYTE

    ld   a,(SHADOW_PORT)
    or   BIT_CS
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a
    ret

; ------------------------------------------------------------
; MAX_SENDBYTE — envia byte em A, MSB primeiro
; ------------------------------------------------------------
MAX_SENDBYTE:
    ld   d,8
MAX_SENDBYTE_LOOP:
    rlca                       ; bit mais significativo vai para carry
    push af                    ; guarda o byte sendo deslocado (e o carry)
    ld   a,(SHADOW_PORT)       ; LD nao mexe nas flags -> carry preservado
    jr   c,MAX_SB_SETBIT
    and  ~BIT_DIN & $FF        ; bit=0 -> zera DIN
    jr   MAX_SB_CLKLOW
MAX_SB_SETBIT:
    or   BIT_DIN                ; bit=1 -> seta DIN
MAX_SB_CLKLOW:
    and  ~BIT_CLK & $FF         ; CLK baixo (mascara nao afeta o bit DIN)
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a

    or   BIT_CLK                ; CLK alto -> MAX7219 amostra o bit
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a

    pop  af
    dec  d
    jr   nz,MAX_SENDBYTE_LOOP
    ret

; ============================================================
; BRILHO / SHUTDOWN / MODO TESTE
; ============================================================

; MAX_SET_BRIGHT — ajusta o brilho
; entrada: A = 0 (minimo) a 15 (maximo)
MAX_SET_BRIGHT:
    ld   c,a
    ld   b,REG_INTENS
    call MAX_SEND
    ret

; MAX_SLEEP — desliga o display (baixo consumo, mantem conteudo)
MAX_SLEEP:
    ld   b,REG_SHUTDN
    ld   c,$00
    call MAX_SEND
    ret

; MAX_WAKE — religa o display (volta a mostrar o que tinha antes)
MAX_WAKE:
    ld   b,REG_SHUTDN
    ld   c,$01
    call MAX_SEND
    ret

; MAX_TEST_ON — acende todos os LEDs no brilho maximo (ignora o buffer)
; util para checar solda/fiacao
MAX_TEST_ON:
    ld   b,REG_DISPTST
    ld   c,$01
    call MAX_SEND
    ret

; MAX_TEST_OFF — volta ao funcionamento normal
MAX_TEST_OFF:
    ld   b,REG_DISPTST
    ld   c,$00
    call MAX_SEND
    ret

; ============================================================
; CASCATA DE MODULOS (para quando NUM_MODULES > 1)
; ============================================================

; MAX_SEND_ALL — manda o MESMO registrador+dado para todos os modulos
; da cadeia de uma vez (bom para comandos de init: decode, scan limit,
; intensidade, shutdown, etc.)
; entrada: B = registrador, C = dado
MAX_SEND_ALL:
    ld   a,(SHADOW_PORT)
    and  ~BIT_CS & $FF
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a

    ld   e,NUM_MODULES
SEND_ALL_LOOP:
    push bc
    push de
    ld   a,b
    call MAX_SENDBYTE
    ld   a,c
    call MAX_SENDBYTE
    pop  de
    pop  bc
    dec  e
    jr   nz,SEND_ALL_LOOP

    ld   a,(SHADOW_PORT)
    or   BIT_CS
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a
    ret

; MAX_SEND_ROW_CASCADE — manda o MESMO registrador (ex: uma linha)
; com um dado DIFERENTE para cada modulo da cadeia
; entrada: B = registrador, HL = ponteiro para NUM_MODULES bytes de dado
;          HL[0] = dado do ultimo modulo da cadeia (mais distante do Z80)
;          HL[NUM_MODULES-1] = dado do primeiro modulo (mais perto do Z80)
MAX_SEND_ROW_CASCADE:
    push bc
    ld   a,(SHADOW_PORT)
    and  ~BIT_CS & $FF
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a
    pop  bc

    ld   d,NUM_MODULES
CASCADE_LOOP:
    push bc
    push de
    push hl
    ld   a,b
    call MAX_SENDBYTE
    ld   a,(hl)
    call MAX_SENDBYTE
    pop  hl
    inc  hl
    pop  de
    pop  bc
    dec  d
    jr   nz,CASCADE_LOOP

    ld   a,(SHADOW_PORT)
    or   BIT_CS
    ld   (SHADOW_PORT),a
    out  (PORT_MAX),a
    ret

; ============================================================
; BIT_MASKS / GET_BIT / SET_BIT_C — helpers usados por
; espelhamento, rotacao e scroll
; ============================================================

BITMASKS:
    defb 00000001b,00000010b,00000100b,00001000b
    defb 00010000b,00100000b,01000000b,10000000b

; GET_BIT — entrada: A=byte, B=posicao do bit (0..7, 0=LSB)
;           saida: carry = valor do bit; A destruido
GET_BIT:
    push hl
    push de
    push af
    ld   hl,BITMASKS
    ld   d,0
    ld   e,b
    add  hl,de
    ld   d,(hl)
    pop  af
    and  d
    pop  de
    pop  hl
    jr   z,GET_BIT_ZERO
    scf
    ret
GET_BIT_ZERO:
    or   a
    ret

; SET_BIT_C — entrada: A=byte, C=posicao do bit (0..7)
;             saida: A = byte com aquele bit setado em 1
SET_BIT_C:
    push hl
    push de
    push bc
    ld   hl,BITMASKS
    ld   d,0
    ld   e,c
    add  hl,de
    or   (hl)
    pop  bc
    pop  de
    pop  hl
    ret

; ============================================================
; ESPELHAMENTO (mirror horizontal / vertical)
; ============================================================

; REVERSE_BYTE — entrada: A=byte, saida: A=byte com bits invertidos
; (bit0<->bit7, bit1<->bit6 ...) usado no espelho horizontal
REVERSE_BYTE:
    push bc
    push de
    ld   e,a
    ld   d,0
    xor  a
    ld   (REV_IDX),a
REV_LOOP:
    ld   a,(REV_IDX)
    ld   b,a
    ld   a,e
    call GET_BIT
    jr   nc,REV_SKIP
    ld   a,7
    ld   hl,REV_IDX
    sub  (hl)
    ld   c,a
    ld   a,d
    call SET_BIT_C
    ld   d,a
REV_SKIP:
    ld   a,(REV_IDX)
    inc  a
    ld   (REV_IDX),a
    cp   8
    jr   nz,REV_LOOP
    ld   a,d
    pop  de
    pop  bc
    ret

; MAX_MIRROR_H — espelha o buffer na horizontal (esquerda<->direita)
; entrada: HL = buffer de 8 bytes (modificado no lugar)
MAX_MIRROR_H:
    push hl                     ; guarda o HL original p/ devolver ao chamador
    ld   b,8
MIRROR_H_LOOP:
    push bc
    push hl
    ld   a,(hl)
    call REVERSE_BYTE
    pop  hl
    ld   (hl),a
    inc  hl
    pop  bc
    djnz MIRROR_H_LOOP
    pop  hl                     ; restaura HL para o valor de entrada
    ret

; MAX_MIRROR_V — espelha o buffer na vertical (cima<->baixo)
; entrada: HL = buffer de 8 bytes (modificado no lugar)
MAX_MIRROR_V:
    push hl
    ld   d,h
    ld   e,l
    ld   a,e
    add  a,7
    ld   e,a
    jr   nc,MV_NOCARRY
    inc  d
MV_NOCARRY:
    pop  hl
    ld   b,4
MV_LOOP:
    push bc
    ld   a,(hl)
    ld   c,a
    ld   a,(de)
    ld   (hl),a
    ld   a,c
    ld   (de),a
    inc  hl
    dec  de
    pop  bc
    djnz MV_LOOP
    ret

; ============================================================
; ROTACAO 90 GRAUS (sentido horario)
; ============================================================

; MAX_ROTATE90_CW — entrada: HL=buffer origem(8 bytes),
;                            DE=buffer destino(8 bytes)
MAX_ROTATE90_CW:
    ld   (ROT_SRC),hl
    ld   (ROT_DST),de
    xor  a
    ld   (ROT_I),a
ROT_I_LOOP:
    xor  a
    ld   (ROT_ACC),a
    ld   (ROT_B),a
ROT_B_LOOP:
    ld   hl,(ROT_SRC)
    ld   a,(ROT_B)
    ld   e,a
    ld   d,0
    add  hl,de
    ld   d,(hl)               ; D = byte de origem numero ROT_B
    ld   a,7
    ld   hl,ROT_I
    sub  (hl)                  ; A = 7 - ROT_I = posicao a extrair
    ld   b,a
    ld   a,d
    call GET_BIT                ; carry = bit (7-ROT_I) do byte ROT_B
    jr   nc,ROT_SKIP
    ld   a,(ROT_B)
    ld   c,a
    ld   a,(ROT_ACC)
    call SET_BIT_C
    ld   (ROT_ACC),a
ROT_SKIP:
    ld   a,(ROT_B)
    inc  a
    ld   (ROT_B),a
    cp   8
    jr   nz,ROT_B_LOOP
    ld   hl,(ROT_DST)
    ld   a,(ROT_I)
    ld   e,a
    ld   d,0
    add  hl,de
    ld   a,(ROT_ACC)
    ld   (hl),a
    ld   a,(ROT_I)
    inc  a
    ld   (ROT_I),a
    cp   8
    jr   nz,ROT_I_LOOP
    ret

; ============================================================
; SCROLL DE TEXTO
; ============================================================

; MAX_SCROLL_STEP — entra uma nova coluna pela direita, desloca
; tudo 1 bit para a esquerda e redesenha
; entrada: A = byte da nova coluna (bit r = pixel da linha r, 0=topo)
MAX_SCROLL_STEP:
    ld   (SCROLL_COL),a
    ld   hl,DISPLAY_BUF
    xor  a
    ld   (SCROLL_ROW),a
SCROLL_ROW_LOOP:
    ld   a,(hl)
    sla  a                      ; desloca a linha 1 bit p/ esquerda
    push hl
    push af
    ld   a,(SCROLL_ROW)
    ld   b,a
    ld   a,(SCROLL_COL)
    call GET_BIT                 ; carry = bit da nova coluna p/ esta linha
    jr   c,SCROLL_BIT_SET        ; testa o carry ANTES do pop af (pop af mexe nas flags)
    pop  af
    jr   SCROLL_ROW_SKIP
SCROLL_BIT_SET:
    pop  af
    or   1
SCROLL_ROW_SKIP:
    pop  hl
    ld   (hl),a
    inc  hl
    ld   a,(SCROLL_ROW)
    inc  a
    ld   (SCROLL_ROW),a
    cp   8
    jr   nz,SCROLL_ROW_LOOP
    ret

; MAX_SCROLL_MSG — rola uma mensagem (array de colunas) pelo display
; entrada: HL = ponteiro para o array de colunas, B = numero de colunas
MAX_SCROLL_MSG:
SCROLL_MSG_LOOP:
    push bc
    push hl
    ld   a,(hl)
    call MAX_SCROLL_STEP
    ld   hl,DISPLAY_BUF
    call MAX_DRAW
    call SCROLL_DELAY
    pop  hl
    inc  hl
    pop  bc
    djnz SCROLL_MSG_LOOP
    ret

; SCROLL_DELAY — pequeno atraso entre passos do scroll (ajuste o B
; inicial para controlar a velocidade)
SCROLL_DELAY:
    push bc
    ld   b, 250
DELAY_OUTER:
    push bc
    ld   c,0
DELAY_INNER:
    dec  c
    jr   nz,DELAY_INNER
    pop  bc
    djnz DELAY_OUTER
    pop  bc
    ret

; ============================================================
; DEMOS
; ============================================================

DEMO_BRIGHT_LOOP:
    call MAX_INIT
    call MAX_CLEAR
    ld   hl,PATTERN_X
    call MAX_DRAW
    xor  a
DEMO_BRIGHT_UP:
    push af
    call MAX_SET_BRIGHT
    call SCROLL_DELAY
    call SCROLL_DELAY
    pop  af
    inc  a
    cp   16
    jr   nz,DEMO_BRIGHT_UP
    ret

DEMO_SLEEP_WAKE:
    call MAX_INIT
    call MAX_CLEAR
    ld   hl,PATTERN_X
    call MAX_DRAW
DEMO_SW_LOOP:
    call MAX_SLEEP
    call SCROLL_DELAY
    call SCROLL_DELAY
    call MAX_WAKE
    call SCROLL_DELAY
    call SCROLL_DELAY
    jr   DEMO_SW_LOOP

DEMO_TEST:
    call MAX_INIT
    call MAX_TEST_ON
    ret

DEMO_MIRROR:
    call MAX_INIT
    call MAX_CLEAR
    ld   hl,PATTERN_L
    ld   de,MIRROR_BUF
    ld   bc,8
    ldir
    ld   hl,MIRROR_BUF
    call MAX_MIRROR_H
    ld   hl,MIRROR_BUF
    call MAX_DRAW
    ret

DEMO_ROTATE:
    call MAX_INIT
    call MAX_CLEAR
    ld   hl,PATTERN_L
    ld   de,ROTATE_BUF
    call MAX_ROTATE90_CW
    ld   hl,ROTATE_BUF
    call MAX_DRAW
    ret

DEMO_SCROLL:
    call MAX_INIT
    call MAX_CLEAR
    ld   hl,DISPLAY_BUF
    ld   b,8
DEMO_SCROLL_CLR:
    xor  a
    ld   (hl),a
    inc  hl
    djnz DEMO_SCROLL_CLR
DEMO_SCROLL_LOOP:
    ld   hl,FONT_MSG
    ld   b,FONT_MSG_LEN
    call MAX_SCROLL_MSG
    jr   DEMO_SCROLL_LOOP

; ============================================================
; DADOS
; ============================================================
SHADOW_PORT: .db $00

DISPLAY_BUF:
    defb 0,0,0,0,0,0,0,0

MIRROR_BUF:
    defb 0,0,0,0,0,0,0,0

ROTATE_BUF:
    defb 0,0,0,0,0,0,0,0

REV_IDX:  defb 0
ROT_SRC:  defw 0
ROT_DST:  defw 0
ROT_I:    defb 0
ROT_B:    defb 0
ROT_ACC:  defb 0
SCROLL_COL: defb 0
SCROLL_ROW: defb 0

PATTERN_X:
    defb 10000001b
    defb 01000010b
    defb 00100100b
    defb 00011000b
    defb 00011000b
    defb 00100100b
    defb 01000010b
    defb 10000001b

; "L" assimetrico — util p/ testar mirror/rotate de forma visivel
; (o PATTERN_X e simetrico e nao mostra diferenca nesses testes)
PATTERN_L:
    defb 11000000b
    defb 11000000b
    defb 11000000b
    defb 11000000b
    defb 11000000b
    defb 11000000b
    defb 11000000b
    defb 11111110b

; fonte de exemplo: "Z80Mini"
; (bit r = pixel da linha r, 0=topo) — expanda para o seu alfabeto
FONT_MSG:
    defb 01000010b, 01100010b, 01010010b, 01001010b, 01000110b  ; Z
    defb 00000000b                                              ; espaco
    defb 00110100b, 01001010b, 01001010b, 01001010b, 00110100b  ; 8
    defb 00000000b                                              ; espaco
    defb 00111100b, 01000010b, 01000010b, 01000010b, 00111100b  ; 0
    defb 00000000b                                              ; espaco
    defb 01111110b, 00000100b, 00001000b, 00000100b, 01111110b  ; M
    defb 00000000b                                              ; espaco
    defb 01111010b                                              ; i
    defb 00000000b                                              ; espaco
    defb 01111110b, 00000100b, 00001000b, 00010000b, 01111110b  ; n
    defb 00000000b                                              ; espaco
    defb 01111010b                                              ; i
    defb 00000000b, 00000000b, 00000000b, 00000000b             ; espacos (loop)
    defb 00000000b, 00000000b, 00000000b, 00000000b             ; espacos (loop)
FONT_MSG_LEN equ $ - FONT_MSG






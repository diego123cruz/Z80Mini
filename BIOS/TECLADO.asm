DB_OUTER    EQU     22          ; iterações externas
DB_INNER    EQU     240         ; iterações DJNZ internas


; -----------------------------------------------------------------------------
;   Check break key (Basic)
;       Informa se há tecla, SEM consumir: a tecla fica em KEY_BUF e
;       a próxima leitura (GETINP -> readKeyboarPressA) a devolve.
;       Esc é guardado como CTRLC, pois o BASIC só reconhece Ctrl+C.
;       On exit: Z  e A = 0        -> nenhuma tecla
;                NZ e A = CTRLC    -> Esc ou Ctrl+C
;                NZ e A = tecla    -> outra tecla
;       BC DE HL preserved
; -----------------------------------------------------------------------------
CHKKEY:
    LD      A, (KEY_BUF)        ; já tem tecla guardada?
    OR      A
    JR      NZ, CK_HAVE

    PUSH    BC
    PUSH    DE
    PUSH    HL
    CALL    readKeyboarPressA   ; Carry=1 e A=tecla nova
    POP     HL                  ; POP não altera flags
    POP     DE
    POP     BC
    JR      NC, CK_NONE

    CP      $1B                 ; Esc vira Ctrl+C para o BASIC
    JR      NZ, CK_STORE
    LD      A, CTRLC
CK_STORE:
    LD      (KEY_BUF), A        ; guarda para o GETINP ler

CK_HAVE:
    CP      $1B                 ; Esc
    JR      Z, CK_BREAK
    CP      CTRLC               ; Ctrl+C ($03)
    JR      Z, CK_BREAK
    OR      A                   ; NZ (A != 0)
    RET

CK_BREAK:
    LD      A, CTRLC
    OR      A                   ; NZ
    RET

CK_NONE:
    XOR     A                   ; A = 0, Z
    RET






LCD_SCROLL_CONIN:
    CALL PUTCHAR
    JP CONIN_K

;   CONIN: Lê um teclado → A
;       On exit: A = KEY
;       BC DE HL preserved
;       loop until key is pressed 
CONIN:
    PUSH BC
    PUSH DE
    PUSH HL
CONIN_K:
    CALL readKeyboarWaitPressA
    CP   $F8    ; ignora scroll up - GLCD
    JR   Z, LCD_SCROLL_CONIN
    CP   $F7    ; ignora scroll down - GLCD
    JR   Z, LCD_SCROLL_CONIN
    CP   LF
    JR   Z, CONIN_K    ; Ignora LF
    CP   ESC
    JR   Z, CONIN_K    ; Ignora
    CP   $FF ;capslock Ignora
    JP   Z, CONIN_K
    POP HL
    POP DE
    POP BC
    RET



;   CONIN: Lê um teclado → A
;       On exit: A = KEY
;       BC DE HL preserved
;       sem loop, Carry=1 se tecla
CONIN_NOT_LOOP:
    PUSH BC
    PUSH DE
    PUSH HL
    CALL readKeyboarPressA
    POP HL
    POP DE
    POP BC
    RET



; ============================================================
; KBD_INIT  -  chamar uma vez no boot
; ============================================================
KBD_INIT:
    XOR     A
    LD      (KEY_BUF), A
    LD      (CAPS_ON), A
    LD      (KEY_HELD), A
    LD      HL, KEY_PREV
    LD      B, 8
KI_CLR:
    LD      (HL), A
    INC     HL
    DJNZ    KI_CLR
    JP      KBD_IDLE            ; porta em repouso, LED apagado


; ============================================================
; readKeyboarWaitPressA  (bloqueante)
;   Aguarda uma tecla NOVA e retorna o caractere em A.
;   Não espera soltar -> permite digitação rápida (rollover).
; ============================================================
readKeyboarWaitPressA:
    CALL    readKeyboarPressA
    JR      NC, readKeyboarWaitPressA
    RET


; ============================================================
; readKeyboarPressA  (não bloqueante)
;   Saída: Carry=1 e A=caractere se uma tecla acabou de ser
;          pressionada; Carry=0 caso contrário.
; ============================================================
readKeyboarPressA:
    ; --- Tecla guardada pelo CHKKEY? ---
    LD      A, (KEY_BUF)
    OR      A
    JR      Z, KP_POLL
    PUSH    AF
    XOR     A
    LD      (KEY_BUF), A        ; esvazia o buffer
    POP     AF
    SCF
    RET

KP_POLL:
    ; --- Caminho rápido: nada pressionado agora nem antes ---
    ; --- Caminho rápido: nada pressionado agora nem antes ---
    CALL    ANY_KEY
    JR      NZ, KP_SCAN
    LD      A, (KEY_HELD)
    OR      A                   ; Carry=0
    RET     Z

KP_SCAN:
    LD      HL, KEY_CUR
    CALL    SCAN_ALL

    ; --- Mudou algo desde o último estado estável? ---
    LD      HL, KEY_CUR
    LD      DE, KEY_PREV
    CALL    COMPARE8
    JR      Z, KP_NONE          ; nada mudou, sem debounce

    ; --- Mudou: debounce e confirma ---
    CALL    DEBOUNCE
    LD      HL, KEY_CHK
    CALL    SCAN_ALL
    LD      HL, KEY_CUR
    LD      DE, KEY_CHK
    CALL    COMPARE8
    JR      NZ, KP_NONE         ; ainda instável, tenta depois

    ; --- Estado estável novo: procura tecla recém-pressionada ---
    CALL    FIND_EDGE           ; Carry=1 se achou (KEY_PRESS)
    PUSH    AF

    ; KEY_PREV <- KEY_CUR
    LD      HL, KEY_CUR
    LD      DE, KEY_PREV
    LD      BC, 8
    LDIR

    ; KEY_HELD <- OR de todas as colunas (0 = nada pressionado)
    LD      HL, KEY_CUR
    LD      B, 8
    XOR     A
KP_OR:
    OR      (HL)
    INC     HL
    DJNZ    KP_OR
    LD      (KEY_HELD), A

    POP     AF                  ; recupera Carry do FIND_EDGE
    LD      A, (KEY_PRESS)      ; LD não altera flags
    RET

KP_NONE:
    OR      A                   ; Carry=0
    RET


; ============================================================
; ANY_KEY
;   Ativa TODAS as colunas de uma vez (seguro graças aos diodos)
;   e lê as linhas numa única leitura.
;   Saída: Z=1 se nenhuma tecla pressionada.
; ============================================================
ANY_KEY:
    XOR     A
    OUT     (KEYBOARD), A       ; todas as colunas ativas
    NOP
    NOP
    NOP
    NOP
    IN      A, (KEYBOARD)
    CPL
    LD      C, A
    CALL    KBD_IDLE            ; volta ao repouso (LED conforme Capslock)
    LD      A, C
    OR      A
    RET


; ============================================================
; SCAN_ALL
;   Entrada: HL = buffer de 8 bytes
;   Saída:   buffer[col] = bits das linhas pressionadas (1 = pressionada)
; ============================================================
SCAN_ALL:
    LD      D, $FE              ; coluna 0 ativa
    LD      B, 8
SA_COL:
    LD      A, D
    OUT     (KEYBOARD), A
    NOP                         ; estabilização
    NOP
    NOP
    NOP
    IN      A, (KEYBOARD)
    CPL                         ; pull-up: pressionado = 1
    LD      (HL), A
    INC     HL
    RLC     D                   ; $FE -> $FD -> $FB ... -> $7F
    DJNZ    SA_COL
    JP      KBD_IDLE            ; volta ao repouso (LED conforme Capslock)


; ============================================================
; KBD_IDLE  -  valor de repouso da porta do teclado
;   Circuito do LED: acende só com b0=b1=b2=0 e b4=b5=1.
;   Na varredura só uma coluna fica em 0, então o LED nunca
;   acende por engano. No repouso deixamos:
;     Capslock ligado    -> $F8  (LED aceso fixo)
;     Capslock desligado -> $FF  (tudo inativo, LED apagado)
;   Altera só A.
; ============================================================
KBD_IDLE:
    LD      A, (CAPS_ON)
    OR      A
    LD      A, $FF              ; LD não altera flags
    JR      Z, KI_OUT
    LD      A, $F8
KI_OUT:
    OUT     (KEYBOARD), A
    RET


; ============================================================
; COMPARE8
;   Compara 8 bytes em (HL) e (DE).  Z=1 se iguais.
; ============================================================
COMPARE8:
    LD      B, 8
C8_LOOP:
    LD      A, (DE)
    CP      (HL)
    RET     NZ
    INC     HL
    INC     DE
    DJNZ    C8_LOOP
    RET                         ; Z=1


; ============================================================
; FIND_EDGE
;   Procura a primeira tecla que está em KEY_CUR mas não em
;   KEY_PREV e que gere um caractere válido.
;   Saída: Carry=1 e KEY_PRESS preenchido se achou.
; ============================================================
FIND_EDGE:
    LD      HL, KEY_CUR
    LD      DE, KEY_PREV
    LD      B, 0                ; B = coluna
FE_COL:
    LD      A, (DE)
    CPL
    AND     (HL)                ; recém-pressionadas = cur AND NOT prev
    JR      Z, FE_NEXT
    LD      C, 0                ; C = linha
FE_ROW:
    SRL     A                   ; bit 0 -> Carry, 0 entra no bit 7
    JR      NC, FE_SKIP
    PUSH    AF
    PUSH    HL
    PUSH    DE
    PUSH    BC
    CALL    KEY_TO_ASCII        ; Carry=1 se caractere válido
    POP     BC
    POP     DE
    POP     HL
    JR      C, FE_FOUND
    POP     AF
FE_SKIP:
    INC     C
    OR      A
    JR      NZ, FE_ROW
FE_NEXT:
    INC     HL
    INC     DE
    INC     B
    LD      A, B
    CP      8
    JR      NZ, FE_COL
    OR      A                   ; Carry=0: nada novo
    RET
FE_FOUND:
    POP     AF                  ; descarta
    SCF
    RET


; ============================================================
; KEY_TO_ASCII
;   Entrada: B = coluna, C = linha
;   Saída:   Carry=1 e KEY_PRESS = caractere, ou Carry=0 se for
;            modificador (Capslock alterna aqui).
;   Shift left = col 0 / linha 3   Ctrl left = col 0 / linha 4
; ============================================================
KEY_TO_ASCII:
    LD      A, B
    ADD     A, A
    ADD     A, A
    ADD     A, A
    ADD     A, C                ; índice = col*8 + linha
    LD      E, A
    LD      D, 0

    LD      HL, KEYMAP_NORMAL
    ADD     HL, DE
    LD      A, (HL)
    CP      $FF
    JR      Z, KTA_CAPS         ; Capslock
    CP      $F6
    JR      Z, KTA_NONE         ; Fn
    CP      $FB
    JR      NC, KTA_NONE        ; $FB-$FE: Alt, Win, Ctrl, Shift

    ; --- Escolhe a tabela ---
    LD      HL, KEYMAP_SHIFT
    LD      A, (KEY_CUR)
    BIT     3, A                ; Shift esquerdo pressionado?
    JR      NZ, KTA_LOOK
    LD      HL, KEYMAP_CAPSLOCK
    LD      A, (CAPS_ON)
    OR      A
    JR      NZ, KTA_LOOK
    LD      HL, KEYMAP_NORMAL
KTA_LOOK:
    ADD     HL, DE
    LD      A, (HL)

    ; --- Ctrl esquerdo: gera código de controle ($40-$7F) ---
    LD      HL, KEY_CUR
    BIT     4, (HL)
    JR      Z, KTA_OK
    CP      $40
    JR      C, KTA_OK
    CP      $80
    JR      NC, KTA_OK
    AND     $1F                 ; Ctrl+C = $03, Ctrl+Z = $1A ...
KTA_OK:
    LD      (KEY_PRESS), A
    SCF
    RET

KTA_CAPS:
    LD      A, (CAPS_ON)
    XOR     1
    LD      (CAPS_ON), A
    CALL    KBD_IDLE            ; atualiza o LED na hora
KTA_NONE:
    OR      A                   ; Carry=0
    RET


; ============================================================
; DEBOUNCE  –  ~10 ms @ 7.3728 MHz, preserva BC
; ============================================================
DEBOUNCE:
    PUSH    BC
    LD      B, DB_OUTER
DB_OUTER_LOOP:
    LD      C, DB_INNER
DB_INNER_LOOP:
    DEC     C
    JR      NZ, DB_INNER_LOOP
    DJNZ    DB_OUTER_LOOP
    POP     BC
    RET
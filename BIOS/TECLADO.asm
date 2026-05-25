DB_OUTER    EQU     22          ; iterações externas
DB_INNER    EQU     240         ; iterações DJNZ internas


; -----------------------------------------------------------------------------
;   Check break key (Basic)
;       On exit: If press A = CTRLC and NZ flagged
;       BC DE HL preserved
; -----------------------------------------------------------------------------
CHKKEY:
    LD      A, 0xFE             ; Máscara: bit 0 baixo = col 0
    OUT     (KEYBOARD), A       ; Ativa coluna B
    NOP                         ; ~270 ns de estabilização
    NOP
    NOP
    NOP
    IN      A, (KEYBOARD)       ; Lê linhas
    CPL                         ; Pull-up: inverte (pressionado = 1)
    CP 1
    jp nz, GRET
	LD  A, CTRLC
	CP	0
	RET
GRET:
	LD  A, 0
	CP 0
	RET


;   CONIN: Lê um teclado → A
;       On exit: A = KEY
;       BC DE HL preserved
;       loop until key is pressed 
CONIN:
    PUSH BC
    PUSH DE
    PUSH HL
    CALL readKeyboarWaitPressA
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


readKeyboarPressA;
    XOR A
    LD (MEN_SHIFT), A ; reset shift
    CALL    SCAN_MATRIX
    RET      NC
    CALl GetKeycode
    CALL checkShiftKey
    LD A, (KEY_PRESS)
    SCF  ; Carry = 1
    RET



; A = col*8 + row  (0x00 – 0x3F)
GetKeycode:
    ; --- Tecla confirmada: calcula keycode ---
    ; col*8 + row  (0x00 – 0x3F)
    LD      A, B                ; B = coluna
    ADD     A, A                ; ×2
    ADD     A, A                ; ×4
    ADD     A, A                ; ×8
    ADD     A, C                ; + linha (C) = keycode
    RET


; Verifica se shift e recupera ascii
;   Salva tecla em KEY_PRESS
checkShiftKey:
    ; Verifica Shift
    LD E, A
    LD HL, KEYMAP_NORMAL
    LD A, (MEN_SHIFT)
    CP 1
    JP NZ, NO_SHIFT
    LD HL, KEYMAP_SHIFT
NO_SHIFT:
    CALL 	DO_LOOKUP	; pega tecla
    LD (KEY_PRESS), A
    RET



; LER TECLADO
; Aguarda até uma teclad for pressionada e retorna em A
readKeyboarWaitPressA:
    CALL    SCAN_MATRIX
    JP      NC, readKeyboarWaitPressA       ; Nenhuma tecla, continua

    ; --- Primeira leitura positiva: aguarda debounce ---
    CALL    DEBOUNCE

    ; --- Confirma que a tecla ainda está pressionada ---
    XOR A
    LD (MEN_SHIFT), A ; reset shift
    CALL    SCAN_MATRIX
    JP      NC, readKeyboarWaitPressA       ; Foi ruído, descarta

    CALL GetKeycode
    
    CALL checkShiftKey
    
    ; --- Aguarda soltar + debounce de release ---
WAIT_RELEASE:
    CALL    SCAN_MATRIX
    JP      C, WAIT_RELEASE     ; Ainda pressionada
    CALL    DEBOUNCE            ; Debounce do soltar
    CALL    SCAN_MATRIX
    JP      C, WAIT_RELEASE     ; Bounce no release, volta a esperar

    LD A, (KEY_PRESS)
    OR A
    RET






; ============================================================
; DEBOUNCE  –  espera ~10 ms (calibrado para 7.3728 MHz)
;   Usa DE como contador, preserva BC
;   T-states totais ≈ 69.080  →  ~9.36 ms
; ============================================================
DEBOUNCE:
    PUSH    BC
    LD      B, DB_OUTER         ; B = contador externo
DB_OUTER_LOOP:
    LD      C, DB_INNER         ; C = contador interno
DB_INNER_LOOP:
    DEC     C                   ; 4 T
    JR      NZ, DB_INNER_LOOP   ; 12 T (não salta) / 7 T (salta)
    DJNZ    DB_OUTER_LOOP       ; 13 T (não salta) / 8 T (salta)
    POP     BC
    RET


; Pega char in table
DO_LOOKUP:
    LD      D, 0
    ADD     HL, DE
    LD      A, (HL)
    RET


; ============================================================
; SCAN_MATRIX
;   Varre 8 colunas, uma por vez (bit baixo = ativo)
;   Saída: B = col (0-7), C = row (0-7), Carry=1 se tecla
; ============================================================
SCAN_MATRIX:
    LD      B, 0                ; Coluna atual
    LD      D, 0xFE             ; Máscara: bit 0 baixo = col 0
SCAN_COL:
    LD      A, D
    OUT     (KEYBOARD), A       ; Ativa coluna B
    NOP                         ; ~270 ns de estabilização
    NOP
    NOP
    NOP
    IN      A, (KEYBOARD)       ; Lê linhas
    CPL                         ; Pull-up: inverte (pressionado = 1)
    
    ; SHIFT
    PUSH AF
    LD A, D
    CP $FE
    JP NZ, FIM
    POP AF
    PUSH AF
    CP $08
    JP NZ, FIM
    LD A, 1
    LD (MEN_SHIFT), A
    POP AF
    LD A, 0
    PUSH AF
    
FIM:
	POP AF
    
    AND     0xFF
    JR      Z, NEXT_COL         ; Nenhuma linha nesta coluna
    
    ; Encontrou linha — identifica bit
    LD      C, 0
FIND_ROW:
    RRA
    JR      C, ROW_FOUND
    INC     C
    JR      FIND_ROW

ROW_FOUND:
    LD      A, 0xFF
    OUT     (KEYBOARD), A           ; Desativa colunas
    SCF                         ; Carry = 1
    RET

NEXT_COL:
    INC     B
    LD      A, B
    CP      8
    JR      Z, SCAN_NONE        ; Todas varridas, nada encontrado

    ; Rotaciona máscara para próxima coluna
    LD      A, D
    SCF
    RL      A                   ; Desloca bit baixo para esquerda
    OR      0x01                ; Garante que o bit 0 volta alto (inativo)
    LD      D, A
    JR      SCAN_COL

SCAN_NONE:
    LD      A, 0xFF
    OUT     (KEYBOARD), A
    OR      A                   ; Limpa Carry
    RET


    
    
    

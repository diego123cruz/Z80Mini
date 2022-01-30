; ---------------------------------------------------------
;   Z80 Mini  -  inicio 01/2022
;   Diego Cruz - github.com/diego123cruz
;
;   Hardware baseado em: http://www.sunrise-ev.com/z80.htm
;   Software próprio - em construção
; ---------------------------------------------------------
;   Z80@4Mhz
;   ROM 32k - 28C256
;   RAM 32k - 65256
;   Display 7 segmentos 8 digitos
;   Teclado 16 teclas + Fn (Tecla de função? ou outra coisa?)
;   Entrada 40h
;   Saida 40h
;
;
; ---------------------------------------------------------
;   Display 7 Segmentos - In(Port40) AND 00000111b
; ---------------------------------------------------------
;
;   ------------------------------------------------
;   | 00h | 01h | 02h | 03h | 04h | 05h | 06h | 07h |
;   ------------------------------------------------
;
;               A(0)
;            ---------
;           |         |
;      F(5) |         | B(1)
;           |   G(6)  |
;            ---------
;           |         |
;      E(4) |         | C(2)
;           |         |
;            ---------         Ponto(7)
;               D(3) 
;
;
;
;
;
; ---------------------------------------------------------
; Teclado 
; ---------------------------------------------------------
;   
;   Keys:        
;       Fn - In(Port40) AND 00010000b - pulldown
;       0 - In(Port40) AND 00000111b
;
;
;
;


; ---------------------------------------------------------
; Constantes
; ---------------------------------------------------------

Port40        .equ    $40
PortC0        .equ    $C0
START_RAM     .equ    $8000
STACK         .equ    $FF00  
CKEY_TIMEOUT  .equ    100  ; 100ms +-

; ---------------------------------------------------------
; RAM MAP - Monitor | $FF00 - $FFFF
; ---------------------------------------------------------
; Cada digito fica em um ponto da memoria RAM
DIG_0       .equ    $FF00   ;(1) endereço do digito 0 na memoria RAM
DIG_1       .equ    $FF01   ;(1) endereço do digito 1 na memoria RAM
DIG_2       .equ    $FF02   ;(1) endereço do digito 2 na memoria RAM
DIG_3       .equ    $FF03   ;(1) endereço do digito 3 na memoria RAM
DIG_4       .equ    $FF04   ;(1) endereço do digito 4 na memoria RAM
DIG_5       .equ    $FF05   ;(1) endereço do digito 5 na memoria RAM
DIG_6       .equ    $FF06   ;(1) endereço do digito 6 na memoria RAM
DIG_7       .equ    $FF07   ;(1) endereço do digito 7 na memoria RAM
KEY_PRESS   .equ    $FF08   ;(1) key atual
INPUT       .equ    $FF09   ;(1) temp input from int
TMP_KEY     .equ    $FF0A   ;(1) tmp key
KEY_TIMEOUT .equ    $FF0B   ;(1) tempo para retornar a tecla, CKEY_TIMEOUT
SHOW_DIG    .equ    $FF0C   ;(1) LIVRE
PC_RAM      .equ    $FF0D   ;(2) save pc to user start $8000

SYSMODE     .equ    $FF0F   ;(1) System mode. 
                            ; 0 - User Mode
                            ; 1 - Monitor
                            ; 2 - Examine Memoria
                            ; 3 - Change Data(Memory)
                            ; 4 - Show register PC
                            ; 5 - Show register SP
                            ; 6 - Show register AF
                            ; 7 - Show register BC
                            ; 8 - Show register DE
                            ; 9 - Show register HL
                            ; A - Show register IX
                            ; B - Show register IY
                            ; C - Show register AF'
                            ; D - Show register BC'
                            ; E - Show register DE'
                            ; F - Show register HL'
TicCounter  .equ    $FF10   ;(2) TicCounter inc 1ms
EXM_COUNT   .equ    $FF12   ;(1) Count digits Examine function, 4 digits
MDF_COUNT   .equ    $FF13   ;(1) Count digits moDify function, 2 digits
USR_PC      .equ    $FF14   ;(2) PC 
USR_SP      .equ    $FF16   ;(2) SP
USR_HL      .equ    $FF18   ;(2) HL
USR_BC      .equ    $FF1A   ;(2) BC
USR_DE      .equ    $FF1C   ;(2) DE
USR_AF      .equ    $FF1E   ;(2) AF
USR_IX      .equ    $FF20   ;(2) IX
USR_IY      .equ    $FF22   ;(2) IY
USR_AFA     .equ    $FF24   ;(2) AF' (Aux)
USR_BCA     .equ    $FF26   ;(2) BC' (Aux)
USR_DEA     .equ    $FF28   ;(2) DE' (Aux)
USR_HLA     .equ    $FF2A   ;(2) HL' (Aux)
; SP Temp   .equ    $FF2C



; Copy USER_DISPx to DIG_x WHEN USER_MODE
USER_DISP0  .equ    $FFD0   ; Mode User - Display Dig 0  - 01234567
USER_DISP1  .equ    $FFD1   ; Mode User - Display Dig 1  - 01234567
USER_DISP2  .equ    $FFD2   ; Mode User - Display Dig 2  - 01234567
USER_DISP3  .equ    $FFD3   ; Mode User - Display Dig 3  - 01234567
USER_DISP4  .equ    $FFD4   ; Mode User - Display Dig 4  - 01234567
USER_DISP5  .equ    $FFD5   ; Mode User - Display Dig 5  - 01234567
USER_DISP6  .equ    $FFD6   ; Mode User - Display Dig 6  - 01234567
USER_DISP7  .equ    $FFD7   ; Mode User - Display Dig 7  - 01234567



; =========================================================
; Start ROM
; =========================================================
.org    $0000
    JP  START

; =========================================================
; Livre para colocar funções 0003h - 0037h 
; =========================================================

; delay_100ms

; char7segFromA

; animacaoLeds

; Limpar RAM (FF).... etc


; =========================================================
; Int 38h
; =========================================================
.org    $38
    DI                       ; Disable interrupt

    LD (USR_SP), SP          ; Save SP
    LD (USR_HL), HL          ; Save HL
    POP  HL                  ; Recupera PC da stack
    LD (USR_PC), HL          ; Save PC
    PUSH HL                  ;
    LD HL, $FF2C             ; Carrega Temp SP to HL
    LD SP, HL                ; Set temp HL
    EXX                      ; Inverte HL e HL', DE.... BC....
    PUSH  HL                 ; Save HL'
    PUSH  DE                 ; Save DE'                
    PUSH  BC                 ; Save BC'
    EX    AF, AF'
    PUSH  AF                 ; Save AF'
    EX    AF, AF'
    EXX                      ; Troca HL' e HL,, DE... BC...
    PUSH  IY                 ; Save IY
    PUSH  IX                 ; Save IX
    PUSH  AF                 ; Save AF
    PUSH  DE                 ; Save DE
    PUSH  BC                 ; Save BC
    LD HL, (USR_SP)          ; Recupera SP
    LD SP, HL                ; Devolve SP original

    ; TicCounter
    LD  HL, (TicCounter)     ; Increment 1ms, used to DELAY_A
    INC  HL
    LD  (TicCounter), HL

    ; Timeout Key
     LD A, (KEY_TIMEOUT)
     CP 0
     JP Z, ENTER_MAIN
     DEC A
     LD (KEY_TIMEOUT), A

    ; Main
ENTER_MAIN:
    CALL UPDATE_DISPLAYS
    CALL UPDATE_KEYS

    ; Show atual digit
    LD  A, (SHOW_DIG)
    OUT (Port40), A

    ;CALL    TRATAMENTO_INT38H; Get key, update display   
    JP      SYS_MAIN         ; Execute function monitor

EXIT_SYS:
    POP HL                   ; Troca o PC
    LD HL, (USR_PC)          ; Recupera PC
    PUSH HL                  ; Devolve PC to stack

    LD HL, (USR_AFA)          ; Load AF' in HL
    PUSH  HL                 ; Push AF'
    POP AF                   ; Recovery AF'
    EX AF, AF'

    LD HL, (USR_HLA)          ; Recovery HL'
    LD DE, (USR_DEA)          ; Recovery DE'
    LD BC, (USR_BCA)          ; Recovery BC'
    EXX

    LD HL, (USR_AF)          ; Load AF in HL
    PUSH  HL                 ; Push AF
    POP AF                   ; Recovery AF

    LD HL, (USR_HL)          ; Recovery HL
    LD DE, (USR_DE)          ; Recovery DE
    LD BC, (USR_BC)          ; Recovery BC

    EI                       ; Enable interrupt
    RETI                     ; Return interrupt


; =========================================================
; Update display - Tratamento Int 38h
; =========================================================
UPDATE_DISPLAYS:    
    IN    A, (Port40)
    LD    (INPUT), A
    AND   $07
    CP    $08
    JP    NC, UPDATE_DISPLAYS_RET ; IF A > 7 RET
    INC   A
    CP    $08
    JP    NZ, UPDATE_DISPLAYS_OK
    LD    A, $00
UPDATE_DISPLAYS_OK:
    LD    H, $FF
    LD    L, A
    LD    A, (HL)
    LD   (SHOW_DIG), A
UPDATE_DISPLAYS_RET:
    RET

; =========================================================
; Update KEY - Tratamento Int 38h
; =========================================================
UPDATE_KEYS:    
    IN    A, (Port40)
    LD    (INPUT), A
    AND   $07
    CP    $08
    JP    NC, UPDATE_KEY_RET ; IF A > 7 RET
    LD  A,  (INPUT)
    BIT  3, A
    JP  Z, TRATAB3
    LD  A,  (INPUT)
    BIT  4, A
    JP  Z, TRATAB4
    JP  UPDATE_KEY_RET
UPDATE_KEY_GET:
    LD    (INPUT), A
    AND   $07
    LD    BC, 0
    LD    C, A
    ADD   HL, BC
    LD    A, (HL)
    LD   (KEY_PRESS), A
    LD A, CKEY_TIMEOUT
    LD (KEY_TIMEOUT), A
UPDATE_KEY_RET:
    RET

TRATAB3:
    LD    HL, KEYSB3
    JP  UPDATE_KEY_GET

TRATAB4:
    LD    HL, KEYSB4
    JP  UPDATE_KEY_GET

KEYSB3 .db $00, $01, $04, $07, $0F, $02, $05, $08
KEYSB4 .db $0E, $03, $06, $09, $0D, $0C, $0B, $0A



; =========================================================
; SYS MAIN
; =========================================================
SYS_MAIN:
    LD  A, (SYSMODE)
    CP  $00                  ; User mode can back to monitor
    JP  Z, USER_MODE        

    LD  A, (SYSMODE)
    CP  $01                  ; monitor
    JP  Z, MONITOR_MODE

    LD  A,  (SYSMODE)
    CP  $02                  ; Examine RAM
    JP  Z, EXAMINE_RAM

    LD  A, (SYSMODE)
    CP  $03                  ; Modify Data (Memory)
    JP  Z,  MODIFY_RAM

    LD  A, (SYSMODE)
    CP  $04                  ; Show register PC
    JP  Z,  SHOW_REG_PC

    LD  A, (SYSMODE)
    CP  $05                  ; Show register SP
    JP  Z,  SHOW_REG_SP

    LD  A, (SYSMODE)
    CP  $06                  ; Show register AF
    JP  Z,  SHOW_REG_AF

    LD  A, (SYSMODE)
    CP  $07                  ; Show register BC
    JP  Z,  SHOW_REG_BC

    LD  A, (SYSMODE)
    CP  $08                  ; Show register DE
    JP  Z,  SHOW_REG_DE

    LD  A, (SYSMODE)
    CP  $09                  ; Show register HL
    JP  Z,  SHOW_REG_HL

    LD  A, (SYSMODE)
    CP  $0A                  ; Show register IX
    JP  Z,  SHOW_REG_IX

    LD  A, (SYSMODE)
    CP  $0B                  ; Show register IY
    JP  Z,  SHOW_REG_IY

    LD  A, (SYSMODE)
    CP  $0C                  ; Show register AF'
    JP  Z,  SHOW_REG_AFaux

    LD  A, (SYSMODE)
    CP  $0D                  ; Show register BC'
    JP  Z,  SHOW_REG_BCaux

    LD  A, (SYSMODE)
    CP  $0E                  ; Show register DE'
    JP  Z,  SHOW_REG_DEaux

    LD  A, (SYSMODE)
    CP  $0F                  ; Show register HL'
    JP  Z,  SHOW_REG_HLaux

    JP  EXIT_SYS


; =========================================================
; Examine RAM Mode
; =========================================================
EXAMINE_RAM:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, EXIT_SYS

    PUSH  AF
    PUSH  AF
    LD  A, (EXM_COUNT)
    CP  3
    JP  Z, EXAMINE_KEY_POS_3

    LD  A, (EXM_COUNT)
    CP  2
    JP  Z, EXAMINE_KEY_POS_2

    LD  A, (EXM_COUNT)
    CP  1
    JP  Z, EXAMINE_KEY_POS_1

    LD  A, (EXM_COUNT)
    CP  0
    JP  Z, EXAMINE_KEY_POS_0

    JP  EXIT_SYS

EXAMINE_KEY_POS_3:
    POP  AF
    RLC  A
    RLC  A
    RLC  A
    RLC  A
    LD  H, A
    LD  (PC_RAM), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_0), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS


EXAMINE_KEY_POS_2:
    POP  AF
    LD  HL, (PC_RAM)
    OR  H
    LD  H, A
    LD  (PC_RAM), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_1), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS

EXAMINE_KEY_POS_1:
    POP  AF
    LD  HL, (PC_RAM)
    RLC  A
    RLC  A
    RLC  A
    RLC  A
    LD  L, A
    LD  (PC_RAM), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_2), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS


EXAMINE_KEY_POS_0:
    POP  AF
    LD  HL, (PC_RAM)
    OR  L
    LD  L, A
    LD  (PC_RAM), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_3), A
    JP  GO_MONITOR

; =========================================================
; MODIFY RAM Mode
; =========================================================
MODIFY_RAM:

    CALL GET_KEY_A
    CP  $FF
    JP  Z, EXIT_SYS

    PUSH  AF
    PUSH  AF
    LD  A, (MDF_COUNT)
    CP  1
    JP  Z, MODIFY_KEY_POS_1

    LD  A, (MDF_COUNT)
    CP  0
    JP  Z, MODIFY_KEY_POS_0

    JP  EXIT_SYS

MODIFY_KEY_POS_1:
    POP  AF
    RLC  A
    RLC  A
    RLC  A
    RLC  A
    LD  HL, (PC_RAM)
    LD  (HL), A

    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_6), A
    LD  A, (MDF_COUNT)
    DEC A
    LD  (MDF_COUNT), A
    JP  EXIT_SYS

MODIFY_KEY_POS_0:
    POP  AF
    LD  HL, (PC_RAM)
    LD  B, (HL)
    OR  B
    LD  HL, (PC_RAM)
    LD  (HL), A

    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_7), A
    JP  GO_MONITOR
    

SHOW_REG_PC:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $73               ; P
    LD  (DIG_1), A

    LD  A, $39
    LD  (DIG_2), A           ; C

    LD HL, (USR_PC)
    CALL PRINT_END_HL
    JP  EXIT_SYS


SHOW_REG_SP:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $6D               ; S
    LD  (DIG_1), A

    LD  A, $73               ; P
    LD  (DIG_2), A

    LD HL, (USR_SP)
    CALL PRINT_END_HL
    JP  EXIT_SYS


SHOW_REG_AF:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AFaux
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $77               ; A
    LD  (DIG_1), A

    LD  A, $71               ; F
    LD  (DIG_2), A

    LD HL, (USR_AF)
    CALL PRINT_END_HL
    JP  EXIT_SYS


SHOW_REG_BC:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BCaux
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $7C               ; B
    LD  (DIG_1), A

    LD  A, $39               ; C
    LD  (DIG_2), A

    LD HL, (USR_BC)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_DE:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DEaux
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $5E               ; D
    LD  (DIG_1), A

    LD  A, $79               ; E
    LD  (DIG_2), A

    LD HL, (USR_DE)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_HL:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HLaux
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $76               ; H
    LD  (DIG_1), A

    LD  A, $38               ; L
    LD  (DIG_2), A

    LD HL, (USR_HL)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_IX:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $06               ; I
    LD  (DIG_1), A

    LD  A, $70               ; X
    LD  (DIG_2), A

    LD HL, (USR_IX)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_IY:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $06               ; I
    LD  (DIG_1), A

    LD  A, $6E               ; Y
    LD  (DIG_2), A

    LD HL, (USR_IY)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_AFaux:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $77               ; A
    LD  (DIG_1), A

    LD  A, $71               ; F
    LD  (DIG_2), A

    LD  A, $20               ; '
    LD  (DIG_3), A

    LD HL, (USR_AFA)
    CALL PRINT_END_HL
    JP  EXIT_SYS


SHOW_REG_BCaux:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $7C               ; B
    LD  (DIG_1), A

    LD  A, $39               ; C
    LD  (DIG_2), A

    LD  A, $20               ; '
    LD  (DIG_3), A

    LD HL, (USR_BCA)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_DEaux:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $5E               ; D
    LD  (DIG_1), A

    LD  A, $79               ; E
    LD  (DIG_2), A

    LD  A, $20               ; '
    LD  (DIG_3), A

    LD HL, (USR_DEA)
    CALL PRINT_END_HL
    JP  EXIT_SYS

SHOW_REG_HLaux:
    CALL  GET_KEY_A
    CP  $00
    JP Z, GO_MONITOR
    CP  $01
    JP Z, GO_SHOW_REG_PC
    CP  $02
    JP Z, GO_SHOW_REG_SP
    CP  $03
    JP Z, GO_SHOW_REG_AF
    CP  $04
    JP Z, GO_SHOW_REG_BC
    CP  $05
    JP Z, GO_SHOW_REG_DE
    CP  $06
    JP Z, GO_SHOW_REG_HL
    CP  $07
    JP Z, GO_SHOW_REG_IX
    CP  $08
    JP Z, GO_SHOW_REG_IY

    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R
    LD  (DIG_0), A

    LD  A, $76               ; H
    LD  (DIG_1), A

    LD  A, $38               ; L
    LD  (DIG_2), A

    LD  A, $20               ; '
    LD  (DIG_3), A

    LD HL, (USR_HLA)
    CALL PRINT_END_HL
    JP  EXIT_SYS


; =========================================================
; GET KEY IN A, IF A == FFh then no KEY
; =========================================================
GET_KEY_A:
    LD  A, (KEY_TIMEOUT)
    CP  0
    JP  Z, RET_KEY
    LD  A, $FF
    RET

RET_KEY:
    LD A, CKEY_TIMEOUT
    LD (KEY_TIMEOUT), A

    LD  A, (KEY_PRESS)
    PUSH  AF
    LD  A, $FF
    LD  (KEY_PRESS), A
    POP  AF
    RET


; =========================================================
; MONITOR Mode
; =========================================================
USER_MODE:
    LD  A, (INPUT)
    CP  $FB
    JP  Z, GO_MONITOR
    
    ; Copy USER_DISPx to DIG_x
    LD	HL, USER_DISP0
	LD	DE, DIG_0
	LD	BC, $0008
	LDIR

    JP  EXIT_SYS

MONITOR_MODE:
    ; Mostra o endereço
    LD  HL, (PC_RAM)
    CALL PRINT_HL

    ; Limpa digitos
    LD  A, 0
    LD  (DIG_4), A
    LD  (DIG_5), A

    ; Mostra os dados no endereço
    LD  HL, (PC_RAM)
    LD  A, (HL)
    CALL  PRINT_A


    CALL  GET_KEY_A

    ; Incrementa endereço
    LD (TMP_KEY), A
    CP  $0A
    JP  Z,  PC_RAM_INC

    ; Decrementa endereço
    LD  A, (TMP_KEY)
    CP  $0B
    JP  Z,  PC_RAM_DEC

    ; Examina memoria
    LD  A, (TMP_KEY)
    CP  $0E
    JP  Z,  GO_EXAMINE

    ; + moDify Memory
    LD  A, (TMP_KEY)
    CP  $0C
    JP  Z,  GO_ADD_MODIFY

    ; moDify Memory
    LD  A, (TMP_KEY)
    CP  $0D
    JP  Z,  GO_MODIFY

    ; RUN
    LD  A, (TMP_KEY)
    CP  $0F
    JP  Z,  FIRE

    ; Show register PC
    LD  A, (TMP_KEY)
    CP  $01
    JP  Z, GO_SHOW_REG_PC

    ; Show register SP
    LD  A, (TMP_KEY)
    CP  $02
    JP  Z, GO_SHOW_REG_SP

    ; Show register AF
    LD  A, (TMP_KEY)
    CP  $03
    JP  Z, GO_SHOW_REG_AF

    ; Show register BC
    LD  A, (TMP_KEY)
    CP  $04
    JP  Z, GO_SHOW_REG_BC

    ; Show register DE
    LD  A, (TMP_KEY)
    CP  $05
    JP  Z, GO_SHOW_REG_DE

    ; Show register HL
    LD  A, (TMP_KEY)
    CP  $06
    JP  Z, GO_SHOW_REG_HL

    ; Show register IX
    LD  A, (TMP_KEY)
    CP  $07
    JP  Z, GO_SHOW_REG_IX

    ; Show register iY
    LD  A, (TMP_KEY)
    CP  $08
    JP  Z, GO_SHOW_REG_IY

    ; Back to user mode
    LD  A, (TMP_KEY)
    CP  $09
    JP  Z, GO_USER_MODE

    JP  EXIT_SYS
    

PC_RAM_DEC:
    LD  HL, (PC_RAM)
    DEC  HL
    LD  (PC_RAM), HL
    JP  EXIT_SYS

PC_RAM_INC:
    LD  HL, (PC_RAM)
    INC  HL
    LD  (PC_RAM), HL
    JP  EXIT_SYS

GO_EXAMINE:
    LD  A, $03
    LD (EXM_COUNT), A        ; Set count 4 digits, position display
    LD  A, $02
    LD (SYSMODE), A          ; Examine mode
    LD A, 01000000b
    LD (DIG_0), A
    LD (DIG_1), A
    LD (DIG_2), A
    LD (DIG_3), A
    JP  EXIT_SYS

GO_ADD_MODIFY:
    LD  HL, (PC_RAM)
    INC HL
    LD  (PC_RAM), HL
    CALL  PRINT_HL
GO_MODIFY:
    LD  A, $01                  ; Set count 2 digits, position display
    LD  (MDF_COUNT), A
    LD  A, $03                  ; moDify mode (Memory)
    LD  (SYSMODE), A
    LD  A, 01000000b
    LD  (DIG_6), A
    LD  (DIG_7), A
    JP  EXIT_SYS

GO_MONITOR:
    CALL  CLEAR_DISPLAY
    LD  A, $01
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_PC:
    CALL CLEAR_DISPLAY
    LD  A, $04
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_SP:
    CALL CLEAR_DISPLAY
    LD  A, $05
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_AF:
    CALL CLEAR_DISPLAY
    LD  A, $06
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_BC:
    CALL CLEAR_DISPLAY
    LD  A, $07
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_DE:
    CALL CLEAR_DISPLAY
    LD  A, $08
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_HL:
    CALL CLEAR_DISPLAY
    LD  A, $09
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_IX:
    CALL CLEAR_DISPLAY
    LD  A, $0A
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_IY:
    CALL CLEAR_DISPLAY
    LD  A, $0B
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_AFaux:
    CALL CLEAR_DISPLAY
    LD  A, $0C
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_BCaux:
    CALL CLEAR_DISPLAY
    LD  A, $0D
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_DEaux:
    CALL CLEAR_DISPLAY
    LD  A, $0E
    LD  (SYSMODE), A
    JP  EXIT_SYS

GO_SHOW_REG_HLaux:
    CALL CLEAR_DISPLAY
    LD  A, $0F
    LD  (SYSMODE), A
    JP  EXIT_SYS

FIRE:
    LD  A, 1
    LD (SYSMODE), A          ; Monitor mode
    LD  HL, (PC_RAM)
    LD  (USR_PC), HL
    JP  EXIT_SYS

GO_USER_MODE:
    LD  A, 0
    LD  (SYSMODE), A
    JP  EXIT_SYS

; =========================================================
; LIMPA DISPLAY
; =========================================================
CLEAR_DISPLAY:
    PUSH  AF
    LD  A, 0
    LD  (DIG_0), A
    LD  (DIG_1), A
    LD  (DIG_2), A
    LD  (DIG_3), A
    LD  (DIG_4), A
    LD  (DIG_5), A
    LD  (DIG_6), A
    LD  (DIG_7), A
    POP  AF
    RET

; =========================================================
; LIMPA USER DISPLAY
; =========================================================
CLEAR_USER_DISPLAY:
    PUSH  AF
    LD  A, 0
    LD  (USER_DISP0), A
    LD  (USER_DISP1), A
    LD  (USER_DISP2), A
    LD  (USER_DISP3), A
    LD  (USER_DISP4), A
    LD  (USER_DISP5), A
    LD  (USER_DISP6), A
    LD  (USER_DISP7), A
    POP  AF
    RET


; =========================================================
; PEGA LOW NUM EM A E RETORNA CHAR 7SEG EM A
; =========================================================
GET_NUM_FROM_LOW:
    PUSH    HL
    PUSH    BC
    LD      HL, LED_FONT
    AND     $0F
    LD      BC, 0
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    POP     BC
    POP     HL
    RET

; =========================================================
; PEGA HIGH NUM EM A E RETORNA CHAR 7SEG EM A
; =========================================================
GET_NUM_FROM_HIGH:
    PUSH    HL
    PUSH    BC
    LD      HL, LED_FONT
    AND     $F0
    RRC     A
    RRC     A
    RRC     A
    RRC     A
    LD      BC, 0
    LD      C, A
    ADD     HL, BC
    LD      A, (HL)
    POP     BC
    POP     HL
    RET

; =========================================================
; Mostra o que esta em A nos digitos 6 e 7
; =========================================================
PRINT_A:
    PUSH    HL
    PUSH    BC
    PUSH    AF
    PUSH    AF

    LD	HL, LED_FONT
    AND $0F
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  (DIG_7), A

    POP    AF
    LD	HL, LED_FONT
    AND  $F0
    RRC  A
    RRC  A
    RRC  A
    RRC  A
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  (DIG_6), A

    POP     AF
    POP     BC
    POP     HL
    RET

; =========================================================
; Mostra o que esta em HL - Display(HHLLXXXX)
; =========================================================
PRINT_HL:
    PUSH  AF
    PUSH  HL
    PUSH  BC

    PUSH  HL
    PUSH  HL
    PUSH  HL

    LD  A, L
    LD	HL, LED_FONT
    AND $0F
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_3
    LD  (HL), A

    POP  HL
    LD  A, L
    LD	HL, LED_FONT
    AND  $F0
    RRC  A
    RRC  A
    RRC  A
    RRC  A
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_2
    LD  (HL), A

    POP  HL
    LD  A, H
    LD	HL, LED_FONT
    AND $0F
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_1
    LD  (HL), A

    POP  HL
    LD  A, H
    LD	HL, LED_FONT
    AND  $F0
    RRC  A
    RRC  A
    RRC  A
    RRC  A
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_0
    LD  (HL), A

    POP  BC
    POP  HL
    POP  AF

    RET

; =========================================================
; Mostra o que esta em HL - Display(XXXXHHLL)
; =========================================================
PRINT_END_HL:
    PUSH  AF
    PUSH  HL
    PUSH  BC

    PUSH  HL
    PUSH  HL
    PUSH  HL

    LD  A, L
    LD	HL, LED_FONT
    AND $0F
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_7
    LD  (HL), A

    POP  HL
    LD  A, L
    LD	HL, LED_FONT
    AND  $F0
    RRC  A
    RRC  A
    RRC  A
    RRC  A
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_6
    LD  (HL), A

    POP  HL
    LD  A, H
    LD	HL, LED_FONT
    AND $0F
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_5
    LD  (HL), A

    POP  HL
    LD  A, H
    LD	HL, LED_FONT
    AND  $F0
    RRC  A
    RRC  A
    RRC  A
    RRC  A
    LD      BC, 0
    LD      C, A
    ADD HL, BC
    LD  A, (HL)
    LD  HL, DIG_4
    LD  (HL), A

    POP  BC
    POP  HL
    POP  AF

    RET

; =========================================================
; Start Sistem ?
; =========================================================
START:
    LD  SP, STACK
    LD  HL, START_RAM
    LD  (PC_RAM), HL

    ; start vars
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A

    LD  A, 1                 ; Monitor mode
    LD  (SYSMODE), A

    LD A, $FF
    LD (KEY_PRESS), A

    IM  1
    EI

    XOR A
    OUT (Port40), A


    LD  A, $00
    LD  (DIG_0), A

    LD  A, $00
    LD  (DIG_1), A

    LD  A, $0
    LD  (DIG_2), A

    LD  A, $00
    LD  (DIG_3), A

    LD  A, $00
    LD  (DIG_4), A

    LD  A, $00
    LD  (DIG_5), A

    LD  A, $00
    LD  (DIG_6), A

    LD  A, $00
    LD  (DIG_7), A

START_LOOP:

    JP START_LOOP









; =========================================================
; Delay
; =========================================================
delay:
	push bc                       ; 2.75 us
    ld b, 255                     ; 1.75 us
delay_loop_b:
	ld c, 255                     ; 1.75 us
delay_loop:
	dec c                         ; 1 us
    jp nz, delay_loop             ; true = 3 us, false 1.75 us
    dec b                         ; 1 us
    jp nz, delay_loop_b           ; true = 3 us, false 1.75 us
    pop bc                        ; 2.50 us
    ret                           ; 2.50 us


;============================================================================
;	Subroutine	Delay_A
;
;	Entry:	A = Millisecond count
;============================================================================
DELAY_A:	PUSH	HL			; Save count
		LD	HL,TicCounter
		ADD	A,(HL)			; A = cycle count
DlyLp		CP	(HL)			; Wait required TicCounter times
		JP	NZ,DlyLp		;  loop if not done
		POP	HL
		RET


DELAY_100mS	LD	C,1
DELAY_C		PUSH	BC
		LD	B,0
DELAY_LP	PUSH	BC
		DJNZ	$		;13   * 256 / 4 = 832uSec
		POP	BC
		DJNZ	DELAY_LP	;~100mSEC
		DEC	C
		JR  NZ,	DELAY_LP	;*4 ~= 7mSec
		POP	BC
		RET

; Mapa char to display 0-F
LED_FONT .db $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $67 ; 0-9
         .DB $77, $7C, $39, $5E, $79, $71                     ; A-F



; ---------------------------------------------------------
; Utilitys Program .ORG 1000h
; ---------------------------------------------------------
.org 1000h
; ---------------------------------------------------------
; RAM MAP - Utilitys Program | $FE00 - $FEFF
; ---------------------------------------------------------
DIEGO      .equ    $FE00   ;(2) Temp Digits to countDown


; ---------------------------------------------------------
; Utilitys Program | CLEAR RAM
; ---------------------------------------------------------
CLEAR_RAM_FF:
    LD  HL, $FE00
    LD  B, $FF
CLEAR_RAM_FF_LOOP:
    DEC HL
    LD (HL), B
    LD A, H
    CP $80
    JP Z, CLEAR_RAM_FF_CHECK_L
    JP CLEAR_RAM_FF_LOOP

CLEAR_RAM_FF_CHECK_L:
    LD A, L
    CP $00
    JP Z, CLEAR_RAM_FF_END
    JP CLEAR_RAM_FF_LOOP
CLEAR_RAM_FF_END:
    LD A, $C3
    LD ($FDFD), A
    XOR A
    LD ($FDFE), A
    LD A, $80
    LD ($FDFF), A
    JP Z, START_LOOP


; ---------------------------------------------------------
; Utilitys Program | BLINKs (teste tempo monitor)
; ---------------------------------------------------------
BLINK_TESTE:
    LD  A, 1
BLINK_TESTE_LOOP:
    XOR 1
    OUT (PortC0), A 
    JP BLINK_TESTE_LOOP


BLINK_DELAY_C:
    LD  A, 1
BLINK_DELAY_C_LOOP:
    XOR 1
    OUT (PortC0), A
    CALL DELAY_100mS
    JP BLINK_DELAY_C_LOOP


BLINK_DELAY_A:
    LD  A, 1
BLINK_DELAY_A_LOOP:
    XOR 1
    OUT (PortC0), A
    PUSH  AF
    LD  A, 100
    CALL DELAY_A
    POP AF
    JP BLINK_DELAY_A_LOOP


; ---------------------------------------------------------
; Utilitys Program | TESTE SOM 
; 
; Key F     = $00 - $FF na saida C0
; Key A e B = Incrementa e Decrementa Saida C0
; ---------------------------------------------------------
TESTE_SOM:
    LD  A, 0
    LD  (SYSMODE), A
    LD  A, 0
    LD  B, A
    CALL CLEAR_USER_DISPLAY
    LD  A, $6D ; S
    LD  (USER_DISP0), A
    LD  A, $3F ; O
    LD  (USER_DISP1), A
    LD  A, $1C ; U
    LD  (USER_DISP2), A
    LD  A, $54 ; N
    LD  (USER_DISP3), A
    LD  A, $5E ; D
    LD  (USER_DISP4), A
LOOP_SOM:
    LD  A, B
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP7), A
    LD  A, B
    CALL GET_NUM_FROM_HIGH
    LD  (USER_DISP6), A

    CALL GET_KEY_A
    CP  $0A
    JP  Z, SOM_INC
    CP  $0B
    JP  Z, SOM_DEC
    CP  $0F
    JP  Z, SOM_LOOP_INC
    JP  LOOP_SOM


SOM_INC:
    INC B
    LD  C, $C0
    OUT (C), B
    CALL DELAY_100mS
    JP  LOOP_SOM

SOM_DEC:
    DEC B
    LD  C, $C0
    OUT (C), B
    CALL DELAY_100mS
    JP  LOOP_SOM

SOM_LOOP_INC:
    LD  A, B
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP7), A
    LD  A, B
    CALL GET_NUM_FROM_HIGH
    LD  (USER_DISP6), A
    INC B
    LD  C, $C0
    OUT (C), B
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP  SOM_LOOP_INC


; ---------------------------------------------------------
; Utilitys Program | Animação led
; ---------------------------------------------------------
ANIMATE_LED1:
    CALL CLEAR_USER_DISPLAY
    LD  A, 0                 ; user mode
    LD (SYSMODE), A

    LD  B, $08
    LD  HL, USER_DISP0
    LD  A, 8

LEDS_LOOP:
    CALL CLEAR_USER_DISPLAY
    LD  (HL), B
    CALL DELAY_100mS
    INC HL
    DEC A
    CP 0
    JP NZ, LEDS_LOOP

    LD A, 8
    LD  HL, USER_DISP7
    LD  B, $40

LEDS_LOOP2:
    CALL CLEAR_USER_DISPLAY
    LD  (HL), B
    CALL DELAY_100mS
    DEC HL
    DEC A
    CP 0
    JP NZ, LEDS_LOOP2

    LD  A, 8
    LD  HL, USER_DISP0
    LD  B, $08
    JP LEDS_LOOP


; ---------------------------------------------------------
; Utilitys Program | CountDown XX
; OBS: Usa a placa de som para o alarme
; ---------------------------------------------------------
COUNT_DOWN_ALERME:
    ; timer count down

    CALL CLEAR_USER_DISPLAY
    LD  A, $39
    LD  (USER_DISP0), A

    LD  A, $3F
    LD  (USER_DISP1), A

    LD  A, $1C
    LD  (USER_DISP2), A

    LD  A, $54
    LD  (USER_DISP3), A

    LD  A, $78
    LD  (USER_DISP4), A

    LD  A, $00
    LD  (USER_DISP5), A



    LD  A, $40
    LD  (USER_DISP6), A

    LD  A, $40
    LD  (USER_DISP7), A

    LD  A, 0                 ; user mode
    LD (SYSMODE), A

READ:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ

    CALL  MODIFY_KEY_POS_1D

READ2
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ2

    CALL MODIFY_KEY_POS_0D

    JP  LOOP


MODIFY_KEY_POS_1D:
    LD  HL, DIEGO
    INC HL
    LD  (HL), A
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP6), A
    RET

MODIFY_KEY_POS_0D:
    LD  HL, DIEGO
    LD  (HL), A
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP7), A
    RET

LOOP:
    LD  HL, (DIEGO)

LOOP_DOWN:
    LD  A, H
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP6), A

    LD  A, L
    CALL GET_NUM_FROM_LOW
    LD  (USER_DISP7), A

    LD C, 7    ; 10 x 100ms = 1seg
    CALL DELAY_C

    LD A, L
    CP 0
    JP Z, DEC_H
    DEC A
    LD L, A
    JP LOOP_DOWN

DEC_H:
    LD  A, H
    CP 0
    JP Z, CHECK_L
    DEC A
    LD H, A
    LD A, 9
    LD L, A
    JP LOOP_DOWN

CHECK_L:
    LD  A, L
    CP 0
    JP Z, BEEP

BEEP:
    LD  A, $80
    OUT  (PortC0), A
    CALL DELAY_100mS

    LD  A, $C0
    OUT  (PortC0), A
    CALL DELAY_100mS
    JP BEEP


; ---------------------------------------------------------
; Utilitys Program | PROGRAM X
; ---------------------------------------------------------





; =========================================================
; Tabela display
; =========================================================
; 
;   0 - $3F     A - $77     K - $7A     U - $1C     . - $80
;   1 - $06     B - $7C     L - $38     V - $3E     Ñ - $55
;   2 - $5B     C - $39     M - $37     W - $1D     : - $41
;   3 - $4F     D - $5E     N - $54     X - $70     ; - $88
;   4 - $66     E - $79     O - $3F     Y - $6E     _ - $08
;   5 - $6D     F - $71     P - $73     Z - $49     ~ - $01
;   6 - $7D     G - $6F     Q - $67                 ' - $20
;   7 - $07     H - $76     R - $50     + - $46     
;   8 - $7F     I - $06     S - $6D     , - $04     
;   9 - $67     J - $1E     T - $78     - - $40     

.end

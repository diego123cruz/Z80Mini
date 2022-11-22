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

; BAUD RATE CONSTANTS
B300:	.EQU	0220H	;300 BAUD
B1200:	.EQU	0080H	;1200 BAUD
B2400:	.EQU	003FH	;2400 BAUD
B4800:	.EQU	001BH	;4800 BAUD - Default
B9600:	.EQU	000BH	;9600 BAUD

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
SHOW_DIG    .equ    $FF0C   ;(1) Atual digito no display
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
                            ; 80 - Modify Any
                            ; 76 - HALT
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
CPU_FLAGS   .equ    $FF2C   ;(1) Flags atual (AF ou AF') SYSMODE
INT_VEC     .equ    $FF2D   ;(2) vector int38

; Serial intel hex loader
BAUD	    .equ	$FF30	;(2) BAUD RATE
PUTCH       .equ    $FF32   ;(2) OUTPUT A CHARACTER TO SERIAL
GETCH       .equ    $FF34   ;(2) WAIT FOR A CHARACTER FROM SERIAL


; Copy USER_DISPx to DIG_x WHEN USER_MODE
USER_DISP0  .equ    $FFD0   ; Mode User - Display Dig 0  - 01234567
USER_DISP1  .equ    $FFD1   ; Mode User - Display Dig 1  - 01234567
USER_DISP2  .equ    $FFD2   ; Mode User - Display Dig 2  - 01234567
USER_DISP3  .equ    $FFD3   ; Mode User - Display Dig 3  - 01234567
USER_DISP4  .equ    $FFD4   ; Mode User - Display Dig 4  - 01234567
USER_DISP5  .equ    $FFD5   ; Mode User - Display Dig 5  - 01234567
USER_DISP6  .equ    $FFD6   ; Mode User - Display Dig 6  - 01234567
USER_DISP7  .equ    $FFD7   ; Mode User - Display Dig 7  - 01234567

LAST_SYS    .equ    $FFD8   ; (1) Last SYSMODE
ISR_MD_HL   .equ    $FFDC   ; (2) endereço do registrador para alterar
ISR_MD_TMP  .equ    $FFDE   ; (2) data register temp


; =========================================================
; Start ROM
; =========================================================
.org    $0000
    LD  HL, INT38
    LD  (INT_VEC), HL
    JP  START


; =========================================================
; Int 38h - Monitor 
; =========================================================
.org    $38
    DI
    LD (USR_HL), HL          ; Save HL
    LD HL, (INT_VEC)
    JP (HL)

INT_ERROR:
    DI
    PUSH AF
    PUSH HL

    LD  HL, INT38
    LD  (INT_VEC), HL

    LD A, $99
    LD (SYSMODE), A

    POP HL
    POP AF
    
    JP START_WARM

INT_HALT:
    DI
    PUSH AF
    PUSH HL

    LD  HL, INT38
    LD  (INT_VEC), HL

    LD A, $76
    LD (SYSMODE), A

    POP HL
    POP AF
    
    JP START_WARM


INT38:
    LD (USR_SP), SP          ; Save SP
    ;LD (USR_HL), HL          ; Save HL
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

    ; check HALT
    LD HL, (USR_SP)
    CALL LD_HL_HL
    DEC HL
    LD  A, (HL)
    CP  $76    ; halt code
    JP  Z, C_HALT
    jp SKIP_CHK

C_HALT:
    LD HL, INT_HALT
    LD (INT_VEC), HL

    LD A, $76
    LD  (SYSMODE), A

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

    EI
    HALT                     ; aguarda proxima int

SKIP_CHK:
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
    CALL UPDATE_FLAGS

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

    LD IX, (USR_IX)          ; Recovery IX
    LD IY, (USR_IY)          ; Recovery IY

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
; Update Flags - Tratamento Int 38h
; =========================================================
UPDATE_FLAGS:
    LD    A, (SYSMODE)
    CP    $06
    JP    Z, UPDATE_FLAGS_MAIN
    CP    $0C
    JP    Z, UPDATE_FLAGS_MAIN
UPDATE_FLAGS_RET:
    RET

UPDATE_FLAGS_MAIN:
    LD    A, (INPUT)
    AND   $07

    CP    $07
    JP    Z, UPDATE_FLAG_S
    CP    $00
    JP    Z, UPDATE_FLAG_Z
    CP    $01
    JP    Z, UPDATE_FLAG_X1
    CP    $02
    JP    Z, UPDATE_FLAG_H
    CP    $03
    JP    Z, UPDATE_FLAG_X2
    CP    $04
    JP    Z, UPDATE_FLAG_PV
    CP    $05
    JP    Z, UPDATE_FLAG_N
    CP    $06
    JP    Z, UPDATE_FLAG_C
    JP    UPDATE_FLAGS_RET

UPDATE_FLAG_S:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 7, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_Z:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 6, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_X1:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 5, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_H:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 4, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_X2:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 3, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_PV:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 2, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_N:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 1, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

UPDATE_FLAG_C:
    CALL  SHOW_DIG_FLAG_ON
    LD  A, (CPU_FLAGS)
    BIT 0, A
    CALL Z, SHOW_DIG_FLAG_OFF
    RET

SHOW_DIG_FLAG_ON:
    LD  A, (SHOW_DIG)
    OR  $80
    LD  (SHOW_DIG), A
    RET

SHOW_DIG_FLAG_OFF:
    LD  A, (SHOW_DIG)
    AND  $7F
    LD  (SHOW_DIG), A 
    RET

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


    LD  A, (SYSMODE)        ; Show HALT
    CP  $76
    JP  Z, SHOW_HALT

    LD  A, (SYSMODE)        ; Modify Any
    CP  $80
    JP  Z, MD_HL


    LD  A, (SYSMODE)        ; Show ERROR
    CP  $99
    JP  Z, SHOW_ERROR

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    LD  A, $73               ; P
    LD  (DIG_0), A

    LD  A, $39
    LD  (DIG_1), A           ; C

    LD HL, (USR_PC)
    CALL PRINT_END_HL

    LD HL, USR_PC
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    CALL  CLEAR_DISPLAY

    LD  A, $6D               ; S
    LD  (DIG_0), A

    LD  A, $73               ; P
    LD  (DIG_1), A

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $77               ; A
    LD  (DIG_0), A

    LD  A, $71               ; F
    LD  (DIG_1), A

    LD  HL, (USR_AF)
    LD  A, L
    LD (CPU_FLAGS), A
    CALL PRINT_END_HL

    LD HL, USR_AF
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY



    CALL  CLEAR_DISPLAY

    LD  A, $7C               ; B
    LD  (DIG_0), A

    LD  A, $39               ; C
    LD  (DIG_1), A

    LD HL, (USR_BC)
    CALL PRINT_END_HL

    LD HL, USR_BC
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $5E               ; D
    LD  (DIG_0), A

    LD  A, $79               ; E
    LD  (DIG_1), A

    LD HL, (USR_DE)
    CALL PRINT_END_HL

    LD HL, USR_DE
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $76               ; H
    LD  (DIG_0), A

    LD  A, $38               ; L
    LD  (DIG_1), A

    LD HL, (USR_HL)
    CALL PRINT_END_HL

    LD HL, USR_HL
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $06               ; I
    LD  (DIG_0), A

    LD  A, $70               ; X
    LD  (DIG_1), A

    LD HL, (USR_IX)
    CALL PRINT_END_HL

    LD HL, USR_IX
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $06               ; I
    LD  (DIG_0), A

    LD  A, $6E               ; Y
    LD  (DIG_1), A

    LD HL, (USR_IY)
    CALL PRINT_END_HL

    LD HL, USR_IY
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY


    LD  A, $77               ; A
    LD  (DIG_0), A

    LD  A, $71               ; F
    LD  (DIG_1), A

    LD  A, $20               ; '
    LD  (DIG_2), A

    LD HL, (USR_AFA)
    LD  A, L
    LD (CPU_FLAGS), A
    CALL PRINT_END_HL

    LD HL, USR_AFA
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY


    LD  A, $7C               ; B
    LD  (DIG_0), A

    LD  A, $39               ; C
    LD  (DIG_1), A

    LD  A, $20               ; '
    LD  (DIG_2), A

    LD HL, (USR_BCA)
    CALL PRINT_END_HL

    LD HL, USR_BCA
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $5E               ; D
    LD  (DIG_0), A

    LD  A, $79               ; E
    LD  (DIG_1), A

    LD  A, $20               ; '
    LD  (DIG_2), A

    LD HL, (USR_DEA)
    CALL PRINT_END_HL

    LD HL, USR_DEA
    LD (ISR_MD_HL), HL

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

    ; RUN
    CP  $0F
    JP  Z,  FIRE

    ; Modify
    CP  $0D
    JP  Z,  MODIFY_ANY

    CALL  CLEAR_DISPLAY

    LD  A, $76               ; H
    LD  (DIG_0), A

    LD  A, $38               ; L
    LD  (DIG_1), A

    LD  A, $20               ; '
    LD  (DIG_2), A

    LD HL, (USR_HLA)
    CALL PRINT_END_HL

    LD HL, USR_HLA
    LD (ISR_MD_HL), HL

    JP  EXIT_SYS

SHOW_HALT:
    LD  A, (INPUT)
    CP  $FB
    JP  Z, GO_MONITOR

    LD  A, $40               ; -
    LD  (DIG_0), A
    LD  (DIG_1), A

    LD  A, $76               ; H
    LD  (DIG_2), A

    LD  A, $77               ; A
    LD  (DIG_3), A

    LD  A, $38               ; L
    LD  (DIG_4), A

    LD  A, $78               ; T
    LD  (DIG_5), A

    LD  A, $40               ; -
    LD  (DIG_6), A
    LD  (DIG_7), A

    JP EXIT_SYS

SHOW_ERROR:
    LD  A, (INPUT)
    CP  $FB
    JP  Z, GO_MONITOR

    LD  A, $79               ; E
    LD  (DIG_0), A

    LD  A, $50               ; R
    LD  (DIG_1), A

    LD  A, $50               ; R
    LD  (DIG_2), A

    LD  A, $3F               ; O
    LD  (DIG_3), A

    LD  A, $50               ; R
    LD  (DIG_4), A

    LD  A, $0               ; ''
    LD  (DIG_5), A           
    LD  (DIG_6), A
    LD  (DIG_7), A

    JP EXIT_SYS

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
    ;LD  A, 1
    ;LD (SYSMODE), A          ; Monitor mode
    LD  HL, (PC_RAM)
    LD  (USR_PC), HL
    JP  EXIT_SYS

MODIFY_ANY:
    ;;CALL CLEAR_DISPLAY

    LD  A, $03
    LD (EXM_COUNT), A        ; Set count 4 digits, position display

    LD A, 00000000b
    LD (DIG_2), A
    LD (DIG_3), A
    LD A, 01000000b
    LD (DIG_4), A
    LD (DIG_5), A
    LD (DIG_6), A
    LD (DIG_7), A

    LD  A, (SYSMODE)
    LD (LAST_SYS), A

    LD  A, $80
    LD  (SYSMODE), A
    JP EXIT_SYS



GO_USER_MODE:
    LD  A, 0
    LD  (SYSMODE), A
    JP  EXIT_SYS


; =========================================================
; Modify (HL)
; =========================================================
MD_HL:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, EXIT_SYS

    PUSH  AF
    PUSH  AF
    LD  A, (EXM_COUNT)
    CP  3
    JP  Z, MD_HL_KEY_POS_3

    LD  A, (EXM_COUNT)
    CP  2
    JP  Z, MD_HL_KEY_POS_2

    LD  A, (EXM_COUNT)
    CP  1
    JP  Z, MD_HL_KEY_POS_1

    LD  A, (EXM_COUNT)
    CP  0
    JP  Z, MD_HL_KEY_POS_0

    JP  EXIT_SYS

MD_HL_KEY_POS_3:
    POP  AF
    RLC  A
    RLC  A
    RLC  A
    RLC  A
    LD  H, A
    LD  (ISR_MD_TMP), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_4), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS


MD_HL_KEY_POS_2:
    POP  AF
    LD  HL, (ISR_MD_TMP)
    OR  H
    LD  H, A
    LD  (ISR_MD_TMP), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_5), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS

MD_HL_KEY_POS_1:
    POP  AF
    LD  HL, (ISR_MD_TMP)
    RLC  A
    RLC  A
    RLC  A
    RLC  A
    LD  L, A
    LD  (ISR_MD_TMP), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_6), A
    LD  A, (EXM_COUNT)
    DEC A
    LD  (EXM_COUNT), A
    JP  EXIT_SYS


MD_HL_KEY_POS_0:
    POP  AF
    LD  HL, (ISR_MD_TMP)
    OR  L
    LD  L, A
    LD  (ISR_MD_TMP), HL
    POP  AF
    CALL GET_NUM_FROM_LOW
    LD  (DIG_7), A


    LD DE, (ISR_MD_HL) ; endereço de memoria do registrador
    LD HL, (ISR_MD_TMP) ; dados

    LD A, L
    LD (DE), A
    INC DE
    LD A, H
    LD (DE), A

    LD  A, (LAST_SYS)
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

    ; if Moni Back(Reset + Press), then Loader Intel Hex
    IN A, (Port40)
    BIT 5, A
    CALL NZ, START_INTEL


    LD  A, 1                 ; Monitor mode
    LD  (SYSMODE), A







;LOOP:
;   INC A
;   JP NZ, LOOP
;   INC BC
;   JP LOOP

    LD A, $3C
    LD ($8000), A

    LD A, $C2
    LD ($8001), A

    LD A, $00
    LD ($8002), A

    LD A, $80
    LD ($8003), A

    LD A, $03
    LD ($8004), A

    LD A, $C3
    LD ($8005), A

    LD A, $00
    LD ($8006), A

    LD A, $80
    LD ($8007), A









START_COM:
    LD  HL, START_RAM
    LD  (PC_RAM), HL

    ; start vars
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A

    LD A, $FF
    LD (KEY_PRESS), A

    LD  A, $00
    LD  (DIG_0), A
    LD  (DIG_1), A
    LD  (DIG_2), A
    LD  (DIG_3), A
    LD  (DIG_4), A
    LD  (DIG_5), A
    LD  (DIG_6), A
    LD  (DIG_7), A

    IM  1
    EI

    XOR A
    OUT (Port40), A

START_LOOP:
    JP START_LOOP

START_WARM:
    LD  SP, STACK

    JP START_COM


; =========================================================
; HL = (HL)
; =========================================================
LD_HL_HL:
	LD      A,(HL)		;7
	INC     HL		;6
	LD      H,(HL)		;7
	LD      L,A		;4
	RET			;10

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
;   FFFFFFFF      I     MM           MM
;   F             I     M  M       M  M
;   F             I     M    M   M    M
;   FFFFFFF       I     M      M      M
;   F             I     M             M
;   F             I     M             M
;   F             I     M             M
;
; ---------------------------------------------------------


; ---------------------------------------------------------
;
;   SERIAL INTEL HEX LOADDER
;
;   Serial 4800-N-8-1
;
; ---------------------------------------------------------
START_INTEL:
    DI

    LD	HL, B4800
	LD	(BAUD),HL	;DEFAULT SERIAL=4800 BAUD

    LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE

    LD    HL,INITSZ  ;VT100 TERMINAL COMMANDS FOR CLEAR SCREEN,CURSOR HOME
    CALL  SNDMSG     ;INITIALISE THE TERMINAL
    
    LD    HL,SIGNON
    CALL  SNDMSG     ;SEND THE SIGNON

    CALL INTELFN
    RET

INTEL_ERROR:
    LD HL, INT_ERROR
    LD (INT_VEC), HL
    IM 1
    EI

INTEL_ERROR_LOOP:
    LD A, $0
    OUT (Port40), a
    JP INTEL_ERROR_LOOP

INTEL_SUCCESS:
    IM 1
    EI
    RET

;-----------------------------------
; OUTPUT A CHARACTER TO THE TERMINAL
;-----------------------------------       
OUTCH:  LD   IX,(PUTCH)
       JP   (IX)
;------------------------------------
; INPUT A CHARACTER FROM THE TERMINAL
;------------------------------------
INCH:  LD   IX,(GETCH)
      JP   (IX)

;------------
; ASCII CODES
;------------
ESC:    .EQU   1BH
CR:     .EQU   0DH
LF:     .EQU   0AH


;-=========================== INTEL

;------------------------------------
; FUNCTION 1 RECEIVE INTEL HEX FORMAT
;------------------------------------
INTELFN:
    CALL  INTELH
    JP    NZ, INTEL_ERROR      ;SHOW THE ERROR 

    LD    HL,SUCCESS
    CALL  SNDMSG     ;SEND THE SUCCESS

    JP    INTEL_SUCCESS        ;JUST RETURN IF ALL OK
;-----------------------
; RECEIVE INTEL HEX FILE
;-----------------------
INTELH:	LD	IX,STACK	;POINT TO SYSTEM VARIABLES
;
; WAIT FOR RECORD MARK
;
INTEL1:	XOR	A
	LD	(IX+3),A	;CLEAR CHECKSUM
	CALL	RXDATA	;WAIT FOR THE RECORD MARK
	CP	':'	;TO BE TRANSMITTED
	JR	NZ,INTEL1	;NOT RECORD MARK

;
; GET RECORD LENGTH
;
	CALL	GETBYT
	LD	(IX+0),A	;NUMBER OF DATA BYTES
;
; GET ADDRESS FIELD
;
	CALL	GETBYT
	LD	(IX+2),A	;LOAD ADDRESS HIGH BYTE
	CALL	GETBYT
	LD	(IX+1),A	;LOAD ADDRESS LOW BYTE
;
; GET RECORD TYPE
;
	CALL	GETBYT
	JR	NZ,INTEL4	;END OF FILE RECORD
;
; READ IN THE DATA
;
	LD	B,(IX+0)	;NUMBER OF DATA BYTES
	LD	H,(IX+2)	;LOAD ADDRESS HIGH BYTE
	LD	L,(IX+1)	;LOAD ADDRESS LOW BYTE

INTEL2:	CALL	GETBYT	;GET DATA BYTE
	LD	(HL),A	;STORE DATA BYTE
	INC	HL
	DJNZ	INTEL2	;LOAD MORE BYTES
;
; GET CHECKSUM AND COMPARE
;
	LD	A,(IX+3)	;CONVERT CHECKSUM TO
	NEG		;TWO'S COMPLEMENT
	LD	(IX+4),A	;SAVE COMPUTED CHECKSUM
	CALL	GETBYT
	LD	(IX+3),A	;SAVE RECORD CHECKSUM
	CP	(IX+4)	;COMPARE CHECKSUM
	JR	Z,INTEL1	;CHECKSUM OK,NEXT RECORD
    RET             ;NZ=CHECKSUM ERROR
;
; END OF FILE RECORD
;
INTEL4:	LD	A,(IX+3)	;CONVERT CHECKSUM TO
	NEG		;TWO'S COMPLEMENT
	LD	(IX+4),A	;SAVE COMPUTED CHECKSUM
	CALL	GETBYT
	LD	(IX+3),A	;SAVE EOF CHECKSUM
	CP	(IX+4)	;COMPARE CHECKSUM
	RET  	    ;NZ=CHECKSUM ERROR

;--------------------------
; GET BYTE FROM SERIAL PORT
;--------------------------
GETBYT:	PUSH	BC
	CALL	RXDATA
	BIT	6,A
	JR	Z,GETBT1
	ADD	A,09H
GETBT1:	AND	0FH
	SLA 	A
	SLA	A
	SLA	A
	SLA	A
	LD	C,A
;
; GET LOW NYBBLE
;
	CALL	RXDATA
	BIT	6,A
	JR	Z,GETBT2
	ADD	A,09H
GETBT2:	AND	0FH
	OR	C
	LD	B,A
	ADD	A,(IX+3)
	LD	(IX+3),A	;ADD TO CHECKSUM
	LD	A,B
	AND	A	;CLEAR CARRY
    POP	BC
	RET

;=========================== INTEL FIM


;-----------------------------------------
; SEND AN ASCII STRING OUT THE SERIAL PORT
;-----------------------------------------
; 
; SENDS A ZERO TERMINATED STRING OR 
; 128 CHARACTERS MAX. OUT THE SERIAL PORT
;
;      ENTRY : HL = POINTER TO 00H TERMINATED STRING
;      EXIT  : NONE
;
;       MODIFIES : A,B,C
;          
SNDMSG: LD    B,128         ;128 CHARS MAX
SDMSG1: LD    A,(HL)        ;GET THE CHAR
       CP    00H          ;ZERO TERMINATOR?
       JR    Z,SDMSG2      ;FOUND A ZERO TERMINATOR, EXIT  
       CALL  OUTCH         ;TRANSMIT THE CHAR
       INC   HL
       DJNZ  SDMSG1        ;128 CHARS MAX!    
SDMSG2: RET

;-----------------
; ONE SECOND DELAY
;-----------------
;
; ENTRY : NONE
; EXIT : FLAG REGISTER MODIFIED
;
DELONE:	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	DE,0001H
	LD	HL,0870H
DELON1:	LD	B,92H
DELON2:	DJNZ	DELON2	;INNER LOOP
	SBC	HL,DE
	JP	NC,DELON1	;OUTER LOOP
	POP	HL
	POP	DE
	POP	BC
	RET

;------------------------
; SERIAL TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TXDATA:	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD	HL,(BAUD)
	LD	C,A
;
; TRANSMIT START BIT
;
	XOR	A
	OUT	(Port40),A
	CALL	BITIME
;
; TRANSMIT DATA
;
	LD	B,08H
	;RRC	C
NXTBIT:	RRC	C	;SHIFT BITS TO D6,
	LD	A,C	;LSB FIRST AND OUTPUT
	AND	80H	;THEM FOR ONE BIT TIME.
	OUT	(Port40),A
	CALL	BITIME
	DJNZ	NXTBIT
;
; SEND STOP BITS
;
	LD	A,80H
	OUT	(Port40),A
	CALL	BITIME
	CALL	BITIME
	POP	HL
	POP	BC
	POP	AF
	RET

;-----------------------
; SERIAL RECEIVE ROUTINE
;-----------------------
;RECEIVE SERIAL BYTE FROM DIN
;
; ENTRY : NONE
;  EXIT : A= RECEIVED BYTE IF CARRY CLEAR
;
; REGISTERS MODIFIED A AND F
;
RXDATA:	PUSH	BC
	PUSH	HL
;
; WAIT FOR START BIT 
;
RXDAT1: IN	A,(Port40)
;        IN	A,(KEYBUF)
	    BIT	6,A
	    JR	NZ,RXDAT1	;NO START BIT
;
; DETECTED START BIT
;
	LD	HL,(BAUD)
	SRL	H
	RR	L 	;DELAY FOR HALF BIT TIME
	CALL 	BITIME
	IN	A,(Port40)
;    IN	A,(KEYBUF)
	BIT	6,A
	JR	NZ,RXDAT1	;START BIT NOT VALID
;
; DETECTED VALID START BIT,READ IN DATA
;
	LD	B,08H
RXDAT2:	LD	HL,(BAUD)
	CALL	BITIME	;DELAY ONE BIT TIME
	IN	A,(Port40)
;    IN	A,(KEYBUF)
	RL	A
    RL	A
	RR	C	;SHIFT BIT INTO DATA REG
	DJNZ	RXDAT2
	LD	A,C
	OR	A	;CLEAR CARRY FLAG
    POP	HL
	POP	BC
	RET
;---------------
; BIT TIME DELAY
;---------------
;DELAY FOR ONE SERIAL BIT TIME
;ENTRY : HL = DELAY TIME
; NO REGISTERS MODIFIED
;
BITIME:	PUSH	HL
	PUSH	DE
	LD	DE,0001H
BITIM1:	SBC	HL,DE
	JP	NC,BITIM1
	POP	DE
	POP	HL
	RET


SIGNON:      .DB     CR,LF,"Load intel hex...",CR,LF,00H
SUCCESS:      .DB    "Load success... ",CR,LF,00H
INITSZ:      .DB     27,"[H",27,"[2J",00H

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

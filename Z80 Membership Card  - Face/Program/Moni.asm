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


CR		.EQU	0DH
LF		.EQU	0AH
ESC		.EQU	1BH
CTRLC	.EQU	03H
CLS		.EQU	0CH


; SIO/2 - 115200
SIOA_D		.EQU	$00
SIOA_C		.EQU	$02
SIOB_D		.EQU	$01 ; Não usado
SIOB_C		.EQU	$03 ; Não usado

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
RST00:
    JP ORG_0

;------------------------------------------------------------------------------
; TX a character over RS232 wait for TXDONE first.
;------------------------------------------------------------------------------
    .ORG $0008
RST08:	JP	conout

;------------------------------------------------------------------------------
; RX a character from buffer wait until char ready.
;------------------------------------------------------------------------------
    .ORG $0010
RST10:		JP	conin

; =========================================================
; Int 38h - Monitor 
; =========================================================
.org    $38
    DI
    LD (USR_HL), HL          ; Save HL
    LD HL, (INT_VEC)
    JP (HL)


ORG_0:
    LD  HL, INT38
    LD  (INT_VEC), HL
    JP  START




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


    ;	Initialise SIO/2 A
	LD	A,$04
	OUT	(SIOA_C),A
	LD	A,$C4
	OUT	(SIOA_C),A

	LD	A,$03
	OUT	(SIOA_C),A
	LD	A,$E1
	OUT	(SIOA_C),A

	LD	A,$05
	OUT	(SIOA_C),A
	LD	A, $68
	OUT	(SIOA_C),A

    LD HL, msg_bemvindo
    CALL PRINT

    LD  A, 1                 ; Monitor mode
    LD  (SYSMODE), A

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

monitor:
	LD HL, monitor ; point to return to monitor
	PUSH HL
monitor0:
	CALL TXCRLF	; Entry point for Monitor, Normal	
	LD   A,'>'	; Get a ">"	
	RST 08H		; print it

monitor1:
	RST 10H	; Get a character from serial
	CP   ' '	; <spc> or less? 	
	JR   C, monitor1	; Go back

	CP   ':'	; ":"?
	JP   Z,LOAD	; First character of a HEX load

	RST 08H	; Print char on console

	CP   '?'
	JP   Z,HELP

	AND  $5F	; Make character uppercase

	CP   'R' 	; reset
	JP   Z, RST00

	CP   'G'
	JP   Z,GOTO

	LD   A,'?'	; Get a "?"	
	RST 08H		; Print it

    jp monitor0

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

; GOTO command
GOTO:
	CALL GETHL		; ENTRY POINT FOR <G>oto addr. Get XXXX from user.
	RET  C			; Return if invalid       	
	PUSH HL
	RET			; Jump to HL address value


; HELP
HELP:
	LD HL, msg_help
	CALL PRINT
	RET


;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
PRINT:  LD   A,(HL)	; Get character
		OR   A		; Is it $00 ?
		RET  Z		; Then RETurn on terminator
		RST  08H	; Print it
		INC  HL		; Next Character
		JR   PRINT	; Continue until $00

TXCRLF:	LD   A,$0D	; 
		RST  08H	; Print character 
		LD   A,$0A	; 
		RST  08H	; Print character
		RET

;------------------------------------------------------------------------------
; Console output routine - Serial
; Output port to send a character.
;------------------------------------------------------------------------------
conout:		PUSH	AF		; Store character
conoutA1:	CALL	CKSIOA		; See if SIO channel A is finished transmitting
		JR	Z, conoutA1	; Loop until SIO flag signals ready
		POP	AF		; RETrieve character
		OUT	(SIOA_D),A	; OUTput the character
		RET

conin:
waitForChar:
	; Check if there is a char in channel A
	SUB	A
	OUT 	(SIOA_C),A
	IN   	A,(SIOA_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
	RRCA			; Rotates RX status into Carry Flag,	
	JR	NC, waitForChar
	IN	A,(SIOA_D)
	OR A ; clear carry
	RET
	

CKSIOA:
		SUB	A
		OUT 	(SIOA_C),A
		IN   	A,(SIOA_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		BIT  	1,A		; Set Zero flag if still transmitting character	
        RET


;------------------------------------------------------------------------------
; Get a character from the console, must be $20-$7F to be valid (no control characters)
; <Ctrl-c> and <SPACE> breaks with the Zero Flag set
;------------------------------------------------------------------------------	
GETCHR	RST 10H	; RX a Character
		CP   $03	; <ctrl-c> User break?
		RET  Z			
		CP   $20	; <space> or better?
		JR   C,GETCHR	; Do it again until we get something usable
		RET

;------------------------------------------------------------------------------
; Gets two ASCII characters from the console (assuming them to be HEX 0-9 A-F)
; Moves them into B and C, converts them into a byte value in A and updates a
; Checksum value in E
;------------------------------------------------------------------------------
GET2	CALL GETCHR	; Get us a valid character to work with
		LD   B,A	; Load it in B
		CALL GETCHR	; Get us another character
		LD   C,A	; load it in C
		CALL BCTOA	; Convert ASCII to byte
		LD   C,A	; Build the checksum
		LD   A,E
		SUB  C		; The checksum should always equal zero when checked
		LD   E,A	; Save the checksum back where it came from
		LD   A,C	; Retrieve the byte and go back
		RET

;------------------------------------------------------------------------------
; Gets four Hex characters from the console, converts them to values in HL
;------------------------------------------------------------------------------
GETHL		LD   HL,$0000	; Gets xxxx but sets Carry Flag on any Terminator
		CALL ECHO	; RX a Character
		CP   $0D	; <CR>?
		JR   NZ,GETX2	; other key		
SETCY		SCF		; Set Carry Flag
		RET             ; and Return to main program		
;------------------------------------------------------------------------------
; This routine converts last four hex characters (0-9 A-F) user types into a value in HL
; Rotates the old out and replaces with the new until the user hits a terminating character
;------------------------------------------------------------------------------
GETX		LD   HL,$0000	; CLEAR HL
GETX1		CALL ECHO	; RX a character from the console
		CP   $0D	; <CR>
		RET  Z		; quit
		CP   $2C	; <,> can be used to safely quit for multiple entries
		RET  Z		; (Like filling both DE and HL from the user)
GETX2		CP   $03	; Likewise, a <ctrl-C> will terminate clean, too, but
		JR   Z,SETCY	; It also sets the Carry Flag for testing later.
		ADD  HL,HL	; Otherwise, rotate the previous low nibble to high
		ADD  HL,HL	; rather slowly
		ADD  HL,HL	; until we get to the top
		ADD  HL,HL	; and then we can continue on.
		SUB  $30	; Convert ASCII to byte	value
		CP   $0A	; Are we in the 0-9 range?
		JR   C,GETX3	; Then we just need to sub $30, but if it is A-F
		SUB  $07	; We need to take off 7 more to get the value down to
GETX3		AND  $0F	; to the right hex value
		ADD  A,L	; Add the high nibble to the low
		LD   L,A	; Move the byte back to A
		JR   GETX1	; and go back for next character until he terminates
;------------------------------------------------------------------------------
; Convert ASCII characters in B C registers to a byte value in A
;------------------------------------------------------------------------------
BCTOA		LD   A,B	; Move the hi order byte to A
		SUB  $30	; Take it down from Ascii
		CP   $0A	; Are we in the 0-9 range here?
		JR   C,BCTOA1	; If so, get the next nybble
		SUB  $07	; But if A-F, take it down some more
BCTOA1		RLCA		; Rotate the nybble from low to high
		RLCA		; One bit at a time
		RLCA		; Until we
		RLCA		; Get there with it
		LD   B,A	; Save the converted high nybble
		LD   A,C	; Now get the low order byte
		SUB  $30	; Convert it down from Ascii
		CP   $0A	; 0-9 at this point?
		JR   C,BCTOA2	; Good enough then, but
		SUB  $07	; Take off 7 more if it's A-F
BCTOA2		ADD  A,B	; Add in the high order nybble
		RET

;------------------------------------------------------------------------------
; Get a character and echo it back to the user
;------------------------------------------------------------------------------
ECHO	RST 10H ; rx
		RST 08H ; tx
		RET




;------------------------------------------------------------------------------
; LOAD Intel Hex format file from the console.
; [Intel Hex Format is:
; 1) Colon (Frame 0)
; 2) Record Length Field (Frames 1 and 2)
; 3) Load Address Field (Frames 3,4,5,6)
; 4) Record Type Field (Frames 7 and 8)
; 5) Data Field (Frames 9 to 9+2*(Record Length)-1
; 6) Checksum Field - Sum of all byte values from Record Length to and 
;   including Checksum Field = 0 ]
;------------------------------------------------------------------------------	
LOAD:	LD   E,0	; First two Characters is the Record Length Field
		CALL GET2	; Get us two characters into BC, convert it to a byte <A>
		LD   D,A	; Load Record Length count into D
		CALL GET2	; Get next two characters, Memory Load Address <H>
		LD   H,A	; put value in H register.
		CALL GET2	; Get next two characters, Memory Load Address <L>
		LD   L,A	; put value in L register.
		CALL GET2	; Get next two characters, Record Field Type
		CP   $01	; Record Field Type 00 is Data, 01 is End of File
		JR   NZ,LOAD2	; Must be the end of that file
		CALL GET2	; Get next two characters, assemble into byte
		LD   A,E	; Recall the Checksum byte
		AND  A		; Is it Zero?
		JR   Z,LOAD00	; Print footer reached message
		JR   LOADERR	; Checksums don't add up, Error out
		
LOAD2		LD   A,D	; Retrieve line character counter	
		AND  A		; Are we done with this line?
		JR   Z,LOAD3	; Get two more ascii characters, build a byte and checksum
		CALL GET2	; Get next two chars, convert to byte in A, checksum it
		LD   (HL),A	; Move converted byte in A to memory location
		INC  HL		; Increment pointer to next memory location	
		LD   A,'.'	; Print out a "." for every byte loaded
		RST  08H	;
		DEC  D		; Decrement line character counter
		JR   LOAD2	; and keep loading into memory until line is complete
		
LOAD3		CALL GET2	; Get two chars, build byte and checksum
		LD   A,E	; Check the checksum value
		AND  A		; Is it zero?
		RET  Z

LOADERR		LD   HL,CKSUMERR  ; Get "Checksum Error" message
		CALL PRINT	; Print Message from (HL) and terminate the load
		RET

LOAD00  	LD   HL,LDETXT	; Print load complete message
		CALL PRINT
		RET


msg_bemvindo:   .db CR, LF, "Z80 Mini - Z80 Membership Card - Face", CR, LF, "? to Help", CR, LF, 0
msg_help:
		.BYTE	CR, LF
		.TEXT	"R           - Reset"
		.BYTE	CR, LF
		.TEXT	"G           - Goto nnnn"
		.BYTE	CR, LF
		.TEXT	":nnnnnn...  - Load Intel-Hex file record"
		.BYTE	CR, LF
        .BYTE   $00

CKSUMERR:
		.BYTE	"Checksum error"
		.BYTE	CR, LF,$00

LDETXT:
		.TEXT	"Load complete."
		.BYTE	CR, LF, $00


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

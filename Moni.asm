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
START_RAM     .equ    $8000
STACK         .equ    $E000  ; Temporario, reorganizar!!!
CKEY_TIMEOUT  .equ    100  ; 100ms

; ---------------------------------------------------------
; RAM MAP - Temporario, reorganizar!!!
; ---------------------------------------------------------

; Cada digito fica em um ponto da memoria RAM
DIG_0       .equ    $9001   ;(1) endereço do digito 0 na memoria RAM
DIG_1       .equ    $9002   ;(1) endereço do digito 1 na memoria RAM
DIG_2       .equ    $9003   ;(1) endereço do digito 2 na memoria RAM
DIG_3       .equ    $9004   ;(1) endereço do digito 3 na memoria RAM
DIG_4       .equ    $9005   ;(1) endereço do digito 4 na memoria RAM
DIG_5       .equ    $9006   ;(1) endereço do digito 5 na memoria RAM
DIG_6       .equ    $9007   ;(1) endereço do digito 6 na memoria RAM
DIG_7       .equ    $9008   ;(1) endereço do digito 7 na memoria RAM

KEY_PRESS   .equ    $9009   ;(1) key atual
INPUT       .equ    $900A   ;(1) temp input from int
TMP_KEY     .equ    $900B   ;(1) tmp key
KEY_TIMEOUT .equ    $900C   ;(1) tempo para retornar a tecla, CKEY_TIMEOUT

PC_RAM      .equ    $9100   ;(2) save pc to user start $8000
SYSMODE     .equ    $9102   ;(1) System mode. 
                            ; 0 - Monitor
                            ; 1 - Examine Memoria
                            ; 2 - Change Data(Memory)
                            ; 3 - Registers - Choice
                            ; 4 - Register - SHOW (REG_INDEX)
EXM_COUNT   .equ    $9103   ;(1) Count digits Examine function, 4 digits
MDF_COUNT   .equ    $9104   ;(1) Count digits moDify function, 2 digits
USR_PC      .equ    $9105   ;(2) PC 
REG_INDEX   .equ    $9107   ;(1) Indice do registro que esta na tela



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
    DI
    EX  AF, AF'
    EXX

    POP HL
    LD  (USR_PC), HL

    CALL    TRATAMENTO_INT38H   
    JP      SYS_MAIN

EXIT_SYS:
    LD  HL, (USR_PC)
    PUSH  HL

    EXX
    EX  AF, AF'
    EI
    RETI



; =========================================================
; Tratamento Int 38h
; =========================================================
TRATAMENTO_INT38H:

    ; timeout key
    LD  A, (KEY_TIMEOUT)
    CP 0
    JP  Z, TRATAMENTO_INT38H_IN
    DEC  A
    LD (KEY_TIMEOUT), A

TRATAMENTO_INT38H_IN
    IN A, (Port40)
    LD  (INPUT), A
    AND $07                  ; 00000111b
    CP  0
    JP  Z, Col0
    CP  1
    JP  Z, Col1
    CP  2
    JP  Z, Col2
    CP  3
    JP  Z, Col3
    CP  4
    JP  Z, Col4
    CP  5
    JP  Z, Col5
    CP  6
    JP  Z, Col6
    CP  7
    JP  Z, Col7
    XOR A
    out (Port40), A
    RET

Col0:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col0_nextA
    LD  A, $00
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col0_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col0_next
    LD  A, $0E
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col0_next:
    LD  A, (DIG_1)           ; Dig_0
    out (Port40), a
    RET


Col1:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col1_nextA
    LD  A, $01
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col1_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col1_next
    LD  A, $03
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col1_next:
    LD  A, (DIG_2)           ; Dig_1
    out (Port40), a
    RET

Col2:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col2_nextA
    LD  A, $04
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col2_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col2_next
    LD  A, $06
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col2_next:
    LD  A, (DIG_3)           ; Dig_2
    out (Port40), a
    RET

Col3:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col3_nextA
    LD  A, $07
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col3_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col3_next
    LD  A, $09
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col3_next:
    LD  A, (DIG_4)           ; Dig_3
    out (Port40), a
    RET

Col4:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col4_nextA
    LD  A, $0F
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col4_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col4_next
    LD  A, $0D
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col4_next:
    LD  A, (DIG_5)           ; Dig_4
    out (Port40), a
    RET

Col5:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col5_nextA
    LD  A, $02
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col5_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col5_next
    LD  A, $0C
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col5_next:
    LD  A, (DIG_6)           ; Dig_5
    out (Port40), a
    RET

Col6:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col6_nextA
    LD  A, $05
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col6_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col6_next
    LD  A, $0B
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col6_next:
    LD  A, (DIG_7)           ; Dig_6
    out (Port40), a
    RET

Col7:
    LD  A,  (INPUT)
    BIT  3, A
    JP  NZ, Col7_nextA
    LD  A, $08
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col7_nextA:
    LD  A,  (INPUT)
    BIT  4, A
    JP  NZ, Col7_next
    LD  A, $0A
    LD  (KEY_PRESS), A
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A
Col7_next:
    LD  A, (DIG_0)           ; Dig_7
    out (Port40), a
    RET


; =========================================================
; SYS MAIN
; =========================================================
SYS_MAIN:
    LD  A, (SYSMODE)
    CP  0                    ; monitor
    JP  Z, MONITOR_MODE

    LD  A,  (SYSMODE)
    CP  1                    ; Examine RAM
    JP  Z, EXAMINE_RAM

    LD  A, (SYSMODE)
    CP  2                    ; Modify Data (Memory)
    JP  Z,  MODIFY_RAM

    LD  A, (SYSMODE)
    CP  3
    JP  Z,  CHOICE_REG       ; Cheice register to show

    LD  A, (SYSMODE)
    CP  4
    JP  SHOW_REGISTERS      ; Show registrer in REG_INDEX


    JP  EXIT_SYS

    RET

; =========================================================
; GET KEY IN A, IF A == FFh then no KEY
; =========================================================
GET_KEY_A:
    LD  A, (KEY_TIMEOUT)
    CP  0
    JP  NZ, GET_KEY_A_RET
    LD  A, CKEY_TIMEOUT
    LD  (KEY_TIMEOUT), A

    LD  A, (KEY_PRESS)
    PUSH  AF
    LD  A, $FF
    LD  (KEY_PRESS), A
    POP  AF
    RET

GET_KEY_A_RET
    LD  A, $FF
    RET

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


; =========================================================
; CHOICE REGISTER Mode 
; 1=PC, 2=SP, 3=AF, 4=BC, 5=DE, 6=HL, 7=IX, 8=IY, 9=IR
; =========================================================
CHOICE_REG:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, EXIT_SYS

    LD (TMP_KEY), A
    CP  0                    ; Back to monitor
    JP  Z, GO_MONITOR

    LD  A, (TMP_KEY)
    CP  $01
    JP  Z,  SET_SHOW_REG_PC



    JP  EXIT_SYS

SET_SHOW_REG_PC:
    LD  A, 4
    LD  (SYSMODE), A

    LD  A, 0
    LD  (REG_INDEX), A
    JP EXIT_SYS


SHOW_REGISTERS:
    CALL  GET_KEY_A
    CP 0
    JP  Z, GO_REGISTERS

    LD  A, (REG_INDEX)
    CP  0                    ; PC
    JP  Z, SHOW_REG_PC

    JP EXIT_SYS


SHOW_REG_PC:
    CALL  CLEAR_DISPLAY

    LD  A, $50               ; R - register
    LD  (DIG_0), A

    LD  A, $73               ; P
    LD  (DIG_1), A

    LD  A, $39
    LD  (DIG_2), A           ; C

    LD HL, (USR_PC)
    CALL PRINT_END_HL
    JP  EXIT_SYS


; =========================================================
; MONITOR Mode
; =========================================================

MONITOR_MODE:
    ; Mostra o endereço
    LD  HL, (PC_RAM)
    CALL PRINT_HL


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

    ; Registers
    LD  A, (TMP_KEY)
    CP  $00
    JP  Z, GO_REGISTERS


    ; Mostra os dados no endereço
    LD  HL, (PC_RAM)
    LD  A, (HL)
    CALL  PRINT_A

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
    LD  A, 3
    LD (EXM_COUNT), A        ; Set count 4 digits, position display
    LD  A, 1
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
    LD  A, 1                 ; Set count 2 digits, position display
    LD  (MDF_COUNT), A
    LD  A, 2                 ; moDify mode (Memory)
    LD  (SYSMODE), A
    LD  A, 01000000b
    LD  (DIG_6), A
    LD  (DIG_7), A
    JP  EXIT_SYS

GO_REGISTERS:
    LD  A, 3
    LD  (SYSMODE), A
    CALL CLEAR_DISPLAY

    LD  A, $39
    LD  (DIG_0), A           ; C

    LD  A, $76
    LD  (DIG_1), A           ; H

    LD  A, $3F
    LD  (DIG_2), A           ; O

    LD  A, $06
    LD  (DIG_3), A           ; I

    LD  A, $39
    LD  (DIG_4), A           ; C

    LD  A, $79
    LD  (DIG_5), A           ; E

    LD  A, $00
    LD  (DIG_6), A           ; " "

    LD  A, $50
    LD  (DIG_7), A           ; R


    JP  EXIT_SYS

GO_MONITOR:
    CALL  CLEAR_DISPLAY
    LD  A, 0
    LD  (SYSMODE), A
    JP  EXIT_SYS

FIRE:
    LD  A, 0
    LD (SYSMODE), A          ; Monitor mode
    LD  HL, $8000
    LD  (USR_PC), HL
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

    LD  A, 0                 ; Monitor mode
    LD  (SYSMODE), A

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



    ;LD  A, 0

LOOP:
    
    ;CALL PRINT_A
    ;call delay
    ;INC  A

    ;PUSH  af
    ;LD  A, (KEY_PRESS)
    ;CALL GET_NUM_FROM_LOW
    ;LD  (DIG_4), A
    ;POP  af


    JP  LOOP




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


LED_FONT .db $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $67 ; 0-9
         .DB $77, $7C, $39, $5E, $79, $71                     ; A-F

.end

; =========================================================
; Tabela display
; =========================================================
; 
;   0 - $3F
;   1 - $06
;   2 - $5B
;   3 - $4F
;   4 - $66
;   5 - $6D
;   6 - $7D
;   7 - $07
;   8 - $7F
;   9 - $67
; 
;   A - $77
;   B - $7C
;   C - $39
;   D - $5E
;   E - $79
;   F - $71
;   G - $6F
;   H - $76
;   I - $06
;   J - $1E
;   K - $7A
;   L - $38
;   M - $37
;   N - $54
;   O - $3F
;   P - $73
;   Q - $67
;   R - $50
;   S - $6D
;   T - $78
;   U - $1C
;   V - $3E
;   W - $1D
;   X - $70
;   Y - $6E
;   Z - $49
;
;   + - $46
;   , - $04
;   - - $40
;   . - $80
;   Ñ - $55
;   : - $41
;   ; - $88
;   _ - $08

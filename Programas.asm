





; ---------------------------------------------------------
; Utilitys Program .ORG 1000h
; ---------------------------------------------------------
.org 1000h
JP_CLEAR_RAM_FF              JP CLEAR_RAM_FF               ; 1000
JP_LOAD_FROM_IR              JP LOAD_FROM_IR               ; 1003
JP_TESTE_SOM                 JP TESTE_SOM                  ; 1006
JP_ANIMATE_LED1              JP ANIMATE_LED1               ; 1009
JP_COUNT_DOWN_ALERME         JP COUNT_DOWN_ALERME          ; 100C
JP_CONTROLE_SONY             JP CONTROLE_SONY              ; 100F
JP_CALC_SUM                  JP CALC_SUM                   ; 1012








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
; Utilitys Program | LOAD RAM FROM IR (NanoTac)
; ---------------------------------------------------------
LOAD_FROM_IR:
    DI                       ; deliga monitor (int38)
    LD HL, $8000           ; inicio ram
LFI_START:
    LD  BC, 0                ; B - time, C - Count
    LD  D, 0                 ; D, Data
LFI_CK1:                         ; aguarda nivel 0
    IN A, (Port40)
    BIT 7, A
    JP NZ, LFI_CK1
LFI_COD_START:               ; Recebe Start (9)
    INC B                    ; B = time, INC B
    CALL CONTROLE_DELAY
    IN  A, (Port40)
    BIT 7, A
    JP Z, LFI_COD_START      ; loop até nivel 1

    LD A, B
    CP 9                     ; start time = 9
    JP NZ, LFI_START         ; se não é start - reinicia

LFI_GET_NEXT:
; agora começa a pegar os commandos
    LD  D, 0                 ; zera data
    LD  C, 7                 ; data tem 8 bits
LFI_LOOP:                    ; Aguarda nivel 0
    IN A, (Port40)
    BIT 7, A
    JP NZ, LFI_LOOP

    LD  B, 0                  ; B = time
LFI_LOOP2:                    ; Recebeu alguma coisa
    INC B
    CALL LFI_DELAY
    IN  A, (Port40)
    BIT 7, A
    JP Z, LFI_LOOP2  ; aguarda nivel 1

    LD A, B
    CP 9
    JP Z, START              ; Back to minitor
    CP 5                     ; 5 HIGH, 3 LOW
    JP NZ, LFI_ZERO
    SET 0, D

LFI_ZERO:
    LD A, C
    CP 0
    JP Z, LFI_BYTE_OK 

    RLC D
    LD B, 0
    DEC C

    JP LFI_LOOP

    

LFI_BYTE_OK:
    LD  (HL), D
    INC HL
    JP LFI_GET_NEXT


LFI_DELAY:
    PUSH AF
    LD A, 50
LFI_DELAY_LOOP:
    DEC A
    CP 0
    JP NZ, LFI_DELAY_LOOP
    POP AF
    RET



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
; Utilitys Program | IR Sensor
; ---------------------------------------------------------
CONTROLE_SONY:
    LD A, 0
    LD ($8000), A            ; BUzzer
CONTROLE_IR:
    DI                       ; deliga monitor (int38)

    LD  BC, 0                ; B - time, C - Count
    LD  D, 0                 ; D, Data
CIR:                         ; aguarda nivel 0
    IN A, (Port40)
    BIT 7, A
    JP NZ, CIR
CIR_START:                   ; Recebe Start (9)
    INC B                    ; B = time, INC B
    CALL CONTROLE_DELAY
    IN  A, (Port40)
    BIT 7, A
    JP Z, CIR_START          ; loop até nivel 1

    LD A, B
    CP 9                     ; start time = 9
    JP NZ, CONTROLE_IR       ; se não é start - reinicia

; agora começa a pegar os commandos
    LD  D, 0                     ; zera data
    LD  C, 6                     ; data tem 7 bits
CONTROLE_IR_LOOP:            ; Aguarda nivel 0
    IN A, (Port40)
    BIT 7, A
    JP NZ, CONTROLE_IR_LOOP

    LD  B, 0                ; B = time
CONTROLE_IR_LOOP2:           ; Recebeu alguma coisa
    INC B
    CALL CONTROLE_DELAY
    IN  A, (Port40)
    BIT 7, A
    JP Z, CONTROLE_IR_LOOP2  ; aguarda nivel 1

    LD A, B
    CP 5                     ; 5 HIGH, 3 LOW
    JP NZ, CIR_ZERO
    SET 0, D

CIR_ZERO:
    LD A, C
    CP 0
    JP Z, CONTROLE_OK 

    RLC D
    LD B, 0
    DEC C

    JP CONTROLE_IR_LOOP

    

CONTROLE_OK:
    LD  A, D
    LD ($9000), A           ; Save data $9000

; commando recebido em D
    LD A, D
    CP $53                   ; ok
    JP Z, CIR_OK
    CP $63                   ; Exit
    JP Z, CIR_SAIR
    CP $54                   ; power
    JP Z, CIR_TOGGLE_BUZZER
    CP $52
    JP Z, CIR_R              ; red
    CP $32
    JP Z, CIR_G              ; green
    CP $72
    JP Z, CIR_Y              ; yellow
    CP $12
    JP Z, CIR_B              ; blue

    OUT (Port40), A
    JP CONTROLE_IR


CIR_R:
    LD A, ($8000)
    XOR $20
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR

CIR_G:
    LD A, ($8000)
    XOR $80
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR

CIR_Y:
    LD A, ($8000)
    XOR $40
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR

CIR_B:
    LD A, ($8000)
    XOR $10
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR


CIR_TOGGLE_BUZZER:
    LD A, ($8000)
    XOR $08
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR

CIR_OK:
    LD A, ($8000)
    XOR $01
    OUT (PortC0), A
    LD ($8000), A
    CALL DELAY_100mS
    CALL DELAY_100mS
    JP CONTROLE_IR

CIR_SAIR:
    ; retorna int
    IM  1
    EI
    XOR A
    OUT (Port40), A
    
CONTROLE_IR_LOOP3:
    JP CONTROLE_IR_LOOP3


CONTROLE_DELAY:
    PUSH AF
    LD A, 50
CONTROLE_DELAY_LOOP:
    DEC A
    CP 0
    JP NZ, CONTROLE_DELAY_LOOP
    POP AF
    RET



; ---------------------------------------------------------
; Utilitys Program | PROGRAM CALC XX + XX 
; ---------------------------------------------------------
CALC_SUM:
NUM1     .equ      $8000
NUM2     .equ      $8001
RESULT1  .equ      $8002
RESULT2  .equ      $8003

    LD  A, 0                 ; user mode
    LD (SYSMODE), A

    CALL CLEAR_USER_DISPLAY

    LD  A, $40
    LD  (USER_DISP6), A

    LD  A, $40
    LD  (USER_DISP7), A

    LD A, 0
    LD (RESULT1), A
    LD (RESULT2), A

READ01:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ01
    PUSH AF
    RLC A
    RLC A
    RLC A
    RLC A
    LD  (NUM1), A
    POP AF
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP6), A

READ02:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ02
    PUSH AF
    LD B, A
    LD A, (NUM1)
    OR B
    LD (NUM1), A

    POP AF
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP7), A

    LD A, $FF
    CALL DELAY_A
; NUM2
    LD  A, $40
    LD  (USER_DISP6), A

    LD  A, $40
    LD  (USER_DISP7), A

READ03:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ03
    PUSH AF
    RLC A
    RLC A
    RLC A
    RLC A
    LD  (NUM2), A
    POP AF
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP6), A

READ04:
    CALL GET_KEY_A
    CP  $FF
    JP  Z, READ04

    PUSH AF
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP7), A
    POP AF
    LD B, A
    LD A, (NUM2)
    OR B
    LD (NUM2), A

    LD A, (NUM1)
    LD B, A
    LD A, (NUM2)
    ADD A, B
    DAA
    LD (RESULT2), A

    JP NC, CALC_SUM_SHOW
    LD A, (RESULT1)
    INC A
    LD (RESULT1),A

CALC_SUM_SHOW:
    LD A, $FF
    CALL DELAY_A

    LD A, (RESULT1)
    CP 0
    JP Z, SHOW_NEXT
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP5), A

SHOW_NEXT:
    LD A, (RESULT2)
    CALL GET_NUM_FROM_HIGH
    LD (USER_DISP6), A

    LD A, (RESULT2)
    CALL GET_NUM_FROM_LOW
    LD (USER_DISP7), A

CALC_SUM_LOOP:
    JP  CALC_SUM_LOOP


; ---------------------------------------------------------
; Utilitys Program | PROGRAM X
; ---------------------------------------------------------
    LD  A, 0                 ; user mode
    LD (SYSMODE), A

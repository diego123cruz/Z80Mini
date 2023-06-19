

DELAY_100mS     .equ    $0C68
Port40          .equ    $40
PortC0          .equ    $C0
; ---------------------------------------------------------
; Utilitys Program | IR Sensor
;
; Save data $9000
;
; ---------------------------------------------------------
.org $8000

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

.end


; Teste Step


;   .org $8000
;
;	   LD A, 1          ; 1.75
;   LOOP:
;      OUT($C0), A      ; 2.75  -> $C0 Leds Test
;	   XOR $1           ; 1.75
;      JP LOOP          ; 2.50

; 3E 01 D3 C0 EE 01 C3 02 80

; Constants
Port40          .equ    $40   ; Displays 7seg
StackRamTop     .equ    $EE00 ; Stack
StartRAM        .equ    $8000 ; Start RAM



; RAM Map
INT_VEC .equ    $EF00 ;(2)
RAM_PC  .equ    $EF02 ;(2)
RAM_AF  .equ    $EF04 ;(2)
RAM_HL  .equ    $EF06 ;(2)
LAST_IN .equ    $EE08 ;(1)

;============================
; $0000
;============================
.org $0
    JP START


;============================
; $0038  INT
;============================
.org $38
    LD (RAM_HL), HL
    LD HL, (INT_VEC)
    JP (HL)


;============================
; START
; Load Program test in RAM $8000
;============================
START:
    LD SP, StackRamTop
    LD HL, StartRAM
    LD (RAM_PC), HL

    ; define int null
    LD HL, INT_MONITOR
    LD (INT_VEC), HL

    ; Coloca codigo teste na ram
    LD A, $3E
    LD ($8000), A ; LD A, $01

    LD A, $01
    LD ($8001), A 

    LD A, $D3
    LD ($8002), A ; OUT ($C0), A

    LD A, $C0
    LD ($8003), A 

    LD A, $EE
    LD ($8004), A ; XOR $01

    LD A, $01
    LD ($8005), A 

    LD A, $C3
    LD ($8006), A ; JP 8000

    LD A, $02
    LD ($8007), A 

    LD A, $80
    LD ($8008), A

    ; Codigo OK $8000

    IM 1
    EI

    LD A, $01
    OUT (Port40), A

;============================
; MAIN LOOP
;============================
LOOP:
    ; Button Step...
    IN A, (Port40)
    BIT 5, A
    JP NZ, INI_STEP

    JP LOOP

INI_STEP:
    DI
    ; Delay for button not repeat (test)
    CALL DELAY_100mS
    CALL DELAY_100mS
    CALL DELAY_100mS
    CALL DELAY_100mS
    CALL DELAY_100mS
    
    OUT (Port40), A

    EI
    
    JP STEP1


;============================
; MONITOR TEST
;============================
INT_MONITOR:
    DI
    PUSH AF

    IN A, (Port40)
    AND 7
    LD (LAST_IN), A
    
    CP 0
    JP Z, SHOW1

    LD A, (LAST_IN)
    CP 1
    JP Z, SHOW2

    LD A, (LAST_IN)
    CP 2
    JP Z, SHOW3

    LD A, (LAST_IN)
    CP 3
    JP Z, SHOW4


    LD A, $00
    OUT (Port40), A

EXIT_INT_MONITOR
    POP AF
    EI
    RETI



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

; Mapa char to display 0-F
LED_FONT .db $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $67 ; 0-9
         .DB $77, $7C, $39, $5E, $79, $71                     ; A-F

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

SHOW1:
    PUSH HL
    LD HL, (RAM_PC)
    LD A, H
    CALL GET_NUM_FROM_HIGH
    OUT (Port40), A
    POP HL
    JP EXIT_INT_MONITOR

SHOW2:
    PUSH HL
    LD HL, (RAM_PC)
    LD A, H
    CALL GET_NUM_FROM_LOW
    OUT (Port40), A
    POP HL
    JP EXIT_INT_MONITOR

SHOW3:
    PUSH HL
    LD HL, (RAM_PC)
    LD A, L
    CALL GET_NUM_FROM_HIGH
    OUT (Port40), A
    POP HL
    JP EXIT_INT_MONITOR

SHOW4:
    PUSH HL
    LD HL, (RAM_PC)
    LD A, L
    CALL GET_NUM_FROM_LOW
    OUT (Port40), A
    POP HL
    JP EXIT_INT_MONITOR

; ===============================================
; ===============================================
; ===============================================



;============================
; PART 1
;============================
STEP1:
    DI
    LD HL, STEP2
    LD (INT_VEC), HL
    OUT (Port40), A
    EI
    HALT



; Somar todos os clocks 1024us
;============================
; PART 2
;============================
STEP2:
    LD HL, STEP3 ;(1.75)
    LD (INT_VEC), HL ; (4.00)


    PUSH AF ; (2.75)
    XOR A ; (1.00)
    OUT (Port40), A ; (2.75)
    POP AF ; (2.50)

    ; delay
    PUSH BC ; (2.75)
    LD B, $E5 ;(1.75)  ----->  DEC(230) = $E6
loop_step2:
    NOP     ;(1)
    DJNZ loop_step2 ;if B!=0 (3.25), if B=0 (2)
    POP BC ; (2.50)
    ; delay end

    ;OUT (Port40), A ;(2.75)
    NOP ; (1)
    NOP ; (1)
    NOP ; (1)

    LD HL, (RAM_PC) ; (4.00)
    PUSH HL ;(2.75)
    EX AF, AF' ; (1)'
    EXX   ;(1)
    EI ;(1)
    RETI ;(2.50)

; 1024 = 36 + (4.25 x T) - 4
; T = (1024 - 36 - 4) / 4.25
; T = 230 DEC

;============================
; PART 3
;============================
STEP3:
    DI
    EX AF, AF' ;'
    EXX
    PUSH AF
    XOR A
    OUT (Port40), A
    POP AF

    
    POP HL ; PC
    LD (RAM_PC), HL

    ; save AF
    PUSH AF
    POP HL
    LD (RAM_AF), HL

    LD HL, INT_MONITOR
    LD (INT_VEC), HL

    LD HL, LOOP
    PUSH HL
    EI
    RETI


;============================
; DELAY 1000mS
;============================
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


.end

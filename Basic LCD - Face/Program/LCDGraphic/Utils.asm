;----------------
;CONVERT A TO ASCII (HEX) AND SHOW LCD
;----------------
;
;CONVERT REG A BYTE TO ASCII 
;
CONV_A_HEX: PUSH  AF          ;SAVE A FOR SECOND NYBBLE 
       RRCA              ;SHIFT HIGH NYBBLE ACROSS
       RRCA
       RRCA
       RRCA
       CALL CONV_A_HEX_NYBASC       ;CALL NYBBLE CONVERTER 
       POP AF            ;RESTORE LOW NYBBLE
;           
; CONVERT A NYBBLE TO ASCII
;
CONV_A_HEX_NYBASC: AND   0FH         ;MASK OFF HIGH NYBBLE 
       ADD   A,90H       ;CONVERT TO
       DAA               ;ASCII
       ADC   A,40H
       DAA
;            
; Print inlcd
;
    CALL PRINTCHAR
    RET 


; Space character ouput to console
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved
SpaceOut:   
            LD   A,$20
            RST $08 ; output chat to lcd
            RET

; New line output to console device
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved
LineOut:    PUSH AF
            LD A, CR ; enter char
            RST $08
            RET


; String output to console device
;   On entry: DE = Address of string
;   On exit:  BC DE HL IX IY preserved
StrOut:     PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            LD H, D
            LD L, E
            CALL SNDLCDMSG
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET

            

; **********************************************************************
; Delay by DE milliseconds
;   On entry: DE = Delay time in milliseconds
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
H_Delay:    PUSH AF
            PUSH BC
            PUSH DE
; 1 ms loop, DE times...        ;[=36]   [=29]    Overhead for each 1ms
LoopDE:    LD   BC, kDelayCnt   ;[10]    [9]
; Inner loop, BC times...       ;[=26]   [=20]    Loop time in Tcycles
LoopBC:    DEC  BC             ;[6]     [4]
            LD   A,C            ;[4]     [4]
            OR   B              ;[4]     [4]
            JP   NZ,LoopBC     ;[12/7]  [8/6] 
; Have we looped once for each millisecond requested?
            DEC  DE             ;[6]     [4]
            LD   A,E            ;[4]     [4]
            OR   D              ;[4]     [4]
            JR   NZ, LoopDE     ;[12/7]  [8/6]
            POP  DE
            POP  BC
            POP  AF
            RET


; ----------------------------------
; INPUT: THE VALUES IN REGISTER B EN C
; OUTPUT: HL = B * C
; CHANGES: AF,DE,HL,B
;
multiplication:
	LD HL,0
	LD A,B
	OR A
	RET Z
	LD D,0
	LD E,C
multiplicationLOOP:	ADD HL,DE
	DJNZ multiplicationLOOP
	RET 

;-----------------------------------
; Div_HL_D
;Inputs:
;   HL and D
;Outputs:
;   HL is the quotient (HL/D)
;   A is the remainder
;   B is 0
;   C,D,E are preserved
Div_HL_D:
    xor a         ; Clear upper eight bits of AHL
    ld b,16       ; Sixteen bits in dividend
_loop:
    add hl,hl     ; Do a "SLA HL". If the upper bit was 1, the c flag is set
    rla           ; This moves the upper bits of the dividend into A
    jr c,_overflow; If D is allowed to be >128, then it is possible for A to overflow here. (Yes future Zeda, 128 is "safe.")
    cp d          ; Check if we can subtract the divisor
    jr c,_skip    ; Carry means A < D
_overflow:
    sub d         ; Do subtraction for real this time
    inc l         ; Set the next bit of the quotient (currently bit 0)
_skip:
    djnz _loop
    ret
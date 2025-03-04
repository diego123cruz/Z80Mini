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
    CALL LCD_PRINT_A
    RET 


;-----------------------
; Change led red, half byte in A
;-----------------------
LED_RED:
    AND $0F
    LD B, A
    LD A, (LED_ONBOARD)
    AND $F0
    OR B
    OUT(LEDS_ONBOARD), A
    LD (LED_ONBOARD), A
    RET


;-----------------------
; Change led green, half byte in A
;-----------------------
LED_GREEN:
    SLA A
    SLA A
    SLA A
    SLA A
    LD B, A
    LD A, (LED_ONBOARD)
    AND $0F
    OR B
    OUT(LEDS_ONBOARD), A
    LD (LED_ONBOARD), A
    RET

;----------------
;CONVERT TO ASCII 
;----------------
;
; CONVERT A WORD,A BYTE OR A NYBBLE TO ASCII
;
;         ENTRY :  A = BINARY TO CONVERT
;                  HL = CHARACTER BUFFER ADDRESS   
;        EXIT   :  HL = POINTS TO LAST CHARACTER+1
;   
;        MODIFIES : DE

WRDASC: LD    A,D         ;CONVERT AND
       CALL  BYTASC      ;OUTPUT D
       LD    A,E         ;THEN E
;
;CONVERT A BYTE TO ASCII 
;
BYTASC: PUSH  AF          ;SAVE A FOR SECOND NYBBLE 
       RRCA              ;SHIFT HIGH NYBBLE ACROSS
       RRCA
       RRCA
       RRCA
       CALL NYBASC       ;CALL NYBBLE CONVERTER 
       POP AF            ;RESTORE LOW NYBBLE
;           
; CONVERT A NYBBLE TO ASCII
;
NYBASC: AND   0FH         ;MASK OFF HIGH NYBBLE 
       ADD   A,90H       ;CONVERT TO
       DAA               ;ASCII
       ADC   A,40H
       DAA
;            
; SAVE IN STRING
;
INSBUF: LD    (HL),A
       INC   HL 
       RET 


;----------------------     
; SEND ASCII HEX VALUES        
;----------------------
;
; OUTPUT THE 4 BYTE, WRDOUT
; THE 2 BYTE, BYTOUT
; OR THE SINGLE BYTE, NYBOUT
; ASCII STRING AT HL TO THE SERIAL PORT
;
WRDOUT: CALL  BYTOUT
BYTOUT: CALL  NYBOUT
NYBOUT: LD    A,(HL)
       CALL  LCD_PRINT_A
       INC   HL
       RET   
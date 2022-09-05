;SIMON Game written by Jim Robertson
;-----------------------------------
; The 4 LED Segments from the right represent keys 0,4,8,C.
; The segments light up and the order they light up represents the
; keys to press.
;
; Modified by B Chiha to auto populate random numbers at startup.
;
KEYBUF:      .EQU 40H             ;MM74C923N KEYBOARD ENCODER
SCAN:        .EQU 70H             ;DISPLAY SCAN LATCH
DISPLY:      .EQU 40H             ;DISPLAY LATCH

            .ORG     8000H 

SIMON:
SETUP:               
            CALL    RANGEN      ;Set up random numbers from 9000 to 90FF
            LD      A,R         ;Get random number for random table lookup
            LD      L,A         ;at 90xx
START:
            LD      C,01H
            CALL    DELAY
            LD      H,90H
GAME:
            LD      B,C         ;Working counter
            PUSH    HL
LOOP:
            LD      A,(HL)      ;Get Random value
            CALL    SOUND
            INC     L
            CALL    DELAY       ;Call delay which shortens on each call
            DJNZ    LOOP
            POP     HL
            LD      B,C
            PUSH    HL
PLAYER:
            CALL    KEYPRESS
            JR      NZ,PLAYER   ;No key pressed
            RRCA                ;Check for keys 0,4,8,C by shifting
            RRCA                ;twice to the right..Clever!
            CP      04H         ;Compare with 4 to see if valid key
            JR      NC,PLAYER
            PUSH    HL
            LD      HL,DSPTBL   ;Display Table
            ADD     A,L
            LD      L,A
            LD      A,(HL)      ;Get display value based on key press
            POP     HL
            CP      (HL)        ;Complare key pressed with value in lookup
            JR      NZ,ERROR
            CALL    SOUND
            INC     L
KEYWAIT:
            ;CALL    KEYPRESS    ;Get another key
            ;JR      NZ,KEYWAIT   ;Loop until key released
            IN      A,(KEYBUF)     ;Check if key is pressed
            BIT     6,A
            JR      NZ, KEYWAIT
            DJNZ    PLAYER
            POP     HL
            CALL    DELAY
            INC     C
            JR      GAME        ;Jump back to start of game
ERROR:
            LD      A,30H       ;Incorrect answer
            CALL    SOUND
            LD      B,C
            XOR     A
HEXBCD:
            INC     A
            DAA    
            DJNZ    HEXBCD
            DEC     A
            DAA
            LD      C,A
SIMON_SCAN:       XOR     A           ;Multiplex
            OUT     (DISPLY),A
            LD      A,04H
            OUT     (SCAN),A
            LD      A,C
            CALL    BCDHEX
            LD      B,00H
LOOP1:      DJNZ    LOOP1
            XOR     A
            OUT     (DISPLY),A
            LD      A,08H
            OUT     (SCAN),A
            LD      A,C
            RRCA
            RRCA
            RRCA
            RRCA
            CALL    BCDHEX
            LD      B,00H
LOOP2:      DJNZ    LOOP2
            CALL    KEYPRESS
            INC     D
            CP      12H        ;Check if GO pressed
            JR      NZ,SIMON_SCAN    ;Keep scanning until GO pressed
            LD      L,D        ;Put random number in L
            XOR     A
            OUT     (SCAN),A
            CALL    SOUND
            JR      START
BCDHEX:
            AND     0FH        ;Mask high nibble
            LD      HL,SEGTBL
            ADD     A,L
            LD      L,A
            LD      A,(HL)     ;Get Segment
            OUT     (DISPLY),A     ;Display number
            RET
DELAY:
            LD      DE,9000H
            LD      A,C        ;Frame count
            RLCA
            RLCA
LOOP3:
            DEC     D
            DEC     A
            JR      NZ,LOOP3
LOOP4:
            DEC     DE
            LD      A,D
            OR      E
            JR      NZ,LOOP4
            LD      A,80H      ;ponto segment
            OUT     (DISPLY),A
            RET
SOUND:
            PUSH    HL
            PUSH    DE
            PUSH    BC
            LD      C,A
            RLCA
            ADD     A,18H
            LD      HL,01E0H
            LD      B,A
            LD      A,C
            LD      DE,0001H
            LD      C,B
            AND     0FH
LOOP5:
            OUT     (SCAN),A     ;Display value
            LD      B,C
LOOP6:      DJNZ    LOOP6
            XOR     80H        ;Toggle speaker bit
            SBC     HL,DE
            JR      NZ,LOOP5
            POP     BC
            POP     DE
            POP     HL
            LD      A,80H      ;ponto segment
            OUT     (DISPLY),A
            XOR     A
            OUT     (SCAN),A
            RET
KEYPRESS:
            IN      A,(KEYBUF)     ;Check if key is pressed
            BIT     6,A
            RET     Z         ;No key pressed
            IN      A,(KEYBUF)     ;Get actual key
            AND     1FH        ;Mask upper bits
            LD      E,A
            XOR     A          ;Clear flags
            LD      A,E
            RET

DSPTBL:     .DB      08H,04H,02H,01H
SEGTBL:     .DB      3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,67H

;Here is the random number generator that puts 1,2,4 and 8 in memory
;between 9000 and 90FF.  Call this routine first
RANGEN:
            LD      B,00H
            LD      HL,9000H
            LD      D,00010001B  ;(rotating 1 bits)
RG1:
            LD      A,R
RG2:
            RLC     D
            DEC     A
            JR      NZ,RG2
            LD      A,D
            AND     0FH
            LD      (HL),A      ;Store randome number
            INC     HL
            PUSH    AF          ;Waste time to move R on a bit
            POP     AF         
            DJNZ    RG1
            RET

	   .END
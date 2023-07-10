KEYMAP:
.BYTE   "12345",KF1,"67890"
.BYTE   KF2,"QWERT",KF3,"YUIOP"
.BYTE   KF4,"ASDFG",KLEFT,"HJKL", CR
.BYTE   KDOWN,CTRLC, "ZXCV",KRIGHT,"BNM ", DEL, KUP

SHIFTKEYMAP:
.BYTE   "!@#$%",KF5,"^&*()"
.BYTE   KF6,"`~-_=",KF7,"+;:'" 
.BYTE   22h
.BYTE   KF8,"{}[]|",KLEFT,$5C,"<>?", CR
.BYTE   KDOWN,ESC,"/,. ",KRIGHT,"    ", DEL, KUP


;-----------------------------
; GET A BYTE FROM KEYBOARD
;-----------------------------
GETCHR: CALL KEYREADINIT ; read key
       CP    ESC
       JR    Z,GETOUT
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A                ;SAVE TO ECHO      
       CALL  ASC2HEX
       JR    NC,GETCHR          ;REJECT NON HEX CHARS    
       LD    HL, DATA
       LD    (HL), A 
       LD    A,B         
       CALL  PRINTCHAR             ;ECHO VALID HEX
       
GETNYB: CALL  KEYREADINIT
       CP    ESC
       JR    Z,GETOUT
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A               ;SAVE TO ECHO
       CALL  ASC2HEX
       JR    NC,GETNYB         ;REJECT NON HEX CHARS
       RLD
       LD    A,B
       CALL  PRINTCHAR             ;ECHO VALID HEX
       LD    A,(HL)
       CALL  GETOUT            ;MAKE SURE WE CLEAR THE CARRY BY SETTING IT,
       CCF                    ;AND THEN COMPLEMENTING IT
       RET   
GETOUT: SCF                    ;SET THE CARRY FLAG TO EXIT BACK TO MENU
       RET
    

;----------------------------------------
; CONVERT ASCII CHARACTER INTO HEX NYBBLE
;----------------------------------------
; THIS ROUTINE IS FOR MASKING OUT KEYBOARD
; ENTRY OTHER THAN HEXADECIMAL KEYS
;
;CONVERTS ASCII 0-9,A-F INTO HEX LSN
;ENTRY : A= ASCII 0-9,A-F
;EXIT  : CARRY =  1
;          A= HEX 0-F IN LSN    
;      : CARRY = 0
;          A= OUT OF RANGE CHARACTER & 7FH
; A AND F REGISTERS MODIFIED
;
ASC2HEX: AND   7FH        ;STRIP OUT PARITY
       CP    30H
       JR    C,AC2HEX3    ;LESS THAN 0
       CP    3AH
       JR    NC,AC2HEX2   ;MORE THAN 9
AC2HEX1: SCF               ;SET THE CARRY - IS HEX
       RET
;     
AC2HEX2: CP    41H
       JR    C,AC2HEX3    ;LESS THAN A
       CP    47H
       JR    NC,AC2HEX3   ;MORE THAN F
       SUB   07H        ;CONVERT TO NYBBLE
       JR    AC2HEX1  
AC2HEX3: AND   0FFH        ;RESET THE CARRY - NOT HEX
       RET


; -----------------------------------------------------------------------------
;   Check break key (Basic)
; -----------------------------------------------------------------------------
CHKKEY: LD  A, $40
	OUT (KEY_OUT), A ; line 4
	IN  A, (KEY_IN)
	CP  1
	JP  NZ, GRET
	LD  A, CTRLC
	CP	0
	RET
GRET:
	LD  A, 0
	CP 0
	RET



; -----------------------------------------------------------------------------
;   KEYREAD - KEY In A
; -----------------------------------------------------------------------------
KEYREADINIT:
    PUSH    BC
	PUSH	DE
	PUSH    HL
	LD      E, 0                    ; E will be the last pressed key
READKEY:        
    LD      H, 1                    ; H is the line register, start with second
	LD      B, 0                    ; Count lines for later multiplication	
	LD      D, 0                    ; DE will be the adress for mask
						
NEXTKEY:        
    LD      A, H						
    CP      0                       ; All lines tried? 
    JP      Z, KEYOUT               ; Then check if there was a key pressed
	OUT     (KEY_OUT), A		    ; Put current line to register
	IN      A, (KEY_IN)		        ; Input Keys
	AND     $3F                     ; only 6 bits
	SLA     H                       ; Next line
    INC     B
    CP      0                       ; Was key zero?
    JP      Z, NEXTKEY              ; Then try again with next lines
    LD      D, 0                    ; In D will be the number of the key
LOGARITHM:      
    INC     D	                    ; Add one per shift
    SRL     A                       ; Shift key right
    JP      NZ, LOGARITHM		    ; If not zero shift again
    DEC     D                       ; Was too much
	IN      A, (KEY_IN)
    AND     $80                     ; Check if first bit set (shift key pressed)
    JP      NZ, LOADSHIFT		    ; Then jump to read with shift
    LD      A, D                    ; Put read key into accu
    ADD     A, KEYMAP               ; Add base of key map array
    JP      ADDOFFSET               ; Jump to load key
LOADSHIFT:
    LD      A, D
    ADD     A, SHIFTKEYMAP          ; In this case add the base for shift		
ADDOFFSET:
    ADD     A, 6                    ; Add 6 for every line
    DJNZ    ADDOFFSET               ; Jump back (do while loop)
	SUB     6                       ; Since do while is one too much
TRANSKEY:
    XOR     B                       ; Empty B
	LD      C, A                    ; A will be address in BC
	LD      A, (BC)	                ; Load key
	CP      E                       ; Same key?
	JP      Z, READKEY              ; Then from beginning
	LD      E, A                    ; Otherwise save new key
	JP      READKEY	                ; And restart
KEYOUT:
    LD      A, E
    LD      E, 0                    ; empty it
    OR      A	                    ; Was a key read?
    JP      Z, READKEY              ; If not restart
    POP     HL
    POP     DE
    POP     BC
    RET
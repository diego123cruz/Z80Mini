INIT_SERIAL:
	; Init Serial
	LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE


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

    ; Print wellcome serial
    LD HL, WELLCOME
    CALL SNDSTR

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
SNDSTR: LD    B,128         ;128 CHARS MAX
SDMSG1: LD    A,(HL)        ;GET THE CHAR
       CP    00H          ;ZERO TERMINATOR?
       JR    Z,SDMSG2      ;FOUND A ZERO TERMINATOR, EXIT  
       CALL  OUTCH         ;TRANSMIT THE CHAR
       INC   HL
       DJNZ  SDMSG1        ;128 CHARS MAX!    
SDMSG2: RET


;------------------------
; SERIAL TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TXDATA:		
		PUSH	AF		; Store character
conoutA1:	CALL	CKSIOA		; See if SIO channel A is finished transmitting
		JR	Z,conoutA1	; Loop until SIO flag signals ready
		POP	AF		; RETrieve character
		OUT	(SIOA_D),A	; OUTput the character
		RET


;------------------------------------------------------------------------------
; I/O status check routine
; Use the "primaryIO" flag to determine which port to check.
;------------------------------------------------------------------------------
CKSIOA
		SUB	A
		OUT 	(SIOA_C),A
		IN   	A,(SIOA_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		BIT  	1,A		; Set Zero flag if still transmitting character	
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
RXDATA:	
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

;------------------------------------------------------------
;------------------------------------------------------------
; RECEIVE INTEL HEX FILE
;------------------------------------------------------------
;------------------------------------------------------------
INTELLOADER: 
		CALL LCD_CR

       	LD DE, MSG_ILOAD
    	XOR A
    	CALL SEND_STRING_TO_GLCD

       	LD HL, MSG_ILOAD
       	CALL  SNDSTR
       

       	CALL  INTELH
       	JR    NZ,ITHEX1

       	LD    DE,FILEOK
       	XOR A
    	CALL SEND_STRING_TO_GLCD   ;GOT FILE OK LCD

       	LD    HL,FILEOK
       	CALL  SNDSTR      ;GOT FILE OK Serial
       
       	RET
ITHEX1: LD    DE,CSUMERR
       	XOR A
    	CALL SEND_STRING_TO_GLCD

       	LD    HL,CSUMERR
       	CALL  SNDSTR      ;CHECKSUM ERROR 
       	RET  





;-----------------------
; RECEIVE INTEL HEX FILE
;-----------------------
INTELH:	LD	IX, SYSTEM_SP	;POINT TO SYSTEM VARIABLES
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
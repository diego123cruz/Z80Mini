; Inicializa SIO/2 Serial 115200
initSerial:
    LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE


    ;	Initialise SIO/2 A - Onboard USB
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

    ; Initialise SIO/2 B - Printer (P2 conector)
	LD	A,$04
	OUT	(SIOB_C),A
	LD	A,$C4
	OUT	(SIOB_C),A

	LD	A,$03
	OUT	(SIOB_C),A
	LD	A,$E1
	OUT	(SIOB_C),A

	LD	A,$05
	OUT	(SIOB_C),A
	LD	A, $68
	OUT	(SIOB_C),A


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
; SERIAL A TRANSMIT ROUTINE
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
; SERIAL A RECEIVE ROUTINE
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



;======================= Serial B ========================
;------------------------
; SERIAL B TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TXDATA_B:		
		PUSH	AF		; Store character
conoutB1:	CALL	CKSIOB		; See if SIO channel A is finished transmitting
		JR	Z,conoutB1	; Loop until SIO flag signals ready
		POP	AF		; RETrieve character
		OUT	(SIOB_D),A	; OUTput the character
		RET


;------------------------------------------------------------------------------
; I/O status check routine
; Use the "primaryIO" flag to determine which port to check.
;------------------------------------------------------------------------------
CKSIOB
		SUB	A
		OUT 	(SIOB_C),A
		IN   	A,(SIOB_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		BIT  	1,A		; Set Zero flag if still transmitting character	
        RET

    
;-----------------------
; SERIAL B RECEIVE ROUTINE
;-----------------------
;RECEIVE SERIAL BYTE FROM DIN
;
; ENTRY : NONE
;  EXIT : A= RECEIVED BYTE IF CARRY CLEAR
;
; REGISTERS MODIFIED A AND F
;
RXDATA_B:	
waitForCharB:
        ; Check if there is a char in channel A
		SUB	A
		OUT 	(SIOB_C),A
		IN   	A,(SIOB_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		JR	NC, waitForCharB
		IN	A,(SIOB_D)
		OR A ; clear carry
		RET


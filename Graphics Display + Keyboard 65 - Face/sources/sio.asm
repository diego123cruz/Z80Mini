
SIOA_D		.EQU	$00
SIOA_C		.EQU	$02
SIOB_D		.EQU	$01 ; Não usado
SIOB_C		.EQU	$03 ; Não usado




;------------------------------------------------------------------------------
;                         START OF MONITOR ROM
;------------------------------------------------------------------------------

	.ORG	$0000		; MONITOR ROM RESET VECTOR
;------------------------------------------------------------------------------
; Reset
;------------------------------------------------------------------------------
RST00:	DI			;Disable INTerrupts
		JP	INIT		;Initialize Hardware and go
		NOP
		NOP
		NOP
		NOP



INIT:
    	LD SP, $9000

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

		

		; Print Hello
    	LD   	HL,INITTXT
		CALL 	PRINT
		

waitForSpace:
        ; Check if there is a char in channel A
		; If not, there is a char in channel B
		SUB	A
		OUT 	(SIOA_C),A
		IN   	A,(SIOA_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		JR	NC, waitForSpace
		IN	A,(SIOA_D)
		call conout
		JP   waitForSpace

        HALT





;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
PRINT	LD   A,(HL)	; Get character
		OR   A		; Is it $00 ?
		RET  Z		; Then RETurn on terminator
		CALL conout	; Print it RTS 08
		INC  HL		; Next Character
		JR   PRINT	; Continue until $00


TXCRLF	LD   A,$0D	; 
		CALL conout	; Print character RST 08
		LD   A,$0A	; 
		CALL conout	; Print character RST 08
		RET


;------------------------------------------------------------------------------
; Console output routine
;------------------------------------------------------------------------------
conout:		
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



INITTXT  
	.BYTE	$0C
	.TEXT	"Hello world"
	.BYTE	$0D,$0A, $00
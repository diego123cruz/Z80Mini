#include "../Z80MiniAPI.asm"
; Inicializa SIO/2 Serial 115200

SIO2A_D		        .EQU	$10
SIO2A_C		        .EQU	$12
SIO2B_D		        .EQU	$11
SIO2B_C		        .EQU	$13

    ORG $8000
    
    ;	Initialise SIO/2 A
	LD	A,$04
	OUT	(SIO2A_C),A
	LD	A,$C4
	OUT	(SIO2A_C),A

	LD	A,$03
	OUT	(SIO2A_C),A
	LD	A,$E1
	OUT	(SIO2A_C),A

	LD	A,$05
	OUT	(SIO2A_C),A
	LD	A, $68
	OUT	(SIO2A_C),A

    ; Initialise SIO/2 B
	LD	A,$04
	OUT	(SIO2B_C),A
	LD	A,$C4
	OUT	(SIO2B_C),A

	LD	A,$03
	OUT	(SIO2B_C),A
	LD	A,$E1
	OUT	(SIO2B_C),A

	LD	A,$05
	OUT	(SIO2B_C),A
	LD	A, $68
	OUT	(SIO2B_C),A

LOOP:
	;Port A
	LD HL, msgA
	LD C, SIO2A_D
	call printStrHLportA
	
	LD A, 'B'
	OUT (SIO2B_D), A

	
	call delay500ms
	JP LOOP
	
	
	
printStrHLportA:
	LD A, (HL)
	CP 0
	RET Z
	call TXDATA
	INC HL
	jp printStrHLportA
	
TXDATA:		
		PUSH	AF		; Store character
conoutA1:	CALL	CKSIOA		; See if SIO channel A is finished transmitting
		JR	Z,conoutA1	; Loop until SIO flag signals ready
		POP	AF		; RETrieve character
		OUT	(SIO2A_D),A	; OUTput the character
		RET

;------------------------------------------------------------------------------
; I/O status check routine
; Use the "primaryIO" flag to determine which port to check.
;------------------------------------------------------------------------------
CKSIOA
		SUB	A
		OUT 	(SIO2A_C),A
		IN   	A,(SIO2A_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		BIT  	1,A		; Set Zero flag if still transmitting character	
        RET
		
		
		
		
msgA:	.db "Teste porta serial A", CR, LF, 0
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
    

; Z80 Mini - CoreBase
; 04/2025
; Requerimento: Placa base.
;
;
;
;   ============== COMPILADOR ===================
;
;   Compilador (https://k1.spdns.de/Develop/Projects/zasm/Distributions/):
;
;       Win(CMD):           zasm.exe --z80 -w -u --bin  Z80MiniCoreBaseSerial.asm
;       Win(Powershell):    ./zasm.exe --z80 -w -u --bin  Z80MiniCoreBaseSerial.asm
;       Macos:              ./zasm --z80 -w -u --bin  Z80MiniCoreBaseSerial.asm
;
;
;   =============== GRAVAÇÃO ====================
;
;     GRAVAÇÃO (32kb) (TL866 2 Plus - MacOS):
;	    minipro -p AT28C256 -w Z80MiniCoreBaseSerial.rom -s	
;
;
;   =============== HARDWARE ====================
;         - CPU Z80@7.37280Mhz
;         - Rom 32k 0000h - 7FFFh
;         - Ram 32k 8000h - FFFFh
;         
;         - Ports:
;               - Onboard IN/OUT: 40H
;               - User IN/OUT: C0H
;
; -----------------------------------------------------------------------------
; H_Delay CONFIG
; -----------------------------------------------------------------------------
kCPUClock:  .EQU 7372800       ;CPU clock speed in Hz
kDelayOH:   .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:   .EQU 26             ;Inner loop time in Tcycles
kDelayTA:   .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:   .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:  .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop


CR		.EQU	0DH
LF		.EQU	0AH
ESC		.EQU	1BH
CTRLC	.EQU	03H
CLS		.EQU	0CH

; PORTS
    ; SIO/2 - 115200
SIOA_D		.EQU	$00
SIOA_C		.EQU	$02
SIOB_D		.EQU	$01 ; Não usado
SIOB_C		.EQU	$03 ; Não usado



; MEM MAP
stack_point .EQU    $FF00



    .ORG $0000
RST00:	DI			    ;Disable INTerrupts
		JP	INIT		;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232 wait for TXDONE first.
;------------------------------------------------------------------------------
    .ORG $0008
RST08:	JP	conout

;------------------------------------------------------------------------------
; RX a character from buffer wait until char ready.
;------------------------------------------------------------------------------
    .ORG $0010
RST10:		JP	conin

	.ORG $0100
	JP DELAY_250ms
	JP DELAY_500ms


INIT:
    LD SP, stack_point
    CALL setup_serial

    LD HL, msg_bemvindo
    CALL PRINT

monitor:
	LD HL, monitor ; point to return to monitor
	PUSH HL
monitor0:
	CALL TXCRLF	; Entry point for Monitor, Normal	
	LD   A,'>'	; Get a ">"	
	RST 08H		; print it

monitor1:
	RST 10H	; Get a character from serial
	CP   ' '	; <spc> or less? 	
	JR   C, monitor1	; Go back

	CP   ':'	; ":"?
	JP   Z,LOAD	; First character of a HEX load

	RST 08H	; Print char on console

	CP   '?'
	JP   Z,HELP

	AND  $5F	; Make character uppercase

	CP   'R' 	; reset
	JP   Z, RST00

	CP   'G'
	JP   Z,GOTO

	LD   A,'?'	; Get a "?"	
	RST 08H		; Print it

    jp monitor0


setup_serial:
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
    RET

; APIs
DELAY_250ms:
	LD DE, $00FA
	CALL DELAY_DE
	RET

DELAY_500ms:
	LD DE, $01f4
	CALL DELAY_DE
	RET


; GOTO command
GOTO:
	CALL GETHL		; ENTRY POINT FOR <G>oto addr. Get XXXX from user.
	RET  C			; Return if invalid       	
	PUSH HL
	RET			; Jump to HL address value


; HELP
HELP:
	LD HL, msg_help
	CALL PRINT
	RET


;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
PRINT:  LD   A,(HL)	; Get character
		OR   A		; Is it $00 ?
		RET  Z		; Then RETurn on terminator
		RST  08H	; Print it
		INC  HL		; Next Character
		JR   PRINT	; Continue until $00

TXCRLF:	LD   A,$0D	; 
		RST  08H	; Print character 
		LD   A,$0A	; 
		RST  08H	; Print character
		RET

;------------------------------------------------------------------------------
; Console output routine - Serial
; Output port to send a character.
;------------------------------------------------------------------------------
conout:		PUSH	AF		; Store character
conoutA1:	CALL	CKSIOA		; See if SIO channel A is finished transmitting
		JR	Z, conoutA1	; Loop until SIO flag signals ready
		POP	AF		; RETrieve character
		OUT	(SIOA_D),A	; OUTput the character
		RET

conin:
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
	

CKSIOA:
		SUB	A
		OUT 	(SIOA_C),A
		IN   	A,(SIOA_C)	; Status byte D2=TX Buff Empty, D0=RX char ready	
		RRCA			; Rotates RX status into Carry Flag,	
		BIT  	1,A		; Set Zero flag if still transmitting character	
        RET


;------------------------------------------------------------------------------
; Get a character from the console, must be $20-$7F to be valid (no control characters)
; <Ctrl-c> and <SPACE> breaks with the Zero Flag set
;------------------------------------------------------------------------------	
GETCHR	RST 10H	; RX a Character
		CP   $03	; <ctrl-c> User break?
		RET  Z			
		CP   $20	; <space> or better?
		JR   C,GETCHR	; Do it again until we get something usable
		RET

;------------------------------------------------------------------------------
; Gets two ASCII characters from the console (assuming them to be HEX 0-9 A-F)
; Moves them into B and C, converts them into a byte value in A and updates a
; Checksum value in E
;------------------------------------------------------------------------------
GET2	CALL GETCHR	; Get us a valid character to work with
		LD   B,A	; Load it in B
		CALL GETCHR	; Get us another character
		LD   C,A	; load it in C
		CALL BCTOA	; Convert ASCII to byte
		LD   C,A	; Build the checksum
		LD   A,E
		SUB  C		; The checksum should always equal zero when checked
		LD   E,A	; Save the checksum back where it came from
		LD   A,C	; Retrieve the byte and go back
		RET

;------------------------------------------------------------------------------
; Gets four Hex characters from the console, converts them to values in HL
;------------------------------------------------------------------------------
GETHL		LD   HL,$0000	; Gets xxxx but sets Carry Flag on any Terminator
		CALL ECHO	; RX a Character
		CP   $0D	; <CR>?
		JR   NZ,GETX2	; other key		
SETCY		SCF		; Set Carry Flag
		RET             ; and Return to main program		
;------------------------------------------------------------------------------
; This routine converts last four hex characters (0-9 A-F) user types into a value in HL
; Rotates the old out and replaces with the new until the user hits a terminating character
;------------------------------------------------------------------------------
GETX		LD   HL,$0000	; CLEAR HL
GETX1		CALL ECHO	; RX a character from the console
		CP   $0D	; <CR>
		RET  Z		; quit
		CP   $2C	; <,> can be used to safely quit for multiple entries
		RET  Z		; (Like filling both DE and HL from the user)
GETX2		CP   $03	; Likewise, a <ctrl-C> will terminate clean, too, but
		JR   Z,SETCY	; It also sets the Carry Flag for testing later.
		ADD  HL,HL	; Otherwise, rotate the previous low nibble to high
		ADD  HL,HL	; rather slowly
		ADD  HL,HL	; until we get to the top
		ADD  HL,HL	; and then we can continue on.
		SUB  $30	; Convert ASCII to byte	value
		CP   $0A	; Are we in the 0-9 range?
		JR   C,GETX3	; Then we just need to sub $30, but if it is A-F
		SUB  $07	; We need to take off 7 more to get the value down to
GETX3		AND  $0F	; to the right hex value
		ADD  A,L	; Add the high nibble to the low
		LD   L,A	; Move the byte back to A
		JR   GETX1	; and go back for next character until he terminates
;------------------------------------------------------------------------------
; Convert ASCII characters in B C registers to a byte value in A
;------------------------------------------------------------------------------
BCTOA		LD   A,B	; Move the hi order byte to A
		SUB  $30	; Take it down from Ascii
		CP   $0A	; Are we in the 0-9 range here?
		JR   C,BCTOA1	; If so, get the next nybble
		SUB  $07	; But if A-F, take it down some more
BCTOA1		RLCA		; Rotate the nybble from low to high
		RLCA		; One bit at a time
		RLCA		; Until we
		RLCA		; Get there with it
		LD   B,A	; Save the converted high nybble
		LD   A,C	; Now get the low order byte
		SUB  $30	; Convert it down from Ascii
		CP   $0A	; 0-9 at this point?
		JR   C,BCTOA2	; Good enough then, but
		SUB  $07	; Take off 7 more if it's A-F
BCTOA2		ADD  A,B	; Add in the high order nybble
		RET

;------------------------------------------------------------------------------
; Get a character and echo it back to the user
;------------------------------------------------------------------------------
ECHO	RST 10H ; rx
		RST 08H ; tx
		RET



; **********************************************************************
; Delay by DE milliseconds
;   On entry: DE = Delay time in milliseconds
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
DELAY_DE:    	PUSH AF
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



;------------------------------------------------------------------------------
; LOAD Intel Hex format file from the console.
; [Intel Hex Format is:
; 1) Colon (Frame 0)
; 2) Record Length Field (Frames 1 and 2)
; 3) Load Address Field (Frames 3,4,5,6)
; 4) Record Type Field (Frames 7 and 8)
; 5) Data Field (Frames 9 to 9+2*(Record Length)-1
; 6) Checksum Field - Sum of all byte values from Record Length to and 
;   including Checksum Field = 0 ]
;------------------------------------------------------------------------------	
LOAD:	LD   E,0	; First two Characters is the Record Length Field
		CALL GET2	; Get us two characters into BC, convert it to a byte <A>
		LD   D,A	; Load Record Length count into D
		CALL GET2	; Get next two characters, Memory Load Address <H>
		LD   H,A	; put value in H register.
		CALL GET2	; Get next two characters, Memory Load Address <L>
		LD   L,A	; put value in L register.
		CALL GET2	; Get next two characters, Record Field Type
		CP   $01	; Record Field Type 00 is Data, 01 is End of File
		JR   NZ,LOAD2	; Must be the end of that file
		CALL GET2	; Get next two characters, assemble into byte
		LD   A,E	; Recall the Checksum byte
		AND  A		; Is it Zero?
		JR   Z,LOAD00	; Print footer reached message
		JR   LOADERR	; Checksums don't add up, Error out
		
LOAD2		LD   A,D	; Retrieve line character counter	
		AND  A		; Are we done with this line?
		JR   Z,LOAD3	; Get two more ascii characters, build a byte and checksum
		CALL GET2	; Get next two chars, convert to byte in A, checksum it
		LD   (HL),A	; Move converted byte in A to memory location
		INC  HL		; Increment pointer to next memory location	
		LD   A,'.'	; Print out a "." for every byte loaded
		RST  08H	;
		DEC  D		; Decrement line character counter
		JR   LOAD2	; and keep loading into memory until line is complete
		
LOAD3		CALL GET2	; Get two chars, build byte and checksum
		LD   A,E	; Check the checksum value
		AND  A		; Is it zero?
		RET  Z

LOADERR		LD   HL,CKSUMERR  ; Get "Checksum Error" message
		CALL PRINT	; Print Message from (HL) and terminate the load
		RET

LOAD00  	LD   HL,LDETXT	; Print load complete message
		CALL PRINT
		RET


msg_bemvindo:   .db CR, LF, "Z80 Mini - CoreBase Serial", CR, LF, 0
msg_help:
		.BYTE	CR, LF
		.TEXT	"R           - Reset"
		.BYTE	CR, LF
		.TEXT	"G           - Goto nnnn"
		.BYTE	CR, LF
		.TEXT	":nnnnnn...  - Load Intel-Hex file record"
		.BYTE	CR, LF
        .BYTE   $00

CKSUMERR:
		.BYTE	"Checksum error"
		.BYTE	CR, LF,$00

LDETXT:
		.TEXT	"Load complete."
		.BYTE	CR, LF, $00

.end

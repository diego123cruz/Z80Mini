; Z80Mini - GameCore
; 05/2025
; Requerimento: Placa base + Game core - Face.
;
;
;
;   ============== COMPILADOR ===================
;
;   Compilador (https://k1.spdns.de/Develop/Projects/zasm/Distributions/):
;
;       Win(CMD):           zasm.exe --z80 -w -u --bin  Z80MiniGame.asm
;       Win(Powershell):    ./zasm.exe --z80 -w -u --bin  Z80MiniGame.asm
;       Macos:              ./zasm --z80 -w -u --bin  Z80MiniGame.asm
;
;
;   =============== GRAVAÇÃO ====================
;
;     GRAVAÇÃO (32kb) (TL866 2 Plus - MacOS):
;	    minipro -p AT28C64B -w Z80MiniGame.rom -s	
;
;
;   =============== HARDWARE ====================
;         - CPU Z80@7.37280Mhz
;         - Rom 32k 0000h - 7FFFh
;         - Ram 32k 8000h - FFFFh
;			
;		  - Display Grafico - 70h
;		  		- 128x64
;         
;         - Ports:
;               - Onboard IN/OUT: 40H
;					- Controle - pullDown (Input)
;						- bit0 - A
;						- bit1 - B
;						- bit2 - Start
;						- bit3 - Select
;						- bit4 - Right
;						- bit5 - Down
;						- bit6 - Left
;						- bit7 - Up
;
;               - User IN/OUT: C0H
;
;   =============== LCD LIB ======================
;   ; Graphical LCD 128 x 64 Library
;   ------------------------------
;   By B. Chiha May-2023
;   https://github.com/bchiha/Z80_LCD_128x64_Graphics_Library/tree/
;
;
;
; -----------------------------------------------------------------------------
; PORTS
; -----------------------------------------------------------------------------
LCDCTRL	    .EQU    $70
LCDDATA     .EQU    $71
GAMEPAD     .EQU    $40
; SIO/2 - 115200
SIOA_D		.EQU	$00
SIOA_C		.EQU	$02
SIOB_D		.EQU	$01 ; Não usado
SIOB_C		.EQU	$03 ; Não usado

; -----------------------------------------------------------------------------
; H_Delay CONFIG
; -----------------------------------------------------------------------------
kCPUClock:  .EQU 7372800       ;CPU clock speed in Hz
kDelayOH:   .EQU 36             ;Overhead for each 1ms in Tcycles
kDelayLP:   .EQU 26             ;Inner loop time in Tcycles
kDelayTA:   .EQU kCPUClock / 1000 ;CPU clock cycles per millisecond
kDelayTB:   .EQU kDelayTA - kDelayOH  ;Cycles required for inner loop
kDelayCnt:  .EQU kDelayTB / kDelayLP  ;Loop counter for inner loop

; -----------------------------------------------------------------------------
; SYSTEM SETTINGS
; -----------------------------------------------------------------------------
SYSTEM_SP:	.EQU 	$FFF0	;INITIAL STACK POINTER


; -----------------------------------------------------------------------------
; I2C SETTINGS
; -----------------------------------------------------------------------------
I2CA_BLOCK: .EQU $AE            ;I2C device addess: 24LC256 (Copy from/to Mem)
TIMEOUT:    .EQU 10000          ;Timeout loop counter


; -----------------------------------------------------------------------------
; INIT SYSTEM 
; -----------------------------------------------------------------------------
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

; =========================================================
; Int 38h - Monitor 
; =========================================================
	.org    $0038
RST38:
    DI
	PUSH HL
    LD HL, (INT_VEC)
    JP (HL)

; -----------------------------------------------------------------------------
; API
; -----------------------------------------------------------------------------
	.ORG $0100 ; API POINTER
; LCD
    JP INIT_LCD             ;Initalise the LCD
    JP CLEAR_GBUF           ;Clear the Graphics Buffer
    JP CLEAR_GR_LCD         ;Clear the Graphics LCD Screen
    JP CLEAR_TXT_LCD        ;Clear the Text LCD Screen
    JP SET_GR_MODE          ;Set Graphics Mode
    JP SET_TXT_MODE         ;Set Text Mode
    JP DRAW_BOX             ;Draw a rectangle between two points
    JP DRAW_LINE            ;Draw a line between two points
    JP DRAW_CIRCLE          ;Draw a circle from Mid X,Y to Radius
    JP DRAW_PIXEL           ;Draw one pixel at X,Y
    JP FILL_BOX             ;Draw a filled rectangle between two points
    JP FILL_CIRCLE          ;Draw a filled circle from Mid X,Y to Radius
    JP PLOT_TO_LCD          ;Display the Graphics Buffer to the LCD Screen
    JP PRINT_STRING         ;Print Text on the screen in a given row
    JP PRINT_CHARS          ;Print Characters on the screen in a given row and column
    JP DELAY_US             ;Microsecond delay for LCD updates
    JP DELAY_MS             ;Millisecond delay for LCD updates
    JP SET_BUF_CLEAR        ;Clear the Graphics buffer on after Plotting to the screen
    JP SET_BUF_NO_CLEAR     ;Retain the Graphics buffer on after Plotting to the screen
    JP CLEAR_PIXEL          ;Remove a Pixel at X,Y
    JP FLIP_PIXEL           ;Flip a Pixel On/Off at X,Y
    JP LCD_INST             ;Send a parallel or serial instruction to LCD
    JP LCD_DATA             ;Send a parallel or serial datum to LCD
    JP SER_SYNC             ;Send serial synchronise byte to LCD
    JP DRAW_GRAPHIC         ;Draw an ASCII charcter or Sprite to the LCD
    JP INV_GRAPHIC          ;Inverse graphics printing
    JP INIT_TERMINAL        ;Initialize the LCD for terminal emulation
    JP SEND_CHAR_TO_GLCD    ;Send an ASCII Character to the LCD
    JP SEND_STRING_TO_GLCD  ;Send an ASCII String to the LCD
    JP SEND_A_TO_GLCD       ;Send register A to the LCD
    JP SEND_HL_TO_GLCD      ;Send register HL to the LCD
    JP SET_CURSOR           ;Set the graphics cursor
    JP GET_CURSOR           ;Get the current cursor
    JP DISPLAY_CURSOR       ;Set Cursor on or off
    JP DELAY_DE             ;Delay in milliseconds (DE in millis)
	JP LCD_PRINT_STRING		;Print string HL, end with 0 EX: "Test", $00




INIT:
    LD SP, SYSTEM_SP
	; Init Serial
    CALL setup_serial
	LD HL, WELLCOME
    CALL PRINT

	; Init LCD
	LD DE, $0064 ; 100ms
    CALL DELAY_DE

    CALL INIT_TERMINAL
    CALL SET_GR_MODE
    CALL SET_BUF_NO_CLEAR

	XOR A
    LD (CURSOR_MENU), A

start:
	CALL CLEAR_GBUF

    LD BC, $0000
    CALL SET_CURSOR

	XOR A
	LD DE, WELLCOME_LCD
	CALL SEND_STRING_TO_GLCD

	CALL NEW_LINE_LCD

    LD A, (CURSOR_MENU)
    CP 0
    CALL MENU1 

    LD A, (CURSOR_MENU)
    CP 1
    CALL MENU2

    LD A, (CURSOR_MENU)
    CP 2
    CALL MENU3

    LD A, (CURSOR_MENU)
    CP 3
    CALL MENU4

	LD  HL, INT38
    LD  (INT_VEC), HL
    ;IM  1
    ;EI

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



LOAD_GAME:
READ_MEM_FILES:
    LD DE, $0000 ; start "D"? File
READ_MEM_NEXT:
    CALL READ_IIC_DE
    OR A
    CP 'D'
    JP Z, READ_FILE
    LD HL, MSG_EOF
    CALL LCD_CR
    CALL LCD_PRINT_STRING
    LD A, CR
    RET

READ_FILE:
    CALL LCD_CR ; new line
    CALL LCD_CR ; new line
    LD B, 16
READ_NAME:
    INC DE
    CALL READ_IIC_DE
    OR A
    CP 0
    CALL NZ, LCD_PRINT_A
    DEC B
    JP NZ, READ_NAME

READ_MEM_KEY:
    ; Show commands
    PUSH DE
    INC DE
    CALL READ_IIC_DE
    OR A
    CP 0
    CALL Z, SHOW_MSG_EXE
    CP 1
    CALL Z, SHOW_MSG_IMG
    CP 2
    CALL Z, SHOW_MSG_TXT
    POP DE
    ; wait command
read_loop:
    IN A, (GAMEPAD)
	cp 0
	JP Z, read_loop
    bit 1, A ; Next - B
    JP    NZ, READ_MEM_STEP
    bit 0, A  ; key Enter, execute - A
    JP    Z, READ_MEM_KEY
    ;read type
    INC DE
    CALL READ_IIC_DE
    OR A
    CP 0
    JP Z, READ_FILE_EXE
    CP 1
    JP Z, READ_FILE_IMG
    CP 2
    JP Z, READ_FILE_TXT
    RET

READ_MEM_STEP:
    INC DE ; type
    INC DE ; size H
    CALL READ_IIC_DE
    LD H, A
    INC DE ; size L
    CALL READ_IIC_DE
    LD L, A
READ_MEM_STEP_L:
    INC DE ; step file
    DEC HL
    LD A, H
    OR L
    JP NZ, READ_MEM_STEP_L
    INC DE ; end
    INC DE ; nex start
    JP READ_MEM_NEXT


READ_FILE_EXE:
    ; read size H
    INC DE
    CALL READ_IIC_DE
    LD B, A

    ; read size L
    INC DE
    CALL READ_IIC_DE
    LD C, A

    INC DE ; first byte file
    LD HL, $8000 ; memory user

    CALL I2C_MemRd
    POP HL ; return
    JP $8000
    RET

READ_FILE_IMG:
    ; read size H
    INC DE
    CALL READ_IIC_DE
    LD B, A

    ; read size L
    INC DE
    CALL READ_IIC_DE
    LD C, A

    INC DE ; first byte file
    LD HL, $8000 ; memory user

    CALL I2C_MemRd

    LD H, $80
    LD L, $00
    CALL LCD_IMAGE_128x64

READ_FILE_IMG_K:
    IN A, (GAMEPAD)
    bit 3, A
    JP    Z, READ_FILE_IMG_K
    LD A, CS
    RET

READ_FILE_TXT:
    CALL LCD_CLEAR

    ; read size H
    INC DE
    CALL READ_IIC_DE
    LD B, A

    ; read size L
    INC DE
    CALL READ_IIC_DE
    LD C, A

    INC DE ; first byte file
READ_FILE_TXT_L:
    CALL READ_IIC_DE
    CALL LCD_PRINT_A
    INC DE ; step file
    DEC BC
    LD A, B
    OR C
    JP NZ, READ_FILE_TXT_L
    INC DE ; end
    INC DE ; next start    
    RET


SHOW_MSG_EXE:
    LD HL, MSG_READFILE_EXE
    CALL LCD_PRINT_STRING
    RET

SHOW_MSG_IMG:
    LD HL, MSG_READFILE_IMG
    CALL LCD_PRINT_STRING
    RET

SHOW_MSG_TXT:
    LD HL, MSG_READFILE_TXT
    CALL LCD_PRINT_STRING
    RET


; Read byte in i2c, address in DE, return byte in A
READ_IIC_DE:
    PUSH BC
    PUSH DE
    PUSH HL
    LD   A, I2CA_BLOCK   ;I2C address to write to
    CALL I2C_Open
    LD   A, D           ;Address (hi) in I2C memory
    CALL I2C_Write      ;Write address
    LD   A,E            ;Address (lo) in I2C memory
    CALL I2C_Write      ;Write address
    LD   A,I2CA_BLOCK+1 ;I2C device to be read from
    CALL I2C_Open       ;Open for read
    CALL I2C_Read
    PUSH AF
    CALL I2C_Stop       ;Generate I2C stop
    POP AF
    POP HL
    POP DE
    POP BC
    RET


KEYUP:
    IN A, (GAMEPAD)
    CP 0
    JP NZ, KEYUP
    LD A, (CURSOR_MENU)
    CP 0
    JP Z, KEYUP_RES
    DEC A
    LD (CURSOR_MENU), A
    JP start
KEYUP_RES:
    LD A, 3
    LD (CURSOR_MENU), A
    JP start

KEYDOWN:
    IN A, (GAMEPAD)
    CP 0
    JP NZ, KEYDOWN
    LD A, (CURSOR_MENU)
    CP 3
    JP Z, KEYDOWN_RES
    INC A
    LD (CURSOR_MENU), A
    JP start
KEYDOWN_RES:
    XOR A
    LD (CURSOR_MENU), A
    JP start

MENU1:
    JP NZ, $+8
    LD A, 6; >
    CALL SEND_CHAR_TO_GLCD
    LD DE, MENU_LCD_1
    XOR A
	CALL SEND_STRING_TO_GLCD
    RET

MENU2:
    JP NZ, $+8
    LD A, 6; >
    CALL SEND_CHAR_TO_GLCD
    LD DE, MENU_LCD_2
    XOR A
	CALL SEND_STRING_TO_GLCD
    RET

MENU3:
    JP NZ, $+8
    LD A, 6; >
    CALL SEND_CHAR_TO_GLCD
    LD DE, MENU_LCD_3
    XOR A
	CALL SEND_STRING_TO_GLCD
    RET

MENU4:
    JP NZ, $+8
    LD A, 6; >
    CALL SEND_CHAR_TO_GLCD
    LD DE, MENU_LCD_4
    XOR A
	CALL SEND_STRING_TO_GLCD
    RET



NEW_LINE_LCD:
	LD A, CR
	CALL SEND_CHAR_TO_GLCD
	RET


INT38:
	DI
	PUSH AF
	IN A, (GAMEPAD)
	JP Z, INT38_END
	LD (GAMEPAD_KEY), A
INT38_END:
	POP AF
	POP HL
	EI
	RETI

check_keypad:
	in A, (GAMEPAD)
    BIT 7, A ; up
    JP NZ, KEYUP
    BIT 5, A ; down
    JP NZ, KEYDOWN
	BIT 0, A ; A
    JP NZ, KEY_A
	RET

KEY_A:
    IN A, (GAMEPAD)
    CP 0
    JP NZ, KEY_A
	LD A, (CURSOR_MENU)
	CP 0
	JP Z, $8000 ; Start game JP $8000
	CP 1
	JP Z, LOAD_GAME
	CP 2
	JP Z, TEST_KEYS
	CP 3
	JP Z, 0 ; reset
	JP 0


TEST_KEYS:
    CALL CLEAR_GBUF

    ; select
    LD B, 56
    LD C, 7
    LD E, $06
    IN A, ($40)
    BIT 3, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    ; Start
    LD B, 73
    LD C, 7
    LD E, $06
    IN A, ($40)
    BIT 2, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    

    ; A
    LD B, 89
    LD C, 40
    LD E, $06
    IN A, ($40)
    BIT 0, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    
    ; B
    LD B, 105
    LD C, 24
    LD E, $06
    IN A, ($40)
    BIT 1, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    
    ; Up
    LD B, 24
    LD C, 24
    LD E, $06
    IN A, ($40)
    BIT 7, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    ; Down
    LD B, 24
    LD C, 57
    LD E, $06
    IN A, ($40)
    BIT 5, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    ; Left
    LD B, 7
    LD C, 41
    LD E, $06
    IN A, ($40)
    BIT 6, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
    ; Right
    LD B, 40
    LD C, 40
    LD E, $06
    IN A, ($40)
    BIT 4, A
    JP Z, $+9
    CALL FILL_CIRCLE
    JP $+6
    CALL DRAW_CIRCLE
    
	CALL PLOT_TO_LCD

	; check select+start to exit
    IN A, (GAMEPAD)
    BIT 2, A
	JP Z, TEST_KEYS
    BIT 3, A
    JP Z, TEST_KEYS
    jp INIT


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
	CALL check_keypad ; Enquanto aguarda serial, verifica check_keypad
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





#include "LCD.asm"
#include "I2C.asm"





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

WELLCOME: .db CS, CR, CR, LF,"Z80Mini - Game core", CR, LF, 00H

WELLCOME_LCD: .db "Z80Mini - Game core", CR, CR, 00H

I2C_LIST_MSG:    .DB "I2C device found at:",CR,0
MSG_EOF  .db " - - - FIM - - - ", 00H
MSG_READFILE_EXE .db "_EXE", 00H
MSG_READFILE_IMG .db "_IMG", 00H
MSG_READFILE_TXT .db "_TXT", 00H

MENU_LCD_1:         .db " Start game", CR, 00H
MENU_LCD_2:         .db " Load from card", CR, 00H
MENU_LCD_3:         .db " Test keys", CR, 00H
MENU_LCD_4:         .db " Reset", CR, 00H


; RAM Locations - Move this section to RAM if necessary
;---------------
.ORG $F000              ;Start location
        
SBUF:   EQU 16 * $78     ;Scroll Buffer size  16 * 60 = 960 byte (10 lines), change to 20 lines (16 * 120($78))
        DS SBUF         ;Scroll Buffer space abover GBUF 
GBUF:   DS 0400H        ;Graphics Buffer 16 * 64 = 1024 byte
TGBUF:  EQU GBUF        ;Terminal GBUF
VPORT:  DW GBUF         ;View port start address
TBUF:   DW GBUF         ;Top of Buffer pointer
ENDPT:  DW 0000H        ;End Point for Line
SX:     DB 00H          ;Sign of X
SY:     DB 00H          ;Sign of Y
DX:     DW 0000H        ;Change of X
DY:     DW 0000H        ;Change of Y
ERR:    DW 0000H        ;Error Rate
RAD:    DW 0000H        ;Radius
CLRBUF: DB 00H          ;Clear Buffer Flag on LCD Displaying
CURSOR_XY: DW 0000H     ;Cursor Address X,Y
CURSOR_Y: EQU CURSOR_XY   ;Cursor Y
CURSOR_X: EQU CURSOR_XY+1 ;Cursor X
CURSOR_YS: DB 00H       ;Start Y row for new line
CURSOR_ON: DB 00H       ;Cursor on/off flag
INVERSE: DB 00H         ;Inverse Flag
PIXEL_X: DB 00H         ;Pixel X length
INT_VEC: DW 0000H       ;Vetor de interrupção
GAMEPAD_KEY: DB 00H 	;Guarda tecla lida na interrupcao
CURSOR_MENU:      .db $00	; Cursor menu

I2C_RAMCPY:         .DB    $00   ; 1 byte - RAM copy of output port
.end

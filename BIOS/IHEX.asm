

loadInit:
    LD A, $FF
    LD (LOAD_FIRST_FLAG), A

    LD HL, MSG_LOAD_HELP
    CALL SERIAL_A_PRINT_STRING

    LD DE, MSG_LOAD_HELP_LCD
    CALL sendStringToLCD

loopHexLoad:
    CALL RXDATA

    CP   ':'	; ":"?
	JR   NZ, loopHexLoad ; Aguarda :

    ; Só inicializa o flag se for a primeira linha do carregamento
	LD   A, (LOAD_FIRST_FLAG)
	CP   $FF                    ; $FF = virgem / sessão nova
	JR   NZ, monitor_do_load    ; já está no meio de um carregamento
	LD   A, $01
	LD   (LOAD_FIRST_FLAG), A   ; sinaliza: próximo LOAD é o primeiro

monitor_do_load:
	CALL    LOAD
	CALL SERIAL_A_TXCRLF
    JP loopHexLoad


CALL_IHEX:
	LD HL, MAIN_LOOP
	PUSH HL
	CALL loadInit
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
LOAD:
		LD   E,0	        ; Zera checksum
		CALL GET2	        ; Record Length -> D
		LD   D,A
		CALL GET2	        ; Endereco High -> H
		LD   H,A
		CALL GET2	        ; Endereco Low -> L
		LD   L,A
		CALL GET2	        ; Record Type -> A
		CP   $01	        ; EOF record?
		JR   NZ,LOAD2	    ; Nao: processa dados

		; --- Record tipo 01: EOF ---
		CALL GET2	        ; Consome checksum do EOF
		LD   A,E
		AND  A
		JR   Z,LOAD00       ; Checksum OK: imprime resumo
		JR   LOADERR        ; Checksum falhou

		; --- Record tipo 00: Dados ---
LOAD2:
		; Salva endereco inicial apenas na primeira linha
		LD   A, (LOAD_FIRST_FLAG)
		CP   $01                    ; e a primeira linha?
		JR   NZ, LOAD2_SKIP
		LD   A, $00
		LD   (LOAD_FIRST_FLAG), A   ; limpa flag
		LD   (LOAD_START_ADDR), HL  ; salva endereco inicial

LOAD2_SKIP:
		LD   A,D	        ; Contador de bytes da linha
		AND  A
		JR   Z,LOAD3

		CALL GET2	        ; Le proximo byte
		LD   (HL),A	        ; Grava na memoria
		INC  HL
		LD   A,'.'
		CALL OUTCH
		DEC  D
		JR   LOAD2_SKIP     ; (continua pelo loop sem re-checar o flag)

LOAD3:
		LD   (LOAD_END_ADDR), HL    ; Atualiza endereco final (apos ultimo byte)
		CALL GET2	                ; Consome checksum da linha
		LD   A,E
		AND  A
		RET  Z                      ; Checksum OK: volta pro monitor

LOADERR:
		LD   HL,CKSUMERR
		CALL SERIAL_A_PRINT_STRING

        ;LCD
        LD   DE, CKSUMERR
        CALL sendStringToLCD

        POP HL

		RET

LOAD00:
		; --- Imprime resumo do carregamento ---
		LD   HL, LDETXT
		CALL SERIAL_A_PRINT_STRING

		LD   HL, msg_load_start
		CALL SERIAL_A_PRINT_STRING
		LD   HL, (LOAD_START_ADDR)
		CALL SERIAL_A_PRINT_HL_HEX
		CALL SERIAL_A_TXCRLF

		LD   HL, msg_load_end
		CALL SERIAL_A_PRINT_STRING
		LD   HL, (LOAD_END_ADDR)
		DEC  HL                     ; aponta para o ultimo byte gravado
		CALL SERIAL_A_PRINT_HL_HEX
		CALL SERIAL_A_TXCRLF

		LD   HL, msg_load_total
		CALL SERIAL_A_PRINT_STRING
		LD   DE, (LOAD_START_ADDR)
		LD   HL, (LOAD_END_ADDR)
		OR   A                      ; limpa carry flag
		SBC  HL, DE                 ; HL = total de bytes
		CALL SERIAL_A_PRINT_HL_HEX
		CALL SERIAL_A_TXCRLF

        ; Mostra status no lcd
        LD   DE, LDETXTLCD
        CALL sendStringToLCD

        LD   DE, msg_load_start
        LD   C, 0
		CALL sendStringToLCD
		LD   HL, (LOAD_START_ADDR)
		CALL sendHLToLCD
		CALL CRLF

		LD   DE, msg_load_end
        LD   C, 0
		CALL sendStringToLCD
		LD   HL, (LOAD_END_ADDR)
		DEC  HL                     ; aponta para o ultimo byte gravado
		CALL sendHLToLCD
		CALL CRLF

		LD   DE, msg_load_total
        LD   C, 0
		CALL sendStringToLCD
		LD   DE, (LOAD_START_ADDR)
		LD   HL, (LOAD_END_ADDR)
		OR   A                      ; limpa carry flag
		SBC  HL, DE                 ; HL = total de bytes
		CALL sendHLToLCD

        CALL CRLF

        POP HL 
		RET




;------------------------------------------------------------------------------
; Get a character from the console, must be $20-$7F to be valid (no control characters)
; <Ctrl-c> and <SPACE> breaks with the Zero Flag set
;------------------------------------------------------------------------------	
GETCHR_S:	CALL INCH	; RX a Character
		CP   $03	; <ctrl-c> User break?
		RET  Z			
		CP   $20	; <space> or better?
		JR   C,GETCHR_S	; Do it again until we get something usable
		RET

;------------------------------------------------------------------------------
; Gets two ASCII characters from the console (assuming them to be HEX 0-9 A-F)
; Moves them into B and C, converts them into a byte value in A and updates a
; Checksum value in E
;------------------------------------------------------------------------------
GET2:   CALL GETCHR_S	; Get us a valid character to work with
		LD   B,A	; Load it in B
		CALL GETCHR_S	; Get us another character
		LD   C,A	; load it in C
		CALL BCTOA	; Convert ASCII to byte
		LD   C,A	; Build the checksum
		LD   A,E
		SUB  C		; The checksum should always equal zero when checked
		LD   E,A	; Save the checksum back where it came from
		LD   A,C	; Retrieve the byte and go back
		RET

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
; Imprime HL como 4 digitos hexadecimais
; Ex: HL=$80FF -> imprime "80FF"
;------------------------------------------------------------------------------
SERIAL_A_PRINT_HL_HEX:
		LD   A, H
		CALL SERIAL_A_PRINT_A_HEX
		LD   A, L
		CALL SERIAL_A_PRINT_A_HEX
		RET


;------------------------------------------------------------------------------
; Imprime byte em A como 2 digitos hexadecimais
;------------------------------------------------------------------------------
SERIAL_A_PRINT_A_HEX:
		PUSH AF
		RRCA
		RRCA
		RRCA
		RRCA
		CALL SERIAL_A_PRINT_NIBBLE
		POP  AF
		CALL SERIAL_A_PRINT_NIBBLE
		RET

SERIAL_A_PRINT_NIBBLE:
		AND  $0F
		CP   $0A
		JR   C, SERIAL_A_PRINT_NIBBLE_09
		ADD  A, $37             ; A-F  ('A'=41h, 41h-0Ah=37h)
		CALL OUTCH
		RET
SERIAL_A_PRINT_NIBBLE_09:
		ADD  A, $30             ; 0-9
		CALL OUTCH
		RET


;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
SERIAL_A_PRINT_STRING:
        LD   A,(HL)	; Get character
		OR   A		; Is it $00 ?
		RET  Z		; Then RETurn on terminator
		CALL OUTCH	; Print it
		INC  HL		; Next Character
		JR   SERIAL_A_PRINT_STRING	; Continue until $00

SERIAL_A_TXCRLF:	LD   A,$0D	; 
		CALL OUTCH	; Print character 
		LD   A,$0A	; 
		CALL OUTCH	; Print character
		RET



CKSUMERR:
		.db	"Checksum error"
		.db	CR, LF,$00

LDETXT:
		.db	"Carregamento completo."
		.db	CR, LF, $00

LDETXTLCD:
		.db	"OK..."
		.db	CR


msg_load_start:
		.db	"Inicio: "
		.db	$00

msg_load_end:
		.db	"Fim:    "
		.db	$00

msg_load_total:
		.db	"Total:  "
		.db	$00

MSG_LOAD_HELP:          .db	CR, LF
MSG_LOAD_HELP_LCD:		.db	"Aguardando envio...", CR, LF
		                .db	":nnnnnn...  - Load Intel-Hex file record", CR, LF, $00
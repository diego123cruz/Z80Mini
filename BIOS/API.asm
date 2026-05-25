
; Não altera nenhum registrador
DELAY_500MS:
    PUSH DE
    LD DE, $01F4
    CALL H_Delay
    POP DE
    RET

SET_DEFAULT_SERIAL_A:
    LD    HL,TXDATA
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE
    RET

SET_DEFAULT_SERIAL_B:
    LD    HL,TXDATA_B
    LD    (PUTCH),HL ;USE THE BITBANG SERIAL TRANSMIT
    LD    HL,RXDATA_B
    LD    (GETCH),HL  ;USE THE BITBANG SERIAL RECEIVE
    RET

;------------------------------------------------------------------------------
; Pegar 2 caracteres ASCII (0-9 A-F) converte em um byte em A
;------------------------------------------------------------------------------
SERIAL_GET_HEX_A:   CALL GETCHR_S	; Get us a valid character to work with
    LD   B,A	; Load it in B
    CALL GETCHR_S	; Get us another character
    LD   C,A	; load it in C
    CALL BCTOA	; Convert ASCII to byte
    RET

;------------------------------------------------------------------------------
; Pegar 4 caracteres ASCII (0-9 A-F) converte em HL
;------------------------------------------------------------------------------
SERIAL_GET_HEX_HL:
    CALL SERIAL_GET_HEX_A	        ; Endereco High -> H
	LD   H,A
	CALL SERIAL_GET_HEX_A	        ; Endereco Low -> L
	LD   L,A
    RET
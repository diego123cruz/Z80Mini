LCDCTRL	   .EQU 70h
LCDDATA    .EQU 71h
REGISTER   .EQU 40h
KEYREAD    .EQU 40h

CTRLC   .EQU    03H             ; Control "C"
CTRLG   .EQU    07H             ; Control "G"
BKSP    .EQU    08H             ; Back space
LF      .EQU    0AH             ; Line feed
VT      .equ    0BH             ; 
CS      .EQU    0CH             ; Clear screen
CR      .EQU    0DH             ; Carriage return [Enter]
CTRLO   .EQU    0FH             ; Control "O"
CTRLQ	.EQU	11H		        ; Control "Q"
CTRLR   .EQU    12H             ; Control "R"
CTRLS   .EQU    13H             ; Control "S"
CTRLU   .EQU    15H             ; Control "U"
ESC     .EQU    1BH             ; Escape
DEL     .EQU    7FH             ; Delete

; commands
lcd_line1	=	$80
lcd_line2	=	$C0
lcd_line3	=	$94
lcd_line4	=	$D4


lcd_comm_port .equ $70	;Port addresses. Change as needed.
lcd_data_port .equ $71
	
lcd_set_8bit .equ $38	;8-bit port, 4-line display
lcd_cursor_on .equ $0f	;Turn cursors on
lcd_cls .equ $01		;Clear the display


TEMPSTACK  .EQU     $FF00




LCD_A		=    $80EE

LCD_BUFFER_POINT    =   $80F1
LCD_DELETE_CHAR     =   $80F2 ; start 0, if delete = ff

LCD_OFFSET          =   $80F3

LCD_BUFFER          =   $8100
LCD_BUFFER_END      =   $81D2

LCD_BUFFER_SIZE     =   $D2 ;   0 - 210  buffer | ainda não pode ser maior que 255, pq só estamos
                            ;   verificando o L e não o HL... e tbm o LCD_BUFFER_SIZE é até 255







		.ORG 			0
RST00		DI
			JP	INIT
						
        .ORG     0008H
RST08       JP	TXA ;PRINTCHAR

        .ORG 0010H
RST10       JP READKEYINIT

        .ORG 0018H ; check break
RST18       ;LD	A, 0
			;CP	0
			;RET
			JP CHKKEY


KEYMAP:
.BYTE				"1234567890"
.BYTE				"QWERTYUIOP"
.BYTE				"ASDFGHJKL", CR
.BYTE				CTRLC, "ZXCVBNM ", DEL

SHIFTKEYMAP:
.BYTE				"!@#$%^&*()"
.BYTE				"`~-_=+;:'X" ; trocar X por " quando for gravar na eeprom
.BYTE				"{}[]|Y<>?/" ; trocar Y por \ quando for gravar na eeprom
.BYTE				CTRLC, ",.     ", VT, LF




WELCOMEMSG:
.BYTE     	"Z80 BASIC 4.7b",CR,LF,0



CHKKEY: 	LD  A, $40
			OUT (REGISTER), A ; line 4
			IN  A, (KEYREAD)
			CP  1
			JP  NZ, GRET
			LD  A, CTRLC
			CP	0
			RET
GRET:
	LD  A, 0
	CP 0
	RET

;---------------------------------------------------------------------------
; INIT LCD
;---------------------------------------------------------------------------
INIT:       LD        HL,TEMPSTACK    ; Temp stack
			LD        SP,HL           ; Set up a temporary stack		
			XOR		  E								; Empty E for key reading
			XOR		  A

			; reset lcd
			ld a, 30h 				; limpa lcd
			call lcd_send_command
			
			ld a, 30h 				; limpa lcd
			call lcd_send_command
			
			ld a, 30h 				; limpa lcd
			call lcd_send_command
			

			; init lcd
			ld a,lcd_set_8bit
			call lcd_send_command
	
			ld a,lcd_cursor_on
			call lcd_send_command
	
			ld a,lcd_cls
			call lcd_send_command

			ld  a, 0Ch              ; Display on, cursor off
			call lcd_send_command
			
			ld a, 06h 				; Increment cursor (shift cursor to right)
			call lcd_send_command
			
			ld a, 01h 				; limpa lcd
			call lcd_send_command


			call      init_lcd_screen    ; init logical

			IM 		  1
			LD        HL, WELCOMEMSG
			CALL	  PRINT

			EI
			JP        $0400           ; Start BASIC COLD
			HALT

loop:
    jp loop			


;---------------------------------------------------------------------------
; LCD PRINT
;---------------------------------------------------------------------------
TXA:            
				; CHAR IN A
                ; out (2), a    ; debug
ver_enter:       

                ; trata dados para o lcd
                CP      CR                     ; compara com ENTER
                jr      nz, ver_limpa

                call    shift_lcd_up
                call    show_lcd_screen
                RET

ver_limpa:
                CP      $0C                     ; compara com limpar tela
                jr      NZ, ver_line
                
                call    clear_lcd_screen
                call    show_lcd_screen
                RET

ver_line:
                CP      LF                     ; retorna começo da linha
                jr      NZ, print_lcd      

                    ;----- verificar se precisa add algo aqui
                ;call    shift_lcd_up
                ;call    show_lcd_screen
                RET   

print_lcd:
                call    print_to_lcd_screen
                call    show_lcd_screen

                RET




; =======================================================================
;
;                        DISPLAY LOGICO
;
; =======================================================================

; =======================================================================
; Inicia LCD screen
; =======================================================================
init_lcd_screen:
        PUSH    AF
        LD      A, $0
        LD      (LCD_DELETE_CHAR), A
        LD      (LCD_BUFFER_POINT), A       ; reset pointer buffer to zero
        LD      (LCD_OFFSET), A
        call    clear_lcd_screen
        POP     AF
        RET


; =======================================================================
; Limpa buffer
; =======================================================================
clear_lcd_screen:
        PUSH    AF
        PUSH    HL
        LD      HL, LCD_BUFFER
        LD      A,  LCD_BUFFER_SIZE
clear_lcd_loop:
        LD      (HL), $1B           ; char espace
        INC     HL
        DEC     A
        CP      $00
        JR      NZ, clear_lcd_loop

        POP     HL
        POP     AF

        RET

; =======================================================================
; Shift buffer  "enter"
; =======================================================================
shift_lcd_up:
        PUSH    AF
        PUSH    HL
        PUSH    DE
        PUSH    BC

        ; ----------------  remove o cursor da linha  ---------------------

        LD      HL, LCD_BUFFER
        LD      A, (LCD_BUFFER_POINT)
        LD      L, A
        LD      (HL), ' '


        ; ----------------  zera buffer point  --------------------------

        LD      A, $00
        LD      (LCD_BUFFER_POINT), A   ; zera buffer size max 20 - LCD 20x4
        

        ; --------------- invisible lines
        ;               line -7
        ;               line -6
        ;               line -5
        ;               line -4
        ;
        ;               line -3
        ;               line -2
        ;               line -1
        ;               line  0
        ;  visible
        ;               line  1
        ;               line  2
        ;               line  3
        ;               line  4

        ; ----------------  copy line -6 to -7  --------------------------
        LD      DE,     LCD_BUFFER_END-$14      ; copy to
        LD      HL,     LCD_BUFFER_END-$28      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR


        ; ----------------  copy line -5 to -6  --------------------------
        LD      DE,     LCD_BUFFER_END-$28      ; copy to
        LD      HL,     LCD_BUFFER_END-$3C      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line -4 to -5   --------------------------
        LD      DE,     LCD_BUFFER_END-$3C      ; copy to
        LD      HL,     LCD_BUFFER_END-$50      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line -3 to -4    --------------------------
        LD      DE,     LCD_BUFFER_END-$50      ; copy to
        LD      HL,     LCD_BUFFER_END-$64      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR


        ; ----------------  copy line -2 to -3    --------------------------
        LD      DE,     LCD_BUFFER_END-$64      ; copy to
        LD      HL,     LCD_BUFFER_END-$78      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR 


        ; ----------------  copy line -1 to -2  --------------------------
        LD      DE,     LCD_BUFFER_END-$78      ; copy to
        LD      HL,     LCD_BUFFER_END-$8C      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR


        ; ----------------  copy line 0 to -1  --------------------------
        LD      DE,     LCD_BUFFER_END-$8C      ; copy to
        LD      HL,     LCD_BUFFER_END-$A0      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line 0 to 1  --------------------------
        LD      DE,     LCD_BUFFER_END-$A0      ; copy to
        LD      HL,     LCD_BUFFER_END-$B4      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line 1 to 2  --------------------------
        LD      DE,     LCD_BUFFER_END-$B4      ; copy to
        LD      HL,     LCD_BUFFER_END-$C8      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line 2 to 3  --------------------------
        LD      DE,     LCD_BUFFER_END-$C8      ; copy to
        LD      HL,     LCD_BUFFER_END-$DC      ; copy from :)
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  copy line 3 to 4  --------------------------
        LD      DE,     LCD_BUFFER_END-$DC      ; copy to
        LD      HL,     LCD_BUFFER_END-$F0      ; copy from
        LD      BC,      $14                     ; copy size
        LDIR

        ; ----------------  clear line 4  --------------------------
        LD      HL, LCD_BUFFER
        LD      A,  $14 ; 20
limpa_line4:
        LD      (HL), ' '

        INC     HL
        DEC     A
        CP      $00
        JR      NZ, limpa_line4

        POP     BC
        POP     DE
        POP     HL
        POP     AF

        RET

; =======================================================================
; FUNCAO PARA PRINTAR A CHAR IN A
; =======================================================================
print_to_lcd_screen:
    ; char in register A
    PUSH    HL
    PUSH    AF  ; guarda char

    LD      A, (LCD_DELETE_CHAR)
    CP      $FF         ; delete char in screen
    JP      NZ, check_is_delete

    ; delete char
    LD      A, (LCD_BUFFER_POINT)
    dec     A
    LD      (LCD_BUFFER_POINT), A
    LD      HL, LCD_BUFFER
    LD      L, A
    LD      (HL), $1B           ; char espace

    INC     HL                  ; coloca _ para mostrar onde esta o cursor
    LD      (HL), $1B           ; coloca _ para mostrar onde esta o cursor

    LD      A, $0
    LD      (LCD_DELETE_CHAR), A

    DEC     HL           ; coloca _ para mostrar onde esta o cursor
    LD      A, '_'       ; coloca _ para mostrar onde esta o cursor
    LD      (HL), A      ; coloca _ para mostrar onde esta o cursor

    POP     AF
    POP     HL
    RET



check_is_delete:
    POP     AF
    PUSH    AF
    CP      $00          ; if $0, delete next char
    JP      NZ, continue_print
    LD      A, (LCD_BUFFER_POINT)
    CP      $0
    JP      Z, continue_print
    LD      A, $FF
    LD      (LCD_DELETE_CHAR), A
    POP     AF
    POP     HL
    RET


continue_print:
    LD      A,  (LCD_BUFFER_POINT)
    CP      $14 ; 20
    call    Z,  shift_lcd_up

    LD      HL, LCD_BUFFER

    LD      A, (LCD_BUFFER_POINT)
    LD      L, A

    POP     AF  ; recupera char in A
    PUSH    AF
    LD      (HL),  A
    INC     HL
    LD      A, L
    LD      (LCD_BUFFER_POINT), A

    ; coloca cursor
    LD      A,  (LCD_BUFFER_POINT)
    CP      $14 ; 20
    JP    Z,  continue_print_fim

    LD      A, '_'       ; coloca '_' para mostrar onde esta o cursor
    LD      (HL), A      ; coloca '_' para mostrar onde esta o cursor

continue_print_fim:
    POP     AF
    POP     HL

    RET

; =======================================================================
; Show buffer to LCD Display
; =======================================================================
show_lcd_screen:
        PUSH    AF
        PUSH    HL
        PUSH    DE

        LD      HL, LCD_BUFFER
        LD      A,  (LCD_OFFSET)
        ADD     A, L
        LD      L, A

        LD      A, lcd_line4
        call    lcd_send_command

        LD      A, (LCD_OFFSET) 
        ADD     A, $14
        LD      D, A           

print_line4:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      D
        JR      NZ, print_line4

        ;  vai para linha 3
        LD      A, lcd_line3
        call    lcd_send_command

        LD      A, D
        ADD     A, $14
        LD      D, A
print_line3:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      D
        JR      NZ, print_line3

        ;   vai para a linha 2
        LD      A, lcd_line2
        call    lcd_send_command

        LD      A, D
        ADD     A, $14
        LD      D, A
print_line2:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      D
        JR      NZ, print_line2

        ;   vai para a linha 1
        LD      A, lcd_line1
        call    lcd_send_command

        LD      A, D
        ADD     A, $14
        LD      D, A
print_line1:
        LD      A, (HL)
        call    lcd_send_data
        LD      A, L
        inc     A
        inc     HL
        CP      D
        JR      NZ, print_line1
teste:

        POP     DE
        POP     HL
        POP     AF
        RET



PRINT:          
			LD       A,(HL)          ; Get character
            OR       A               ; Is it $00 ?
            RET      Z               ; Then RETurn on terminator
            RST      08H             ; Print it
            INC      HL              ; Next Character
            JR       PRINT           ; Continue until $00
            RET


;---------------------------------------------------------------------------
; TECLADO 8X5 = 40 Teclas
;---------------------------------------------------------------------------
READKEYINIT:			PUSH			BC
						PUSH			DE
						PUSH			HL
						LD				E, 0						; E will be the last pressed key
READKEY:				LD				H, 1						; H is the line register, start with second
						LD				B, 0						; Count lines for later multiplication	
						LD				D, 0						; DE will be the adress for mask
						
NEXTKEY:				LD				A, H						
						CP				0								; All lines tried? 
						JP				Z, KEYOUT				; Then check if there was a key pressed
						OUT				(REGISTER), A		; Put current line to register
						IN				A, (KEYREAD)		; Input Keys
						AND 			$1F ; only 5 bits
						SLA				H								; Next line
						INC				B
						CP				0								; Was key zero?
						JP				Z, NEXTKEY	 		; Then try again with next lines
						LD				D, 0						; In D will be the number of the key
LOGARITHM:				INC				D								; Add one per shift
						SRL				A								; Shift key right
						JP				NZ, LOGARITHM		; If not zero shift again
						DEC				D								; Was too much
						;LD				A, 1						; Check first line for alt, shift, etc...
						;OUT				(REGISTER), A
						IN				A, (KEYREAD)
						AND				$80								; Check if first bit set (shift key pressed)
						JP				NZ, LOADSHIFT		; Then jump to read with shift
						LD				A, D						; Put read key into accu
						ADD				A, KEYMAP				; Add base of key map array
						JP				ADDOFFSET				; Jump to load key
LOADSHIFT:				LD				A, D
						ADD				A, SHIFTKEYMAP	; In this case add the base for shift		
ADDOFFSET:				ADD				A, 5						; Add 5 for every line
						DJNZ			ADDOFFSET				; Jump back (do while loop)
						SUB				5								; Since do while is one too much
TRANSKEY:				XOR				B								; Empty B
						LD				C, A						; A will be address in BC
						LD				A, (BC)					; Load key
						CP				E								; Same key?
						JP				Z, READKEY			; Then from beginning
						LD				E, A						; Otherwise save new key
						JP				READKEY					; And restart
KEYOUT:					LD				A, E
						LD				E, 0						; empty it
						OR				A								; Was a key read?
						JP				Z, READKEY			; If not restart
						;CALL			PRINTCHAR				; If yes print key
						POP				HL
						POP				DE
						POP				BC
						;RET		


				PUSH     AF
                PUSH     HL


                cp      VT         ; if key up
                JP      NZ, serialInt_check_down ; se nao for key up desvia

                PUSH    AF
                LD      A, (LCD_OFFSET)
                CP      $78
                JP      Z, serialInt_check_down_pop
                ADD     A, $14                ; tratar se LCD_OFFSET > LCD_BUFFER_END - $14
                LD      (LCD_OFFSET), A
                call    show_lcd_screen

serialInt_check_down_pop:              
                POP     AF
serialInt_check_down:


                cp      LF         ; if key down
                jp      NZ, serialInt_continue
                PUSH    AF
                ld      a, (LCD_OFFSET)
                CP      $0
                JP      Z, serialInt_continue_pop             ; se for 0 não diminuir
                SUB     $14                   ; tratar se LCD_OFFSET = 0
                LD      (LCD_OFFSET), A
                call    show_lcd_screen

serialInt_continue_pop:
                POP     AF
serialInt_continue:
                
				POP      HL
                POP      AF

                RET




					

;******************
;Send a command byte to the LCD
;Entry: A= command byte
;Exit: All preserved
;******************
lcd_send_command:
	push bc				;Preserve
	ld c,lcd_comm_port	;Command port
	
lcd_command_wait_loop:	;Busy wait
	in b,(c)			;Read status byte
	rl b				;Shift busy bit into carry flag
	jr c,lcd_command_wait_loop	;While busy
	
	out (c),a			;Send command
	pop bc				;Restore
	ret
	
;******************
;Send a data byte to the LCD
;Entry: A= data byte
;Exit: All preserved
;******************
lcd_send_data:
	push bc				;Preserve
	ld c,lcd_comm_port	;Command port
	
lcd_data_wait_loop:	;Busy wait
	in b,(c)			;Read status byte
	rl b				;Shift busy bit into carry flag
	jr c,lcd_data_wait_loop	;While busy
	
	ld c,lcd_data_port	;Data port
	out (c),a			;Send data
	pop bc				;Restore
	ret



.end

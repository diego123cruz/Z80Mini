

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



key_out:
    PUSH AF
    LD A, (KEY_CAPS)
    OR A
    JP Z, key_out_caps_off
    JP key_out_caps_on

key_out_caps_on:
    POP AF
    AND $0F ;5 4 3210 
    OUT (KEY_OUT), A
    RET

key_out_caps_off:
    POP AF
    OR $10 ;5 4 3210 
    OUT (KEY_OUT), A
    RET



; -----------------------------------------------------------------------------
;   Check break key (Basic)
; -----------------------------------------------------------------------------
CHKKEY:
    XOR A
	CALL key_out
    NOP
    NOP
    NOP
    NOP
    NOP
	IN  A, (KEY_IN)
    bit 0, a
    jp nz, GRET
	LD  A, CTRLC
	CP	0
	RET
GRET:
	LD  A, 0
	CP 0
	RET

CHANGE_CAPS:
    LD A, (KEY_CAPS)
    XOR 1
    LD (KEY_CAPS), A
CHANGE_CAPS_L:
    CALL NOP_TIME
    in a, (KEY_IN)
    bit 2, A
    JP Z, CHANGE_CAPS_L
    RET

CHECK_CAPS:
    PUSH AF
    ; check caps
    ld a, (KEY_CAPS)
    or a
    JP Z, CHECK_CAPS_F ; se não CAPS, ret
    ; a = 61h, z = 7A
    POP AF
	cp 61h
	RET C
	cp 7Bh
	RET NC 
    AND     01011111B       ; Force upper case
    OR A
    RET
CHECK_CAPS_F:
    POP AF
    RET

; -----------------------------------------------------------------------------
;   KEYREAD - KEY In A, or 0 if not press key
;   aguarda até presionar uma tecla
; -----------------------------------------------------------------------------
KEYREAD:
    PUSH    BC
	PUSH	DE
	PUSH    HL
i_read_key:
    CALL NOP_TIME
    xor a
    LD (KEY_READ), A
    ld (KEY_SHIFT), a ; Reset shift
    CALL key_out
    CALL NOP_TIME
    in a, (KEY_IN)
    bit 2, A
    CALL Z, CHANGE_CAPS
    bit 3, a
    jp NZ, r_key
    ld (KEY_SHIFT), a ; se shitft a > 0
r_key:
    ld b, 13
    ld c, 0
k_read_loop:
    ld a, c
    CALL key_out
    CALL NOP_TIME
    in a, (KEY_IN)
    and $1f
    xor $1f
    jp z, k_read_fim
    push bc
    ld b, a
    call trata_key
    pop bc
k_read_fim:
    inc c
    djnz k_read_loop
    LD A, (KEY_READ)
    OR A
    CALL CHECK_CAPS
    OR A
    POP     HL
    POP     DE
    POP     BC
    RET ; Return KEYREAD



; -----------------------------------------------------------------------------
;   KEYREADINIT - KEY In A 
;   aguarda até presionar uma tecla
; -----------------------------------------------------------------------------
KEYREADINIT:
    ; save registers (MSBASIC)
    PUSH    BC
	PUSH	DE
	PUSH    HL
init_read_key:
    CALL NOP_TIME
    xor a
    LD (KEY_READ), A
    ld (KEY_SHIFT), a ; Reset shift
    CALL key_out
    CALL NOP_TIME
    in a, (KEY_IN)
    bit 2, A
    CALL Z, CHANGE_CAPS
    bit 3, a
    jp NZ, read_key
    ld (KEY_SHIFT), a ; se shitft a > 0
read_key:
    ld b, 13
    ld c, 0
key_read_loop:
    ld a, c
    CALL key_out
    CALL NOP_TIME
    in a, (KEY_IN)
    and $1f
    xor $1f
    jp z, key_read_fim
    push bc
    ld b, a
    call trata_key
    pop bc
key_read_fim:
    inc c
    djnz key_read_loop
    LD A, (KEY_READ)
    OR A
    JP Z, init_read_key
    CALL CHECK_CAPS
    OR A
    POP     HL
    POP     DE
    POP     BC
    RET ; Return KEYREADINIT
    
; C - coluna
; B - linha
trata_key:
    ld a, b
    
    bit 0, a
    jp nz, trata_line1
    
    bit 1, a
    jp nz, trata_line2
    
    bit 2, a
    jp nz, trata_line3
    
    bit 3, a
    jp nz, trata_line4
    
    bit 4, a
    jp nz, trata_line5
    
L_fim:
    ; letra final
    ld d, 0
    ld e, c
    add hl, de
    
    ld a, (hl)
    or a
    ret z
    
    ; check shift
    ld a, (KEY_SHIFT)
    or a
    jp Z, load_a
    ld e, $41 ; 65
    add hl, de
    ; shift reset
    xor a
    ld (KEY_SHIFT), a
    
load_a:
    ld a, (hl)
    or a
    cp 0
    ret Z
    LD (KEY_READ), A
    LD B, $32
debaunce_key:
    LD DE, $0001
    PUSH BC
    CALL H_Delay
    POP BC
    in a, (KEY_IN)
    and $1f
    xor $1f
    RET Z
    DJNZ debaunce_key
    RET ; return tratar_key
    
    
trata_line1:
    ld hl, line1
    jp L_fim
trata_line2:
    ld hl, line2
    jp L_fim
trata_line3:
    ld hl, line3
    jp L_fim
trata_line4:
    ld hl, line4
    jp L_fim
trata_line5:
    ld hl, line5
    jp L_fim

NOP_TIME:
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RET

;-----------------------------
; GET A BYTE FROM KEYBOARD
;-----------------------------
GETCHR_KEYBOARD: CALL KEYREADINIT ; read key
       CP    ESC
       JR    Z,GET_ESP
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A                ;SAVE TO ECHO      
       CALL  ASC2HEX
       JR    NC,GETCHR_KEYBOARD          ;REJECT NON HEX CHARS    
       LD    HL, DATABYTE
       LD    (HL), A 
       LD    A,B         
       CALL  LCD_PRINT_A             ;ECHO VALID HEX
       
GETNYB: CALL  KEYREADINIT
       CP    ESC
       JR    Z,GET_ESP
       CP    CTRLC  ; key BK (reset)
       JP    Z, RESET_WARM
       LD    B,A               ;SAVE TO ECHO
       CALL  ASC2HEX
       JR    NC,GETNYB         ;REJECT NON HEX CHARS
       RLD
       LD    A,B
       CALL  LCD_PRINT_A             ;ECHO VALID HEX
       LD    A,(HL)
       CALL  GETOUT            ;MAKE SURE WE CLEAR THE CARRY BY SETTING IT,
       CCF                    ;AND THEN COMPLEMENTING IT
       RET   
GETOUT: SCF                    ;SET THE CARRY FLAG TO EXIT BACK TO MENU
       RET
GET_ESP:
    SCF
    LD A, CR ; ENTER on exit
    RET
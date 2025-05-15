; ---------------------------------------------------------
;   ZMini  -  inicio 08/2022
;   Diego Cruz - github.com/diego123cruz
;
;   Hardware baseado em: http://www.sunrise-ev.com/z80.htm
;   Software próprio - em construção
; ---------------------------------------------------------
;   Z80@4Mhz
;   ROM 32k - 28C256
;   RAM 32k - 65256
;   Display 7 segmentos 8 digitos
;   Teclado 16 teclas + Fn (Tecla de função? ou outra coisa?)
;   Entrada 40h
;   Saida 40h
;
;
; ---------------------------------------------------------
;   Display 7 Segmentos - In(Port40) AND 00000111b
; ---------------------------------------------------------
;
;   ------------------------------------------------
;   | 00h | 01h | 02h | 03h | 04h | 05h | 06h | 07h |
;   ------------------------------------------------
;
;               A(0)
;            ---------
;           |         |
;      F(5) |         | B(1)
;           |   G(6)  |
;            ---------
;           |         |
;      E(4) |         | C(2)
;           |         |
;            ---------         Ponto(7)
;               D(3) 
;
;
;
;
;
; ---------------------------------------------------------
; Teclado 
; ---------------------------------------------------------
;   
;   Keys:        
;       Fn - In(Port40) AND 00010000b - pulldown
;       0 - In(Port40) AND 00000111b
;
;
;
;


; ---------------------------------------------------------
; Constantes
; ---------------------------------------------------------

Port40        .equ    $40    ; System
PortC0        .equ    $C0    ; User
START_RAM     .equ    $8000
STACK_TOP         .equ    $FF00  


; ---------------------------------------------------------
; RAM MAP
; ---------------------------------------------------------
DISPLAY_LED   .equ    $FF00 ; (8) 8xDisplay

REG_SP        .equ    $FF09 ; (2) SP
REG_AF        .equ    $FF0B ; (2) AF
REG_BC        .equ    $FF0D ; (2) BC
REG_DE        .equ    $FF0F ; (2) DE
REG_HL        .equ    $FF11 ; (2) HL
REG_PC        .equ    $FF13 ; (2) PC
REG_IX        .equ    $FF15 ; (2) IX
REG_IY        .equ    $FF17 ; (2) IY
REG_IR        .equ    $FF19 ; (2) IR
REG_AF2       .equ    $FF1B ; (2) AF'
REG_BC2       .equ    $FF1D ; (2) BC'
REG_DE2       .equ    $FF1F ; (2) DE'
REG_HL2       .equ    $FF21 ; (2) HL'
RAMSIGNATURE  .equ    $FF23 ; (8) RAMSIGNATURE

.org $0000
    DI
    JP RESET_SYS

.org $0038


; Salva registradores
RESET_SYS:
    IM 1                     ; Int mode 1 - reset $38
    LD (REG_HL), HL          ; Salva HL
    POP HL                   ; Recupera o PC da pilha
    LD (REG_PC), HL          ; Salva PC
    LD (REG_SP), SP          ; Salva SP

    LD SP, REG_DE+2          ; Nova SP para salvar os registradores
    PUSH DE
    PUSH BC
    PUSH AF

    EX AF, AF'               ; Troca AF e AF'
    EXX                      ; Traca os outros registradores
    LD SP, REG_HL2+2         ; Nova SP para salvar HL', DE', etc...
    PUSH HL                  ; Salva HL'
    PUSH DE                  ; Salva DE'
    PUSH BC                  ; Salva BC'
    PUSH AF                  ; Salva AF'

    EX AF, AF'               ; Volta AF
    EXX                      ; Volta registradores

    LD	A,I		             ; Recupera IR
	LD	B,A
	LD	A,R
	LD	C,A
	PUSH BC		             ; Salva IR

	PUSH IY                  ; Salva IY
	PUSH IX                  ; Salva IX

    LD SP, STACK_TOP         ; Define Stack Pointer - SP

; Salva entradas
    LD C, Port40
    LD E, $80
    LD B, 8
RST_SYS1:
    OUT (C), E
    IN A, (C)
    LD D, A
    AND 7
    JR Z, RST_SYS_OK
    DJNZ RST_SYS1
RST_SYS_OK:

CHK_RESET	LD	HL, RAMSIGNATURE		
		LD	A,$F0		;First signature byte expected
		LD	B,8		;#bytes in signature (loop)
RAMSIG_LP	CP	(HL)
		JR  NZ,	START_COLD
		INC	L
		SUB	$F
		DJNZ	RAMSIG_LP
		JR	START_WARM

START_COLD:
    LD A, $1
    OUT (PortC0), A
    JP START_SYS

START_WARM:
    LD A, $2
    OUT (PortC0), A





START_SYS:
    	LD	HL,RAMSIGNATURE
		LD	A,$F0		;First signature byte expected
		LD	B,8		;#bytes in signature (loop)
RAMSIGN_LP	LD	(HL),A		;Save Signature
		INC	L
		SUB	$F
		DJNZ	RAMSIGN_LP
		XOR	A

    JP $




INT_38:
    







; =========================================================
; Tabela display
; =========================================================
; 
;   0 - $3F     A - $77     K - $7A     U - $1C     . - $80
;   1 - $06     B - $7C     L - $38     V - $3E     Ñ - $55
;   2 - $5B     C - $39     M - $37     W - $1D     : - $41
;   3 - $4F     D - $5E     N - $54     X - $70     ; - $88
;   4 - $66     E - $79     O - $3F     Y - $6E     _ - $08
;   5 - $6D     F - $71     P - $73     Z - $49     ~ - $01
;   6 - $7D     G - $6F     Q - $67                 ' - $20
;   7 - $07     H - $76     R - $50     + - $46     
;   8 - $7F     I - $06     S - $6D     , - $04     
;   9 - $67     J - $1E     T - $78     - - $40     

.end

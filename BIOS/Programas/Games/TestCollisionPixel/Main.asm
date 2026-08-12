#include "../../Z80MiniAPI.asm"

	.ORG 8000H
	
main:



loop:
	call clearGBUF
	
	LD BC, $0000
	LD DE, $7F3F
	call drawBox
	
	
	call keyboardA
	LD BC, (pXY)
	LD (lXY), BC
	call C, trataKey


	ld bc, $0808
	call setCursor
	
	ld a, 0	; draw image
	ld b, 8 ; X
	ld c, 8	; Y
	ld hl, monster
	call drawGraphic
	
	
	ld bc, $0F08
	call setCursor
	
	ld a, 0	; draw image
	ld b, 8 ; X
	ld c, 8	; Y
	ld hl, cubo
	call drawGraphic
	
	
	ld bc, $1F08
	call setCursor
	
	ld a, 0	; draw image
	ld b, 8 ; X
	ld c, 5	; Y
	ld hl, cubo5
	call drawGraphic
	
	
	ld bc, $2F08
	call setCursor
	
	ld a, 0		; draw image
	ld b, 16 	; X
	ld c, 12	; Y
	ld hl, cubo12
	call drawGraphic
	
	
	
	ld bc, $4F08
	call setCursor
	
	
	
	ld a, (a0)
	cp 0
	call z, load_a1
	cp 2
	call z, load_a2
	cp 4
	call z, load_a3
	
	inc a
	cp 6
	call z, zera_a0
	ld (a0), a
	
	ld a, 0		; draw image
	ld b, 8 	; X
	ld c, 8		; Y
	LD HL, (aHL)
	call drawGraphic
	
	
		
	
	call resetCollisionPixel	
	
	ld bc, (pXY)
	call setCursor
	
	ld a, 0		; draw image
	ld b, 8 	; X
	ld c, 16	; Y
	ld hl, sprite_data
	call drawGraphic
	
	
	
	LD A, $10
	OUT ($10), A
	call checkCollisionPixel
	jp NZ, colisao
	
	call plotToLCD
	
	call keyboardIsEsc
	JP NZ, 0
	jp loop
	
colisao:
	LD A, $01
	OUT ($10), A
	
	LD BC, (lXY)
	LD (pXY), BC
	jp loop
	
	
	
zera_a0:
	ld a, 0
	ret
	
load_a1:	
	LD HL, a1
	LD (aHL), HL
	RET
	
load_a2:	
	LD HL, a2
	LD (aHL), HL
	RET
	
load_a3:	
	LD HL, a3
	LD (aHL), HL
	RET
	
	
	
	
trataKey:
	cp 'w'
	jp z, Kup
	
	cp 's'
	jp z, Kdown
	
	cp 'a'
	jp z, Kleft
	
	cp 'd'
	jp z, Kright
	ret
	
Kup:
	LD BC, (pXY)
	dec c
	dec c
	LD (pXY), BC
	ret
	
Kdown:
	LD BC, (pXY)
	inc c
	inc c
	LD (pXY), BC
	ret
	
Kleft:
	LD BC, (pXY)
	dec b
	dec b
	LD (pXY), BC
	ret
	
Kright:	
	LD BC, (pXY)
	inc b
	inc b
	LD (pXY), BC
	ret
	
	
pXY:	db $1F, $1F
lXY:	db $1F, $1F

a0:	db	$00
aHL:	db	$00, $00

a1:
    DB $18, $18, $10, $16, $1C, $10, $28, $24   ; row 7
    
a2:
    DB $18, $18, $10, $16, $1C, $10, $28, $48   ; row 7

a3:
    DB $18, $18, $10, $16, $1C, $10, $28, $10   ; row 7


	
cubo5:
    DB $F8, $88, $A8, $88, $F8   ; row 4
	
cubo:
    DB $FF, $81, $BD, $BD, $BD, $BD, $81, $FF   ; row 7	
	
monster:
    DB $18, $7E, $5A, $7E, $7E, $3C, $18, $66   ; row 7

sprite_data:
    DB $3C, $7E, $5A, $7E, $66, $3C, $18, $7E, $BD, $BD, $3C, $3C, $24, $24, $24, $E7
    
cubo12:
    DB $FF, $F0, $80, $10, $BF, $90, $A0, $90, $AE, $90, $AE, $90, $AE, $D0, $AE, $F0, $A0, $F0, $BF, $90, $80, $90, $FF, $F0   ; row 11

#include "../Z80MiniAPI.asm"

PORT_OUT		.equ	$c0

    ORG $8000
    
    call clearGBUF
    
    ld bc, $0000
	call setCursor
	
    ld a, 0
	ld de, tst
	call sendStringToLCD
    
    ld a, $f0
    out (PORT_OUT), a
    call delay500ms
    
    ld a, $0f
    out (PORT_OUT), a
    call delay500ms
    
    ld a, $00
    out (PORT_OUT), a
    call delay500ms
    
    ld a, $ff
    out (PORT_OUT), a
    call delay500ms
    
    ld a, $00
    out (PORT_OUT), a
    call delay500ms
    
    ld a, $ff
    out (PORT_OUT), a
    call delay500ms

	ld h, 0
loop:
	call clearGBUF
	
	ld bc, $0000
	call setCursor
	
	ld a, 0
	ld de, msg
	call sendStringToLCD
	
	ld a, (val)
	out (PORT_OUT), a
	call sendRegToLCD
	
	ld a, (val)
	inc a
	ld (val), a
	
    JP loop
    
tst: .db "Iniciando testes... ", 0
msg: .db "Saida C0h: ", 0
val: .db 0

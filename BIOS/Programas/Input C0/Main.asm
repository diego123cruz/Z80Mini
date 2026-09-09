#include "../Z80MiniAPI.asm"

PORT_IN		.equ	$c0

    ORG $8000

loop:
	call clearGBUF
	
	ld bc, $0000
	call setCursor
	
	in a, (PORT_IN)
	
	xor $ff
	
	call sendRegToLCD
	
    
    JP loop

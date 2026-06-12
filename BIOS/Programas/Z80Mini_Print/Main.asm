#include "../Z80MiniAPI.asm"

    .org $8000
    
    ;	Initialise SIO/2 B - Printer (P2 conector)
	LD	A,$04
	OUT	(SIOB_C),A
	LD	A,$C4
	OUT	(SIOB_C),A

	LD	A,$03
	OUT	(SIOB_C),A
	LD	A,$E1
	OUT	(SIOB_C),A

	LD	A,$05
	OUT	(SIOB_C),A
	LD	A, $68
	OUT	(SIOB_C),A
	
    NOP
    NOP
    NOP
    NOP
    NOP
    
    call test_feed
    

	
	
    JP 0


delay:
    ld a, $ff
    loop_delay:
    dec a
    jp nz, loop_delay
    ret





test_feed:
    LD   A, $1B             ; ESC d n
    OUT (SIOB_D), A

    LD   A, $64
    OUT (SIOB_D), A

    LD  A, $01
    OUT (SIOB_D), A ; lines

    LD A, $0a
    OUT (SIOB_D), A

    ret

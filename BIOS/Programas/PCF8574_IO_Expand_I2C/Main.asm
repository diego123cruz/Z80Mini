#include "../Z80MiniAPI.asm"

	.ORG 8000H
	
main:
	LD A, $40
	CALL I2C_Open
	
	LD A, $FF
	CALL I2C_Write
	
	CALL I2C_Close

loop:
	CALL keyboardWaitA
	
	LD A, $41
	CALL I2C_Open
	
	CALL I2C_Read
	
	PUSH AF
	
	CALL I2C_Close
	
	POP AF
	CALL serialHexA
	
	CALL serialCRLF

	jp loop

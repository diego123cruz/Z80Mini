INCLUDE "Z80MiniAPI.asm"

    PUBLIC	OSINIT
    PUBLIC	OSRDCH
    PUBLIC	OSWRCH
    PUBLIC	OSLINE
    PUBLIC	OSSAVE
    PUBLIC	OSLOAD
    PUBLIC	OSOPEN
    PUBLIC	OSSHUT
    PUBLIC	OSBGET
    PUBLIC	OSBPUT
    PUBLIC	OSSTAT
    PUBLIC	GETEXT
    PUBLIC	GETPTR
    PUBLIC	PUTPTR
    PUBLIC	PROMPT
    PUBLIC	RESET
    PUBLIC	LTRAP
    PUBLIC	OSCLI
    PUBLIC	TRAP
    PUBLIC	OSKEY
    PUBLIC	OSCALL
;
    EXTERN	ESCAPE
    EXTERN	EXTERR
    EXTERN	CHECK
    EXTERN	CRLF
    EXTERN	TELL
;
    EXTERN	ACCS
    EXTERN	FREE
    EXTERN	HIMEM
    EXTERN	ERRLIN
    EXTERN	USER


;OSINIT - Initialise RAM mapping etc.
;If BASIC is entered by BBCBASIC FILENAME then file
;FILENAME.BBC is automatically CHAINed.
;   Outputs: DE = initial value of HIMEM (top of RAM)
;            HL = initial value of PAGE (user program)
;            Z-flag reset indicates AUTO-RUN.
;  Destroys: A,B,C,D,E,H,L,F
;
OSINIT:
        ; Reset Z flag
        or 1
SKIPLOAD:
        ld de, 0xEFFF
        ld hl, USER ; start of user memory
        ret



;OSRDCH - Read from the current input stream (keyboard).
;  Outputs: A = character
; Destroys: A,F
;
KEYGET:
OSRDCH:
        push bc
        push de
        push hl
        CALL KEYREADINIT
        pop hl
        pop de
        pop bc
        ret

;OSWRCH - Write a character to console output.
;   Inputs: A = character.
; Destroys: Nothing
;
OSWRCH:
        push af
        push bc
        push de
        push hl
        CALL SEND_CHAR_TO_GLCD
        pop hl
        pop de
        pop bc
        pop af
        ret




;OSLINE - Read/edit a complete line, terminated by CR.
;   Inputs: HL addresses destination buffer.
;           (L=0)
;  Outputs: Buffer filled, terminated by CR.
;           A=0.
; Destroys: A,B,C,D,E,H,L,F
;
OSLINE_DEL:
        DEC HL
        DEC HL
OSLINE:
        CALL OSRDCH
        CALL OSWRCH
        LD (HL), A
        INC HL

        CP 7FH ; DELETE
        JP Z, OSLINE_DEL

        CP 0DH ; CR - Enter
        JP NZ, OSLINE

        
        xor a
        ret


;OSOPEN - Open a file for reading or writing.
;   Inputs: HL addresses filename (term 0)
;           Carry set for OPENIN, cleared for OPENOUT.
;  Outputs: A = file channel (=0 if cannot open)
;           DE = file FCB
; Destroys: A,B,C,D,E,H,L,F
;
OSOPEN:
        xor a
        ret


;OSSTAT - Read file status.
;   Inputs: E = file channel
;  Outputs: Z flag set - EOF
;           (If Z then A=0)
;           DE = address of file block.
; Destroys: A,D,E,H,L,F
;
OSSTAT:
        ret


;OSBGET - Read a byte from a random disk file.
;   Inputs: E = file channel
;  Outputs: A = byte read
;           Carry set if LAST BYTE of file
; Destroys: A,B,C,F
;
OSBGET:
        xor a
        ret

;OSBPUT - Write a byte to a random disk file.
;   Inputs: E = file channel
;           A = byte to write
; Destroys: A,B,C,F
;
OSBPUT:
        xor a
        ret

;OSLOAD - Load an area of memory from a file.
;   Inputs: HL addresses filename (NULL-term)
;           DE = address at which to load
;           BC = maximum allowed size (bytes)
;  Outputs: Carry reset indicates no room for file.
; Destroys: A,B,C,D,E,H,L,F
;
OSLOAD:
        xor a
        ret

;OSLOAD_SIZE: DEFW 0x2000

;OSSAVE - Save an area of memory to a file.
;   Inputs: HL addresses filename (term CR)
;           DE = start address of data to save
;           BC = length of data to save (bytes)
; Destroys: A,B,C,D,E,H,L,F
;
OSSAVE:
        xor a
        ret


;OSSHUT - Close disk file(s).
;   Inputs: E = file channel
;           If E=0 all files are closed (except SPOOL)
; Destroys: A,B,C,D,E,H,L,F
;
OSSHUT:
    xor a
    ret


;
;GETEXT - Find file size.
;   Inputs: E = file channel
;  Outputs: DEHL = file size (0-&800000)
; Destroys: A,B,C,D,E,H,L,F
;
GETEXT:
        xor a
        ret

;
;GETPTR - Return file pointer.
;   Inputs: E = file channel
;  Outputs: DEHL = pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
GETPTR:
        xor a
        ret

;
;PUTPTR - Update file pointer.
;   Inputs: A = file channel
;           DEHL = new pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
PUTPTR:
        xor a
        ret


PROMPT:
        ld a, '>'
        call OSWRCH
        ld a, ' '
        jp OSWRCH

;
;BYE - Stop interrupts and return to CP/M.
;
BYE:
        jp 0

RESET:
        xor a
        ld (OPTVAL), a
        ret

OPTVAL: DEFS 1

;LTRAP - Test ESCAPE flag and abort if set.
; Destroys: A,F
;
LTRAP:
        xor a
        ret

;TRAP - Test ESCAPE flag and abort if set;
;       every 20th call, test for keypress.
; Destroys: A,H,L,F
;
TRAP:
        ret

;
;OSCLI - Process an "operating system" command
;
OSCLI:
        jr BYE
        ret

;
;OSKEY - Read key with time-limit, test for ESCape.
;Main function is carried out in user patch.
;   Inputs: HL = time limit (centiseconds)
;  Outputs: Carry reset if time-out
;           If carry set A = character
; Destroys: A,H,L,F
;
OSKEY:
        xor a
        ret

OSCALL:
        ret

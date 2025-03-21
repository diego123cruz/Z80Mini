;	TITLE	BBC BASIC (C) R.T.RUSSELL 1984
;
;PATCH FOR BBC BASIC TO CP/M 2.2 & 3.0
;*    PLAIN VANILLA CP/M VERSION     *
;(C) COPYRIGHT R.T.RUSSELL, 25-12-1986
;
;**  NEW TO THIS VERSION
;
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
;
;OSSAVE - Save an area of memory to a file.
;   Inputs: HL addresses filename (term CR)
;           DE = start address of data to save
;           BC = length of data to save (bytes)
; Destroys: A,B,C,D,E,H,L,F
;
STSAVE:	CALL	SAVLOD		;*SAVE
	JP	C,HUH		;"Bad command"
	PUSH	HL
	JR	OSS1
;
OSSAVE:	PUSH	BC		;SAVE
	CALL	SETUP0
OSS1:	EX	DE,HL
	CALL	CREATE
	JR	NZ,SAVE
DIRFUL:	LD	A,190
	CALL	EXTERR
	DEFM	"Directory full"
	DEFB	0
SAVE:	CALL	WRITE
	ADD	HL,BC
	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	Z,SAVE1
	JR	NC,SAVE
SAVE1:	POP	BC
CLOSE:	LD	A,16
	CALL	BDOS1
	INC	A
	RET	NZ
	LD	A,200
	CALL	EXTERR
	DEFM	"Close error"
	DEFB	0
;
;OSSHUT - Close disk file(s).
;   Inputs: E = file channel
;           If E=0 all files are closed (except SPOOL)
; Destroys: A,B,C,D,E,H,L,F
;
OSSHUT:	LD	A,E
	OR	A
	JR	NZ,SHUT1
SHUT0:	INC	E
	BIT	3,E
	RET	NZ
	PUSH	DE
	CALL	SHUT1
	POP	DE
	JR	SHUT0
;
SESHUT:	LD	HL,FLAGS
	RES	0,(HL)		;STOP EXEC
	RES	1,(HL)		;STOP SPOOL
	LD	E,8		;SPOOL/EXEC CHANNEL
SHUT1:	CALL	FIND1
	RET	Z
	XOR	A
	LD	(HL),A
	DEC	HL
	LD	(HL),A
	LD	HL,37
	ADD	HL,DE
	BIT	7,(HL)
	INC	HL
	CALL	NZ,WRITE
	LD	HL,FCBSIZ
	ADD	HL,DE
	LD	BC,(FREE)
	SBC	HL,BC
	JR	NZ,CLOSE
	LD	(FREE),DE	;RELEASE SPACE
	JR	CLOSE
;
;TYPE - *TYPE command.
;Types file to console output.
;
TYPE:	SCF			;*TYPE
	CALL	OSOPEN
	OR	A
	JR	Z,NOTFND
	LD	E,A
TYPE1:	LD	A,(FLAGS)	;TEST
	BIT	7,A		;FOR
	JR	NZ,TYPESC	;ESCape
	CALL	OSBGET
	CALL	OSWRCH		;N.B. CALLS "TEST"
	JR	NC,TYPE1
	JR	OSSHUT
;
TYPESC:	CALL	OSSHUT		;CLOSE!
	JP	ABORT
;
;OSLOAD - Load an area of memory from a file.
;   Inputs: HL addresses filename (term CR)
;           DE = address at which to load
;           BC = maximum allowed size (bytes)
;  Outputs: Carry reset indicates no room for file.
; Destroys: A,B,C,D,E,H,L,F
;
STLOAD:	CALL	SAVLOD		;*LOAD
	PUSH	HL
	JR	OSL1
;
OSLOAD:	PUSH	BC		;LOAD
	CALL	SETUP0
OSL1:	EX	DE,HL
	CALL	OPEN
	JR	NZ,LOAD0
NOTFND:	LD	A,214
	CALL	EXTERR
	DEFM	"File not found"
	DEFB	0
LOAD:	CALL	READ
	JR	NZ,LOAD1
	CALL	INCSEC
	ADD	HL,BC
LOAD0:	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	NC,LOAD
LOAD1:	POP	BC
	PUSH	AF
	CALL	CLOSE
	POP	AF
	CCF
OSCALL:	RET
;
;OSOPEN - Open a file for reading or writing.
;   Inputs: HL addresses filename (term CR)
;           Carry set for OPENIN, cleared for OPENOUT.
;  Outputs: A = file channel (=0 if cannot open)
;           DE = file FCB
; Destroys: A,B,C,D,E,H,L,F
;
OPENIT:	PUSH	AF		;SAVE CARRY
	CALL	SETUP0
	POP	AF
	CALL	NC,CREATE
	CALL	C,OPEN
	RET
;
OSOPEN:	CALL	OPENIT
	RET	Z		;ERROR
	LD	B,7		;MAX. NUMBER OF FILES
	LD	HL,TABLE+15
OPEN1:	LD	A,(HL)
	DEC	HL
	OR	(HL)
	JR	Z,OPEN2		;FREE CHANNEL
	DEC	HL
	DJNZ	OPEN1
	LD	A,192
	CALL	EXTERR
	DEFM	"Too many open files"
	DEFB	0
;
OPEN2:	LD	DE,(FREE)	;FREE SPACE POINTER
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	A,B		;CHANNEL (1-7)
	LD	HL,FCBSIZ
	ADD	HL,DE		;RESERVE SPACE
	LD	(FREE),HL
OPEN3:	LD	HL,FCB		;ENTRY FROM SPOOL/EXEC
	PUSH	DE
	LD	BC,36
	LDIR			;COPY FCB
	EX	DE,HL
	INC	HL
	LD	(HL),C		;CLEAR PTR
	INC	HL
	POP	DE
	LD	B,A
	CALL	RDF		;READ OR FILL
	LD	A,B
	JP	CHECK
;
;OSBPUT - Write a byte to a random disk file.
;   Inputs: E = file channel
;           A = byte to write
; Destroys: A,B,C,F
;
OSBPUT:	PUSH	DE
	PUSH	HL
	LD	B,A
	CALL	FIND
	LD	A,B
	LD	B,0
	DEC	HL
	LD	(HL),B		;CLEAR EOF
	INC	HL
	LD	C,(HL)
	RES	7,C
	SET	7,(HL)
	INC	(HL)
	INC	HL
	PUSH	HL
	ADD	HL,BC
	LD	(HL),A
	POP	HL
	CALL	Z,WRRDF		;WRITE THEN READ/FILL
	POP	HL
	POP	DE
	RET
;
;OSBGET - Read a byte from a random disk file.
;   Inputs: E = file channel
;  Outputs: A = byte read
;           Carry set if LAST BYTE of file
; Destroys: A,B,C,F
;
OSBGET:	PUSH	DE
	PUSH	HL
	CALL	FIND
	LD	C,(HL)
	RES	7,C
	INC	(HL)
	INC	HL
	PUSH	HL
	LD	B,0
	ADD	HL,BC
	LD	B,(HL)
	POP	HL
	CALL	PE,INCRDF	;INC SECTOR THEN READ
	CALL	Z,WRRDF		;WRITE THEN READ/FILL
	LD	A,B
	POP	HL
	POP	DE
	RET
;
;OSSTAT - Read file status.
;   Inputs: E = file channel
;  Outputs: Z flag set - EOF
;           (If Z then A=0)
;           DE = address of file block.
; Destroys: A,D,E,H,L,F
;
OSSTAT:	CALL	FIND
	DEC	HL
	LD	A,(HL)
	INC	A
	RET
;
;GETEXT - Find file size.
;   Inputs: E = file channel
;  Outputs: DEHL = file size (0-&800000)
; Destroys: A,B,C,D,E,H,L,F
;
GETEXT:	CALL	FIND
	EX	DE,HL
	LD	DE,FCB
	LD	BC,36
	PUSH	DE
	LDIR			;COPY FCB
	EX	DE,HL
	EX	(SP),HL
	EX	DE,HL
	LD	A,35
	CALL	BDOS1		;COMPUTE SIZE
	POP	HL
	XOR	A
	JR	GETPT1
;
;GETPTR - Return file pointer.
;   Inputs: E = file channel
;  Outputs: DEHL = pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
GETPTR:	CALL	FIND
	LD	A,(HL)
	ADD	A,A
	DEC	HL
GETPT1:	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	DEC	HL
	LD	H,(HL)
	LD	L,A
	SRL	D
	RR	E
	RR	H
	RR	L
	RET
;
;PUTPTR - Update file pointer.
;   Inputs: A = file channel
;           DEHL = new pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
PUTPTR:	LD	D,L
	ADD	HL,HL
	RL	E
	LD	B,E
	LD	C,H
	LD	E,A		;CHANNEL
	PUSH	DE
	CALL	FIND
	POP	AF
	AND	7FH
	BIT	7,(HL)		;PENDING WRITE?
	JR	Z,PUTPT1
	OR	80H
PUTPT1:	LD	(HL),A
	PUSH	DE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	EX	DE,HL
	OR	A
	SBC	HL,BC
	POP	HL
	POP	DE
	RET	Z
	INC	HL
	OR	A
	CALL	M,WRITE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(HL),0
	DEC	HL
	LD	(HL),B
	DEC	HL
	LD	(HL),C		;NEW RECORD NO.
	POP	HL
	JR	RDF
;
;WRRDF - Write, read; if EOF fill with zeroes.
;RDF - Read; if EOF fill with zeroes.
;   Inputs: DE address FCB.
;           HL addresses data buffer.
;  Outputs: A=0, Z-flag set.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
WRRDF:	CALL	WRITE
RDF:	CALL	READ
	DEC	HL
	RES	7,(HL)
	DEC	HL
	LD	(HL),A		;CLEAR EOF FLAG
	RET	Z
	LD	(HL),-1		;SET EOF FLAG
	INC	HL
	INC	HL
	PUSH	BC
	XOR	A
	LD	B,128
FILL:	LD	(HL),A
	INC	HL
	DJNZ	FILL
	POP	BC
	SCF
	RET
;
;INCRDF - Increment record, read; if EOF fill.
;   Inputs: DE addresses FCB.
;           HL addresses data buffer.
;  Outputs: A=1, Z-flag reset.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
INCRDF:	CALL	INCSEC
	CALL	RDF
	INC	A
	RET
;
;READ - Read a record from a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to store data.
;  Outputs: A<>0 & Z-flag reset indicates EOF.
;           Carry = 0
; Destroys: A,F
;
;BDOS1 - CP/M BDOS call.
;   Inputs: A = function number
;          DE = parameter
;  Outputs: AF = result (carry=0)
; Destroys: A,F
;
READ:	CALL	SETDMA
	LD	A,33
BDOS1:	CALL	BDOS0		;*
	JR	NZ,CPMERR	;*
	OR	A		;*
	RET			;*
CPMERR:	LD	A,255		;* CP/M 3
	CALL	EXTERR		;* BDOS ERROR
	DEFM	"CP/M Error"	;*
	DEFB	0		;*
;
BDOS0:	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY
	LD	C,A
	CALL	BDOS
	INC	H		;* TEST H
	DEC	H		;* CP/M 3 ONLY
	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	RET
;
;WRITE - Write a record to a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to get data.
; Destroys: A,F
;
WRITE:	CALL	SETDMA
	LD	A,40
	CALL	BDOS1
	JR	Z,INCSEC
	LD	A,198
	CALL	EXTERR
	DEFM	"Disk full"
	DEFB	0
;
;INCSEC - Increment random record number.
;   Inputs: DE addresses FCB.
; Destroys: F
;
INCSEC:	PUSH	HL
	LD	HL,33
	ADD	HL,DE
INCS1:	INC	(HL)
	INC	HL
	JR	Z,INCS1
	POP	HL
	RET
;
;OPEN - Open a file for access.
;   Inputs: FCB set up.
;  Outputs: DE = FCB
;           A=0 & Z-flag set indicates Not Found.
;           Carry = 0
; Destroys: A,D,E,F
;
OPEN:	LD	DE,FCB
	LD	A,15
	CALL	BDOS1
	INC	A
	RET
;
;CREATE - Create a disk file for writing.
;   Inputs: FCB set up.
;  Outputs: DE = FCB
;           A=0 & Z-flag set indicates directory full.
;           Carry = 0
; Destroys: A,D,E,F
;
CREATE:	CALL	CHKAMB
	LD	DE,FCB
	LD	A,19
	CALL	BDOS1		;DELETE
	LD	A,22
	CALL	BDOS1		;MAKE
	INC	A
	RET
;
;CHKAMB - Check for ambiguous filename.
; Destroys: A,D,E,F
;
CHKAMB:	PUSH	BC
	LD	DE,FCB
	LD	B,12
CHKAM1:	LD	A,(DE)
	CP	'?'
	JR	Z,AMBIG		;AMBIGUOUS
	INC	DE
	DJNZ	CHKAM1
	POP	BC
	RET
AMBIG:	LD	A,204
	CALL	EXTERR
	DEFM	"Bad name"
	DEFB	0
;
;SETDMA - Set "DMA" address.
;   Inputs: HL = address
; Destroys: A,F
;
SETDMA:	LD	A,26
	EX	DE,HL
	CALL	BDOS0
	EX	DE,HL
	RET
;
;FIND - Find file parameters from channel.
;   Inputs: E = channel
;  Outputs: DE addresses FCB
;           HL addresses pointer byte (FCB+37)
; Destroys: A,D,E,H,L,F
;
FIND:	CALL	FIND1
	LD	HL,37
	ADD	HL,DE
	RET	NZ
	LD	A,222
	CALL	EXTERR
	DEFM	"Channel"
	DEFB	0
;
;FIND1 - Look up file table.
;   Inputs: E = channel
;  Outputs: Z-flag set = file not opened
;           If NZ, DE addresses FCB
;                  HL points into table
; Destroys: A,D,E,H,L,F
;
FIND1:	LD	A,E
	AND	7
	ADD	A,A
	LD	E,A
	LD	D,0
	LD	HL,TABLE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,D
	OR	E
	RET
;
;SETUP - Set up File Control Block.
;   Inputs: HL addresses filename
;           Format  [A:]FILENAME[.EXT]
;           Device defaults to current drive
;           Extension defaults to .BBC
;           A = fill character
;  Outputs: HL updated
;           A = terminator
;           BC = 128
; Destroys: A,B,C,H,L,F
;
;FCB FORMAT (36 BYTES TOTAL):
; 0      0=SAME DISK, 1=DISK A, 2=DISK B (ETC.)
; 1-8    FILENAME, PADDED WITH SPACES
; 9-11   EXTENSION, PADDED WITH SPACES
; 12     CURRENT EXTENT, SET TO ZERO
; 32-35  CLEARED TO ZERO
;
SETUP0:	LD	A,' '
SETUP:	PUSH	DE
	PUSH	HL
	LD	DE,FCB+9
	LD	HL,BBC
	LD	BC,3
	LDIR
	LD	HL,FCB+32
	LD	B,4
SETUP1:	LD	(HL),C
	INC	HL
	DJNZ	SETUP1
	POP	HL
	LD	C,A
	XOR	A
	LD	(DE),A
	POP	DE
	CALL	SKIPSP
	CP	'"'
	JR	NZ,SETUP2
	INC	HL
	CALL	SKIPSP
	CALL	SETUP2
	CP	'"'
	INC	HL
	JR	Z,SKIPSP
BADSTR:	LD	A,253
	CALL	EXTERR
	DEFM	"Bad string"
	DEFB	0
;
PARSE:	LD	A,(HL)
	INC	HL
	CP	'`'
	RET	NC
	CP	'?'
	RET	C
	XOR	40H
	RET
;
SETUP2:	PUSH	DE
	INC	HL
	LD	A,(HL)
	CP	':'
	DEC	HL
	LD	A,B
	JR	NZ,DEVICE
	LD	A,(HL)		;DRIVE
	AND	31
	INC	HL
	INC	HL
DEVICE:	LD	DE,FCB
	LD	(DE),A
	INC	DE
	LD	B,8
COPYF:	LD	A,(HL)
	CP	'.'
	JR	Z,COPYF1
	CP	' '
	JR	Z,COPYF1
	CP	CR
	JR	Z,COPYF1
	CP	'='
	JR	Z,COPYF1
	CP	'"' ; " 
	JR	Z,COPYF1
	LD	C,'?'
	CP	'*'
	JR	Z,COPYF1
	LD	C,' '
	INC	HL
	CP	'|'
	JR	NZ,COPYF2
	CALL	PARSE
	JR	COPYF0
COPYF1:	LD	A,C
COPYF2:	CALL	UPPRC
COPYF0:	LD	(DE),A
	INC	DE
	DJNZ	COPYF
COPYF3:	LD	A,(HL)
	INC	HL
	CP	'*'
	JR	Z,COPYF3
	CP	'.'
	LD	BC,3*256+' '
	LD	DE,FCB+9
	JR	Z,COPYF
	DEC	HL
	POP	DE
	LD	BC,128
SKIPSP:	LD	A,(HL)
	CP	' '
	RET	NZ
	INC	HL
	JR	SKIPSP
;
BBC:	DEFM	"BBC"
;
;HEX - Read a hex string and convert to binary.
;   Inputs: HL = text pointer
;  Outputs: HL = updated text pointer
;           DE = value
;            A = terminator (spaces skipped)
; Destroys: A,D,E,H,L,F
;
HEX:	LD	DE,0		;INITIALISE
	CALL	SKIPSP
HEX1:	LD	A,(HL)
	CALL	UPPRC
	CP	'0'
	JR	C,SKIPSP
	CP	'9'+1
	JR	C,HEX2
	CP	'A'
	JR	C,SKIPSP
	CP	'F'+1
	JR	NC,SKIPSP
	SUB	7
HEX2:	AND	0FH
	EX	DE,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	OR	E
	LD	E,A
	INC	HL
	JR	HEX1
;
;OSCLI - Process an "operating system" command
;
OSCLI:	CALL	SKIPSP
	CP	CR
	RET	Z
	CP	'|'
	RET	Z
	CP	'.'
	JP	Z,DOT		;*.
	EX	DE,HL
	LD	HL,COMDS
OSCLI0:	LD	A,(DE)
	CALL	UPPRC
	CP	(HL)
	JR	Z,OSCLI2
	JR	C,HUH
OSCLI1:	BIT	7,(HL)
	INC	HL
	JR	Z,OSCLI1
	INC	HL
	INC	HL
	JR	OSCLI0
;
OSCLI2:	PUSH	DE
OSCLI3:	INC	DE
	INC	HL
	LD	A,(DE)
	CALL	UPPRC
	CP	'.'		;ABBREVIATED?
	JR	Z,OSCLI4
	XOR	(HL)
	JR	Z,OSCLI3
	CP	80H
	JR	Z,OSCLI4
	POP	DE
	JR	OSCLI1
;
OSCLI4:	POP	AF
	INC	DE
OSCLI5:	BIT	7,(HL)
	INC	HL
	JR	Z,OSCLI5
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	PUSH	HL
	EX	DE,HL
	JP	SKIPSP
;
;
ERA:	CALL	SETUP0		;*ERA, *ERASE
	LD	C,19
	JR	XEQ		;"DELETE"
;
RES:	LD	C,13		;*RESET
	JR	XEQ		;"RESET"
;
DRV:	CALL	SETUP0		;*DRIVE
	LD	A,(FCB)
	DEC	A
	JP	M,HUH
	LD	E,A
	LD	C,14
	JR	XEQ0
;
REN:	CALL	SETUP0		;*REN, *RENAME
	CP	'='
	JR	NZ,HUH
	INC	HL		;SKIP "="
	PUSH	HL
	CALL	EXISTS
	LD	HL,FCB
	LD	DE,FCB+16
	LD	BC,12
	LDIR
	POP	HL
	CALL	SETUP0
	CALL	CHKAMB
	LD	C,23
XEQ:	LD	DE,FCB
XEQ0:	LD	A,(HL)
	CP	CR
	JR	NZ,HUH
BDC:	LD	A,C
	CALL	BDOS1
	RET	P
HUH:	LD	A,254
	CALL	EXTERR
	DEFM	"Bad command"
	DEFB	0
;
EXISTS:	LD	HL,DSKBUF
	CALL	SETDMA
	LD	DE,FCB
	LD	A,17
	CALL	BDOS1		;SEARCH
	INC	A
	RET	Z
	LD	A,196
	CALL	EXTERR
	DEFM	"File exists"
	DEFB	0
;
SAVLOD:	CALL	SETUP0		;PART OF *SAVE, *LOAD
	CALL	HEX
	CP	'+'
	PUSH	AF
	PUSH	DE
	JR	NZ,SAVLO1
	INC	HL
SAVLO1:	CALL	HEX
	CP	CR
	JR	NZ,HUH
	EX	DE,HL
	POP	DE
	POP	AF
	RET	Z
	OR	A
	SBC	HL,DE
	RET	NZ
	JR	HUH
;
DOT:	INC	HL
DIR:	LD	A,'?'		;*DIR
	CALL	SETUP
	CP	CR
	JR	NZ,HUH
	LD	C,17
DIR0:	LD	B,4
DIR1:	CALL	LTRAP
	LD	DE,FCB
	LD	HL,DSKBUF
	CALL	SETDMA
	LD	A,C
	CALL	BDOS1		;SEARCH DIRECTORY
	JP	M,CRLF
	RRCA
	RRCA
	RRCA
	AND	60H
	LD	E,A
	LD	D,0
	LD	HL,DSKBUF+1
	ADD	HL,DE
	PUSH	HL
	LD	DE,8		;**
	ADD	HL,DE
	LD	E,(HL)		;**
	INC	HL		;**
	BIT	7,(HL)		;SYSTEM FILE?
	POP	HL
	LD	C,18
	JR	NZ,DIR1
	PUSH	BC
	LD	A,(FCB)
	DEC	A
	LD	C,25
	CALL	M,BDC
	ADD	A,'A'
	CALL	OSWRCH
	LD	B,8
	LD	A,' '		;**
	BIT	7,E		;** READ ONLY?
	JR	Z,DIR3		;**
	LD	A,'*'		;**
DIR3:	CALL	CPTEXT
	LD	B,3
	LD	A,' '		;**
	CALL	SPTEXT
	POP	BC
	DJNZ	DIR2
	CALL	CRLF
	JR	DIR0
;
DIR2:	PUSH	BC
	LD	B,5
PAD:	LD	A,' '
	CALL	OSWRCH
	DJNZ	PAD
	POP	BC
	JR	DIR1
;
OPT:	CALL	HEX		;*OPT
	LD	A,E
	AND	3
SETOPT:	LD	(OPTVAL),A
	RET
;
RESET:	XOR	A
	JR	SETOPT
;
EXEC:	LD	A,00000001B	;*EXEC
	DEFB	1		;SKIP 2 BYTES (LD BC)
SPOOL:	LD	A,00000010B	;*SPOOL
	PUSH	AF
	PUSH	HL
	CALL	SESHUT		;STOP SPOOL/EXEC
	POP	HL
	POP	BC
	LD	A,(HL)
	CP	CR		;JUST SHUT?
	RET	Z
	LD	A,(FLAGS)
	OR	B
	LD	(FLAGS),A	;SPOOL/EXEC FLAG
	RRA			;CARRY=1 FOR EXEC
	CALL	OPENIT		;OPEN SPOOL/EXEC FILE
	RET	Z		;DIR FULL / NOT FOUND
	POP	IX		;RETURN ADDRESS
	LD	HL,(HIMEM)
	OR	A
	SBC	HL,SP		;SP=HIMEM?
	ADD	HL,SP
	JR	NZ,JPIX		;ABORT
	LD	BC,-FCBSIZ
	ADD	HL,BC		;HL=HL-FCBSIZ
	LD	(HIMEM),HL	;NEW HIMEM
	LD	(TABLE),HL	;FCB/BUFFER
	LD	SP,HL		;NEW SP
	EX	DE,HL
	CALL	OPEN3		;FINISH OPEN OPERATION
JPIX:	JP	(IX)		;"RETURN"
;
UPPRC:	AND	7FH
	CP	'`'
	RET	C
	AND	5FH		;CONVERT TO UPPER CASE
	RET
;
;*ESC COMMAND
;
ESCCTL:	LD	A,(HL)
	CALL	UPPRC		;**
	CP	'O'
	JR	NZ,ESCC1
	INC	HL
ESCC1:	CALL	HEX
	LD	A,E
	OR	A
	LD	HL,FLAGS
	RES	6,(HL)		;ENABLE ESCAPE
	RET	Z
	SET	6,(HL)		;DISABLE ESCAPE
	RET
;
;
COMDS:	DEFM	"BY"
	DEFB	'E'+80H
	DEFW	BYE
	DEFM	"CP"
	DEFB	'M'+80H
	DEFW	BYE
	DEFM	"DI"
	DEFB	'R'+80H
	DEFW	DIR
	DEFM	"DRIV"
	DEFB	'E'+80H
	DEFW	DRV
	DEFM	"ERAS"
	DEFB	'E'+80H
	DEFW	ERA
	DEFM	"ER"
	DEFB	'A'+80H
	DEFW	ERA
	DEFM	"ES"
	DEFB	'C'+80H
	DEFW	ESCCTL
	DEFM	"EXE"
	DEFB	'C'+80H
	DEFW	EXEC
	DEFM	"LOA"
	DEFB	'D'+80H
	DEFW	STLOAD
	DEFM	"OP"
	DEFB	'T'+80H
	DEFW	OPT
	DEFM	"RENAM"
	DEFB	'E'+80H
	DEFW	REN
	DEFM	"RE"
	DEFB	'N'+80H
	DEFW	REN
	DEFM	"RESE"
	DEFB	'T'+80H
	DEFW	RES
	DEFM	"SAV"
	DEFB	'E'+80H
	DEFW	STSAVE
	DEFM	"SPOO"
	DEFB	'L'+80H
	DEFW	SPOOL
	DEFM	"TYP"
	DEFB	'E'+80H
	DEFW	TYPE
	DEFB	0FFH
;
;PTEXT - Print text
;   Inputs: HL = address of text
;            B = number of characters to print
; Destroys: A,B,H,L,F
;
CPTEXT:	PUSH	AF		;**
	LD	A,':'
	CALL	OSWRCH
	POP	AF		;**
SPTEXT:	CALL	OSWRCH		;**
PTEXT:	LD	A,(HL)
	AND	7FH
	INC	HL
	CALL	OSWRCH
	DJNZ	PTEXT
	RET
;
;OSINIT - Initialise RAM mapping etc.
;If BASIC is entered by BBCBASIC FILENAME then file
;FILENAME.BBC is automatically CHAINed.
;   Outputs: DE = initial value of HIMEM (top of RAM)
;            HL = initial value of PAGE (user program)
;            Z-flag reset indicates AUTO-RUN.
;  Destroys: A,B,C,D,E,H,L,F
;
OSINIT:	LD	C,45		;*
	LD	E,254		;*
	CALL	BDOS		;*
	LD	B,INILEN
	LD	HL,TABLE
CLRTAB:	LD	(HL),A		;CLEAR FILE TABLE ETC.
	INC	HL
	DJNZ	CLRTAB
	LD	DE,ACCS
	LD	HL,DSKBUF
	LD	C,(HL)
	INC	HL
	CP	C		;N.B. A=B=0
	JR	Z,NOBOOT
	LDIR			;COPY TO ACC$
NOBOOT:	EX	DE,HL
	LD	(HL),CR
	LD	DE,(6)		;DE = HIMEM
	LD	E,A		;PAGE BOUNDARY
	LD	HL,USER
	RET
;
;BYE - Stop interrupts and return to CP/M. 
;
BYE:	RST	0
;
;
;TRAP - Test ESCAPE flag and abort if set;
;       every 20th call, test for keypress.
; Destroys: A,H,L,F
;
;LTRAP - Test ESCAPE flag and abort if set.
; Destroys: A,F
;
TRAP:	LD	HL,TRPCNT
	DEC	(HL)
	CALL	Z,TEST20	;TEST KEYBOARD
LTRAP:	LD	A,(FLAGS)	;ESCAPE FLAG
	OR	A		;TEST
	RET	P
ABORT:	LD	HL,FLAGS	;ACKNOWLEDGE
	RES	7,(HL)		;ESCAPE
	JP	ESCAPE		;AND ABORT
;
;TEST - Sample for ESCape and CTRL/S. If ESCape
;       pressed set ESCAPE flag and return.
; Destroys: A,F
;
TEST20:	LD	(HL),20
TEST:	PUSH	DE
	LD	A,6
	LD	E,0FFH
	CALL	BDOS0
	POP	DE
	OR	A
	RET	Z
	CP	'S' & 1FH	;PAUSE DISPLAY?
	JR	Z,OSRDCH
	CP	ESC
	JR	Z,ESCSET
	LD	(INKEY),A
	RET
;
;OSRDCH - Read from the current input stream (keyboard).
;  Outputs: A = character
; Destroys: A,F
;
KEYGET:	LD	B,(IX-12)	;SCREEN WIDTH
OSRDCH:	LD	A,(FLAGS)
	RRA			;*EXEC ACTIVE?
	JR	C,EXECIN
	PUSH	HL
	SBC	HL,HL		;HL=0
	CALL	OSKEY
	POP	HL
	RET	C
	JR	OSRDCH
;
;EXECIN - Read byte from EXEC file
;  Outputs: A = byte read
; Destroys: A,F
;
EXECIN:	PUSH	BC		;SAVE REGISTERS
	PUSH	DE
	PUSH	HL
	LD	E,8		;SPOOL/EXEC CHANNEL
	LD	HL,FLAGS
	RES	0,(HL)
	CALL	OSBGET
	SET	0,(HL)
	PUSH	AF
	CALL	C,SESHUT	;END EXEC IF EOF
	POP	AF
	POP	HL		;RESTORE REGISTERS
	POP	DE
	POP	BC
	RET
;
;
;OSKEY - Read key with time-limit, test for ESCape.
;Main function is carried out in user patch.
;   Inputs: HL = time limit (centiseconds)
;  Outputs: Carry reset if time-out
;           If carry set A = character
; Destroys: A,H,L,F
;
OSKEY:	PUSH	HL
	LD	HL,INKEY
	LD	A,(HL)
	LD	(HL),0
	POP	HL
	OR	A
	SCF
	RET	NZ
	PUSH	DE
	CALL	GETKEY
	POP	DE
	RET	NC
	CP	ESC
	SCF
	RET	NZ
ESCSET:	PUSH	HL
	LD	HL,FLAGS
	BIT	6,(HL)		;ESC DISABLED?
	JR	NZ,ESCDIS
	SET	7,(HL)		;SET ESCAPE FLAG
ESCDIS:	POP	HL
	RET
;
;GETKEY - Sample keyboard with specified wait.
;   Inputs: HL = Time to wait (centiseconds)
;  Outputs: Carry reset indicates time-out.
;           If carry set, A = character typed.
; Destroys: A,D,E,H,L,F
;
GETKEY:	PUSH	BC
	PUSH	HL
	LD	C,6
	LD	E,0FFH
	CALL	BDOS		;CONSOLE INPUT
	POP	HL
	POP	BC
	OR	A
	SCF
	RET	NZ		;KEY PRESSED
	OR	H
	OR	L
	RET	Z		;TIME-OUT
	PUSH	HL
	LD	HL,TIME
	LD	A,(HL)
WAIT1:	CP	(HL)
	JR	Z,WAIT1		;WAIT FOR 10 ms.
	POP	HL
	DEC	HL
	JR	GETKEY
;
;OSWRCH - Write a character to console output.
;   Inputs: A = character.
; Destroys: Nothing
;
OSWRCH:	PUSH	AF
	PUSH	DE
	PUSH	HL
	LD	E,A
	CALL	TEST
	CALL	EDPUT
	POP	HL
	POP	DE
	POP	AF
	RET
;
EDPUT:	LD	A,(FLAGS)
	BIT	3,A
	JR	Z,WRCH
	LD	A,E
	CP	' '
	RET	C
	LD	HL,(EDPTR)
	LD	(HL),E
	INC	L
	RET	Z
	LD	(EDPTR),HL
	RET
;
PROMPT:	LD	E,'>'
WRCH:	LD	A,(OPTVAL)	;FAST ENTRY
	ADD	A,3
	CP	3
	JR	NZ,WRCH1
	ADD	A,E
	LD	A,2
	JR	C,WRCH1
	LD	A,6
WRCH1:	CALL	BDOS0
	LD	HL,FLAGS
	BIT	2,(HL)
	LD	A,5		;PRINTER O/P
	CALL	NZ,BDOS0
	BIT	1,(HL)		;SPOOLING?
	RET	Z
	RES	1,(HL)
	LD	A,E		;BYTE TO WRITE
	LD	E,8		;SPOOL/EXEC CHANNEL
	PUSH	BC
	CALL	OSBPUT
	POP	BC
	SET	1,(HL)
	RET
;
TOGGLE:	LD	A,(FLAGS)
	XOR	00000100B
	LD	(FLAGS),A
	RET
;
;OSLINE - Read/edit a complete line, terminated by CR.
;   Inputs: HL addresses destination buffer.
;           (L=0)
;  Outputs: Buffer filled, terminated by CR.
;           A=0.
; Destroys: A,B,C,D,E,H,L,F
;
OSLINE:	LD	IX,KEYS
	LD	A,(FLAGS)
	BIT	3,A		;EDIT MODE?
	JR	Z,OSLIN1
	RES	3,A
	LD	(FLAGS),A
	LD	HL,(EDPTR)
	CP	L
OSLIN1:	LD	A,CR
	LD	(HL),A
	CALL	NZ,OSWRCH
	LD	L,0
	LD	C,L		;REPEAT FLAG
	JR	Z,OSWAIT	;SUPPRESS UNWANTED SPACE
UPDATE:	LD	B,0
UPD1:	LD	A,(HL)
	INC	B
	INC	HL
	CP	CR
	PUSH	AF
	PUSH	HL
	LD	E,A
	CALL	NZ,WRCH		;FAST WRCH
	POP	HL
	POP	AF
	JR	NZ,UPD1
	LD	A,' '
	CALL	OSWRCH
	LD	E,BS
UPD2:	PUSH	HL
	CALL	WRCH		;FAST WRCH
	POP	HL
	DEC	HL
	DJNZ	UPD2
OSWAIT:	LD	A,C
	DEC	B
	JR	Z,LIMIT
	OR	A		;REPEAT COMMAND?
LIMIT:	CALL	Z,KEYGET	;READ KEYBOARD
	LD	C,A		;SAVE FOR REPEAT
	LD	DE,OSWAIT	;RETURN ADDRESS
	PUSH	DE
	LD	A,(FLAGS)
	OR	A		;TEST FOR ESCAPE
	LD	A,C
	JP	M,OSEXIT
	CP	(IX-11)		;CURSOR UP     (IX-11)
	JP	Z,LEFT
	CP	(IX-10)		;CURSOR DOWN   (IX-10)
	JP	Z,RIGHT
	LD	B,0
	CP	(IX-5)		;CLEAR LEFT    (IX-5)
	JR	Z,BACK
	CP	(IX-9)		;START OF LINE (IX-9)
	JR	Z,LEFT
	CP	(IX-7)		;CLEAR RIGHT   (IX-7)
	JR	Z,DELETE
	CP	(IX-8)		;END OF LINE   (IX-8)
	JP	Z,RIGHT
	LD	C,0		;INHIBIT REPEAT
	CP	'P' & 1FH
	JP	Z,TOGGLE
	CP	(IX-6)		;DELETE LEFT   (IX-6)
	JR	Z,BACK
	CP	(IX-4)		;CURSOR LEFT   (IX-4)
	JR	Z,LEFT
	CP	(IX-2)		;DELETE RIGHT  (IX-2)
	JR	Z,DELETE
	CP	(IX-1)		;INSERT SPACE  (IX-1)
	JR	Z,INSERT
	CP	(IX-3)		;CURSOR RIGHT  (IX-3)
	JR	Z,RIGHT
	CP	' '		;PRINTING CHARACTER
	JR	NC,SAVECH
	CP	CR		;ENTER LINE
	RET	NZ
OSEXIT:	LD	A,(HL)
	CALL	OSWRCH		;WRITE REST OF LINE
	INC	HL
	SUB	CR
	JR	NZ,OSEXIT
	POP	DE		;DITCH RETURN ADDRESS
	CP	C
	JP	NZ,ABORT	;ESCAPE
	LD	A,LF
	CALL	OSWRCH
	LD	DE,(ERRLIN)
	XOR	A
	LD	L,A
	LD	(EDPTR),HL
	CP	D
	RET	NZ
	CP	E
	RET	NZ
	LD	DE,EDITST
	LD	B,4
CMPARE:	LD	A,(DE)
	CP	(HL)
	LD	A,0
	RET	NZ
	INC	HL
	INC	DE
	LD	A,(HL)
	CP	'.'
	JR	Z,ABBR
	DJNZ	CMPARE
ABBR:	XOR	A
	LD	B,A
	LD	C,L
	LD	L,A
	LD	DE,LISTST
	EX	DE,HL
	LDIR
	LD	HL,FLAGS
	SET	3,(HL)
	RET
;
BACK:	SCF			;DELETE LEFT
LEFT:	INC	L		;CURSOR LEFT
	DEC	L
	JR	Z,STOP
	LD	A,BS
	CALL	OSWRCH
	DEC	L
	RET	NC
DELETE:	LD	A,(HL)		;DELETE RIGHT
	CP	CR
	JR	Z,STOP
	LD	D,H
	LD	E,L
DEL1:	INC	DE
	LD	A,(DE)
	DEC	DE
	LD	(DE),A
	INC	DE
	CP	CR
	JR	NZ,DEL1
DEL2:	POP	DE		;DITCH
	JP	UPDATE
;
INSERT:	LD	A,CR		;INSERT SPACE
	CP	(HL)
	RET	Z
	LD	D,H
	LD	E,254
INS1:	INC	DE
	LD	(DE),A
	DEC	DE
	LD	A,E
	CP	L
	DEC	DE
	LD	A,(DE)
	JR	NZ,INS1
	LD	(HL),' '
	JR	DEL2
;
RIGHT:	LD	A,(HL)		;CURSOR RIGHT
	CP	CR
	JR	Z,STOP
SAVECH:	LD	D,(HL)		;PRINTING CHARACTER
	LD	(HL),A
	INC	L
	JR	Z,WONTGO	;LINE TOO LONG
	CALL	OSWRCH
	LD	A,CR
	CP	D
	RET	NZ
	LD	(HL),A
	RET
;
WONTGO:	DEC	L
	LD	(HL),CR
	LD	A,BEL
	CALL	OSWRCH		;BEEP!
STOP:	LD	C,0		;STOP REPEAT
	RET
;
;
EDITST:	DEFM	"EDIT"
LISTST:	DEFM	"LIST"
;
; keyboard definitions
	DEFB	80		;WIDTH
	DEFB	'E' & 1FH	;CURSOR UP
	DEFB	'X' & 1FH	;CURSOR DOWN
	DEFB	'A' & 1FH	;START OF LINE
	DEFB	'F' & 1FH	;END OF LINE
	DEFB	'T' & 1FH	;DELETE TO END OF LINE
	DEFB	8H		;BACKSPACE & DELETE
	DEFB	'U' & 1FH	;CANCEL LINE
	DEFB	'S' & 1FH	;CURSOR LEFT
	DEFB	'D' & 1FH	;CURSOR RIGHT
	DEFB	'G' & 1FH	;DELETE CHARACTER
	DEFB	'V' & 1FH	;INSERT CHARACTER
KEYS:
;
BEL	EQU	7
BS	EQU	8
HT	EQU	9
LF	EQU	0AH
VT	EQU	0BH
CR	EQU	0DH
ESC	EQU	1BH
DEL	EQU	7FH
;
BDOS	EQU	5
;
FCB	EQU	5CH
DSKBUF	EQU	80H
;
FCBSIZ	EQU	128+36+2
;
TIME:	DEFS	4
;
TRPCNT:	DEFB	10
TABLE:	DEFS	16		;FILE BLOCK POINTERS
FLAGS:	DEFB	0
INKEY:	DEFB	0
EDPTR:	DEFW	0
OPTVAL:	DEFB	0
INILEN	EQU	$-TABLE
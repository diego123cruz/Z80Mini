; **********************************************************************
; I2C support functions

; I2C bus open device
;   On entry: A = Device address (bit zero is read flag)
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             BC DE HL IX IY preserved
I2C_Open:   PUSH AF
            CALL I2C_Start      ;Output start condition
            POP  AF
            JR   I2C_Write      ;Write data byte


; I2C bus close device
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  If successfully A=0 and Z flagged
;             If unsuccessfully A=Error and NZ flagged
;             SCL = hi, SDA = hi
;             BC DE HL IX IY preserved
I2C_Close:  JP   I2C_Stop       ;Output stop condition


; **********************************************************************
; **********************************************************************
; I2C bus master driver
; **********************************************************************
; **********************************************************************

; Functions provided are:
;     I2C_Start
;     I2C_Stop
;     I2C_Read
;     I2C_Write
;
; This code has delays between all I/O operations to ensure it works
; with the slowest I2C devices
;
; I2C transfer sequence
;   +-------+  +---------+  +---------+     +---------+  +-------+
;   | Start |  | Address |  | Data    | ... | Data    |  | Stop  |
;   |       |  | frame   |  | frame 1 |     | frame N |  |       |
;   +-------+  +---------+  +---------+     +---------+  +-------+
;
;
; Start condition                     Stop condition
; Output by master device             Output by master device
;       ----+                                      +----
; SDA       |                         SDA          |
;           +-------                        -------+
;       -------+                                +-------
; SCL          |                      SCL       |
;              +----                        ----+
;
;
; Address frame
; Clock and data output from master device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | A 7 | A 6 | A 5 | A 4 | A 3 | A 2 | A 1 | R/W | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;
; Data frame 
; Clock output by master device
; Data output by transmitting device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | D 7 | D 6 | D 5 | D 4 | D 3 | D 2 | D 1 | D 0 | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;


; **********************************************************************
; I2C constants


; I2C bus master interface
; The default device option is for SC126 or compatible

I2C_PORT:   .EQU $21           ;Host I2C port address
I2C_SDA_WR: .EQU 7              ;Host I2C write SDA bit number
I2C_SDA_RD: .EQU 7              ;Host I2C read SDA bit number
I2C_SCL_WR: .EQU 0              ;Host I2C write SCL bit number
I2C_SCL_RD: .EQU 0              ;Host I2C read SCL bit number 
I2C_QUIES:  .EQU 0b10000001     ;Host I2C output port quiescent value


; I2C support constants
ERR_NONE:   .EQU 0              ;Error = None
ERR_JAM:    .EQU 1              ;Error = Bus jammed [not used]
ERR_NOACK:  .EQU 2              ;Error = No ackonowledge
ERR_TOUT:   .EQU 3              ;Error = Timeout


; **********************************************************************
; Hardware dependent I2C bus functions


; I2C bus transmit frame (address or data)
;   On entry: A = Data byte, or
;                 Address byte (bit zero is read flag)
;             SCL = low, SDA = low
;   On exit:  If successful A=0 and Z flagged
;                SCL = lo, SDA = lo
;             If unsuccessful A=Error and NZ flagged
;                SCL = high, SDA = high, I2C closed
;             BC DE HL IX IY preserved
I2C_Write:  PUSH BC             ;Preserve registers
            PUSH DE
            LD   D,A            ;Store byte to be written
            LD   B,8            ;8 data bits, bit 7 first
I2C_WriteWr_Loop:   RL   D              ;Test M.S.Bit
            JR   C,I2C_WriteBit_Hi      ;High, so skip
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = data bit)
            JR   I2C_WriteBit_Clk
I2C_WriteBit_Hi:    CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA = data bit)
I2C_WriteBit_Clk:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = data bit)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = data bit)
            DJNZ I2C_WriteWr_Loop
; Test for acknowledge from slave (receiver)
; On arriving here, SCL = lo, SDA = data bit
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/ack)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/ack)
            CALL I2C_RdPort     ;Read SDA input
            LD   B,A
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = hi)
            BIT  I2C_SDA_RD,B
            JR   NZ,I2C_WriteNoAck      ;Skip if no acknowledge
            POP  DE             ;Restore registers
            POP  BC
            XOR  A              ;Return success A=0 and Z flagged
            RET
; I2C STOP required as no acknowledge
; On arriving here, SCL = lo, SDA = hi
I2C_WriteNoAck:     CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = lo)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA = hi)
            POP  DE             ;Restore registers
            POP  BC
            LD   A,ERR_NOACK    ;Return error = No Acknowledge
            OR   A              ;  and NZ flagged
            RET


; I2C bus receive frame (data)
;   On entry: A = Acknowledge flag
;               If A != 0 the read is acknowledged
;             SCL low, SDA low
;   On exit:  If successful A = data byte and Z flagged
;               SCL = low, SDA = low
;             If unsuccessul* A = Error and NZ flagged
;               SCL = low, SDA = low
;             BC DE HL IX IY preserved
; *This function always returns successful
I2C_Read:   PUSH BC             ;Preserve registers
            PUSH DE
            LD   E,A            ;Store acknowledge flag
            LD   B,8            ;8 data bits, 7 first
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/input)
I2C_ReadRd_Loop:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/input)
            CALL I2C_RdPort     ;Read SDA input bit
            SCF                 ;Set carry flag
            BIT  I2C_SDA_RD,A   ;SDA input high?
            JR   NZ, I2C_ReadRotate     ;Yes, skip with carry flag set
            CCF                 ;Clear carry flag
I2C_ReadRotate:    RL   D              ;Rotate result into D
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA hi/input)
            DJNZ  I2C_ReadRd_Loop       ;Repeat for all 8 bits
; Acknowledge input byte
; On arriving here, SCL = lo, SDA = hi/input
            LD   A,E            ;Get acknowledge flag
            OR   A              ;A = 0? (indicates no acknowledge)
            JR   Z, I2C_ReadNoAck       ;Yes, so skip acknowledge
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA lo)
I2C_ReadNoAck:     CALL I2C_SCL_HI     ;SCL hi    (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            LD   A,D            ;Get data byte received
            POP  DE             ;Restore registers
            POP  BC
            CP   A              ;Return success Z flagged
            RET


; I2C bus start
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = low, SDA = low
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are high
I2C_Start:  CALL I2C_INIT       ;Initialise I2C control port
;           CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA ??)
;           CALL I2C_SDA_HI     ;SDA high  (SCL hi, SDA hi)
; Generate I2C start condition
            CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; I2C bus stop 
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = high, SDA = high
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are low
I2C_Stop:   CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
; Generate stop condition
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA hi)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; **********************************************************************
; I2C bus simple I/O functions
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved

I2C_INIT:   LD   A,I2C_QUIES    ;I2C control port quiescent value
            JR   I2C_WrPort

I2C_SCL_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SCL_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SDA_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SDA_WR,A
            JR   I2C_WrPort

I2C_SDA_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SDA_WR,A

I2C_WrPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            OUT  (C),A          ;Write A to I2C I/O port
            LD   (I2C_RAMCPY),A ;Write A to RAM copy
            POP  BC             ;Restore registers
            RET

I2C_RdPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            IN   A,(C)          ;Read A from I/O port
            POP  BC             ;Restore registers
            RET



;==============================================================================
;==============================================================================
;==============================================================================
;===================       FUNCTIONS    =======================================
;==============================================================================
;==============================================================================




; **********************************************************************
; List devices found on the I2C bus
;
; Test each I2C device address and reports any that acknowledge

I2CLIST:       LD   DE,LISTMsg        ;Address of message string
            CALL StrOut         ;Output string
            LD   D,0            ;First I2C device address to test
LISTLOOP:      PUSH DE             ;Preserve DE
            LD   A,D            ;Get device address to be tested
            CALL LISTTEST          ;Test if device is present
            POP  DE             ;Restore DE
            JR   NZ,LISTNEXT       ;Skip if no acknowledge
            LD   A,D            ;Get address of device tested
            CALL HexOut         ;Output as two character hex 
            CALL SpaceOut       ;Output space character
LISTNEXT:      INC  D              ;Get next write address
            INC  D
            LD   A,D            ;Address of next device to test
            OR   A              ;Have we tested all addresses?
            JR   NZ,LISTLOOP       ;No, so loop again
            CALL LineOut        ;Output new line
            RET

; Test if device at I2C address A acknowledges
;   On entry: A = I2C device address (8-bit, bit 0 = lo for write)
;   On exit:  Z flagged if device acknowledges
;             NZ flagged if devices does not acknowledge
LISTTEST:      CALL I2C_Open       ;Open I2C device for write
            RET  NZ             ;Abort if failed to open
            CALL I2C_Close      ;Close I2C device 
            XOR  A              ;Return with Z flagged
            RET




; Copy a block from I2C memory to CPU memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
I2C_MemRd:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
I2C_MemRdRepeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,I2C_MemRdReady       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,I2C_MemRdRepeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
I2C_MemRdReady:     POP  BC             ;Restore byte counter
            LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,I2CA_BLOCK+1 ;I2C device to be read from
            CALL I2C_Open       ;Open for read
            RET  NZ             ;Abort if error
I2C_MemRdRead:      DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Last byte to be read?
            CALL I2C_Read       ;Read byte with no ack on last byte
            LD   (HL),A         ;Write byte in CPU memory
            INC  HL             ;Increment CPU memory pointer
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,I2C_MemRdRead       ;No, so go read next byte
            CALL I2C_Stop       ;Generate I2C stop
            XOR  A              ;Return with success (Z flagged)
            RET


; Copy a block from CPU memory to I2C memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
; The 24LC64 requires blocks of data to be written in 64 byte (or less)
; pages.
I2C_MemWr:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
I2C_MemWrRepeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,I2C_MemWrReady       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,I2C_MemWrRepeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
I2C_MemWrReady:     POP  BC             ;Restore byte counter
I2C_MemWrBlock:     LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
I2C_MemWrWrite:     LD   A,(HL)         ;Get data byte from CPU memory
            CALL I2C_Write      ;Read byte from I2C memory
            INC  HL             ;Increment CPU memory pointer
            INC  DE             ;Increment I2C memory pointer
            DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Finished?
            JR   Z,I2C_MemWrStore       ;Yes, so go store this page
            LD   A,E            ;Get address in I2C memory (lo byte)
            AND  63             ;64 byte page boundary?
            JR   NZ,I2C_MemWrWrite      ;No, so go write another byte
I2C_MemWrStore:     CALL I2C_Stop       ;Generate I2C stop
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,I2C_MemWr   ;No, so go write some more
            RET   


; Hex byte output to console
;   On entry: A = Byte to be output in hex
;   On exit:  BC DE HL IX IY preserved
HexOut:     PUSH AF             ;Preserve byte to be output
            RRA                 ;Shift top nibble to
            RRA                 ;  botom four bits..
            RRA
            RRA
            AND  $0F           ;Mask off unwanted bits
            CALL HexOutHex           ;Output hi nibble
            POP  AF             ;Restore byte to be output
            AND  $0F           ;Mask off unwanted bits
; Output nibble as ascii character
HexOutHex:       CP   $0A           ;Nibble > 10 ?
            JR   C,HexOutSkip        ;No, so skip
            ADD  A,7            ;Yes, so add 7
HexOutSkip:      ADD  A,$30         ;Add ASCII '0'
            CALL $0008       ;Write character
            RET


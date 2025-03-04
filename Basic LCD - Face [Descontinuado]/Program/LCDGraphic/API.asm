; **********************************************************************
; **  API - Public functions                                          **
; **********************************************************************

; API: CALLs
; Copy by APITable!
    JP  SysReset           ; 0x00 = System reset
    JP  InputCharKey       ; 0x01 = Input character KeyboardOnboard (Char in A)
    JP  OutLcdChar         ; 0x02 = Output character LCD (Char in A)
    JP  OutLcdNewLine      ; 0x03 = Output new line LCD
    JP  H_Delay            ; 0x04 = Delay in milliseconds (DE in millis)
    JP  PrtSet             ; 0x05 = Set Port (Default C0)
    JP  PrtOWr             ; 0x06 = Write to output port
    JP  PrtORd             ; 0x07 = Read from output port
    JP  PrtIRd             ; 0x08 = Read from input port
    JP  PrintBufferChar    ; 0x09 = Print char to display buffer, with out show LCD (Chat in A)
    JP  DisplayImage128x64 ; 0x0A = Print image to buffer and LCD (Pointer in DE), 128x64, 1024 bytes
    JP  ClearDisplayBuffer ; 0x0B = Clear display buffer (A=$00 without show LCD, A > $00 show to LCD)
    JP  ShowBufferDisplay  ; 0x0C = Show DISPLAY buffer to LCD
    JP  LcdSetCXY          ; 0x0D = LCD Cursor X (0-20), Y (0-7) value in D(X) E(Y)
    JP  BufferImage128x64  ; 0x0E = Print image to buffer without LCD, (Pointer in DE), 128x64, 1024 bytes
    JP  SysReset           ; 0x0F = Reserved
    JP  I2COpen            ; 0x10 = Start i2c (Device address in A)
    JP  I2CClose           ; 0x11 = Close i2c 
    JP  I2CRead            ; 0x12 = I2C Read
    JP  I2CWrite           ; 0x13 = I2C Write
    JP  Print8x8           ; 0x14 = Print image 8x8 bits in buffer, A = Y[7b-4b] X[3b-0b], DE = Image pointer
    JP  Clear8x8           ; 0x15 = Print image 8x8bits with 0 in buffer, A = Y[7b-4b] X[3b-0b]




; API: Main entry point
;   On entry: C = Function number
;             A, DE = Parameters (as specified by function)
;   On exit:  AF,BC,DE,HL = Return values (as specified by function)
;             IX IY I AF' BC' DE' HL' preserved
; This handler modifies: F, B, HL but preserves A, C, DE
; Other registers depend on API function called
APIHandler: LD   HL,APITable    ;Start of function address table
            LD   B,A            ;Preserve A
            LD   A,C            ;Get function number
            CP   kAPILast+1     ;Supported function?
            RET  NC             ;No, so abort
            LD   A,B            ;Restore A
            LD   B,0
            ADD  HL,BC          ;Calculate table pointer..
            ADD  HL,BC
            LD   B,(HL)         ;Read function address from table..
            INC  HL
            LD   H,(HL)
            LD   L,B
            JP   (HL)           ;Jump to function address



; API: Function address table (function in C)
; This table contains a list of addresses, one for each API function. 
; Each is the address of the subroutine for the relevant function.
APITable:   .DW  SysReset           ; 0x00 = System reset
            .DW  InputCharKey       ; 0x01 = Input character KeyboardOnboard (Char in A)
            .DW  OutLcdChar         ; 0x02 = Output character LCD (Char in A)
            .DW  OutLcdNewLine      ; 0x03 = Output new line LCD
            .DW  H_Delay            ; 0x04 = Delay in milliseconds (DE in millis)
            .DW  PrtSet             ; 0x05 = Set Port (Default C0)
            .DW  PrtOWr             ; 0x06 = Write to output port
            .DW  PrtORd             ; 0x07 = Read from output port
            .DW  PrtIRd             ; 0x08 = Read from input port
            .DW  PrintBufferChar    ; 0x09 = Print char to display buffer, with out show LCD (Chat in A)
            .DW  DisplayImage128x64 ; 0x0A = Print image (Pointer in DE), 128x64, 1024 bytes
            .DW  ClearDisplayBuffer ; 0x0B = Clear display buffer (A=$00 without show LCD, A > $00 show to LCD)
            .DW  ShowBufferDisplay  ; 0x0C = Show DISPLAY buffer to LCD
            .DW  LcdSetCXY          ; 0x0D = LCD Cursor X (0-20), Y (0-7) value in D(X) E(Y)
            .DW  BufferImage128x64  ; 0x0E = Print image to buffer without LCD, (Pointer in DE), 128x64, 1024 bytes
            .DW  SysReset           ; 0x0F = Reserved
            .DW  I2COpen            ; 0x10 = Start i2c (Device address in A)
            .DW  I2CClose           ; 0x11 = Close i2c 
            .DW  I2CRead            ; 0x12 = I2C Read
            .DW  I2CWrite           ; 0x13 = I2C Write
            .DW  Print8x8           ; 0x14 = Print image 8x8 bits in buffer, A = Y[7b-4b] X[3b-0b], DE = Image pointer
            .DW  Clear8x8           ; 0x15 = Print image 8x8bits with 0 in buffer, A = Y[7b-4b] X[3b-0b]
kAPILast:   .EQU $15                ;Last API function number






SysReset:
    JP RESET_WARM

InputCharKey:
    JP KEYREADINIT

OutLcdChar:
    JP PRINTCHAR

OutLcdNewLine:
    LD A, CR
    JP PRINTCHAR

PrtSet:
    LD (PORT_SET), A ; define a porta padrão de entrada e saida
    RET

PrtOWr:
    LD B, A
    LD A, (PORT_SET)
    LD C, A
    LD A, B
    LD (PORT_OUT_VAL), A
    out (C), A
    RET

PrtORd: ; Return value from output port
    LD A, (PORT_OUT_VAL)
    RET

PrtIRd: ; Return value from input
    LD A, (PORT_SET)
    LD C, A
    in A, (C)
    RET

DisplayImage128x64:
    ; copy to buffer
    LD H, D   ; FROM
    LD L, E
    LD DE, DISPLAY  ; TO
    LD BC, $0400    ; 1024 bytes to copy
    LDIR            ; Start copy
    JP ShowBufferDisplay

BufferImage128x64:
    ; copy (DE) to buffer
    LD H, D   ; FROM
    LD L, E
    LD DE, DISPLAY  ; TO
    LD BC, $0400    ; 1024 bytes to copy
    LDIR            ; Start copy
    RET

ClearDisplayBuffer:
    PUSH AF
    CALL lcd_clear
    POP AF
    OR A
    CP $00
    JP Z, ClearDisplayBufferEnd
    LD HL, DISPLAY
    JP print_image
ClearDisplayBufferEnd:
    RET

ShowBufferDisplay:
    LD HL, DISPLAY
    JP print_image

I2COpen:
    JP I2C_Open

I2CClose:
    JP I2C_Close

I2CRead:
    JP I2C_Read

I2CWrite:
    JP I2C_Write

LcdSetCXY:
    PUSH AF
    LD A, D
    LD (LCD_TXT_X), A

    LD A, E
    LD (LCD_TXT_Y), A
    POP AF
    RET
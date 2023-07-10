; -----------------------------------------------------------------------------
;   START_MONITOR
; -----------------------------------------------------------------------------
START_MONITOR:
    LD  SP, SYSTEM  ; Set stack point

    LD A, 0
    LD (PORT_OUT_VAL), A ; Set default value to port

    LD A, $c0
    LD (PORT_SET), A

    CALL INIT_SOFTSERIAL ; Initialize software serial

    ; Init LCD hardware
    CALL INIT_LCD
    call delay

    call cls_TXT
    call delay

    CALL enable_grafic
    call delay

    call cls_GRAPHIC
    call delay

RESET_WARM:
    call lcd_clear

    ; Init LCD logical
    call INIT_TXT_LCD ; set cursor X Y to 0

    LD HL, MSG_MONITOR
    CALL SNDLCDMSG

    LD A, '>'
    CALL PRINTCHAR

KEY:
    CALL KEYREADINIT

    CP 'H'
    CALL Z, SHOWHELP

    CP KF1
    JP Z, $8000

    CP KF2
    JP Z, INTEL_HEX

    CP 'B'
    JP Z, BASIC

    CP 'G'
    CALL Z, GOJUMP

    CP 'M'
    CALL Z, MODIFY

    CP 'D'
    CALL Z, DSPLAY

    CP 'O'
    CALL Z, OUTPORT

    CP 'I'
    CALL Z, INPORT

    CP '1'
    CALL Z, I2CLIST

    CP '2'
    CALL Z, I2CCPUTOMEM

    CP '3'
    CALL Z, I2CMEMTOCPU

    CP '4'
    CALL Z, I2C_WR_DD

    CP '5'
    CALL Z, I2C_WR_RR_DD

    CP '6'
    CALL Z, I2C_RD

    CP '7'
    CALL Z, I2C_RD_RR

    







    LD A, CR 
    CALL PRINTCHAR
    LD A, '>' 
    CALL PRINTCHAR

    JP  KEY






;--------------------------
; D DISPLAY MEMORY LOCATION
;--------------------------
DSPLAY: LD A, 'D'
        CALL PRINTCHAR
        CALL  OUTSP       ;A SPACE
       CALL  GETCHR
       RET   C         
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; WAIT FOR CR OR ESC
;
DPLAY1: CALL  KEYREADINIT
       CP    ESC
       RET   Z
       CP    CR
       JR    NZ,DPLAY1          
       CALL  TXCRLF      ;NEWLINE
;
; DISPLAY THE LINE
;
DPLAY2: CALL  DPLINE
       LD    (ADDR),DE   ;SAVE THE NEW ADDRESS
;
; DISPLAY MORE LINES OR EXIT
;       
DPLAY3: CALL  KEYREADINIT
       JR    C,DPLAY3   
       CP    CR        ;ENTER DISPLAYS THE NEXT LINE
       JR    Z,DPLAY2
       CP    ESC         ;ESC EXITS (SHIFT + C)
       JR    NZ,DPLAY3     
       RET   
;-------------------------
; DISPLAY A LINE OF MEMORY
;-------------------------      
DPLINE: LD    DE,(ADDR)   ;ADDRESS TO BE DISPLAYED
       LD    HL,MSGBUF   ;HL POINTS TO WHERE THE OUTPUT STRING GOES
;
; DISPLAY THE ADDRESS
;         
       CALL  WRDASC     ;CONVERT ADDRESS IN DE TO ASCII
       CALL  SPCBUF        
;
; DISPLAY 4 BYTES
;
       LD    B,4 ;16
DLINE1: LD    A,(DE)
       CALL  BYTASC
       CALL  SPCBUF
       INC   DE        
       DJNZ  DLINE1
       ;CALL  SPCBUF
;
; NOW DISPLAY THE ASCII CHARACTER
; IF YOU ARE DISPLAYING NON-MEMORY AREAS THE BYTES READ AND THE ASCII COULD
; BE DIFFERENT BETWEEN THE TWO PASSES!
;
       LD    DE,(ADDR)    
       LD    B,4 ; 4 bytes
DLINE2: LD    A,(DE)   
       CP    20H
       JR    C,DOT
       CP    7FH
       JR    NC,DOT
       JP    NDOT
DOT:    LD    A,'.'
NDOT:   CALL  INBUF
       INC   DE       
       DJNZ  DLINE2
;         
;TERMINATE AND DISPLAY STRING
;       
       CALL  BCRLF
       LD    A,00H
       LD    (HL),A
       LD    HL,MSGBUF
       CALL  SNDLCDMSG
       RET


;
; PUT A SPACE IN THE BUFFER
;
SPCBUF: LD    A, 8 ;20H(32dec)
INBUF:  LD    (HL),A
       INC   HL
       RET
;
; PUT A CR LF IN THE BUFFER
;        
BCRLF:  ;LD    A,CR  
       ;CALL  INBUF  ;Display add CR automaticamente quando chegar na coluna 21
       RET



;----------------------------------------------
; Output value to port
; O AA DD - Port address in AA, Data to out in DD
;----------------------------------------------
OUTPORT:
    LD A, 'O'
    CALL PrintBufferChar
    CALL OUTSP ; space and show lcd

    CALL  GETCHR 
    RET   C
    LD C, A

    CALL OUTSP

    CALL  GETCHR 
    RET   C
    OUT (C), A
    RET


;----------------------------------------------
; Read input port and show value to LCD
; I AA - Port address in AA
;----------------------------------------------
INPORT:
    LD A, 'I'
    CALL PrintBufferChar
    CALL OUTSP ; space and show lcd

    CALL  GETCHR 
    RET   C
    LD C, A

    IN A, (C)

    LD B, A
    PUSH BC
    LD A, CR
    CALL PRINTCHAR
    POP BC
    LD A, B

    CALL CONV_A_HEX
    RET


; --------------------------------------
; I2C - Write one byte
; --------------------------------------
I2C_WR_DD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_WR_DD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_WR_DD_LOOP:
    ; Get Data
    CALL GET_DEV_DD   ; get data

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_DD)  ; Data
    CALL I2C_Write
 
    CALL I2C_Close  ; Close

    JR I2C_WR_DD_LOOP

    RET



; --------------------------------------
; I2C - Write register one byte
; --------------------------------------
I2C_WR_RR_DD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_WR_RR_DD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_WR_RR_DD_LOOP:
    ; Get register
    CALL GET_DEV_RR ; get address

    ; Get Data
    CALL GET_DEV_DD   ; get data

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_RR)  ; register
    CALL I2C_Write

    LD A, (I2C_DD)  ; Data
    CALL I2C_Write

    CALL I2C_Close  ; Close

    JR I2C_WR_RR_DD_LOOP

    RET


; --------------------------------------
; I2C - Read one byte
; --------------------------------------
I2C_RD:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_RD
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address
    CALL TXCRLF ; new line

I2C_RD_LOOP:
    ; Send
    LD A, (I2C_ADDR) ; Open
    INC A ; To read address + 1 (flag)
    CALL I2C_Open

    CALL I2C_Read      ; Read
    PUSH AF

    CALL I2C_Close     ; Close

    ; Show
    POP AF
    CALL CONV_A_HEX ; Show A to (HEX) LCD
    CALL TXCRLF ; new line

    CALL KEYREADINIT
    CP CTRLC
    JP Z, RESET_WARM

    JR I2C_RD_LOOP
    RET


; --------------------------------------
; I2C - Read register one byte
; --------------------------------------
I2C_RD_RR:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    ; Show msg func
    LD HL, MSG_I2C_RD_RR
    CALL SNDLCDMSG

    ; Device Address
    CALL GET_DEV_ADDR ; get address

I2C_RD_RR_LOOP:
    ; Get register
    CALL GET_DEV_RR ; get address
    CALL TXCRLF ; new line

    ; Send
    LD A, (I2C_ADDR) ; Open
    CALL I2C_Open

    LD A, (I2C_RR)
    CALL I2C_Write ; Register to read

    LD A, (I2C_ADDR) ; Open
    INC A ; To read address + 1 (flag)
    CALL I2C_Open

    CALL I2C_Read ; Read register
    PUSH AF

    CALL I2C_Close ; Close

    ; Show
    POP AF
    CALL CONV_A_HEX ; Show A to (HEX) LCD

    JR I2C_RD_RR_LOOP
    RET


GET_DEV_ADDR:
    LD HL, MSG_DEV_ADDR
    CALL SNDLCDMSG
    CALL  GETCHR 
    RET   C
    LD (I2C_ADDR), A
    RET

GET_DEV_DD:
    LD HL, MSG_DEV_DATA
    CALL SNDLCDMSG

    CALL  GETCHR 
    RET   C
    LD (I2C_DD), A
    RET

GET_DEV_RR:
    LD HL, MSG_DEV_REG
    CALL SNDLCDMSG

    CALL  GETCHR 
    RET   C
    LD (I2C_RR), A
    RET




I2CMEMTOCPU:
    ; Get parameters to copy a block from I2C memory to CPU memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved

    LD HL, MSG_MEM2CPU
    CALL SNDLCDMSG

    CALL GET_FROM_TO_SIZE

;    DE = First address in I2C memory
;    HL = First address in CPU memory
;    BC = Number of bytes to be copied

    LD DE, (ADDR_FROM)
    LD HL, (ADDR_TO)
    LD BC, (ADDR_SIZE)
    CALL I2C_MemRd  

    JP Z, I2CMEMTOCPU_OK
    LD HL, MSG_COPYFAIL
    CALL SNDLCDMSG
    RET
I2CMEMTOCPU_OK:
    LD HL, MSG_COPYOK
    CALL SNDLCDMSG
    RET


I2CCPUTOMEM:
; Get parameters to copy a block from CPU memory to I2C memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If unsuccessfully A = Error and NZ flagged
;             IX IY preserved
; The 24LC64 requires blocks of data to be written in 64 byte (or less)
; pages.
    LD HL, MSG_CPU2MEM
    CALL SNDLCDMSG

    CALL GET_FROM_TO_SIZE

;    DE = First address in I2C memory
;    HL = First address in CPU memory
;    BC = Number of bytes to be copied

    LD HL, (ADDR_FROM)
    LD DE, (ADDR_TO)
    LD BC, (ADDR_SIZE)
    CALL I2C_MemWr
    
    JP Z, I2CCPUTOMEM_OK
    LD HL, MSG_COPYFAIL
    CALL SNDLCDMSG
    RET
I2CCPUTOMEM_OK:
    LD HL, MSG_COPYOK
    CALL SNDLCDMSG
    RET






GET_FROM_TO_SIZE:
    ; FROM
    LD HL, MSG_FROM
    CALL SNDLCDMSG
    ;
    ;GET THE ADDRESS  FROM
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_FROM+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_FROM),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR Z, GET_FROM_TO_SIZE_TO
    LD A, CR
    CALL PRINTCHAR
    JP GET_FROM_TO_SIZE

GET_FROM_TO_SIZE_TO:
    ; TO
    LD HL, MSG_TO
    CALL SNDLCDMSG
    ;
    ;GET THE ADDRESS  TO
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_TO+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_TO),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR NZ, GET_FROM_TO_SIZE_TO

GET_FROM_TO_SIZE_SIZE:
    ; SIZE
    LD HL, MSG_SIZE
    CALL SNDLCDMSG
    ;
    ;GET THE SIZE
    ;
    CALL  GETCHR 
    RET   C        
    LD    (ADDR_SIZE+1),A  ;SAVE ADDRESS HIGH
    CALL  GETCHR
    RET   C
    LD    (ADDR_SIZE),A    ;SAVE ADDRESS LOW

    CALL  KEYREADINIT
    CP    ESC         ;ESC KEY?
    RET   Z
    CP    CR
    JR NZ, GET_FROM_TO_SIZE_SIZE
    RET


INTEL_HEX:
    CALL INTHEX
    CALL delay
    CALL delay
    JP START_MONITOR

SHOWHELP:
    LD A, $0C ; limpar tela
    CALL PRINTCHAR

    LD HL, MSG_MENU0
    CALL SNDLCDMSG

    LD HL, MSG_MENU1
    CALL SNDLCDMSG

    LD HL, MSG_MENU2
    CALL SNDLCDMSG

    LD HL, MSG_MENU3
    CALL SNDLCDMSG

    LD HL, MSG_MENU4
    CALL SNDLCDMSG

    LD HL, MSG_MENU5
    CALL SNDLCDMSG

    LD HL, MSG_MENU6
    CALL SNDLCDMSG

    LD HL, MSG_MENU7
    CALL SNDLCDMSG

    LD HL, MSG_MENU8
    CALL SNDLCDMSG

    LD HL, MSG_MENU9
    CALL SNDLCDMSG

    LD HL, MSG_MENU10
    CALL SNDLCDMSG

    LD HL, MSG_MENU11
    CALL SNDLCDMSG

    LD HL, MSG_MENU12
    CALL SNDLCDMSG

    LD HL, MSG_MENU13
    CALL SNDLCDMSG

    LD HL, MSG_MENU14
    CALL SNDLCDMSG

    RET



;----------------------     
; SEND ASCII HEX VALUES        
;----------------------
;
; OUTPUT THE 4 BYTE, WRDOUT
; THE 2 BYTE, BYTOUT
; OR THE SINGLE BYTE, NYBOUT
; ASCII STRING AT HL TO THE SERIAL PORT
;
WRDOUT: CALL  BYTOUT
BYTOUT: CALL  NYBOUT
NYBOUT: LD    A,(HL)
       CALL  PRINTCHAR
       INC   HL
       RET       



;----------------
;CONVERT TO ASCII 
;----------------
;
; CONVERT A WORD,A BYTE OR A NYBBLE TO ASCII
;
;         ENTRY :  A = BINARY TO CONVERT
;                  HL = CHARACTER BUFFER ADDRESS   
;        EXIT   :  HL = POINTS TO LAST CHARACTER+1
;   
;        MODIFIES : DE

WRDASC: LD    A,D         ;CONVERT AND
       CALL  BYTASC      ;OUTPUT D
       LD    A,E         ;THEN E
;
;CONVERT A BYTE TO ASCII 
;
BYTASC: PUSH  AF          ;SAVE A FOR SECOND NYBBLE 
       RRCA              ;SHIFT HIGH NYBBLE ACROSS
       RRCA
       RRCA
       RRCA
       CALL NYBASC       ;CALL NYBBLE CONVERTER 
       POP AF            ;RESTORE LOW NYBBLE
;           
; CONVERT A NYBBLE TO ASCII
;
NYBASC: AND   0FH         ;MASK OFF HIGH NYBBLE 
       ADD   A,90H       ;CONVERT TO
       DAA               ;ASCII
       ADC   A,40H
       DAA
;            
; SAVE IN STRING
;
INSBUF: LD    (HL),A
       INC   HL 
       RET 




;----------------------------
; M DISPLAY AND MODIFY MEMORY
;----------------------------
MODIFY: LD A, 'M'
        CALL PRINTCHAR
     CALL  OUTSP
;
;GET THE ADDRESS        
;
       CALL  GETCHR 
       RET   C        
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; DISPLAY ON A NEW LINE
;       
MDIFY1: CALL  TXCRLF       
       LD    DE,(ADDR)    
       LD    HL,MSGBUF   
       CALL  WRDASC      ;CONVERT ADDRESS IN DE TO ASCII
       LD    HL,MSGBUF
       CALL  WRDOUT      ;OUTPUT THE ADDRESS
       CALL  OUTSP    
;      
;GET THE DATA AT THE ADDRESS        
;
        LD   HL,(ADDR)       
        LD   A,(HL)
;
; DISPLAY THE DATA
;        
       LD    HL,MSGBUF
       CALL  BYTASC     ;CONVERT THE DATA BYTE IN A TO ASCII
       LD    HL,MSGBUF
       CALL  BYTOUT      ;OUTPUT THE BYTE
       CALL  OUTSP
;
; GET NEW DATA,EXIT OR CONTINUE
;
       CALL  GETCHR
       RET   C
       LD    B,A         ;SAVE IT FOR LATER
       LD    HL,(ADDR)
       LD    (HL),A      ;PUT THE BYTE AT THE CURRENT ADDRESS
       LD    A,B
       CP    (HL)
       JR    Z,MDIFY2
       LD    A,'?'
       CALL  PRINTCHAR       ;NOT THE SAME DATA, PROBABLY NO RAM THERE      
;
; INCREMENT THE ADDRESS
;
MDIFY2: INC   HL
       LD    (ADDR),HL
       JP    MDIFY1



;------------------------------
; GO <ADDR>
; TRANSFERS EXECUTION TO <ADDR>
;------------------------------
GOJUMP_new:
    LD A, CR
    CALL PRINTCHAR

    LD A, '>'
    CALL PRINTCHAR

GOJUMP: LD A, 'G'
        CALL PRINTCHAR
       CALL  OUTSP       
       CALL  GETCHR      ;GET ADDRESS HIGH BYTE
       RET   C
       LD    (ADDR+1),A  ;SAVE ADDRESS HIGH
       CALL  GETCHR      ;GET ADDRESS LOW BYTE
       RET   C
       LD    (ADDR),A    ;SAVE ADDRESS LOW 
;
; WAIT FOR A CR OR ESC
;       
GOJMP1: CALL  KEYREADINIT
       CP    ESC         ;ESC KEY?
       RET   Z
       CP    CR
       ;JR    NZ,GOJMP1
       JR NZ, GOJUMP_new
       CALL  TXCRLF
       POP   HL          ;POP THE UNUSED MENU RETURN ADDRESS FROM THE STACK
       LD    HL,(ADDR)
       JP    (HL)        ;GOOD LUCK WITH THAT!

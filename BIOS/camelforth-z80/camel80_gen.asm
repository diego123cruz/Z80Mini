; Listing 2.
; ===============================================
; CamelForth for the Zilog Z80
; Copyright (c) 1994,1995 Bradford J. Rodriguez
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; Commercial inquiries should be directed to the author at 
; 115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
; or via email to bj@camelforth.com
;
; ===============================================
; CAMEL80.AZM: Code Primitives
;   Source code is for the Z80MR macro assembler.
;   Forth words are documented as follows:
;x   NAME     stack -- stack    description
;   where x=C for ANS Forth Core words, X for ANS
;   Extensions, Z for internal or private words.
;
; Direct-Threaded Forth model for Zilog Z80
; 16 bit cell, 8 bit char, 8 bit (byte) adrs unit
;    Z80 BC = Forth TOS (top Param Stack item)
;        HL =       W    working register
;        DE =       IP   Interpreter Pointer
;        SP =       PSP  Param Stack Pointer
;        IX =       RSP  Return Stack Pointer
;        IY =       UP   User area Pointer
;    A, alternate register set = temporaries
;
; Revision history:
;   19 Aug 94 v1.0
;   25 Jan 95 v1.01  now using BDOS function 0Ah
;       for interpreter input; TIB at 82h.
;   02 Mar 95 v1.02  changed ALIGN to ALIGNED in
;       S" (S"); changed ,BRANCH to ,XT in DO.
; ===============================================
; Macros to define Forth headers
; HEAD  label,length,name,action
; IMMED label,length,name,action
;    label  = assembler name for this word
;             (special characters not allowed)
;    length = length of name field
;    name   = Forth's name for this word
;    action = code routine for this word, e.g.
;             DOCOLON, or DOCODE for code words
; IMMED defines a header for an IMMEDIATE word.
;








; NEXTHL is used when the IP is already in HL.


; The NEXT macro (7 bytes) assembles the 'next'
; code in-line in every Z80 CamelForth CODE word.




; RESET AND INTERRUPT VECTORS ===================

; RC2014 Entry point
        org $8000
reset:  ld hl,$dc00
        dec h        ; EM-100h
        ld sp,hl     ;      = top of param stack
        inc h        ; EM
        push hl
        pop ix       ;      = top of return stack
        dec h        ; EM-200h
        dec h
        push hl
        pop iy       ;      = bottom of user area
        ld de,1      ; do reset if COLD returns
        jp COLD      ; enter top-level Forth word

; Memory map:
;   0080h       Terminal Input Buffer, 128 bytes
;   0100h       Forth kernel = start of CP/M TPA
;     ? h       Forth dictionary (user RAM)
;   EM-200h     User area, 128 bytes
;   EM-180h     Parameter stack, 128B, grows down
;   EM-100h     HOLD area, 40 bytes, grows down
;   EM-0D8h     PAD buffer, 88 bytes
;   EM-80h      Return stack, 128 B, grows down
;   EM          End of RAM = start of CP/M BDOS
; See also the definitions of U0, S0, and R0
; in the "system variables & constants" area.
; A task w/o terminal input requires 200h bytes.
; Double all except TIB and PAD for 32-bit CPUs.

; INTERPRETER LOGIC =============================
; See also "defining words" at end of this file

;C EXIT     --      exit a colon definition
    
      dw 0
      db 0
EXIT_link:
      
      defm 4, "EXIT"
EXIT:
      
      
        ld e,(ix+0)    ; pop old IP from ret stk
        inc ix
        ld d,(ix+0)
        inc ix
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z lit      -- x    fetch inline literal to stack
; This is the primtive compiled by LITERAL.
    
      dw EXIT_link
      db 0
lit_link:
      
      defm 3, "LIT"
lit:
      
      
        push bc        ; push old TOS
        ld a,(de)      ; fetch cell at IP to TOS,
        ld c,a         ;        advancing IP
        inc de
        ld a,(de)
        ld b,a
        inc de
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C EXECUTE   i*x xt -- j*x   execute Forth word
;C                           at 'xt'
    
      dw lit_link
      db 0
EXECUTE_link:
      
      defm 7, "EXECUTE"
EXECUTE:
      
      
        ld h,b          ; address of word -> HL
        ld l,c
        pop bc          ; get new TOS
        jp (hl)         ; go do Forth word

; DEFINING WORDS ================================

; ENTER, a.k.a. DOCOLON, entered by CALL ENTER
; to enter a new high-level thread (colon def'n.)
; (internal code fragment, not a Forth word)
; N.B.: DOCOLON must be defined before any
; appearance of 'docolon' in a 'word' macro!
docolon:               ; (alternate name)
enter:  dec ix         ; push old IP on ret stack
        ld (ix+0),d
        dec ix
        ld (ix+0),e
        pop hl         ; param field adrs -> IP
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)

;C VARIABLE   --      define a Forth variable
;   CREATE 1 CELLS ALLOT ;
; Action of RAM variable is identical to CREATE,
; so we don't need a DOES> clause to change it.
    
      dw EXECUTE_link
      db 0
VARIABLE_link:
      
      defm 8, "VARIABLE"
VARIABLE:
      call docolon
      
        DW CREATE,lit,1,CELLS,ALLOT,EXIT
; DOVAR, code action of VARIABLE, entered by CALL
; DOCREATE, code action of newly created words
docreate:
dovar:  ; -- a-addr
        pop hl     ; parameter field address
        push bc    ; push old TOS
        ld b,h     ; pfa = variable's adrs -> TOS
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C CONSTANT   n --      define a Forth constant
;   CREATE , DOES> (machine code fragment)
    
      dw VARIABLE_link
      db 0
CONSTANT_link:
      
      defm 8, "CONSTANT"
CONSTANT:
      call docolon
      
        DW CREATE,COMMA,XDOES
; DOCON, code action of CONSTANT,
; entered by CALL DOCON
docon:  ; -- x
        pop hl     ; parameter field address
        push bc    ; push old TOS
        ld c,(hl)  ; fetch contents of parameter
        inc hl     ;    field -> TOS
        ld b,(hl)
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z USER     n --        define user variable 'n'
;   CREATE , DOES> (machine code fragment)
    
      dw CONSTANT_link
      db 0
USER_link:
      
      defm 4, "USER"
USER:
      call docolon
      
        DW CREATE,COMMA,XDOES
; DOUSER, code action of USER,
; entered by CALL DOUSER
douser:  ; -- a-addr
        pop hl     ; parameter field address
        push bc    ; push old TOS
        ld c,(hl)  ; fetch contents of parameter
        inc hl     ;    field
        ld b,(hl)
        push iy    ; copy user base address to HL
        pop hl
        add hl,bc  ;    and add offset
        ld b,h     ; put result in TOS
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; DODOES, code action of DOES> clause
; entered by       CALL fragment
;                  parameter field
;                       ...
;        fragment: CALL DODOES
;                  high-level thread
; Enters high-level thread with address of
; parameter field on top of stack.
; (internal code fragment, not a Forth word)
dodoes: ; -- a-addr
        dec ix         ; push old IP on ret stk
        ld (ix+0),d
        dec ix
        ld (ix+0),e
        pop de         ; adrs of new thread -> IP
        pop hl         ; adrs of parameter field
        push bc        ; push old TOS onto stack
        ld b,h         ; pfa -> new TOS
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; TERMINAL I/O ==================================

; Endereços da jump table do Z80Mini
TX_CHAR  EQU $0181    ; envia A via Serial A (SIO port A)
RX_CHAR  EQU $0115    ; recebe char bloqueante em A
RX_RDY   EQU $0118    ; retorna C=1 se char disponível, A=char

;C EMIT     c --    output character to console
;   6 BDOS DROP ;
; warning: if c=0ffh, will read one keypress
    
      dw USER_link
      db 0
EMIT_link:
      
      defm 4, "EMIT"
EMIT:
      
      
    ld a, c          ; char está em TOS (BC), pega byte baixo
    

    PUSH BC
    PUSH DE
    PUSH HL
    call TX_CHAR     ; envia via ROM API
    POP HL
   	POP DE
   	POP BC

   	
    pop bc           ; pop new TOS
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X KEY?     -- f    return true if char waiting
;   0FF 6 BDOS DUP SAVEKEY C! ;   rtns 0 or key
; must use BDOS function 6 to work with KEY
	
      dw EMIT_link
      db 0
QUERYKEY_link:
      
      defm 4, "KEY?"
QUERYKEY:
      
      
    push bc
    push de
    push hl
    call RX_RDY      ; C=1 se disponível, A=char
    pop hl
    pop de
    pop bc
    push bc          ; salva TOS antigo no param stack
    jr nc, z80mini_nokey
    ld bc, 0FFFFh    ; true
    jr z80mini_keyok
z80mini_nokey:
    ld bc, 0         ; false
z80mini_keyok:
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C KEY      -- c    get character from keyboard
;   BEGIN SAVEKEY C@ 0= WHILE KEY? DROP REPEAT
;   SAVEKEY C@  0 SAVEKEY C! ;
; must use CP/M direct console I/O to avoid echo
; (BDOS function 6, contained within KEY?)
    
      dw QUERYKEY_link
      db 0
KEY_link:
      
      defm 3, "KEY"
KEY:
      
      

    PUSH BC
    PUSH DE
    PUSH HL
    call RX_CHAR     ; bloqueante, retorna char em A
    POP HL
    POP DE
    POP BC
    
    push bc
    ld c, a
    ld b, 0
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        


;X BYE     i*x --    return to CP/M
    
      dw KEY_link
      db 0
BYE_link:
      
      defm 3, "BYE"
BYE:
      
      
        jp 0




      dw BYE_link
      db 0
CPMACCEPT_link:
      
      defm 9, "CPMACCEPT"
CPMACCEPT:
      
      
    pop  hl          ; HL = c-addr
    ld   a, c        ; salva maxlen em A ANTES de zerар BC
    exx
    ld   c, a        ; alt-C' = maxlen (seguro, não é IP)
    exx
    ld   bc, 0       ; BC = count = 0

acc_loop:
    push bc
    push de
    push hl
    call RX_CHAR     ; char retorna em A
    pop  hl
    pop  de
    pop  bc

    cp   $0D
    jr   z, acc_done
    cp   $08
    jr   z, acc_bs
    cp   $7F
    jr   z, acc_bs

    ; compara count (C) com maxlen (alt-C')
    push af          ; preserva char recebido
    ld   a, c        ; A = count
    exx
    cp   c           ; count vs maxlen
    exx
    pop  af          ; restaura char
    jr   nc, acc_loop     ; count >= maxlen → ignora

    ld   (hl), a     ; armazena char no buffer
    inc  hl
    inc  bc          ; count++

    push bc
    push de
    push hl
    call TX_CHAR     ; echo (A ainda tem o char)
    pop  hl
    pop  de
    pop  bc
    jr   acc_loop

acc_bs:
    ld   a, b
    or   c
    jr   z, acc_loop      ; count=0, nada a apagar
    dec  hl
    dec  bc
    push bc
    push de
    push hl
    ld   a, $08
    call TX_CHAR
    ld   a, ' '
    call TX_CHAR
    ld   a, $08
    call TX_CHAR
    pop  hl
    pop  de
    pop  bc
    jr   acc_loop

acc_done:
    push bc
    push de
    push hl
    ld   a, $0D
    call TX_CHAR
    pop  hl
    pop  de
    pop  bc
    ; BC = count final → novo TOS
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        


    
    
; STACK OPERATIONS ==============================

;C DUP      x -- x x      duplicate top of stack
    
      dw CPMACCEPT_link
      db 0
DUP_link:
      
      defm 3, "DUP"
DUP:
      
      
pushtos: push bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C ?DUP     x -- 0 | x x    DUP if nonzero
    
      dw DUP_link
      db 0
QDUP_link:
      
      defm 4, "?DUP"
QDUP:
      
      
        ld a,b
        or c
        jr nz,pushtos
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C DROP     x --          drop top of stack
    
      dw QDUP_link
      db 0
DROP_link:
      
      defm 4, "DROP"
DROP:
      
      
poptos: pop bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C SWAP     x1 x2 -- x2 x1    swap top two items
    
      dw DROP_link
      db 0
SWOP_link:
      
      defm 4, "SWAP"
SWOP:
      
      
        pop hl
        push bc
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C OVER    x1 x2 -- x1 x2 x1   per stack diagram
    
      dw SWOP_link
      db 0
OVER_link:
      
      defm 4, "OVER"
OVER:
      
      
        pop hl
        push hl
        push bc
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C ROT    x1 x2 x3 -- x2 x3 x1  per stack diagram
    
      dw OVER_link
      db 0
ROT_link:
      
      defm 3, "ROT"
ROT:
      
      
        ; x3 is in TOS
        pop hl          ; x2
        ex (sp),hl      ; x2 on stack, x1 in hl
        push bc
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X NIP    x1 x2 -- x2           per stack diagram
    
      dw ROT_link
      db 0
NIP_link:
      
      defm 3, "NIP"
NIP:
      call docolon
      
        DW SWOP,DROP,EXIT

;X TUCK   x1 x2 -- x2 x1 x2     per stack diagram
    
      dw NIP_link
      db 0
TUCK_link:
      
      defm 4, "TUCK"
TUCK:
      call docolon
      
        DW SWOP,OVER,EXIT

;C >R    x --   R: -- x   push to return stack
    
      dw TUCK_link
      db 0
TOR_link:
      
      defm 2, ">R"
TOR:
      
      
        dec ix          ; push TOS onto rtn stk
        ld (ix+0),b
        dec ix
        ld (ix+0),c
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C R>    -- x    R: x --   pop from return stack
    
      dw TOR_link
      db 0
RFROM_link:
      
      defm 2, "R>"
RFROM:
      
      
        push bc         ; push old TOS
        ld c,(ix+0)     ; pop top rtn stk item
        inc ix          ;       to TOS
        ld b,(ix+0)
        inc ix
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C R@    -- x     R: x -- x   fetch from rtn stk
    
      dw RFROM_link
      db 0
RFETCH_link:
      
      defm 2, "R@"
RFETCH:
      
      
        push bc         ; push old TOS
        ld c,(ix+0)     ; fetch top rtn stk item
        ld b,(ix+1)     ;       to TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SP@  -- a-addr       get data stack pointer
    
      dw RFETCH_link
      db 0
SPFETCH_link:
      
      defm 3, "SP@"
SPFETCH:
      
      
        push bc
        ld hl,0
        add hl,sp
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SP!  a-addr --       set data stack pointer
    
      dw SPFETCH_link
      db 0
SPSTORE_link:
      
      defm 3, "SP!"
SPSTORE:
      
      
        ld h,b
        ld l,c
        ld sp,hl
        pop bc          ; get new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z RP@  -- a-addr       get return stack pointer
    
      dw SPSTORE_link
      db 0
RPFETCH_link:
      
      defm 3, "RP@"
RPFETCH:
      
      
        push bc
        push ix
        pop bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z RP!  a-addr --       set return stack pointer
    
      dw RPFETCH_link
      db 0
RPSTORE_link:
      
      defm 3, "RP!"
RPSTORE:
      
      
        push bc
        pop ix
        pop bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; MEMORY AND I/O OPERATIONS =====================

;C !        x a-addr --   store cell in memory
    
      dw RPSTORE_link
      db 0
STORE_link:
      
      defm 1, "!"
STORE:
      
      
        ld h,b          ; address in hl
        ld l,c
        pop bc          ; data in bc
        ld (hl),c
        inc hl
        ld (hl),b
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C C!      char c-addr --    store char in memory
    
      dw STORE_link
      db 0
CSTORE_link:
      
      defm 2, "C!"
CSTORE:
      
      
        ld h,b          ; address in hl
        ld l,c
        pop bc          ; data in bc
        ld (hl),c
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C @       a-addr -- x   fetch cell from memory
    
      dw CSTORE_link
      db 0
FETCH_link:
      
      defm 1, "@"
FETCH:
      
      
        ld h,b          ; address in hl
        ld l,c
        ld c,(hl)
        inc hl
        ld b,(hl)
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C C@     c-addr -- char   fetch char from memory
    
      dw FETCH_link
      db 0
CFETCH_link:
      
      defm 2, "C@"
CFETCH:
      
      
        ld a,(bc)
        ld c,a
        ld b,0
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z PC!     char c-addr --    output char to port
    
      dw CFETCH_link
      db 0
PCSTORE_link:
      
      defm 3, "PC!"
PCSTORE:
      
      
        pop hl          ; char in L
        out (c),l       ; to port (BC)
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z PC@     c-addr -- char   input char from port
    
      dw PCSTORE_link
      db 0
PCFETCH_link:
      
      defm 3, "PC@"
PCFETCH:
      
      
        in c,(c)        ; read port (BC) to C
        ld b,0
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; ARITHMETIC AND LOGICAL OPERATIONS =============

;C +       n1/u1 n2/u2 -- n3/u3     add n1+n2
    
      dw PCFETCH_link
      db 0
PLUS_link:
      
      defm 1, "+"
PLUS:
      
      
        pop hl
        add hl,bc
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X M+       d n -- d         add single to double
    
      dw PLUS_link
      db 0
MPLUS_link:
      
      defm 2, "M+"
MPLUS:
      
      
        ex de,hl
        pop de          ; hi cell
        ex (sp),hl      ; lo cell, save IP
        add hl,bc
        ld b,d          ; hi result in BC (TOS)
        ld c,e
        jr nc,mplus1
        inc bc
mplus1: pop de          ; restore saved IP
        push hl         ; push lo result
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C -      n1/u1 n2/u2 -- n3/u3    subtract n1-n2
    
      dw MPLUS_link
      db 0
MINUS_link:
      
      defm 1, "-"
MINUS:
      
      
        pop hl
        or a
        sbc hl,bc
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C AND    x1 x2 -- x3            logical AND
    
      dw MINUS_link
      db 0
AND_link:
      
      defm 3, "AND"
AND:
      
      
        pop hl
        ld a,b
        and h
        ld b,a
        ld a,c
        and l
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C OR     x1 x2 -- x3           logical OR
    
      dw AND_link
      db 0
OR_link:
      
      defm 2, "OR"
OR:
      
      
        pop hl
        ld a,b
        or h
        ld b,a
        ld a,c
        or l
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C XOR    x1 x2 -- x3            logical XOR
    
      dw OR_link
      db 0
XOR_link:
      
      defm 3, "XOR"
XOR:
      
      
        pop hl
        ld a,b
        xor h
        ld b,a
        ld a,c
        xor l
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C INVERT   x1 -- x2            bitwise inversion
    
      dw XOR_link
      db 0
INVERT_link:
      
      defm 6, "INVERT"
INVERT:
      
      
        ld a,b
        cpl
        ld b,a
        ld a,c
        cpl
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C NEGATE   x1 -- x2            two's complement
    
      dw INVERT_link
      db 0
NEGATE_link:
      
      defm 6, "NEGATE"
NEGATE:
      
      
        ld a,b
        cpl
        ld b,a
        ld a,c
        cpl
        ld c,a
        inc bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 1+      n1/u1 -- n2/u2       add 1 to TOS
    
      dw NEGATE_link
      db 0
ONEPLUS_link:
      
      defm 2, "1+"
ONEPLUS:
      
      
        inc bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 1-      n1/u1 -- n2/u2     subtract 1 from TOS
    
      dw ONEPLUS_link
      db 0
ONEMINUS_link:
      
      defm 2, "1-"
ONEMINUS:
      
      
        dec bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z ><      x1 -- x2         swap bytes (not ANSI)
    
      dw ONEMINUS_link
      db 0
swapbytes_link:
      
      defm 2, "><"
swapbytes:
      
      
        ld a,b
        ld b,c
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 2*      x1 -- x2         arithmetic left shift
    
      dw swapbytes_link
      db 0
TWOSTAR_link:
      
      defm 2, "2*"
TWOSTAR:
      
      
        sla c
        rl b
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 2/      x1 -- x2        arithmetic right shift
    
      dw TWOSTAR_link
      db 0
TWOSLASH_link:
      
      defm 2, "2/"
TWOSLASH:
      
      
        sra b
        rr c
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C LSHIFT  x1 u -- x2    logical L shift u places
    
      dw TWOSLASH_link
      db 0
LSHIFT_link:
      
      defm 6, "LSHIFT"
LSHIFT:
      
      
        ld b,c        ; b = loop counter
        pop hl        ;   NB: hi 8 bits ignored!
        inc b         ; test for counter=0 case
        jr lsh2
lsh1:   add hl,hl     ; left shift HL, n times
lsh2:   djnz lsh1
        ld b,h        ; result is new TOS
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C RSHIFT  x1 u -- x2    logical R shift u places
    
      dw LSHIFT_link
      db 0
RSHIFT_link:
      
      defm 6, "RSHIFT"
RSHIFT:
      
      
        ld b,c        ; b = loop counter
        pop hl        ;   NB: hi 8 bits ignored!
        inc b         ; test for counter=0 case
        jr rsh2
rsh1:   srl h         ; right shift HL, n times
        rr l
rsh2:   djnz rsh1
        ld b,h        ; result is new TOS
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C +!     n/u a-addr --       add cell to memory
    
      dw RSHIFT_link
      db 0
PLUSSTORE_link:
      
      defm 2, "+!"
PLUSSTORE:
      
      
        pop hl
        ld a,(bc)       ; low byte
        add a,l
        ld (bc),a
        inc bc
        ld a,(bc)       ; high byte
        adc a,h
        ld (bc),a
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; COMPARISON OPERATIONS =========================

;C 0=     n/u -- flag    return true if TOS=0
    
      dw PLUSSTORE_link
      db 0
ZEROEQUAL_link:
      
      defm 2, "0="
ZEROEQUAL:
      
      
        ld a,b
        or c            ; result=0 if bc was 0
        sub 1           ; cy set   if bc was 0
        sbc a,a         ; propagate cy through A
        ld b,a          ; put 0000 or FFFF in TOS
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 0<     n -- flag      true if TOS negative
    
      dw ZEROEQUAL_link
      db 0
ZEROLESS_link:
      
      defm 2, "0<"
ZEROLESS:
      
      
        sla b           ; sign bit -> cy flag
        sbc a,a         ; propagate cy through A
        ld b,a          ; put 0000 or FFFF in TOS
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C =      x1 x2 -- flag         test x1=x2
    
      dw ZEROLESS_link
      db 0
EQUAL_link:
      
      defm 1, "="
EQUAL:
      
      
        pop hl
        or a
        sbc hl,bc       ; x1-x2 in HL, SZVC valid
        jr z,tostrue
tosfalse: ld bc,0
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X <>     x1 x2 -- flag    test not eq (not ANSI)
    
      dw EQUAL_link
      db 0
NOTEQUAL_link:
      
      defm 2, "<>"
NOTEQUAL:
      call docolon
      
        DW EQUAL,ZEROEQUAL,EXIT

;C <      n1 n2 -- flag        test n1<n2, signed
    
      dw NOTEQUAL_link
      db 0
LESS_link:
      
      defm 1, "<"
LESS:
      
      
        pop hl
        or a
        sbc hl,bc       ; n1-n2 in HL, SZVC valid
; if result negative & not OV, n1<n2
; neg. & OV => n1 +ve, n2 -ve, rslt -ve, so n1>n2
; if result positive & not OV, n1>=n2
; pos. & OV => n1 -ve, n2 +ve, rslt +ve, so n1<n2
; thus OV reverses the sense of the sign bit
        jp pe,revsense  ; if OV, use rev. sense
        jp p,tosfalse   ;   if +ve, result false
tostrue: ld bc,0ffffh   ;   if -ve, result true
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        
revsense: jp m,tosfalse ; OV: if -ve, reslt false
        jr tostrue      ;     if +ve, result true

;C >     n1 n2 -- flag         test n1>n2, signed
    
      dw LESS_link
      db 0
GREATER_link:
      
      defm 1, ">"
GREATER:
      call docolon
      
        DW SWOP,LESS,EXIT

;C U<    u1 u2 -- flag       test u1<n2, unsigned
    
      dw GREATER_link
      db 0
ULESS_link:
      
      defm 2, "U<"
ULESS:
      
      
        pop hl
        or a
        sbc hl,bc       ; u1-u2 in HL, SZVC valid
        sbc a,a         ; propagate cy through A
        ld b,a          ; put 0000 or FFFF in TOS
        ld c,a
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X U>    u1 u2 -- flag     u1>u2 unsgd (not ANSI)
    
      dw ULESS_link
      db 0
UGREATER_link:
      
      defm 2, "U>"
UGREATER:
      call docolon
      
        DW SWOP,ULESS,EXIT

; LOOP AND BRANCH OPERATIONS ====================

;Z branch   --                  branch always
    
      dw UGREATER_link
      db 0
branch_link:
      
      defm 6, "branch"
branch:
      
      
dobranch: ld a,(de)     ; get inline value => IP
        ld l,a
        inc de
        ld a,(de)
        ld h,a
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)

;Z ?branch   x --              branch if TOS zero
    
      dw branch_link
      db 0
qbranch_link:
      
      defm 7, "?branch"
qbranch:
      
      
        ld a,b
        or c            ; test old TOS
        pop bc          ; pop new TOS
        jr z,dobranch   ; if old TOS=0, branch
        inc de          ; else skip inline value
        inc de
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z (do)    n1|u1 n2|u2 --  R: -- sys1 sys2
;Z                          run-time code for DO
; '83 and ANSI standard loops terminate when the
; boundary of limit-1 and limit is crossed, in
; either direction.  This can be conveniently
; implemented by making the limit 8000h, so that
; arithmetic overflow logic can detect crossing.
; I learned this trick from Laxen & Perry F83.
; fudge factor = 8000h-limit, to be added to
; the start value.
    
      dw qbranch_link
      db 0
xdo_link:
      
      defm 4, "(do)"
xdo:
      
      
        ex de,hl
        ex (sp),hl   ; IP on stack, limit in HL
        ex de,hl
        ld hl,8000h
        or a
        sbc hl,de    ; 8000-limit in HL
        dec ix       ; push this fudge factor
        ld (ix+0),h  ;    onto return stack
        dec ix       ;    for later use by 'I'
        ld (ix+0),l
        add hl,bc    ; add fudge to start value
        dec ix       ; push adjusted start value
        ld (ix+0),h  ;    onto return stack
        dec ix       ;    as the loop index.
        ld (ix+0),l
        pop de       ; restore the saved IP
        pop bc       ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z (loop)   R: sys1 sys2 --  | sys1 sys2
;Z                        run-time code for LOOP
; Add 1 to the loop index.  If loop terminates,
; clean up the return stack and skip the branch.
; Else take the inline branch.  Note that LOOP
; terminates when index=8000h.
    
      dw xdo_link
      db 0
xloop_link:
      
      defm 6, "(loop)"
xloop:
      
      
        exx
        ld bc,1
looptst: ld l,(ix+0)  ; get the loop index
        ld h,(ix+1)
        or a
        adc hl,bc    ; increment w/overflow test
        jp pe,loopterm  ; overflow=loop done
        ; continue the loop
        ld (ix+0),l  ; save the updated index
        ld (ix+1),h
        exx
        jr dobranch  ; take the inline branch
loopterm: ; terminate the loop
        ld bc,4      ; discard the loop info
        add ix,bc
        exx
        inc de       ; skip the inline branch
        inc de
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z (+loop)   n --   R: sys1 sys2 --  | sys1 sys2
;Z                        run-time code for +LOOP
; Add n to the loop index.  If loop terminates,
; clean up the return stack and skip the branch.
; Else take the inline branch.
    
      dw xloop_link
      db 0
xplusloop_link:
      
      defm 7, "(+loop)"
xplusloop:
      
      
        pop hl      ; this will be the new TOS
        push bc
        ld b,h
        ld c,l
        exx
        pop bc      ; old TOS = loop increment
        jr looptst

;C I        -- n   R: sys1 sys2 -- sys1 sys2
;C                  get the innermost loop index
    
      dw xplusloop_link
      db 0
II_link:
      
      defm 1, "I"
II:
      
      
        push bc     ; push old TOS
        ld l,(ix+0) ; get current loop index
        ld h,(ix+1)
        ld c,(ix+2) ; get fudge factor
        ld b,(ix+3)
        or a
        sbc hl,bc   ; subtract fudge factor,
        ld b,h      ;   returning true index
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C J        -- n   R: 4*sys -- 4*sys
;C                  get the second loop index
    
      dw II_link
      db 0
JJ_link:
      
      defm 1, "J"
JJ:
      
      
        push bc     ; push old TOS
        ld l,(ix+4) ; get current loop index
        ld h,(ix+5)
        ld c,(ix+6) ; get fudge factor
        ld b,(ix+7)
        or a
        sbc hl,bc   ; subtract fudge factor,
        ld b,h      ;   returning true index
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C UNLOOP   --   R: sys1 sys2 --  drop loop parms
    
      dw JJ_link
      db 0
UNLOOP_link:
      
      defm 6, "UNLOOP"
UNLOOP:
      
      
        inc ix
        inc ix
        inc ix
        inc ix
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; MULTIPLY AND DIVIDE ===========================

;C UM*     u1 u2 -- ud   unsigned 16x16->32 mult.
    
      dw UNLOOP_link
      db 0
UMSTAR_link:
      
      defm 3, "UM*"
UMSTAR:
      
      
        push bc
        exx
        pop bc      ; u2 in BC
        pop de      ; u1 in DE
        ld hl,0     ; result will be in HLDE
        ld a,17     ; loop counter
        or a        ; clear cy
umloop: rr h
        rr l
        rr d
        rr e
        jr nc,noadd
        add hl,bc
noadd:  dec a
        jr nz,umloop
        push de     ; lo result
        push hl     ; hi result
        exx
        pop bc      ; put TOS back in BC
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C UM/MOD   ud u1 -- u2 u3   unsigned 32/16->16
    
      dw UMSTAR_link
      db 0
UMSLASHMOD_link:
      
      defm 6, "UM/MOD"
UMSLASHMOD:
      
      
        push bc
        exx
        pop bc      ; BC = divisor
        pop hl      ; HLDE = dividend
        pop de
        ld a,16     ; loop counter
        sla e
        rl d        ; hi bit DE -> carry
udloop: adc hl,hl   ; rot left w/ carry
        jr nc,udiv3
        ; case 1: 17 bit, cy:HL = 1xxxx
        or a        ; we know we can subtract
        sbc hl,bc
        or a        ; clear cy to indicate sub ok
        jr udiv4
        ; case 2: 16 bit, cy:HL = 0xxxx
udiv3:  sbc hl,bc   ; try the subtract
        jr nc,udiv4 ; if no cy, subtract ok
        add hl,bc   ; else cancel the subtract
        scf         ;   and set cy to indicate
udiv4:  rl e        ; rotate result bit into DE,
        rl d        ; and next bit of DE into cy
        dec a
        jr nz,udloop
        ; now have complemented quotient in DE,
        ; and remainder in HL
        ld a,d
        cpl
        ld b,a
        ld a,e
        cpl
        ld c,a
        push hl     ; push remainder
        push bc
        exx
        pop bc      ; quotient remains in TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; BLOCK AND STRING OPERATIONS ===================

;C FILL   c-addr u char --  fill memory with char
    
      dw UMSLASHMOD_link
      db 0
FILL_link:
      
      defm 4, "FILL"
FILL:
      
      
        ld a,c          ; character in a
        exx             ; use alt. register set
        pop bc          ; count in bc
        pop de          ; address in de
        or a            ; clear carry flag
        ld hl,0ffffh
        adc hl,bc       ; test for count=0 or 1
        jr nc,filldone  ;   no cy: count=0, skip
        ld (de),a       ; fill first byte
        jr z,filldone   ;   zero, count=1, done
        dec bc          ; else adjust count,
        ld h,d          ;   let hl = start adrs,
        ld l,e
        inc de          ;   let de = start adrs+1
        ldir            ;   copy (hl)->(de)
filldone: exx           ; back to main reg set
        pop bc          ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X CMOVE   c-addr1 c-addr2 u --  move from bottom
; as defined in the ANSI optional String word set
; On byte machines, CMOVE and CMOVE> are logical
; factors of MOVE.  They are easy to implement on
; CPUs which have a block-move instruction.
    
      dw FILL_link
      db 0
CMOVE_link:
      
      defm 5, "CMOVE"
CMOVE:
      
      
        push bc
        exx
        pop bc      ; count
        pop de      ; destination adrs
        pop hl      ; source adrs
        ld a,b      ; test for count=0
        or c
        jr z,cmovedone
        ldir        ; move from bottom to top
cmovedone: exx
        pop bc      ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;X CMOVE>  c-addr1 c-addr2 u --  move from top
; as defined in the ANSI optional String word set
    
      dw CMOVE_link
      db 0
CMOVEUP_link:
      
      defm 6, "CMOVE>"
CMOVEUP:
      
      
        push bc
        exx
        pop bc      ; count
        pop hl      ; destination adrs
        pop de      ; source adrs
        ld a,b      ; test for count=0
        or c
        jr z,umovedone
        add hl,bc   ; last byte in destination
        dec hl
        ex de,hl
        add hl,bc   ; last byte in source
        dec hl
        lddr        ; move from top to bottom
umovedone: exx
        pop bc      ; pop new TOS
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SKIP   c-addr u c -- c-addr' u'
;Z                          skip matching chars
; Although SKIP, SCAN, and S= are perhaps not the
; ideal factors of WORD and FIND, they closely
; follow the string operations available on many
; CPUs, and so are easy to implement and fast.
    
      dw CMOVEUP_link
      db 0
skip_link:
      
      defm 4, "SKIP"
skip:
      
      
        ld a,c      ; skip character
        exx
        pop bc      ; count
        pop hl      ; address
        ld e,a      ; test for count=0
        ld a,b
        or c
        jr z,skipdone
        ld a,e
skiploop: cpi
        jr nz,skipmis   ; char mismatch: exit
        jp pe,skiploop  ; count not exhausted
        jr skipdone     ; count 0, no mismatch
skipmis: inc bc         ; mismatch!  undo last to
        dec hl          ;  point at mismatch char
skipdone: push hl   ; updated address
        push bc     ; updated count
        exx
        pop bc      ; TOS in bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SCAN    c-addr u c -- c-addr' u'
;Z                      find matching char
    
      dw skip_link
      db 0
scan_link:
      
      defm 4, "SCAN"
scan:
      
      
        ld a,c      ; scan character
        exx
        pop bc      ; count
        pop hl      ; address
        ld e,a      ; test for count=0
        ld a,b
        or c
        jr z,scandone
        ld a,e
        cpir        ; scan 'til match or count=0
        jr nz,scandone  ; no match, BC & HL ok
        inc bc          ; match!  undo last to
        dec hl          ;   point at match char
scandone: push hl   ; updated address
        push bc     ; updated count
        exx
        pop bc      ; TOS in bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z S=    c-addr1 c-addr2 u -- n   string compare
;Z             n<0: s1<s2, n=0: s1=s2, n>0: s1>s2
    
      dw scan_link
      db 0
sequal_link:
      
      defm 2, "S="
sequal:
      
      
        push bc
        exx
        pop bc      ; count
        pop hl      ; addr2
        pop de      ; addr1
        ld a,b      ; test for count=0
        or c
        jr z,smatch     ; by definition, match!
sloop:  ld a,(de)
        inc de
        cpi
        jr nz,sdiff     ; char mismatch: exit
        jp pe,sloop     ; count not exhausted
smatch: ; count exhausted & no mismatch found
        exx
        ld bc,0         ; bc=0000  (s1=s2)
        jr snext
sdiff:  ; mismatch!  undo last 'cpi' increment
        dec hl          ; point at mismatch char
        cp (hl)         ; set cy if char1 < char2
        sbc a,a         ; propagate cy thru A
        exx
        ld b,a          ; bc=FFFF if cy (s1<s2)
        or 1            ; bc=0001 if ncy (s1>s2)
        ld c,a
snext:  
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; LISTING 3.
;
; ===============================================
; CamelForth for the Zilog Z80
; Copyright (c) 1994,1995 Bradford J. Rodriguez
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; Commercial inquiries should be directed to the author at 
; 115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
; or via email to bj@camelforth.com
;
; ===============================================
; CAMEL80D.AZM: CPU and Model Dependencies
;   Source code is for the Z80MR macro assembler.
;   Forth words are documented as follows:
;*   NAME     stack -- stack    description
;   Word names in upper case are from the ANS
;   Forth Core word set.  Names in lower case are
;   "internal" implementation words & extensions.
;
; Direct-Threaded Forth model for Zilog Z80
;   cell size is   16 bits (2 bytes)
;   char size is    8 bits (1 byte)
;   address unit is 8 bits (1 byte), i.e.,
;       addresses are byte-aligned.
; ===============================================

; ALIGNMENT AND PORTABILITY OPERATORS ===========
; Many of these are synonyms for other words,
; and so are defined as CODE words.

;C ALIGN    --                         align HERE
    
      dw sequal_link
      db 0
ALIGN_link:
      
      defm 5, "ALIGN"
ALIGN:
      
      
noop:   
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C ALIGNED  addr -- a-addr       align given addr
    
      dw ALIGN_link
      db 0
ALIGNED_link:
      
      defm 7, "ALIGNED"
ALIGNED:
      
      
        jr noop

;Z CELL     -- n                 size of one cell
    
      dw ALIGNED_link
      db 0
CELL_link:
      
      defm 4, "CELL"
CELL:
      call docon
      
        dw 2

;C CELL+    a-addr1 -- a-addr2      add cell size
;   2 + ;
    
      dw CELL_link
      db 0
CELLPLUS_link:
      
      defm 5, "CELL+"
CELLPLUS:
      
      
        inc bc
        inc bc
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C CELLS    n1 -- n2            cells->adrs units
    
      dw CELLPLUS_link
      db 0
CELLS_link:
      
      defm 5, "CELLS"
CELLS:
      
      
        jp TWOSTAR

;C CHAR+    c-addr1 -- c-addr2   add char size
    
      dw CELLS_link
      db 0
CHARPLUS_link:
      
      defm 5, "CHAR+"
CHARPLUS:
      
      
        jp ONEPLUS

;C CHARS    n1 -- n2            chars->adrs units
    
      dw CHARPLUS_link
      db 0
CHARS_link:
      
      defm 5, "CHARS"
CHARS:
      
      
        jr noop

;C >BODY    xt -- a-addr      adrs of param field
;   3 + ;                     Z80 (3 byte CALL)
    
      dw CHARS_link
      db 0
TOBODY_link:
      
      defm 5, ">BODY"
TOBODY:
      call docolon
      
        DW lit,3,PLUS,EXIT

;X COMPILE,  xt --         append execution token
; I called this word ,XT before I discovered that
; it is defined in the ANSI standard as COMPILE,.
; On a DTC Forth this simply appends xt (like , )
; but on an STC Forth this must append 'CALL xt'.
    
      dw TOBODY_link
      db 0
COMMAXT_link:
      
      defm 8, "COMPILE,"
COMMAXT:
      
      
        jp COMMA

;Z !CF    adrs cfa --   set code action of a word
;   0CD OVER C!         store 'CALL adrs' instr
;   1+ ! ;              Z80 VERSION
; Depending on the implementation this could
; append CALL adrs or JUMP adrs.
    
      dw COMMAXT_link
      db 0
STORECF_link:
      
      defm 3, "!CF"
STORECF:
      call docolon
      
        DW lit,0CDH,OVER,CSTORE
        DW ONEPLUS,STORE,EXIT

;Z ,CF    adrs --       append a code field
;   HERE !CF 3 ALLOT ;  Z80 VERSION (3 bytes)
    
      dw STORECF_link
      db 0
COMMACF_link:
      
      defm 3, ",CF"
COMMACF:
      call docolon
      
        DW HERE,STORECF,lit,3,ALLOT,EXIT

;Z !COLON   --      change code field to docolon
;   -3 ALLOT docolon-adrs ,CF ;
; This should be used immediately after CREATE.
; This is made a distinct word, because on an STC
; Forth, colon definitions have no code field.
    
      dw COMMACF_link
      db 0
STORCOLON_link:
      
      defm 6, "!COLON"
STORCOLON:
      call docolon
      
        DW lit,-3,ALLOT
        DW lit,docolon,COMMACF,EXIT

;Z ,EXIT    --      append hi-level EXIT action
;   ['] EXIT ,XT ;
; This is made a distinct word, because on an STC
; Forth, it appends a RET instruction, not an xt.
    
      dw STORCOLON_link
      db 0
CEXIT_link:
      
      defm 5, ",EXIT"
CEXIT:
      call docolon
      
        DW lit,EXIT,COMMAXT,EXIT

; CONTROL STRUCTURES ============================
; These words allow Forth control structure words
; to be defined portably.

;Z ,BRANCH   xt --    append a branch instruction
; xt is the branch operator to use, e.g. qbranch
; or (loop).  It does NOT append the destination
; address.  On the Z80 this is equivalent to ,XT.
    
      dw CEXIT_link
      db 0
COMMABRANCH_link:
      
      defm 7, ",BRANCH"
COMMABRANCH:
      
      
        jp COMMA

;Z ,DEST   dest --        append a branch address
; This appends the given destination address to
; the branch instruction.  On the Z80 this is ','
; ...other CPUs may use relative addressing.
    
      dw COMMABRANCH_link
      db 0
COMMADEST_link:
      
      defm 5, ",DEST"
COMMADEST:
      
      
        jp COMMA

;Z !DEST   dest adrs --    change a branch dest'n
; Changes the destination address found at 'adrs'
; to the given 'dest'.  On the Z80 this is '!'
; ...other CPUs may need relative addressing.
    
      dw COMMADEST_link
      db 0
STOREDEST_link:
      
      defm 5, "!DEST"
STOREDEST:
      
      
        jp STORE

; HEADER STRUCTURE ==============================
; The structure of the Forth dictionary headers
; (name, STOREDEST_link, immediate flag, and "smudge" bit)
; does not necessarily differ across CPUs.  This
; structure is not easily factored into distinct
; "portable" words; instead, it is implicit in
; the definitions of FIND and CREATE, and also in
; NFA>LFA, NFA>CFA, IMMED?, IMMEDIATE, HIDE, and
; REVEAL.  These words must be (substantially)
; rewritten if either the header structure or its
; inherent assumptions are changed.

   ; CPU Dependencies
; LISTING 2.
;
; ===============================================
; CamelForth for the Zilog Z80
; Copyright (c) 1994,1995 Bradford J. Rodriguez
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; Commercial inquiries should be directed to the author at 
; 115 First St., #105, Collingwood, Ontario L9Y 4W3 Canada
; or via email to bj@camelforth.com
;
; ===============================================
; CAMEL80H.AZM: High Level Words
;   Source code is for the Z80MR macro assembler.
;   Forth words are documented as follows:
;*   NAME     stack -- stack    description
;   Word names in upper case are from the ANS
;   Forth Core word set.  Names in lower case are
;   "internal" implementation words & extensions.
; ===============================================

; SYSTEM VARIABLES & CONSTANTS ==================

;C BL      -- char            an ASCII space
    
      dw STOREDEST_link
      db 0
BL_link:
      
      defm 2, "BL"
BL:
      call docon
      
        dw 20h

;Z tibsize  -- n         size of TIB
    
      dw BL_link
      db 0
TIBSIZE_link:
      
      defm 7, "TIBSIZE"
TIBSIZE:
      call docon
      
        dw 124          ; 2 chars safety zone

;X tib     -- a-addr     Terminal Input Buffer
;  HEX 82 CONSTANT TIB   CP/M systems: 126 bytes
;  HEX -80 USER TIB      others: below user area
    
      dw TIBSIZE_link
      db 0
TIB_link:
      
      defm 3, "TIB"
TIB:
      call docon
      
        dw $e000

;Z u0      -- a-addr       current user area adrs
;  0 USER U0
    
      dw TIB_link
      db 0
U0_link:
      
      defm 2, "U0"
U0:
      call douser
      
        dw 0

;C >IN     -- a-addr        holds offset into TIB
;  2 USER >IN
    
      dw U0_link
      db 0
TOIN_link:
      
      defm 3, ">IN"
TOIN:
      call douser
      
        dw 2

;C BASE    -- a-addr       holds conversion radix
;  4 USER BASE
    
      dw TOIN_link
      db 0
BASE_link:
      
      defm 4, "BASE"
BASE:
      call douser
      
        dw 4

;C STATE   -- a-addr       holds compiler state
;  6 USER STATE
    
      dw BASE_link
      db 0
STATE_link:
      
      defm 5, "STATE"
STATE:
      call douser
      
        dw 6

;Z dp      -- a-addr       holds dictionary ptr
;  8 USER DP
    
      dw STATE_link
      db 0
DP_link:
      
      defm 2, "DP"
DP:
      call douser
      
        dw 8

;Z 'source  -- a-addr      two cells: len, adrs
; 10 USER 'SOURCE
    
      dw DP_link
      db 0
TICKSOURCE_link:
      
      defm 7, "'SOURCE"
TICKSOURCE:
      call douser
      
        dw 10

;Z latest    -- a-addr     last word in dict.
;   14 USER LATEST
    
      dw TICKSOURCE_link
      db 0
LATEST_link:
      
      defm 6, "LATEST"
LATEST:
      call douser
      
        dw 14

;Z hp       -- a-addr     HOLD pointer
;   16 USER HP
    
      dw LATEST_link
      db 0
HP_link:
      
      defm 2, "HP"
HP:
      call douser
      
        dw 16

;Z LP       -- a-addr     Leave-stack pointer
;   18 USER LP
    
      dw HP_link
      db 0
LP_link:
      
      defm 2, "LP"
LP:
      call douser
      
        dw 18

;Z s0       -- a-addr     end of parameter stack
    
      dw LP_link
      db 0
S0_link:
      
      defm 2, "S0"
S0:
      call douser
      
        dw 100h

;X PAD       -- a-addr    user PAD buffer
;                         = end of hold area!
    
      dw S0_link
      db 0
PAD_link:
      
      defm 3, "PAD"
PAD:
      call douser
      
        dw 128h

;Z l0       -- a-addr     bottom of Leave stack
    
      dw PAD_link
      db 0
L0_link:
      
      defm 2, "L0"
L0:
      call douser
      
        dw 180h

;Z r0       -- a-addr     end of return stack
    
      dw L0_link
      db 0
R0_link:
      
      defm 2, "R0"
R0:
      call douser
      
        dw 200h

;Z uinit    -- addr  initial values for user area
    
      dw R0_link
      db 0
UINIT_link:
      
      defm 5, "UINIT"
UINIT:
      call docreate
      
        DW 0,0,10,0     ; reserved,>IN,BASE,STATE
        DW enddict      ; DP
        DW 0,0          ; SOURCE init'd elsewhere
        DW lastword     ; LATEST
        DW 0            ; HP init'd elsewhere

;Z #init    -- n    #bytes of user area init data
    
      dw UINIT_link
      db 0
NINIT_link:
      
      defm 5, "#INIT"
NINIT:
      call docon
      
        DW 18

; ARITHMETIC OPERATORS ==========================

;C S>D    n -- d          single -> double prec.
;   DUP 0< ;
    
      dw NINIT_link
      db 0
STOD_link:
      
      defm 3, "S>D"
STOD:
      call docolon
      
        dw DUP,ZEROLESS,EXIT

;Z ?NEGATE  n1 n2 -- n3  negate n1 if n2 negative
;   0< IF NEGATE THEN ;        ...a common factor
    
      dw STOD_link
      db 0
QNEGATE_link:
      
      defm 7, "?NEGATE"
QNEGATE:
      call docolon
      
        DW ZEROLESS,qbranch,QNEG1,NEGATE
QNEG1:  DW EXIT

;C ABS     n1 -- +n2     absolute value
;   DUP ?NEGATE ;
    
      dw QNEGATE_link
      db 0
ABS_link:
      
      defm 3, "ABS"
ABS:
      call docolon
      
        DW DUP,QNEGATE,EXIT

;X DNEGATE   d1 -- d2     negate double precision
;   SWAP INVERT SWAP INVERT 1 M+ ;
    
      dw ABS_link
      db 0
DNEGATE_link:
      
      defm 7, "DNEGATE"
DNEGATE:
      call docolon
      
        DW SWOP,INVERT,SWOP,INVERT,lit,1,MPLUS
        DW EXIT

;Z ?DNEGATE  d1 n -- d2   negate d1 if n negative
;   0< IF DNEGATE THEN ;       ...a common factor
    
      dw DNEGATE_link
      db 0
QDNEGATE_link:
      
      defm 8, "?DNEGATE"
QDNEGATE:
      call docolon
      
        DW ZEROLESS,qbranch,DNEG1,DNEGATE
DNEG1:  DW EXIT

;X DABS     d1 -- +d2    absolute value dbl.prec.
;   DUP ?DNEGATE ;
    
      dw QDNEGATE_link
      db 0
DABS_link:
      
      defm 4, "DABS"
DABS:
      call docolon
      
        DW DUP,QDNEGATE,EXIT

;C M*     n1 n2 -- d    signed 16*16->32 multiply
;   2DUP XOR >R        carries sign of the result
;   SWAP ABS SWAP ABS UM*
;   R> ?DNEGATE ;
    
      dw DABS_link
      db 0
MSTAR_link:
      
      defm 2, "M*"
MSTAR:
      call docolon
      
        DW TWODUP,XOR,TOR
        DW SWOP,ABS,SWOP,ABS,UMSTAR
        DW RFROM,QDNEGATE,EXIT

;C SM/REM   d1 n1 -- n2 n3   symmetric signed div
;   2DUP XOR >R              sign of quotient
;   OVER >R                  sign of remainder
;   ABS >R DABS R> UM/MOD
;   SWAP R> ?NEGATE
;   SWAP R> ?NEGATE ;
; Ref. dpANS-6 section 3.2.2.1.
    
      dw MSTAR_link
      db 0
SMSLASHREM_link:
      
      defm 6, "SM/REM"
SMSLASHREM:
      call docolon
      
        DW TWODUP,XOR,TOR,OVER,TOR
        DW ABS,TOR,DABS,RFROM,UMSLASHMOD
        DW SWOP,RFROM,QNEGATE,SWOP,RFROM,QNEGATE
        DW EXIT

;C FM/MOD   d1 n1 -- n2 n3   floored signed div'n
;   DUP >R              save divisor
;   SM/REM
;   DUP 0< IF           if quotient negative,
;       SWAP R> +         add divisor to rem'dr
;       SWAP 1-           decrement quotient
;   ELSE R> DROP THEN ;
; Ref. dpANS-6 section 3.2.2.1.
    
      dw SMSLASHREM_link
      db 0
FMSLASHMOD_link:
      
      defm 6, "FM/MOD"
FMSLASHMOD:
      call docolon
      
        DW DUP,TOR,SMSLASHREM
        DW DUP,ZEROLESS,qbranch,FMMOD1
        DW SWOP,RFROM,PLUS,SWOP,ONEMINUS
        DW branch,FMMOD2
FMMOD1: DW RFROM,DROP
FMMOD2: DW EXIT

;C *      n1 n2 -- n3       signed multiply
;   M* DROP ;
    
      dw FMSLASHMOD_link
      db 0
STAR_link:
      
      defm 1, "*"
STAR:
      call docolon
      
        dw MSTAR,DROP,EXIT

;C /MOD   n1 n2 -- n3 n4    signed divide/rem'dr
;   >R S>D R> FM/MOD ;
    
      dw STAR_link
      db 0
SLASHMOD_link:
      
      defm 4, "/MOD"
SLASHMOD:
      call docolon
      
        dw TOR,STOD,RFROM,FMSLASHMOD,EXIT

;C /      n1 n2 -- n3       signed divide
;   /MOD nip ;
    
      dw SLASHMOD_link
      db 0
SLASH_link:
      
      defm 1, "/"
SLASH:
      call docolon
      
        dw SLASHMOD,NIP,EXIT

;C MOD    n1 n2 -- n3       signed remainder
;   /MOD DROP ;
    
      dw SLASH_link
      db 0
MOD_link:
      
      defm 3, "MOD"
MOD:
      call docolon
      
        dw SLASHMOD,DROP,EXIT

;C */MOD  n1 n2 n3 -- n4 n5    n1*n2/n3, rem&quot
;   >R M* R> FM/MOD ;
    
      dw MOD_link
      db 0
SSMOD_link:
      
      defm 5, "*/MOD"
SSMOD:
      call docolon
      
        dw TOR,MSTAR,RFROM,FMSLASHMOD,EXIT

;C */     n1 n2 n3 -- n4        n1*n2/n3
;   */MOD nip ;
    
      dw SSMOD_link
      db 0
STARSLASH_link:
      
      defm 2, "*/"
STARSLASH:
      call docolon
      
        dw SSMOD,NIP,EXIT

;C MAX    n1 n2 -- n3       signed maximum
;   2DUP < IF SWAP THEN DROP ;
    
      dw STARSLASH_link
      db 0
MAX_link:
      
      defm 3, "MAX"
MAX:
      call docolon
      
        dw TWODUP,LESS,qbranch,MAX1,SWOP
MAX1:   dw DROP,EXIT

;C MIN    n1 n2 -- n3       signed minimum
;   2DUP > IF SWAP THEN DROP ;
    
      dw MAX_link
      db 0
MIN_link:
      
      defm 3, "MIN"
MIN:
      call docolon
      
        dw TWODUP,GREATER,qbranch,MIN1,SWOP
MIN1:   dw DROP,EXIT

; DOUBLE OPERATORS ==============================

;C 2@    a-addr -- x1 x2    fetch 2 cells
;   DUP CELL+ @ SWAP @ ;
;   the lower address will appear on top of stack
    
      dw MIN_link
      db 0
TWOFETCH_link:
      
      defm 2, "2@"
TWOFETCH:
      call docolon
      
        dw DUP,CELLPLUS,FETCH,SWOP,FETCH,EXIT

;C 2!    x1 x2 a-addr --    store 2 cells
;   SWAP OVER ! CELL+ ! ;
;   the top of stack is stored at the lower adrs
    
      dw TWOFETCH_link
      db 0
TWOSTORE_link:
      
      defm 2, "2!"
TWOSTORE:
      call docolon
      
        dw SWOP,OVER,STORE,CELLPLUS,STORE,EXIT

;C 2DROP  x1 x2 --          drop 2 cells
;   DROP DROP ;
    
      dw TWOSTORE_link
      db 0
TWODROP_link:
      
      defm 5, "2DROP"
TWODROP:
      call docolon
      
        dw DROP,DROP,EXIT

;C 2DUP   x1 x2 -- x1 x2 x1 x2   dup top 2 cells
;   OVER OVER ;
    
      dw TWODROP_link
      db 0
TWODUP_link:
      
      defm 4, "2DUP"
TWODUP:
      call docolon
      
        dw OVER,OVER,EXIT

;C 2SWAP  x1 x2 x3 x4 -- x3 x4 x1 x2  per diagram
;   ROT >R ROT R> ;
    
      dw TWODUP_link
      db 0
TWOSWAP_link:
      
      defm 5, "2SWAP"
TWOSWAP:
      call docolon
      
        dw ROT,TOR,ROT,RFROM,EXIT

;C 2OVER  x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
;   >R >R 2DUP R> R> 2SWAP ;
    
      dw TWOSWAP_link
      db 0
TWOOVER_link:
      
      defm 5, "2OVER"
TWOOVER:
      call docolon
      
        dw TOR,TOR,TWODUP,RFROM,RFROM
        dw TWOSWAP,EXIT

; INPUT/OUTPUT ==================================

;C COUNT   c-addr1 -- c-addr2 u  counted->adr/len
;   DUP CHAR+ SWAP C@ ;
    
      dw TWOOVER_link
      db 0
COUNT_link:
      
      defm 5, "COUNT"
COUNT:
      call docolon
      
        dw DUP,CHARPLUS,SWOP,CFETCH,EXIT

;C CR      --               output newline
;   0D EMIT 0A EMIT ;
    
      dw COUNT_link
      db 0
CR_link:
      
      defm 2, "CR"
CR:
      call docolon
      
        dw lit,0dh,EMIT,lit,0ah,EMIT,EXIT

;C SPACE   --               output a space
;   BL EMIT ;
    
      dw CR_link
      db 0
SPACE_link:
      
      defm 5, "SPACE"
SPACE:
      call docolon
      
        dw BL,EMIT,EXIT

;C SPACES   n --            output n spaces
;   BEGIN DUP WHILE SPACE 1- REPEAT DROP ;
    
      dw SPACE_link
      db 0
SPACES_link:
      
      defm 6, "SPACES"
SPACES:
      call docolon
      
SPCS1:  DW DUP,qbranch,SPCS2
        DW SPACE,ONEMINUS,branch,SPCS1
SPCS2:  DW DROP,EXIT

;Z umin     u1 u2 -- u      unsigned minimum
;   2DUP U> IF SWAP THEN DROP ;
    
      dw SPACES_link
      db 0
UMIN_link:
      
      defm 4, "UMIN"
UMIN:
      call docolon
      
        DW TWODUP,UGREATER,qbranch,UMIN1,SWOP
UMIN1:  DW DROP,EXIT

;Z umax    u1 u2 -- u       unsigned maximum
;   2DUP U< IF SWAP THEN DROP ;
    
      dw UMIN_link
      db 0
UMAX_link:
      
      defm 4, "UMAX"
UMAX:
      call docolon
      
        DW TWODUP,ULESS,qbranch,UMAX1,SWOP
UMAX1:  DW DROP,EXIT

;C ACCEPT  c-addr +n -- +n'  get line from term'l
;   OVER + 1- OVER      -- sa ea a
;   BEGIN KEY           -- sa ea a c
;   DUP 0D <> WHILE
;       DUP EMIT        -- sa ea a c
;       DUP 8 = IF  DROP 1-    >R OVER R> UMAX
;             ELSE  OVER C! 1+ OVER UMIN
;       THEN            -- sa ea a
;   REPEAT              -- sa ea a c
;   DROP NIP SWAP - ;
    
      dw UMAX_link
      db 0
ACCEPT_link:
      
      defm 6, "ACCEPT"
ACCEPT:
      call docolon
      
        DW OVER,PLUS,ONEMINUS,OVER
ACC1:   DW KEY,DUP,lit,0DH,NOTEQUAL,qbranch,ACC5
        DW DUP,EMIT,DUP,lit,8,EQUAL,qbranch,ACC3
        DW DROP,ONEMINUS,TOR,OVER,RFROM,UMAX
        DW branch,ACC4
ACC3:   DW OVER,CSTORE,ONEPLUS,OVER,UMIN
ACC4:   DW branch,ACC1
ACC5:   DW DROP,NIP,SWOP,MINUS,EXIT

;C TYPE    c-addr +n --     type line to term'l
;   ?DUP IF
;     OVER + SWAP DO I C@ EMIT LOOP
;   ELSE DROP THEN ;
    
      dw ACCEPT_link
      db 0
TYPE_link:
      
      defm 4, "TYPE"
TYPE:
      call docolon
      
        DW QDUP,qbranch,TYP4
        DW OVER,PLUS,SWOP,xdo
TYP3:   DW II,CFETCH,EMIT,xloop,TYP3
        DW branch,TYP5
TYP4:   DW DROP
TYP5:   DW EXIT

;Z (S")     -- c-addr u   run-time code for S"
;   R> COUNT 2DUP + ALIGNED >R  ;
    
      dw TYPE_link
      db 0
XSQUOTE_link:
      
      defm 4, "(S",34,")"
XSQUOTE:
      call docolon
      
        DW RFROM,COUNT,TWODUP,PLUS,ALIGNED,TOR
        DW EXIT

;C S"       --         compile in-line string
;   COMPILE (S")  [ HEX ]
;   22 WORD C@ 1+ ALIGNED ALLOT ; IMMEDIATE
    
      dw XSQUOTE_link
      db 1
SQUOTE_link:
      
      defm 2, "S",34,""
SQUOTE:
      call docolon
      
        DW lit,XSQUOTE,COMMAXT
        DW lit,22H,WORD,CFETCH,ONEPLUS
        DW ALIGNED,ALLOT,EXIT

;C ."       --         compile string to print
;   POSTPONE S"  POSTPONE TYPE ; IMMEDIATE
    
      dw SQUOTE_link
      db 1
DOTQUOTE_link:
      
      defm 2, ".",34,""
DOTQUOTE:
      call docolon
      
        DW SQUOTE
        DW lit,TYPE,COMMAXT
        DW EXIT
                        
; NUMERIC OUTPUT ================================
; Numeric conversion is done l.s.digit first, so
; the output buffer is built backwards in memory.

; Some double-precision arithmetic operators are
; needed to implement ANSI numeric conversion.

;Z UD/MOD   ud1 u2 -- u3 ud4   32/16->32 divide
;   >R 0 R@ UM/MOD  ROT ROT R> UM/MOD ROT ;
    
      dw DOTQUOTE_link
      db 0
UDSLASHMOD_link:
      
      defm 6, "UD/MOD"
UDSLASHMOD:
      call docolon
      
        DW TOR,lit,0,RFETCH,UMSLASHMOD,ROT,ROT
        DW RFROM,UMSLASHMOD,ROT,EXIT

;Z UD*      ud1 d2 -- ud3      32*16->32 multiply
;   DUP >R UM* DROP  SWAP R> UM* ROT + ;
    
      dw UDSLASHMOD_link
      db 0
UDSTAR_link:
      
      defm 3, "UD*"
UDSTAR:
      call docolon
      
        DW DUP,TOR,UMSTAR,DROP
        DW SWOP,RFROM,UMSTAR,ROT,PLUS,EXIT

;C HOLD  char --        add char to output string
;   -1 HP +!  HP @ C! ;
    
      dw UDSTAR_link
      db 0
HOLD_link:
      
      defm 4, "HOLD"
HOLD:
      call docolon
      
        DW lit,-1,HP,PLUSSTORE
        DW HP,FETCH,CSTORE,EXIT

;C <#    --             begin numeric conversion
;   PAD HP ! ;          (initialize Hold Pointer)
    
      dw HOLD_link
      db 0
LESSNUM_link:
      
      defm 2, "<#"
LESSNUM:
      call docolon
      
        DW PAD,HP,STORE,EXIT

;Z >digit   n -- c      convert to 0..9A..Z
;   [ HEX ] DUP 9 > 7 AND + 30 + ;
    
      dw LESSNUM_link
      db 0
TODIGIT_link:
      
      defm 6, ">DIGIT"
TODIGIT:
      call docolon
      
        DW DUP,lit,9,GREATER,lit,7,AND,PLUS
        DW lit,30H,PLUS,EXIT

;C #     ud1 -- ud2     convert 1 digit of output
;   BASE @ UD/MOD ROT >digit HOLD ;
    
      dw TODIGIT_link
      db 0
NUM_link:
      
      defm 1, "#"
NUM:
      call docolon
      
        DW BASE,FETCH,UDSLASHMOD,ROT,TODIGIT
        DW HOLD,EXIT

;C #S    ud1 -- ud2     convert remaining digits
;   BEGIN # 2DUP OR 0= UNTIL ;
    
      dw NUM_link
      db 0
NUMS_link:
      
      defm 2, "#S"
NUMS:
      call docolon
      
NUMS1:  DW NUM,TWODUP,OR,ZEROEQUAL,qbranch,NUMS1
        DW EXIT

;C #>    ud1 -- c-addr u    end conv., get string
;   2DROP HP @ PAD OVER - ;
    
      dw NUMS_link
      db 0
NUMGREATER_link:
      
      defm 2, "#>"
NUMGREATER:
      call docolon
      
        DW TWODROP,HP,FETCH,PAD,OVER,MINUS,EXIT

;C SIGN  n --           add minus sign if n<0
;   0< IF 2D HOLD THEN ;
    
      dw NUMGREATER_link
      db 0
SIGN_link:
      
      defm 4, "SIGN"
SIGN:
      call docolon
      
        DW ZEROLESS,qbranch,SIGN1,lit,2DH,HOLD
SIGN1:  DW EXIT

;C U.    u --           display u unsigned
;   <# 0 #S #> TYPE SPACE ;
    
      dw SIGN_link
      db 0
UDOT_link:
      
      defm 2, "U."
UDOT:
      call docolon
      
        DW LESSNUM,lit,0,NUMS,NUMGREATER,TYPE
        DW SPACE,EXIT

;C .     n --           display n signed
;   <# DUP ABS 0 #S ROT SIGN #> TYPE SPACE ;
    
      dw UDOT_link
      db 0
DOT_link:
      
      defm 1, "."
DOT:
      call docolon
      
        DW LESSNUM,DUP,ABS,lit,0,NUMS
        DW ROT,SIGN,NUMGREATER,TYPE,SPACE,EXIT

;C DECIMAL  --      set number base to decimal
;   10 BASE ! ;
    
      dw DOT_link
      db 0
DECIMAL_link:
      
      defm 7, "DECIMAL"
DECIMAL:
      call docolon
      
        DW lit,10,BASE,STORE,EXIT

;X HEX     --       set number base to hex
;   16 BASE ! ;
    
      dw DECIMAL_link
      db 0
HEX_link:
      
      defm 3, "HEX"
HEX:
      call docolon
      
        DW lit,16,BASE,STORE,EXIT

; DICTIONARY MANAGEMENT =========================

;C HERE    -- addr      returns dictionary ptr
;   DP @ ;
    
      dw HEX_link
      db 0
HERE_link:
      
      defm 4, "HERE"
HERE:
      call docolon
      
        dw DP,FETCH,EXIT

;C ALLOT   n --         allocate n bytes in dict
;   DP +! ;
    
      dw HERE_link
      db 0
ALLOT_link:
      
      defm 5, "ALLOT"
ALLOT:
      call docolon
      
        dw DP,PLUSSTORE,EXIT

; Note: , and C, are only valid for combined
; Code and Data spaces.

;C ,    x --           append cell to dict
;   HERE ! 1 CELLS ALLOT ;
    
      dw ALLOT_link
      db 0
COMMA_link:
      
      defm 1, ","
COMMA:
      call docolon
      
        dw HERE,STORE,lit,1,CELLS,ALLOT,EXIT

;C C,   char --        append char to dict
;   HERE C! 1 CHARS ALLOT ;
    
      dw COMMA_link
      db 0
CCOMMA_link:
      
      defm 2, "C,"
CCOMMA:
      call docolon
      
        dw HERE,CSTORE,lit,1,CHARS,ALLOT,EXIT

; INTERPRETER ===================================
; Note that NFA>LFA, NFA>CFA, IMMED?, and FIND
; are dependent on the structure of the Forth
; header.  This may be common across many CPUs,
; or it may be different.

;C SOURCE   -- adr n    current input buffer
;   'SOURCE 2@ ;        length is at lower adrs
    
      dw CCOMMA_link
      db 0
SOURCE_link:
      
      defm 6, "SOURCE"
SOURCE:
      call docolon
      
        DW TICKSOURCE,TWOFETCH,EXIT

;X /STRING  a u n -- a+n u-n   trim string
;   ROT OVER + ROT ROT - ;
    
      dw SOURCE_link
      db 0
SLASHSTRING_link:
      
      defm 7, "/STRING"
SLASHSTRING:
      call docolon
      
        DW ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

;Z >counted  src n dst --     copy to counted str
;   2DUP C! CHAR+ SWAP CMOVE ;
    
      dw SLASHSTRING_link
      db 0
TOCOUNTED_link:
      
      defm 8, ">COUNTED"
TOCOUNTED:
      call docolon
      
        DW TWODUP,CSTORE,CHARPLUS,SWOP,CMOVE,EXIT

;C WORD   char -- c-addr n   word delim'd by char
;   DUP  SOURCE >IN @ /STRING   -- c c adr n
;   DUP >R   ROT SKIP           -- c adr' n'
;   OVER >R  ROT SCAN           -- adr" n"
;   DUP IF CHAR- THEN        skip trailing delim.
;   R> R> ROT -   >IN +!        update >IN offset
;   TUCK -                      -- adr' N
;   HERE >counted               --
;   HERE                        -- a
;   BL OVER COUNT + C! ;    append trailing blank
    
      dw TOCOUNTED_link
      db 0
WORD_link:
      
      defm 4, "WORD"
WORD:
      call docolon
      
        DW DUP,SOURCE,TOIN,FETCH,SLASHSTRING
        DW DUP,TOR,ROT,skip
        DW OVER,TOR,ROT,scan
        DW DUP,qbranch,WORD1,ONEMINUS  ; char-
WORD1:  DW RFROM,RFROM,ROT,MINUS,TOIN,PLUSSTORE
        DW TUCK,MINUS
        DW HERE,TOCOUNTED,HERE
        DW BL,OVER,COUNT,PLUS,CSTORE,EXIT

;Z NFA>LFA   nfa -- lfa    name adr -> WORD_link field
;   3 - ;
    
      dw WORD_link
      db 0
NFATOLFA_link:
      
      defm 7, "NFA>LFA"
NFATOLFA:
      call docolon
      
        DW lit,3,MINUS,EXIT

;Z NFA>CFA   nfa -- cfa    name adr -> code field
;   COUNT 7F AND + ;       mask off 'smudge' bit
    
      dw NFATOLFA_link
      db 0
NFATOCFA_link:
      
      defm 7, "NFA>CFA"
NFATOCFA:
      call docolon
      
        DW COUNT,lit,07FH,AND,PLUS,EXIT

;Z IMMED?    nfa -- f      fetch immediate flag
;   1- C@ ;                     nonzero if `immed'
    
      dw NFATOCFA_link
      db 0
IMMEDQ_link:
      
      defm 6, "IMMED?"
IMMEDQ:
      call docolon
      
        DW ONEMINUS,CFETCH,EXIT

;C FIND   c-addr -- c-addr 0   if not found
;C                  xt  1      if immediate
;C                  xt -1      if "normal"
;   LATEST @ BEGIN             -- a nfa
;       2DUP OVER C@ CHAR+     -- a nfa a nfa n+1
;       S=                     -- a nfa f
;       DUP IF
;           DROP
;           NFA>LFA @ DUP      -- a IMMEDQ_link IMMEDQ_link
;       THEN
;   0= UNTIL                   -- a nfa  OR  a 0
;   DUP IF
;       NIP DUP NFA>CFA        -- nfa xt
;       SWAP IMMED?            -- xt iflag
;       0= 1 OR                -- xt 1/-1
;   THEN ;
    
      dw IMMEDQ_link
      db 0
FIND_link:
      
      defm 4, "FIND"
FIND:
      call docolon
      
        DW LATEST,FETCH
FIND1:  DW TWODUP,OVER,CFETCH,CHARPLUS
        DW sequal,DUP,qbranch,FIND2
        DW DROP,NFATOLFA,FETCH,DUP
FIND2:  DW ZEROEQUAL,qbranch,FIND1
        DW DUP,qbranch,FIND3
        DW NIP,DUP,NFATOCFA
        DW SWOP,IMMEDQ,ZEROEQUAL,lit,1,OR
FIND3:  DW EXIT

;C LITERAL  x --        append numeric literal
;   STATE @ IF ['] LIT ,XT , THEN ; IMMEDIATE
; This tests STATE so that it can also be used
; interpretively.  (ANSI doesn't require this.)
    
      dw FIND_link
      db 1
LITERAL_link:
      
      defm 7, "LITERAL"
LITERAL:
      call docolon
      
        DW STATE,FETCH,qbranch,LITER1
        DW lit,lit,COMMAXT,COMMA
LITER1: DW EXIT

;Z DIGIT?   c -- n -1   if c is a valid digit
;Z            -- x  0   otherwise
;   [ HEX ] DUP 39 > 100 AND +     silly looking
;   DUP 140 > 107 AND -   30 -     but it works!
;   DUP BASE @ U< ;
    
      dw LITERAL_link
      db 0
DIGITQ_link:
      
      defm 6, "DIGIT?"
DIGITQ:
      call docolon
      
        DW DUP,lit,39H,GREATER,lit,100H,AND,PLUS
        DW DUP,lit,140H,GREATER,lit,107H,AND
        DW MINUS,lit,30H,MINUS
        DW DUP,BASE,FETCH,ULESS,EXIT

;Z ?SIGN   adr n -- adr' n' f  get optional sign
;Z  advance adr/n if sign; return NZ if negative
;   OVER C@                 -- adr n c
;   2C - DUP ABS 1 = AND    -- +=-1, -=+1, else 0
;   DUP IF 1+               -- +=0, -=+2
;       >R 1 /STRING R>     -- adr' n' f
;   THEN ;
    
      dw DIGITQ_link
      db 0
QSIGN_link:
      
      defm 5, "?SIGN"
QSIGN:
      call docolon
      
        DW OVER,CFETCH,lit,2CH,MINUS,DUP,ABS
        DW lit,1,EQUAL,AND,DUP,qbranch,QSIGN1
        DW ONEPLUS,TOR,lit,1,SLASHSTRING,RFROM
QSIGN1: DW EXIT

;C >NUMBER  ud adr u -- ud' adr' u'
;C                      convert string to number
;   BEGIN
;   DUP WHILE
;       OVER C@ DIGIT?
;       0= IF DROP EXIT THEN
;       >R 2SWAP BASE @ UD*
;       R> M+ 2SWAP
;       1 /STRING
;   REPEAT ;
    
      dw QSIGN_link
      db 0
TONUMBER_link:
      
      defm 7, ">NUMBER"
TONUMBER:
      call docolon
      
TONUM1: DW DUP,qbranch,TONUM3
        DW OVER,CFETCH,DIGITQ
        DW ZEROEQUAL,qbranch,TONUM2,DROP,EXIT
TONUM2: DW TOR,TWOSWAP,BASE,FETCH,UDSTAR
        DW RFROM,MPLUS,TWOSWAP
        DW lit,1,SLASHSTRING,branch,TONUM1
TONUM3: DW EXIT

;Z ?NUMBER  c-addr -- n -1      string->number
;Z                 -- c-addr 0  if convert error
;   DUP  0 0 ROT COUNT      -- ca ud adr n
;   ?SIGN >R  >NUMBER       -- ca ud adr' n'
;   IF   R> 2DROP 2DROP 0   -- ca 0   (error)
;   ELSE 2DROP NIP R>
;       IF NEGATE THEN  -1  -- n -1   (ok)
;   THEN ;
    
      dw TONUMBER_link
      db 0
QNUMBER_link:
      
      defm 7, "?NUMBER"
QNUMBER:
      call docolon
      
        DW DUP,lit,0,DUP,ROT,COUNT
        DW QSIGN,TOR,TONUMBER,qbranch,QNUM1
        DW RFROM,TWODROP,TWODROP,lit,0
        DW branch,QNUM3
QNUM1:  DW TWODROP,NIP,RFROM,qbranch,QNUM2,NEGATE
QNUM2:  DW lit,-1
QNUM3:  DW EXIT

;Z INTERPRET    i*x c-addr u -- j*x
;Z                      interpret given buffer
; This is a common factor of EVALUATE and QUIT.
; ref. dpANS-6, 3.4 The Forth Text Interpreter
;   'SOURCE 2!  0 >IN !
;   BEGIN
;   BL WORD DUP C@ WHILE        -- textadr
;       FIND                    -- a 0/1/-1
;       ?DUP IF                 -- xt 1/-1
;           1+ STATE @ 0= OR    immed or interp?
;           IF EXECUTE ELSE ,XT THEN
;       ELSE                    -- textadr
;           ?NUMBER
;           IF POSTPONE LITERAL     converted ok
;           ELSE COUNT TYPE 3F EMIT CR ABORT  err
;           THEN
;       THEN
;   REPEAT DROP ;
    
      dw QNUMBER_link
      db 0
INTERPRET_link:
      
      defm 9, "INTERPRET"
INTERPRET:
      call docolon
      
        DW TICKSOURCE,TWOSTORE,lit,0,TOIN,STORE
INTER1: DW BL,WORD,DUP,CFETCH,qbranch,INTER9
        DW FIND,QDUP,qbranch,INTER4
        DW ONEPLUS,STATE,FETCH,ZEROEQUAL,OR
        DW qbranch,INTER2
        DW EXECUTE,branch,INTER3
INTER2: DW COMMAXT
INTER3: DW branch,INTER8
INTER4: DW QNUMBER,qbranch,INTER5
        DW LITERAL,branch,INTER6
INTER5: DW COUNT,TYPE,lit,3FH,EMIT,CR,ABORT
INTER6:
INTER8: DW branch,INTER1
INTER9: DW DROP,EXIT

;C EVALUATE  i*x c-addr u -- j*x  interprt string
;   'SOURCE 2@ >R >R  >IN @ >R
;   INTERPRET
;   R> >IN !  R> R> 'SOURCE 2! ;
    
      dw INTERPRET_link
      db 0
EVALUATE_link:
      
      defm 8, "EVALUATE"
EVALUATE:
      call docolon
      
        DW TICKSOURCE,TWOFETCH,TOR,TOR
        DW TOIN,FETCH,TOR,INTERPRET
        DW RFROM,TOIN,STORE,RFROM,RFROM
        DW TICKSOURCE,TWOSTORE,EXIT

;C QUIT     --    R: i*x --    interpret from kbd
;   L0 LP !  R0 RP!   0 STATE !
;   BEGIN
;       TIB DUP TIBSIZE ACCEPT  SPACE
;       INTERPRET
;       STATE @ 0= IF CR ." OK" THEN
;   AGAIN ;
    
      dw EVALUATE_link
      db 0
QUIT_link:
      
      defm 4, "QUIT"
QUIT:
      call docolon
      
        DW L0,LP,STORE
        DW R0,RPSTORE,lit,0,STATE,STORE
QUIT1:  DW TIB,DUP,TIBSIZE,CPMACCEPT,SPACE
        DW INTERPRET
        DW STATE,FETCH,ZEROEQUAL,qbranch,QUIT2
        DW CR,XSQUOTE
        DB 3,"ok "
        DW TYPE
QUIT2:  DW branch,QUIT1

;C ABORT    i*x --   R: j*x --   clear stk & QUIT
;   S0 SP!  QUIT ;
    
      dw QUIT_link
      db 0
ABORT_link:
      
      defm 5, "ABORT"
ABORT:
      call docolon
      
        DW S0,SPSTORE,QUIT   ; QUIT never returns

;Z ?ABORT   f c-addr u --      abort & print msg
;   ROT IF TYPE ABORT THEN 2DROP ;
    
      dw ABORT_link
      db 0
QABORT_link:
      
      defm 6, "?ABORT"
QABORT:
      call docolon
      
        DW ROT,qbranch,QABO1,TYPE,ABORT
QABO1:  DW TWODROP,EXIT

;C ABORT"  i*x 0  -- i*x   R: j*x -- j*x  x1=0
;C         i*x x1 --       R: j*x --      x1<>0
;   POSTPONE S" POSTPONE ?ABORT ; IMMEDIATE
    
      dw QABORT_link
      db 1
ABORTQUOTE_link:
      
      defm 6, "ABORT",34,""
ABORTQUOTE:
      call docolon
      
        DW SQUOTE
        DW lit,QABORT,COMMAXT
        DW EXIT

;C '    -- xt           find word in dictionary
;   BL WORD FIND
;   0= ABORT" ?" ;
     
      dw ABORTQUOTE_link
      db 0
TICK_link:
      
      defm 1, "'"
TICK:
      call docolon
      
        DW BL,WORD,FIND,ZEROEQUAL,XSQUOTE
        DB 1,"?"
        DW QABORT,EXIT

;C CHAR   -- char           parse ASCII character
;   BL WORD 1+ C@ ;
    
      dw TICK_link
      db 0
CHAR_link:
      
      defm 4, "CHAR"
CHAR:
      call docolon
      
        DW BL,WORD,ONEPLUS,CFETCH,EXIT

;C [CHAR]   --          compile character literal
;   CHAR  ['] LIT ,XT  , ; IMMEDIATE
    
      dw CHAR_link
      db 1
BRACCHAR_link:
      
      defm 6, "[CHAR]"
BRACCHAR:
      call docolon
      
        DW CHAR
        DW lit,lit,COMMAXT
        DW COMMA,EXIT

;C (    --                     skip input until )
;   [ HEX ] 29 WORD DROP ; IMMEDIATE
    
      dw BRACCHAR_link
      db 1
PAREN_link:
      
      defm 1, "("
PAREN:
      call docolon
      
        DW lit,29H,WORD,DROP,EXIT

; COMPILER ======================================

;C CREATE   --      create an empty definition
;   LATEST @ , 0 C,         PAREN_link & immed field
;   HERE LATEST !           new "latest" PAREN_link
;   BL WORD C@ 1+ ALLOT         name field
;   docreate ,CF                code field
    
      dw PAREN_link
      db 0
CREATE_link:
      
      defm 6, "CREATE"
CREATE:
      call docolon
      
        DW LATEST,FETCH,COMMA,lit,0,CCOMMA
        DW HERE,LATEST,STORE
        DW BL,WORD,CFETCH,ONEPLUS,ALLOT
        DW lit,docreate,COMMACF,EXIT
        
;Z (DOES>)  --      run-time action of DOES>
;   R>              adrs of headless DOES> def'n
;   LATEST @ NFA>CFA    code field to fix up
;   !CF ;
    
      dw CREATE_link
      db 0
XDOES_link:
      
      defm 7, "(DOES>)"
XDOES:
      call docolon
      
        DW RFROM,LATEST,FETCH,NFATOCFA,STORECF
        DW EXIT

;C DOES>    --      change action of latest def'n
;   COMPILE (DOES>)
;   dodoes ,CF ; IMMEDIATE
    
      dw XDOES_link
      db 1
DOES_link:
      
      defm 5, "DOES>"
DOES:
      call docolon
      
        DW lit,XDOES,COMMAXT
        DW lit,dodoes,COMMACF,EXIT

;C RECURSE  --      recurse current definition
;   LATEST @ NFA>CFA ,XT ; IMMEDIATE
    
      dw DOES_link
      db 1
RECURSE_link:
      
      defm 7, "RECURSE"
RECURSE:
      call docolon
      
        DW LATEST,FETCH,NFATOCFA,COMMAXT,EXIT

;C [        --      enter interpretive state
;   0 STATE ! ; IMMEDIATE
    
      dw RECURSE_link
      db 1
LEFTBRACKET_link:
      
      defm 1, "["
LEFTBRACKET:
      call docolon
      
        DW lit,0,STATE,STORE,EXIT

;C ]        --      enter compiling state
;   -1 STATE ! ;
    
      dw LEFTBRACKET_link
      db 0
RIGHTBRACKET_link:
      
      defm 1, "]"
RIGHTBRACKET:
      call docolon
      
        DW lit,-1,STATE,STORE,EXIT

;Z HIDE     --      "hide" latest definition
;   LATEST @ DUP C@ 80 OR SWAP C! ;
    
      dw RIGHTBRACKET_link
      db 0
HIDE_link:
      
      defm 4, "HIDE"
HIDE:
      call docolon
      
        DW LATEST,FETCH,DUP,CFETCH,lit,80H,OR
        DW SWOP,CSTORE,EXIT

;Z REVEAL   --      "reveal" latest definition
;   LATEST @ DUP C@ 7F AND SWAP C! ;
    
      dw HIDE_link
      db 0
REVEAL_link:
      
      defm 6, "REVEAL"
REVEAL:
      call docolon
      
        DW LATEST,FETCH,DUP,CFETCH,lit,7FH,AND
        DW SWOP,CSTORE,EXIT

;C IMMEDIATE   --   make last def'n immediate
;   1 LATEST @ 1- C! ;   set immediate flag
    
      dw REVEAL_link
      db 0
IMMEDIATE_link:
      
      defm 9, "IMMEDIATE"
IMMEDIATE:
      call docolon
      
        DW lit,1,LATEST,FETCH,ONEMINUS,CSTORE
        DW EXIT

;C :        --      begin a colon definition
;   CREATE HIDE ] !COLON ;
    
      dw IMMEDIATE_link
      db 0
COLON_link:
      
      defm 1, ":"
COLON:
      
      
        CALL docolon    ; code fwd ref explicitly
        DW CREATE,HIDE,RIGHTBRACKET,STORCOLON
        DW EXIT

;C ;
;   REVEAL  ,EXIT
;   POSTPONE [  ; IMMEDIATE
    
      dw COLON_link
      db 1
SEMICOLON_link:
      
      defm 1, ";"
SEMICOLON:
      call docolon
      
        DW REVEAL,CEXIT
        DW LEFTBRACKET,EXIT

    
      dw SEMICOLON_link
      db 1
BRACTICK_link:
      
      defm 3, "[']"
BRACTICK:
      call docolon
      
        DW TICK               ; get xt of 'xxx'
        DW lit,lit,COMMAXT    ; append LIT action
        DW COMMA,EXIT         ; append xt literal

;C POSTPONE  --   postpone compile action of word
;   BL WORD FIND
;   DUP 0= ABORT" ?"
;   0< IF   -- xt  non immed: add code to current
;                  def'n to compile xt later.
;       ['] LIT ,XT  ,      add "lit,xt,COMMAXT"
;       ['] ,XT ,XT         to current definition
;   ELSE  ,XT      immed: compile into cur. def'n
;   THEN ; IMMEDIATE
    
      dw BRACTICK_link
      db 1
POSTPONE_link:
      
      defm 8, "POSTPONE"
POSTPONE:
      call docolon
      
        DW BL,WORD,FIND,DUP,ZEROEQUAL,XSQUOTE
        DB 1,"?"
        DW QABORT,ZEROLESS,qbranch,POST1
        DW lit,lit,COMMAXT,COMMA
        DW lit,COMMAXT,COMMAXT,branch,POST2
POST1:  DW COMMAXT
POST2:  DW EXIT
               
;Z COMPILE   --   append inline execution token
;   R> DUP CELL+ >R @ ,XT ;
; The phrase ['] xxx ,XT appears so often that
; this word was created to combine the actions
; of LIT and ,XT.  It takes an inline literal
; execution token and appends it to the dict.
;    xxxhead COMPILE,7,COMPILE,docolon
;        DW RFROM,DUP,CELLPLUS,TOR
;        DW FETCH,COMMAXT,EXIT
; N.B.: not used in the current implementation

; CONTROL STRUCTURES ============================

;C IF       -- adrs    conditional forward branch
;   ['] qbranch ,BRANCH  HERE DUP ,DEST ;
;   IMMEDIATE
    
      dw POSTPONE_link
      db 1
IF_link:
      
      defm 2, "IF"
IF:
      call docolon
      
        DW lit,qbranch,COMMABRANCH
        DW HERE,DUP,COMMADEST,EXIT

;C THEN     adrs --        resolve forward branch
;   HERE SWAP !DEST ; IMMEDIATE
    
      dw IF_link
      db 1
THEN_link:
      
      defm 4, "THEN"
THEN:
      call docolon
      
        DW HERE,SWOP,STOREDEST,EXIT

;C ELSE     adrs1 -- adrs2    branch for IF..ELSE
;   ['] branch ,BRANCH  HERE DUP ,DEST
;   SWAP  POSTPONE THEN ; IMMEDIATE
    
      dw THEN_link
      db 1
ELSE_link:
      
      defm 4, "ELSE"
ELSE:
      call docolon
      
        DW lit,branch,COMMABRANCH
        DW HERE,DUP,COMMADEST
        DW SWOP,THEN,EXIT

;C BEGIN    -- adrs        target for bwd. branch
;   HERE ; IMMEDIATE
    
      dw ELSE_link
      db 1
BEGIN_link:
      
      defm 5, "BEGIN"
BEGIN:
      
      
        jp HERE

;C UNTIL    adrs --   conditional backward branch
;   ['] qbranch ,BRANCH  ,DEST ; IMMEDIATE
;   conditional backward branch
    
      dw BEGIN_link
      db 1
UNTIL_link:
      
      defm 5, "UNTIL"
UNTIL:
      call docolon
      
        DW lit,qbranch,COMMABRANCH
        DW COMMADEST,EXIT

;X AGAIN    adrs --      uncond'l backward branch
;   ['] branch ,BRANCH  ,DEST ; IMMEDIATE
;   unconditional backward branch
    
      dw UNTIL_link
      db 1
AGAIN_link:
      
      defm 5, "AGAIN"
AGAIN:
      call docolon
      
        DW lit,branch,COMMABRANCH
        DW COMMADEST,EXIT

;C WHILE    -- adrs         branch for WHILE loop
;   POSTPONE IF ; IMMEDIATE
    
      dw AGAIN_link
      db 1
WHILE_link:
      
      defm 5, "WHILE"
WHILE:
      
      
        jp IF

;C REPEAT   adrs1 adrs2 --     resolve WHILE loop
;   SWAP POSTPONE AGAIN POSTPONE THEN ; IMMEDIATE
    
      dw WHILE_link
      db 1
REPEAT_link:
      
      defm 6, "REPEAT"
REPEAT:
      call docolon
      
        DW SWOP,AGAIN,THEN,EXIT

;Z >L   x --   L: -- x        move to leave stack
;   CELL LP +!  LP @ ! ;      (L stack grows up)
    
      dw REPEAT_link
      db 0
TOL_link:
      
      defm 2, ">L"
TOL:
      call docolon
      
        DW CELL,LP,PLUSSTORE,LP,FETCH,STORE,EXIT

;Z L>   -- x   L: x --      move from leave stack
;   LP @ @  CELL NEGATE LP +! ;
    
      dw TOL_link
      db 0
LFROM_link:
      
      defm 2, "L>"
LFROM:
      call docolon
      
        DW LP,FETCH,FETCH
        DW CELL,NEGATE,LP,PLUSSTORE,EXIT

;C DO       -- adrs   L: -- 0
;   ['] xdo ,XT   HERE     target for bwd branch
;   0 >L ; IMMEDIATE           marker for LEAVEs
    
      dw LFROM_link
      db 1
DO_link:
      
      defm 2, "DO"
DO:
      call docolon
      
        DW lit,xdo,COMMAXT,HERE
        DW lit,0,TOL,EXIT

;Z ENDLOOP   adrs xt --   L: 0 a1 a2 .. aN --
;   ,BRANCH  ,DEST                backward loop
;   BEGIN L> ?DUP WHILE POSTPONE THEN REPEAT ;
;                                 resolve LEAVEs
; This is a common factor of LOOP and +LOOP.
    
      dw DO_link
      db 0
ENDLOOP_link:
      
      defm 7, "ENDLOOP"
ENDLOOP:
      call docolon
      
        DW COMMABRANCH,COMMADEST
LOOP1:  DW LFROM,QDUP,qbranch,LOOP2
        DW THEN,branch,LOOP1
LOOP2:  DW EXIT

;C LOOP    adrs --   L: 0 a1 a2 .. aN --
;   ['] xloop ENDLOOP ;  IMMEDIATE
    
      dw ENDLOOP_link
      db 1
LOOP_link:
      
      defm 4, "LOOP"
LOOP:
      call docolon
      
        DW lit,xloop,ENDLOOP,EXIT

;C +LOOP   adrs --   L: 0 a1 a2 .. aN --
;   ['] xplusloop ENDLOOP ;  IMMEDIATE
    
      dw LOOP_link
      db 1
PLUSLOOP_link:
      
      defm 5, "+LOOP"
PLUSLOOP:
      call docolon
      
        DW lit,xplusloop,ENDLOOP,EXIT

;C LEAVE    --    L: -- adrs
;   ['] UNLOOP ,XT
;   ['] branch ,BRANCH   HERE DUP ,DEST  >L
;   ; IMMEDIATE      unconditional forward branch
    
      dw PLUSLOOP_link
      db 1
LEAVE_link:
      
      defm 5, "LEAVE"
LEAVE:
      call docolon
      
        DW lit,UNLOOP,COMMAXT
        DW lit,branch,COMMABRANCH
        DW HERE,DUP,COMMADEST,TOL,EXIT

; OTHER OPERATIONS ==============================

;X WITHIN   n1|u1 n2|u2 n3|u3 -- f   n2<=n1<n3?
;  OVER - >R - R> U< ;          per ANS document
    
      dw LEAVE_link
      db 0
WITHIN_link:
      
      defm 6, "WITHIN"
WITHIN:
      call docolon
      
        DW OVER,MINUS,TOR,MINUS,RFROM,ULESS,EXIT

;C MOVE    addr1 addr2 u --     smart move
;             VERSION FOR 1 ADDRESS UNIT = 1 CHAR
;  >R 2DUP SWAP DUP R@ +     -- ... dst src src+n
;  WITHIN IF  R> CMOVE>        src <= dst < src+n
;       ELSE  R> CMOVE  THEN ;          otherwise
    
      dw WITHIN_link
      db 0
MOVE_link:
      
      defm 4, "MOVE"
MOVE:
      call docolon
      
        DW TOR,TWODUP,SWOP,DUP,RFETCH,PLUS
        DW WITHIN,qbranch,MOVE1
        DW RFROM,CMOVEUP,branch,MOVE2
MOVE1:  DW RFROM,CMOVE
MOVE2:  DW EXIT

;C DEPTH    -- +n        number of items on stack
;   SP@ S0 SWAP - 2/ ;   16-BIT VERSION!
    
      dw MOVE_link
      db 0
DEPTH_link:
      
      defm 5, "DEPTH"
DEPTH:
      call docolon
      
        DW SPFETCH,S0,SWOP,MINUS,TWOSLASH,EXIT

;C ENVIRONMENT?  c-addr u -- false   system query
;                         -- i*x true
;   2DROP 0 ;       the minimal definition!
    
      dw DEPTH_link
      db 0
ENVIRONMENTQ_link:
      
      defm 12, "ENVIRONMENT?"
ENVIRONMENTQ:
      call docolon
      
        DW TWODROP,lit,0,EXIT

; UTILITY WORDS AND STARTUP =====================

;X WORDS    --          list all words in dict.
;   LATEST @ BEGIN
;       DUP COUNT TYPE SPACE
;       NFA>LFA @
;   DUP 0= UNTIL
;   DROP ;
    
      dw ENVIRONMENTQ_link
      db 0
WORDS_link:
      
      defm 5, "WORDS"
WORDS:
      call docolon
      
        DW LATEST,FETCH
WDS1:   DW DUP,COUNT,TYPE,SPACE,NFATOLFA,FETCH
        DW DUP,ZEROEQUAL,qbranch,WDS1
        DW DROP,EXIT

;X .S      --           print stack contents
;   SP@ S0 - IF
;       SP@ S0 2 - DO I @ U. -2 +LOOP
;   THEN ;
    
      dw WORDS_link
      db 0
DOTS_link:
      
      defm 2, ".S"
DOTS:
      call docolon
      
        DW SPFETCH,S0,MINUS,qbranch,DOTS2
        DW SPFETCH,S0,lit,2,MINUS,xdo
DOTS1:  DW II,FETCH,UDOT,lit,-2,xplusloop,DOTS1
DOTS2:  DW EXIT

;C D.    d --           display d signed
    
      dw DOTS_link
      db 0
DDOT_link:
      
      defm 2, "D."
DDOT:
      call docolon
      
        DW LESSNUM,DUP,TOR,DABS,NUMS
        DW RFROM,SIGN,NUMGREATER,TYPE,SPACE,EXIT

;X D+               d1 d2 -- d1+d2              Add double numbers
    
      dw DDOT_link
      db 0
DPLUS_link:
      
      defm 2, "D+"
DPLUS:
      
      
        exx
        pop bc          ; BC'=d2lo
        exx
        pop hl          ; HL=d1hi,BC=d2hi
        exx
        pop hl          ; HL'=d1lo
        add hl,bc
        push hl         ; 2OS=d1lo+d2lo
        exx
        adc hl,bc       ; HL=d1hi+d2hi+cy
        ld b,h
        ld c,l
        
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;C 2>R   d --           2 to R
    
      dw DPLUS_link
      db 0
TWOTOR_link:
      
      defm 3, "2>R"
TWOTOR:
      call docolon
      
        DW SWOP,RFROM,SWOP,TOR,SWOP,TOR,TOR,EXIT

;C 2R>   d --           fetch 2 from R
    
      dw TWOTOR_link
      db 0
TWORFROM_link:
      
      defm 3, "2R>"
TWORFROM:
      call docolon
      
        DW RFROM,RFROM,RFROM,SWOP,ROT,TOR,EXIT

TNEGATE:
        call docolon
        DW TOR,TWODUP,OR,DUP,qbranch,TNEG1,DROP,DNEGATE,lit,1
TNEG1:
        DW RFROM,PLUS,NEGATE,EXIT

qtneg:
        call docolon
        DW ZEROLESS,qbranch,qtneg1,TNEGATE
qtneg1:
        DW EXIT

TSTAR:
        call docolon
        DW TWODUP,XOR,TOR
        DW TOR,DABS,RFROM,ABS
        DW TWOTOR
        DW RFETCH,UMSTAR,lit,0
        DW TWORFROM,UMSTAR
        DW DPLUS
        DW RFROM
        DW qtneg
        DW EXIT

TDIV:
        call docolon
        DW OVER,TOR,TOR
        DW DUP,qtneg
        DW RFETCH,UMSLASHMOD
        DW ROT,ROT
        DW RFROM,UMSLASHMOD
        DW NIP,SWOP
        DW RFROM,ZEROLESS,qbranch,tdiv1,DNEGATE
tdiv1:
        DW EXIT

    
      dw TWORFROM_link
      db 0
MSTARSLASH_link:
      
      defm 3, "M*/"
MSTARSLASH:
      call docolon
      
        DW TOR,TSTAR,RFROM,TDIV,EXIT

;Z COLD     --      cold start Forth system
;   UINIT U0 #INIT CMOVE      init user area
;   80 COUNT INTERPRET       interpret CP/M cmd
;   ." Z80 CamelForth etc."
;   ABORT ;
    
      dw MSTARSLASH_link
      db 0
COLD_link:
      
      defm 4, "COLD"
COLD:
      call docolon
      
        DW UINIT,U0,NINIT,CMOVE
        DW XSQUOTE
        DB 35,"Z80 CamelForth v1.01  25 Jan 1995"
        DB 0dh,0ah
        DW TYPE,ABORT       ; ABORT never returns

   ; High Level words
; ============================================================
; Z80Mini CamelForth Extensions
; Incluir via: m4 camel80.asm.m4 z80mini_forth.asm.m4 > camel80_gen.asm
;
; Convenções CamelForth:
;   BC = TOS    DE = IP (NUNCA corromper sem salvar!)
;   SP = PSP    IX = RSP    IY = UP
;
; Padrão para chamadas ROM simples (sem usar DE):
;   push bc / push de / push hl
;   call ROM_FUNC
;   pop hl / pop de / pop bc
;
; Padrão para chamadas que precisam de DE como argumento:
;   exx          ; salva IP em DE', valores em BC'/HL'
;   ... monta registradores ...
;   call ROM_FUNC
;   exx          ; restaura IP em DE
; ============================================================

; ------------------------------------------------------------
; ROM API — Jump Table $0100
; ------------------------------------------------------------
delay500ms      EQU $0100
delay           EQU $0103   ; DE = milissegundos

I2C_Open        EQU $0106   ; A = endereço (bit0=leitura)
I2C_Close       EQU $0109
I2C_Read        EQU $010C   ; saída: A=byte, Z=ok
I2C_Write       EQU $010F   ; entrada: A=byte

keyboardIsEsc   EQU $0112
keyboardWaitA   EQU $0115   ; bloqueante, preserva BC DE HL
keyboardA       EQU $0118   ; Carry=1 se tecla, preserva BC DE HL

setDefaultSerialA EQU $011B
setDefaultSerialB EQU $011E
serialPrintA    EQU $0121   ; A = char → terminal setado
serialInputA    EQU $0124   ; saída: A = char (bloqueante)
serialPrintStr  EQU $0127   ; HL = string terminada em 0
serialCRLF      EQU $012A
serialHexA      EQU $012D   ; A = byte → imprime "XX"
serialHexHL     EQU $0130   ; HL → imprime "XXXX"

initLCD         EQU $0139
clearGBUF       EQU $013C
clearGrLCD      EQU $013F
clearTxtLCD     EQU $0142
setGrMode       EQU $0145
setTxtMode      EQU $0148

drawBox         EQU $014B   ; B=X0 C=Y0 D=X1 E=Y1
drawLine        EQU $014E   ; B=X0 C=Y0 D=X1 E=Y1
drawCircle      EQU $0151   ; B=X  C=Y  E=raio
drawPixel       EQU $0154   ; B=X  C=Y
fillBox         EQU $0157   ; B=X0 C=Y0 D=X1 E=Y1
fillCircle      EQU $015A   ; B=X  C=Y  E=raio
plotToLCD       EQU $015D
printString     EQU $0160   ; A=linha (0-3), string na próxima linha
printChars      EQU $0163   ; B=col C=lin HL=str

setBufClear     EQU $016C
setBufNoClear   EQU $016F
clearPixel      EQU $0172   ; B=X C=Y
flipPixel       EQU $0175   ; B=X C=Y
drawGraphic     EQU $0178   ; A=ascii (ou 0+HL) B=w C=h

initTerminal    EQU $017E
sendCharToLCD   EQU $0181   ; A = char ASCII → terminal GLCD
sendStringToLCD EQU $0184   ; DE=str A=char-parada
sendRegToLCD    EQU $0187   ; A = byte → HEX no GLCD
sendHLToLCD     EQU $018A   ; HL → "XXXX" no GLCD
setCursor       EQU $018D   ; B=X(0-127) C=Y(0-63) pixel
getCursor       EQU $0190   ; saída: B=X C=Y
displayCursor   EQU $0193   ; A=0 ativa, A!=0 desativa
autoLF          EQU $0196   ; A=0 liga, A!=0 desliga
plotAlways      EQU $019C   ; A=0 sempre, A!=0 manual

resetCollision  EQU $0294
checkCollision  EQU $0299   ; Z=sem colisão, NZ=colisão

; ============================================================
; SECÇÃO 1: DISPLAY GLCD
; ============================================================

;Z CLS  --  inicializa terminal GLCD (cursor 0,0 + limpa)
; Uso: CLS

      dw COLD_link
      db 0
ZM_CLS_link:
      
      defm 3, "CLS"
ZM_CLS:
      
      
    push bc
    push de
    push hl
    call initTerminal
    pop hl
    pop de
    pop bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z CLG  --  limpa gráfico do LCD diretamente (sem PLOT)
; Uso: CLG

      dw ZM_CLS_link
      db 0
ZM_CLG_link:
      
      defm 3, "CLG"
ZM_CLG:
      
      
    push bc
    push de
    push hl
    call clearGrLCD
    pop hl
    pop de
    pop bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z PLOT  --  envia buffer gráfico para o LCD
; Necessário após PIXEL, LINE, BOX, CIRCLE etc.
; Uso: 64 32 20 CIRCLE PLOT

      dw ZM_CLG_link
      db 0
ZM_PLOT_link:
      
      defm 4, "PLOT"
ZM_PLOT:
      
      
    push bc
    push de
    push hl
    call plotToLCD
    pop hl
    pop de
    pop bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z AT  x y --  posiciona cursor em pixel x,y (0-127, 0-63)
; Uso: 0 0 AT        ( canto superior esquerdo )
;      63 32 AT      ( meio da tela )

      dw ZM_PLOT_link
      db 0
ZM_AT_link:
      
      defm 2, "AT"
ZM_AT:
      
      
    ; TOS=y(C), NOS=x
    ld   a, c        ; A = y (salva antes do exx)
    pop  hl          ; HL = x (consome NOS)
    ld   b, l        ; B = x
    ld   c, a        ; C = y → setCursor(B=x, C=y)
    push de
    push hl
    call setCursor
    pop  hl
    pop  de
    pop  bc          ; novo TOS
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z PIXEL  x y --  acende pixel (requer PLOT depois)
; Uso: 64 32 PIXEL PLOT

      dw ZM_AT_link
      db 0
ZM_PIXEL_link:
      
      defm 5, "PIXEL"
ZM_PIXEL:
      
      
    ; TOS=y(C), NOS=x
    ld   a, c        ; A = y
    pop  hl          ; HL = x
    ld   b, l        ; B = x
    ld   c, a        ; C = y → drawPixel(B=x, C=y)
    push de
    push hl
    call drawPixel
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z CPIXEL  x y --  apaga pixel (requer PLOT)
; Uso: 64 32 CPIXEL PLOT

      dw ZM_PIXEL_link
      db 0
ZM_CPIXEL_link:
      
      defm 6, "CPIXEL"
ZM_CPIXEL:
      
      
    ld   a, c
    pop  hl
    ld   b, l
    ld   c, a
    push de
    push hl
    call clearPixel
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z FPIXEL  x y --  inverte pixel (requer PLOT)
; Uso: 64 32 FPIXEL PLOT

      dw ZM_CPIXEL_link
      db 0
ZM_FPIXEL_link:
      
      defm 6, "FPIXEL"
ZM_FPIXEL:
      
      
    ld   a, c
    pop  hl
    ld   b, l
    ld   c, a
    push de
    push hl
    call flipPixel
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z LINE  x0 y0 x1 y1 --  desenha linha (requer PLOT)
; drawLine: B=X0 C=Y0 D=X1 E=Y1
; Uso: 0 0 127 63 LINE PLOT    ( diagonal )
;      0 32 127 32 LINE PLOT   ( horizontal )

      dw ZM_FPIXEL_link
      db 0
ZM_LINE_link:
      
      defm 4, "LINE"
ZM_LINE:
      
      
    ; TOS=y1(C), SP→[x1, y0, x0, prev_TOS]
    ld   a, c        ; A = y1  (salva ANTES do exx, A não é afetado)
    exx              ; DE'=IP salvo
    pop  hl          ; HL = x1 (L=x1)
    pop  de          ; DE = y0 (E=y0)
    pop  bc          ; BC = x0 (C=x0)
    ld   b, c        ; B = x0 ✓
    ld   c, e        ; C = y0 ✓
    ld   d, l        ; D = x1 ✓
    ld   e, a        ; E = y1 (de A, nunca tocou DE') ✓
    push hl
    call drawLine
    pop  hl
    exx              ; restaura DE=IP
    pop  bc          ; novo TOS
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z BOX  x0 y0 x1 y1 --  caixa vazia (requer PLOT)
; Uso: 10 10 117 53 BOX PLOT

      dw ZM_LINE_link
      db 0
ZM_BOX_link:
      
      defm 3, "BOX"
ZM_BOX:
      
      
    ld   a, c        ; A = y1
    exx              ; DE'=IP
    pop  hl          ; HL = x1
    pop  de          ; DE = y0
    pop  bc          ; BC = x0
    ld   b, c        ; B = x0 ✓
    ld   c, e        ; C = y0 ✓
    ld   d, l        ; D = x1 ✓
    ld   e, a        ; E = y1 ✓
    push hl
    call drawBox
    pop  hl
    exx
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z FBOX  x0 y0 x1 y1 --  caixa preenchida (requer PLOT)
; Uso: 0 0 127 63 FBOX PLOT    ( preenche tudo )

      dw ZM_BOX_link
      db 0
ZM_FBOX_link:
      
      defm 4, "FBOX"
ZM_FBOX:
      
      
    ld   a, c        ; A = y1
    exx              ; DE'=IP
    pop  hl          ; HL = x1
    pop  de          ; DE = y0
    pop  bc          ; BC = x0
    ld   b, c        ; B = x0 ✓
    ld   c, e        ; C = y0 ✓
    ld   d, l        ; D = x1 ✓
    ld   e, a        ; E = y1 ✓
    push hl
    call fillBox
    pop  hl
    exx
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z CIRCLE  x y r --  círculo (requer PLOT)
; drawCircle: B=X C=Y E=raio
; Uso: 64 32 20 CIRCLE PLOT

      dw ZM_FBOX_link
      db 0
ZM_CIRCLE_link:
      
      defm 6, "CIRCLE"
ZM_CIRCLE:
      
      
    ; TOS=r(C), SP→[y, x, prev_TOS]
    ld   a, c        ; A = r (salva antes do exx)
    exx              ; DE'=IP
    pop  hl          ; HL = y (L=y)
    pop  bc          ; BC = x (C=x)
    ld   b, c        ; B = x ✓
    ld   c, l        ; C = y ✓
    ld   e, a        ; E = r  ✓ (de A, sem tocar DE')
    push hl
    call drawCircle
    pop  hl
    exx              ; restaura DE=IP
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z FCIRCLE  x y r --  círculo preenchido (requer PLOT)
; Uso: 64 32 20 FCIRCLE PLOT

      dw ZM_CIRCLE_link
      db 0
ZM_FCIRCLE_link:
      
      defm 7, "FCIRCLE"
ZM_FCIRCLE:
      
      
    ld   a, c        ; A = r
    exx              ; DE'=IP
    pop  hl          ; HL = y
    pop  bc          ; BC = x
    ld   b, c        ; B = x ✓
    ld   c, l        ; C = y ✓
    ld   e, a        ; E = r  ✓
    push hl
    call fillCircle
    pop  hl
    exx
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z HEX.LCD  n --  imprime n em HEX no GLCD ("XXXX")
; Uso: $CAFE HEX.LCD
;      HERE HEX.LCD

      dw ZM_FCIRCLE_link
      db 0
ZM_HEXDOTLCD_link:
      
      defm 7, "HEX.LCD"
ZM_HEXDOTLCD:
      
      
    ld   h, b
    ld   l, c        ; HL = n
    push bc
    push de
    push hl
    call sendHLToLCD
    pop  hl
    pop  de
    pop  bc
    pop  bc          ; drop n
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; ============================================================
; SECÇÃO 2: SERIAL
; ============================================================

;Z SERIAL-A  --  terminal → Serial A
; Uso: SERIAL-A

      dw ZM_HEXDOTLCD_link
      db 0
ZM_SERIALA_link:
      
      defm 8, "SERIAL-A"
ZM_SERIALA:
      
      
    push bc
    push de
    push hl
    call setDefaultSerialA
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SERIAL-B  --  terminal → Serial B (ZiModem)
; Uso: SERIAL-B

      dw ZM_SERIALA_link
      db 0
ZM_SERIALB_link:
      
      defm 8, "SERIAL-B"
ZM_SERIALB:
      
      
    push bc
    push de
    push hl
    call setDefaultSerialB
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SEMIT  c --  envia char para serial setada
; Uso: 65 SEMIT    ( envia 'A' )
;      13 SEMIT    ( envia CR )

      dw ZM_SERIALB_link
      db 0
ZM_SEMIT_link:
      
      defm 5, "SEMIT"
ZM_SEMIT:
      
      
    ld   a, c
    push bc
    push de
    push hl
    push ix 
    call serialPrintA
    pop  ix
    pop  hl
    pop  de
    pop  bc
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SKEY  -- c  aguarda char da serial setada
; Uso: SKEY EMIT

      dw ZM_SEMIT_link
      db 0
ZM_SKEY_link:
      
      defm 4, "SKEY"
ZM_SKEY:
      
      
    push bc
    push de
    push hl
    push ix
    call serialInputA
    pop  ix
    pop  hl
    pop  de
    pop  bc
    push bc
    ld   c, a
    ld   b, 0
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z SHEX  n --  imprime byte n em HEX na serial ("XX")
; Uso: $FF SHEX     → "FF"
;      10  SHEX     → "0A"

      dw ZM_SKEY_link
      db 0
ZM_SHEX_link:
      
      defm 4, "SHEX"
ZM_SHEX:
      
      
    ld   a, c
    push bc
    push de
    push hl
    push ix
    call serialHexA
    pop  ix
    pop  hl
    pop  de
    pop  bc
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z S-CRLF  --  envia CR+LF pela serial
; Uso: S-CRLF

      dw ZM_SHEX_link
      db 0
ZM_SCRLF_link:
      
      defm 6, "S-CRLF"
ZM_SCRLF:
      
      
    push bc
    push de
    push hl
    push ix
    call serialCRLF
    pop  ix
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; ============================================================
; SECÇÃO 3: I2C / EEPROM 24C256
; ============================================================

;Z I2C-OPEN  addr --  abre dispositivo I2C
; addr bit0=0 → escrita,  bit0=1 → leitura
; Uso: $A0 I2C-OPEN    ( EEPROM para escrita )
;      $A1 I2C-OPEN    ( EEPROM para leitura )

      dw ZM_SCRLF_link
      db 0
ZM_I2COPEN_link:
      
      defm 8, "I2C-OPEN"
ZM_I2COPEN:
      
      
    ld   a, c
    push bc
    push de
    push hl
    call I2C_Open
    pop  hl
    pop  de
    pop  bc
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z I2C-CLOSE  --  fecha I2C
; Uso: I2C-CLOSE

      dw ZM_I2COPEN_link
      db 0
ZM_I2CCLOSE_link:
      
      defm 9, "I2C-CLOSE"
ZM_I2CCLOSE:
      
      
    push bc
    push de
    push hl
    call I2C_Close
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z I2C-C!  byte --  escreve byte no I2C
; Uso: $42 I2C-C!

      dw ZM_I2CCLOSE_link
      db 0
ZM_I2CBYTEW_link:
      
      defm 6, "I2C-C!"
ZM_I2CBYTEW:
      
      
    ld   a, c
    push bc
    push de
    push hl
    call I2C_Write
    pop  hl
    pop  de
    pop  bc
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z I2C-C@  -- byte  lê byte do I2C
; Uso: I2C-C@ .

      dw ZM_I2CBYTEW_link
      db 0
ZM_I2CBYTER_link:
      
      defm 6, "I2C-C@"
ZM_I2CBYTER:
      
      
    push bc
    push de
    push hl
    call I2C_Read    ; A=byte, Z=ok
    pop  hl
    pop  de
    pop  bc
    push bc
    ld   c, a
    ld   b, 0
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z EEPROM!  byte addr --  escreve byte na EEPROM 24C256
; Uso: $42 $0000 EEPROM!
;      65  $1234 EEPROM!

      dw ZM_I2CBYTER_link
      db 0
ZM_EEPROMSTORE_link:
      
      defm 7, "EEPROM!"
ZM_EEPROMSTORE:
      call docolon
      
    DW lit,$A0,ZM_I2COPEN          ; abre para escrita
    DW DUP                         ; addr addr
    DW lit,8,RSHIFT,lit,$FF,AND    ; high byte do endereço
    DW ZM_I2CBYTEW                 ; envia addr_hi
    DW lit,$FF,AND                 ; low byte do endereço
    DW ZM_I2CBYTEW                 ; envia addr_lo
    DW ZM_I2CBYTEW                 ; envia o dado
    DW ZM_I2CCLOSE
    DW lit,5,ZM_MS                 ; aguarda write cycle ~5ms
    DW EXIT

;Z EEPROM@  addr -- byte  lê byte da EEPROM 24C256
; Uso: $0000 EEPROM@ .      ( deve retornar o byte gravado )
;      $1234 EEPROM@ HEX.LCD PLOT

      dw ZM_EEPROMSTORE_link
      db 0
ZM_EEPROMFETCH_link:
      
      defm 7, "EEPROM@"
ZM_EEPROMFETCH:
      call docolon
      
    DW lit,$A0,ZM_I2COPEN          ; abre para escrita (endereçamento)
    DW DUP
    DW lit,8,RSHIFT,lit,$FF,AND
    DW ZM_I2CBYTEW                 ; envia addr_hi
    DW lit,$FF,AND
    DW ZM_I2CBYTEW                 ; envia addr_lo
    DW ZM_I2CCLOSE
    DW lit,$A1,ZM_I2COPEN          ; reabre para leitura
    DW ZM_I2CBYTER                 ; lê byte
    DW ZM_I2CCLOSE
    DW EXIT

;Z EEPROM-DUMP  addr u --  dump de u bytes em HEX pela serial
; Uso: $0000 16 EEPROM-DUMP
;      $0100 64 EEPROM-DUMP

      dw ZM_EEPROMFETCH_link
      db 0
ZM_EEPROMDUMP_link:
      
      defm 11, "EEPROM-DUMP"
ZM_EEPROMDUMP:
      call docolon
      
    DW lit,0,xdo             ; DO i=0..u-1 (addr permanece no stack)
zm_eedump_loop:
    DW OVER                  ; addr addr
    DW II,PLUS               ; addr (addr+i)
    DW ZM_EEPROMFETCH        ; addr byte
    DW ZM_SHEX               ; addr   (imprime "XX")
    DW lit,32,ZM_SEMIT       ; espaço
    DW xloop
    DW zm_eedump_loop
    DW DROP                  ; descarta addr
    DW ZM_SCRLF
    DW EXIT

; ============================================================
; SECÇÃO 4: TEMPORIZAÇÃO
; ============================================================

;Z MS  n --  delay de n milissegundos (via ROM, preciso)
; ROM delay: DE = milissegundos
; Uso: 500 MS     ( meio segundo )
;      1000 MS    ( 1 segundo )

      dw ZM_EEPROMDUMP_link
      db 0
ZM_MS_link:
      
      defm 2, "MS"
ZM_MS:
      
      
    ; BC=n(TOS), DE=IP
    ; Precisamos DE=n para a ROM, mas DE é o IP!
    ; Solução: exx salva IP em DE'
    exx              ; DE'=IP  BC'=n
    ld   d, b        ; DE = n  (para ROM delay)
    ld   e, c
    call delay
    exx              ; restaura DE=IP
    pop  bc          ; novo TOS (drop n)
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z 500MS  --  delay fixo de 500 milissegundos
; Uso: 500MS

      dw ZM_MS_link
      db 0
ZM_MS500_link:
      
      defm 5, "500MS"
ZM_MS500:
      
      
    push bc
    push de
    push hl
    call delay500ms
    pop  hl
    pop  de
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

; ============================================================
; SECÇÃO 5: CURSOR E DISPLAY
; ============================================================

;Z D-CURSOR  f --  controla cursor GLCD (0=on, !=0=off)
; Uso: 0 D-CURSOR    ( liga cursor )
;      1 D-CURSOR    ( desliga cursor )

      dw ZM_MS500_link
      db 0
ZM_DCURSOR_link:
      
      defm 8, "D-CURSOR"
ZM_DCURSOR:
      
      
    ld   a, c
    push bc
    push de
    push hl
    call displayCursor
    pop  hl
    pop  de
    pop  bc
    pop  bc
    
        ex de,hl
        
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ex de,hl
        jp (hl)
        

;Z BLINK  n --  pisca cursor n vezes (100ms on/off)
; Uso: 5 BLINK
;      10 BLINK

      dw ZM_DCURSOR_link
      db 0
ZM_BLINK_link:
      
      defm 5, "BLINK"
ZM_BLINK:
      call docolon
      
    DW lit,0,xdo
zm_blink_loop:
    DW lit,0,ZM_DCURSOR     ; cursor ON
    DW lit,100,ZM_MS
    DW lit,1,ZM_DCURSOR     ; cursor OFF
    DW lit,100,ZM_MS
    DW xloop
    DW zm_blink_loop
    DW EXIT

; ============================================================
; SECÇÃO 6: SISTEMA / DEBUG
; ============================================================

;Z FREE  -- n  bytes livres no dicionário
; Uso: FREE .

      dw ZM_BLINK_link
      db 0
ZM_FREE_link:
      
      defm 4, "FREE"
ZM_FREE:
      call docolon
      
    DW HERE
    DW SPFETCH
    DW SWOP
    DW MINUS
    DW EXIT

;Z DEMO  --  demo gráfico: bordas + diagonais + círculo
; Uso: DEMO

      dw ZM_FREE_link
      db 0
ZM_DEMO_link:
      
      defm 4, "DEMO"
ZM_DEMO:
      call docolon
      
    DW ZM_CLG
    DW lit,0,lit,0,lit,127,lit,63,ZM_BOX
    DW lit,0,lit,0,lit,127,lit,63,ZM_LINE
    DW lit,127,lit,0,lit,0,lit,63,ZM_LINE
    DW lit,64,lit,32,lit,20,ZM_CIRCLE
    DW ZM_PLOT
    DW EXIT

; ============================================================
; EXEMPLOS DE USO
; ============================================================
;
; --- Display gráfico ---
; DEMO                          \ demo completo
; CLG                           \ limpa gráfico
; 0 0 127 63 LINE PLOT          \ diagonal principal
; 0 63 127 0 LINE PLOT          \ diagonal inversa
; 10 10 117 53 BOX PLOT         \ caixa
; 0 0 127 63 FBOX PLOT          \ preenche tudo
; 64 32 30 CIRCLE PLOT          \ círculo
; 64 32 15 FCIRCLE PLOT         \ círculo preenchido
; 64 32 PIXEL PLOT              \ pixel no centro
; $BEEF HEX.LCD                 \ imprime "BEEF" no GLCD
;
; --- Posicionamento ---
; 0 0 AT                        \ cursor para pixel 0,0
; 65 EMIT                       \ imprime 'A' ali
;
; --- Serial ---
; SERIAL-B                      \ Forth via ZiModem
; SERIAL-A                      \ volta para teclado
; 65 SEMIT                      \ envia 'A' pela serial
; $FF SHEX                      \ imprime "FF" na serial
; S-CRLF                        \ CR+LF na serial
;
; --- EEPROM ---
; $42 $0000 EEPROM!             \ grava $42 no endereço 0
; $0000 EEPROM@ .               \ lê → 66
; $0000 16 EEPROM-DUMP          \ dump hex de 16 bytes
;
; --- Timing ---
; 1000 MS                       \ aguarda 1 segundo
; 500MS                         \ aguarda 500ms exatos
;
; --- Debug ---
; FREE .                        \ bytes livres
; 5 BLINK                       \ pisca cursor 5 vezes
;
; --- Exemplos Forth ---
; : SQUARE  DUP * ;
; 7 SQUARE .                    \ → 49
;
; : COUNTDOWN ( n -- )
;   0 DO  I .  1000 MS  LOOP ;
; 10 COUNTDOWN
;
; : SPIRAL ( -- )
;   CLG
;   0 DO
;     I 3 * 64 + 32 I 2 * CIRCLE
;   LOOP PLOT ;
; 15 CONSTANT RINGS  RINGS SPIRAL
	; Z80Mini

        defc lastword=ZM_DEMO_link       ; nfa of last word in dict.
        defc enddict=asmpc       ; user's code starts here

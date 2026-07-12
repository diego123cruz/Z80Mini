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
    head(ALIGN,ALIGN,docode)
noop:   next

;C ALIGNED  addr -- a-addr       align given addr
    head(ALIGNED,ALIGNED,docode)
        jr noop

;Z CELL     -- n                 size of one cell
    head(CELL,CELL,docon)
        dw 2

;C CELL+    a-addr1 -- a-addr2      add cell size
;   2 + ;
    head(CELLPLUS,CELL+,docode)
        inc bc
        inc bc
        next

;C CELLS    n1 -- n2            cells->adrs units
    head(CELLS,CELLS,docode)
        jp TWOSTAR

;C CHAR+    c-addr1 -- c-addr2   add char size
    head(CHARPLUS,CHAR+,docode)
        jp ONEPLUS

;C CHARS    n1 -- n2            chars->adrs units
    head(CHARS,CHARS,docode)
        jr noop

;C >BODY    xt -- a-addr      adrs of param field
;   3 + ;                     Z80 (3 byte CALL)
    head(TOBODY,>BODY,docolon)
        DW lit,3,PLUS,EXIT

;X COMPILE,  xt --         append execution token
; I called this word ,XT before I discovered that
; it is defined in the ANSI standard as COMPILE,.
; On a DTC Forth this simply appends xt (like , )
; but on an STC Forth this must append 'CALL xt'.
    head(COMMAXT,``COMPILE,'',docode)
        jp COMMA

;Z !CF    adrs cfa --   set code action of a word
;   0CD OVER C!         store 'CALL adrs' instr
;   1+ ! ;              Z80 VERSION
; Depending on the implementation this could
; append CALL adrs or JUMP adrs.
    head(STORECF,!CF,docolon)
        DW lit,0CDH,OVER,CSTORE
        DW ONEPLUS,STORE,EXIT

;Z ,CF    adrs --       append a code field
;   HERE !CF 3 ALLOT ;  Z80 VERSION (3 bytes)
    head(COMMACF,``,CF'',docolon)
        DW HERE,STORECF,lit,3,ALLOT,EXIT

;Z !COLON   --      change code field to docolon
;   -3 ALLOT docolon-adrs ,CF ;
; This should be used immediately after CREATE.
; This is made a distinct word, because on an STC
; Forth, colon definitions have no code field.
    head(STORCOLON,!COLON,docolon)
        DW lit,-3,ALLOT
        DW lit,docolon,COMMACF,EXIT

;Z ,EXIT    --      append hi-level EXIT action
;   ['] EXIT ,XT ;
; This is made a distinct word, because on an STC
; Forth, it appends a RET instruction, not an xt.
    head(CEXIT,``,EXIT'',docolon)
        DW lit,EXIT,COMMAXT,EXIT

; CONTROL STRUCTURES ============================
; These words allow Forth control structure words
; to be defined portably.

;Z ,BRANCH   xt --    append a branch instruction
; xt is the branch operator to use, e.g. qbranch
; or (loop).  It does NOT append the destination
; address.  On the Z80 this is equivalent to ,XT.
    head(COMMABRANCH,``,BRANCH'',docode)
        jp COMMA

;Z ,DEST   dest --        append a branch address
; This appends the given destination address to
; the branch instruction.  On the Z80 this is ','
; ...other CPUs may use relative addressing.
    head(COMMADEST,``,DEST'',docode)
        jp COMMA

;Z !DEST   dest adrs --    change a branch dest'n
; Changes the destination address found at 'adrs'
; to the given 'dest'.  On the Z80 this is '!'
; ...other CPUs may need relative addressing.
    head(STOREDEST,``!DEST'',docode)
        jp STORE

; HEADER STRUCTURE ==============================
; The structure of the Forth dictionary headers
; (name, link, immediate flag, and "smudge" bit)
; does not necessarily differ across CPUs.  This
; structure is not easily factored into distinct
; "portable" words; instead, it is implicit in
; the definitions of FIND and CREATE, and also in
; NFA>LFA, NFA>CFA, IMMED?, IMMEDIATE, HIDE, and
; REVEAL.  These words must be (substantially)
; rewritten if either the header structure or its
; inherent assumptions are changed.


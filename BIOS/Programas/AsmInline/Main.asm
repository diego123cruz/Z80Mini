;#include "../Z80MiniAPI.asm"


; -------- Constantes gerais --------
CR          EQU  0DH
LF          EQU  0AH
BkS          EQU  08H
DEL         EQU  7FH
ESC         EQU  1BH
SPACE       EQU  20H
NUL         EQU  00H


; ============================================================
; MINI-ASSEMBLER DE LINHA - Z80Mini
; ------------------------------------------------------------
; Digite mnemonicos Z80 linha a linha (estilo Apple 1 / KIM-1).
; Nao usa labels/forward refs: JR e DJNZ recebem o ENDERECO
; ALVO ($nnnn) e o proprio codigo calcula o deslocamento.
;
; Cobertura desta v1:
;   LD (todas as formas de 8/16 bits abaixo), ALU (ADD/ADC/SUB/
;   SBC/AND/XOR/OR/CP reg8 e imediato), INC/DEC r/rp, ADD HL,rp,
;   JP/JP cc/JP (HL), JR/JR cc, DJNZ, CALL/CALL cc, RET/RET cc,
;   PUSH/POP, IN A,(n) / OUT (n),A, EX DE,HL / EX AF,AF' / EXX,
;   HALT/NOP/DI/EI/DAA/CPL/SCF/CCF/RLCA/RRCA/RLA/RRA
;
; NAO implementado nesta v1 (fica facil de estender depois):
;   instrucoes prefixadas CB (bit/set/res/rot em geral),
;   ED (LD (nn),rp / LDIR / etc), e modos indexados IX/IY.
;
; IMPORTANTE: ajuste o bloco "I/O DO MONITOR" abaixo para
; apontar para as rotinas reais da sua jump table em $0100.
; Este arquivo NAO foi montado/testado num assembler real
; (ambiente sem zasm) - revise a montagem antes de gravar na EEPROM.
; ============================================================

        ORG     8000h

; ---- I/O DO MONITOR (AJUSTE AQUI) ----
CONIN	EQU		$0319
CRLF	EQU		$0447

; PUTCHAR: imprime o caractere em A
PUTCHAR EQU     $042B
; PUTSTR: imprime string terminada em 0 apontada por HL
PUTSTR  EQU     $0437

LINEMAX EQU     40              ; tamanho maximo de uma linha digitada

; ============================================================
; PONTO DE ENTRADA
; HL = endereco inicial de montagem (default $8000 se chamado direto)
; ============================================================
ASMSTART:
        LD      HL,9000h        ; endereco default; troque se quiser
                                 ; pedir o endereco ao usuario aqui
        LD      (CURADDR),HL
ASMLOOP:
        CALL    PRINTADDR       ; imprime "AAAA: " usando (CURADDR)

        LD      DE,LINEBUF
        LD      B,LINEMAX
        CALL    GETLINE         ; A = tamanho lido, LINEBUF = texto
        OR      A
        JR      Z,ASMDONE       ; linha vazia -> sai do assembler

        LD      C,A             ; C = tamanho da linha
        CALL    UPCASE_LINE     ; converte para maiusculas

        LD      HL,LINEBUF
        CALL    SKIPSPACES
        CALL    READMNEMONIC    ; DE=MNEBUF, A=tamanho do mnemonico
        OR      A
        JR      Z,ASMLOOP       ; linha so com espacos -> ignora (nao mexe em CURADDR)

        LD      (LINEPTR),HL    ; salva o resto da linha ANTES de FINDMNEMONIC
                                 ; reaproveitar HL para varrer a MNETAB
        CALL    FINDMNEMONIC    ; procura em MNETAB
        JR      C,ASMBADOP      ; nao achou -> erro

        ; HL aponta para a entrada da tabela; IX = ponteiro pro handler
        CALL    CALLHANDLER     ; handler consome o resto da linha,
                                 ; emite bytes em EMITBUF, retorna
                                 ; B = quantidade de bytes emitidos
                                 ; carry set = erro de sintaxe/operando
        JR      C,ASMBADOP

        ; grava os bytes emitidos a partir de CURADDR
        LD      HL,(CURADDR)
        LD      DE,EMITBUF
        LD      A,B
        OR      A
        JR      Z,ASMLOOP       ; 0 bytes emitidos (nao deveria ocorrer)
EMITCOPY:
        LD      A,(DE)
        LD      (HL),A
        INC     HL
        INC     DE
        DJNZ    EMITCOPY
        LD      (CURADDR),HL    ; atualiza o endereco corrente (unico lugar que avanca)
        JR      ASMLOOP

ASMBADOP:
        LD      HL,MSGERR
        CALL    PUTSTR
        JR      ASMLOOP         ; nao mexe em CURADDR

ASMDONE:
        RET
        
        
        
        
        
        


; GETLINE: le uma linha ate CR em (DE), tamanho max B, retorna
;          tamanho lido em A. Deve ecoar os caracteres digitados
;          e tratar backspace. Troque pelo endereco real da sua
;          rotina de leitura de linha na jump table.

; --- GETLINE: Lê linha para LINEBUF; eco local ---
;     Termina em CR. Suporta BS/DEL para apagar.
GETLINE:
            LD   HL, DE
            LD 	 D, 0
GETLINE_LOOP:
            CALL CONIN
            CP   CR
            JR   Z, GETLINE_DONE
            CP   $F8    ; ignora scroll up - GLCD
            JR   Z, GETLINE_LOOP
            CP   $F7    ; ignora scroll down - GLCD
            JR   Z, GETLINE_LOOP
            CP   LF
            JR   Z, GETLINE_LOOP    ; Ignora LF
            CP   ESC
            JR   Z, GETLINE_LOOP    ; Ignora
            CP   $FF ;capslock Ignora
            JP   Z, GETLINE_LOOP
            CP   BkS
            JR   Z, GETLINE_BS
            CP   DEL
            JR   Z, GETLINE_BS
            CP   $FA ; AltGr
            JP   Z, GETLINE_LOOP
            CP   $F9 ; LUZ
            JP   Z, GETLINE_LOOP
            LD   C, A
            LD   A, B
            CP   0
            JR   Z, GETLINE_LOOP    ; Buffer cheio
            LD   A, C
            LD   (HL), A
            INC  HL
            DEC  B
            INC  D
            CALL PUTCHAR             ; Eco
            JR   GETLINE_LOOP
GETLINE_BS:
            LD   A, B
            CP   79
            JR   Z, GETLINE_LOOP    ; Início: ignora BS
            DEC  HL
            INC  B
            DEC  D
            LD   A, BkS
            CALL PUTCHAR
            LD   A, SPACE
            CALL PUTCHAR
            LD   A, BkS
            CALL PUTCHAR
            JR   GETLINE_LOOP
GETLINE_DONE:
            LD   (HL), NUL           ; Termina string
            CALL CRLF
            LD A, D
            RET   
        
        
        
        
        
        
        
        
        

; ------------------------------------------------------------
PRINTADDR:
        LD      HL,(CURADDR)
        CALL    PRINTHEX16
        LD      A,':'
        CALL    PUTCHAR
        LD      A,' '
        CALL    PUTCHAR
        RET

; Imprime HL em hex, 4 digitos maiusculos
PRINTHEX16:
        LD      A,H
        CALL    PRINTHEX8
        LD      A,L
        CALL    PRINTHEX8
        RET
PRINTHEX8:
        PUSH    AF
        RRA
        RRA
        RRA
        RRA
        CALL    PRINTNIBBLE
        POP     AF
PRINTNIBBLE:
        AND     0Fh
        CP      0Ah
        JR      C,PN_DIGIT
        ADD     A,'A'-'9'-1
PN_DIGIT:
        ADD     A,'0'
        CALL    PUTCHAR
        RET

; ------------------------------------------------------------
; Converte LINEBUF (C bytes) para maiusculas
UPCASE_LINE:
        LD      HL,LINEBUF
        LD      B,C
        LD      A,B
        OR      A
        RET     Z
UPC1:
        LD      A,(HL)
        CP      'a'
        JR      C,UPC2
        CP      'z'+1
        JR      NC,UPC2
        SUB     20h
        LD      (HL),A
UPC2:
        INC     HL
        DJNZ    UPC1
        RET

; Pula espacos a partir de (HL)
SKIPSPACES:
        LD      A,(HL)
        CP      ' '
        RET     NZ
        INC     HL
        JR      SKIPSPACES

; Le o MNEMONICO a partir de (HL): igual READTOKEN mas tambem para
; em '(' (sem consumir), para aceitar "OUT(10),A" sem espaco antes
; do parenteses. Operandos continuam usando READTOKEN normal.
; Nao usa B/C (varios chamadores guardam estado em B entre uma
; chamada e outra - ex.: porta em OUT, condicao em JP/JR/CALL cc).
READMNEMONIC:
        LD      DE,MNEBUF
        XOR     A
        LD      (TOKLEN),A      ; contador em memoria, nao em B
RM1:
        LD      A,(HL)
        OR      A
        JR      Z,RM_END
        CP      13
        JR      Z,RM_END
        CP      ' '
        JR      Z,RM_END
        CP      ','
        JR      Z,RM_END
        CP      '('
        JR      Z,RM_END
        LD      (DE),A
        INC     DE
        INC     HL
        LD      A,(TOKLEN)
        INC     A
        LD      (TOKLEN),A
        CP      8
        JR      C,RM1
RM_END:
        XOR     A
        LD      (DE),A
        LD      A,(TOKLEN)
        RET

; Le um token (letras/digitos/$/(/)/+/-) a partir de (HL) ate achar
; espaco, virgula ou CR/0. Copia para MNEBUF (max 8 chars), poe 0
; no final. Retorna A = tamanho, HL aponta pro delimitador.
; Nao usa B/C (mesmo motivo do READMNEMONIC acima).
READTOKEN:
        LD      DE,MNEBUF
        XOR     A
        LD      (TOKLEN),A      ; contador em memoria, nao em B
RT1:
        LD      A,(HL)
        OR      A
        JR      Z,RT_END
        CP      13
        JR      Z,RT_END
        CP      ' '
        JR      Z,RT_END
        CP      ','
        JR      Z,RT_END
        LD      (DE),A
        INC     DE
        INC     HL
        LD      A,(TOKLEN)
        INC     A
        LD      (TOKLEN),A
        CP      8
        JR      C,RT1
RT_END:
        XOR     A
        LD      (DE),A
        LD      A,(TOKLEN)
        RET

; ------------------------------------------------------------
; Procura MNEBUF em MNETAB. Cada entrada: 4 bytes de nome
; (preenchido com 0), 2 bytes ponteiro pro handler, 1 byte
; parametro (ex: numero da operacao ALU / opcode fixo).
; Retorna: HL = ponteiro pra entrada (nome), carry=1 se nao achou.
FINDMNEMONIC:
        LD      HL,MNETAB
FM1:
        LD      A,(HL)
        OR      A
        JR      Z,FM_NOTFOUND   ; entrada com nome vazio = fim da tabela
        PUSH    HL
        LD      DE,MNEBUF
        LD      B,4
FM2:
        LD      A,(DE)
        CP      (HL)
        JR      NZ,FM_NEXT
        OR      A
        JR      Z,FM_MATCHCHK   ; bateu 0 nos dois -> confere resto
        INC     HL
        INC     DE
        DJNZ    FM2
        JR      FM_MATCH        ; 4 chars bateram e nao houve 0 -> ok
FM_MATCHCHK:
        JR      FM_MATCH
FM_NEXT:
        POP     HL
        LD      DE,7            ; 4 (nome) + 2 (ptr) + 1 (param)
        ADD     HL,DE
        JR      FM1
FM_MATCH:
        POP     HL
        OR      A               ; carry = 0
        RET
FM_NOTFOUND:
        SCF
        RET

; Chama o handler da entrada apontada por HL (nome de 4 bytes,
; +4 = ponteiro do handler, +6 = byte de parametro).
; O resto da linha (apos o mnemonico) e recuperado de LINEPTR,
; que o ASMLOOP grava logo depois do READTOKEN do mnemonico
; (antes de HL ser reaproveitado por FINDMNEMONIC).
CALLHANDLER:
        PUSH    HL
        LD      DE,4
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ; DE = endereco do handler
        INC     HL
        LD      C,(HL)          ; C = byte de parametro (ex: op ALU)
        POP     HL              ; (descarta o ponteiro da tabela)
        LD      HL,(LINEPTR)    ; HL = resto da linha, apos o mnemonico
        PUSH    DE              ; empilha o ENDERECO DO HANDLER
        RET                     ; "salta" pro handler; o RET dele volta
                                 ; pro chamador original de CALLHANDLER,
                                 ; pois o proprio endereco de retorno da
                                 ; CALL CALLHANDLER continua embaixo na pilha

; ============================================================
; HANDLERS
; Convencao: entrada HL = ponto da linha logo apos o mnemonico
; (ainda pode ter espacos antes do operando). C = parametro da
; tabela. Saida: B = bytes emitidos em EMITBUF, carry=1 se erro.
; Todos preservam a pilha (fazem RET normal).
; ============================================================

; ---- instrucoes sem operando, opcode fixo em C ----
H_SIMPLE:
        LD      A,C
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET

; ---- HALT precisa ser tratado como H_SIMPLE tambem (opcode 76h) ----

; ---- ALU: <MNE> A,r | <MNE> A,n | <MNE> r | <MNE> n ----
; C = numero da operacao ALU (0=ADD 1=ADC 2=SUB 3=SBC 4=AND 5=XOR 6=OR 7=CP)
H_ALU:
        CALL    SKIPSPACES
        CALL    READTOKEN       ; DE/MNEBUF = primeiro operando
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,ALU_NOTA     ; nao comecou com "A," -> e o unico operando
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,ALU_NOTA     ; token era "A" mesmo (nao "AB" etc)
        ; consumiu "A,"; le o operando real
        CALL    SKIPSPACES
        CALL    READTOKEN
ALU_NOTA:
        CALL    CLASSIFY_R_OR_N
        JR      C,ALU_ERR
        JR      Z,ALU_ISREG
        ; imediato: opcode = C6 + (op<<3), byte = A
        LD      B,A             ; guarda imediato
        LD      A,C
        RLCA
        RLCA
        RLCA
        ADD     A,0C6h
        LD      (EMITBUF),A
        LD      A,B
        LD      (EMITBUF+1),A
        LD      B,2
        OR      A
        RET
ALU_ISREG:
        ; registrador em A (codigo 0-7)
        LD      B,A
        LD      A,C
        RLCA
        RLCA
        RLCA
        ADD     A,80h
        ADD     A,B
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
ALU_ERR:
        SCF
        RET

; ---- LD (a mais complexa) ----
; Trata: LD r,r | LD r,n | LD rp,nn | LD (HL),n | LD A,(BC/DE/nn)
;        LD (BC/DE/nn),A | LD HL,(nn) | LD (nn),HL | LD SP,HL
H_LD:
        CALL    SKIPSPACES
        CALL    READTOKEN       ; primeiro operando -> MNEBUF; HL fica no delimitador
        CALL    CLASSIFY_DEST   ; classifica destino: retorna tipo em A (preserva HL)
                                 ; 0=reg8 1=reg16 2=(HL)ja incluso em reg8
                                 ; 3=(BC) 4=(DE) 5=(nn)
        ; guarda tipo/valor do destino
        LD      (LD_DSTTYPE),A
        LD      (LD_DSTVAL),BC  ; BC = valor (reg code) ou endereco, conforme tipo

        ; pula a virgula
        CALL    SKIPTOCOMMA
        JP      C,LD_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN       ; segundo operando

        LD      A,(LD_DSTTYPE)
        CP      0
        JP      Z,LD_DST_REG8
        CP      1
        JP      Z,LD_DST_REG16
        CP      3
        JP      Z,LD_DST_INDBC
        CP      4
        JP      Z,LD_DST_INDDE
        CP      5
        JP      Z,LD_DST_INDNN
        JP      LD_ERR

LD_DST_REG8:
        ; segundo operando: reg8, (HL) ja coberto por CLASSIFY_R_OR_N, ou imediato
        ; NAO guardamos o destino em D antes desta chamada: CLASSIFY_R_OR_N
        ; pode cair em PARSEDEC16FROM/PARSEHEX16FROM, que usam DE inteiro
        ; como acumulador e destruiriam D. Relemos LD_DSTVAL da memoria
        ; sempre que precisamos do destino, depois da chamada.
        CALL    CLASSIFY_R_OR_N
        JP      C,LD_ERR
        JP      Z,LD_REG8_REG
        ; imediato: 06 + (dst<<3), n   -- cobre tambem LD (HL),n
        LD      B,A             ; guarda o imediato
        LD      A,(LD_DSTVAL)   ; A = codigo do destino (relido)
        RLCA
        RLCA
        RLCA
        ADD     A,06h
        LD      (EMITBUF),A
        LD      A,B
        LD      (EMITBUF+1),A
        LD      B,2
        OR      A
        RET
LD_REG8_REG:
        ; A = codigo do reg fonte (0-7)
        ; rejeita (HL),(HL) = 76h (isso e HALT)
        LD      B,A             ; B = fonte (guardado antes de reler o destino)
        CP      6
        JR      NZ,LD_R8R8_OK
        LD      A,(LD_DSTVAL)
        CP      6
        JP      Z,LD_ERR
LD_R8R8_OK:
        LD      A,(LD_DSTVAL)   ; A = destino (relido)
        RLCA
        RLCA
        RLCA
        ADD     A,40h
        ADD     A,B
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET

LD_DST_REG16:
        ; destino e BC/DE/HL/SP. Se for "SP,HL" -> F9. Senao espera imediato de 16 bits.
        LD      A,(LD_DSTVAL)   ; codigo do par (0=BC 1=DE 2=HL 3=SP)
        CP      3
        JR      NZ,LD_R16_IMM
        ; destino SP: unico operando valido aqui e "HL"
        LD      A,(MNEBUF)
        CP      'H'
        JP      NZ,LD_ERR
        LD      A,(MNEBUF+1)
        CP      'L'
        JP      NZ,LD_ERR
        LD      A,(MNEBUF+2)
        OR      A
        JP      NZ,LD_ERR
        LD      A,0F9h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
LD_R16_IMM:
        CALL    CLASSIFY_IMM16  ; exige token comecando com $ ou digito
        JR      C,LD_ERR
        LD      A,(LD_DSTVAL)
        RLCA
        RLCA
        RLCA
        RLCA
        ADD     A,01h
        LD      (EMITBUF),A
        LD      (EMITBUF+1),HL  ; HL = valor imediato (lo,hi ja na ordem certa)
        LD      B,3
        OR      A
        RET

LD_DST_INDBC:
        ; (BC),A
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,LD_ERR
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,LD_ERR
        LD      A,02h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET

LD_DST_INDDE:
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,LD_ERR
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,LD_ERR
        LD      A,12h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET

LD_DST_INDNN:
        ; (nn),A  ou  (nn),HL
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,LD_INDNN_HL
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,LD_INDNN_HL
        LD      A,32h
        LD      (EMITBUF),A
        LD      HL,(LD_DSTVAL)
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET
LD_INDNN_HL:
        LD      A,(MNEBUF)
        CP      'H'
        JR      NZ,LD_ERR
        LD      A,(MNEBUF+1)
        CP      'L'
        JR      NZ,LD_ERR
        LD      A,(MNEBUF+2)
        OR      A
        JR      NZ,LD_ERR
        LD      A,22h
        LD      (EMITBUF),A
        LD      HL,(LD_DSTVAL)
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET

LD_ERR:
        SCF
        RET

; ---- INC/DEC r | INC/DEC rp ----  (C: bit0 = 0 INC / 1 DEC)
H_INCDEC:
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_R_OR_N
        JR      C,INCDEC_TRY16
        JR      NZ,INCDEC_TRY16 ; Z=1 quer dizer "era registrador" (ver CLASSIFY_R_OR_N)
        ; reg8, codigo em A
        LD      B,A
        BIT     0,C
        JR      NZ,INCDEC_D8
        LD      A,B
        RLCA
        RLCA
        RLCA
        ADD     A,04h
        JR      INCDEC_EMIT1
INCDEC_D8:
        LD      A,B
        RLCA
        RLCA
        RLCA
        ADD     A,05h
INCDEC_EMIT1:
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
INCDEC_TRY16:
        CALL    CLASSIFY_REG16
        JR      C,INCDEC_ERR
        BIT     0,C
        JR      NZ,INCDEC_D16
        RLCA
        RLCA
        RLCA
        RLCA
        ADD     A,03h
        JR      INCDEC_EMIT1B
INCDEC_D16:
        RLCA
        RLCA
        RLCA
        RLCA
        ADD     A,0Bh
INCDEC_EMIT1B:
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
INCDEC_ERR:
        SCF
        RET

; ---- ADD HL,rp ----
H_ADDHL:
        CALL    SKIPSPACES
        CALL    READTOKEN       ; espera "HL"
        LD      A,(MNEBUF)
        CP      'H'
        JR      NZ,ADDHL_ERR
        LD      A,(MNEBUF+1)
        CP      'L'
        JR      NZ,ADDHL_ERR
        CALL    SKIPTOCOMMA
        JR      C,ADDHL_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_REG16
        JR      C,ADDHL_ERR
        RLCA
        RLCA
        RLCA
        RLCA
        ADD     A,09h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
ADDHL_ERR:
        SCF
        RET

; ---- PUSH/POP rp2 ----  (C: bit0 = 0 PUSH / 1 POP)
H_PUSHPOP:
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_REG16AF ; BC/DE/HL/AF -> A=codigo 0-3
        JR      C,PP_ERR
        RLCA
        RLCA
        RLCA
        RLCA
        BIT     0,C
        JR      NZ,PP_POP
        ADD     A,0C5h
        JR      PP_EMIT
PP_POP:
        ADD     A,0C1h
PP_EMIT:
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
PP_ERR:
        SCF
        RET

; ---- JP nn | JP cc,nn | JP (HL) ----
H_JP:
        CALL    SKIPSPACES
        CALL    READTOKEN
        LD      A,(MNEBUF)
        CP      '('
        JR      NZ,JP_NOTIND
        LD      A,(MNEBUF+1)
        CP      'H'
        JR      NZ,JP_ERR
        LD      A,(MNEBUF+2)
        CP      'L'
        JR      NZ,JP_ERR
        LD      A,0E9h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
JP_NOTIND:
        CALL    CLASSIFY_COND3  ; tenta como condicao (NZ/Z/NC/C/PO/PE/P/M)
        JR      C,JP_UNCOND
        ; era condicao; A = codigo 0-7; consome virgula e le endereco
        LD      B,A
        CALL    SKIPTOCOMMA
        JR      C,JP_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_IMM16
        JR      C,JP_ERR
        LD      A,B
        RLCA
        RLCA
        RLCA
        ADD     A,0C2h
        LD      (EMITBUF),A
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET
JP_UNCOND:
        CALL    CLASSIFY_IMM16  ; token ja lido esta em MNEBUF (via HL apontado? reclassifica)
        JR      C,JP_ERR
        LD      A,0C3h
        LD      (EMITBUF),A
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET
JP_ERR:
        SCF
        RET

; ---- JR e | JR cc,e ----  (e = endereco alvo; calcula deslocamento)
; ---- DJNZ e ----  (mesmo calculo, sem condicao)
; C = 0 -> JR simples/cc ; C = 1 -> DJNZ
H_JR:
        CALL    SKIPSPACES
        CALL    READTOKEN
        BIT     0,C
        JR      NZ,JR_DJNZ
        CALL    CLASSIFY_COND2 ; NZ/Z/NC/C -> A=0-3 ; carry=erro
        JR      C,JR_UNCOND
        LD      B,A
        CALL    SKIPTOCOMMA
        JR      C,JR_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_IMM16
        JR      C,JR_ERR
        CALL    JR_CALCOFFSET   ; HL(alvo) -> A=offset, carry=fora de alcance
        JR      C,JR_ERR
        LD      C,A
        LD      A,B
        RLCA
        RLCA
        RLCA
        ADD     A,20h
        LD      (EMITBUF),A
        LD      A,C
        LD      (EMITBUF+1),A
        LD      B,2
        OR      A
        RET
JR_UNCOND:
        CALL    CLASSIFY_IMM16
        JR      C,JR_ERR
        CALL    JR_CALCOFFSET
        JR      C,JR_ERR
        LD      (EMITBUF+1),A
        LD      A,18h
        LD      (EMITBUF),A
        LD      B,2
        OR      A
        RET
JR_DJNZ:
        CALL    CLASSIFY_IMM16
        JR      C,JR_ERR
        CALL    JR_CALCOFFSET
        JR      C,JR_ERR
        LD      (EMITBUF+1),A
        LD      A,10h
        LD      (EMITBUF),A
        LD      B,2
        OR      A
        RET
JR_ERR:
        SCF
        RET

; entra com HL = endereco alvo (imediato), calcula deslocamento
; relativo a (CURADDR)+2. Retorna A=offset (signed), carry=1 se
; fora do intervalo -128..127
JR_CALCOFFSET:
        PUSH    HL
        LD      DE,(CURADDR)
        INC     DE
        INC     DE
        POP     HL
        OR      A
        SBC     HL,DE           ; HL = alvo - (PC+2)
        LD      A,H
        ; precisa ser 00 (positivo pequeno) ou FF (negativo pequeno)
        CP      0
        JR      Z,JRC_OK
        CP      0FFh
        JR      Z,JRC_OK
        SCF
        RET
JRC_OK:
        LD      A,L
        OR      A
        RET

; ---- CALL nn | CALL cc,nn ----
H_CALL:
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_COND3
        JR      C,CALL_UNCOND
        LD      B,A
        CALL    SKIPTOCOMMA
        JR      C,CALL_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN
        CALL    CLASSIFY_IMM16
        JR      C,CALL_ERR
        LD      A,B
        RLCA
        RLCA
        RLCA
        ADD     A,0C4h
        LD      (EMITBUF),A
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET
CALL_UNCOND:
        CALL    CLASSIFY_IMM16
        JR      C,CALL_ERR
        LD      A,0CDh
        LD      (EMITBUF),A
        LD      (EMITBUF+1),HL
        LD      B,3
        OR      A
        RET
CALL_ERR:
        SCF
        RET

; ---- RET | RET cc ----
H_RET:
        CALL    SKIPSPACES
        CALL    READTOKEN
        LD      A,(MNEBUF)
        OR      A
        JR      Z,RET_PLAIN     ; linha sem operando -> RET simples
        CALL    CLASSIFY_COND3
        JR      C,RET_ERR
        RLCA
        RLCA
        RLCA
        ADD     A,0C0h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
RET_PLAIN:
        LD      A,0C9h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
RET_ERR:
        SCF
        RET

; ---- IN A,(n) ----
H_IN:
        CALL    SKIPSPACES
        CALL    READTOKEN       ; "A"
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,IN_ERR
        CALL    SKIPTOCOMMA
        JR      C,IN_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN       ; "(n)"
        CALL    CLASSIFY_INDN   ; espera "(" imm8 ")"
        JR      C,IN_ERR
        LD      (EMITBUF+1),A
        LD      A,0DBh
        LD      (EMITBUF),A
        LD      B,2
        OR      A
        RET
IN_ERR:
        SCF
        RET

; ---- OUT (n),A ----
H_OUT:
        CALL    SKIPSPACES
        CALL    READTOKEN       ; "(n)"
        CALL    CLASSIFY_INDN
        JR      C,OUT_ERR
        LD      B,A             ; guarda n
        CALL    SKIPTOCOMMA
        JR      C,OUT_ERR
        CALL    SKIPSPACES
        CALL    READTOKEN       ; "A"
        LD      A,(MNEBUF)
        CP      'A'
        JR      NZ,OUT_ERR
        LD      A,0D3h
        LD      (EMITBUF),A
        LD      A,B
        LD      (EMITBUF+1),A
        LD      B,2
        OR      A
        RET
OUT_ERR:
        SCF
        RET

; ---- EX DE,HL | EX AF,AF' | EXX (EXX cai em H_SIMPLE) ----
H_EX:
        CALL    SKIPSPACES
        CALL    READTOKEN
        LD      A,(MNEBUF)
        CP      'D'
        JR      NZ,EX_TRYAF
        LD      A,0EBh
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
EX_TRYAF:
        CP      'A'
        JR      NZ,EX_ERR
        LD      A,08h
        LD      (EMITBUF),A
        LD      B,1
        OR      A
        RET
EX_ERR:
        SCF
        RET

; ============================================================
; CLASSIFICADORES DE OPERANDO
; Todos assumem que o token a classificar ja esta em MNEBUF
; (preenchido pela ultima chamada a READTOKEN), exceto quando
; dito o contrario.
; ============================================================

; Registrador de 8 bits ou (HL) -> A = codigo 0-7, Z=1
; Numero/$hex -> A = valor de 8 bits, Z=0
; Erro (nao reconhecido) -> carry=1
CLASSIFY_R_OR_N:
        LD      A,(MNEBUF)
        OR      A
        JR      Z,CRN_ERR
        CP      '('
        JR      Z,CRN_INDHL
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,CRN_NUM      ; mais de 1 char -> numero
        ; um unico caractere: pode ser registrador
        LD      A,(MNEBUF)
        CALL    REGCHAR2CODE    ; A = codigo do registrador (0-7)
        JR      C,CRN_NUM
        CP      A               ; Z=1, sem alterar o valor de A
        RET
CRN_INDHL:
        LD      A,(MNEBUF+1)
        CP      'H'
        JR      NZ,CRN_ERR
        LD      A,(MNEBUF+2)
        CP      'L'
        JR      NZ,CRN_ERR
        LD      A,(MNEBUF+3)
        CP      ')'
        JR      NZ,CRN_ERR
        LD      A,6             ; codigo de (HL) no campo reg8
        CP      A               ; Z=1, sem alterar A
        RET
CRN_NUM:
        CALL    PARSENUM8       ; MNEBUF -> A = valor, carry=1 se erro
        RET     C               ; erro: sai com carry=1
        LD      B,A             ; guarda o valor (mesmo se for 0)
        XOR     A               ; A=0, carry=0, Z=1
        INC     A               ; A=1, Z=0 (INC nao mexe no carry) -> Z=0,carry=0 garantidos
        LD      A,B             ; restaura o valor em A; LD nao afeta flags
        RET                     ; sai com A=valor, Z=0, carry=0 (mesmo se valor=0)
CRN_ERR:
        SCF
        RET

; Converte caractere de registrador simples em codigo 0-7.
; B=000 C=001 D=010 E=011 H=100 L=101 A=111 ; erro -> carry=1
REGCHAR2CODE:
        CP      'B'
        JR      NZ,RC1
        LD      A,0
        RET
RC1:    CP      'C'
        JR      NZ,RC2
        LD      A,1
        RET
RC2:    CP      'D'
        JR      NZ,RC3
        LD      A,2
        RET
RC3:    CP      'E'
        JR      NZ,RC4
        LD      A,3
        RET
RC4:    CP      'H'
        JR      NZ,RC5
        LD      A,4
        RET
RC5:    CP      'L'
        JR      NZ,RC6
        LD      A,5
        RET
RC6:    CP      'A'
        JR      NZ,RC_ERR
        LD      A,7
        RET
RC_ERR:
        SCF
        RET

; Classifica MNEBUF como par de 16 bits: BC/DE/HL/SP -> A=0-3
CLASSIFY_REG16:
        LD      A,(MNEBUF)
        CP      'B'
        JR      NZ,C16_DE
        LD      A,0
        RET
C16_DE:
        CP      'D'
        JR      NZ,C16_HL
        LD      A,1
        RET
C16_HL:
        CP      'H'
        JR      NZ,C16_SP
        LD      A,2
        RET
C16_SP:
        CP      'S'
        JR      NZ,C16_ERR
        LD      A,3
        RET
C16_ERR:
        SCF
        RET

; Classifica MNEBUF como BC/DE/HL/AF (para PUSH/POP) -> A=0-3
CLASSIFY_REG16AF:
        LD      A,(MNEBUF)
        CP      'B'
        JR      NZ,C16A_DE
        LD      A,0
        RET
C16A_DE:
        CP      'D'
        JR      NZ,C16A_HL
        LD      A,1
        RET
C16A_HL:
        CP      'H'
        JR      NZ,C16A_AF
        LD      A,2
        RET
C16A_AF:
        CP      'A'
        JR      NZ,C16A_ERR
        LD      A,3
        RET
C16A_ERR:
        SCF
        RET

; Classifica MNEBUF (2 letras) como condicao de 3 bits (JP/CALL/RET)
; NZ=0 Z=1 NC=2 C=3 PO=4 PE=5 P=6 M=7
CLASSIFY_COND3:
        LD      A,(MNEBUF)
        CP      'N'
        JR      Z,CC3_N
        CP      'Z'
        JR      Z,CC3_Z
        CP      'C'
        JR      Z,CC3_C
        CP      'P'
        JR      Z,CC3_P
        CP      'M'
        JR      Z,CC3_M
        JR      CC3_ERR
CC3_N:
        LD      A,(MNEBUF+1)
        CP      'Z'
        JR      Z,CC3_RET0
        CP      'C'
        JR      Z,CC3_RET2
        JR      CC3_ERR
CC3_Z:
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,CC3_ERR
        LD      A,1
        RET
CC3_C:
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,CC3_ERR
        LD      A,3
        RET
CC3_P:
        LD      A,(MNEBUF+1)
        CP      'O'
        JR      Z,CC3_RET4
        CP      'E'
        JR      Z,CC3_RET5
        OR      A
        JR      Z,CC3_RET6
        JR      CC3_ERR
CC3_M:
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,CC3_ERR
        LD      A,7
        RET
CC3_RET0:
        LD      A,0
        RET
CC3_RET2:
        LD      A,2
        RET
CC3_RET4:
        LD      A,4
        RET
CC3_RET5:
        LD      A,5
        RET
CC3_RET6:
        LD      A,6
        RET
CC3_ERR:
        SCF
        RET

; Classifica MNEBUF como condicao de 2 bits (so para JR): NZ/Z/NC/C
CLASSIFY_COND2:
        CALL    CLASSIFY_COND3
        RET     C
        CP      4
        JR      NC,C2_ERR       ; PO/PE/P/M nao valem em JR
        RET
C2_ERR:
        SCF
        RET

; Le MNEBUF como imediato de 16 bits ($nnnn ou decimal) -> HL=valor
CLASSIFY_IMM16:
        LD      HL,MNEBUF
        LD      A,(HL)
        CP      '$'
        JR      Z,I16_HEX
        CALL    PARSEDEC16
        RET
I16_HEX:
        INC     HL
        CALL    PARSEHEX16
        RET

; Le MNEBUF como imediato de 8 bits ($nn ou decimal) -> A=valor
PARSENUM8:
        LD      HL,MNEBUF
        LD      A,(HL)
        CP      '$'
        JR      Z,PN8_HEX
        CALL    PARSEDEC16
        LD      A,L
        RET
PN8_HEX:
        INC     HL
        CALL    PARSEHEX16
        LD      A,L
        RET

; Classifica MNEBUF no formato "(n)" ou "($nn)" -> A = valor 8 bits
; Preserva o HL do chamador (nao e usado como saida aqui, so A).
CLASSIFY_INDN:
        LD      A,(MNEBUF)
        CP      '('
        JR      NZ,CIN_ERR
        PUSH    HL              ; salva o ponteiro real da linha
        LD      A,(MNEBUF+1)
        CP      '$'
        JR      NZ,CIN_DEC2
        LD      HL,MNEBUF+2
        CALL    PARSEHEX16FROM  ; HL=valor, carry=erro (nao mexe em BC/DE globais)
        JR      CIN_DONE
CIN_DEC2:
        LD      HL,MNEBUF+1
        CALL    PARSEDEC16FROM
CIN_DONE:
        LD      A,L             ; A = valor (LD nao mexe em carry)
        POP     HL              ; restaura o ponteiro real da linha (POP nao mexe em carry)
        RET
CIN_ERR:
        SCF
        RET

; Classifica destino de LD: retorna A=tipo, BC=valor
;  0 = reg8 (BC=codigo 0-7)      3 = (BC)
;  1 = reg16 (BC=codigo 0-3)     4 = (DE)
;                                 5 = (nn) (BC=endereco)
CLASSIFY_DEST:
        LD      A,(MNEBUF+1)
        OR      A
        JR      NZ,CD_MULTI
        LD      A,(MNEBUF)
        CALL    REGCHAR2CODE
        JR      C,CD_ERR
        LD      C,A
        LD      B,0
        XOR     A               ; tipo 0
        RET
CD_MULTI:
        LD      A,(MNEBUF)
        CP      '('
        JR      Z,CD_IND
        ; BC/DE/HL/SP como par de 16 bits
        CALL    CLASSIFY_REG16
        JR      C,CD_ERR
        LD      C,A
        LD      B,0
        LD      A,1
        RET
CD_IND:
        LD      A,(MNEBUF+1)
        CP      'B'
        JR      NZ,CD_IND_DE
        LD      C,0
        LD      B,0
        LD      A,3
        RET
CD_IND_DE:
        CP      'D'
        JR      NZ,CD_IND_NN
        LD      C,0
        LD      B,0
        LD      A,4
        RET
CD_IND_NN:
        ; "(nn)" ou "($nnnn)"
        PUSH    HL
        LD      HL,MNEBUF+1
        LD      A,(HL)
        CP      '$'
        JR      NZ,CD_NN_DEC
        INC     HL
        CALL    PARSEHEX16FROM
        JR      CD_NN_DONE
CD_NN_DEC:
        CALL    PARSEDEC16FROM
CD_NN_DONE:
        LD      B,H
        LD      C,L
        POP     HL
        LD      A,5
        RET
CD_ERR:
        SCF
        RET

; ------------------------------------------------------------
; Avanca HL (ponteiro da linha, recebido em HL) ate depois de uma
; ',', ignorando o que vier antes dela. carry=1 se nao achou
; virgula antes do fim da linha. Chamar logo apos READTOKEN do
; operando anterior, com HL ainda apontando pro delimitador.
SKIPTOCOMMA:
STC1:
        LD      A,(HL)
        OR      A
        JR      Z,STC_ERR
        CP      13
        JR      Z,STC_ERR
        CP      ','
        JR      Z,STC_OK
        INC     HL
        JR      STC1
STC_OK:
        INC     HL
        OR      A
        RET
STC_ERR:
        SCF
        RET

; ------------------------------------------------------------
; PARSEHEX16 / PARSEDEC16: interpretam digitos a partir de (HL)
; ate um nao-digito, retornam valor em HL. Variante *FROM idem
; mas nao mexe em MNEBUF (usadas de dentro de CLASSIFY_INDN/DEST).
; Nao usam BC (varios chamadores mantem B/C vivos - ex.: codigo
; de condicao em JP cc/CALL cc/JR cc - durante esta chamada).
; O PUSH/POP HL de guarda de ponteiro fica balanceado dentro de
; cada iteracao, entao nao depende de nada empilhado pelo chamador.
PARSEHEX16:
        JR      PARSEHEX16FROM
PARSEHEX16FROM:
        LD      DE,0            ; DE = acumulador
PH16_1:
        LD      A,(HL)
        CALL    ISHEXDIGIT
        JR      C,PH16_DONE
        CALL    HEXVAL          ; A = valor do digito (0-15)
        LD      (DIGITTMP),A
        PUSH    HL              ; guarda o ponteiro de leitura
        EX      DE,HL           ; HL = acumulador atual
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; HL = acumulador*16
        LD      A,(DIGITTMP)
        ADD     A,L
        LD      L,A
        JR      NC,PH16_NOCARRY
        INC     H
PH16_NOCARRY:
        EX      DE,HL           ; DE = novo acumulador
        POP     HL              ; restaura o ponteiro
        INC     HL
        JR      PH16_1
PH16_DONE:
        EX      DE,HL           ; HL = valor final
        OR      A               ; forca carry=0 (sucesso); nao mexe em HL
        RET

PARSEDEC16:
        JR      PARSEDEC16FROM
PARSEDEC16FROM:
        LD      DE,0            ; DE = acumulador
PD16_1:
        LD      A,(HL)
        CP      '0'
        JR      C,PD16_DONE
        CP      '9'+1
        JR      NC,PD16_DONE
        SUB     '0'             ; A = digito (0-9)
        LD      (DIGITTMP),A
        PUSH    HL              ; guarda o ponteiro de leitura
        EX      DE,HL           ; HL = acumulador atual
        ADD     HL,HL           ; HL = ac*2
        LD      (ACCTMP),HL     ; guarda ac*2
        ADD     HL,HL           ; HL = ac*4
        ADD     HL,HL           ; HL = ac*8
        LD      DE,(ACCTMP)
        ADD     HL,DE           ; HL = ac*8 + ac*2 = ac*10
        LD      A,(DIGITTMP)
        ADD     A,L
        LD      L,A
        JR      NC,PD16_NOCARRY
        INC     H
PD16_NOCARRY:
        EX      DE,HL           ; DE = novo acumulador
        POP     HL              ; restaura o ponteiro
        INC     HL
        JR      PD16_1
PD16_DONE:
        EX      DE,HL           ; HL = valor final
        OR      A               ; forca carry=0 (sucesso); nao mexe em HL
        RET

ISHEXDIGIT:
        CP      '0'
        JR      C,IHD_NO
        CP      '9'+1
        JR      C,IHD_YES
        CP      'A'
        JR      C,IHD_NO
        CP      'F'+1
        JR      NC,IHD_NO
IHD_YES:
        OR      A
        RET
IHD_NO:
        SCF
        RET

HEXVAL:
        CP      '9'+1
        JR      C,HV_NUM
        SUB     'A'-10
        RET
HV_NUM:
        SUB     '0'
        RET

; ============================================================
; TABELA DE MNEMONICOS
; formato: 4 bytes nome (padded com 0), 2 bytes ptr handler,
;          1 byte parametro
; ============================================================
; cada entrada ocupa 3 linhas: nome(4) / ponteiro do handler(2) / parametro(1)
MNETAB:
        DB      "LD",0,0
        DW      H_LD
        DB      0
        DB      "ADD",0
        DW      H_ALU
        DB      0               ; ADD A,x  (ADD HL,rp tratado a parte, ver nota no H_ALU)
        DB      "ADC",0
        DW      H_ALU
        DB      1
        DB      "SUB",0
        DW      H_ALU
        DB      2
        DB      "SBC",0
        DW      H_ALU
        DB      3
        DB      "AND",0
        DW      H_ALU
        DB      4
        DB      "XOR",0
        DW      H_ALU
        DB      5
        DB      "OR",0,0
        DW      H_ALU
        DB      6
        DB      "CP",0,0
        DW      H_ALU
        DB      7
        DB      "INC",0
        DW      H_INCDEC
        DB      0
        DB      "DEC",0
        DW      H_INCDEC
        DB      1
        DB      "JP",0,0
        DW      H_JP
        DB      0
        DB      "JR",0,0
        DW      H_JR
        DB      0
        DB      "DJNZ"
        DW      H_JR
        DB      1
        DB      "CALL"
        DW      H_CALL
        DB      0
        DB      "RET",0
        DW      H_RET
        DB      0
        DB      "PUSH"
        DW      H_PUSHPOP
        DB      0
        DB      "POP",0
        DW      H_PUSHPOP
        DB      1
        DB      "IN",0,0
        DW      H_IN
        DB      0
        DB      "OUT",0
        DW      H_OUT
        DB      0
        DB      "EX",0,0
        DW      H_EX
        DB      0
        DB      "EXX",0
        DW      H_SIMPLE
        DB      0D9h
        DB      "HALT"
        DW      H_SIMPLE
        DB      76h
        DB      "NOP",0
        DW      H_SIMPLE
        DB      00h
        DB      "DI",0,0
        DW      H_SIMPLE
        DB      0F3h
        DB      "EI",0,0
        DW      H_SIMPLE
        DB      0FBh
        DB      "DAA",0
        DW      H_SIMPLE
        DB      27h
        DB      "CPL",0
        DW      H_SIMPLE
        DB      2Fh
        DB      "SCF",0
        DW      H_SIMPLE
        DB      37h
        DB      "CCF",0
        DW      H_SIMPLE
        DB      3Fh
        DB      "RLCA"
        DW      H_SIMPLE
        DB      07h
        DB      "RRCA"
        DW      H_SIMPLE
        DB      0Fh
        DB      "RLA",0
        DW      H_SIMPLE
        DB      17h
        DB      "RRA",0
        DW      H_SIMPLE
        DB      1Fh
        DB      0,0,0,0
        DW      0
        DB      0               ; fim da tabela

; ============================================================
; VARIAVEIS
; ============================================================
CURADDR:  DW    0
LINEPTR:  DW    0
LD_DSTTYPE: DB  0
LD_DSTVAL:  DW  0
DIGITTMP: DB    0
TOKLEN:   DB    0
ACCTMP:   DW    0

LINEBUF:  DS    LINEMAX+2
MNEBUF:   DS    9
EMITBUF:  DS    4

MSGERR:   DB    "?",13,10,0

        END     ASMSTART

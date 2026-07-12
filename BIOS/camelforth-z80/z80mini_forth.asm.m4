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
head(ZM_CLS,CLS,docode)
    push bc
    push de
    push hl
    call initTerminal
    pop hl
    pop de
    pop bc
    next

;Z CLG  --  limpa gráfico do LCD diretamente (sem PLOT)
; Uso: CLG
head(ZM_CLG,CLG,docode)
    push bc
    push de
    push hl
    call clearGrLCD
    pop hl
    pop de
    pop bc
    next

;Z PLOT  --  envia buffer gráfico para o LCD
; Necessário após PIXEL, LINE, BOX, CIRCLE etc.
; Uso: 64 32 20 CIRCLE PLOT
head(ZM_PLOT,PLOT,docode)
    push bc
    push de
    push hl
    call plotToLCD
    pop hl
    pop de
    pop bc
    next

;Z AT  x y --  posiciona cursor em pixel x,y (0-127, 0-63)
; Uso: 0 0 AT        ( canto superior esquerdo )
;      63 32 AT      ( meio da tela )
head(ZM_AT,AT,docode)
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
    next

;Z PIXEL  x y --  acende pixel (requer PLOT depois)
; Uso: 64 32 PIXEL PLOT
head(ZM_PIXEL,PIXEL,docode)
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
    next

;Z CPIXEL  x y --  apaga pixel (requer PLOT)
; Uso: 64 32 CPIXEL PLOT
head(ZM_CPIXEL,CPIXEL,docode)
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
    next

;Z FPIXEL  x y --  inverte pixel (requer PLOT)
; Uso: 64 32 FPIXEL PLOT
head(ZM_FPIXEL,FPIXEL,docode)
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
    next

;Z LINE  x0 y0 x1 y1 --  desenha linha (requer PLOT)
; drawLine: B=X0 C=Y0 D=X1 E=Y1
; Uso: 0 0 127 63 LINE PLOT    ( diagonal )
;      0 32 127 32 LINE PLOT   ( horizontal )
head(ZM_LINE,LINE,docode)
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
    next

;Z BOX  x0 y0 x1 y1 --  caixa vazia (requer PLOT)
; Uso: 10 10 117 53 BOX PLOT
head(ZM_BOX,BOX,docode)
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
    next

;Z FBOX  x0 y0 x1 y1 --  caixa preenchida (requer PLOT)
; Uso: 0 0 127 63 FBOX PLOT    ( preenche tudo )
head(ZM_FBOX,FBOX,docode)
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
    next

;Z CIRCLE  x y r --  círculo (requer PLOT)
; drawCircle: B=X C=Y E=raio
; Uso: 64 32 20 CIRCLE PLOT
head(ZM_CIRCLE,CIRCLE,docode)
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
    next

;Z FCIRCLE  x y r --  círculo preenchido (requer PLOT)
; Uso: 64 32 20 FCIRCLE PLOT
head(ZM_FCIRCLE,FCIRCLE,docode)
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
    next

;Z HEX.LCD  n --  imprime n em HEX no GLCD ("XXXX")
; Uso: $CAFE HEX.LCD
;      HERE HEX.LCD
head(ZM_HEXDOTLCD,HEX.LCD,docode)
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
    next

; ============================================================
; SECÇÃO 2: SERIAL
; ============================================================

;Z SERIAL-A  --  terminal → Serial A
; Uso: SERIAL-A
head(ZM_SERIALA,SERIAL-A,docode)
    push bc
    push de
    push hl
    call setDefaultSerialA
    pop  hl
    pop  de
    pop  bc
    next

;Z SERIAL-B  --  terminal → Serial B (ZiModem)
; Uso: SERIAL-B
head(ZM_SERIALB,SERIAL-B,docode)
    push bc
    push de
    push hl
    call setDefaultSerialB
    pop  hl
    pop  de
    pop  bc
    next

;Z SEMIT  c --  envia char para serial setada
; Uso: 65 SEMIT    ( envia 'A' )
;      13 SEMIT    ( envia CR )
head(ZM_SEMIT,SEMIT,docode)
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
    next

;Z SKEY  -- c  aguarda char da serial setada
; Uso: SKEY EMIT
head(ZM_SKEY,SKEY,docode)
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
    next

;Z SHEX  n --  imprime byte n em HEX na serial ("XX")
; Uso: $FF SHEX     → "FF"
;      10  SHEX     → "0A"
head(ZM_SHEX,SHEX,docode)
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
    next

;Z S-CRLF  --  envia CR+LF pela serial
; Uso: S-CRLF
head(ZM_SCRLF,S-CRLF,docode)
    push bc
    push de
    push hl
    push ix
    call serialCRLF
    pop  ix
    pop  hl
    pop  de
    pop  bc
    next

; ============================================================
; SECÇÃO 3: I2C / EEPROM 24C256
; ============================================================

;Z I2C-OPEN  addr --  abre dispositivo I2C
; addr bit0=0 → escrita,  bit0=1 → leitura
; Uso: $A0 I2C-OPEN    ( EEPROM para escrita )
;      $A1 I2C-OPEN    ( EEPROM para leitura )
head(ZM_I2COPEN,I2C-OPEN,docode)
    ld   a, c
    push bc
    push de
    push hl
    call I2C_Open
    pop  hl
    pop  de
    pop  bc
    pop  bc
    next

;Z I2C-CLOSE  --  fecha I2C
; Uso: I2C-CLOSE
head(ZM_I2CCLOSE,I2C-CLOSE,docode)
    push bc
    push de
    push hl
    call I2C_Close
    pop  hl
    pop  de
    pop  bc
    next

;Z I2C-C!  byte --  escreve byte no I2C
; Uso: $42 I2C-C!
head(ZM_I2CBYTEW,I2C-C!,docode)
    ld   a, c
    push bc
    push de
    push hl
    call I2C_Write
    pop  hl
    pop  de
    pop  bc
    pop  bc
    next

;Z I2C-C@  -- byte  lê byte do I2C
; Uso: I2C-C@ .
head(ZM_I2CBYTER,I2C-C@,docode)
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
    next

;Z EEPROM!  byte addr --  escreve byte na EEPROM 24C256
; Uso: $42 $0000 EEPROM!
;      65  $1234 EEPROM!
head(ZM_EEPROMSTORE,EEPROM!,docolon)
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
head(ZM_EEPROMFETCH,EEPROM@,docolon)
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
head(ZM_EEPROMDUMP,EEPROM-DUMP,docolon)
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
head(ZM_MS,MS,docode)
    ; BC=n(TOS), DE=IP
    ; Precisamos DE=n para a ROM, mas DE é o IP!
    ; Solução: exx salva IP em DE'
    exx              ; DE'=IP  BC'=n
    ld   d, b        ; DE = n  (para ROM delay)
    ld   e, c
    call delay
    exx              ; restaura DE=IP
    pop  bc          ; novo TOS (drop n)
    next

;Z 500MS  --  delay fixo de 500 milissegundos
; Uso: 500MS
head(ZM_MS500,500MS,docode)
    push bc
    push de
    push hl
    call delay500ms
    pop  hl
    pop  de
    pop  bc
    next

; ============================================================
; SECÇÃO 5: CURSOR E DISPLAY
; ============================================================

;Z D-CURSOR  f --  controla cursor GLCD (0=on, !=0=off)
; Uso: 0 D-CURSOR    ( liga cursor )
;      1 D-CURSOR    ( desliga cursor )
head(ZM_DCURSOR,D-CURSOR,docode)
    ld   a, c
    push bc
    push de
    push hl
    call displayCursor
    pop  hl
    pop  de
    pop  bc
    pop  bc
    next

;Z BLINK  n --  pisca cursor n vezes (100ms on/off)
; Uso: 5 BLINK
;      10 BLINK
head(ZM_BLINK,BLINK,docolon)
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
head(ZM_FREE,FREE,docolon)
    DW HERE
    DW SPFETCH
    DW SWOP
    DW MINUS
    DW EXIT

;Z DEMO  --  demo gráfico: bordas + diagonais + círculo
; Uso: DEMO
head(ZM_DEMO,DEMO,docolon)
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

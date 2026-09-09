#include "../Z80MiniAPI.asm"


; =========================================================
; TESTE_SDCARD.ASM
; Teste de inicializacao SPI do modulo SD Card no Z80Mini
; Porta $C0 (bit-bang SPI, somente escrita) + entrada $C0 (MISO)
; Roda na RAM a partir de $8000
;
; Mapeamento assumido (mesmo do driver ST7735/MAX7219):
;   OUT $C0:  bit0=SCK  bit1=MOSI  bit2=CS
;   IN  $C0:  bit0=MISO (com pull-up externo confirmado no hardware)
;
; Status confirmado:
;   CMD0 -> R1=$01 (cartao entrou em modo SPI, idle)   OK
;   CMD8 -> timeout ($FF)  -> cartao nao suporta CMD8,
;           tratado como SDv1 (comportamento esperado)
;
; Esta versao adiciona:
;   - loop de ACMD41 (CMD55+CMD41, sem HCS ja que e' SDv1)
;     ate o cartao sair do estado idle (R1 = $00)
;   - CMD58 (READ_OCR) apos inicializar, so' para conferir
;
; Compilar:  zasm --z80 -w -u --bin TESTE_SDCARD.ASM
; Rodar a partir de $8000 no monitor do Z80Mini (G8000)
; =========================================================



PORTC0  EQU   $C0
BUFFER  EQU   $9000            ; buffer de 512 bytes p/ o setor lido (fora da area de codigo)

; ---- mascaras da SAIDA $C0 (ajustar se necessario) ----
M_SCK   EQU   $01
M_MOSI  EQU   $02
M_CS    EQU   $04

; ---- mascara da ENTRADA $C0 (ajustar se necessario) ----
M_MISO  EQU   $01

        ORG   $8000

START:
        LD    HL,MSGTITLE
        CALL  PRINT

        ; ---- estado inicial: CS=1 (inativo), MOSI=1, SCK=0 ----
        LD    A,M_CS|M_MOSI
        LD    (OUTSTATE),A
        OUT   (PORTC0),A

        ; ---- 0) delay p/ VDD do cartao estabilizar ----
        LD    DE,100          ; 100ms
        CALL  delay

        ; ---- 1) power-up: >=74 clocks com CS=1 MOSI=1 ----
        LD    B,80
PULOOP:
        CALL  SCKPULSE
        DJNZ  PULOOP

        ; ---- 2) CMD0: GO_IDLE_STATE ----
        LD    HL,MSGCMD0
        CALL  PRINT

        CALL  CSLOW
        LD    HL,CMD0
        CALL  SENDCMD
        CALL  READR1

        LD    HL,MSGR1
        CALL  PRINT
        CALL  HEXOUT
        CALL  TXCRLF

        CALL  CSHIGH

        ; ---- 3) ACMD41: inicializacao (CMD55 + CMD41, sem HCS = SDv1) ----
        LD    HL,MSGACMD41
        CALL  PRINT

        LD    IX,0             ; contador de tentativas (16 bits, nao usa B)
ACMD41LOOP:
        CALL  CSLOW

        LD    HL,CMD55
        CALL  SENDCMD
        CALL  READR1           ; A = R1 do CMD55

        LD    C,A               ; guarda R1 do CMD55 em C
        LD    A,IXH
        OR    A
        JR    NZ,SKIPPRINT55    ; so' imprime detalhado na 1a "volta" de IX
        LD    A,IXL
        CP    15
        JR    NC,SKIPPRINT55

        LD    HL,MSGCMD55R1
        CALL  PRINT
        LD    A,C
        CALL  HEXOUT
        LD    A,' '
        RST   $08
SKIPPRINT55:

        LD    HL,CMD41
        CALL  SENDCMD
        CALL  READR1           ; A = R1 do ACMD41

        LD    C,A               ; guarda R1 do ACMD41
        LD    A,IXH
        OR    A
        JR    NZ,SKIPPRINT41
        LD    A,IXL
        CP    15
        JR    NC,SKIPPRINT41

        LD    HL,MSGCMD41R1
        CALL  PRINT
        LD    A,C
        CALL  HEXOUT
        CALL  TXCRLF
SKIPPRINT41:

        CALL  CSHIGH

        LD    A,C               ; R1 do ACMD41 de volta em A
        OR    A
        JR    Z,ACMD41OK       ; R1=0 -> cartao pronto

        LD    DE,5              ; pequeno delay entre tentativas (5ms)
        CALL  delay

        INC   IX
        LD    A,IXH
        CP    4                 ; ~ate 1024 tentativas (IX 16 bits)
        JR    C,ACMD41LOOP

        LD    HL,MSGACMD41TO
        CALL  PRINT
        JP    ENDTEST

ACMD41OK:
        LD    HL,MSGACMD41OK
        CALL  PRINT

        ; ---- 4) CMD58: READ_OCR (so' para conferir) ----
        CALL  CSLOW
        LD    HL,CMD58
        CALL  SENDCMD
        CALL  READR1

        LD    HL,MSGR1
        CALL  PRINT
        CALL  HEXOUT
        CALL  TXCRLF

        LD    HL,MSGOCR
        CALL  PRINT
        LD    B,4
OCRLOOP:
        PUSH  BC
        CALL  SPIRECV
        CALL  HEXOUT
        LD    A,' '
        RST   $08
        POP   BC
        DJNZ  OCRLOOP
        CALL  TXCRLF
        CALL  CSHIGH

        ; ---- 5) CMD17: READ_SINGLE_BLOCK (le o bloco 0) ----
        ; cartao e' SDSC (CCS=0 no OCR) -> endereco em BYTES, nao em blocos
        ; bloco 0 -> endereco = 0
        LD    HL,MSGCMD17
        CALL  PRINT

        CALL  CSLOW
        LD    HL,CMD17
        CALL  SENDCMD
        CALL  READR1

        LD    HL,MSGR1
        CALL  PRINT
        CALL  HEXOUT
        CALL  TXCRLF

        OR    A
        JR    NZ,CMD17ERR      ; R1 != 0 -> comando rejeitado

        ; ---- espera o token de inicio de dados ($FE) ----
        LD    IX,0
WAITTOKEN:
        CALL  SPIRECV
        CP    $FE
        JR    Z,GOTTOKEN
        INC   IX
        LD    A,IXH
        CP    $20              ; timeout generoso (~8000 tentativas)
        JR    C,WAITTOKEN

        LD    HL,MSGTOKENTO
        CALL  PRINT
        JR    CMD17DONE

GOTTOKEN:
        ; ---- le os 512 bytes de dados para o buffer ----
        LD    HL,BUFFER
        LD    BC,512
READLOOP:
        CALL  SPIRECV
        LD    (HL),A
        INC   HL
        DEC   BC
        LD    A,B
        OR    C
        JR    NZ,READLOOP

        ; ---- le e descarta o CRC16 (2 bytes) ----
        CALL  SPIRECV
        CALL  SPIRECV

        LD    HL,MSGDATAOK
        CALL  PRINT

        ; ---- mostra os primeiros 16 bytes em hex ----
        LD    HL,BUFFER
        LD    B,16
DUMPLOOP:
        PUSH  BC
        LD    A,(HL)
        CALL  HEXOUT
        LD    A,' '
        RST   $08
        INC   HL
        POP   BC
        DJNZ  DUMPLOOP
        CALL  TXCRLF

        ; ---- confere assinatura de boot 0x55 0xAA (offset 510-511) ----
        LD    HL,BUFFER+510
        LD    A,(HL)
        CP    $55
        JR    NZ,NOSIG
        INC   HL
        LD    A,(HL)
        CP    $AA
        JR    NZ,NOSIG

        LD    HL,MSGBOOTSIG
        CALL  PRINT
        JR    CMD17DONE

NOSIG:
        LD    HL,MSGNOBOOTSIG
        CALL  PRINT

CMD17DONE:
        CALL  CSHIGH
        JR    ENDTEST

CMD17ERR:
        LD    HL,MSGCMD17ERR
        CALL  PRINT
        CALL  CSHIGH

ENDTEST:
        LD    HL,MSGBYE
        CALL  PRINT
        RET

; ---------------------------------------------------------
; CSLOW / CSHIGH - controla CS mantendo os demais bits de OUTSTATE
; ---------------------------------------------------------
CSLOW:
        LD    A,(OUTSTATE)
        AND   ~M_CS & $FF
        LD    (OUTSTATE),A
        OUT   (PORTC0),A
        RET

CSHIGH:
        LD    A,(OUTSTATE)
        OR    M_CS
        LD    (OUTSTATE),A
        OUT   (PORTC0),A
        CALL  SCKPULSE
        RET

HEXOUT:
	push bc
	push de
	push hl
	call sendRegToLCD
	pop hl
	pop de
	pop bc
	ret

TXCRLF:
	push af
	ld a, 13
	rst $08
	pop af
	ret



PRINT:
	push af
	push bc 
	push de
	push hl
	push hl
	pop de
	LD A, 0
	call sendStringToLCD
	pop hl
	pop de
	pop bc
	pop af
	ret






; ---------------------------------------------------------
; SENDCMD - envia comando SD de 6 bytes apontado por HL
; ---------------------------------------------------------
SENDCMD:
        LD    B,6
SCLOOP:
        LD    A,(HL)
        CALL  SPISEND
        INC   HL
        DJNZ  SCLOOP
        RET

; ---------------------------------------------------------
; READR1 - espera resposta R1 (bit7=0), timeout em B
; retorna valor em A
; ---------------------------------------------------------
READR1:
        LD    B,$FF
RR1LOOP:
        CALL  SPIRECV
        BIT   7,A
        RET   Z
        DJNZ  RR1LOOP
        RET                    ; timeout: retorna ultimo valor lido ($FF = sem resposta)

; ---------------------------------------------------------
; SPISEND - envia byte A via bit-bang (MSB first)
; NOPs adicionados para desacelerar o clock (fase de init)
; ---------------------------------------------------------
SPISEND:
        PUSH  BC
        LD    C,A
        LD    B,8
SSLOOP:
        LD    A,(OUTSTATE)
        AND   ~M_MOSI & $FF
        RLC   C
        JR    NC,SSNOBIT
        OR    M_MOSI
SSNOBIT:
        OUT   (PORTC0),A       ; MOSI valido, SCK=0
        NOP
        NOP
        OR    M_SCK
        OUT   (PORTC0),A       ; sobe SCK (dado e' amostrado)
        NOP
        NOP
        AND   ~M_SCK & $FF
        OUT   (PORTC0),A       ; desce SCK
        NOP
        NOP
        DJNZ  SSLOOP
        LD    A,(OUTSTATE)
        OUT   (PORTC0),A       ; restaura estado (MOSI=1, CS mantido)
        POP   BC
        RET

; ---------------------------------------------------------
; SPIRECV - le um byte via bit-bang (MSB first), MOSI=1 (0xFF)
; NOPs adicionados para desacelerar o clock (fase de init)
; retorna byte em A
; ---------------------------------------------------------
SPIRECV:
        PUSH  BC
        LD    D,0
        LD    B,8
SRLOOP:
        LD    A,(OUTSTATE)
        OR    M_SCK
        OUT   (PORTC0),A       ; sobe SCK
        NOP
        NOP
        IN    A,(PORTC0)
        AND   M_MISO
        JR    Z,SRZERO
        SCF
        JR    SRSHIFT
SRZERO:
        OR    A
SRSHIFT:
        RL    D
        LD    A,(OUTSTATE)
        OUT   (PORTC0),A       ; desce SCK
        NOP
        NOP
        DJNZ  SRLOOP
        LD    A,D
        POP   BC
        RET

; ---------------------------------------------------------
; SCKPULSE - um pulso de clock com o estado atual de saida
; NOPs adicionados para desacelerar o clock (fase de init)
; ---------------------------------------------------------
SCKPULSE:
        LD    A,(OUTSTATE)
        OR    M_SCK
        OUT   (PORTC0),A
        NOP
        NOP
        LD    A,(OUTSTATE)
        OUT   (PORTC0),A
        NOP
        NOP
        RET

; ---------------------------------------------------------
; Dados
; ---------------------------------------------------------
OUTSTATE: DEFB  0

CMD0:   DEFB  $40,$00,$00,$00,$00,$95   ; GO_IDLE_STATE (CRC valido)
CMD8:   DEFB  $48,$00,$00,$01,$AA,$87   ; SEND_IF_COND (nao usado neste teste)
CMD55:  DEFB  $77,$00,$00,$00,$00,$01   ; APP_CMD (prefixo do ACMD)
CMD41:  DEFB  $69,$40,$00,$00,$00,$01   ; SD_SEND_OP_COND, HCS=1 (assume SDv2/SDHC)
CMD58:  DEFB  $7A,$00,$00,$00,$00,$01   ; READ_OCR
CMD17:  DEFB  $51,$00,$00,$00,$00,$01   ; READ_SINGLE_BLOCK, endereco=0 (bloco 0, SDSC)

MSGTITLE:
        DEFM  "Teste SD Card - init SPI"
        DEFB  13,0
MSGCMD0:
        DEFM  "Enviando CMD0 (GO_IDLE_STATE)..."
        DEFB  13,0
MSGACMD41:
        DEFM  "Enviando ACMD41 ate sair do idle..."
        DEFB  13,0
MSGACMD41OK:
        DEFM  "Cartao inicializado! (R1=0)"
        DEFB  13,0
MSGACMD41TO:
        DEFM  "Timeout no ACMD41 (cartao nao saiu do idle)"
        DEFB  13,0
MSGOCR:
        DEFM  "OCR = "
        DEFB  0
MSGR1:
        DEFM  "R1 = $"
        DEFB  0
MSGCMD55R1:
        DEFM  "  CMD55 R1=$"
        DEFB  0
MSGCMD41R1:
        DEFM  " CMD41 R1=$"
        DEFB  0
MSGBYE:
        DEFM  "Fim do teste."
        DEFB  13,0
MSGCMD17:
        DEFM  "Lendo bloco 0 (CMD17)..."
        DEFB  13,0
MSGCMD17ERR:
        DEFM  "CMD17 rejeitado (R1 != 0)"
        DEFB  13,0
MSGTOKENTO:
        DEFM  "Timeout esperando token de dados ($FE)"
        DEFB  13,0
MSGDATAOK:
        DEFM  "512 bytes lidos! Primeiros 16 bytes:"
        DEFB  13,0
MSGBOOTSIG:
        DEFM  "Assinatura de boot 55 AA encontrada!"
        DEFB  13,0
MSGNOBOOTSIG:
        DEFM  "Sem assinatura 55 AA (bloco 0 pode nao ser boot sector)"
        DEFB  13,0

        END

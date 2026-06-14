#include "../Z80MiniAPI.asm"

;       TESTES
;
;       ATW "wifiName,WifiSenha"
;
;       ATD "bbs.retrocampus.com"
;
;       atualiza o display quando é preciona uma tecla, a cada 3 chars recebidos (PLOT_EVERY) ou a cada $0800 ticks.

SER_BUFSIZE     .EQU  $200    ; 512 bytes
SER_FULLSIZE    .EQU  $80
SER_EMPTYSIZE   .EQU  5

PLOT_EVERY  EQU  3      ; plota a cada N chars recebidos
        org $8000

;------------------------------------------------------------------------------
; Inicializacao
;------------------------------------------------------------------------------
inicio:
        ; Initialise SIO/2 B - Printer (P2 conector)
        LD      A,$04
        OUT     (SIOB_C),A
        LD      A,$C4
        OUT     (SIOB_C),A

        LD      A,$03
        OUT     (SIOB_C),A
        LD      A,$E1
        OUT     (SIOB_C),A

        LD      A,$05
        OUT     (SIOB_C),A
        LD      A,$68
        OUT     (SIOB_C),A

        ; WR1 = interrupção em todos os caracteres recebidos
        LD      A,1
        OUT     (SIOB_C),A
        LD      A,%00011000
        OUT     (SIOB_C),A

        ; Inicializa buffer serial B
        LD      HL,$0000
        LD      (serBBufUsed),HL
        LD      HL,serBBuf
        LD      (serBInPtr),HL
        LD      (serBRdPtr),HL


        XOR     A
        LD      (plotCounter), A

        LD HL, $0800
        LD (tick), HL


        ; Configura serial B como padrao
        CALL    setDefaultSerialB

        ; Configura ISR serial B via INT38
        LD      HL,serialInt
        CALL    setInt38
        IM      1
        EI

        LD      A,FF
        CALL    sendCharToLCD

        LD      DE,msg
        CALL    sendStringToLCD

;------------------------------------------------------------------------------
; Loop principal — le byte do buffer e exibe no LCD
;------------------------------------------------------------------------------
LOOP:
        CALL    coninB        ; pega do buffer se tiver, le teclado se tecla e retorna
        CALL    PUTCHAR       ; mostra no display
        JP      LOOP

;------------------------------------------------------------------------------
; ISR Serial B
; O trampolim em $0038 faz PUSH HL antes de saltar aqui,
; por isso o primeiro POP HL é obrigatório para desfazer esse push.
;------------------------------------------------------------------------------
serialInt:
        POP     HL              ; desfaz PUSH HL do trampolim em $0038

        PUSH    AF
        PUSH    HL
        PUSH    BC

serialIntB:
        ; Grava na posição atual, incrementa depois
        LD      HL,(serBInPtr)
        IN      A,(SIOB_D)      ; lê byte UMA vez
        LD      (HL),A          ; grava no buffer

        ; Avança serBInPtr com wrap por comparação de endereço
        INC     HL
        LD      BC,serBBuf + SER_BUFSIZE
        LD      A,H
        CP      B
        JR      NZ,notBWrap
        LD      A,L
        CP      C
        JR      NZ,notBWrap
        LD      HL,serBBuf      ; wrap: volta ao início
notBWrap:
        LD      (serBInPtr),HL

        ; Incrementa contador (16 bits)
        LD      HL,(serBBufUsed)
        INC     HL
        LD      (serBBufUsed),HL

        POP     BC
        POP     HL
        POP     AF
        EI
        RETI


updateDisplay:
        call plotToLCD
        LD HL, $0800
        LD (tick), HL
        ret


;------------------------------------------------------------------------------
; coninB — aguarda e retorna um byte do buffer serial B em A
; Também verifica teclado: se tecla pressionada, chama getLine
;------------------------------------------------------------------------------
coninB:
waitForCharB:
        CALL    keyboardA
        CALL    C, keyboardSend       ; tecla pressionada: envia linha via serial

        ;tick para atualizar o display
        ld HL, (tick)
        dec HL
        LD (tick), HL
        ld a, h
        or l
        cp 0
        call z, updateDisplay

        ; Verifica se buffer tem dados (16 bits)
        LD      HL,(serBBufUsed)
        LD      A,H
        OR      L
        JR      Z,waitForCharB  ; vazio, aguarda

        ; Lê byte na posição atual de leitura
        LD      HL,(serBRdPtr)
        LD      A,(HL)          ; lê o byte
        PUSH    AF              ; preserva byte lido

        ; Avança serBRdPtr com wrap
        INC     HL
        LD      BC,serBBuf + SER_BUFSIZE
        LD      A,H
        CP      B
        JR      NZ,notRdWrapB
        LD      A,L
        CP      C
        JR      NZ,notRdWrapB
        LD      HL,serBBuf      ; wrap: volta ao início
notRdWrapB:
        DI
        LD      (serBRdPtr),HL

        ; Decrementa contador (16 bits)
        LD      HL,(serBBufUsed)
        DEC     HL
        LD      (serBBufUsed),HL
        EI

        POP     AF              ; byte lido de volta em A
        RET

;------------------------------------------------------------------------------
; getLine — captura linha do teclado e envia pela serial
;------------------------------------------------------------------------------
keyboardSend:
        call keyboardWaitA              ; pega char do teclado
        CP  $F8                         ; UP key
        JR  Z, keyboardSendDispOnly     ; Só manda para o display (comando scroll tela)
        CP  $F7                         ; DOWN key
        JR  Z, keyboardSendDispOnly     ; Só manda para o display (comando scroll tela)
        call serialPrintA               ; envia direto pra serial, sem buffer..
        LD A, PLOT_EVERY                ; forca mostrar
        LD (plotCounter), A             ; força atualizar display
        ret                             ; retorna
keyboardSendDispOnly:
        CALL    sendCharToLCD           ; manda para o display
        RET                             ; retorna

;------------------------------------------------------------------------------
; PUTCHAR — exibe o caractere em A no LCD e atualiza display
;------------------------------------------------------------------------------
PUTCHAR:
        PUSH    BC
        PUSH    DE
        PUSH    HL

        PUSH    AF
        LD      A, 1
        CALL    plotAlways      ; desativa plot automático
        POP     AF

        CALL    sendCharToLCD   ; só grava no buffer, não plota

        ; Força plot se for CR
        CP      CR
        JR      Z, PUTCHARdoPlot
        CP      LF
        JR      Z, PUTCHARdoPlot

        ; Incrementa contador
        LD      A, (plotCounter)
        INC     A
        LD      (plotCounter), A
        CP      PLOT_EVERY
        JR      C, PUTCHARskip        ; ainda não chegou em N

PUTCHARdoPlot:
        XOR     A
        LD      (plotCounter), A
        CALL    updateDisplay

PUTCHARskip:
        POP     HL
        POP     DE
        POP     BC
        RET

;------------------------------------------------------------------------------
; Dados
;------------------------------------------------------------------------------
msg:    db      "Term v0.1", CR, 0

;------------------------------------------------------------------------------
; RAM
;------------------------------------------------------------------------------
serBBuf:        .ds     SER_BUFSIZE
serBInPtr:      .ds     2
serBRdPtr:      .ds     2
serBBufUsed:    .ds     2
plotCounter:    .ds     1
tick:           .ds     2

#include "../Z80MiniAPI.asm"

; =============================================================================
; EDMINI.ASM - Editor de texto estilo ED.COM (CP/M) para o Z80Mini
; -----------------------------------------------------------------------------
; Roda em RAM a partir de 0x8000 (tecla LUZ do Z80Mini faz CALL 8000H).
; Monta com zasm.
;
; ESTILO: como o ED.COM original do CP/M, este é um editor ORIENTADO A LINHA,
; não um editor de tela cheia (full-screen). Comandos de uma letra digitados
; num prompt "*", texto do buffer aparece no terminal do GLCD com scroll
; automático (autoLF). Isso combina bem com uma tela pequena de 128x64.
;
; COMANDOS (digite no prompt "*" e pressione ENTER):
;   I        - Insere linha(s) ANTES da linha atual
;   A        - Adiciona linha(s) DEPOIS da linha atual
;                (em I/A, digite uma linha por ENTER; ENTER em branco termina;
;                 ESC cancela a entrada da linha atual)
;   D        - Apaga a linha atual
;   N        - Vai para a próxima linha (e mostra)
;   P        - Vai para a linha anterior (e mostra)
;   G<num>   - Vai para a linha <num>, ex: G10
;   L        - Lista o buffer inteiro (pausa a cada algumas linhas)
;   W        - Envia o buffer inteiro pela serial (para capturar/salvar
;              num terminal externo, já que a API não expõe um FS aqui)
;   H ou ?   - Mostra a ajuda
;   E        - Sai do editor (volta para o monitor)
;
; LIMITAÇÕES (mantido simples de propósito):
;   - Números de linha são de 1 byte (1-255 linhas no máximo)
;   - Sem undo, sem busca/substituição, sem numeração automática de reflow
;   - "Salvar" = enviar pela serial (W); não grava em EEPROM/FS. Se você tiver
;     rotinas de sistema de arquivos, é só trocar CMD_WRITE por chamadas a elas.
;   - Backspace: mandamos BKS,SPACE,BKS para o terminal para apagar visualmente
;     mesmo que o driver não trate BKS sozinho. Ajuste se seu driver já tratar.
;   - O programa NÃO mexe no SP (mantém a pilha que o monitor já preparou),
;     assim "E"/RET volta corretamente para quem deu CALL 8000H.
;
; AJUSTES: mude MAXLINE e BUFSIZE conforme a RAM livre acima do programa.
; =============================================================================

    ORG 8000h

CR:    EQU 0Dh
LF:    EQU 0Ah
BKS:   EQU 08h
DEL:   EQU 7Fh
ESC:   EQU 1Bh
SPACE: EQU 20h
NUL:   EQU 00h

; -----------------------------------------------------------------------------
; Configuração (ajuste conforme a RAM livre do seu Z80Mini)
; -----------------------------------------------------------------------------
MAXLINE:  EQU 60      ; tamanho máximo de uma linha de texto digitada
BUFSIZE:  EQU 4096    ; tamanho da área de armazenamento do texto
PAGESIZE: EQU 10      ; linhas mostradas por "página" no comando L

; =============================================================================
; PONTO DE ENTRADA
; =============================================================================
START:
    CALL initTerminal
    XOR A
    CALL autoLF             ; A=0 -> quebra de linha automática ligada

    CALL CMD_HELP            ; mostra banner/ajuda ao abrir

MAINLOOP:
    CALL PRINT_PROMPT
    CALL READ_LINE
    JP C, MAINLOOP            ; ESC no prompt -> ignora, volta a perguntar
    LD A, (LINEBUF)
    OR A
    JP Z, MAINLOOP             ; linha vazia -> ignora
    CALL EXEC_CMD
    JP MAINLOOP

; =============================================================================
; DESPACHO DE COMANDOS
; =============================================================================
; Lê o primeiro caractere de LINEBUF+1 e chama a rotina correspondente.
EXEC_CMD:
    LD A, (LINEBUF+1)
    CALL UPCASE
    CP 'I'
    JP Z, CMD_INSERT
    CP 'A'
    JP Z, CMD_APPEND
    CP 'D'
    JP Z, CMD_DELETE
    CP 'N'
    JP Z, CMD_NEXT
    CP 'P'
    JP Z, CMD_PREV
    CP 'G'
    JP Z, CMD_GOTO
    CP 'L'
    JP Z, CMD_LIST
    CP 'W'
    JP Z, CMD_WRITE
    CP 'H'
    JP Z, CMD_HELP
    CP '?'
    JP Z, CMD_HELP
    CP 'E'
    JP Z, CMD_EXIT
    CP 'C'
    JP Z, CMD_CLEAR
    LD HL, MSG_UNKNOWN
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_INSERT:
    LD A, (LINECOUNT)
    OR A
    JP Z, CI_ATSTART
    LD A, (CURLINE)
    JP CI_GOTIN
CI_ATSTART:
    LD A, 1
CI_GOTIN:
    LD (INS_POS), A
    ;LD HL, MSG_INSERT_HELP
    ;CALL PRINT_STR
CI_LOOP:
    CALL READ_LINE
    JP C, CI_END               ; ESC termina
    LD A, (LINEBUF)
    OR A
    JP Z, CI_END                ; linha vazia termina
    LD A, (INS_POS)
    CALL ADD_LINE_AT
    JP C, CI_END                 ; buffer cheio ou posição inválida - aborta
    LD A, (INS_POS)
    LD (CURLINE), A               ; CURLINE = linha que acabou de ser inserida
    LD A, (LINECOUNT)
    CP 255
    JP Z, CI_END                   ; atingiu o maximo de 255 linhas - encerra
    LD HL, INS_POS
    INC (HL)
    JP CI_LOOP
CI_END:
    RET

; -----------------------------------------------------------------------------
CMD_APPEND:
    LD A, (CURLINE)
    INC A
    LD (INS_POS), A
    ;LD HL, MSG_INSERT_HELP
    ;CALL PRINT_STR
    JP CI_LOOP

; -----------------------------------------------------------------------------
CMD_DELETE:
    LD A, (LINECOUNT)
    OR A
    JP Z, CX_EMPTY
    LD A, (CURLINE)
    CALL DELETE_LINE
    LD A, (LINECOUNT)
    OR A
    RET Z
    LD A, (CURLINE)
    JP DISPLAY_LINE
CX_EMPTY:
    LD HL, MSG_EMPTY
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_NEXT:
    LD A, (LINECOUNT)
    OR A
    JP Z, CX_EMPTY
    LD HL, LINECOUNT
    LD A, (CURLINE)
    CP (HL)
    JP Z, CN_ATEND
    LD HL, CURLINE
    INC (HL)
    LD A, (CURLINE)
    JP DISPLAY_LINE
CN_ATEND:
    LD HL, MSG_LASTLINE
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_PREV:
    LD A, (CURLINE)
    CP 2
    JP C, CP_ATSTART
    LD HL, CURLINE
    DEC (HL)
    LD A, (CURLINE)
    JP DISPLAY_LINE
CP_ATSTART:
    LD HL, MSG_FIRSTLINE
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_GOTO:
    LD HL, LINEBUF+2           ; pula o 'G'; PARSE_NUMBER ainda pula espaços
    CALL PARSE_NUMBER
    JP C, CG_ERR                ; número > 255 (estouro) - inválido
    OR A
    JP Z, CG_ERR
    CALL FIND_LINE               ; entrada A=alvo; saída D=alvo preservado
    JP C, CG_ERR
    LD A, D
    LD (CURLINE), A
    JP DISPLAY_LINE
CG_ERR:
    LD HL, MSG_NOLINE
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_LIST:
    LD A, (LINECOUNT)
    OR A
    JP Z, CX_EMPTY
    LD (LIST_TOTAL), A
    LD A, 1
    LD (LIST_CUR), A
    XOR A
    LD (LIST_PAGE), A
CL_LOOP:
    LD A, (LIST_CUR)
    LD D, A
    LD A, (LIST_TOTAL)
    CP D
    JP C, CL_END
    LD A, D
    CALL DISPLAY_LINE
    LD HL, LIST_CUR
    INC (HL)
    LD HL, LIST_PAGE
    INC (HL)
    LD A, (HL)
    CP PAGESIZE
    JP C, CL_LOOP
    LD HL, MSG_MORE
    CALL PRINT_MSG
    CALL keyboardWaitA
    CALL LCD_NEWLINE
    CP ESC
    JP Z, CL_END
    XOR A
    LD (LIST_PAGE), A
    JP CL_LOOP
CL_END:
    RET

; -----------------------------------------------------------------------------
; Envia o buffer inteiro pela serial, uma linha de texto por linha,
; para ser capturado/salvo por um terminal externo. Troca temporariamente
; o canal serial padrão para a impressora térmica (Serial B) e restaura
; o canal original (Serial A) ao final, mesmo em caso de erro.
CMD_WRITE:
    LD A, (LINECOUNT)
    OR A
    JP Z, CX_EMPTY

    CALL setDefaultSerialB ; impressora termica

    LD HL, MSG_SENDING
    CALL PRINT_MSG
    LD HL, BUFSTART
    LD A, (LINECOUNT)
    LD B, A
CW_LOOP:
    LD A, (HL)
    LD C, A
    INC HL
    LD A, C
    OR A
    JP Z, CW_EOL
CW_CHAR:
    LD A, (HL)
    CALL serialPrintA
    INC HL
    DEC C
    JP NZ, CW_CHAR
CW_EOL:
    CALL serialCRLF
    DJNZ CW_LOOP

    CALL setDefaultSerialA  ; restaura o canal serial padrão (Serial A)

    LD HL, MSG_DONE
    JP PRINT_MSG

; -----------------------------------------------------------------------------
CMD_HELP:
    LD HL, MSG_HELP
    CALL PRINT_MSG
    RET

; -----------------------------------------------------------------------------
CMD_EXIT:
    LD HL, MSG_BYE
    CALL PRINT_MSG
    RET                         ; volta para quem deu CALL 8000H (ex.: monitor)

;------------------------------------------------------------------------------

; =============================================================================
CMD_CLEAR:
    LD A, (LINECOUNT)
    OR A
    JP Z, CC_EMPTY              ; se já está vazio, avisa e sai
    
    LD HL, MSG_CLEAR_CONFIRM
    CALL PRINT_MSG
    
    CALL keyboardWaitA
    CALL UPCASE
    CP 'S'                       ; 'S' de "Sim"
    JR NZ, CC_ABORT
    
    ; Limpa o buffer
    XOR A
    LD (CURLINE), A
    LD (LINECOUNT), A
    LD HL, BUFSTART
    LD (BUFPTR), HL
    
    LD HL, MSG_CLEARED
    JP PRINT_MSG
    
CC_ABORT:
    LD HL, MSG_CLEAR_CANCEL
    JP PRINT_MSG
    
CC_EMPTY:
    LD HL, MSG_EMPTY
    JP PRINT_MSG

; =============================================================================
; MOTOR DO BUFFER DE TEXTO
; -----------------------------------------------------------------------------
; Cada linha é gravada como: [tamanho:1 byte][texto:tamanho bytes], uma após
; a outra, sem separador, a partir de BUFSTART. BUFPTR aponta para o primeiro
; byte livre. LINECOUNT = total de linhas. CURLINE = linha atual (1-based).
; =============================================================================

; Entrada: A = número da linha desejada (1-based)
; Saída:   HL = endereço do byte de tamanho do registro daquela linha,
;          (ou, se A = LINECOUNT+1, HL = BUFPTR, útil para inserir no fim)
;          D  = número da linha alvo (preservado, útil para quem chamou)
;          Carry=1 se A é inválido (0, ou maior que LINECOUNT+1)
FIND_LINE:
    OR A
    JP Z, FL_INVALID
    LD D, A
    LD A, (LINECOUNT)
    INC A
    CP D
    JP C, FL_INVALID            ; D > LINECOUNT+1
    LD HL, BUFSTART
    LD E, 1
FL_LOOP:
    LD A, E
    CP D
    JR Z, FL_FOUND
    LD A, (HL)
    LD C, A
    LD B, 0
    INC BC
    ADD HL, BC
    INC E
    JR FL_LOOP
FL_FOUND:
    OR A                          ; garante Carry=0
    RET
FL_INVALID:
    SCF
    RET

; -----------------------------------------------------------------------------
; Entrada: A = número da linha a apagar
DELETE_LINE:
    CALL FIND_LINE
    RET C
    LD A, (LINECOUNT)
    CP D
    JP C, DL_INVALID             ; D > LINECOUNT -> linha não existe de fato
    LD (T_DEST), HL
    LD A, (HL)
    LD E, A
    LD D, 0
    INC DE
    LD (T_SIZE), DE               ; tamanho do registro (1+tamanho do texto)
    LD HL, (T_DEST)
    ADD HL, DE
    LD (T_SRC), HL                 ; início do próximo registro
    LD HL, (BUFPTR)
    LD DE, (T_SRC)
    OR A
    SBC HL, DE
    LD (T_COUNT), HL                ; bytes que sobraram depois da linha removida
    LD A, H
    OR L
    JR Z, DL_SKIPMOVE
    LD HL, (T_SRC)
    LD DE, (T_DEST)
    LD BC, (T_COUNT)
    LDIR                              ; desloca o resto do buffer para trás
DL_SKIPMOVE:
    LD HL, (BUFPTR)
    LD DE, (T_SIZE)
    OR A
    SBC HL, DE
    LD (BUFPTR), HL
    LD HL, LINECOUNT
    DEC (HL)
    LD A, (CURLINE)
    LD HL, LINECOUNT
    CP (HL)
    JR C, DL_KEEPCUR
    LD A, (HL)
    LD (CURLINE), A                  ; se CURLINE ficou > LINECOUNT, recua
DL_KEEPCUR:
    LD HL, MSG_DELETED
    JP PRINT_MSG
DL_INVALID:
    LD HL, MSG_NOLINE
    JP PRINT_MSG

; -----------------------------------------------------------------------------
; Entrada: A = posição (número de linha, 1..LINECOUNT+1) onde a nova linha
;          deve ficar. LINEBUF = [tamanho][texto] da nova linha (já lida).
; Saída:   Carry=1 se a inserção falhou (posição inválida ou buffer cheio);
;          nesse caso já foi impressa uma mensagem de erro.
ADD_LINE_AT:
    CALL FIND_LINE
    JR NC, AL_POSOK
    LD HL, MSG_MAXLINES          ; ex.: CURLINE estourou 255 (byte) ao incrementar
    CALL PRINT_MSG
    SCF
    RET
AL_POSOK:
    LD (T_DEST_INS), HL
    LD A, (LINEBUF)
    LD E, A
    LD D, 0
    INC DE
    LD (T_SIZE), DE                  ; tamanho do novo registro
    LD HL, (BUFPTR)
    ADD HL, DE
    LD DE, BUFEND
    OR A
    SBC HL, DE
    JP NC, AL_FULL                    ; não cabe no buffer
    LD HL, (BUFPTR)
    LD DE, (T_DEST_INS)
    OR A
    SBC HL, DE
    LD (T_COUNT), HL                   ; bytes existentes que precisam abrir espaço
    LD A, H
    OR L
    JR Z, AL_NOSHIFT
    LD HL, (BUFPTR)
    LD BC, (T_SIZE)
    ADD HL, BC
    DEC HL
    LD D, H
    LD E, L                              ; DE = último byte de destino
    LD HL, (BUFPTR)
    DEC HL                                ; HL = último byte de origem
    LD BC, (T_COUNT)
    LDDR                                   ; abre espaço, copiando de trás pra frente
AL_NOSHIFT:
    LD HL, LINEBUF
    LD DE, (T_DEST_INS)
    LD BC, (T_SIZE)
    LDIR                                    ; grava a nova linha no espaço aberto
    LD HL, (BUFPTR)
    LD DE, (T_SIZE)
    ADD HL, DE
    LD (BUFPTR), HL
    LD HL, LINECOUNT
    INC (HL)
    OR A                                    ; garante Carry=0 (sucesso)
    RET
AL_FULL:
    LD HL, MSG_FULL
    CALL PRINT_MSG
    SCF
    RET

; -----------------------------------------------------------------------------
; Entrada: A = número da linha a exibir. Mostra "NNN: texto".
DISPLAY_LINE:
    PUSH AF
    CALL FIND_LINE
    JP C, DSP_ERR
    POP AF
    CALL PRINT_DEC
    LD A, ':'
    RST 8
    LD A, SPACE
    RST 8
    LD A, (HL)
    LD B, A
    INC HL
    LD A, B
    OR A
    JR Z, DSP_NL
DSP_PRINTCH:
    LD A, (HL)
    RST 8
    INC HL
    DJNZ DSP_PRINTCH
DSP_NL:
    CALL LCD_NEWLINE
    RET
DSP_ERR:
    POP AF
    LD HL, MSG_NOLINE
    JP PRINT_MSG

; =============================================================================
; ENTRADA DE LINHA PELO TECLADO
; =============================================================================
; Lê uma linha do teclado para LINEBUF: [tamanho][texto...][NUL].
; Ecoa cada caractere no LCD. BKS/DEL apaga o último caractere (envia
; BKS,SPACE,BKS para garantir que apague visualmente). ESC cancela a linha.
; Saída: B = tamanho da linha lida. Carry=1 se cancelado com ESC.
READ_LINE:
    LD HL, LINEBUF+1
    LD B, 0
RL_LOOP:
    CALL keyboardWaitA
    LD E, A
    CP ESC
    JR Z, RL_ABORT
    CP CR
    JR Z, RL_DONE
    CP BKS
    JR Z, RL_BACK
    CP DEL
    JR Z, RL_BACK
    CP SPACE
    JR C, RL_LOOP                 ; ignora controles não tratados
    CP 7Fh
    JR NC, RL_LOOP                  ; ignora teclas especiais (0x7F-0xFF)
    LD A, B
    CP MAXLINE
    JR Z, RL_LOOP                    ; linha cheia, ignora tecla
    LD (HL), E
    INC HL
    INC B
    LD A, E
    RST 8
    JR RL_LOOP
RL_BACK:
    LD A, B
    OR A
    JR Z, RL_LOOP
    DEC B
    DEC HL
    LD A, BKS
    RST 8
    JR RL_LOOP
RL_DONE:
    LD A, B
    LD (LINEBUF), A
    LD HL, LINEBUF+1
    LD D, 0
    LD E, B
    ADD HL, DE
    XOR A
    LD (HL), A                       ; termina com NUL (facilita PARSE_NUMBER)
    CALL LCD_NEWLINE
    OR A
    RET
RL_ABORT:
    XOR A
    LD (LINEBUF), A
    LD B, A
    CALL LCD_NEWLINE
    SCF
    RET

; =============================================================================
; UTILITÁRIOS
; =============================================================================
PRINT_PROMPT:
    CALL LCD_NEWLINE
    LD A, '*'
    RST 8
    RET

LCD_NEWLINE:
    LD A, CR
    RST 8
    LD A, LF
    RST 8
    RET


; Imprime string terminada em NUL apontada por HL
PRINT_STR:
    LD A, (HL)
    OR A
    RET Z
    RST 8
    INC HL
    JR PRINT_STR
    
; Imprime string terminada em NUL e adiciona uma quebra de linha
PRINT_MSG:
	LD A,1
	CALL plotAlways

    CALL PRINT_STR
    CALL LCD_NEWLINE
    
    LD A,0
	CALL plotAlways
	CALL plotToLCD
    RET

; Converte A para maiúscula (a-z -> A-Z)
UPCASE:
    CP 'a'
    RET C
    CP 'z'+1
    RET NC
    SUB 20h
    RET

; Imprime A (0-255) em decimal, sem zeros à esquerda
PRINT_DEC:
    LD E, A
    LD B, 0
    LD C, 100
    CALL PD_PLACE
    LD C, 10
    CALL PD_PLACE
    LD A, E
    ADD A, '0'
    RST 8
    RET
PD_PLACE:
    LD D, 0
PD_PLACE_LOOP:
    LD A, E
    CP C
    JR C, PD_PLACE_DONE
    SUB C
    LD E, A
    INC D
    JR PD_PLACE_LOOP
PD_PLACE_DONE:
    LD A, D
    OR A
    JR NZ, PD_PLACE_PRINT
    LD A, B
    OR A
    RET Z                            ; suprime zero à esquerda
PD_PLACE_PRINT:
    LD A, D
    ADD A, '0'
    RST 8
    LD B, 1
    RET

; Entrada: HL = ponteiro para texto ASCII (termina em NUL, CR ou não-dígito)
; Saída:   A = valor decimal (0-255), pula espaços iniciais
;          Carry=1 se o número digitado estourou 255 (inválido)
PARSE_NUMBER:
    XOR A
    LD C, A
PN_SKIPSPACE:
    LD A, (HL)
    CP SPACE
    JR NZ, PN_DIGITS
    INC HL
    JR PN_SKIPSPACE
PN_DIGITS:
    LD A, (HL)
    OR A
    JR Z, PN_DONE
    CP '0'
    JR C, PN_DONE
    CP '9'+1
    JR NC, PN_DONE
    SUB '0'
    LD B, A
    LD A, C
    CP 26                    ; se C>=26, C*10 já estouraria 255 (26*10=260)
    JR NC, PN_OVERFLOW
    ADD A, A
    LD D, A
    ADD A, A
    ADD A, A
    ADD A, D
    ADD A, B
    JR C, PN_OVERFLOW         ; estourou 255 na soma final
    LD C, A
    INC HL
    JR PN_DIGITS
PN_DONE:
    LD A, C
    OR A                      ; garante Carry=0
    RET
PN_OVERFLOW:
    SCF
    RET

; =============================================================================
; MENSAGENS
; =============================================================================
MSG_UNKNOWN:      DB "Comando invalido. H = ajuda", CR, LF, 0
MSG_EMPTY:        DB "Buffer vazio", CR, LF, 0
MSG_NOLINE:       DB "Linha nao existe", CR, LF, 0
MSG_FULL:         DB "Buffer cheio!", CR, LF, 0
MSG_MAXLINES:     DB "Limite de 255 linhas atingido", CR, LF, 0
MSG_DELETED:      DB "Linha apagada", CR, LF, 0
MSG_LASTLINE:     DB "Ja esta na ultima linha", CR, LF, 0
MSG_FIRSTLINE:    DB "Ja esta na primeira linha", CR, LF, 0
MSG_MORE:         DB "--mais-- (ESC p/ parar)", 0
MSG_SENDING:      DB "Enviando pela serial...", CR, LF, 0
MSG_DONE:         DB "Concluido", CR, LF, 0
MSG_BYE:          DB "Saindo do editor...", CR, LF, 0
MSG_INSERT_HELP:  DB "Digite o texto (ENTER vazio termina, ESC cancela)", CR, LF, 0
MSG_CLEAR_CONFIRM:  DB "Limpar tudo? (S/N) ", 0
MSG_CLEARED:        DB "Buffer limpo", CR, LF, 0
MSG_CLEAR_CANCEL:   DB "Cancelado", CR, LF, 0

MSG_HELP:
    DB " --- EDMINI ---", CR, LF
    DB "I=Insere antes linha", CR, LF
	DB "A=Adiciona depois", CR, LF
	DB "D=Apaga linha", CR, LF
    DB "N=Prox P=Ant ", CR, LF
    DB "G<n>=Ir p/ linha", CR, LF
    DB "L=Lista W=Print serialB", CR, LF
    DB "C=Limpar ", CR, LF
    DB "E=Sair H=Ajuda", 0

; =============================================================================
; VARIÁVEIS
; =============================================================================
CURLINE:      DB 0
LINECOUNT:    DB 0
BUFPTR:       DW BUFSTART
INS_POS:      DB 0
LIST_TOTAL:   DB 0
LIST_CUR:     DB 0
LIST_PAGE:    DB 0
T_DEST:       DW 0
T_DEST_INS:   DW 0
T_SRC:        DW 0
T_SIZE:       DW 0
T_COUNT:      DW 0

LINEBUF:      DS 2+MAXLINE     ; [tamanho][texto...][NUL]

; =============================================================================
; ÁREA DE ARMAZENAMENTO DO TEXTO
; =============================================================================
BUFSTART:
    DS BUFSIZE
BUFEND:

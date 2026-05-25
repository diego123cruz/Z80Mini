
; --- Constantes ---
FS_SIG:     .EQU $A5
FS_PG_BMP:  .EQU $00
FS_PG_DIR:  .EQU $01
FS_PG_DATA: .EQU $02        ; primeira pagina de dados
FS_MAXFILES:.EQU 8
FS_ENTRY_SZ:.EQU 32
FS_NAME_SZ: .EQU 8
FS_DATAPG:  .EQU 255        ; bytes uteis por pagina

FS_FLAG_FREE: .EQU $FF
FS_FLAG_USED: .EQU $01

; Offsets na entrada
FS_O_NAME:  .EQU 0
FS_O_FSTPG: .EQU 8
FS_O_SIZEH: .EQU 9
FS_O_SIZEL: .EQU 10
FS_O_RADRH: .EQU 11
FS_O_RADRL: .EQU 12
FS_O_FLAGS: .EQU 13



; **********************************************************************
; FS_DIR
; **********************************************************************
FS_DIR:
    CALL CRLF
    LD HL, str_dir_hdr
    CALL PUTS
    XOR A
    LD (FS_CUR), A
    LD B, FS_MAXFILES
    LD C, 0
FS_DIR_LOOP:
    PUSH BC
    CALL FS_RD_ENTRY
    JP NZ, FS_ERR_I2C_POP
    LD A, (FS_WRKBUF + FS_O_FLAGS)
    CP FS_FLAG_USED
    JR NZ, FS_DIR_SKIP
    LD HL, FS_WRKBUF + FS_O_NAME
    LD B, FS_NAME_SZ
FS_DIR_NM:
    LD A, (HL)
    OR A
    JR Z, FS_DIR_PAD
    RST $08
    INC HL
    DJNZ FS_DIR_NM
    JR FS_DIR_AFT
FS_DIR_PAD:
    LD A, ' '
    RST $08
    INC HL
    DJNZ FS_DIR_PAD
FS_DIR_AFT:
    LD A, ' '
    RST $08
    LD A, (FS_WRKBUF + FS_O_SIZEH)
    CALL HexOut
    LD A, (FS_WRKBUF + FS_O_SIZEL)
    CALL HexOut
    LD A, ' '
    RST $08
    LD A, (FS_WRKBUF + FS_O_RADRH)
    CALL HexOut
    LD A, (FS_WRKBUF + FS_O_RADRL)
    CALL HexOut
    LD A, ' '
    RST $08
    LD A, (FS_WRKBUF + FS_O_FSTPG)
    CALL HexOut
    POP BC
    INC C
    JP FS_DIR_INC
FS_DIR_SKIP:
    POP BC
FS_DIR_INC:
    LD A, (FS_CUR)
    INC A
    LD (FS_CUR), A
    DJNZ FS_DIR_LOOP
    LD A, C
    OR A
    JR NZ, FS_DIR_CNT
    LD HL, str_empty
    CALL PUTS
    RET
FS_DIR_CNT:
    CALL HexOut
    LD HL, str_nfiles
    CALL PUTS
    RET

; **********************************************************************
; FS_LOAD_CMD
; **********************************************************************
FS_LOAD_CMD:
    CALL FS_COPY_NAME_FROM_BUFFER
    JP C, FS_ABORT
    CALL CRLF
    CALL FS_FIND_NAME
    JP Z, FS_LOAD_DO
    LD HL, str_notfound
    CALL PUTS
    RET

FS_LOAD_DO:
    CALL FS_DO_LOAD
    JP NZ, FS_ERR_I2C
    LD HL, str_loadat
    CALL PUTS
    LD A, (FS_WRKBUF + FS_O_RADRH)
    CALL HexOut
    LD A, (FS_WRKBUF + FS_O_RADRL)
    CALL HexOut
    LD A, 'h'
    RST $08
    CALL CRLF
    RET

; FS_DO_LOAD - carrega arquivo (FS_WRKBUF preenchido)
;   On exit: Z=OK  NZ=erro
FS_DO_LOAD:
    LD A, (FS_WRKBUF + FS_O_RADRH)
    LD H, A
    LD A, (FS_WRKBUF + FS_O_RADRL)
    LD L, A
    LD (FS_TMPRAM), HL      ; destino RAM
    LD A, (FS_WRKBUF + FS_O_SIZEH)
    LD H, A
    LD A, (FS_WRKBUF + FS_O_SIZEL)
    LD L, A
    LD (FS_TMPSZ), HL       ; bytes restantes
    LD A, (FS_WRKBUF + FS_O_FSTPG)
    LD (FS_CURPG), A

FS_DL_PG:
    LD A, (FS_CURPG)
    OR A
    JR Z, FS_DL_DONE

    ; Le byte 0 (next page)
    LD D, A
    LD E, 0
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemRd
    RET NZ

    ; min(FS_TMPSZ, 255) bytes a ler
    LD HL, (FS_TMPSZ)
    LD A, H
    OR A
    JR NZ, FS_DL_255
    LD A, L
    CP FS_DATAPG
    JR C, FS_DL_LT
FS_DL_255:
    LD BC, FS_DATAPG
    JR FS_DL_RD
FS_DL_LT:
    LD B, 0
    LD C, L

FS_DL_RD:
    ; BC=bytes, DE=pag*256+1, HL=destino
    PUSH BC
    LD A, (FS_CURPG)
    LD D, A
    LD E, 1
    LD HL, (FS_TMPRAM)
    CALL I2C_MemRd
    POP BC
    RET NZ

    ; Atualiza ponteiros
    LD HL, (FS_TMPRAM)
    ADD HL, BC
    LD (FS_TMPRAM), HL
    LD HL, (FS_TMPSZ)
    OR A                    ; limpa carry
    SBC HL, BC
    LD (FS_TMPSZ), HL

    ; Proxima pagina
    LD A, (FS_TMP1)
    LD (FS_CURPG), A
    JR FS_DL_PG

FS_DL_DONE:
    XOR A
    RET


; **********************************************************************
; FS_SAVE
; 
; save name xxxx xxxx
; Comando Nome End.Ram Tamanho
; **********************************************************************
FS_SAVE:
    CALL FS_COPY_NAME_FROM_BUFFER
    JP C, FS_ABORT
    
    ; pega endereço inicial XXXX
    CALL SKIP_SPACES_DE
    CALL PARSE_HEX16_DE
    JP C, FS_ABORT
    LD (FS_TMPRAM), HL
    ; pega tamanho XXXX
    CALL SKIP_SPACES_DE
    CALL PARSE_HEX16_DE
    JP C, FS_ABORT
    LD A, H
    OR L
    JP Z, FS_ABORT
    LD (FS_TMPSZ), HL
    CALL CRLF

    ; Nome ja existe?
    CALL FS_FIND_NAME
    JP Z, FS_SV_OVERW
    CALL FS_FIND_FREE
    JP NZ, FS_ERR_FULL
    JP FS_SV_DO

FS_SV_OVERW:
    LD A, (FS_WRKBUF + FS_O_FSTPG)
    OR A
    JP Z, FS_SV_DO
    CALL FS_FREE_CHAIN
    JP NZ, FS_ERR_I2C

FS_SV_DO:
    LD A, (FS_CUR)
    LD (FS_SLOTBK), A

    ; Zera e monta FS_WRKBUF
    LD HL, FS_WRKBUF
    LD B, FS_ENTRY_SZ
    XOR A
FS_SV_CLR:
    LD (HL), A
    INC HL
    DJNZ FS_SV_CLR

    LD HL, FS_NAMBUF
    LD IX, FS_WRKBUF
    LD B, FS_NAME_SZ
FS_SV_NM:
    LD A, (HL)
    LD (IX+0), A
    INC IX
    INC HL
    DJNZ FS_SV_NM

    LD HL, (FS_TMPSZ)
    LD A, H
    LD (FS_WRKBUF + FS_O_SIZEH), A
    LD A, L
    LD (FS_WRKBUF + FS_O_SIZEL), A
    LD HL, (FS_TMPRAM)
    LD A, H
    LD (FS_WRKBUF + FS_O_RADRH), A
    LD A, L
    LD (FS_WRKBUF + FS_O_RADRL), A
    LD A, FS_FLAG_USED
    LD (FS_WRKBUF + FS_O_FLAGS), A

    ; Aloca primeira pagina
    CALL FS_ALLOC_PG
    JP Z, FS_ERR_NOSPACE
    LD (FS_WRKBUF + FS_O_FSTPG), A
    LD (FS_CURPG), A

FS_SV_LOOP:
    LD A, (FS_CURPG)
    CALL FS_WRITE_PG
    JP NZ, FS_ERR_I2C
    LD HL, (FS_TMPSZ)
    LD A, H
    OR L
    JP Z, FS_SV_DONE
    ; Aloca proxima pagina
    CALL FS_ALLOC_PG
    JP Z, FS_ERR_NOSPACE
    LD B, A                 ; B = proxima pagina
    LD A, (FS_CURPG)
    CALL FS_SET_NEXT        ; byte 0 da pagina A = B
    JP NZ, FS_ERR_I2C
    LD A, B
    LD (FS_CURPG), A
    JP FS_SV_LOOP

FS_SV_DONE:
    LD A, (FS_SLOTBK)
    LD (FS_CUR), A
    CALL FS_WR_ENTRY
    JP NZ, FS_ERR_I2C
    LD HL, str_saved
    CALL PUTS
    RET


; **********************************************************************
; FS_EXEC
; **********************************************************************
FS_EXEC:
    CALL FS_COPY_NAME_FROM_BUFFER
    JP C, FS_ABORT
    CALL CRLF
    CALL FS_FIND_NAME
    JP Z, FS_EX_DO
    LD HL, str_notfound
    CALL PUTS
    RET
FS_EX_DO:
    LD A, (FS_WRKBUF + FS_O_RADRH)
    LD H, A
    LD A, (FS_WRKBUF + FS_O_RADRL)
    LD L, A
    PUSH HL
    CALL FS_DO_LOAD
    JP NZ, FS_EX_ERR
    LD HL, str_running
    CALL PUTS
    POP HL
    JP (HL)
FS_EX_ERR:
    POP HL
    JP FS_ERR_I2C



; **********************************************************************
; FS_ERASE
; **********************************************************************
FS_ERASE:
    CALL FS_COPY_NAME_FROM_BUFFER
    JP C, FS_ABORT
    CALL CRLF
    CALL FS_FIND_NAME
    JP Z, FS_ER_FOUND
    LD HL, str_notfound
    CALL PUTS
    RET
FS_ER_FOUND:
    LD HL, FS_NAMBUF
    LD B, FS_NAME_SZ
FS_ER_NM:
    LD A, (HL)
    OR A
    JP Z, FS_ER_CFM
    RST $08
    INC HL
    DJNZ FS_ER_NM
FS_ER_CFM:
    LD HL, str_sure
    CALL PUTS
    RST $10
    RST $08
    AND $5F
    CP 'S'
    JP NZ, FS_ABORT
    CALL CRLF
    LD A, (FS_WRKBUF + FS_O_FSTPG)
    OR A
    JP Z, FS_ER_DIR
    CALL FS_FREE_CHAIN
    JP NZ, FS_ERR_I2C
FS_ER_DIR:
    LD HL, FS_WRKBUF
    LD B, FS_ENTRY_SZ
    XOR A
FS_ER_CLR:
    LD (HL), A
    INC HL
    DJNZ FS_ER_CLR
    LD A, FS_FLAG_FREE
    LD (FS_WRKBUF + FS_O_FLAGS), A
    CALL FS_WR_ENTRY
    JP NZ, FS_ERR_I2C
    LD HL, str_erased
    CALL PUTS
    RET



; **********************************************************************
; FS_FORMAT
; **********************************************************************
FS_FORMAT:
    LD HL, str_fmt_ask
    CALL PUTS
    RST $10
    RST $08
    AND $5F
    CP 'S'
    RET NZ
    CALL CRLF
    LD HL, str_wait
    CALL PUTS

    ; Pagina 0: assinatura + bitmap
    ; Pags 0,1 ocupadas (bits 0,1 do byte 1 = 0): byte1 = 11111100 = $FC
    LD HL, PG_BUF
    LD (HL), FS_SIG
    INC HL
    LD (HL), $FC
    INC HL
    LD B, 14                ; bytes 2..15 = $FF
FS_FMT_1:
    LD (HL), $FF
    INC HL
    DJNZ FS_FMT_1
    LD B, 240               ; bytes 16..255 = $FF
FS_FMT_2:
    LD (HL), $FF
    INC HL
    DJNZ FS_FMT_2

    LD DE, $0000
    LD HL, PG_BUF
    LD BC, 256
    CALL I2C_MemWr
    JP NZ, FS_ERR_I2C

    ; Pagina 1: diretorio todo $FF (entradas livres)
    LD HL, PG_BUF
    LD B, 0                 ; 256 iteracoes (B=0: DJNZ decrementa para 255, depois 0 = 256 total)
FS_FMT_3:
    LD (HL), $FF
    INC HL
    DJNZ FS_FMT_3

    LD DE, $0100
    LD HL, PG_BUF
    LD BC, 256
    CALL I2C_MemWr
    JP NZ, FS_ERR_I2C
    LD HL, str_ok
    CALL PUTS
    RET


; **********************************************************************
; FS_CHK_SIG - Z=formatada NZ=nao
; **********************************************************************
FS_CHK_SIG:
    PUSH BC
    PUSH DE
    PUSH HL
    LD DE, $0000
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemRd
    POP HL
    POP DE
    POP BC
    RET NZ
    LD A, (FS_TMP1)
    CP FS_SIG
    RET
























; **********************************************************************
; FUNCOES INTERNAS
; **********************************************************************

; Preenche FS_NAMBUF com NUL, depois copia buffer em DE até NUL(0) ou SPACE
; Nome não pode ter espaços e Diego != diego
FS_COPY_NAME_FROM_BUFFER:
    LD B, FS_NAME_SZ + 1
    LD HL, FS_NAMBUF
    XOR A
FS_CLEAR_NUL:
    LD (HL), A
    INC HL
    djnz FS_CLEAR_NUL

    LD B, FS_NAME_SZ + 1
    LD HL, FS_NAMBUF
FS_COPY_NAME_FROM_BUFFER_LOOP:
    LD A, (DE)
    CP NUL
    RET Z
    CP SPACE
    RET Z
    LD (HL), A
    INC HL
    INC DE
    djnz FS_COPY_NAME_FROM_BUFFER_LOOP
    RET

; FS_RD_ENTRY: Le entrada FS_CUR → FS_WRKBUF
;   EEPROM addr = $0100 + FS_CUR*32
;   On exit: Z=OK  NZ=erro
FS_RD_ENTRY:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (FS_CUR)
    RLCA
    RLCA
    RLCA
    RLCA
    RLCA                    ; A = FS_CUR * 32
    LD E, A
    LD D, $01
    LD HL, FS_WRKBUF
    LD BC, FS_ENTRY_SZ
    CALL I2C_MemRd
    POP HL
    POP DE
    POP BC
    RET


; FS_WR_ENTRY: Grava FS_WRKBUF → EEPROM posicao FS_CUR
;   On exit: Z=OK  NZ=erro
FS_WR_ENTRY:
    PUSH BC
    PUSH DE
    PUSH HL
    LD A, (FS_CUR)
    RLCA
    RLCA
    RLCA
    RLCA
    RLCA
    LD E, A
    LD D, $01
    LD HL, FS_WRKBUF
    LD BC, FS_ENTRY_SZ
    CALL I2C_MemWr
    POP HL
    POP DE
    POP BC
    RET


; FS_FIND_FREE: Acha slot livre no diretorio
;   On exit: Z=encontrado (FS_CUR=idx)  NZ=cheio
FS_FIND_FREE:
    XOR A
    LD (FS_CUR), A
    LD B, FS_MAXFILES
FS_FF_LP:
    PUSH BC
    CALL FS_RD_ENTRY
    JP NZ, FS_FF_ERR
    LD A, (FS_WRKBUF + FS_O_FLAGS)
    CP FS_FLAG_FREE
    JP Z, FS_FF_FOUND
    LD A, (FS_CUR)
    INC A
    LD (FS_CUR), A
    POP BC
    DJNZ FS_FF_LP
    LD A, 1
    OR A
    RET
FS_FF_FOUND:
    POP BC
    XOR A
    RET
FS_FF_ERR:
    POP BC
    LD A, ERR_TOUT
    OR A
    RET



; FS_ALLOC_PG: Aloca primeira pagina livre (>=2) no bitmap
;   Registradores: B=pagina, C=bit_index, D=byte_bitmap, E=byte_index, HL=ptr
;   On exit: A=pagina (NZ=ok)   A=0 (Z=sem espaco)
FS_ALLOC_PG:
    ; Le os 16 bytes do bitmap para PG_BUF
    LD DE, $0001
    LD HL, PG_BUF
    LD BC, 16
    CALL I2C_MemRd
    RET NZ

    LD B, 2                 ; B = pagina corrente

FS_AP_LOOP:
    LD A, B
    AND $07
    LD C, A                 ; C = bit_index

    LD A, B
    SRL A
    SRL A
    SRL A
    LD E, A                 ; E = byte_index

    LD HL, PG_BUF
    LD D, 0
    ADD HL, DE
    LD D, (HL)              ; D = byte do bitmap

    LD A, 1
FS_AP_TBIT:
    DEC C
    JP M, FS_AP_TBIT_DONE
    RLCA
    JR FS_AP_TBIT
FS_AP_TBIT_DONE:
    AND D                   ; 0=ocupado, !=0=livre
    JR NZ, FS_AP_FOUND

    INC B
    LD A, B
    CP 128
    JR C, FS_AP_LOOP
    XOR A                   ; Z = sem espaco
    RET

FS_AP_FOUND:
    ; B = pagina livre. Salva bit_index e byte_index.
    LD A, B
    AND $07
    LD (FS_BMPADDR+1), A    ; bit_index

    LD A, B
    SRL A
    SRL A
    SRL A
    LD E, A                 ; E = byte_index

    ; HL = PG_BUF + byte_index
    LD HL, PG_BUF
    LD D, 0
    ADD HL, DE

    ; Mascara = ~(1 << bit_index) para zerar o bit
    LD A, (FS_BMPADDR+1)
    LD C, A
    LD A, 1
FS_AP_MKSHL:
    DEC C
    JP M, FS_AP_MKINV
    RLCA
    JR FS_AP_MKSHL
FS_AP_MKINV:
    CPL                     ; ~mascara

    AND (HL)
    LD (HL), A              ; atualiza PG_BUF

    ; Salva numero da pagina antes do LD BC,1 destruir B
    LD A, B
    LD (FS_BMPADDR), A

    ; Grava byte atualizado na EEPROM: addr = byte_index + 1
    LD D, 0
    INC E                   ; E = byte_index + 1
    LD BC, 1
    CALL I2C_MemWr
    RET NZ

    LD A, (FS_BMPADDR)      ; A = pagina alocada
    OR A                    ; NZ = sucesso
    RET

; FS_FREE_PG: Libera pagina A no bitmap (seta bit = 1)
;   On exit: Z=OK  NZ=erro I2C
FS_FREE_PG:
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH AF                 ; salva numero da pagina

    ; bit_index = pagina mod 8
    AND $07
    LD C, A                 ; C = bit_index

    ; byte_index = pagina / 8 → endereco EEPROM = byte_index + 1
    POP AF
    PUSH AF
    SRL A
    SRL A
    SRL A                   ; A = byte_index
    INC A                   ; A = endereco EEPROM (1..16)
    LD (FS_BMPADDR), A      ; salva endereco

    ; Le byte atual do bitmap
    ; ATENCAO: LD BC,1 vai sobrescrever C (bit_index)!
    ; Salva C na RAM antes.
    LD A, C
    LD (FS_BMPADDR+1), A    ; salva bit_index em FS_BMPADDR+1

    LD A, (FS_BMPADDR)
    LD E, A
    LD D, 0
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemRd
    JP NZ, FS_FP_ERR

    ; Recupera bit_index
    LD A, (FS_BMPADDR+1)
    LD C, A                 ; C = bit_index restaurado

    ; Constroi mascara = 1 << bit_index
    LD A, 1
FS_FP_SHL:
    DEC C
    JP M, FS_FP_OR
    RLCA
    JR FS_FP_SHL

FS_FP_OR:
    LD B, A
    LD A, (FS_TMP1)
    OR B                    ; seta o bit (marca pagina como livre)
    LD (FS_TMP1), A

    ; Grava
    LD A, (FS_BMPADDR)
    LD E, A
    LD D, 0
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemWr
    JR FS_FP_DONE

FS_FP_ERR:
    POP AF
    POP HL
    POP DE
    POP BC
    LD A, 1
    OR A
    RET

FS_FP_DONE:
    POP AF
    POP HL
    POP DE
    POP BC
    RET

; FS_FREE_CHAIN: Libera cadeia de paginas a partir da pagina A
;   On exit: Z=OK  NZ=erro
FS_FREE_CHAIN:
    OR A
    RET Z

FS_FC_LP:
    LD (FS_BMPADDR), A      ; salva pagina corrente

    ; Primeiro le o next page (antes de liberar)
    LD D, A
    LD E, 0
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemRd
    JR NZ, FS_FC_ERR

    ; Salva next page no stack (FS_FREE_PG vai usar FS_BMPADDR/+1)
    LD A, (FS_TMP1)
    PUSH AF                 ; [1] next page

    ; Pequeno delay para o barramento I2C se estabilizar entre as operacoes
    ; Abre e fecha a EEPROM ate receber ACK (write cycle polling)
FS_FC_WAIT:
    LD A, $AE
    CALL I2C_Open
    CALL I2C_Close
    JR NZ, FS_FC_WAIT       ; aguarda EEPROM pronta

    ; Libera a pagina
    LD A, (FS_BMPADDR)
    CALL FS_FREE_PG
    JR NZ, FS_FC_ERR2

    POP AF                  ; [1] A = next page
    OR A
    JR NZ, FS_FC_LP         ; continua na proxima pagina

    XOR A
    RET

FS_FC_ERR:
    LD HL, str_fc_err
    CALL PUTS
    LD A, 1
    OR A
    RET
FS_FC_ERR2:
    POP AF                  ; [1]
    LD HL, str_fc_err
    CALL PUTS
    LD A, 1
    OR A
    RET

str_fc_err:  .TEXT "FC ERRO!"
             .DB CR, LF, 0



; FS_WRITE_PG: Grava pagina A com dados de FS_TMPRAM
;   Grava min(FS_TMPSZ, 255) bytes. Atualiza FS_TMPRAM e FS_TMPSZ.
;   byte 0 da pagina = $00 (next=fim; FS_SET_NEXT corrige se necessario)
;   On exit: Z=OK  NZ=erro
;   Preserva: BC DE HL
FS_WRITE_PG:
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH AF                 ; A = numero da pagina

    ; Calcula quantos bytes gravar: min(FS_TMPSZ, 255)
    LD HL, (FS_TMPSZ)
    LD A, H
    OR A
    JR NZ, FS_WP_USE255     ; HL >= 256: usa 255
    LD A, L
    CP FS_DATAPG            ; L < 255?
    JR C, FS_WP_USELT       ; sim: usa L
FS_WP_USE255:
    LD C, FS_DATAPG         ; C = 255
    JR FS_WP_COPY
FS_WP_USELT:
    LD C, L                 ; C = L (< 255)

FS_WP_COPY:
    ; C = bytes a gravar (1..255). Salva em D para nao perder.
    LD D, C                 ; D = bytes a gravar

    ; Monta PG_BUF[0..$FF]:
    ;   [0]    = $00 (next page, sera corrigido por FS_SET_NEXT)
    ;   [1..C] = dados da RAM
    ;   [C+1..$FF] = $FF (padding)
    LD HL, PG_BUF
    LD (HL), $00            ; byte 0 = next = $00
    INC HL                  ; HL = PG_BUF + 1

    ; Copia D bytes de FS_TMPRAM para PG_BUF+1
    ; Usa IX como ponteiro de origem (LD BC,(nn) pode nao funcionar no zasm)
    LD IX, (FS_TMPRAM)      ; IX = ponteiro RAM origem
    LD E, D                 ; E = contador de copia
FS_WP_CPLOOP:
    LD A, (IX+0)            ; le da RAM origem
    LD (HL), A              ; grava no PG_BUF
    INC IX
    INC HL
    DEC E
    JR NZ, FS_WP_CPLOOP

    ; Padding $FF ate completar 256 bytes (posicoes D+1 a 255)
    ; Bytes de padding = 255 - D
    LD A, FS_DATAPG         ; 255
    SUB D                   ; A = 255 - D (bytes de padding)
    JR Z, FS_WP_NOPAD       ; sem padding (D=255, pagina cheia)
    LD E, A
FS_WP_PADLOOP:
    LD (HL), $FF
    INC HL
    DEC E
    JR NZ, FS_WP_PADLOOP
FS_WP_NOPAD:

    ; Grava PG_BUF inteiro (256 bytes) na EEPROM
    ; Endereco EEPROM = pagina * 256 (D = pagina, E = 0)
    POP AF                  ; A = numero da pagina
    PUSH AF
    LD D, A
    LD E, 0
    LD HL, PG_BUF
    LD BC, 256
    CALL I2C_MemWr
    JP NZ, FS_WP_ERR

    ; Atualiza FS_TMPRAM += D_bytes_gravados
    POP AF                  ; A = pagina (descarta)
    POP HL                  ; restaura HL original
    POP DE                  ; restaura DE original
    POP BC                  ; restaura BC original

    ; Recalcula com D = bytes gravados
    ; D foi preservado? Nao — foi sobrescrito por LD D, A (pagina).
    ; Usamos FS_TMPSZ antes e depois para calcular o que foi gravado:
    ; bytes_gravados = min(TMPSZ_antes, 255)
    ; Mais simples: relemos FS_TMPSZ e FS_TMPRAM e atualizamos
    ; Mas D foi sobrescrito... precisamos salvar D antes do I2C_MemWr.
    ; SOLUCAO: salvar D (bytes) em FS_TMP1 antes de gravar.
    ; Para nao refatorar todo o fluxo acima, usamos um truque:
    ; bytes_gravados = FS_TMPSZ se < 255, ou 255 se >= 255.
    ; Recalcula de FS_TMPSZ:
    LD HL, (FS_TMPSZ)
    LD A, H
    OR A
    JR NZ, FS_WP_UPD255
    LD A, L
    CP FS_DATAPG
    JR C, FS_WP_UPDLT
FS_WP_UPD255:
    LD BC, FS_DATAPG        ; bytes gravados = 255
    JR FS_WP_UPDATE
FS_WP_UPDLT:
    LD B, 0
    LD C, L                 ; bytes gravados = L

FS_WP_UPDATE:
    ; FS_TMPRAM += BC
    LD HL, (FS_TMPRAM)
    ADD HL, BC
    LD (FS_TMPRAM), HL
    ; FS_TMPSZ -= BC
    LD HL, (FS_TMPSZ)
    OR A                    ; limpa carry
    SBC HL, BC
    LD (FS_TMPSZ), HL
    XOR A                   ; Z = sucesso
    RET

FS_WP_ERR:
    POP AF
    POP HL
    POP DE
    POP BC
    LD A, 1
    OR A
    RET

; FS_SET_NEXT: Escreve byte 0 da pagina A com valor B
;   On exit: Z=OK  NZ=erro
FS_SET_NEXT:
    PUSH BC
    PUSH DE
    PUSH HL
    LD D, A
    LD E, 0
    LD A, B
    LD (FS_TMP1), A
    LD HL, FS_TMP1
    LD BC, 1
    CALL I2C_MemWr
    POP HL
    POP DE
    POP BC
    RET



; FS_FIND_NAME: Busca FS_NAMBUF no diretorio
;   On exit: Z=encontrado (FS_CUR=idx, FS_WRKBUF=entrada)
;            NZ=nao encontrado
FS_FIND_NAME:
    XOR A
    LD (FS_CUR), A
    LD B, FS_MAXFILES
FS_FN_LP:
    PUSH BC
    CALL FS_RD_ENTRY
    JP NZ, FS_FN_ERR
    LD A, (FS_WRKBUF + FS_O_FLAGS)
    CP FS_FLAG_USED
    JR NZ, FS_FN_NXT
    LD HL, FS_NAMBUF
    LD DE, FS_WRKBUF + FS_O_NAME
    LD C, FS_NAME_SZ
FS_FN_CMP:
    LD   A, (HL)
    LD   B, A
    LD   A, (DE)
    CP   B
    JP  NZ, FS_FN_NXT
    INC HL
    INC DE
    DEC C
    JR NZ, FS_FN_CMP
    POP BC
    XOR A
    RET
FS_FN_NXT:
    LD A, (FS_CUR)
    INC A
    LD (FS_CUR), A
    POP BC
    DJNZ FS_FN_LP
    LD A, 1
    OR A
    RET
FS_FN_ERR:
    POP BC
    LD A, ERR_TOUT
    OR A
    RET


; **********************************************************************
; Handlers de erro comuns
; **********************************************************************
FS_ERR_I2C:
    LD HL, str_i2cerr
    CALL PUTS
    RET
FS_ERR_I2C_POP:
    POP BC
    LD HL, str_i2cerr
    CALL PUTS
    RET
FS_ERR_FULL:
    LD HL, str_dirfull
    CALL PUTS
    RET
FS_ERR_NOSPACE:
    LD HL, str_nospace
    CALL PUTS
    RET
FS_ABORT:
    LD HL, str_abort
    CALL PUTS
    RET


; **********************************************************************
; STRINGS
; **********************************************************************
str_empty:
    .TEXT "(vazio)"
    .DB CR, 0

str_nfiles:
    .TEXT " arquivo(s)"
    .DB CR, 0

str_i2cerr:
    .TEXT "Erro I2C!"
    .DB CR, 0

str_dirfull:
    .TEXT "Diretorio cheio! (max 8)"
    .DB CR, 0

str_nospace:
    .TEXT "Sem espaco na EEPROM!"
    .DB CR, 0

str_abort:
    .TEXT "Cancelado."
    .DB CR, 0

str_notfound:
    .TEXT "Nao encontrado."
    .DB CR, 0

str_running:
    .TEXT "Executando..."
    .DB CR, 0

str_saved:
    .TEXT "Arquivo salvo!"
    .DB CR, 0

str_sure:
    .TEXT " - Confirmar (S/N)? "
    .DB CR, 0

str_erased:
    .TEXT "Apagado."
    .DB CR, 0

str_fmt_ask:
    .TEXT "Formatar? Apaga tudo. (S/N):"
    .DB CR, 0
str_wait:
    .TEXT "Aguarde..."
    .DB CR, 0
str_ok:
    .TEXT "OK."
    .DB CR, 0

str_loadat:
    .TEXT "Carregado em: "
    .DB CR, 0

str_notfmt:
    .TEXT "EEPROM nao formatada. Use FORMAT."
    .DB CR, 0

str_dir_hdr:
    .TEXT "NAME-SIZE-LOAD-1aPAG"
    .DB CR, 0
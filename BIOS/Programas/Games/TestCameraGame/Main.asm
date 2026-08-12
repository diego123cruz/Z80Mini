#include "../../Z80MiniAPI.asm"

; ============================================================
; Z80Mini - Demo de "Câmera" estilo Game Boy
; ------------------------------------------------------------
; Mundo virtual: 256x256 pixels (32x32 tiles de 8x8)
; Tela física:   128x64 pixels (o LCD do Z80Mini)
; Personagem:    círculo 8x8 que anda livre pelo mundo
;
; IDEIA CENTRAL:
;   - O mundo inteiro mora na RAM como um MAPA DE TILES (1 byte
;     por tile = 1024 bytes), não como um bitmap gigante.
;   - A cada frame, calculamos qual "janela" 128x64 do mundo a
;     câmera está enquadrando (camX, camY = canto superior
;     esquerdo da janela, em pixels do mundo).
;   - Só desenhamos os tiles que caem dentro dessa janela,
;     "recortando" onde necessário.
;   - Como a câmera pode parar em qualquer pixel (não só
;     múltiplos de 8), os tiles quase sempre caem meio
;     deslocados na tela -> precisamos de um blit com shift de
;     bits entre bytes (mesma ideia do bug de largura não
;     múltipla de 8 que você já resolveu no drawGraphic).
;
; Como o mundo é 256x256, TODAS as coordenadas (player, câmera,
; tiles) cabem num único byte (0-255) - não precisa de conta em
; 16 bits pra posição. É por isso que 256 foi escolhido.
;
; Os pontos marcados com TODO devem ser ligados às rotinas reais
; do seu firmware (scanner de teclado, flush pro ST7920, etc).
; ============================================================

    ORG $8000           ; ajuste para o endereço real do seu ROM/RAM

; ---------------- Constantes ----------------
SCR_W       EQU 128
SCR_H       EQU 64
SCR_STRIDE  EQU SCR_W/8          ; 16 bytes por linha do framebuffer
FB_SIZE     EQU SCR_STRIDE*SCR_H ; 1024 bytes

TILE_SIZE   EQU 8
MAP_W       EQU 32              ; 32*8 = 256
MAP_H       EQU 32
MAP_SIZE    EQU MAP_W*MAP_H     ; 1024 bytes

; a câmera tenta centralizar o player na tela
CAM_OFFX    EQU (SCR_W-TILE_SIZE)/2   ; 60
CAM_OFFY    EQU (SCR_H-TILE_SIZE)/2   ; 28
CAM_MAXX    EQU 256-SCR_W             ; 128  (limite direito da câmera)
CAM_MAXY    EQU 256-SCR_H             ; 192  (limite inferior da câmera)
PLAYER_MAXX EQU 256-TILE_SIZE         ; 248
PLAYER_MAXY EQU 256-TILE_SIZE         ; 248

framebuf	equ $F784

; ============================================================
; PONTO DE ENTRADA
; ============================================================
start:
    CALL BuildMap
main_loop:
    CALL ReadInput          ; TODO: ligar ao scanner de teclado real
    CALL UpdateCamera
    CALL ClearFB
    CALL DrawVisibleTiles
    CALL DrawPlayer
    CALL FlushFB            ; TODO: ligar à rotina real de LCD (ST7920)
    JP main_loop

; ============================================================
; BuildMap - preenche a borda do mapa com parede (id=1)
; ============================================================
BuildMap:
	LD BC, MAP_SIZE
	LD DE, map_data
	LD HL, mapa1
	LDIR
	RET




    LD HL,map_data
    LD B,MAP_W
bm_top:
    LD (HL),1
    INC HL
    DJNZ bm_top

    LD HL,map_data+(MAP_H-1)*MAP_W
    LD B,MAP_W
bm_bottom:
    LD (HL),1
    INC HL
    DJNZ bm_bottom

    LD HL,map_data
    LD B,MAP_H
bm_sides:
    LD (HL),1
    PUSH HL
    LD DE,MAP_W-1
    ADD HL,DE
    LD (HL),1
    POP HL
    LD DE,MAP_W
    ADD HL,DE
    DJNZ bm_sides
    RET

; ============================================================
; UpdateCamera - centraliza a câmera no player, limitada às
; bordas do mundo (0..CAM_MAXX / 0..CAM_MAXY)
; ============================================================
UpdateCamera:
    LD A,(playerX)
    SUB CAM_OFFX
    JR NC,cam_x_pos
    XOR A
cam_x_pos:
    CP CAM_MAXX+1
    JR C,cam_x_done
    LD A,CAM_MAXX
cam_x_done:
    LD (camX),A

    LD A,(playerY)
    SUB CAM_OFFY
    JR NC,cam_y_pos
    XOR A
cam_y_pos:
    CP CAM_MAXY+1
    JR C,cam_y_done
    LD A,CAM_MAXY
cam_y_done:
    LD (camY),A
    RET

; ============================================================
; ClearFB - zera o framebuffer local
; ============================================================
ClearFB:
    LD HL,framebuf
    LD (HL),0
    LD DE,framebuf+1
    LD BC,FB_SIZE-1
    LDIR
    RET

; ============================================================
; DrawVisibleTiles - percorre só os tiles que aparecem na
; janela da câmera e chama DrawTile8x8 pra cada um
; ============================================================
DrawVisibleTiles:
    LD A,(camX)
    LD B,A
    SRL A
    SRL A
    SRL A
    LD (tx_start),A
    LD A,B
    ADD A,SCR_W-1
    SRL A
    SRL A
    SRL A
    LD (tx_end),A

    LD A,(camY)
    LD B,A
    SRL A
    SRL A
    SRL A
    LD (ty_start),A
    LD A,B
    ADD A,SCR_H-1
    SRL A
    SRL A
    SRL A
    LD (ty_end),A

    LD A,(ty_start)
    LD (ty_cur),A
dvt_row_loop:
    LD A,(tx_start)
    LD (tx_cur),A
dvt_col_loop:
    ; endereço no mapa = ty_cur*32 + tx_cur
    LD A,(ty_cur)
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL           ; *32
    LD A,(tx_cur)
    LD E,A
    LD D,0
    ADD HL,DE
    LD DE,map_data
    ADD HL,DE
    LD A,(HL)            ; A = id do tile

    ; ponteiro do tile = tiles_table + id*2
    LD L,A
    LD H,0
    ADD HL,HL
    LD DE,tiles_table
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    EX DE,HL             ; HL = ponteiro real do tile

    ; screenX = tx_cur*8 - camX
    LD A,(tx_cur)
    ADD A,A
    ADD A,A
    ADD A,A
    LD B,A
    LD A,(camX)
    LD C,A
    LD A,B
    SUB C
    LD E,A               ; E = screenX (com sinal)

    ; screenY = ty_cur*8 - camY
    LD A,(ty_cur)
    ADD A,A
    ADD A,A
    ADD A,A
    LD B,A
    LD A,(camY)
    LD C,A
    LD A,B
    SUB C
    LD D,A               ; D = screenY (com sinal)

    CALL DrawTile8x8

    LD A,(tx_cur)
    INC A
    LD (tx_cur),A
    LD B,A
    LD A,(tx_end)
    CP B
    JR NC,dvt_col_loop

    LD A,(ty_cur)
    INC A
    LD (ty_cur),A
    LD B,A
    LD A,(ty_end)
    CP B
    JR NC,dvt_row_loop
    RET

; ============================================================
; DrawPlayer - desenha o círculo 8x8 na posição relativa à
; câmera (a câmera é clampada, então o player sempre cabe
; inteiro na tela)
; ============================================================
DrawPlayer:
    LD A,(playerX)
    LD B,A
    LD A,(camX)
    LD C,A
    LD A,B
    SUB C
    LD E,A
    LD A,(playerY)
    LD B,A
    LD A,(camY)
    LD C,A
    LD A,B
    SUB C
    LD D,A
    
    ;LD HL, sprite_player
    ;CALL DrawTile8x8
    ;RET
    
    LD A, (diego)
    CP 0
    CALL Z, p1
    CP 2
    CALL Z, p2
    
    
    INC A
    LD (diego), A
    CP 4
    CALL Z, p0
    
    
	LD HL, (player)
    CALL DrawTile8x8
    RET
    
p0:
	LD A, 0
	LD (diego), A
	ret

p1:
	LD HL, teste
	LD (player), HL
	ret

p2:
	LD HL, teste+8
	LD (player), HL
	ret

; ============================================================
; DrawTile8x8 - desenha um tile/sprite 8x8 no framebuffer com
; CLIPPING (corta o que sai da tela) e SHIFT horizontal de
; sub-pixel (0-7 bits, pra quando a posição não é múltiplo de 8)
;
; Entrada: HL = ponteiro pros 8 bytes do tile
;          D  = screenY (com sinal, tipicamente -7..63)
;          E  = screenX (com sinal, tipicamente -7..127)
;
; Essa é a mesma ideia do ajuste de largura não-múltipla-de-8
; que você já tinha no drawGraphic - se preferir, pode trocar
; o corpo desta rotina por uma chamada pra ela.
; ============================================================
DrawTile8x8:
    LD (dt_tileptr),HL
    LD A,E
    AND $07
    LD (dt_shift),A
    LD A,E
    SRA A
    SRA A
    SRA A
    LD (dt_bytex),A          ; byteX com sinal (-1..15)
    LD A,D
    LD (dt_cury),A
    LD A,8
    LD (dt_rowcount),A

dt_next_row:
    LD A,(dt_cury)
    BIT 7,A
    JR NZ,dt_advance         ; Y negativo -> linha fora da tela
    CP SCR_H
    JR NC,dt_advance         ; Y >= 64 -> linha fora da tela

    ; rowbase = framebuf + cury*16
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL                ; *16
    LD DE,framebuf
    ADD HL,DE
    LD (dt_rowbase),HL

    ; ---- byte esquerdo (coluna byteX) ----
    LD A,(dt_bytex)
    CP $FF
    JR Z,dt_right_only        ; byteX == -1 -> só o byte da direita existe
    CP SCR_STRIDE
    JR NC,dt_right_only
    LD C,A
    LD HL,(dt_rowbase)
    LD B,0
    ADD HL,BC
    LD (dt_addr),HL
    LD HL,(dt_tileptr)
    LD A,(HL)
    LD B,A                    ; B = byte original do tile
    LD A,(dt_shift)
    OR A
    JR Z,dt_left_noshift
    LD C,A
dt_left_shift_loop:
    SRL B
    DEC C
    JR NZ,dt_left_shift_loop
dt_left_noshift:
    LD HL,(dt_addr)
    LD A,(HL)
    OR B
    LD (HL),A

dt_right_only:
    ; ---- byte direito (coluna byteX+1), só existe transbordo
    ; se shift != 0 ----
    LD A,(dt_shift)
    OR A
    JR Z,dt_advance
    LD A,(dt_bytex)
    INC A
    CP SCR_STRIDE
    JR NC,dt_advance
    LD C,A
    LD HL,(dt_rowbase)
    LD B,0
    ADD HL,BC
    LD (dt_addr),HL
    LD HL,(dt_tileptr)
    LD A,(HL)
    LD B,A
    LD A,(dt_shift)
    LD C,A
    LD A,8
    SUB C
    LD C,A                    ; C = 8-shift
dt_right_shift_loop:
    SLA B
    DEC C
    JR NZ,dt_right_shift_loop
    LD HL,(dt_addr)
    LD A,(HL)
    OR B
    LD (HL),A

dt_advance:
    LD HL,(dt_tileptr)
    INC HL
    LD (dt_tileptr),HL
    LD A,(dt_cury)
    INC A
    LD (dt_cury),A
    LD A,(dt_rowcount)
    DEC A
    LD (dt_rowcount),A
    Jp NZ, dt_next_row
    RET

; ============================================================
; ReadInput - TODO: substituir pela leitura real do teclado
; matricial do Z80Mini. Aqui só um placeholder lendo uma porta
; fictícia com 4 bits (direita/esquerda/baixo/cima) pra deixar
; o exemplo executável/testável.
; ============================================================
ReadInput:
	call keyboardA
	jp c, ReadOk
	ret
	
ReadOk:
	PUSH AF
	LD A, (playerX)
	LD (playerXLast), A
	LD A, (playerY)
	LD (playerYLast), A
	POP AF

    cp 'd'
    JR NZ,ri_no_right
    LD A,(playerX)
    CP PLAYER_MAXX
    JR NC,ri_no_right
    INC A
    INC A

    LD (playerX),A
    call CheckTile
    RET
    
ri_no_right:
    cp 'a'
    JR NZ,ri_no_left
    LD A,(playerX)
    OR A
    JR Z,ri_no_left
    DEC A
    DEC A

    LD (playerX),A
    call CheckTile
    RET
    
ri_no_left:
    cp 's'
    JR NZ,ri_no_down
    LD A,(playerY)
    CP PLAYER_MAXY
    JR NC,ri_no_down
    INC A
    INC A

    LD (playerY),A
    call CheckTile
    RET
    
ri_no_down:
    cp	'w'
    JR NZ,ri_no_up
    LD A,(playerY)
    OR A
    JR Z,ri_no_up
    DEC A
    DEC A


    LD (playerY),A
    call CheckTile    
ri_no_up:
    RET


; ============================================================
; CheckTile - verifica qual tile está em (A = X, playerY = Y)
; Retorna: Z = tile é 0 (pode passar), NZ = colisão
; ============================================================
CheckTile:
	call serialCRLF
	call serialCRLF	
	
	LD A, (playerX)
	INC A
	INC A
	INC A
	INC A
	
    ; tileX = B / 8
    SRL A
    SRL A
    SRL A
    LD C,A                  ; C = tileX
    
    ; tileY = playerY / 8
    LD A,(playerY)
    INC A
    INC A
    INC A
    INC A
    
    SRL A
    SRL A
    SRL A
    LD B,A                  ; B = tileY
    

    
    
    push bc   
    ld h, b
    ld l, c
    call serialHexHL
    pop bc
    
    
    ; B = tileY
    ; C = tileX
    ; endereço = map_data + tileY*32 + tileX
    LD L,B          ; L = tileY, H já é 0
	LD H,0          ; HL = tileY * 1
	ADD HL,HL       ; HL = tileY * 2
	ADD HL,HL       ; HL = tileY * 4
	ADD HL,HL       ; HL = tileY * 8
	ADD HL,HL       ; HL = tileY * 16
	ADD HL,HL       ; HL = tileY * 32
	LD B,0
	ADD HL,BC       ; HL = tileY*32 + tileX
	LD DE,map_data
	ADD HL,DE       ; HL = &map_data[tileY*32 + tileX]
    
    
    PUSH HL
    PUSH HL
    call serialCRLF
    POP HL
    call serialHexHL
    POP HL
    
    
    ; carrega o tile
    LD A,(HL)
    PUSH AF
    PUSH AF
    call serialCRLF
    POP AF
    call serialHexA
    POP AF
    
    CP 4 ; porta1
    JP Z, 0
    
    cp 0
    RET Z
    LD A, (playerXLast)
    LD (playerX), A
    LD A, (playerYLast)
    LD (playerY), A  
    RET
    
    
; ============================================================
; FlushFB - TODO: chamar aqui sua rotina real que envia o
; framebuf (128x64, 1bpp, 16 bytes/linha) pro ST7920.
; ============================================================
FlushFB:
	call plotToLCD
    ret
    
    
    
; ============================================================
; VARIÁVEIS
; ============================================================
playerXLast:    DB 8
playerYLast:    DB 8
playerX:    DB 8
playerY:    DB 8
camX:       DB 0
camY:       DB 0

tx_start:   DB 0
tx_end:     DB 0
ty_start:   DB 0
ty_end:     DB 0
tx_cur:     DB 0
ty_cur:     DB 0

; usadas pela rotina DrawTile8x8
dt_tileptr: DW 0
dt_shift:   DB 0
dt_bytex:   DB 0
dt_cury:    DB 0
dt_rowcount:DB 0
dt_rowbase: DW 0
dt_addr:    DW 0

player:		dw 0
diego:		db 0

; ============================================================
; MAPA 32x32 (id do tile por posição). Preenchido em runtime
; com paredes na borda e chão no meio.
; ============================================================
map_data:
    DEFS MAP_SIZE,0
    
    
    
; ============================================================
; GRÁFICOS (8 bytes = 8 linhas, 1 bit por pixel, MSB = esquerda)
; ============================================================
tile_empty:
    DB $00,$00,$00,$00,$00,$00,$00,$00
tile_floor:                     ; marcador de referência (pontinho)
    ;DB $00, $12, $24, $48, $12, $24, $48, $00
    DB $00, $00, $00, $00, $00, $00, $00, $00
    
tile_wall:
    DB $FF, $81, $BD, $BD, $BD, $BD, $81, $FF

sprite_player:                  ; círculo 8x8
    DB $3C, $3C, $3C, $18, $FF, $BD, $24, $66
    
bloco1:
	DB $FF, $44, $44, $FF, $12, $12, $FF, $49
	
bloco2:
	DB $5A, $C3, $3C, $BD, $BD, $3C, $C3, $5A
	
porta1:
	DB $FF, $81, $81, $81, $85, $81, $81, $81	


teste:
	DB $18, $24, $18, $00, $7E, $99, $A5, $24, $18, $24, $18, $7E, $99, $99, $24, $24
	
bomba:	
	DB $00, $3C, $42, $81, $81, $81, $42, $3C, $00, $00, $18, $24, $42, $42, $24, $18



tiles_table:
	; índice 0 = chão, 1 = parede, 2 = bloco1, 3=bloco2, 4=porta1, 5=teste
    DW tile_floor, tile_wall, bloco1, bloco2, porta1, teste

mapa1:	db	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 2, 0, 2, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 3, 3, 3, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 3, 0, 0, 0, 4, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
		db	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
		
		
;32x32 titles
mapa2:	db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		db	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


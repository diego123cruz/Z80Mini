; **********************************************************************
; **  Z80 Mini GameCore - API - Public functions                      **
; **********************************************************************
;----------------------------------------------------------------------------------------------------------
;	Display LCD
;----------------------------------------------------------------------------------------------------------
INIT_LCD			        .EQU	$0100			;Initalise the LCD
CLEAR_GBUF			        .EQU	$0103			;Clear the Graphics Buffer
CLEAR_GR_LCD			    .EQU	$0106			;Clear the Graphics LCD Screen
CLEAR_TXT_LCD			    .EQU	$0109			;Clear the Text LCD Screen
SET_GR_MODE			        .EQU	$010C			;Set Graphics Mode
SET_TXT_MODE			    .EQU	$010F			;Set Text Mode
DRAW_BOX			        .EQU	$0112			;Draw a rectangle between two points
DRAW_LINE			        .EQU	$0115			;Draw a line between two points
DRAW_CIRCLE			        .EQU	$0118			;Draw a circle from Mid X,Y to Radius
DRAW_PIXEL			        .EQU	$011B			;Draw one pixel at X,Y
FILL_BOX			        .EQU	$011E			;Draw a filled rectangle between two points
FILL_CIRCLE			        .EQU	$0121			;Draw a filled circle from Mid X,Y to Radius
PLOT_TO_LCD			        .EQU	$0124			;Display the Graphics Buffer to the LCD Screen
PRINT_STRING			    .EQU	$0127			;Print Text on the screen in a given row
PRINT_CHARS			        .EQU	$012A			;Print Characters on the screen in a given row and column
DELAY_US			        .EQU	$012D			;Microsecond delay for LCD updates
DELAY_MS             		.EQU	$0130			;Millisecond delay for LCD updates
SET_BUF_CLEAR			    .EQU	$0133			;Clear the Graphics buffer on after Plotting to the screen
SET_BUF_NO_CLEAR     		.EQU	$0136			;Retain the Graphics buffer on after Plotting to the screen
CLEAR_PIXEL          		.EQU	$0139			;Remove a Pixel at X,Y
FLIP_PIXEL			        .EQU	$013C			;Flip a Pixel On/Off at X,Y
LCD_INST             		.EQU	$013F			;Send a parallel or serial instruction to LCD
LCD_DATA             		.EQU	$0142			;Send a parallel or serial datum to LCD
SER_SYNC             		.EQU	$0145			;Send serial synchronise byte to LCD
DRAW_GRAPHIC         		.EQU	$0148			;Draw an ASCII charcter or Sprite to the LCD
INV_GRAPHIC          		.EQU	$014B			;Inverse graphics printing
INIT_TERMINAL        		.EQU	$014E			;Initialize the LCD for terminal emulation
SEND_CHAR_TO_GLCD    		.EQU	$0151			;Send an ASCII Character to the LCD
SEND_STRING_TO_GLCD 		.EQU	$0154			;Send an ASCII String to the LCD
SEND_A_TO_GLCD       		.EQU	$0157			;Send register A to the LCD
SEND_HL_TO_GLCD      		.EQU	$015A			;Send register HL to the LCD
SET_CURSOR           		.EQU	$015D			;Set the graphics cursor
GET_CURSOR           		.EQU	$0160			;Get the current cursor
DISPLAY_CURSOR       		.EQU	$0163			;Set Cursor on or off
;----------------------------------------------------------------------------------------------------------
;	UTIL
;----------------------------------------------------------------------------------------------------------
H_Delay              		.EQU	$0166			;Delay in milliseconds (DE in millis)
LCD_PRINT_STRING            .EQU    $0169           ;Print string HL, end with 0 EX: "Test", $00
;----------------------------------------------------------------------------------------------------------
;	I2C Board
;----------------------------------------------------------------------------------------------------------
I2C_Open     			    .EQU	$016C			;Start i2c (Device address in A)
I2C_Close             		.EQU	$016F			;Close i2c 
I2C_Read              		.EQU	$0172			;I2C Read (data in A)
I2C_Write 			        .EQU	$0175			;I2C Write (data in A)
I2CLIST                     .EQU    $0178           ;I2C List devices on lcd

CLEAR_COLLISION             .EQU    $017B           ; lampa a flag de colisao
CHECK_COLLISION             .EQU    $017E           ; JP Z, SEM_COLISAO. JP NZ, COLISAO.

INIT_GAME_WAIT_START        .EQU   $0181        ; Chamar no setup, aguarda press start e returna, dar um (LD HL, setup) e (PUSH HL).
CHECK_GAMEOVER_WAIT_START   .EQU    $0184   ; Chamar no loop para verificar gameover e depois aguarda press start e ret para o inicio
SET_GAMEOVER                .EQU    $0187                 ; Seta a flag de gameover....




    .org $8000

setup:
    ld hl, setup
    push hl
    
    call CLEAR_GBUF
    call INIT_GAME_WAIT_START
    
    ld a, 1
    ld (jogador), a
    
    xor a
    ld (cursor_x), a
    ld (cursor_y), a

    ; zera tabuleiro
    ld b, 9
    ld hl, tabuleiro
zera_tab:
    ld a, $0A
    ld (hl), a
    inc hl
    DJNZ zera_tab

loop:
    call CLEAR_GBUF
    
    call ler_controle
    call desenha_tabuleiro
    call desenha_cursor
    call desenha_jogadas
    call desenha_jogador_atual
    call verifica_vencedor
    call CHECK_GAMEOVER_WAIT_START
    
    
    call PLOT_TO_LCD
    jp loop
    
    
verifica_velha:
    ld b, 9
    ld hl, tabuleiro
verifica_velha_loop:
    ld a, (hl)
    cp $0A
    RET Z
    inc hl
    DJNZ verifica_velha_loop
    JP deu_velha
    ret
    
verifica_vencedor:
    ld ix, tabuleiro
    
    ; ---
    ; ...
    ; ...
    ld a, (ix)
    ld b, (ix+1)
    ld c, (ix+2)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ...
    ; ---
    ; ...
    ld a, (ix+3)
    ld b, (ix+4)
    ld c, (ix+5)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ...
    ; ...
    ; ---
    ld a, (ix+6)
    ld b, (ix+7)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; -..
    ; -..
    ; -..
    ld a, (ix)
    ld b, (ix+3)
    ld c, (ix+6)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; .-.
    ; .-.
    ; .-.
    ld a, (ix+1)
    ld b, (ix+4)
    ld c, (ix+7)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ..-
    ; ..-
    ; ..-
    ld a, (ix+2)
    ld b, (ix+5)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; -..
    ; .-.
    ; ..-
    ld a, (ix)
    ld b, (ix+4)
    ld c, (ix+8)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    ; ..-
    ; .-.
    ; -..
    ld a, (ix+2)
    ld b, (ix+4)
    ld c, (ix+6)
    add a, b
    add a, c
    cp 3
    jp z, ganhouX
    cp 6
    jp z, ganhouO
    
    call verifica_velha
    ret

ganhouX:
    LD BC, $2800
    CALL SET_CURSOR
    
    ld hl, msg_winX
    call LCD_PRINT_STRING
    call SET_GAMEOVER
    ret
   
ganhouO:
    LD BC, $2800
    CALL SET_CURSOR
    
    ld hl, msg_winO
    call LCD_PRINT_STRING
    call SET_GAMEOVER
    ret 
    
deu_velha:
    LD BC, $2800
    CALL SET_CURSOR
    
    ld hl, msg_velha
    call LCD_PRINT_STRING
    call SET_GAMEOVER
    ret 
    
    
ler_controle:
    in a, ($40)
    bit 7,a
    JP NZ, KUP
    
    bit 5,a
    JP NZ, KDOWN
    
    bit 6,a
    JP NZ, KLEFT
    
    bit 4,a
    JP NZ, KRIGHT
    
    bit 0,a
    JP NZ, KA

    RET
    

KUP:
    call delay
    ld a, (cursor_y)
    cp 0
    RET Z
    dec a
    ld (cursor_y), a
    RET
    
KDOWN:
    call delay
    ld a, (cursor_y)
    cp 2
    ret z
    inc a
    ld (cursor_y), a
    RET
    
KLEFT:
    call delay
    ld a, (cursor_x)
    cp 0
    ret z
    dec a
    ld (cursor_x), a
    RET
    
KRIGHT:
    call delay
    ld a, (cursor_x)
    cp 2
    ret z
    inc a
    ld (cursor_x), a
    RET
    
    
getline0:
    ld hl, tabuleiro
    ret
    
getline1:
    ld hl, tabuleiro+3
    ret
    
getline2:
    ld hl, tabuleiro+6
    ret
    
    
KA:
    ld a, (cursor_y)
    cp 0
    call z, getline0
    cp 1
    call z, getline1
    cp 2
    call z, getline2
    ld a, (cursor_x)
    ld bc, $0000
    ld c, a
    add hl, bc
    ld a, (hl)
    cp $0A
    ret nz
    ld a, (jogador)
    ld (hl), a
    call proximo_jogador
    ret
    

proximo_jogador:
    ld a, (jogador)
    cp 1
    jp z, proximo_jogador2
    ld a, 1
    ld (jogador), a
    ret
proximo_jogador2:
    ld a,2
    ld (jogador),a
    ret
    
    
    
delay:
    LD DE, $0096
    call H_Delay
    ret
    
ajuste_cursor:   
    cp 1
    jp z, add10
    cp 2
    jp z, add19
    ret
    
add10:
    add a, 10
    ret

add19:
    add a, 19
    ret
    
    
desenha_jogador_atual:
    ld bc, $0028
    call SET_CURSOR
    
    ld a, (jogador)
    cp 1
    jp z, mostra_jogador1
    cp 2
    jp z, mostra_jogador2
    ret

mostra_jogador1:
    xor a
    ld bc, $0808
    ld hl, dx
    call DRAW_GRAPHIC
    ret


mostra_jogador2:
    xor a
    ld bc, $0808
    ld hl, do
    call DRAW_GRAPHIC
    ret

desenha_cursor:
    LD a, (cursor_x)
    cp 0
    call nz, ajuste_cursor
    LD B, A
    add a, 8
    ld d, a
    
    ld a, (cursor_y)
    cp 0
    call nz, ajuste_cursor
    ld c, a
    add a, 8
    ld e, a
    call FILL_BOX
    RET
    
    
    
desenha_jogadas:
    LD B, 9
    LD HL, tabuleiro 
    LD DE, $0000 ; cursor
desenha_jogadas_loop:
    ld a, (hl)
    cp 1
    call z, draw_X
    cp 2 
    call z, draw_O
    inc HL
    ld a, d
    add a,11
    ld d, a
    
    ld a, b
    cp 7
    jp nz, $+8
    xor a
    ld d, a
    add a, 11
    ld e, a
    
    ld a, b
    cp 4
    jp nz, $+8
    xor a
    ld d, a
    add a, 22
    ld e, a
    

    DJNZ desenha_jogadas_loop
    ret
    
draw_X:
    push af
    push bc
    push de
    push hl
    
    push de
    pop bc
    call SET_CURSOR
    
    LD BC, $0808
    LD HL, dx
    xor a
    call DRAW_GRAPHIC
    
    pop hl
    pop de
    pop bc
    pop af
    ret
    
draw_O:
    push af
    push bc
    push de
    push hl
    
    push de
    pop bc
    call SET_CURSOR
    
    LD BC, $0808
    LD HL, do
    xor a
    call DRAW_GRAPHIC
    
    pop hl
    pop de
    pop bc
    pop af
    ret
    
desenha_tabuleiro:
    LD BC, $0A00
    ld DE, $0A1E
    call DRAW_LINE
    
    LD BC, $1400
    ld DE, $141E
    call DRAW_LINE
    
    LD BC, $000A
    ld DE, $1E0A
    call DRAW_LINE
    
    LD BC, $0014
    ld DE, $1E14
    call DRAW_LINE
    RET
    
    

msg_winX:    .db "X - GANHOU!!!",0
msg_winO:    .db "O - GANHOU!!!",0
msg_velha:   .db "DEU VELHA!!!",0

dx: .db     0xC3, 0xC3, 0x24, 0x18, 0x18, 0x24, 0xC3, 0xC3
do: .db     0x3C, 0x42, 0x81, 0x81, 0x81, 0x81, 0x42, 0x3C

cursor_x:   .db 0x00
cursor_y:   .db 0x00
jogador:    .db 0x01

; 0x01 = X
; 0x02 = O
tabuleiro:  .db 0x0A, 0x0A, 0x0A
            .db 0x0A, 0x0A, 0x0A 
            .db 0x0A, 0x0A, 0x0A
    
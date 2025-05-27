; **********************************************************************
; **  API - Public functions   Z80 Mini - GAMECORE                    **
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
    
    

inicio:
    LD HL, inicio
    PUSH HL
    
    xor a
    ld (box_x), a
    ld (box_y), a
    ld (box2_x), a
    ld (box2_y), a
    ld a, $30
    ld (player_x),a
    ld (player_y),a
    call CLEAR_GBUF
    call INIT_GAME_WAIT_START
    call new_fruit
    XOR A
    LD (count), A
loop:
    
    call ler_teclado
    call CLEAR_GBUF
    
    
    ; print fruit
    LD A, (fruit_x)
    ld b, a
    ld a, (fruit_y)
    ld c, a
    LD E, 1
    call FILL_CIRCLE
    
    
    ; DRAW BOX to RIGHT
    ; set cursor 
    LD A, (box_x)
    ld b, a
    ld a, (box_y)
    ld c, a
    call SET_CURSOR
    
    ; print imageR
    LD A, 0
    LD BC, $0808
    LD HL, imageR
    call DRAW_GRAPHIC
    
    
    ; DRAW BOX to DOWN
    ; set cursor 
    LD A, (box2_x)
    ld b, a
    ld a, (box2_y)
    ld c, a
    call SET_CURSOR
    
    ; print imageD
    LD A, 0
    LD BC, $0808
    LD HL, imageD
    call DRAW_GRAPHIC
    

    ; DRAW PLAYER
    call CLEAR_COLLISION
    ; set cursor
    LD A, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call SET_CURSOR
    
    ; print player
    LD A, 0
    LD BC, $0808
    LD HL, player
    call DRAW_GRAPHIC
    
    CALL CHECK_COLLISION
    CALL NZ, check_collision_object


    ;DRAW pontos
    LD BC, $0000
    call SET_CURSOR
    LD A, (count)
    CALL SEND_A_TO_GLCD
    
    
    CALL CHECK_GAMEOVER_WAIT_START

    call PLOT_TO_LCD


    call update_box 
    call update_box2

    jp loop
    

; # Algoritmo de Colisão AABB (Axis-Aligned Bounding Box)
;*   **Retângulo A:** (Ax, Ay, Aw, Ah)
;*   **Retângulo B:** (Bx, By, Bw, Bh)

; Calculamos as coordenadas das bordas direita e inferior:
;   ARight = Ax + Aw
;   ABottom = Ay + Ah
;   BRight = Bx + Bw
;   BBottom = By + Bh

; Os retângulos **NÃO** colidem se **QUALQUER** uma das seguintes condições for verdadeira:
; 1.  A está totalmente à esquerda de B: `ARight <= Bx`
; 2.  A está totalmente à direita de B: `Ax >= BRight`
; 3.  A está totalmente acima de B: `ABottom <= By`
; 4.  A está totalmente abaixo de B: `Ay >= BBottom`
check_collision_object:
    ld a, (fruit_x)
    dec a
    ld b, a
    ld a, (player_x)
    add a, 8
    cp b
    JP C, check_collision_object_end
    
    ld a, (fruit_x)
    dec a
    add a, 3
    ld b, a
    ld a, (player_x)
    cp b
    JP NC, check_collision_object_end
    
    ld a, (fruit_y)
    dec a
    ld b, a
    ld a, (player_y)
    add a, 8
    cp b
    JP C, check_collision_object_end
    
    ld a, (fruit_y)
    dec a
    add a, 3
    ld b,a
    ld a, (player_y)
    cp b
    JP NC, check_collision_object_end
    
    call new_fruit
    ret
check_collision_object_end:
    CALL SET_GAMEOVER
    ret

    
    
new_fruit:
    call randomHL
    LD A, H
    LD (fruit_x), A
    LD A, L
    LD (fruit_y), A
    
    LD A, (count)
    adc a, 1
    daa
    LD (count), A
    ret
    
    
    

update_box:
    ld a, (box_x)
    add a, 2
    cp $80
    JP NC, inc_y
    ld (box_x), a
    ret
    
inc_y:
    ld a, (box_y)
    add a, 8
    cp $40
    jp NC, res_box
    ld (box_y),a
    xor a
    ld (box_x), a
    ret
    
res_box:
    xor a
    ld (box_x),a
    ld (box_y), a
    ret
    
    
update_box2:
    ld a, (box2_y)
    add a, 2
    cp $40
    JP NC, inc_x
    ld (box2_y), a
    ret
    
inc_x:
    ld a, (box2_x)
    add a, 12
    cp $80
    jp NC, res_box2
    ld (box2_x),a
    xor a
    ld (box2_y), a
    ret
    
res_box2:
    xor a
    ld (box2_x),a
    ld (box2_y), a
    ret
    
    
    
ler_teclado:
    IN A, ($40)

    bit 7, A
    JP NZ, TRY_UP

    bit 5, A
    JP NZ, TRY_DOWN

    bit 6, A
    JP NZ, TRY_LEFT

    bit 4, A
    JP NZ, TRY_RIGHT
    
    bit 1, A
    JP NZ, new_fruit

    bit 3, A
    JP NZ, 0 ; Back to Monitor
    RET
    
    
TRY_UP:
    ld a, (player_y)
    dec a
    cp 1
    ret C
    ld (player_y), a
    ret
    
TRY_DOWN:
    ld a, (player_y)
    inc a
    cp 56
    ret NC
    ld (player_y), a
    ret
    
TRY_LEFT:
    ld a, (player_x)
    dec a
    cp 1
    ret C
    ld (player_x), a
    ret
    
TRY_RIGHT:
    ld a, (player_x)
    inc a
    cp 120
    ret NC
    ld (player_x), a
    ret
    
    

    

VTELA_X     .EQU    $7E ; Tela virtal 
VTELA_Y     .EQU    $3E ; Tela virtal

randomHL:
    ; 3F = 126/2
    ; 1F = 62/2
    CALL prng16
    LD A, H
    AND VTELA_X-1
    CP 0
    JP Z, randomHL
    LD H, A

    LD A, L
    AND VTELA_Y-1
    CP 0
    JP Z, randomHL
    LD L, A
    RET


prng16:
; Site: https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Random
;Inputs:
;   (seed1) contains a 16-bit seed value
;   (seed2) contains a NON-ZERO 16-bit seed value
;Outputs:
;   HL is the result
;   BC is the result of the LCG, so not that great of quality
;   DE is preserved
;Destroys:
;   AF
;cycle: 4,294,901,760 (almost 4.3 billion)
;160cc
;26 bytes
    ld hl,(seed1)
    ld b,h
    ld c,l
    add hl,hl
    add hl,hl
    inc l
    add hl,bc
    ld (seed1),hl
    ld hl,(seed2)
    add hl,hl
    sbc a,a
    and %00101101
    xor l
    ld l,a
    ld (seed2),hl
    add hl,bc
    ret


seed1       .dw 1234
seed2       .dw 8765

count       .db 0x00    

fruit_x     .db 0x00
fruit_y     .db 0x00

box_x:    .db 0x00
box_y:    .db 0x00

box2_x:    .db 0x00
box2_y:    .db 0x00
    
player_x: .db 0x0A
player_y: .db 0x0A

imageR: .db 0xFF, 0xFE, 0x7C, 0x7F, 0x7F, 0x7C, 0xFE, 0xFF
imageD: .db 0xC3, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xDB, 0x99
player: .db 0x1C, 0x1C, 0x14, 0x08, 0x3E, 0x08, 0x08, 0x36

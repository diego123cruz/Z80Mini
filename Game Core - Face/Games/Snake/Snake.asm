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
DRAW_LINE			        .EQU	$0115			;Draw a line between two points Inputs: BC = X0,Y0  DE = X1,Y1
DRAW_CIRCLE			        .EQU	$0118			;Draw a circle from Mid X,Y to Radius
DRAW_PIXEL			        .EQU	$011B			;Draw one pixel at X,Y Input B = column/X (0-127), C = row/Y (0-63)
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
LCD_INST             		.EQU	$013F			;Send a parallel instruction to LCD
LCD_DATA             		.EQU	$0142			;Send a parallel datum to LCD
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
;----------------------------------------------------------------------------------------------------------
;	FIM
;----------------------------------------------------------------------------------------------------------

; Portas
GAMEPAD     .EQU    $40

; RAM - Core
KEY_GAMEPAD .EQU    $FB99

; direções
DIR_UP      .EQU    1
DIR_DOWN    .EQU    2
DIR_LEFT    .EQU    3
DIR_RIGHT   .EQU    4

TELA_X      .EQU    $7F ; 0-127 = 128
TELA_Y      .EQU    $3F ; 0-63 = 64

VTELA_X     .EQU    $3F ; Tela virtal 
VTELA_Y     .EQU    $1F ; Tela virtal 

.org $8000
    ; Setup ram
    LD A, 1
    LD (gameover), A ; Gameover

start_game:
    ; Direção inicial
    LD A, 4
    LD (direction), A

    LD A, 15
    LD (food_x), A
    LD (food_y), A

    ; seed to random
    LD A, $82
    LD HL, seed1
    LD (HL), A
    INC HL
    LD (HL), A
    LD A, $76
    LD HL, seed2
    LD (HL), A
    INC HL
    LD (HL), A

    ; Tamanho inicial
    LD A, 4
    LD (size), A

    ; Posição inicial
    LD A, 10
    
    LD (head_y+3), A    ;X
    LD (head_y+1), A    ;X
    LD (head_y+5), A    ;X
    LD (head_y+7), A    ;X
    INC A
    LD (head_y), A      ;Y
    INC A
    LD (head_y+2), A    ;Y
    INC A
    LD (head_y+4), A    ;Y
    INC A
    LD (head_y+6), A    ;Y
    

loop:
    CALL atualiza_jogo
    CALL atualiza_display

    LD B, $62
delay_loop:
    in A, (GAMEPAD)
    CP 0
    JP Z, delay_loop_skip
    LD (read_keys), A
delay_loop_skip:
    LD DE, $0001
    CALL H_Delay
    DJNZ delay_loop
    
    ; Check GameOver
    LD A, (gameover)
    CP 0
    JP Z, loop

    ; Cursor OFF
    LD A, 1
    CALL DISPLAY_CURSOR

    ; Set cursor XY
    ;Inputs: BC = X,Y where X = 0..127, Y = 0..63
    LD BC, $1E2B
    CALL SET_CURSOR

    LD A, 0
    LD DE, msg_start
    CALL SEND_STRING_TO_GLCD
loop_enter:
    in A, (GAMEPAD)
    bit 2, A
    JP Z, loop_enter
    LD A, 0
    LD (gameover), A
    jp loop


atualiza_jogo:
    CALL ler_teclado
    CALL atualiza_corpo
    CALL atualiza_head
    CALL check_colisao
    CALL check_food
    RET


check_food:
    ; if head_x == food_x E head_y == food_y = comer
    LD HL, (head_y)
    LD A, (food_x)
    CP H
    RET NZ
    LD A, (food_y)
    CP L 
    RET NZ
    CALL comer
    RET

comer:
    LD A, (size)
    INC A
    LD (size), A
    CALL new_food
    RET

new_food:
    CALL randomHL
    LD A, H
    LD (food_x), A
    LD A, L
    LD (food_y), A
    RET

fim_de_jogo:
    LD BC, $1E2B
    CALL SET_CURSOR

    LD A, 0
    LD DE, msg_gameover
    CALL SEND_STRING_TO_GLCD
    LD A, (size)
    CALL SEND_A_TO_GLCD
fim_de_jogo_loop:
    in A, (GAMEPAD)
    bit 2, A
    JP Z, fim_de_jogo_loop
    JP start_game
    

check_colisao:
    ; colisão com Paredes
    ; if head_x < 1 ou head_x > 63 = fim de jogo
    ; if head_y < 1 ou head_y > 31 = fim de jogo
    LD HL, (head_y) ; H=X, L=Y
    LD A, H
    CP 1
    JP C, fim_de_jogo ; if x < 1
    CP VTELA_X
    JP NC, fim_de_jogo ; fi x >= 63

    LD A, L
    CP 1
    JP C, fim_de_jogo ; if y < 1
    CP VTELA_Y
    JP NC, fim_de_jogo ; if y >= 31
    RET



atualiza_corpo:
    LD A, (size)

    LD      C, A 
    LD      B, 0 
    SLA     C ; Multiplicar por 2

    LD A, C
    PUSH AF

    LD HL, head_y
    ADD HL, BC ; HL ultimo segmento HL
    PUSH HL

    LD HL, head_y+2 ; depois do ultimo DE
    ADD HL, BC
    LD D, H
    LD E, L

    POP HL

    POP AF
    LD B, A
atualiza_corpo_loop:
    LD A, (HL)
    LD (DE), A
    DEC HL
    DEC DE
    DJNZ atualiza_corpo_loop
    LD A, (HL)
    LD (DE), A
    RET


atualiza_head:
    LD A, (direction)
    CP DIR_UP
    JP Z, HEAD_UP
    CP DIR_DOWN
    JP Z, HEAD_DOWN
    CP DIR_LEFT
    JP Z, HEAD_LEFT
    CP DIR_RIGHT
    JP Z, HEAD_RIGHT
    RET


HEAD_UP:
    LD A, (head_y)
    DEC A
    LD (head_y), A
    RET

HEAD_DOWN:
    LD A, (head_y)
    INC A
    LD (head_y), A
    RET

HEAD_LEFT:
    LD A, (head_x)
    DEC A
    LD (head_x), A
    RET

HEAD_RIGHT:
    LD A, (head_x)
    INC A
    LD (head_x), A
    RET





ler_teclado:
    LD A, (read_keys)
    LD B, A

    LD A, 0
    LD (read_keys), A

    LD A, B

    bit 7, A
    JP NZ, TRY_UP

    bit 5, A
    JP NZ, TRY_DOWN

    bit 6, A
    JP NZ, TRY_LEFT

    bit 4, A
    JP NZ, TRY_RIGHT

    bit 3, A
    JP NZ, 0 ; Back to Monitor
    RET

TRY_UP:
    LD A, (direction)
    CP DIR_DOWN
    RET Z
    LD A, DIR_UP
    LD (direction), A
    RET

TRY_DOWN:
    LD A, (direction)
    CP DIR_UP
    RET Z
    LD A, DIR_DOWN
    LD (direction), A
    RET

TRY_LEFT:
    LD A, (direction)
    CP DIR_RIGHT
    RET Z
    LD A, DIR_LEFT
    LD (direction), A
    RET

TRY_RIGHT:
    LD A, (direction)
    CP DIR_LEFT
    RET Z
    LD A, DIR_RIGHT
    LD (direction), A
    RET


desenha_food;
    LD A, (food_x)
    LD B, A
    LD A, (food_y)
    LD C, A
    CALL set_pixel_bc
    RET


desenha_snake:
    LD A, (size)
    LD B, A
    LD HL, head_y
desenha_snake_loop:
    PUSH BC

    LD C, (HL)
    INC HL
    LD B, (HL)
    
    PUSH HL
    CALL set_pixel_bc
    POP HL
    POP BC

    INC HL

    DJNZ desenha_snake_loop
    RET

set_pixel_bc:
    ; Desenha pixel
    ; Input B = column/X (0-127), C = row/Y (0-63)

    SLA B
    SLA C
    PUSH BC 
    ; *-
    ; --
    CALL PIXEL_BC_DRAW ; Main pixel

    ; **
    ; --
    INC B
    CALL PIXEL_BC_DRAW

    ; **
    ; *-
    POP BC
    INC C
    CALL PIXEL_BC_DRAW

    ; **
    ; **
    INC B
    CALL PIXEL_BC_DRAW
    RET

PIXEL_BC_DRAW:
    PUSH BC
    CALL DRAW_PIXEL
    POP BC
    RET

atualiza_display:
    ; Limpa buffer display
    CALL CLEAR_GBUF

    CALL desenha_food

    CALL desenha_snake

    ; Desenha limites
    LD BC, $0000
    LD D, TELA_X
    LD E, TELA_Y
    CALL DRAW_BOX

    ; Atualiza display
    CALL PLOT_TO_LCD
    RET

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

msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER ",0
read_keys   .db $00
gameover    .db $00
seed1       .dw 1234
seed2       .dw 8765
direction   .db $01
size        .db $01
food_y      .db $01
food_x      .db $01
head_y      .db $01
head_x      .db $01

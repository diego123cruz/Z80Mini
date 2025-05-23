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


;         - Ports:
;               - Onboard IN/OUT: 40H
;					- Controle - pullDown (Input)
;						- bit0 - A
;						- bit1 - B
;						- bit2 - Start
;						- bit3 - Select
;						- bit4 - Right
;						- bit5 - Down
;						- bit6 - Left
;						- bit7 - Up

GAMEPAD         .equ    $40
.org $8000

init:
    LD A, 1
    LD (gameover), A ; Gameover

    XOR A
    LD (cursor_x), A
    LD (cursor_y), A
    ld (bomb_alive), A
    LD IX, predios
    LD BC, 0x132E
    LD (IX), BC
    LD BC, 0x193F
    LD (IX+2), BC
    LD BC, 0x2e33
    LD (IX+4), BC
    LD BC, 0x343F
    LD (IX+6), BC
    LD BC, 0x4630
    LD (IX+8), BC
    LD BC, 0x4c3F
    LD (IX+10), BC
    LD BC, 0x582E
    LD (IX+12), BC
    LD BC, 0x5e3F
    LD (IX+14), BC
    LD BC, 0x6a33
    LD (IX+16), BC
    LD BC, 0x703F
    LD (IX+18), BC

loop:
    CALL ler_gamepad
    call update_bomb
    call update_airplane
    call update_predios
    call update_screen

    ; Check GameOver
    LD A, (gameover)
    CP 0
    JP Z, loop

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


inc_bc:
    INC BC
    INC BC
    INC BC
    INC BC
    ret

inc_b:
    inc B
    inc B
    inc B
    inc B
    inc B
    inc B
    inc B
    ret

update_predios:
    LD A, (bomb_alive)
    cp 0
    RET Z
    LD IX, predios
p1:
    ld bc, (IX)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p2
    ld a, (bomb_y)
    cp c
    jp NC, p2
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p2
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p2
    CALL inc_bc
    LD (IX), bc
    xor a
    ld (bomb_alive), a

p2:
    ld bc, (IX+4)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p3
    ld a, (bomb_y)
    cp c
    jp NC, p3
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p3
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p3
    CALL inc_bc
    LD (IX+4), bc
    xor a
    ld (bomb_alive), a

p3:
    ld bc, (IX+8)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p4
    ld a, (bomb_y)
    cp c
    jp NC, p4
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p4
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p4
    CALL inc_bc
    LD (IX+8), bc
    xor a
    ld (bomb_alive), a

p4
    ld bc, (IX+12)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p5
    ld a, (bomb_y)
    cp c
    jp NC, p5
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p5
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p5
    CALL inc_bc
    LD (IX+12), bc
    xor a
    ld (bomb_alive), a

p5
    ld bc, (IX+16)
    ld a, (bomb_y)
    add a, 7
    cp c
    jp C, p6
    ld a, (bomb_y)
    cp c
    jp NC, p6
    ld a, (bomb_x)
    add a, 5
    cp B
    jp C, p6
    ld a, (bomb_x)
    PUSH BC
    CALL inc_b
    cp b
    POP BC
    JP NC, p6
    CALL inc_bc
    LD (IX+16), bc
    xor a
    ld (bomb_alive), a
p6:
    RET


ler_gamepad:
    in A, (GAMEPAD)
    bit 0, A
    jp nz, bomb_fire

    bit 3, A
    JP NZ, quit

    ;bit 7, A
    ;jp nz, btnUp

    ;bit 5, A
    ;jp nz, btnDown

    ;bit 6, A
    ;jp nz, btnLeft

    ;bit 4, A
    ;jp nz, btnRight
    RET

quit:
    jp 0

update_screen:
    CALL CLEAR_GBUF

; Draw predios
    LD IX, predios
    ld bc, (IX)
    ld de, (IX+2)
    call FILL_BOX

    ld bc, (IX+4)
    ld de, (IX+6)
    call FILL_BOX

    ld bc, (IX+8)
    ld de, (IX+10)
    call FILL_BOX

    ld bc, (IX+12)
    ld de, (IX+14)
    call FILL_BOX

    ld bc, (IX+16)
    ld de, (IX+18)
    call FILL_BOX


; Draw airplane
    LD A, (cursor_x)
    LD B, A
    LD A, (cursor_y)
    LD C, A
    CALL SET_CURSOR
    LD A, 0
    LD BC, $0F08
    LD HL, airplane
    CALL DRAW_GRAPHIC


    ; Draw bomb
    ld A, (bomb_alive)
    cp 0
    JP Z, fim_bomb
    LD A, (bomb_x)
    LD B, A
    LD A, (bomb_y)
    LD C, A
    CALL SET_CURSOR
    LD A, 14 ; bomb
    CALL DRAW_GRAPHIC
fim_bomb:

    CALL PLOT_TO_LCD
    ret


btnUp:
    ld a, (cursor_y)
    dec A
    ld (cursor_y), a
    RET

btnDown:
    ld a, (cursor_y)
    inc A
    ld (cursor_y), a
    RET

btnLeft:
    ld a, (cursor_x)
    dec A
    ld (cursor_x), a
    RET

btnRight:
    ld a, (cursor_x)
    inc A
    ld (cursor_x), a
    RET




update_bomb:
    ld a, (bomb_alive)
    cp 0
    RET Z
    ; x
    ld a, (bomb_x)
    add a, 2
    ld (bomb_x), A
    ; y
    ld a, (bomb_y)
    add a, 3
    ld (bomb_y), A
    cp 64
    JP NC, bomb_alive_zera

    ld a, (bomb_x)
    cp 124
    JP NC, bomb_alive_zera
    ret

bomb_alive_zera:
    xor A
    ld (bomb_alive), A
    ret




update_airplane:
    ld a, (cursor_x)
    add a, 2
    cp 126
    JP NC, update_airplane_zero
    ld (cursor_x), A
    ld a, (cursor_y)
    cp 50
    JP NC, fim_de_jogo

    RET
update_airplane_zero:
    xor a
    ld (cursor_x), A
    LD A, (cursor_y)
    ADD A, 8
    LD (cursor_y), A
    RET

fim_de_jogo:
    LD BC, $1E2B
    CALL SET_CURSOR

    LD A, 0
    LD DE, msg_gameover
    CALL SEND_STRING_TO_GLCD
fim_de_jogo_loop:
    in A, (GAMEPAD)
    bit 2, A
    JP Z, fim_de_jogo_loop
    JP init


bomb_fire:
    ld a, (bomb_alive)
    cp 0
    RET NZ
    ld a, (cursor_x)
    cp 120
    ret NC
    ld a, 1
    ld (bomb_alive), A
    ld a, (cursor_x)
    add a, 4
    ld (bomb_x), A
    ld a, (cursor_y)
    add a, 2
    ld (bomb_y), A
    RET

msg_start      .db "Press START",0
msg_gameover   .db "GAMEOVER",0

gameover:   .db 0x00
cursor_x:   .db 0x00
cursor_y:   .db 0x00
bomb_x:     .db 0x00
bomb_y:     .db 0x00
bomb_alive  .db 0x00
;predios XY
predios     .dw 0x132E, 0x193F, 0x2e33, 0x343F, 0x4630, 0x4c3F, 0x582E, 0x5e3F, 0x6a33, 0x703F

airplane: .db 0x01, 0x00, 0x00, 0xC0, 0xC0, 0xC0, 0x7F, 0xFE, 0x1F, 0xFF, 0x01, 0x80, 0x01, 0x80, 0x03, 0x00

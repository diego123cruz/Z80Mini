
speed:         .equ 12       ;time delay before shift

               .org  2000h

               ld de,dis_buff      ;DE is pointer into dis_buff
               ld hl,ASCII_tab     ;HL points to character to display
               ld (code_buff),hl   ;save pointer
loop:          ld hl,(code_buff)   ;looping here: get pointer
               ld a,(hl)           ;put character code in A
               inc hl              ;up pointer to next char
               ld (code_buff),hl   ;save pointer
               cp 0ffh             ;done all characters?
               jr z,scaninit       ;jump if ffh as all converted
               ld l,a              ;put char code into HL
               ld h,0              ;zero H
               push hl             ;put char code into BC also
               pop bc              ;by using the stack
               or a                ;this clears carry flag
               adc hl,hl           ;double char code
               adc hl,hl           ;double char code again (x4)
               adc hl,bc           ;add original char code (x5)
               ld bc,char_tab-(20h*5)  ;load BC with base of character
               adc hl,bc           ;table; add offset
               ld bc,5             ;now setup for transfer of 5 bytes
               ldir                ;from (HL) to (DE); do transfer
               xor a               ;clear A
               ld (de),a           ;add space to end of char
               inc de              ;next display buffer location
               jr loop             ;do rest of characters

scaninit:      ld a,0ffh           ;mark end of display buffer
               ld (de),a           ;pointed to by DE
 
scan_in2:      ld hl,dis_buff      ;point HL to start of dis_buff
               ld (ptr1),hl        ;save start
               or a                ;clear carry
               ld de,08            ;now get start for second 8x8
               adc hl,de           ;8 bytes from first
               ld (ptr2),hl        ;save second start
scan_dly:      ld b,speed          ;static scan time
scan_lp1:      push bc             ;save scan time
               ld hl,(ptr1)        ;move pointer to
               ld (aptr1),hl       ;working pointer buffer
               ld hl,(ptr2)        ;second pointer
               ld (aptr2),hl       ;also
               ld b,80h            ;load B with rotating scan bit
scan_lp2:      ld hl,(aptr1)       ;get first pointer
               ld a,(hl)           ;put display code into A
               inc hl              ;up pointer
               cp 0ffh             ;is this end code?
               jr nz,notend1       ;jump away if not else reset
               ld hl,dis_buff      ;working pointer to start of buff
               ld a,(hl)           ;get display code
               inc hl              ;up pointer
notend1:       ld (aptr1),hl       ;save new working pointer
               out (82h),a         ;output first code to segments
               ld hl,(aptr2)       ;now do all again for second code
               ld a,(hl)           ;put display code into A
               inc hl              ;next
               cp 0ffh             ;end?
               jr nz,notend2       ;jump no
               ld hl,dis_buff      ;else
               ld a,(hl)           ;get first display code
               inc hl              ;up pointer to second
notend2:       ld (aptr2),hl       ;save new pointer
               out (83h),a         ;output second display byte
               ld a,b              ;get scan bit in A
               out (80h),a         ;output it to first commons
               out (81h),a         ;output it to second commons
               ld b,0              ;load B with display on time
               djnz $              ;loop here until delay finished
               ld b,a              ;return scan bit into B
               xor a               ;trick to zero A
               out (80h),a         ;clear commons to prevent ghosts
               out (81h),a         ;second commons also
               rrc b               ;shift scan bit once to the right
               jp nc,scan_lp2      ;jump if not fallen into carry flag
               pop bc              ;else all 8 scanned
               djnz scan_lp1       ;rescan until scan timer = 0
               ld hl,(ptr1)        ;now up first pointer to
               inc hl              ;shift display along
               ld a,(hl)           ;test for end
               cp 0ffh             ;of display buffer
               jr nz,ptr1_ok       ;jump if not end
               ld hl,dis_buff      ;else point to start
ptr1_ok:       ld (ptr1),hl        ;save new pointer
               ld hl,(ptr2)        ;now up second pointer to
               inc hl              ;shift display along
               ld a,(hl)           ;test for end
               cp 0ffh             ;of display buffer
               jr nz,ptr2_ok       ;jump if not end
               ld hl,dis_buff      ;else point to start
ptr2_ok:       ld (ptr2),hl        ;save new pointer
               jp scan_dly         ;jump if not else return

               .org 2100h
                                        ;char  ;ASCII code
char_tab:      .db 0,0,0,0,0              ;space  20h
               .db 0,0,7bh,0,0            ;!      21h
               .db 0,70h,0,70h,0          ;"      22h
               .db 14h,7fh,14h,7fh,14h    ;#      23h
               .db 12h,4ah,7fh,4ah,24h    ;$      24h
               .db 62h,64h,8,13h,23h      ;%      25h
               .db 36h,49h,55h,22h,5      ;&      26h
               .db 0,50h,60h,0,0          ;'      27h
               .db 0,1ch,22h,41h,0        ;(      28h
               .db 0,41h,22h,1ch,0        ;)      29h
               .db 14h,8,3eh,8,14h        ;*      2ah
               .db 8,8,3eh,8,8            ;+      2bh
               .db 0,5,6,0,0              ;,      2ch
               .db 8,8,8,8,8              ;-      2dh
               .db 0,3,3,0,0              ;.      2eh
               .db 2,4,8,10h,20h          ;/      2fh
               .db 3eh,45h,49h,51h,3eh    ;0      30h
               .db 0,21h,7fh,1,0          ;1      31h
               .db 21h,43h,45h,49h,31h    ;2      32h
               .db 42h,41h,51h,69h,46h    ;3      33h
               .db 0ch,14h,24h,7fh,4      ;4      34h
               .db 72h,51h,51h,51h,4eh    ;5      35h
               .db 1eh,29h,49h,49h,6      ;6      36h
               .db 40h,40h,4fh,50h,60h    ;7      37h
               .db 36h,49h,49h,49h,36h    ;8      38h
               .db 30h,49h,49h,4ah,3ch    ;9      39h
               .db 0,36h,36h,0,0          ;:      3ah
               .db 0,35h,36h,0,0          ;;      3bh
               .db 8,14h,22h,41h,0        ;<      3ch
               .db 14h,14h,14h,14h,14h    ;=      3dh
               .db 0,41h,22h,14h,8        ;>      3eh
               .db 20h,40h,45h,48h,30h    ;?      3fh
               .db 3eh,41h,5dh,45h,3ah    ;@      40h
               .db 3fh,44h,44h,44h,3fh    ;A      41h
               .db 7fh,49h,49h,49h,36h    ;B      42h
               .db 3eh,41h,41h,41h,22h    ;C      43h
               .db 7fh,41h,41h,41h,3eh    ;D      44h
               .db 7fh,49h,49h,49h,41h    ;E      45h
               .db 7fh,48h,48h,48h,40h    ;E      46h
               .db 3eh,41h,49h,49h,2eh    ;G      47h
               .db 7fh,8,8,8,7fh          ;H      48h
               .db 0,41h,7fh,41h,0        ;I      49h
               .db 2,1,41h,7eh,40h        ;J      4ah
               .db 7fh,8,14h,22h,41h      ;k      4bh
               .db 7fh,01,01,01,01h       ;L      4ch
               .db 7fh,20h,18h,20h,7fh    ;M      4dh
               .db 7fh,10h,8,4,7fh        ;N      4eh
               .db 3eh,41h,41h,41h,3eh    ;O      4fh
               .db 7fh,48h,48h,48h,30h    ;P      50h
               .db 3eh,41h,45h,42h,3dh    ;Q      51h
               .db 7fh,48h,4ch,4ah,31h    ;R      52h
               .db 31h,49h,49h,49h,46h    ;S      53h
               .db 40h,40h,7fh,40h,40h    ;T      54h
               .db 7eh,1,1,1,7eh          ;U      55h
               .db 7ch,2,1,2,7ch          ;V      56h
               .db 7eh,1,0eh,1,7eh        ;W      57h
               .db 63h,14h,8,14h,63h      ;X      58h
               .db 70h,08,7,8,70h         ;Y      59h
               .db 43h,45h,49h,51h,61h    ;Z      5ah
               .db 0,7fh,41h,41h,0        ;[      5bh
               .db 10h,8,4,2,1            ;\      5ch
               .db 0,41h,41h,7fh,0        ;]      5dh
               .db 10h,20h,40h,20h,10h    ;^      5eh
               .db 1,1,1,1,1              ;_      5fh
               .db 0,70h,68h,0,0          ;`      60h

               .org 2300h
               .db 2,15h,15h,15h,0fh      ;a      61h

               .org 2400h

ASCII_tab       .db "SOUTHERN CROSS SINGLE BOARD COMPUTER  "
                .db " WRITE YOUR OWN MESSAGE HERE.",0ffh

               .org 24A0h

ptr1           .equ $
ptr2           .equ ptr1+2
aptr1          .equ ptr2+2
aptr2          .equ aptr1+2
code_buff      .equ aptr2+2
dis_buff       .equ code_buff+2

               .end

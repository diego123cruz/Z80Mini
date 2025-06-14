all:		compiler 

compiler:	crt0-z80mini-loadable.s main.c ../Z80Mini.c ../Z80Mini.h
				sdasz80 -o -l -s -g crt0-z80mini-loadable.s
				sdcc -c -V --disable-warning 85 -mz80 --opt-code-size --std-sdcc99 main.c
				sdcc -c -V --disable-warning 85 -mz80 --opt-code-size --std-sdcc99 ../Z80Mini.c
				sdcc -mz80 --code-loc 0x8000 --no-std-crt0 -Wl crt0-z80mini-loadable.rel main.rel Z80Mini.rel

clear:
	del *.lk *.map *.sym *.lst *.bin *.rel *.noi *.asm 
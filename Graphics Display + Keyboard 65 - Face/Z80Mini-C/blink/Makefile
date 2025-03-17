all:
	sdcc -V --code-loc 0x8000 --data-loc 0 --disable-warning 85 -mz80 --no-std-crt0 --opt-code-size --std-sdcc99 blink.c

clear:
	del *.lk *.map *.sym *.lst *.bin *.rel *.noi *.asm *.ihx
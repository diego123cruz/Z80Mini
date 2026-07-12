camel80_gen.ihex: camel80.asm.m4 z80mini_forth.asm.m4 Makefile
	m4 camel80.asm.m4 > camel80_gen.asm
	z80asm -b camel80_gen.asm
	srec_cat camel80_gen.bin -binary -offset 0x8000 -output camel80_gen.ihex -intel -address-length=2

clean:
	rm -f camel80_gen.asm camel80_gen.bin camel80_gen.ihex

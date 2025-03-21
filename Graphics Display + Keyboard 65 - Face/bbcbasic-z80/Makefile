SRCS = main.asm exec.asm eval.asm fpp.asm hardware.asm z80mini.asm ram.asm

bbcbasic.com: $(SRCS)
	z80asm -obbcbasic.com -b -d -l -m $(SRCS)

clean:
	del -f *.o *.err *.lis *.map *.com *.bin

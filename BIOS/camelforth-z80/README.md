# camelforth-z80

This is a port of Brad Rodriguez' Z80 CamelForth to the RC2014.
It builds using z88dk, using a Makefile.
It includes the pre-built hex file, which is all you need to run it on on your very own RC2014.

To run it, set your jumpers to enter the SCM:

    Small Computer Monitor - RC2014
    *

Paste `camel80.ihx` into the terminal window.
There's no visual confirmation for about a second, and then the monitor writes:

    * Ready

Check that it loaded by inspecting memory:

    *m 8000
    8000:  21 00 FC 25 F9 24 E5 DD  E1 25 25 E5 FD E1 11 01  !..%.$...%%.....
    8010:  00 C3 8A A5 00 00 00 04  45 58 49 54 DD 5E 00 DD  ........EXIT.^..
    8020:  23 DD 56 00 DD 23 EB 5E  23 56 23 EB E9 17 90 00  #.V..#.^#V#.....
    8030:  03 4C 49 54 C5 1A 4F 13  1A 47 13 EB 5E 23 56 23  .LIT..O..G..^#V#

Then run it by jumping to address 8000:

    *G 8000
    Z80 CamelForth v1.01  25 Jan 1995


You're in! CamelForth is a 16-bit Forth, closely following the ANSI standard.
You can use ``WORDS`` to see what's available in the system.
The two CamelForth files
``glosshi.txt`` and ``glosslo.txt``
contain a full list of the available words.

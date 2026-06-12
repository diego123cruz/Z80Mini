#!/bin/bash
mkdir -p build

echo "Compilando main.c..."
sdcc -c --code-loc 0x8000 --data-loc 0 --reserve-regs-iy \
     --disable-warning 85 -mz80 --no-std-crt0 \
     --opt-code-size --std-sdcc99 -o build/ main.c

echo "Compilando Z80Mini.c..."
sdcc -c --reserve-regs-iy --disable-warning 85 -mz80 \
     --no-std-crt0 --opt-code-size --std-sdcc99 -o build/ ../Z80Mini.c

echo "Linkando..."
sdcc --code-loc 0x8000 --data-loc 0 --reserve-regs-iy \
     -mz80 --no-std-crt0 -o build/ build/main.rel build/Z80Mini.rel

echo "Pronto! Saida em build/"

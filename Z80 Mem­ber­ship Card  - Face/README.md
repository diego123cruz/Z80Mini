# Z80Mini
Circuito - https://github.com/diego123cruz/Z80Mini/blob/main/Circuito/Z80Mini.PDF

Monitor - https://github.com/diego123cruz/Z80Mini/blob/main/Moni.asm

Manual - ???

## Spec
Z80 @4Mhz

RAM 32kb @62256

ROM 32Kb @28C256 / 8Kb @28C64


## IN / OUT
Display 7 Segments 8 digits - OUT_40h_B0-B7 + 74LS145

Sensor IR - IN_40h_B7 (PullUp)

KEY_MONI/BACK - IN_40h_B5 (PullDown)

KEYS_0-F - IN_40h_B3, IN_40h_B4 + 74LS145

## BUILD
DOSBox - mount f: Users/diego/Z80Mini

F: tasm -80 -fff -c Moni.asm MONI.HEX

## BURN EEPROM - MAC OS
(32K) minipro -p 28C256 -w MONI.HEX

(8K) minipro -p AT28C64B -w MONI.HEX


## Z80 Mini
![Z80Mini](https://raw.githubusercontent.com/diego123cruz/Z80Mini/main/photos/Z80Mini.jpg)

### Main Board
![Z80Mini](https://raw.githubusercontent.com/diego123cruz/Z80Mini/main/photos/MainBoard.jpg)

### Front Board
![Z80Mini](https://raw.githubusercontent.com/diego123cruz/Z80Mini/main/photos/FrontBoard.jpg)

### Keys Board
![Z80Mini](https://raw.githubusercontent.com/diego123cruz/Z80Mini/main/photos/KeysBoard.jpg)

### 7 Segments
![Z80Mini](https://raw.githubusercontent.com/diego123cruz/Z80Mini/main/photos/7segBoard.jpg)

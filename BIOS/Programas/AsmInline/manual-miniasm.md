# Mini-Assembler de Linha — Z80Mini

Manual de uso do comando de montagem em linha do monitor, no estilo
"edit/dump" do Apple 1 / KIM-1: você digita mnemônicos Z80 um por
linha, e cada linha vira bytes de máquina gravados direto na RAM, no
endereço atual, que avança sozinho a cada instrução.

## Como iniciar

Ao entrar no assembler, ele mostra o endereço atual e espera uma
linha:

```
9000: ld a, $10
9002: out ($10), a
9004: halt
9005:
```

Uma **linha vazia** (Enter sem digitar nada) encerra o assembler e
volta pro monitor.

Uma linha com **erro de sintaxe** imprime `?` e repete o mesmo
endereço, sem gravar nada — corrija e digite de novo.

## Formato de uma linha

```
MNEMÔNICO operando1, operando2
```

- Espaços entre mnemônico, operandos e vírgula são opcionais —
  `OUT($10),A` funciona igual a `OUT ($10), A`.
- Maiúsculas/minúsculas não importam (`ld`, `LD`, `Ld` são iguais).
- Não há suporte a comentários nem a mais de uma instrução por linha.

## Números: decimal vs hexadecimal

| Escrito como | Interpretado como |
|---|---|
| `10`   | decimal (dez) |
| `$10`  | hexadecimal ($10 = 16 decimal) |

**Atenção:** esse é o erro mais fácil de cometer. `CALL 0100` monta
uma chamada para o endereço **decimal** 100 (`$0064`), não para
`$0100`. Se a intenção é um endereço/valor em hex, o `$` é
obrigatório.

## Registradores e operandos aceitos

- Registradores de 8 bits: `A B C D E H L`
- Registradores/pares de 16 bits: `BC DE HL SP` (e `AF` em `PUSH`/`POP`)
- Indireto por `HL`: `(HL)`
- Indireto por `BC`/`DE`: `(BC)`, `(DE)` — só em `LD A,(BC)` / `LD
  A,(DE)` / `LD (BC),A` / `LD (DE),A`
- Endereço direto: `(nn)` ou `($nnnn)` — em `LD A,(nn)`, `LD (nn),A`,
  `LD HL,(nn)`, `LD (nn),HL`
- Porta de I/O: `(n)` ou `($nn)` — em `IN A,(n)` / `OUT (n),A`
- Condições: `NZ Z NC C PO PE P M` (em `JP`/`CALL`/`RET`); só `NZ Z
  NC C` valem em `JR`

## Instruções suportadas

### Transferência de dados

| Sintaxe | Exemplo |
|---|---|
| `LD r,r'` | `LD A,B` |
| `LD r,n` | `LD A,$FF` |
| `LD (HL),n` | `LD (HL),$00` |
| `LD rp,nn` | `LD HL,$8000` |
| `LD A,(BC)` / `LD A,(DE)` | `LD A,(HL)` não — use `LD A,(nn)` ou registrador |
| `LD (BC),A` / `LD (DE),A` | |
| `LD A,(nn)` / `LD (nn),A` | `LD A,($9000)` |
| `LD HL,(nn)` / `LD (nn),HL` | `LD HL,($9000)` |
| `LD SP,HL` | |

### Aritmética/lógica (ALU)

`ADD ADC SUB SBC AND XOR OR CP` — aceitam `A,r` / `A,n` / `r` / `n`
(a forma sem `A,` é equivalente):

```
ADD A,B
ADD A,$05
ADD HL,DE      ; forma especial, 16 bits
XOR A          ; zera o acumulador
CP $10
```

### Incremento/decremento

```
INC A
DEC (HL)
INC HL         ; 16 bits
DEC BC
```

### Desvios

| Sintaxe | Observação |
|---|---|
| `JP nn` / `JP cc,nn` / `JP (HL)` | `nn` é o endereço alvo direto |
| `JR e` / `JR cc,e` | `e` é o **endereço alvo**, não o deslocamento — o assembler calcula o byte de offset sozinho. Só aceita `NZ Z NC C` como condição. Erro `?` se o alvo estiver fora do alcance de -128/+127 bytes |
| `DJNZ e` | mesma ideia do `JR`: `e` é o endereço alvo |
| `CALL nn` / `CALL cc,nn` | |
| `RET` / `RET cc` | |

### Pilha

```
PUSH BC
POP AF
```

### I/O

```
IN A,($01)
OUT ($01),A
```

### Troca de registradores

```
EX DE,HL
EX AF,AF'
EXX
```

### Sem operando

```
HALT NOP DI EI DAA CPL SCF CCF RLCA RRCA RLA RRA
```

## Não suportado nesta versão

- Instruções prefixadas `CB` (`BIT`, `SET`, `RES`, `RLC r`, `SRL r`
  etc.)
- Instruções prefixadas `ED` além das já cobertas (`LDIR`, `LDDR`,
  `CPIR`, `LD (nn),BC/DE/SP`, `NEG`, `IM`, etc.)
- Modos indexados `IX`/`IY` (`LD A,(IX+d)` etc.)
- Labels e referências para frente — todo endereço em `JP`/`JR`/
  `CALL`/`DJNZ` tem que ser digitado por extenso (`$nnnn`), inclusive
  para saltar pra frente dentro do próprio código que você está
  montando.

## Dicas de uso

- Pra testar um trecho pequeno sem se preocupar com endereço, monte
  primeiro e confira o resultado com o comando de dump do monitor
  antes de rodar (`CALL`/`JP` pro endereço montado).
- Erro `?` sem crash: a sintaxe da linha não bateu com nenhuma forma
  reconhecida — revise vírgulas, parênteses e o prefixo `$`.
- Se o assembler travar (não devolver o prompt), é sinal de bug no
  parser, não de erro de digitação — o comportamento esperado pra
  qualquer entrada malformada é sempre `?`, nunca travar.

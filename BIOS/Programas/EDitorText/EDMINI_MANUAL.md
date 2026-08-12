# EDMINI — Manual do Editor de Texto (estilo ED.COM)

Editor de texto orientado a linha para o **Z80Mini**, inspirado no `ED.COM`
do CP/M. Roda em RAM a partir de `0x8000` e é chamado pela tecla **LUZ**
(`CALL 8000H`).

Arquivo fonte: `EDMINI.asm` — monta com `zasm`.

---

## 1. Por que "orientado a linha"?

O `ED.COM` original do CP/M não é um editor de tela cheia — ele funciona
como um console: você digita um comando de uma letra, o editor mostra ou
altera uma linha do texto, e a tela rola como um terminal normal. O EDMINI
segue o mesmo espírito, o que combina bem com a tela de 128x64: não é
preciso redesenhar a tela inteira a cada tecla, só imprimir texto que rola
para cima (`autoLF` do GLCD).

Não há cursor livre pela tela nem seleção com setas — tudo é feito por
**número de linha** e comandos de uma letra.

---

## 2. Iniciando o editor

Pressione a tecla **LUZ** no teclado do Z80Mini (isso executa `CALL 8000H`,
onde o EDMINI foi carregado). Ao abrir, ele mostra a tela de ajuda e o
prompt:

```
EDMINI - editor de linha
I=Insere A=Adiciona D=Apaga
N=Prox P=Ant G<n>=Ir p/ linha
L=Lista W=Envia p/ serial
E=Sai H=Ajuda

*
```

O `*` é o prompt. Digite um comando e pressione **ENTER**.

---

## 3. Comandos

| Comando | Ação |
|---|---|
| `I` | Insere linha(s) **antes** da linha atual |
| `A` | Adiciona linha(s) **depois** da linha atual |
| `D` | Apaga a linha atual |
| `N` | Vai para a **próxima** linha e mostra |
| `P` | Vai para a linha **anterior** e mostra |
| `G<num>` | Vai direto para a linha `<num>` (ex.: `G10`) |
| `L` | Lista o buffer inteiro (pausa a cada algumas linhas) |
| `W` | Envia o buffer inteiro pela **serial** (ver seção 6) |
| `H` ou `?` | Mostra a tela de ajuda novamente |
| `E` | Sai do editor e volta para o monitor |

Comandos aceitam letra maiúscula ou minúscula (`i` funciona igual a `I`).

### Durante a digitação de uma linha
- **ENTER** confirma a linha.
- **BACKSPACE/DEL** apaga o último caractere digitado.
- **ESC** cancela a linha atual (comando ou texto) e volta ao prompt.

### Durante `I` ou `A` (modo de inserção)
Depois de `I` ou `A`, o editor entra em modo de entrada de texto:

```
Digite o texto (ENTER vazio termina, ESC cancela)
```

Digite uma linha, ENTER, digite a próxima, ENTER... Para **terminar**,
pressione ENTER numa linha vazia. Para **cancelar tudo**, pressione ESC.

---

## 4. Exemplo de uso

Criar um texto do zero (buffer começa vazio):

```
*I
Digite o texto (ENTER vazio termina, ESC cancela)
Ola mundo
Este e um teste
do editor EDMINI
[ENTER vazio aqui termina a insercao]
```

Depois disso o buffer tem 3 linhas e a linha atual é a 3. Para ver tudo:

```
*L
1: Ola mundo
2: Este e um teste
3: do editor EDMINI
```

Ir para a linha 2, corrigir (apagando e reinserindo) e adicionar uma linha
nova no final:

```
*G2
2: Este e um teste
*D
Linha apagada
2: do editor EDMINI
*I
Digite o texto (ENTER vazio termina, ESC cancela)
Este eh soh um teste
[ENTER vazio]
*G3
3: Este eh soh um teste
*A
Digite o texto (ENTER vazio termina, ESC cancela)
Ultima linha do arquivo
[ENTER vazio]
```

> Não existe comando de "substituir linha direto" — para corrigir uma
> linha, apague-a (`D`) e insira o texto certo no lugar (`I`).

---

## 5. Números de linha

- Começam em **1**.
- São de **1 byte** (0-255): o buffer aceita no máximo **255 linhas**.
- Depois de `D` (apagar), as linhas seguintes "sobem" um número — a linha
  que antes era 5 vira 4, e assim por diante.
- `G<num>` aceita espaço opcional depois do `G` (`G 10` funciona igual a
  `G10`).

---

## 6. Salvando o texto (comando `W`)

A API do Z80Mini usada aqui não tem rotinas de sistema de arquivos
(EEPROM/flash), então o EDMINI não "salva" para um disco. Em vez disso, o
comando `W` **envia o buffer inteiro pela porta serial**, uma linha de
texto por linha, terminada em CR/LF — ou seja, é uma forma de exportar o
texto para ser capturado por um terminal serial no PC (e colado de volta
depois, se precisar).

Se você tiver (ou vier a criar) rotinas de gravação em EEPROM/flash, é só
trocar a rotina `CMD_WRITE` no fonte por chamadas a elas — o restante do
editor não precisa mudar.

---

## 7. Limitações conhecidas (de propósito, para manter simples)

- Máximo de 255 linhas (número de linha de 1 byte).
- Tamanho máximo de cada linha: 60 caracteres (`MAXLINE`, ajustável no
  topo do fonte).
- Área de texto: 4096 bytes por padrão (`BUFSIZE`, ajustável).
- Sem desfazer (undo), sem busca/substituição, sem numeração automática.
- Sem sistema de arquivos — salvar é enviar pela serial (`W`).
- Se o buffer encher, o editor avisa `Buffer cheio!` e não perde nada do
  que já existe (a inserção que não coube simplesmente não é feita).

---

## 8. Ajustando para o seu hardware

No topo do `EDMINI.asm`:

```asm
MAXLINE:  EQU 60      ; tamanho máximo de uma linha de texto digitada
BUFSIZE:  EQU 4096    ; tamanho da área de armazenamento do texto
PAGESIZE: EQU 6        ; linhas mostradas por "página" no comando L
```

Aumente `BUFSIZE` conforme a RAM livre acima do programa. `PAGESIZE`
controla de quantas em quantas linhas o comando `L` pausa esperando uma
tecla (com ESC você cancela a listagem no meio).

Duas suposições sobre o driver do LCD/teclado, caso precise ajustar:

- O editor manda `BKS, SPACE, BKS` para apagar visualmente um caractere,
  para funcionar mesmo que `sendCharToLCD` não trate `0x08` sozinho.
- O editor ignora qualquer tecla lida pelo `keyboardWaitA` com valor acima
  de `0x7E` (as teclas especiais como Shift/Ctrl/Alt/Fn do teclado do
  Z80Mini), para não digitar lixo no texto.

---

## 9. Onde o buffer fica na memória

Cada linha é gravada como `[tamanho: 1 byte][texto: "tamanho" bytes]`, uma
atrás da outra, a partir do rótulo `BUFSTART`. Não há separador entre
linhas — o próprio byte de tamanho indica onde a próxima começa. Isso é
interno ao editor; não é preciso mexer nisso para usá-lo, mas é útil saber
caso queira ler o buffer de outro programa (por exemplo, um montador que
rode em seguida usando o mesmo texto).

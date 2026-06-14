"""
Labirinto

Gera um labirinto pequeno (grid 9x7) com DFS, jogador navega com
w/a/s/d (cima/esquerda/baixo/direita) + ENTER ate chegar na saida.

Tela 20x10: grid de 9 colunas x 7 linhas (9x7=9 chars largura, 7 altura)
+ linha de instrucoes.

Contrato: play(conn, helpers)
"""

import random

GRID_W = 9
GRID_H = 7

WALL = "#"
FLOOR = "."
PLAYER = "@"
EXIT = "E"

MOVES = {
    "w": (0, -1),
    "s": (0, 1),
    "a": (-1, 0),
    "d": (1, 0),
}


def gen_maze(w, h):
    """Gera labirinto com DFS em grid de celulas (w x h), cada celula
    ocupando 1 posicao; paredes entre celulas. Retorna grid binario
    (True = parede) de tamanho (2w+1) x (2h+1) -- mas para caber em
    20x10 usamos diretamente w x h celulas como grid de jogo, sem
    duplicar para paredes (labirinto "denso", paredes finas dentro da
    propria celula via bitmask). Aqui simplificamos: grid w x h onde
    cada celula e FLOOR, e geramos um caminho garantido aleatorio do
    inicio ao fim, com algumas paredes extras aleatorias que nao
    bloqueiam o caminho gerado.
    """
    # grid todo aberto inicialmente
    grid = [[FLOOR for _ in range(w)] for _ in range(h)]

    start = (0, 0)
    end = (w - 1, h - 1)

    # gera um caminho aleatorio (random walk com bias) de start a end
    visited = set()
    path = set()
    stack = [start]
    visited.add(start)

    while stack:
        cx, cy = stack[-1]
        if (cx, cy) == end:
            path.update(visited)
            break
        neighbors = []
        for dx, dy in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                neighbors.append((nx, ny))
        if neighbors:
            # bias: prefere ir em direcao ao end
            neighbors.sort(key=lambda p: abs(p[0] - end[0]) + abs(p[1] - end[1]))
            if random.random() < 0.7:
                nxt = neighbors[0]
            else:
                nxt = random.choice(neighbors)
            visited.add(nxt)
            stack.append(nxt)
        else:
            stack.pop()

    path.update(visited)

    # adiciona algumas celulas extras (ramais) para nao ser corredor unico
    extra_tries = w * h
    for _ in range(extra_tries):
        x = random.randrange(w)
        y = random.randrange(h)
        if (x, y) in path:
            continue
        # so adiciona se for adjacente a uma celula do caminho (ramal)
        for dx, dy in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
            nx, ny = x + dx, y + dy
            if (nx, ny) in path:
                if random.random() < 0.5:
                    path.add((x, y))
                break

    for y in range(h):
        for x in range(w):
            grid[y][x] = FLOOR if (x, y) in path else WALL

    grid[start[1]][start[0]] = FLOOR
    grid[end[1]][end[0]] = FLOOR

    return grid, start, end


def render(grid, player, end):
    w = len(grid[0])
    h = len(grid)
    lines = []
    for y in range(h):
        row = []
        for x in range(w):
            if (x, y) == player:
                row.append(PLAYER)
            elif (x, y) == end:
                row.append(EXIT)
            else:
                row.append(grid[y][x])
        lines.append("".join(row))
    return "\n".join(lines)


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  LABIRINTO\n"
        "\n"
        "Mova com w a s d\n"
        "+ ENTER\n"
        "w=cima a=esq\n"
        "s=baixo d=dir\n"
        "\n"
        "@ = voce\n"
        "E = saida\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        grid, start, end = gen_maze(GRID_W, GRID_H)
        player = start
        moves_count = 0

        while True:
            clear_screen()
            send(render(grid, player, end))
            send("\n\n")

            if player == end:
                send(f"CHEGOU! ({moves_count} mov.)\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            send("w/a/s/d: ")
            line = recv_line()
            if line is None:
                return
            if line == ".":
                return

            line = line.lower().strip()
            if not line:
                continue
            d = line[0]
            if d not in MOVES:
                continue

            dx, dy = MOVES[d]
            nx, ny = player[0] + dx, player[1] + dy
            if 0 <= nx < GRID_W and 0 <= ny < GRID_H and grid[ny][nx] == FLOOR:
                player = (nx, ny)
                moves_count += 1

"""
Batalha Naval (6x6)

Voce e a CPU posicionam navios automaticamente (aleatorio).
Voce ataca o tabuleiro da CPU; CPU ataca o seu.
Jogada: coluna(1-6) + linha(a-f), ex: "c3" ou "3c"

Tabuleiros: 6x6
Navios: tamanhos 3, 2, 2 (total 7 casas) por jogador

Tela 20x10: mostra um tabuleiro por vez (alterna "seu" / "inimigo"
via tecla 'v'), ou ambos compactados.

Contrato: play(conn, helpers)
"""

import random

N = 6
ROW_LETTERS = "abcdef"
COL_DIGITS = "123456"

SHIP_SIZES = [3, 2, 2]

EMPTY = "."
SHIP = "S"
HIT = "X"
MISS = "o"


def new_board():
    return [[EMPTY for _ in range(N)] for _ in range(N)]


def place_ships(board):
    for size in SHIP_SIZES:
        placed = False
        while not placed:
            horizontal = random.random() < 0.5
            if horizontal:
                r = random.randrange(N)
                c = random.randrange(N - size + 1)
                cells = [(r, c + i) for i in range(size)]
            else:
                r = random.randrange(N - size + 1)
                c = random.randrange(N)
                cells = [(r + i, c) for i in range(size)]

            if all(board[rr][cc] == EMPTY for rr, cc in cells):
                for rr, cc in cells:
                    board[rr][cc] = SHIP
                placed = True


def parse_move(s):
    if len(s) != 2:
        return None
    s = s.lower()
    c0, c1 = s[0], s[1]
    if c0 in ROW_LETTERS and c1 in COL_DIGITS:
        return ROW_LETTERS.index(c0), COL_DIGITS.index(c1)
    if c1 in ROW_LETTERS and c0 in COL_DIGITS:
        return ROW_LETTERS.index(c1), COL_DIGITS.index(c0)
    return None


def draw_own(board):
    """Mostra navios proprios + tiros recebidos."""
    lines = []
    lines.append("  123456  SEU")
    for r in range(N):
        lines.append(f"{ROW_LETTERS[r]} {''.join(board[r])}")
    return "\n".join(lines)


def draw_enemy(board):
    """Mostra apenas o que foi descoberto (esconde navios nao atingidos)."""
    lines = []
    lines.append("  123456  INIMIGO")
    for r in range(N):
        row = []
        for c in range(N):
            cell = board[r][c]
            if cell == SHIP:
                row.append(EMPTY)  # esconde
            else:
                row.append(cell)
        lines.append(f"{ROW_LETTERS[r]} {''.join(row)}")
    return "\n".join(lines)


def total_ship_cells():
    return sum(SHIP_SIZES)


def ships_remaining(board):
    return sum(row.count(SHIP) for row in board)


def cpu_attack(board, ai_state):
    """IA simples: ataca aleatorio, mas se acertar tenta vizinhos
    (modo 'cacador')."""
    targets = ai_state.get("targets", [])

    while targets:
        r, c = targets.pop(0)
        if board[r][c] in (HIT, MISS):
            continue
        return r, c

    # ataque aleatorio
    while True:
        r = random.randrange(N)
        c = random.randrange(N)
        if board[r][c] not in (HIT, MISS):
            return r, c


def apply_attack(board, r, c, ai_state=None):
    """Retorna True se acertou navio."""
    hit = board[r][c] == SHIP
    board[r][c] = HIT if hit else MISS

    if ai_state is not None and hit:
        # adiciona vizinhos como proximos alvos (modo cacador)
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if 0 <= nr < N and 0 <= nc < N and board[nr][nc] not in (HIT, MISS):
                ai_state.setdefault("targets", []).append((nr, nc))

    return hit


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  BATALHA NAVAL\n"
        "\n"
        "Tabuleiro 6x6.\n"
        "Ataque: letra+num\n"
        "ex: a1, c4\n"
        "\n"
        "S=seu navio\n"
        "X=acerto o=erro\n"
        "\n"
        "Afunde tudo p/ vencer\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        my_board = new_board()
        enemy_board = new_board()
        place_ships(my_board)
        place_ships(enemy_board)

        ai_state = {}
        total = total_ship_cells()
        view = "enemy"  # 'enemy' ou 'own'

        while True:
            clear_screen()
            my_remaining = ships_remaining(my_board)
            enemy_remaining = ships_remaining(enemy_board)

            if view == "enemy":
                send(draw_enemy(enemy_board))
            else:
                send(draw_own(my_board))

            send("\n")
            send(f"Voc:{total - my_remaining}/{total} ")
            send(f"CPU:{total - enemy_remaining}/{total}\n")

            if enemy_remaining == 0:
                send("\nVOCE VENCEU!\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            if my_remaining == 0:
                send("\nCPU VENCEU!\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            send("v=ver seu tab.\n")
            send("Ataque: ")

            line = recv_line()
            if line is None:
                return
            if line == ".":
                return

            low = line.lower().strip()
            if low == "v":
                view = "own" if view == "enemy" else "enemy"
                continue

            pos = parse_move(line)
            if not pos:
                continue
            r, c = pos
            if enemy_board[r][c] in (HIT, MISS):
                continue

            apply_attack(enemy_board, r, c)

            # CPU ataca
            cr, cc = cpu_attack(my_board, ai_state)
            apply_attack(my_board, cr, cc, ai_state)

            view = "enemy"

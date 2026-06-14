"""
Reversi / Othello (tabuleiro 6x6)

Jogador = X, CPU = O. Casas vazias = '.'
Jogada: coluna(1-6) + linha(a-f), ex: "c3" ou "3c"

Contrato: play(conn, helpers)
"""

N = 6  # tamanho do tabuleiro (NxN)

ROW_LETTERS = "abcdef"  # linhas a-f
COL_DIGITS = "123456"   # colunas 1-6

DIRECTIONS = [(-1, -1), (-1, 0), (-1, 1),
               (0, -1),          (0, 1),
               (1, -1),  (1, 0),  (1, 1)]


def new_board():
    b = [["." for _ in range(N)] for _ in range(N)]
    mid = N // 2
    b[mid - 1][mid - 1] = "O"
    b[mid][mid] = "O"
    b[mid - 1][mid] = "X"
    b[mid][mid - 1] = "X"
    return b


def parse_move(s):
    """Aceita 'a1'..'f6' ou '1a'..'6f'. Retorna (row, col) ou None."""
    if len(s) != 2:
        return None
    s = s.lower()
    c0, c1 = s[0], s[1]

    if c0 in ROW_LETTERS and c1 in COL_DIGITS:
        row = ROW_LETTERS.index(c0)
        col = COL_DIGITS.index(c1)
    elif c1 in ROW_LETTERS and c0 in COL_DIGITS:
        row = ROW_LETTERS.index(c1)
        col = COL_DIGITS.index(c0)
    else:
        return None
    return row, col


def opponent(p):
    return "O" if p == "X" else "X"


def flips_for_move(board, row, col, player):
    """Retorna lista de celulas (r,c) que seriam viradas se 'player'
    jogasse em (row, col). Lista vazia = jogada invalida."""
    if board[row][col] != ".":
        return []

    opp = opponent(player)
    all_flips = []

    for dr, dc in DIRECTIONS:
        r, c = row + dr, col + dc
        line = []
        while 0 <= r < N and 0 <= c < N and board[r][c] == opp:
            line.append((r, c))
            r += dr
            c += dc
        if line and 0 <= r < N and 0 <= c < N and board[r][c] == player:
            all_flips.extend(line)

    return all_flips


def valid_moves(board, player):
    moves = {}
    for r in range(N):
        for c in range(N):
            flips = flips_for_move(board, r, c, player)
            if flips:
                moves[(r, c)] = flips
    return moves


def apply_move(board, row, col, player, flips):
    board[row][col] = player
    for r, c in flips:
        board[r][c] = player


def count_pieces(board):
    x = sum(row.count("X") for row in board)
    o = sum(row.count("O") for row in board)
    return x, o


def draw(board):
    lines = []
    lines.append("  123456")
    for r in range(N):
        lines.append(f"{ROW_LETTERS[r]} {''.join(board[r])}")
    return "\n".join(lines)


def ai_choose(board, player):
    """CPU: escolhe jogada que maximiza pecas viradas, com leve
    preferencia por cantos."""
    moves = valid_moves(board, player)
    if not moves:
        return None

    corners = {(0, 0), (0, N - 1), (N - 1, 0), (N - 1, N - 1)}

    def score(item):
        (r, c), flips = item
        s = len(flips)
        if (r, c) in corners:
            s += 5
        return s

    best = max(moves.items(), key=score)
    return best[0]


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  REVERSI/OTHELLO\n"
        "\n"
        "Voce e X, CPU e O.\n"
        "Jogue: letra+num\n"
        "ex: a1, c4\n"
        "Vira as pecas do\n"
        "adversario.\n"
        "Mais pecas ganha!\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        board = new_board()
        human, ai = "X", "O"
        turn_human = True

        while True:
            clear_screen()
            send(draw(board))
            send("\n")
            x, o = count_pieces(board)
            send(f"X:{x} O:{o}\n")

            human_moves = valid_moves(board, human)
            ai_moves = valid_moves(board, ai)

            if not human_moves and not ai_moves:
                # fim de jogo
                if x > o:
                    send("\nVOCE GANHOU!\n")
                elif o > x:
                    send("\nCPU GANHOU!\n")
                else:
                    send("\nEMPATE!\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            if turn_human:
                if not human_moves:
                    send("\nSem jogadas! Passa.\n")
                    send("ENTER p/ continuar")
                    line = recv_line(echo=False)
                    if line == ".":
                        return
                    turn_human = False
                    continue

                send("\nSua vez: ")
                while True:
                    line = recv_line()
                    if line is None:
                        return
                    if line == ".":
                        return
                    pos = parse_move(line)
                    if pos and pos in human_moves:
                        apply_move(board, pos[0], pos[1], human, human_moves[pos])
                        break
                    send("\nInvalido. Tente: ")
                turn_human = False
            else:
                if not ai_moves:
                    turn_human = True
                    continue
                send("\nCPU pensando...\n")
                pos = ai_choose(board, ai)
                if pos:
                    flips = ai_moves[pos]
                    apply_move(board, pos[0], pos[1], ai, flips)
                turn_human = True

"""
Jogo da Velha (Tic Tac Toe)

Toda vez que o cliente entra nesse jogo, o servidor recarrega este
modulo do disco (importlib.reload), entao alteracoes salvas aqui
aparecem na proxima vez que alguem jogar - sem reiniciar o servidor
nem derrubar outras conexoes ativas.

Contrato: este modulo expoe a funcao play(conn, helpers)
- conn: socket do cliente
- helpers: objeto com send(text), clear_screen(), recv_line(echo=True)
"""

ROW_LETTERS = {"a": 0, "b": 1, "c": 2}
COL_DIGITS = {"1": 0, "2": 1, "3": 2}

WIN_LINES = [
    (0, 1, 2), (3, 4, 5), (6, 7, 8),
    (0, 3, 6), (1, 4, 7), (2, 5, 8),
    (0, 4, 8), (2, 4, 6),
]


def parse_move(s):
    """Aceita 'a1', '1a', etc. Retorna indice 0-8 ou None se invalido."""
    if len(s) != 2:
        return None
    s = s.lower()
    c0, c1 = s[0], s[1]

    if c0 in ROW_LETTERS and c1 in COL_DIGITS:
        row, col = ROW_LETTERS[c0], COL_DIGITS[c1]
    elif c1 in ROW_LETTERS and c0 in COL_DIGITS:
        row, col = ROW_LETTERS[c1], COL_DIGITS[c0]
    else:
        return None

    return row * 3 + col


def draw_board(board):
    b = board
    lines = []
    lines.append("    1 2 3")
    lines.append("   ______")
    lines.append(f"a | {b[0]} {b[1]} {b[2]}")
    lines.append(f"b | {b[3]} {b[4]} {b[5]}")
    lines.append(f"c | {b[6]} {b[7]} {b[8]}")
    return "\n".join(lines)


def check_winner(b):
    for a, c, d in WIN_LINES:
        if b[a] != "." and b[a] == b[c] == b[d]:
            return b[a]
    if "." not in b:
        return "DRAW"
    return None


def ai_move(b, ai_symbol, human_symbol):
    # 1) tenta ganhar
    for i in range(9):
        if b[i] == ".":
            b[i] = ai_symbol
            if check_winner(b) == ai_symbol:
                return i
            b[i] = "."
    # 2) tenta bloquear
    for i in range(9):
        if b[i] == ".":
            b[i] = human_symbol
            if check_winner(b) == human_symbol:
                b[i] = "."
                return i
            b[i] = "."
    # 3) centro
    if b[4] == ".":
        return 4
    # 4) cantos
    for i in (0, 2, 6, 8):
        if b[i] == ".":
            return i
    # 5) qualquer
    for i in range(9):
        if b[i] == ".":
            return i
    return -1


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  JOGO DA VELHA\n"
        "\n"
        "Voce e X, CPU e O.\n"
        "Jogue: letra+num\n"
        "ex: a1, b2, c3\n"
        "\n"
        "    1 2 3\n"
        "  _______\n"
        "a |\n"
        "b |\n"
        "c |\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    board = ["."] * 9
    human, ai = "X", "O"
    turn_human = True

    while True:
        clear_screen()
        send(draw_board(board))
        send("\n\n")

        winner = check_winner(board)
        if winner:
            if winner == "DRAW":
                send("EMPATE!\n")
            elif winner == human:
                send("VOCE GANHOU!\n")
            else:
                send("CPU GANHOU!\n")
            send("\n. menu / ENTER novo")
            line = recv_line(echo=False)
            if line == ".":
                return
            board = ["."] * 9
            human, ai = "X", "O"
            turn_human = True
            continue

        if turn_human:
            send("Sua vez: ")
            while True:
                line = recv_line()
                if line is None:
                    return
                if line == ".":
                    return
                pos = parse_move(line)
                if pos is not None and board[pos] == ".":
                    board[pos] = human
                    break
                send("\nInvalido. Tente: ")
            turn_human = False
        else:
            send("CPU pensando...\n")
            pos = ai_move(board, ai, human)
            if pos >= 0:
                board[pos] = ai
            turn_human = True

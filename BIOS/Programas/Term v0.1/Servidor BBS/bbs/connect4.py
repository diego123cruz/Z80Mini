"""
Connect 4

Toda vez que o cliente entra nesse jogo, o servidor recarrega este
modulo do disco (importlib.reload), entao alteracoes salvas aqui
aparecem na proxima vez que alguem jogar - sem reiniciar o servidor
nem derrubar outras conexoes ativas.

Contrato: este modulo expoe a funcao play(conn, helpers)
- conn: socket do cliente
- helpers: objeto com send(text), clear_screen(), recv_line(echo=True)
"""

C4_COLS = 7
C4_ROWS = 6


def new_board():
    # board[col][row], row 0 = base (baixo)
    return [["." for _ in range(C4_ROWS)] for _ in range(C4_COLS)]


def draw(board):
    lines = []
    lines.append("1234567")
    for row in range(C4_ROWS - 1, -1, -1):
        line = "".join(board[col][row] for col in range(C4_COLS))
        lines.append(line)
    return "\n".join(lines)


def drop(board, col, symbol):
    """Solta peca na coluna. Retorna row onde caiu, ou -1 se coluna cheia."""
    for row in range(C4_ROWS):
        if board[col][row] == ".":
            board[col][row] = symbol
            return row
    return -1


def col_full(board, col):
    return board[col][C4_ROWS - 1] != "."


def check_winner(board, last_col, last_row):
    """Verifica vitoria a partir da ultima jogada (last_col, last_row)."""
    if last_col is None:
        return None
    symbol = board[last_col][last_row]
    if symbol == ".":
        return None

    directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
    for dc, dr in directions:
        count = 1
        c, r = last_col + dc, last_row + dr
        while 0 <= c < C4_COLS and 0 <= r < C4_ROWS and board[c][r] == symbol:
            count += 1
            c += dc
            r += dr
        c, r = last_col - dc, last_row - dr
        while 0 <= c < C4_COLS and 0 <= r < C4_ROWS and board[c][r] == symbol:
            count += 1
            c -= dc
            r -= dr
        if count >= 4:
            return symbol

    if all(col_full(board, c) for c in range(C4_COLS)):
        return "DRAW"
    return None


def ai_move(board, ai_symbol, human_symbol):
    valid_cols = [c for c in range(C4_COLS) if not col_full(board, c)]

    # 1) tenta ganhar
    for c in valid_cols:
        row = drop(board, c, ai_symbol)
        win = check_winner(board, c, row)
        board[c][row] = "."
        if win == ai_symbol:
            return c

    # 2) tenta bloquear
    for c in valid_cols:
        row = drop(board, c, human_symbol)
        win = check_winner(board, c, row)
        board[c][row] = "."
        if win == human_symbol:
            return c

    # 3) prefere centro
    for c in (3, 2, 4, 1, 5, 0, 6):
        if c in valid_cols:
            return c

    return valid_cols[0] if valid_cols else -1


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  CONNECT 4\n"
        "\n"
        "Voce e X, CPU e O.\n"
        "Escolha a coluna 1-7\n"
        "para soltar a peca.\n"
        "Alinhe 4 para ganhar!\n"
        "\n"
        "1234567\n"
        ".......\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    board = new_board()
    human, ai = "X", "O"
    turn_human = True
    last_col, last_row = None, None

    while True:
        clear_screen()
        send(draw(board))
        send("\n\n")

        winner = check_winner(board, last_col, last_row)
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
            board = new_board()
            human, ai = "X", "O"
            turn_human = True
            last_col, last_row = None, None
            continue

        if turn_human:
            send("Sua vez (1-7): ")
            while True:
                line = recv_line()
                if line is None:
                    return
                if line == ".":
                    return
                if line.isdigit():
                    col = int(line) - 1
                    if 0 <= col < C4_COLS and not col_full(board, col):
                        row = drop(board, col, human)
                        last_col, last_row = col, row
                        break
                send("\nInvalido. Tente: ")
            turn_human = False
        else:
            send("CPU pensando...\n")
            col = ai_move(board, ai, human)
            if col >= 0:
                row = drop(board, col, ai)
                last_col, last_row = col, row
            turn_human = True

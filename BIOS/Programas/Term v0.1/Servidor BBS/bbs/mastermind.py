"""
Mastermind (Senha de cores/digitos)

Senha secreta de 4 digitos (1-6, podem repetir). Jogador tenta
adivinhar; recebe feedback:
  X = digito certo na posicao certa
  O = digito certo na posicao errada

Contrato: play(conn, helpers)
"""

import random

CODE_LEN = 4
DIGITS = "123456"
MAX_TENTATIVAS = 10


def gen_secret():
    return [random.choice(DIGITS) for _ in range(CODE_LEN)]


def feedback(secret, guess):
    """Retorna (certos_na_posicao, certos_fora_posicao)."""
    exact = sum(1 for s, g in zip(secret, guess) if s == g)

    # conta ocorrencias restantes para "certo, posicao errada"
    secret_left = []
    guess_left = []
    for s, g in zip(secret, guess):
        if s != g:
            secret_left.append(s)
            guess_left.append(g)

    misplaced = 0
    used = [False] * len(secret_left)
    for g in guess_left:
        for i, s in enumerate(secret_left):
            if not used[i] and s == g:
                used[i] = True
                misplaced += 1
                break

    return exact, misplaced


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  MASTERMIND\n"
        "\n"
        f"Adivinhe a senha de\n"
        f"{CODE_LEN} digitos (1-6).\n"
        "Digitos podem repetir.\n"
        "\n"
        "X = certo no lugar\n"
        "O = certo, lugar\n"
        "    errado\n"
        "\n"
        f"Max {MAX_TENTATIVAS} tentativas\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        secret = gen_secret()
        history = []

        while True:
            clear_screen()
            send("  MASTERMIND\n\n")
            if history:
                for i, (g, x, o) in enumerate(history[-6:], 1):
                    send(f"{g}  {x}X {o}O\n")
                send("\n")
            send(f"Tentativa {len(history) + 1}/{MAX_TENTATIVAS}\n")
            send(f"Senha ({CODE_LEN} digitos): ")

            line = recv_line()
            if line is None:
                return
            if line == ".":
                return

            if len(line) != CODE_LEN or not all(c in DIGITS for c in line):
                continue

            guess = list(line)
            exact, misplaced = feedback(secret, guess)
            history.append((line, exact, misplaced))

            if exact == CODE_LEN:
                clear_screen()
                send("  MASTERMIND\n\n")
                send("ACERTOU A SENHA!\n")
                send(f"Senha: {''.join(secret)}\n")
                send(f"Tentativas: {len(history)}\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            if len(history) >= MAX_TENTATIVAS:
                clear_screen()
                send("  MASTERMIND\n\n")
                send("Acabaram as tentativas!\n")
                send(f"Senha era: {''.join(secret)}\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

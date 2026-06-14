"""
Adivinhe o Numero

Contrato: play(conn, helpers)
"""

import random

MIN_NUM = 1
MAX_NUM = 100
MAX_TENTATIVAS = 7


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  ADIVINHE O NUMERO\n"
        "\n"
        f"Pensei em um numero\n"
        f"de {MIN_NUM} a {MAX_NUM}.\n"
        f"Voce tem {MAX_TENTATIVAS}\n"
        "tentativas.\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        secret = random.randint(MIN_NUM, MAX_NUM)
        tentativas = 0
        history = []

        while True:
            clear_screen()
            send("  ADIVINHE O NUMERO\n\n")
            if history:
                for h in history[-6:]:
                    send(h + "\n")
                send("\n")
            send(f"Tentativa {tentativas + 1}/{MAX_TENTATIVAS}\n")
            send(f"Faixa: {MIN_NUM}-{MAX_NUM}\n\n")
            send("Seu palpite: ")

            line = recv_line()
            if line is None:
                return
            if line == ".":
                return
            if not line.isdigit():
                continue

            guess = int(line)
            tentativas += 1

            if guess == secret:
                clear_screen()
                send("  ADIVINHE O NUMERO\n\n")
                send(f"ACERTOU!\n")
                send(f"O numero era {secret}\n")
                send(f"Tentativas: {tentativas}\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

            if guess < secret:
                history.append(f"{guess} -> MAIOR")
            else:
                history.append(f"{guess} -> MENOR")

            if tentativas >= MAX_TENTATIVAS:
                clear_screen()
                send("  ADIVINHE O NUMERO\n\n")
                send("Acabaram as tentativas!\n")
                send(f"O numero era {secret}\n")
                send("\n. menu / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    return
                break

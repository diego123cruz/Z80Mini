"""
Jogo de Dados (1 contra a CPU, melhor soma de 2 dados)

Voce e CPU jogam 2 dados cada. Quem tiver a maior soma ganha a rodada.

Layout compacto para caber em 20x10: os dois pares de dados (seu e da
CPU) sao desenhados lado a lado, 3 linhas no total.

Contrato: play(conn, helpers)
"""

import random

# Faces dos dados em ASCII, 3 linhas x 3 colunas cada
DIE_FACES = {
    1: ["...", ".O.", "..."],
    2: ["O..", "...", "..O"],
    3: ["O..", ".O.", "..O"],
    4: ["O.O", "...", "O.O"],
    5: ["O.O", ".O.", "O.O"],
    6: ["O.O", "O.O", "O.O"],
}


def roll():
    return random.randint(1, 6), random.randint(1, 6)


def draw_round(v1, v2, c1, c2):
    """Desenha os 4 dados (seus 2 + CPU 2) em 3 linhas compactas."""
    fv1, fv2 = DIE_FACES[v1], DIE_FACES[v2]
    fc1, fc2 = DIE_FACES[c1], DIE_FACES[c2]
    lines = []
    for i in range(3):
        lines.append(f"{fv1[i]} {fv2[i]}  {fc1[i]} {fc2[i]}")
    return "\n".join(lines)


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  JOGO DE DADOS\n"
        "\n"
        "Voce e CPU jogam 2\n"
        "dados cada.\n"
        "Maior soma ganha a\n"
        "rodada.\n"
        "\n"
        "ENTER p/ jogar"
    )
    recv_line(echo=False)

    placar_voce = 0
    placar_cpu = 0

    while True:
        clear_screen()
        send("  JOGO DE DADOS\n\n")
        send(f"Voce: {placar_voce}  CPU: {placar_cpu}\n\n")
        send("ENTER p/ rolar")
        line = recv_line(echo=False)
        if line == ".":
            return

        v1, v2 = roll()
        c1, c2 = roll()
        soma_v = v1 + v2
        soma_c = c1 + c2

        clear_screen()
        send("  DADOS\n\n")
        send("Voce      CPU\n")
        send(draw_round(v1, v2, c1, c2) + "\n")
        send(f"{soma_v:<10}{soma_c}\n\n")

        if soma_v > soma_c:
            send("VOCE GANHOU!\n")
            placar_voce += 1
        elif soma_c > soma_v:
            send("CPU GANHOU!\n")
            placar_cpu += 1
        else:
            send("EMPATE!\n")

        send("\n. menu / ENTER cont.")
        resp = recv_line(echo=False)
        if resp == ".":
            return

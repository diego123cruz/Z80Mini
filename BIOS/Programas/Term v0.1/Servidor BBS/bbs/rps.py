"""
Pedra, Papel e Tesoura

Contrato: play(conn, helpers)
"""

import random

CHOICES = {"p": "PEDRA", "a": "PAPEL", "t": "TESOURA"}

# o que vence o que (chave vence valor)
BEATS = {"p": "t", "a": "p", "t": "a"}


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  PEDRA PAPEL TESOURA\n"
        "\n"
        "p - Pedra\n"
        "a - Papel\n"
        "t - Tesoura\n"
        "\n"
        "Melhor de varias\n"
        "rodadas.\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    placar_voce = 0
    placar_cpu = 0

    while True:
        clear_screen()
        send("  PEDRA PAPEL TESOURA\n\n")
        send(f"Voce: {placar_voce}  CPU: {placar_cpu}\n\n")
        send("p Pedra / a Papel\n")
        send("t Tesoura\n\n")
        send("Escolha: ")

        line = recv_line()
        if line is None:
            return
        if line == ".":
            return

        line = line.lower()
        if line not in CHOICES:
            continue

        cpu = random.choice(list(CHOICES.keys()))

        clear_screen()
        send("  PEDRA PAPEL TESOURA\n\n")
        send(f"Voce: {CHOICES[line]}\n")
        send(f"CPU:  {CHOICES[cpu]}\n\n")

        if line == cpu:
            send("EMPATE!\n")
        elif BEATS[line] == cpu:
            send("VOCE GANHOU!\n")
            placar_voce += 1
        else:
            send("CPU GANHOU!\n")
            placar_cpu += 1

        send(f"\nPlacar {placar_voce} x {placar_cpu}\n")
        send("\n. menu / ENTER continua")
        resp = recv_line(echo=False)
        if resp == ".":
            return

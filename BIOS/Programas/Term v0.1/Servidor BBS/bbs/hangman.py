"""
Forca (Hangman)

Recarregado pelo servidor a cada entrada no jogo (hot reload).

Contrato: este modulo expoe a funcao play(conn, helpers)
- conn: socket do cliente
- helpers: objeto com send(text), clear_screen(), recv_line(echo=True)
"""

import random

WORDS = [
    "PYTHON", "TECLADO", "MEMORIA", "CIRCUITO", "PROGRAMA",
    "MONITOR", "BATERIA", "ROBOTICA", "GUITARRA", "FIRMWARE",
    "PROCESSADOR", "ASSEMBLY", "TERMINAL", "SERVIDOR", "IMPRESSORA",
]

MAX_ERROS = 6

# Bonequinho compacto, 1 linha por estagio (0 a 6 erros), cabe em 20x10
STAGES = [
    "  ___",
    "  o__",
    "  o__ |",
    "  o_\\ |",
    "  o_\\ |/",
    " \\o_\\ |/",
    " \\o_\\_|/",
]


def render(word, guessed, errors):
    display = " ".join(c if c in guessed else "_" for c in word)
    lines = []
    lines.append("  FORCA")
    lines.append("")
    lines.append(STAGES[errors])
    lines.append("")
    lines.append(display)
    lines.append("")
    lines.append(f"Erros: {errors}/{MAX_ERROS}")
    return "\n".join(lines)


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  FORCA\n"
        "\n"
        "Adivinhe a palavra\n"
        "letra por letra.\n"
        "\n"
        f"Max de erros: {MAX_ERROS}\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        word = random.choice(WORDS)
        guessed = set()
        errors = 0
        used = set()

        while True:
            clear_screen()
            send(render(word, guessed, errors))
            send("\n\n")

            won = all(c in guessed for c in word)
            lost = errors >= MAX_ERROS

            if won or lost:
                if won:
                    send("VOCE GANHOU!\n")
                else:
                    send(f"VOCE PERDEU!\nPalavra: {word}\n")
                send("\n. menu / ENTER novo")
                line = recv_line(echo=False)
                if line == ".":
                    return
                break  # nova palavra

            send("Letra: ")
            while True:
                line = recv_line()
                if line is None:
                    return
                if line == ".":
                    return
                line = line.upper()
                if len(line) == 1 and line.isalpha():
                    if line in used:
                        send("\nJa tentou. Outra: ")
                        continue
                    used.add(line)
                    if line in word:
                        guessed.add(line)
                    else:
                        errors += 1
                    break
                send("\nInvalido. Tente: ")

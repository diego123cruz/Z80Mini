"""
Calculadora

Avalia expressoes aritmeticas simples: + - * / ( ) e numeros.
Usa apenas os caracteres permitidos (sem eval livre).

Contrato: play(conn, helpers)
"""

import re

ALLOWED = re.compile(r"^[0-9+\-*/().\s]+$")


def safe_eval(expr):
    """Avalia expressao apos validar que so contem caracteres
    aritmeticos permitidos (numeros, + - * / ( ) . e espacos)."""
    if not expr:
        return None
    if not ALLOWED.match(expr):
        return None
    try:
        # eval restrito: sem builtins, so a expressao validada
        return eval(expr, {"__builtins__": {}}, {})
    except Exception:
        return None


def format_result(value):
    if isinstance(value, float):
        if value == int(value):
            return str(int(value))
        return f"{value:.6g}"
    return str(value)


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  CALCULADORA\n"
        "\n"
        "Digite uma expressao\n"
        "ex: 2+2*3\n"
        "Operadores: + - * /\n"
        "Parenteses: ( )\n"
        "\n"
        ". para voltar\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    history = []

    while True:
        clear_screen()
        send("  CALCULADORA\n\n")
        if history:
            for h in history[-6:]:
                send(h + "\n")
            send("\n")
        send("> ")

        line = recv_line()
        if line is None:
            return
        if line == ".":
            return
        if not line.strip():
            continue

        result = safe_eval(line)
        if result is None:
            history.append(f"{line[:14]} = ERRO")
        else:
            history.append(f"{line[:10]} = {format_result(result)}")

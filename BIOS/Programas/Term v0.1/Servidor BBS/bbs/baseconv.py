"""
Conversor de Bases (Hex / Dec / Bin)

Digite um numero com prefixo opcional:
  0x... ou h... -> hexadecimal
  0b... ou b... -> binario
  (sem prefixo) -> decimal

Mostra o valor convertido em hexadecimal, decimal e binario.

Contrato: play(conn, helpers)
"""


def parse_number(s):
    """Tenta interpretar a string como hex, bin ou decimal.
    Retorna (valor_int, base_detectada) ou (None, None) se invalido."""
    s = s.strip()
    if not s:
        return None, None

    low = s.lower()

    try:
        if low.startswith("0x"):
            return int(low, 16), "hex"
        if low.startswith("0b"):
            return int(low, 2), "bin"
        if low.startswith("h") and len(low) > 1:
            return int(low[1:], 16), "hex"
        if low.startswith("b") and len(low) > 1 and all(c in "01" for c in low[1:]):
            return int(low[1:], 2), "bin"
        # se contiver apenas 0/1 e tiver mais de 1 digito, trata como
        # decimal mesmo assim (decimal tem prioridade sobre binario
        # ambiguo, ja que o usuario pode digitar so numeros)
        return int(s, 10), "dec"
    except ValueError:
        try:
            # fallback: tenta hex puro (ex: usuario digitou "FF")
            return int(s, 16), "hex"
        except ValueError:
            return None, None


def format_bin(value):
    if value == 0:
        return "0"
    return bin(value)[2:]


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  CONV. HEX/DEC/BIN\n"
        "\n"
        "Digite um numero:\n"
        "0x1F ou h1F -> hex\n"
        "0b101 ou b101 -> bin\n"
        "123 -> decimal\n"
        "\n"
        ". p/ voltar\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        clear_screen()
        send("  CONV. HEX/DEC/BIN\n\n")
        send("hex/dec/bin: ")

        line = recv_line()
        if line is None:
            return
        if line == ".":
            return
        if not line.strip():
            continue

        value, base = parse_number(line)

        clear_screen()
        send("  CONV. HEX/DEC/BIN\n\n")
        if value is None:
            send(f"Entrada: {line[:14]}\n")
            send("Invalido!\n")
        else:
            if value < 0:
                send("Negativo nao\n")
                send("suportado.\n")
            else:
                send(f"Entrada: {line[:14]}\n")
                send(f"({base})\n\n")
                send(f"HEX: {value:X}\n")
                send(f"DEC: {value}\n")
                bin_str = format_bin(value)
                if len(bin_str) > 14:
                    # quebra binario longo em duas linhas
                    send(f"BIN: {bin_str[:14]}\n")
                    send(f"     {bin_str[14:]}\n")
                else:
                    send(f"BIN: {bin_str}\n")

        send("\nENTER p/ continuar")
        resp = recv_line(echo=False)
        if resp == ".":
            return

"""
Chat

Chat simples entre todos os usuarios conectados ao BBS. Mensagens
novas de outros usuarios aparecem automaticamente enquanto voce
digita (polling nao-bloqueante via helpers.recv_line_nb).

Digite uma mensagem + ENTER para enviar.
"." + ENTER sai do chat.

Contrato: play(conn, helpers)
"""


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    name = helpers.client_info["name"]
    broadcast = helpers.broadcast_chat
    client_info = helpers.client_info

    # esvazia fila de mensagens antigas (de antes de entrar no chat)
    client_info["chat_queue"].clear()

    clear_screen()
    send(
        "  CHAT\n"
        "\n"
        f"Voce e: {name}\n"
        "Digite e ENTER p/\n"
        "enviar.\n"
        ". p/ sair\n"
        "\n"
        "ENTER p/ comecar"
    )
    helpers.recv_line(echo=False)

    broadcast("*", f"{name} entrou no chat", exclude=client_info)

    clear_screen()
    send("  CHAT\n")
    send(f"(voce: {name})\n")
    send("------------------\n")
    send("> ")

    try:
        while True:
            # mostra mensagens novas que chegaram (de outros usuarios)
            queue = client_info["chat_queue"]
            if queue:
                send("\n")
                while queue:
                    sender, text = queue.pop(0)
                    line = f"{sender}: {text}"
                    if len(line) > 161:
                        line = line[:160] + ">"
                    send(line + "\n")
                send("> ")

            line, done = helpers.recv_line_nb(poll_timeout=0.3)
            if not done:
                continue  # timeout, volta a checar a fila

            if line is None:
                return  # conexao caiu

            if line == ".":
                return

            if line.strip():
                broadcast(name, line.strip(), exclude=client_info)
                send(f"\n[EU] {line.strip()[:160]}\n> ")
    finally:
        broadcast("*", f"{name} saiu do chat", exclude=client_info)

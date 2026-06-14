"""
Mural de Recados

Lista as ultimas mensagens deixadas por outros usuarios e permite
deixar uma nova mensagem. Persistido em bbs/data/board.json - as
mensagens sobrevivem a reinicios do servidor.

Cada mensagem pode ter ate MAX_MSG_LEN caracteres. Na lista, o texto
aparece resumido (1 linha); selecionando a mensagem (numero), ela e
exibida completa com quebra de linha em WRAP_WIDTH colunas.

Contrato: play(conn, helpers)
"""

MAX_MSG_LEN = 200
WRAP_WIDTH = 18
SUMMARY_LEN = 16


def wrap_text(text, width):
    """Quebra texto em linhas de no maximo 'width' colunas, quebrando
    em espacos quando possivel (sem cortar palavras no meio, exceto
    palavras maiores que 'width')."""
    words = text.split(" ")
    lines = []
    current = ""
    for word in words:
        while len(word) > width:
            if current:
                lines.append(current)
                current = ""
            lines.append(word[:width])
            word = word[width:]
        if not current:
            current = word
        elif len(current) + 1 + len(word) <= width:
            current += " " + word
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line
    get_messages = helpers.get_board_messages
    add_message = helpers.add_board_message
    name = helpers.client_info["name"]

    page = 0
    per_page = 5

    while True:
        messages = get_messages()
        total = len(messages)
        max_page = max(0, (total - 1) // per_page)
        page = min(page, max_page)

        # mais recentes primeiro: indice global (1-based) decrescente
        start = total - (page + 1) * per_page
        end = total - page * per_page
        start = max(0, start)
        visible = list(enumerate(messages[start:end], start=start + 1))
        visible.reverse()  # mais recente no topo da pagina

        clear_screen()
        send("  MURAL DE RECADOS\n\n")
        if not visible:
            send("(sem recados)\n")
        else:
            for idx, m in visible:
                author = m["author"][:10]
                text = m["text"]
                if len(text) > SUMMARY_LEN:
                    text = text[:SUMMARY_LEN - 1] + ">"
                send(f"{idx}.{author}: {text}\n")

        send(f"\nPag {page+1}/{max_page+1}\n")
        send("n=nova p=prox a=ant\n")
        send("num=ler . voltar\n")
        send("> ")

        line = recv_line()
        if line is None:
            return
        cmd = line.lower().strip()

        if cmd == ".":
            return
        elif cmd == "n":
            clear_screen()
            send("  NOVO RECADO\n\n")
            send(f"De: {name}\n")
            send(f"Max {MAX_MSG_LEN} caract.\n\n")
            send("Mensagem:\n> ")
            text = recv_line()
            if text is None:
                return
            text = text.strip()
            if text and text != ".":
                if len(text) > MAX_MSG_LEN:
                    text = text[:MAX_MSG_LEN]
                add_message(name, text)
            page = 0
        elif cmd == "p":
            if page < max_page:
                page += 1
        elif cmd == "a":
            if page > 0:
                page -= 1
        elif cmd.isdigit():
            idx = int(cmd)
            if 1 <= idx <= total:
                msg = messages[idx - 1]
                lines = wrap_text(msg["text"], WRAP_WIDTH)

                lpage = 0
                lines_per_page = 7
                while True:
                    lmax_page = max(0, (len(lines) - 1) // lines_per_page)
                    lpage = min(lpage, lmax_page)
                    lstart = lpage * lines_per_page
                    lend = lstart + lines_per_page

                    clear_screen()
                    send(f"  RECADO #{idx}\n")
                    send(f"  {msg['author']}\n")
                    for l in lines[lstart:lend]:
                        send(l + "\n")
                    send(f"\nPag {lpage+1}/{lmax_page+1}\n")
                    send("p=prox a=ant . volta")

                    resp = recv_line(echo=False)
                    if resp is None:
                        return
                    resp = resp.lower().strip()
                    if resp == ".":
                        break
                    elif resp == "p" and lpage < lmax_page:
                        lpage += 1
                    elif resp == "a" and lpage > 0:
                        lpage -= 1

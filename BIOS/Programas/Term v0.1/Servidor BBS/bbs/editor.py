"""
Editor de Texto Remoto

Editor simples baseado em linhas (como um "ed" minimalista), para
editar pequenos arquivos de texto no servidor a partir do terminal
20x10.

Comandos (digite no prompt "ed>"):
  l           - lista as linhas (com numeros)
  a <texto>   - adiciona uma linha no final
  i <n> <txt> - insere uma linha na posicao n
  d <n>       - apaga a linha n
  e <n> <txt> - edita (substitui) a linha n
  v <n>       - ve a linha n completa, com quebra de linha
  s           - salva no arquivo
  .           - volta ao menu (pergunta se quer salvar antes)

Na tela de arquivos:
  x <nome>    - apaga o arquivo (pede confirmacao)

Arquivos ficam em bbs/data/notes/ (criado automaticamente).

Contrato: play(conn, helpers)
"""

import os

NOTES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "notes")


def ensure_dir():
    os.makedirs(NOTES_DIR, exist_ok=True)


def safe_filename(name):
    name = "".join(c for c in name if c.isalnum() or c in ("-", "_", "."))
    name = name.strip(".")
    if not name:
        return None
    if not name.endswith(".txt"):
        name += ".txt"
    return name


def list_files():
    ensure_dir()
    return sorted(f for f in os.listdir(NOTES_DIR) if f.endswith(".txt"))


def load_file(name):
    path = os.path.join(NOTES_DIR, name)
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return [line.rstrip("\n") for line in f.readlines()]


def save_file(name, lines):
    ensure_dir()
    path = os.path.join(NOTES_DIR, name)
    with open(path, "w", encoding="utf-8") as f:
        for line in lines:
            f.write(line + "\n")


def delete_file(name):
    path = os.path.join(NOTES_DIR, name)
    try:
        os.remove(path)
        return True
    except OSError:
        return False


def wrap_text(text, width):
    """Quebra texto em linhas de no maximo 'width' colunas, sem cortar
    palavras no meio (exceto palavras maiores que 'width')."""
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


def render_lines(lines, start, count):
    out = []
    end = min(start + count, len(lines))
    for i in range(start, end):
        text = lines[i]
        if len(text) > 15:
            text = text[:14] + ">"
        out.append(f"{i+1:>2} {text}")
    if not lines:
        out.append("(vazio)")
    return out


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(
        "  EDITOR DE TEXTO\n"
        "\n"
        "Arquivos pequenos\n"
        "salvos no servidor.\n"
        "\n"
        "Comandos: l a i d e\n"
        "  v s . (sair)\n"
        "x <nome> apaga arq.\n"
        "\n"
        "ENTER p/ comecar"
    )
    recv_line(echo=False)

    while True:
        clear_screen()
        send("  ARQUIVOS\n\n")
        files = list_files()
        if files:
            for f in files[:6]:
                send(f"- {f}\n")
        else:
            send("(nenhum arquivo)\n")
        send("\nNome (novo/existente)\n")
        send("x <nome> apaga\n")
        send(". voltar\n")
        send("> ")

        line = recv_line()
        if line is None:
            return
        if line == ".":
            return

        if line.lower().startswith("x "):
            target = safe_filename(line[2:].strip())
            if target is None or target not in files:
                continue
            clear_screen()
            send(f"  APAGAR\n\n")
            send(f"Apagar '{target}'?\n")
            send("Esta acao nao pode\n")
            send("ser desfeita.\n\n")
            send("s/n: ")
            resp = recv_line()
            if resp is None:
                return
            if resp.lower().startswith("s"):
                delete_file(target)
            continue

        filename = safe_filename(line)
        if filename is None:
            continue

        lines = load_file(filename)
        dirty = False
        view_start = 0

        while True:
            clear_screen()
            send(f"  {filename}\n")
            for row in render_lines(lines, view_start, 6):
                send(row + "\n")
            mark = "*" if dirty else " "
            send(f"\n{mark}{len(lines)} linhas\n")
            send("ed> ")

            cmd_line = recv_line()
            if cmd_line is None:
                return
            if cmd_line == ".":
                if dirty:
                    send("\nSalvar antes de sair?\n")
                    send("s/n: ")
                    resp = recv_line()
                    if resp and resp.lower().startswith("s"):
                        save_file(filename, lines)
                break

            if not cmd_line:
                continue

            parts = cmd_line.split(" ", 1)
            cmd = parts[0].lower()
            rest = parts[1] if len(parts) > 1 else ""

            if cmd == "l":
                if view_start + 6 < len(lines):
                    view_start += 6
                else:
                    view_start = 0
            elif cmd == "a":
                if rest:
                    lines.append(rest)
                    dirty = True
            elif cmd == "d":
                if rest.isdigit():
                    idx = int(rest) - 1
                    if 0 <= idx < len(lines):
                        lines.pop(idx)
                        dirty = True
            elif cmd == "i":
                sub = rest.split(" ", 1)
                if len(sub) == 2 and sub[0].isdigit():
                    idx = int(sub[0]) - 1
                    if 0 <= idx <= len(lines):
                        lines.insert(idx, sub[1])
                        dirty = True
            elif cmd == "e":
                sub = rest.split(" ", 1)
                if len(sub) == 2 and sub[0].isdigit():
                    idx = int(sub[0]) - 1
                    if 0 <= idx < len(lines):
                        lines[idx] = sub[1]
                        dirty = True
            elif cmd == "v":
                if rest.isdigit():
                    idx = int(rest) - 1
                    if 0 <= idx < len(lines):
                        wrapped = wrap_text(lines[idx], 18)
                        vpage = 0
                        lines_per_page = 7
                        while True:
                            vmax_page = max(0, (len(wrapped) - 1) // lines_per_page)
                            vpage = min(vpage, vmax_page)
                            vstart = vpage * lines_per_page
                            vend = vstart + lines_per_page

                            clear_screen()
                            send(f"  LINHA {idx+1}\n")
                            for l in wrapped[vstart:vend]:
                                send(l + "\n")
                            send(f"\nPag {vpage+1}/{vmax_page+1}\n")
                            send("p=prox a=ant . volta")

                            resp = recv_line(echo=False)
                            if resp is None:
                                return
                            resp = resp.lower().strip()
                            if resp == ".":
                                break
                            elif resp == "p" and vpage < vmax_page:
                                vpage += 1
                            elif resp == "a" and vpage > 0:
                                vpage -= 1
            elif cmd == "s":
                save_file(filename, lines)
                dirty = False

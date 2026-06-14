#!/usr/bin/env python3
"""
Servidor BBS para Z80Mini + ZiModem (ESP8266)
Tela: 20x10 (modo texto), com até +10 linhas de rolagem
Fim de linha: CR ("\\r") - sem LF
Limpa tela: FF ("\\f")

Porta: 2323

HOT RELOAD:
O menu (menu.py) e cada jogo (tictactoe.py, connect4.py, ...) ficam na
pasta bbs/ e sao recarregados do disco (importlib.reload) toda vez que
o cliente entra neles. Assim, voce pode editar e salvar um jogo, e na
proxima vez que ALGUEM ENTRAR NESSE JOGO (incluindo conexoes ja ativas,
quando voltarem ao menu e entrarem de novo) o codigo novo entra em uso
- sem reiniciar o servidor e sem derrubar outras conexoes.

Para adicionar um novo jogo:
1. Crie bbs/meu_jogo.py com uma funcao play(conn, helpers)
2. Adicione uma linha em bbs/menu.py na lista GAMES:
   ("3", "Meu Jogo", "meu_jogo")
Salve os dois arquivos - na proxima vez que alguem abrir o menu, a
nova opcao ja aparece.

Uso:
    python3 bbs_server.py
"""

import socket
import threading
import importlib
import importlib.util
import sys
import os
import json

HOST = "0.0.0.0"
PORT = 2323

CR = "\r"
FF = "\f"

COLS = 20
ROWS = 10

# Se True, converte CR em CR+LF na saida (util para testar com
# telnet/nc no Debian, que esperam \r\n). O Z80Mini usa apenas \r,
# entao deixe False (padrao) nesse caso. Ativado via --crlf.
USE_CRLF = False

# Pasta onde ficam menu.py, tictactoe.py, connect4.py, etc.
BBS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bbs")

if BBS_DIR not in sys.path:
    sys.path.insert(0, BBS_DIR)


def load_module(mod_name):
    """Carrega (ou recarrega) um modulo da pasta bbs/ usando o caminho
    explicito do arquivo .py atual no disco.

    Usa importlib.util com spec_from_file_location para evitar problemas
    de cache/spec do importlib em caminhos com espacos/acentos (comum em
    'Area de trabalho', etc.), que fazem importlib.reload falhar com
    'spec not found for the module'."""
    file_path = os.path.join(BBS_DIR, mod_name + ".py")
    spec = importlib.util.spec_from_file_location(mod_name, file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    sys.modules[mod_name] = module
    return module


# ---------------------------------------------------------------------------
# Estado compartilhado entre conexoes (mural, chat, lista online)
# ---------------------------------------------------------------------------

state_lock = threading.Lock()

# Lista de clientes conectados: cada item e um dict com
# {"addr": addr, "name": str, "chat_queue": [list de mensagens pendentes]}
online_clients = []

# Mural de recados: lista de dicts {"author": str, "text": str}
# Persistido em bbs/data/board.json - sobrevive a reinicios do servidor.
MAX_BOARD_MESSAGES = 50
BOARD_FILE = os.path.join(BBS_DIR, "data", "board.json")


def _load_board():
    try:
        with open(BOARD_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            return data
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        pass
    return []


def _save_board(messages):
    os.makedirs(os.path.dirname(BOARD_FILE), exist_ok=True)
    try:
        with open(BOARD_FILE, "w", encoding="utf-8") as f:
            json.dump(messages, f, ensure_ascii=False, indent=2)
    except OSError:
        pass


message_board = _load_board()


class Helpers:
    """Funcoes auxiliares passadas para o menu e para os jogos/ferramentas."""

    def __init__(self, conn, client_info):
        self.conn = conn
        self.client_info = client_info

    def send(self, text):
        """Envia texto convertendo \\n internos em \\r (sem LF).

        Se USE_CRLF estiver ativo (--crlf), tambem envia \\n apos cada
        \\r, para compatibilidade com telnet/nc no Debian."""
        text = text.replace("\n", CR)
        if USE_CRLF:
            text = text.replace(CR, CR + "\n")
        self.conn.sendall(text.encode("ascii", errors="replace"))

    def clear_screen(self):
        self.send(FF)

    def recv_line(self, echo=True):
        """Le ate receber CR ou LF, fazendo echo dos caracteres (servidor
        controla o echo, terminal deve estar SEM echo local).

        Trata CRLF/LFCR como um unico terminador: depois de receber \\r
        ou \\n, espia (com timeout curto) se o proximo byte e o outro
        caractere do par e, se for, descarta-o. Isso evita que o \\n
        residual de um ENTER (que o telnet envia como \\r\\n) seja lido
        como uma linha vazia na proxima chamada."""
        conn = self.conn
        buf = b""
        while True:
            ch = conn.recv(1)
            if not ch:
                return None  # conexao caiu
            if ch in (b"\r", b"\n"):
                if echo:
                    self.send("\n")
                self._consume_pending_eol(ch)
                break
            if ch in (b"\x08", b"\x7f"):  # backspace/delete
                if buf:
                    buf = buf[:-1]
                    if echo:
                        conn.sendall(b"\x08 \x08")
                continue
            buf += ch
            if echo:
                conn.sendall(ch)
        try:
            return buf.decode("ascii", errors="ignore").strip()
        except Exception:
            return ""

    def _consume_pending_eol(self, first_ch):
        """Apos receber \\r ou \\n, descarta o outro caractere do par
        (\\n ou \\r) se ele chegar imediatamente depois - trata CRLF e
        LFCR como um unico ENTER."""
        other = b"\n" if first_ch == b"\r" else b"\r"
        conn = self.conn
        conn.settimeout(0.05)
        try:
            peek = conn.recv(1, socket.MSG_PEEK)
            if peek == other:
                conn.recv(1)  # descarta
        except (TimeoutError, OSError, BlockingIOError):
            pass
        finally:
            conn.settimeout(None)

    def load_game(self, mod_name):
        """Carrega (ou recarrega) o modulo de um jogo/ferramenta pelo nome."""
        return load_module(mod_name)

    # -- estado compartilhado (online, chat, mural) ----------------------

    def recv_line_nb(self, poll_timeout=0.2):
        """Tenta ler uma linha sem bloquear indefinidamente: retorna a
        linha se o usuario apertou ENTER dentro de poll_timeout, ou
        ("", False) se nada chegou ainda (timeout), ou (None, True) se
        a conexao caiu. Usado pelo chat para poder verificar mensagens
        novas enquanto espera o usuario digitar.

        Retorna (linha_ou_None, terminou_bool)."""
        conn = self.conn
        buf = self.client_info.setdefault("_input_buf", b"")
        conn.settimeout(poll_timeout)
        try:
            ch = conn.recv(1)
        except (TimeoutError, OSError):
            return "", False
        finally:
            conn.settimeout(None)

        if not ch:
            return None, True

        if ch in (b"\r", b"\n"):
            self.send("\n")
            self._consume_pending_eol(ch)
            try:
                line = buf.decode("ascii", errors="ignore").strip()
            except Exception:
                line = ""
            self.client_info["_input_buf"] = b""
            return line, True

        if ch in (b"\x08", b"\x7f"):
            if buf:
                buf = buf[:-1]
                conn.sendall(b"\x08 \x08")
            self.client_info["_input_buf"] = buf
            return "", False

        buf += ch
        conn.sendall(ch)
        self.client_info["_input_buf"] = buf
        return "", False


def get_online_list():
    """Retorna copia da lista de (addr, name) dos clientes conectados."""
    with state_lock:
        return [(c["addr"], c["name"]) for c in online_clients]


def add_board_message(author, text):
    with state_lock:
        message_board.append({"author": author, "text": text})
        if len(message_board) > MAX_BOARD_MESSAGES:
            del message_board[: len(message_board) - MAX_BOARD_MESSAGES]
        _save_board(message_board)


def get_board_messages():
    with state_lock:
        return list(message_board)


def broadcast_chat(sender_name, text, exclude=None):
    """Adiciona a mensagem na fila de chat de todos os clientes online,
    exceto (opcionalmente) o remetente."""
    with state_lock:
        for c in online_clients:
            if exclude is not None and c is exclude:
                continue
            c["chat_queue"].append((sender_name, text))


def handle_client(conn, addr):
    print(f"[+] Conexao de {addr}")
    client_info = {
        "addr": addr,
        "name": f"User{addr[1]}",
        "chat_queue": [],
    }
    helpers = Helpers(conn, client_info)

    # expoe funcoes compartilhadas (online/chat/mural) via helpers, para
    # que os modulos de bbs/ nao precisem importar o servidor
    helpers.get_online_list = get_online_list
    helpers.add_board_message = add_board_message
    helpers.get_board_messages = get_board_messages
    helpers.broadcast_chat = broadcast_chat

    with state_lock:
        online_clients.append(client_info)

    try:
        helpers.clear_screen()
        helpers.send(
            "Conectado ao Z80Mini BBS\n"
            "\n"
            "ENTER para iniciar"
        )
        helpers.recv_line(echo=False)

        helpers.clear_screen()
        helpers.send("Seu nome/apelido:\n")
        helpers.send("(ENTER p/ padrao)\n\n> ")
        name = helpers.recv_line()
        if name is None:
            return
        name = name.strip()[:12]
        if name:
            client_info["name"] = name

        # Pilha de menus: comeca no menu raiz ("menu"). Cada modulo de
        # menu e recarregado em CADA exibicao, entao edicoes salvas
        # (novos itens, novos submenus, textos, etc.) aparecem na tela
        # seguinte - sem reiniciar o servidor.
        #
        # menu.show(helpers) retorna:
        #   None         -> cliente desconectou
        #   "."          -> volta um nivel (ou desconecta, se ja no raiz)
        #   ""           -> escolha invalida, ja tratada
        #   ("menu", m)  -> entra no submenu m
        #   ("item", m)  -> executa m.play(conn, helpers)
        menu_stack = ["menu"]

        while True:
            current = menu_stack[-1]
            menu = load_module(current)
            choice = menu.show(helpers)

            if choice is None:
                return  # cliente desconectou

            if choice == ".":
                if len(menu_stack) > 1:
                    menu_stack.pop()
                    continue
                # "." no menu raiz = desconectar
                helpers.clear_screen()
                helpers.send("Tchau!\n")
                return

            if choice == "":
                continue  # escolha invalida, ja tratada por menu.show()

            item_type, mod_name = choice
            if item_type == "menu":
                menu_stack.append(mod_name)
            else:
                item = load_module(mod_name)
                item.play(conn, helpers)
    except (ConnectionError, OSError):
        pass
    finally:
        with state_lock:
            if client_info in online_clients:
                online_clients.remove(client_info)
        conn.close()
        print(f"[-] Desconectado {addr}")


def main():
    global USE_CRLF

    import argparse
    parser = argparse.ArgumentParser(description="Servidor BBS Z80Mini")
    parser.add_argument(
        "--crlf",
        action="store_true",
        help="Envia CR+LF (\\r\\n) em vez de so CR (\\r). "
             "Use para testar com telnet/nc no Debian. "
             "NAO use para o Z80Mini (ele so espera \\r).",
    )
    args = parser.parse_args()
    USE_CRLF = args.crlf

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(5)
    print(f"Servidor BBS rodando em {HOST}:{PORT}")
    print(f"Modulos do BBS em: {BBS_DIR}")
    if USE_CRLF:
        print("Modo CRLF ativo (\\r\\n) - para teste com telnet/nc")

    try:
        while True:
            conn, addr = s.accept()
            t = threading.Thread(target=handle_client, args=(conn, addr), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print("\nEncerrando servidor...")
    finally:
        s.close()


if __name__ == "__main__":
    main()

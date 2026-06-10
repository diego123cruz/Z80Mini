import socket
import random

HOST = "0.0.0.0"
PORT = 2323


def envia_tela(conn, texto):
    conn.sendall(texto.encode("ascii"))
    conn.sendall(b"\n")


def recebe_linha(conn):
    dados = conn.recv(32)

    if not dados:
        return None

    return dados.decode("ascii").strip().upper()


def desenha_tabuleiro(tab):
    txt = "\fJogo da Velha\r\r"

    txt += "   1   2   3\r"
    txt += f"A  {tab[0]} | {tab[1]} | {tab[2]}\r"
    txt += "  -----------\r"
    txt += f"B  {tab[3]} | {tab[4]} | {tab[5]}\r"
    txt += "  -----------\r"
    txt += f"C  {tab[6]} | {tab[7]} | {tab[8]}\r"

    return txt


def posicao(cmd):
    mapa = {
        "A1": 0, "A2": 1, "A3": 2,
        "B1": 3, "B2": 4, "B3": 5,
        "C1": 6, "C2": 7, "C3": 8
    }

    return mapa.get(cmd)


def vencedor(tab):
    linhas = [
        (0,1,2),
        (3,4,5),
        (6,7,8),
        (0,3,6),
        (1,4,7),
        (2,5,8),
        (0,4,8),
        (2,4,6)
    ]

    for a,b,c in linhas:
        if tab[a] != " " and tab[a] == tab[b] == tab[c]:
            return tab[a]

    return None


def velha(tab):
    return " " not in tab


def pergunta_reinicio(conn, mensagem):

    tela = mensagem
    tela += "\r"
    tela += "\rJogar novamente? (S/N): "

    envia_tela(conn, tela)

    resposta = recebe_linha(conn)

    if resposta == "S":
        return True

    return False


def jogar(conn):

    while True:

        tab = [" "] * 9

        while True:

            tela = desenha_tabuleiro(tab)
            tela += "\r"
            tela += "\rJogada (A1-C3): "

            envia_tela(conn, tela)

            cmd = recebe_linha(conn)

            if cmd is None:
                return

            p = posicao(cmd)

            if p is None:
                continue

            if tab[p] != " ":
                continue

            tab[p] = "X"

            if vencedor(tab) == "X":

                tela = desenha_tabuleiro(tab)
                tela += "\r"
                tela += "\rVoce venceu!"

                if pergunta_reinicio(conn, tela):
                    break

                return

            if velha(tab):

                tela = desenha_tabuleiro(tab)
                tela += "\r"
                tela += "\rEmpate!"

                if pergunta_reinicio(conn, tela):
                    break

                return

            livres = [i for i, v in enumerate(tab) if v == " "]

            if livres:
                cpu = random.choice(livres)
                tab[cpu] = "O"

            if vencedor(tab) == "O":

                tela = desenha_tabuleiro(tab)
                tela += "\r"
                tela += "\rComputador venceu!"

                if pergunta_reinicio(conn, tela):
                    break

                return

            if velha(tab):

                tela = desenha_tabuleiro(tab)
                tela += "\r"
                tela += "\rEmpate!"

                if pergunta_reinicio(conn, tela):
                    break

                return


server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((HOST, PORT))
server.listen(5)

print(f"Ouvindo porta {PORT}")

while True:

    conn, addr = server.accept()

    print("Conectado:", addr)

    try:
        jogar(conn)

    except Exception as e:
        print("Erro:", e)

    finally:
        conn.close()
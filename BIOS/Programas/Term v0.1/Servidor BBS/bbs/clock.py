"""
Data/Hora do Servidor

Mostra a data e hora atuais do servidor (uteis para debug de conexao).

Contrato: play(conn, helpers)
"""

import time


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    while True:
        now = time.localtime()
        clear_screen()
        send("  DATA/HORA SERVER\n\n")
        send(time.strftime("%d/%m/%Y\n", now))
        send(time.strftime("%H:%M:%S\n", now))
        send("\n")
        send(time.strftime("Dia da semana:\n%A\n", now))
        send("\n. voltar / ENTER att.")

        resp = recv_line(echo=False)
        if resp is None or resp == ".":
            return

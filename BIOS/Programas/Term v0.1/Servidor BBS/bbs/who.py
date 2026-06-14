"""
Quem esta Online

Lista os usuarios atualmente conectados ao BBS.

Contrato: play(conn, helpers)
"""


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line
    get_online = helpers.get_online_list
    my_name = helpers.client_info["name"]

    while True:
        users = get_online()

        clear_screen()
        send("  QUEM ESTA ONLINE\n\n")
        send(f"{len(users)} conectado(s)\n\n")
        for _addr, name in users[:6]:
            marker = "*" if name == my_name else " "
            send(f"{marker}{name}\n")

        send("\n. voltar / ENTER att.")
        resp = recv_line(echo=False)
        if resp is None or resp == ".":
            return

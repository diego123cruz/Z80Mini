"""
Logica generica de menu, compartilhada pelo menu raiz e pelos submenus
(jogos, ferramentas, online, etc.)

Cada arquivo de menu (menu.py, menu_jogos.py, ...) define:
    TITLE: str
    ITEMS: lista de (tecla, titulo, tipo, nome_do_modulo)
        tipo = "menu"  -> abre outro submenu (modulo com TITLE/ITEMS)
        tipo = "item"  -> executa item.play(conn, helpers)

e expoe:
    def show(helpers):
        return show_menu(helpers, TITLE, ITEMS)

show_menu() retorna:
    None        -> cliente desconectou
    "."         -> voltar (sair deste menu, um nivel acima)
    ""          -> escolha invalida, ja tratada (chame show() de novo)
    (tipo, mod) -> usuario escolheu um item ("menu" ou "item") + nome do modulo
"""


def show_menu(helpers, title, items):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    clear_screen()
    send(f"  {title}\n\n")
    for key, item_title, _type, _mod in items:
        send(f"{key} - {item_title}\n")
    send(". - Voltar\n")
    send("\nEscolha: ")

    choice = recv_line()
    if choice is None:
        return None

    if choice == ".":
        return "."

    for key, _title, item_type, mod_name in items:
        if choice == key:
            return (item_type, mod_name)

    send("\nOpcao invalida.\n")
    send("ENTER p/ continuar")
    recv_line(echo=False)
    return ""

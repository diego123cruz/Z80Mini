"""
Menu raiz do BBS.

Este modulo (e os submenus) sao recarregados pelo servidor a cada
exibicao, entao alteracoes salvas aparecem na tela seguinte - sem
reiniciar o servidor.

Contrato: este modulo expoe:
- TITLE: str
- ITEMS: lista de (tecla, titulo, tipo, nome_do_modulo)
    tipo = "menu" -> abre um submenu (modulo com TITLE/ITEMS proprios)
    tipo = "item" -> executa <modulo>.play(conn, helpers)
- show(helpers): delega para menulib.show_menu()

No menu raiz, "." significa desconectar (tratado pelo servidor).
"""

from menulib import show_menu

TITLE = "Z80MINI BBS"

ITEMS = [
    ("1", "Jogos", "menu", "menu_jogos"),
    ("2", "Ferramentas", "menu", "menu_ferramentas"),
    ("3", "Online", "menu", "menu_online"),
]


def show(helpers):
    return show_menu(helpers, TITLE, ITEMS)

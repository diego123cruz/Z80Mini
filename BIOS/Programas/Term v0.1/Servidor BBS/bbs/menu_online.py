"""
Submenu: Online
"""

from menulib import show_menu

TITLE = "ONLINE"

ITEMS = [
    ("1", "Mural de Recados", "item", "board"),
    ("2", "Chat", "item", "chat"),
    ("3", "Quem esta Online", "item", "who"),
]


def show(helpers):
    return show_menu(helpers, TITLE, ITEMS)

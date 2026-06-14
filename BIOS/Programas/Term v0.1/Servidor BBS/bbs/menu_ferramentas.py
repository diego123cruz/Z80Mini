"""
Submenu: Ferramentas
"""

from menulib import show_menu

TITLE = "FERRAMENTAS"

ITEMS = [
    ("1", "Calculadora", "item", "calculator"),
    ("2", "Conversor Unid.", "item", "converter"),
    ("3", "Conv. Hex/Dec/Bin", "item", "baseconv"),
    ("4", "Data/Hora Server", "item", "clock"),
    ("5", "Editor de Texto", "item", "editor"),
]


def show(helpers):
    return show_menu(helpers, TITLE, ITEMS)

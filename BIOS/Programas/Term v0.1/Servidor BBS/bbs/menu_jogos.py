"""
Submenu: Jogos
"""

from menulib import show_menu

TITLE = "JOGOS"

ITEMS = [
    ("1", "Jogo da Velha", "item", "tictactoe"),
    ("2", "Connect 4", "item", "connect4"),
    ("3", "Forca", "item", "hangman"),
    ("4", "Adiv. o Numero", "item", "guessnumber"),
    ("5", "Pedra/Papel/Tes.", "item", "rps"),
    ("6", "Dados", "item", "dice"),
    ("7", "Mastermind", "item", "mastermind"),
    ("8", "Labirinto", "item", "maze"),
    ("9", "Reversi", "item", "reversi"),
    ("0", "Batalha Naval", "item", "battleship"),
]


def show(helpers):
    return show_menu(helpers, TITLE, ITEMS)

"""
Conversor de Unidades

Conversoes simples de temperatura, distancia e peso.

Contrato: play(conn, helpers)
"""

CATEGORIES = {
    "1": {
        "title": "Temperatura",
        "options": [
            ("1", "Celsius -> Fahrenheit", lambda v: v * 9 / 5 + 32, "C", "F"),
            ("2", "Fahrenheit -> Celsius", lambda v: (v - 32) * 5 / 9, "F", "C"),
        ],
    },
    "2": {
        "title": "Distancia",
        "options": [
            ("1", "Km -> Milhas", lambda v: v * 0.621371, "km", "mi"),
            ("2", "Milhas -> Km", lambda v: v / 0.621371, "mi", "km"),
            ("3", "Metros -> Pes", lambda v: v * 3.28084, "m", "ft"),
            ("4", "Pes -> Metros", lambda v: v / 3.28084, "ft", "m"),
        ],
    },
    "3": {
        "title": "Peso",
        "options": [
            ("1", "Kg -> Libras", lambda v: v * 2.20462, "kg", "lb"),
            ("2", "Libras -> Kg", lambda v: v / 2.20462, "lb", "kg"),
        ],
    },
}


def fmt(v):
    if v == int(v):
        return str(int(v))
    return f"{v:.3f}"


def play(conn, helpers):
    send = helpers.send
    clear_screen = helpers.clear_screen
    recv_line = helpers.recv_line

    while True:
        clear_screen()
        send("  CONVERSOR\n\n")
        for key, cat in CATEGORIES.items():
            send(f"{key} - {cat['title']}\n")
        send(". - voltar\n\n")
        send("Categoria: ")

        cat_choice = recv_line()
        if cat_choice is None:
            return
        if cat_choice == ".":
            return
        cat = CATEGORIES.get(cat_choice)
        if cat is None:
            continue

        while True:
            clear_screen()
            send(f"  {cat['title']}\n\n")
            for key, title, _f, _u1, _u2 in cat["options"]:
                send(f"{key} - {title}\n")
            send(". - voltar\n\n")
            send("Opcao: ")

            opt_choice = recv_line()
            if opt_choice is None:
                return
            if opt_choice == ".":
                break

            opt = None
            for key, title, fn, u1, u2 in cat["options"]:
                if key == opt_choice:
                    opt = (title, fn, u1, u2)
                    break
            if opt is None:
                continue

            title, fn, u1, u2 = opt

            while True:
                clear_screen()
                send(f"  {title}\n\n")
                send(f"Valor em {u1}: ")
                val_line = recv_line()
                if val_line is None:
                    return
                if val_line == ".":
                    break
                try:
                    val = float(val_line.replace(",", "."))
                except ValueError:
                    continue

                result = fn(val)
                clear_screen()
                send(f"  {title}\n\n")
                send(f"{fmt(val)} {u1}\n")
                send(f"= {fmt(result)} {u2}\n")
                send("\n. voltar / ENTER novo")
                resp = recv_line(echo=False)
                if resp == ".":
                    break

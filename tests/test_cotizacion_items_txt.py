"""
Test del bug: al convertir cotización → venta, Flutter reconstruía el
ID_Perfume parseando el nombre desde el texto guardado en la hoja
Cotizaciones (columna Items), porque items_txt no incluía el ID_Perfume.
Con 52 perfumes, nombres parecidos/duplicados hacían que el matching por
texto eligiera el perfume equivocado (ej. ID 46 -> 45, ID 51 -> 13),
descontando stock del perfume incorrecto.

Fix: items_txt ahora embebe el ID_Perfume real de cada item (ej. "[#P046]")
para que la conversión no necesite adivinar por nombre.
"""
from backend.services.cotizacion_service import construir_items_txt


def test_construir_items_txt_embebe_id_perfume():
    items = [
        {"marca": "Dior", "perfume": "Sauvage", "id_perfume": "P046",
         "ml": 5, "precio": 25.0},
        {"marca": "Chanel", "perfume": "No5", "id_perfume": "P013",
         "ml": 2, "precio": 10.0},
    ]
    txt = construir_items_txt(items)
    assert txt == "Dior Sauvage 5ml S/25.00 [#P046] | Chanel No5 2ml S/10.00 [#P013]"


def test_construir_items_txt_ids_distintos_no_se_confunden():
    """Dos perfumes con nombres parecidos deben conservar su propio ID_Perfume."""
    items = [
        {"marca": "Armani", "perfume": "Acqua di Gio", "id_perfume": "P045",
         "ml": 5, "precio": 20.0},
        {"marca": "Armani", "perfume": "Acqua di Gio Profumo", "id_perfume": "P046",
         "ml": 5, "precio": 22.0},
    ]
    txt = construir_items_txt(items)
    ids = [part.split("[#")[1].rstrip("]") for part in txt.split(" | ")]
    assert ids == ["P045", "P046"]

"""
logic/venta.py — Lógica pura de negocio para ventas.

Sin imports de Streamlit. Todas las funciones son puras:
reciben datos, retornan resultados, no modifican estado global.

Principio: si necesitas importar streamlit aquí, algo está mal en el diseño.
"""
import uuid
import pandas as pd
from config import METODOS_PAGO, TIPOS_ENVIO


# ── Catálogo ──────────────────────────────────────────────────────────────────

def filtrar_catalogo(
    df: pd.DataFrame,
    texto: str = "",
    marca: str | None = None,
) -> pd.DataFrame:
    """
    Filtra el catálogo por texto libre (nombre o marca) y/o marca exacta.
    Ambos filtros son opcionales y se combinan con AND.
    """
    result = df
    if marca:
        result = result[result["Marca"] == marca]
    if texto.strip():
        mask = (
            result["Nombre"].str.contains(texto, case=False, na=False, regex=False)
            | result["Marca"].str.contains(texto, case=False, na=False, regex=False)
        )
        result = result[mask]
    return result


def precio_catalogo(perfume_row, ml: str) -> float | None:
    """
    Retorna el precio de catálogo para un tamaño, o None si no está configurado.
    Considera "no configurado" a los valores 0, "" y None.
    """
    col = f"Precio_{ml}ml"
    val = perfume_row.get(col)
    if val in (0, "", None):
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None


# ── Cesta ─────────────────────────────────────────────────────────────────────

def construir_item(perfume_row, ml: str, metodo: str, precio: float) -> dict:
    """
    Crea un item de cesta con ID único inmutable (UUID4).

    El ID permite eliminación por referencia en lugar de por índice de lista,
    evitando el clásico bug de index-shift cuando se borra un elemento
    mientras Streamlit re-renderiza la lista.
    """
    return {
        "id": str(uuid.uuid4()),
        "perfume": str(perfume_row["Nombre"]),
        "marca": str(perfume_row.get("Marca", "")),
        "id_perfume": perfume_row["ID_Perfume"],
        "ml": ml,
        "precio": round(float(precio), 2),
        "metodo": metodo,
    }


def eliminar_item(cesta: list, item_id: str) -> list:
    """
    Retorna una nueva cesta sin el item con ese ID.
    No muta la lista original — el caller reemplaza state["cesta"].
    """
    return [i for i in cesta if i["id"] != item_id]


def calcular_total(cesta: list) -> float:
    return round(sum(float(i["precio"]) for i in cesta), 2)


# ── Cliente ───────────────────────────────────────────────────────────────────

def buscar_cliente_previo(df_ventas: pd.DataFrame, celular: str) -> dict | None:
    """
    Retorna los datos del último pedido registrado para un número de celular.
    Retorna None si no hay historial o si el nombre está vacío.

    Solo retorna cuando hay nombre — un nombre vacío no sirve para autocomplete.
    """
    if df_ventas.empty or "Celular" not in df_ventas.columns:
        return None
    matches = df_ventas[df_ventas["Celular"].astype(str) == celular]
    if matches.empty:
        return None
    row = matches.iloc[-1]
    nombre = str(row.get("Comprador", "")).strip()
    if not nombre:
        return None
    return {
        "nombre": nombre,
        "direccion": str(row.get("Direccion", "")),
        "metodo": str(row.get("Metodo_Pago", "")),
        "tipo_envio": str(row.get("Tipo_Envio", "")),
    }


def validar_paso_cliente(
    comprador: str,
    celular: str,
    direccion: str,
    tipo_envio: str,
) -> list[str]:
    """
    Valida los datos del paso 1 del wizard.
    Retorna lista de mensajes de error (vacía = datos válidos).
    Función pura: no renderiza nada, solo valida y retorna.
    """
    errores: list[str] = []
    if not comprador.strip():
        errores.append("El nombre es requerido")
    if len(celular) != 9 or not celular.isdigit():
        errores.append("Celular debe tener exactamente 9 dígitos numéricos")
    if tipo_envio != "Contraentrega" and not direccion.strip():
        errores.append(f"Dirección requerida para envío por {tipo_envio}")
    return errores

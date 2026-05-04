"""
state.py — Capa de estado centralizada de la aplicación.

Todo el estado mutable vive bajo st.session_state["app"].
Accede siempre a través de get_state() como único punto de entrada.
Nunca escribas directamente a st.session_state desde los módulos de UI
para estado de la app — usa las funciones de este módulo.

Excepciones documentadas:
  - st.session_state.error_log  → usado por data.py (capa de datos)
  - Widget keys (v_comp, v_cel…) → gestionados por Streamlit para binding
    de inputs; se limpian explícitamente vía reset_venta() / reset_busqueda()
"""
import streamlit as st
from config import hoy_peru, METODOS_PAGO, TIPOS_ENVIO, ML_OPCIONES

_KEY = "app"

# ── Claves de widgets del wizard ─────────────────────────────────────────────
# Nombres cortos, fijos — NO hay sufijos de contador.
# Se eliminan explícitamente en reset_venta() / reset_busqueda().

CLIENTE_WIDGET_KEYS: tuple[str, ...] = (
    "v_fecha", "v_envio", "v_comp", "v_cel", "v_dir",
)
BUSQUEDA_WIDGET_KEYS: tuple[str, ...] = (
    "v_busq", "v_marca", "v_perf", "v_ml", "v_pago", "v_editar", "v_precio",
)


# ── Esquema de estado por defecto ─────────────────────────────────────────────

def _default() -> dict:
    return {
        # ── Autenticación ────────────────────────────────────────────────────
        "auth": {
            "autenticado": False,
            "intentos": 0,
            "bloqueado_hasta": 0.0,
        },
        # ── Wizard de venta ──────────────────────────────────────────────────
        "venta": {
            "paso": 1,           # 1 | 2 | 3
            "guardada": False,   # True tras guardar con éxito
            "id_compra": "",
            "url_wa": "",
            "total": 0.0,
        },
        # ── Datos del cliente (confirmados al avanzar paso 1) ────────────────
        "cliente": {
            "comprador": "",
            "celular": "",
            "direccion": "",
            "tipo_envio": TIPOS_ENVIO[0],
            "fecha": hoy_peru(),
        },
        # ── Cesta de items ───────────────────────────────────────────────────
        # Cada item es un dict con "id" (uuid4) + campos de ItemCesta.
        # Nunca se borra por índice — siempre por id.
        "cesta": [],
        # ── Estado del buscador de perfumes (paso 2) ─────────────────────────
        # Solo persiste "metodo" entre items (último método de pago elegido).
        # El resto se limpia en reset_busqueda().
        "busqueda": {
            "metodo": METODOS_PAGO[0],
        },
        # ── Autocomplete de cliente ──────────────────────────────────────────
        "autocomplete": {
            "aplicado": False,
            "celular_buscado": "",
        },
        # ── Cotización por WhatsApp ──────────────────────────────────────────
        "cotizacion": {
            "cesta": [],      # list[dict] con "id" (uuid4)
            "celular": "",
            "guardada": False,
            "id": "",
            "url_wa": "",
        },
        # ── Formularios de conversión de cotizaciones ────────────────────────
        # {str(fila_sheet): bool}  — True = formulario desplegado
        "conv_activas": {},
    }


# ── Acceso principal ──────────────────────────────────────────────────────────

def get_state() -> dict:
    """Punto de acceso único al estado de la app. Inicializa si no existe."""
    if _KEY not in st.session_state:
        st.session_state[_KEY] = _default()
    return st.session_state[_KEY]


# ── Resets ────────────────────────────────────────────────────────────────────

def reset_venta() -> None:
    """
    Resetea el wizard de venta a estado inicial limpio.

    - Conserva el último método de pago (comodidad del vendedor).
    - Limpia TODOS los widgets del wizard eliminando sus claves de session_state,
      de modo que en el siguiente render vuelvan a sus valores por defecto.
    """
    state = get_state()
    ultimo_metodo = state["busqueda"].get("metodo", METODOS_PAGO[0])

    state["venta"] = {
        "paso": 1,
        "guardada": False,
        "id_compra": "",
        "url_wa": "",
        "total": 0.0,
    }
    state["cliente"] = {
        "comprador": "",
        "celular": "",
        "direccion": "",
        "tipo_envio": TIPOS_ENVIO[0],
        "fecha": hoy_peru(),
    }
    state["cesta"] = []
    state["busqueda"] = {"metodo": ultimo_metodo}
    state["autocomplete"] = {"aplicado": False, "celular_buscado": ""}
    state["conv_activas"] = {}

    for k in CLIENTE_WIDGET_KEYS + BUSQUEDA_WIDGET_KEYS:
        st.session_state.pop(k, None)

    # Pre-cargar último método en el widget de pago para el siguiente render
    if ultimo_metodo in METODOS_PAGO:
        st.session_state["v_pago"] = ultimo_metodo


def reset_busqueda() -> None:
    """
    Resetea solo el formulario de búsqueda de perfume.
    Llamar después de agregar un item a la cesta.
    Conserva el método de pago actual para el siguiente item.
    """
    state = get_state()
    ultimo_metodo = state["busqueda"].get("metodo", METODOS_PAGO[0])
    state["busqueda"] = {"metodo": ultimo_metodo}

    for k in BUSQUEDA_WIDGET_KEYS:
        st.session_state.pop(k, None)

    if ultimo_metodo in METODOS_PAGO:
        st.session_state["v_pago"] = ultimo_metodo


def reset_cotizacion() -> None:
    """Resetea la sección de cotización y limpia sus widgets."""
    state = get_state()
    state["cotizacion"] = {
        "cesta": [],
        "celular": "",
        "guardada": False,
        "id": "",
        "url_wa": "",
        "_last_precio_key": "",
    }
    for k in ("cot_cel", "cot_marca", "cot_perf", "cot_ml", "cot_delivery",
               "cot_precio"):
        st.session_state.pop(k, None)

"""
backend/utils/formatters.py — Generadores de HTML y utilidades de formato.

Sin dependencias de Streamlit. Generan strings HTML puros que luego
Streamlit muestra con st.markdown(..., unsafe_allow_html=True).

Fuente de verdad: funciones extraídas de config.py y components.py.
"""
import html as _html
from backend.core.config import STOCK_CRITICO, STOCK_BAJO


# ── Badges de stock ───────────────────────────────────────────────────────────

def stock_badge_html(stock_ml, size: str = "sm") -> str:
    """Genera un badge HTML de color según el nivel de stock."""
    try:
        n = float(stock_ml)
    except (TypeError, ValueError):
        return ""
    if n <= 0:
        return ""

    if size == "lg":
        fs, pad = "0.85rem", "4px 12px"
    else:
        fs, pad = "0.7rem", "2px 8px"

    if n <= STOCK_CRITICO:
        bg, color, icono, label = "#fee2e2", "#991b1b", "🔴", f"{n:.0f}ml — crítico"
        extra_class = "stock-critico-badge"
    elif n <= STOCK_BAJO:
        bg, color, icono, label = "#fef9c3", "#854d0e", "🟡", f"{n:.0f}ml — bajo"
        extra_class = ""
    else:
        bg, color, icono, label = "#dcfce7", "#166534", "🟢", f"{n:.0f}ml"
        extra_class = ""

    return (
        f"<span class='{extra_class}' style='background:{bg}; color:{color}; font-size:{fs}; "
        f"padding:{pad}; border-radius:20px; font-weight:600; "
        f"display:inline-block; margin-left:4px;'>{icono} {label}</span>"
    )


def stock_barra_html(stock_ml, max_ml: int = 100) -> str:
    """Genera una barra de progreso HTML según el nivel de stock."""
    try:
        n = float(stock_ml)
    except (TypeError, ValueError):
        return ""
    if n <= 0:
        return ""
    pct = min(100, int((n / max_ml) * 100))
    color = "#ef4444" if n <= STOCK_CRITICO else ("#eab308" if n <= STOCK_BAJO else "#22c55e")
    return (
        f"<div style='background:#f0e0d0; border-radius:4px; height:5px; "
        f"margin-top:4px; overflow:hidden;'>"
        f"<div style='width:{pct}%; height:100%; background:{color}; "
        f"border-radius:4px;'></div></div>"
        f"<div style='font-size:0.7rem; color:#a07850; text-align:right; "
        f"margin-top:2px;'>{n:.0f}ml</div>"
    )


# ── Catálogo ──────────────────────────────────────────────────────────────────

def construir_catalogo_dict(df_catalogo) -> dict[str, str]:
    """Retorna {str(ID_Perfume): Nombre} para lookup O(1) desde ventas."""
    if df_catalogo is None or df_catalogo.empty:
        return {}
    return dict(zip(df_catalogo["ID_Perfume"].astype(str), df_catalogo["Nombre"]))


def nombre_por_id(catalogo_dict: dict, id_perfume) -> str:
    """Resuelve el nombre de un perfume a partir de su ID."""
    return catalogo_dict.get(str(id_perfume), f"ID: {id_perfume}")


# ── Notas ─────────────────────────────────────────────────────────────────────

def notas_pills_html(
    notas_str,
    color_bg: str = "#fdf0e8",
    color_border: str = "#e8c9a8",
    color_text: str = "#7a4520",
) -> str:
    """Convierte un string de notas separadas por comas en pills HTML."""
    if not notas_str or str(notas_str).strip() in ("", "nan"):
        return ""
    notas = [
        n.strip()
        for n in str(notas_str).replace(";", ",").replace("|", ",").replace("/", ",").split(",")
        if n.strip()
    ]
    if not notas:
        return ""
    pills = "".join([
        f"<span style='display:inline-block; background:{color_bg}; "
        f"border:1px solid {color_border}; border-radius:20px; "
        f"padding:0.15rem 0.65rem; font-size:0.72rem; color:{color_text}; "
        f"font-weight:600; margin:0.15rem 0.1rem; white-space:nowrap;'>"
        f"{_html.escape(n)}</span>"
        for n in notas
    ])
    return f"<div style='display:flex; flex-wrap:wrap; margin-top:0.25rem;'>{pills}</div>"

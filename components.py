"""
components.py — Componentes UI de Streamlit + re-exportación de utilidades puras.

Decisión de arquitectura:
  - Funciones que llaman st.*: se quedan aquí (UI pura de Streamlit).
  - Funciones puras (sin st.*): movidas a backend/utils/formatters.py
    y backend/services/whatsapp_service.py, re-exportadas aquí para
    compatibilidad con el código existente.

Para nuevo código: importar directamente desde backend/.
"""
import streamlit as st

# Funciones puras re-exportadas desde backend (compatibilidad)
from backend.utils.formatters import (
    construir_catalogo_dict,
    nombre_por_id,
    notas_pills_html,
)
from backend.services.whatsapp_service import generar_url_whatsapp


# ── Componentes UI (requieren Streamlit) ──────────────────────────────────────

def mostrar_encabezado() -> None:
    st.markdown(
        '<div class="header-wrapper">'
        '<div class="header-ornamento">'
        '<div class="header-ornamento-dot"></div>'
        '<div class="header-ornamento-dot"></div>'
        '<div class="header-ornamento-dot"></div>'
        '</div>'
        '<div class="titulo-app">🌸 Perfuteca</div>'
        '<div class="subtitulo-app">Catálogo de Precios</div>'
        '<div class="header-linea">'
        '<span class="header-linea-symbol">✦ ✦ ✦</span>'
        '</div>'
        '</div>',
        unsafe_allow_html=True,
    )


def mostrar_placeholder_vacio(emoji: str, titulo: str, subtitulo: str) -> None:
    """Estado vacío estándar: ícono centrado + título + subtexto."""
    import html as _html
    titulo_safe = _html.escape(str(titulo))
    subtitulo_safe = _html.escape(str(subtitulo))
    st.markdown(
        f"""<div style="
            text-align:center; padding:2.5rem 1.5rem; margin-top:1rem;
            background:#ffffff; border:1px dashed #e0c9b4; border-radius:16px;
        ">
            <div style="font-size:2.2rem; margin-bottom:0.7rem;">{emoji}</div>
            <div style="font-family:'Playfair Display',serif; font-size:1.05rem;
                color:#2c1a0e; font-weight:600; margin-bottom:0.3rem;">
                {titulo_safe}
            </div>
            <div style="font-size:0.83rem; color:#a07850;">
                {subtitulo_safe}
            </div>
        </div>""",
        unsafe_allow_html=True,
    )


def separador(simbolo: str = "✦", texto: str = "") -> None:
    contenido = (
        f"{simbolo} {texto} {simbolo}" if texto
        else f"{simbolo} &nbsp; {simbolo} &nbsp; {simbolo}"
    )
    linea_izq = "flex:1;height:0.5px;background:linear-gradient(to right,transparent,#c8956c);"
    linea_der = "flex:1;height:0.5px;background:linear-gradient(to left,transparent,#c8956c);"
    span_style = (
        "color:#c8956c;font-size:0.75rem;letter-spacing:0.18em;"
        "font-family:Lato,sans-serif;font-weight:400;white-space:nowrap;"
    )
    html_out = (
        f'<div style="display:flex;align-items:center;gap:12px;margin:1.2rem 0;opacity:0.7;">'
        f'<div style="{linea_izq}"></div>'
        f'<span style="{span_style}">{contenido}</span>'
        f'<div style="{linea_der}"></div>'
        f'</div>'
    )
    st.markdown(html_out, unsafe_allow_html=True)


__all__ = [
    # UI Streamlit
    "mostrar_encabezado", "mostrar_placeholder_vacio", "separador",
    # Re-exportadas desde backend (compatibilidad)
    "generar_url_whatsapp",
    "construir_catalogo_dict", "nombre_por_id", "notas_pills_html",
]

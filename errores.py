import streamlit as st
from config import COLUMNAS_REQUERIDAS

# ── Función base para tarjetas de error ───────────────────
def _mostrar_card(contenido, color_borde, color_fondo):
    st.markdown(f"""
    <div style="
        background: {color_fondo};
        border-left: 4px solid {color_borde};
        border-radius: 12px;
        padding: 1.5rem;
        margin: 1rem 0;
    ">{contenido}</div>
    """, unsafe_allow_html=True)

def mostrar_error_conexion():
    _mostrar_card("""
        <div style="color:#e53e3e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ❌ Error de conexión con Google Sheets
        </div>
        <div style="color:#742a2a; font-size:0.9rem;">
            No se pudo conectar al catálogo. Posibles causas:
            <ul>
                <li>Sin conexión a internet</li>
                <li>Las credenciales de Google vencieron</li>
                <li>El nombre de la hoja cambió</li>
            </ul>
        </div>
    """, color_borde="#e53e3e", color_fondo="#fff5f5")

def mostrar_error_datos_vacios():
    _mostrar_card("""
        <div style="color:#d69e2e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ⚠️ El catálogo está vacío
        </div>
        <div style="color:#744210; font-size:0.9rem;">
            La hoja de Google Sheets no tiene datos.
            Verifica que la pestaña <strong>Catalogo</strong> tenga perfumes cargados.
        </div>
    """, color_borde="#d69e2e", color_fondo="#fffbeb")

def mostrar_error_columna(columna):
    columnas_esperadas = " | ".join(COLUMNAS_REQUERIDAS)
    _mostrar_card(f"""
        <div style="color:#e53e3e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ❌ Columna no encontrada: <code>{columna}</code>
        </div>
        <div style="color:#742a2a; font-size:0.9rem;">
            Verifica que tu Google Sheets tenga exactamente estas columnas:
            <br><br>
            <code>{columnas_esperadas}</code>
        </div>
    """, color_borde="#e53e3e", color_fondo="#fff5f5")

def mostrar_sin_precio(nombre, tamanio):
    _mostrar_card(f"""
        <div style="color:#744210; font-size:0.9rem;">
            ⚠️ <strong>{nombre}</strong> no tiene precio para <strong>{tamanio}</strong>.
            Agrégalo en tu Google Sheets.
        </div>
    """, color_borde="#d69e2e", color_fondo="#fffbeb")

def validar_dataframe(df):
    """Valida que el dataframe tenga las columnas requeridas según config.py"""
    return [c for c in COLUMNAS_REQUERIDAS if c not in df.columns]
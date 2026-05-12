"""
errores.py — Componentes de error para la UI de Streamlit.

Decisión de arquitectura: las funciones 'mostrar_*' llaman st.* y se
quedan aquí (son UI pura). La validación pura (validar_dataframe)
fue movida a backend/utils/validators.py, que es la fuente de verdad.
"""
import html
import streamlit as st
from backend.core.config import COLUMNAS_REQUERIDAS

# validar_dataframe re-exportada desde backend para compatibilidad
from backend.utils.validators import validar_dataframe


def mostrar_error_conexion() -> None:
    st.error(
        "**❌ Error de conexión con Google Sheets**\n\n"
        "No se pudo conectar al catálogo. Posibles causas:\n"
        "- Sin conexión a internet\n"
        "- Las credenciales de Google vencieron\n"
        "- El nombre de la hoja cambió"
    )


def mostrar_error_datos_vacios() -> None:
    st.warning(
        "**⚠️ El catálogo está vacío**\n\n"
        "La hoja de Google Sheets no tiene datos. "
        "Verifica que la pestaña **Catalogo** tenga perfumes cargados."
    )


def mostrar_error_columna(columna: str) -> None:
    columna_safe = html.escape(str(columna))
    columnas_esperadas = " | ".join(COLUMNAS_REQUERIDAS)
    st.error(
        f"**❌ Columna no encontrada: `{columna_safe}`**\n\n"
        f"Verifica que tu Google Sheets tenga exactamente estas columnas:\n\n"
        f"`{columnas_esperadas}`"
    )


def mostrar_sin_precio(nombre: str, tamanio: str) -> None:
    nombre_safe = html.escape(str(nombre))
    tamanio_safe = html.escape(str(tamanio))
    st.warning(
        f"**{nombre_safe}** no tiene precio para **{tamanio_safe}**. "
        "Agrégalo en tu Google Sheets."
    )

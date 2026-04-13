import html
import streamlit as st
from config import COLUMNAS_REQUERIDAS


def mostrar_error_conexion():
    st.error(
        "**❌ Error de conexión con Google Sheets**\n\n"
        "No se pudo conectar al catálogo. Posibles causas:\n"
        "- Sin conexión a internet\n"
        "- Las credenciales de Google vencieron\n"
        "- El nombre de la hoja cambió"
    )


def mostrar_error_datos_vacios():
    st.warning(
        "**⚠️ El catálogo está vacío**\n\n"
        "La hoja de Google Sheets no tiene datos. "
        "Verifica que la pestaña **Catalogo** tenga perfumes cargados."
    )


def mostrar_error_columna(columna):
    columna_safe = html.escape(str(columna))
    columnas_esperadas = " | ".join(COLUMNAS_REQUERIDAS)
    st.error(
        f"**❌ Columna no encontrada: `{columna_safe}`**\n\n"
        f"Verifica que tu Google Sheets tenga exactamente estas columnas:\n\n"
        f"`{columnas_esperadas}`"
    )


def mostrar_sin_precio(nombre, tamanio):
    nombre_safe = html.escape(str(nombre))
    tamanio_safe = html.escape(str(tamanio))
    st.warning(
        f"**{nombre_safe}** no tiene precio para **{tamanio_safe}**. "
        "Agrégalo en tu Google Sheets."
    )


def validar_dataframe(df):
    return [c for c in COLUMNAS_REQUERIDAS if c not in df.columns]

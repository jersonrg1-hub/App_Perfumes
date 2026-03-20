import streamlit as st
from config import PRECIOS_COLUMNAS
from styles import get_styles
from data import cargar_catalogo
from components import (
    mostrar_encabezado,
    mostrar_perfume_card,
    mostrar_todos_precios
)
from errores import (
    mostrar_error_conexion,
    mostrar_error_datos_vacios,
    mostrar_sin_precio,
    mostrar_error_columna,
    validar_dataframe
)

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")
# Detectar si es móvil y ajustar layout
st.markdown("""
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)
mostrar_encabezado()

try:
    df = cargar_catalogo()

    # ── Validar que no esté vacío ─────────────────────────
    if df.empty:
        mostrar_error_datos_vacios()
        st.stop()

    # ── Validar columnas requeridas ───────────────────────
    columnas_faltantes = validar_dataframe(df)
    if columnas_faltantes:
        for col in columnas_faltantes:
            mostrar_error_columna(col)
        st.stop()

    tab1, tab2 = st.tabs(["🏷️  Por Marca", "🔍  Por Nombre"])

    # ── Pestaña 1: Por Marca ──────────────────────────────
    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            marcas = ["— Elige una marca —"] + sorted(df["Marca"].unique().tolist())
            marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
        with col2:
            tamanio1 = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

        if marca_seleccionada != "— Elige una marca —":
            df_filtrado = df[df["Marca"] == marca_seleccionada]
            columna1 = PRECIOS_COLUMNAS[tamanio1]

            st.markdown("---")
            st.markdown(f"**✨ {len(df_filtrado)} perfume(s) — precios para {tamanio1}**")
            st.markdown("")

            for _, row in df_filtrado.iterrows():
                precio = row[columna1]
                col_nombre, col_precio = st.columns([4, 2])
                with col_nombre:
                    st.markdown(f"🌸 **{row['Nombre']}**")
                with col_precio:
                    if precio:
                        st.markdown(f"**S/ {precio}**")
                    else:
                        st.markdown("*Sin precio*")
                st.divider()
        else:
            st.markdown("")
            st.info("👆 Selecciona una marca para ver sus perfumes")

    # ── Pestaña 2: Por Nombre ─────────────────────────────
    with tab2:
        nombres = ["— Elige un perfume —"] + sorted(df["Nombre"].unique().tolist())
        nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

        if nombre_seleccionado != "— Elige un perfume —":
            perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
            url_imagen = str(perfume.get("URL_imagen", "")).strip()
            mostrar_perfume_card(perfume["Marca"], perfume["Nombre"], url_imagen)

            st.markdown("---")
            mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

            # Avisar si algún tamaño no tiene precio
            for tamanio, columna in PRECIOS_COLUMNAS.items():
                if not perfume.get(columna):
                    mostrar_sin_precio(perfume["Nombre"], tamanio)
        else:
            st.markdown("")
            st.info("👆 Selecciona un perfume para ver sus precios")

except Exception as e:
    mostrar_error_conexion()
    with st.expander("🔍 Ver detalle del error"):
        st.code(str(e))
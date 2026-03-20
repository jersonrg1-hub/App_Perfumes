import streamlit as st
from pathlib import Path
from config import PRECIOS_COLUMNAS
from styles import get_styles
from data import cargar_catalogo
from components import (
    mostrar_encabezado,
    mostrar_perfume_card,
    mostrar_todos_precios
)

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")
st.markdown(get_styles(), unsafe_allow_html=True)
mostrar_encabezado()

try:
    df = cargar_catalogo()
    tab1, tab2 = st.tabs(["🏷️  Por Marca", "🔍  Por Nombre"])

    # ── Pestaña 1: Por Marca ──────────────────────────────
    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            marcas = ["— Elige una marca —"] + sorted(df["Marca"].unique().tolist())
            marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
        with col2:
            tamanio1 = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

        # Solo mostrar si eligió una marca real
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
        else:
            st.markdown("")
            st.info("👆 Selecciona un perfume para ver sus precios")

except Exception as e:
    st.error(f"❌ Error: {e}")
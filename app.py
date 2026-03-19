import streamlit as st
from config import PRECIOS_COLUMNAS
from styles import get_styles
from data import cargar_catalogo
from components import (
    mostrar_encabezado,
    mostrar_perfume_card,
    mostrar_precio_box,
    mostrar_lista_marca
)

st.set_page_config(
    page_title="Perfumes 🌸",
    page_icon="🌸",
    layout="centered"
)

st.markdown(get_styles(), unsafe_allow_html=True)
mostrar_encabezado()

try:
    df = cargar_catalogo()
    tab1, tab2 = st.tabs(["🏷️  Por Marca", "🔍  Por Nombre"])

    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            marcas = sorted(df["Marca"].unique().tolist())
            marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
        with col2:
            tamanio1 = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

        df_filtrado = df[df["Marca"] == marca_seleccionada]
        mostrar_lista_marca(df_filtrado, PRECIOS_COLUMNAS[tamanio1], tamanio1)

    with tab2:
        nombres = sorted(df["Nombre"].unique().tolist())
        nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")
        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]

        url_imagen = perfume.get("URL_imagen", "")
        mostrar_perfume_card(perfume["Marca"], perfume["Nombre"], url_imagen)

        tamanio2 = st.selectbox("Tamaño del decant", list(PRECIOS_COLUMNAS.keys()), key="tamanio2")
        precio2 = perfume[PRECIOS_COLUMNAS[tamanio2]]

        if precio2:
            mostrar_precio_box(precio2, tamanio2)
        else:
            st.warning("⚠️ Este perfume no tiene precio para ese tamaño.")

except Exception as e:
    st.error(f"❌ Error: {e}")
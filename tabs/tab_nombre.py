import streamlit as st
from config import PRECIOS_COLUMNAS
from components import mostrar_perfume_card, mostrar_todos_precios
from errores import mostrar_sin_precio

def mostrar_tab_nombre(df):
    nombres = ["— Elige un perfume —"] + sorted(df["Nombre"].unique().tolist())
    nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

    if nombre_seleccionado != "— Elige un perfume —":
        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
        url_imagen = str(perfume.get("URL_imagen", "")).strip()
        mostrar_perfume_card(perfume["Marca"], perfume["Nombre"], url_imagen)

        st.markdown("---")
        mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

        for tamanio, columna in PRECIOS_COLUMNAS.items():
            if not perfume.get(columna):
                mostrar_sin_precio(perfume["Nombre"], tamanio)
    else:
        st.markdown("")
        st.info("👆 Selecciona un perfume para ver sus precios")
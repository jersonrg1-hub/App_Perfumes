import streamlit as st
from config import PRECIOS_COLUMNAS

def mostrar_tab_marca(df):
    col_marca, col_tamanio = st.columns(2)
    with col_marca:
        marcas = ["— Elige una marca —"] + sorted(df["Marca"].unique().tolist())
        marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
    with col_tamanio:
        tamanio = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

    if marca_seleccionada != "— Elige una marca —":
        df_filtrado = df[df["Marca"] == marca_seleccionada]
        columna = PRECIOS_COLUMNAS[tamanio]

        st.markdown("---")
        st.markdown(f"**✨ {len(df_filtrado)} perfume(s) — precios para {tamanio}**")
        st.markdown("")

        for _, row in df_filtrado.iterrows():
            precio = row[columna]
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
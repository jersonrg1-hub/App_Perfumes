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

        # ── Notas y perfil ────────────────────────────────
        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns

        if tiene_notas or tiene_perfil:
            st.markdown(f"""
                        <div style="
                            background: #f5ede6;
                            border-radius: 10px;
                            padding: 0.8rem 1.2rem;
                            margin: 0.5rem 0;
                        ">
                            {"<div style='color:#a07850; font-size:1rem; margin-bottom:0.3rem;'>🎵 <strong>Notas:</strong> " + str(perfume.get('Notas', '')) + "</div>" if tiene_notas and perfume.get('Notas') else ""}
                            {"<div style='color:#c8956c; font-size:1rem;'>✨ <strong>Perfil:</strong> " + str(perfume.get('Perfil_Olfativo', '')) + "</div>" if tiene_perfil and perfume.get('Perfil_Olfativo') else ""}
                        </div>
                        """, unsafe_allow_html=True)

        st.markdown("---")
        mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

        for tamanio, columna in PRECIOS_COLUMNAS.items():
            if not perfume.get(columna):
                mostrar_sin_precio(perfume["Nombre"], tamanio)
    else:
        st.markdown("")
        st.info("👆 Selecciona un perfume para ver sus precios")
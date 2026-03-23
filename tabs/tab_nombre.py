import html
import streamlit as st
from config import PRECIOS_COLUMNAS
from components import mostrar_perfume_card, mostrar_todos_precios
from errores import mostrar_sin_precio


def mostrar_tab_nombre(df):
    nombres = ["— Elige un perfume —"] + sorted(df["Nombre"].dropna().unique().tolist())
    nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

    if nombre_seleccionado != "— Elige un perfume —":
        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
        url_imagen = str(perfume.get("URL_imagen", "")).strip()
        mostrar_perfume_card(perfume["Marca"], perfume["Nombre"], url_imagen)

        # ── Notas y perfil ────────────────────────────────
        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns

        if tiene_notas or tiene_perfil:
            notas_txt  = html.escape(str(perfume.get('Notas', ''))) if tiene_notas and perfume.get('Notas') else ''
            perfil_txt = html.escape(str(perfume.get('Perfil_Olfativo', ''))) if tiene_perfil and perfume.get('Perfil_Olfativo') else ''

            if notas_txt or perfil_txt:
                st.markdown(f"""
                    <div style="
                        background: #f5ede6;
                        border-radius: 10px;
                        padding: 0.8rem 1.2rem;
                        margin: 0.5rem 0;
                    ">
                        {"<div style='color:#a07850; font-size:1rem; margin-bottom:0.3rem;'>🎵 <strong>Notas:</strong> " + notas_txt + "</div>" if notas_txt else ""}
                        {"<div style='color:#c8956c; font-size:1rem;'>✨ <strong>Perfil:</strong> " + perfil_txt + "</div>" if perfil_txt else ""}
                    </div>
                    """, unsafe_allow_html=True)

        st.markdown("---")
        mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

        sin_precios = [t for t, c in PRECIOS_COLUMNAS.items() if not perfume.get(c)]
        if len(sin_precios) == len(PRECIOS_COLUMNAS):
            mostrar_sin_precio(perfume["Nombre"], "ningún tamaño")

    else:
        st.markdown("")
        st.info("👆 Selecciona un perfume para ver sus precios")
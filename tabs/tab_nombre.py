import html
from pathlib import Path
import streamlit as st
from config import PRECIOS_COLUMNAS
from components import mostrar_todos_precios
from errores import mostrar_sin_precio


def mostrar_tab_nombre(df):
    nombres = ["— Elige un perfume —"] + sorted(df["Nombre"].dropna().unique().tolist())
    nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

    if nombre_seleccionado != "— Elige un perfume —":
        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]
        url_imagen = str(perfume.get("URL_imagen", "")).strip()

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns
        notas_txt  = html.escape(str(perfume.get('Notas', ''))) if tiene_notas and perfume.get('Notas') else ''
        perfil_txt = html.escape(str(perfume.get('Perfil_Olfativo', ''))) if tiene_perfil and perfume.get('Perfil_Olfativo') else ''
        marca_safe  = html.escape(str(perfume.get('Marca', '')))
        nombre_safe = html.escape(str(perfume.get('Nombre', '')))

        col_info, col_notas = st.columns([1, 1])

        with col_info:
            stock_val = perfume.get("Stock_ml", None)
            if stock_val not in (None, "", 0):
                stock_num = float(stock_val)
                if stock_num <= 15:
                    stock_html = f"<div style='margin-top:0.5rem;'><span style='background:#fff3cd; color:#856404; font-size:0.8rem; padding:3px 10px; border-radius:20px; font-weight:600;'>⚠️ Stock bajo: {stock_num:.0f}ml</span></div>"
                else:
                    stock_html = f"<div style='margin-top:0.5rem;'><span style='background:#d4edda; color:#155724; font-size:0.8rem; padding:3px 10px; border-radius:20px; font-weight:600;'>✅ Disponible: {stock_num:.0f}ml</span></div>"
            else:
                stock_html = ""

            st.markdown(f"""
            <div class="perfume-card" style="height:100%;">
                <div class="marca">{marca_safe}</div>
                <div class="nombre">{nombre_safe}</div>
                {stock_html}
            </div>
            """, unsafe_allow_html=True)

        with col_notas:
            if notas_txt or perfil_txt:
                st.markdown(f"""
                <div style="background:#f5ede6; border-radius:10px; padding:0.8rem 1.2rem; height:100%; box-sizing:border-box;">
                    {"<div style='color:#a07850; font-size:0.95rem; margin-bottom:0.4rem;'>🎵 <strong>Notas:</strong> " + notas_txt + "</div>" if notas_txt else ""}
                    {"<div style='color:#c8956c; font-size:0.95rem;'>✨ <strong>Perfil:</strong> " + perfil_txt + "</div>" if perfil_txt else ""}
                </div>
                """, unsafe_allow_html=True)

        if url_imagen:
            imagen_path = Path(__file__).parent.parent / url_imagen
            if imagen_path.exists():
                col_img, _ = st.columns([1, 2])
                with col_img:
                    st.image(str(imagen_path), width=220)
            else:
                st.caption("📷 Imagen no disponible")

        st.markdown("---")
        mostrar_todos_precios(perfume, PRECIOS_COLUMNAS)

        sin_precios = [t for t, c in PRECIOS_COLUMNAS.items() if not perfume.get(c)]
        if len(sin_precios) == len(PRECIOS_COLUMNAS):
            mostrar_sin_precio(perfume["Nombre"], "ningún tamaño")

    else:
        st.markdown("")
        st.info("👆 Selecciona un perfume para ver sus precios")
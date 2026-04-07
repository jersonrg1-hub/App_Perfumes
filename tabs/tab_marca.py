import html
import pandas as pd
import streamlit as st
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html


def mostrar_tab_marca(df):
    col_marca, col_tamanio = st.columns(2)
    with col_marca:
        marcas = ["— Elige una marca —"] + sorted(df["Marca"].dropna().unique().tolist())
        marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
    with col_tamanio:
        tamanio = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

    if marca_seleccionada != "— Elige una marca —":
        df_filtrado = df[df["Marca"] == marca_seleccionada]
        columna = PRECIOS_COLUMNAS[tamanio]

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns

        st.markdown(
            f"<div style='margin-top:0.8rem; margin-bottom:0.5rem; "
            f"color:#a07850; font-size:0.85rem;'>"
            f"{len(df_filtrado)} perfume(s) — {tamanio}</div>",
            unsafe_allow_html=True
        )

        bloques = []
        for row in df_filtrado.to_dict("records"):
            precio = row.get(columna, "")

            notas = (
                html.escape(str(row.get("Notas", "")))
                if tiene_notas and pd.notna(row.get("Notas"))
                else ""
            )
            perfil = (
                html.escape(str(row.get("Perfil_Olfativo", "")))
                if tiene_perfil and pd.notna(row.get("Perfil_Olfativo"))
                else ""
            )
            nombre = html.escape(str(row.get("Nombre", "")))
            marca_safe = html.escape(str(row.get("Marca", "")))
            stock_badge = stock_badge_html(row.get("Stock_ml", None))

            tiene_precio = precio not in (0, "", None)
            precio_display = f"S/ {fmt_precio(precio)}" if tiene_precio else "—"
            precio_color = "#2c1a0e" if tiene_precio else "#bbb"

            notas_html = (
                f"<div style='color:#a07850; font-size:0.82rem; margin-top:0.3rem;'>"
                f"🎵 {notas}</div>"
                if notas else ""
            )
            perfil_html = (
                f"<div style='color:#c8956c; font-size:0.82rem; margin-top:0.15rem;'>"
                f"✨ {perfil}</div>"
                if perfil else ""
            )

            bloques.append(
                f'<div class="perfume-card" style="display:flex; justify-content:space-between; align-items:center; gap:1rem;">'
                f'<div style="flex:1; min-width:0;">'
                f'<div style="font-size:0.65rem; letter-spacing:0.2em; text-transform:uppercase;'
                f'color:#c8956c; font-weight:600; margin-bottom:0.25rem;">{marca_safe}</div>'
                f'<div style="font-family:\'Playfair Display\',serif; font-size:1.1rem;'
                f'color:#2c1a0e; font-weight:600;">{nombre}{stock_badge}</div>'
                f'{notas_html}{perfil_html}</div>'
                f'<div style="background:#fdf6f0; border:1px solid #ede0d4; border-radius:10px;'
                f'padding:0.55rem 1rem; text-align:center; min-width:88px; flex-shrink:0;">'
                f'<div style="color:#a07850; font-size:0.65rem; text-transform:uppercase;'
                f'letter-spacing:0.12em; font-weight:600; margin-bottom:0.2rem;">{tamanio}</div>'
                f'<div style="color:{precio_color}; font-family:\'Inter\',\'DM Sans\',sans-serif;'
                f'font-size:1.2rem; font-weight:700; font-variant-numeric:tabular-nums;">'
                f'{precio_display}</div></div></div>'
            )

        st.markdown("".join(bloques), unsafe_allow_html=True)

    else:
        st.markdown("")
        st.info("👆 Selecciona una marca para ver sus perfumes")
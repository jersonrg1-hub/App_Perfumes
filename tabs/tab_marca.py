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
            f"<div style='margin-top:0.8rem; margin-bottom:0.5rem; color:#a07850; font-size:0.85rem;'>"
            f"✨ {len(df_filtrado)} perfume(s) — precios para {tamanio}</div>",
            unsafe_allow_html=True
        )

        for row in df_filtrado.to_dict('records'):
            precio = row.get(columna, "")

            notas  = html.escape(str(row.get('Notas', ''))) if tiene_notas and pd.notna(row.get('Notas')) else ''
            perfil = html.escape(str(row.get('Perfil_Olfativo', ''))) if tiene_perfil and pd.notna(row.get('Perfil_Olfativo')) else ''

            nombre = html.escape(str(row.get('Nombre', '')))

            stock_badge = stock_badge_html(row.get('Stock_ml', None))

            tiene_precio = precio not in (0, "", None)
            precio_display = f"S/ {fmt_precio(precio)}" if tiene_precio else "—"
            precio_color = "#f5e6d8" if tiene_precio else "#a07850"
            bg_precio = "#1a0f08" if tiene_precio else "#f5ede6"
            border_top = "2px solid #c8956c" if tiene_precio else "2px solid #e0c9b4"

            st.markdown(f"""
            <div style="background:#fffdf9;border:none;border-top:2px solid #c8956c;
                border-radius:0 0 14px 14px;padding:1.1rem 1.6rem 1.3rem;
                margin-bottom:0.8rem;box-shadow:0 2px 12px rgba(160,120,80,0.08);">
                <div style="display:flex;justify-content:space-between;align-items:center;">
                    <div style="flex:1;min-width:0;">
                        <div style="font-family:'Playfair Display',serif;font-size:1.25rem;
                            color:#2c1a0e;font-weight:600;letter-spacing:-0.01em;">
                            🌸 {nombre}{stock_badge}
                        </div>
                        {"<div style='color:#a07850;font-size:0.85rem;margin-top:0.2rem;'>🎵 " + notas + "</div>" if notas else ""}
                        {"<div style='color:#c8956c;font-size:0.85rem;margin-top:0.1rem;'>✨ " + perfil + "</div>" if perfil else ""}
                    </div>
                    <div style="background:{bg_precio};border-top:{border_top};
                        border-radius:14px;padding:0.7rem 1.1rem 0.8rem;
                        text-align:center;min-width:100px;flex-shrink:0;margin-left:1rem;
                        box-shadow:0 4px 14px rgba(26,15,8,0.25);">
                        <div style="color:#c8956c;font-size:0.78rem;letter-spacing:0.18em;
                            text-transform:uppercase;font-weight:400;margin-bottom:0.35rem;">{tamanio}</div>
                        <div style="width:20px;height:1px;background:#c8956c;opacity:0.4;margin:0 auto 0.35rem;"></div>
                        <div style="color:{precio_color};font-family:'Playfair Display',serif;
                            font-size:1.45rem;font-weight:700;letter-spacing:-0.02em;">
                            {precio_display}
                        </div>
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

    else:
        st.markdown("")
        st.info("👆 Selecciona una marca para ver sus perfumes")
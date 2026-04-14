import html
import pandas as pd
import streamlit as st
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html


def mostrar_tab_marca(df):
    marcas = sorted(df["Marca"].dropna().unique().tolist())
    marca_seleccionada = st.selectbox(
        "Marca", marcas, index=None,
        placeholder="— Elige una marca —", key="marca"
    )

    if marca_seleccionada is not None:
        df_filtrado = df[df["Marca"] == marca_seleccionada]

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns

        st.markdown(
            f"<div style='margin-top:0.8rem; margin-bottom:0.5rem; "
            f"color:#a07850; font-size:0.85rem;'>"
            f"{len(df_filtrado)} perfume(s)</div>",
            unsafe_allow_html=True
        )

        bloques = []
        for row in df_filtrado.to_dict("records"):
            notas = (
                html.escape(str(row.get("Notas", "")))
                if tiene_notas and pd.notna(row.get("Notas")) else ""
            )
            perfil = (
                html.escape(str(row.get("Perfil_Olfativo", "")))
                if tiene_perfil and pd.notna(row.get("Perfil_Olfativo")) else ""
            )
            nombre = html.escape(str(row.get("Nombre", "")))
            marca_safe = html.escape(str(row.get("Marca", "")))
            stock_badge = stock_badge_html(row.get("Stock_ml", None))

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

            precios_html = ""
            for tamanio, columna in PRECIOS_COLUMNAS.items():
                precio = row.get(columna, "")
                tiene_precio = precio not in (0, "", None)
                precio_display = f"S/ {fmt_precio(precio)}" if tiene_precio else "—"
                precio_color = "#2c1a0e" if tiene_precio else "#bbb"
                tamanio_safe = html.escape(str(tamanio))
                precios_html += (
                    f'<div style="background:#fdf6f0; border:1px solid #ede0d4;'
                    f'border-radius:8px; padding:0.35rem 0.65rem; text-align:center;'
                    f'flex:1; min-width:60px;">'
                    f'<div style="color:#a07850; font-size:0.6rem; text-transform:uppercase;'
                    f'font-weight:600; letter-spacing:0.1em; margin-bottom:0.15rem;">{tamanio_safe}</div>'
                    f'<div style="color:{precio_color}; font-family:\'Inter\',\'DM Sans\',sans-serif;'
                    f'font-size:0.95rem; font-weight:700; font-variant-numeric:tabular-nums;'
                    f'white-space:nowrap;">{precio_display}</div>'
                    f'</div>'
                )

            bloques.append(
                f'<div class="perfume-card">'
                f'<div style="font-size:0.65rem; letter-spacing:0.2em; text-transform:uppercase;'
                f'color:#c8956c; font-weight:600; margin-bottom:0.25rem;">{marca_safe}</div>'
                f'<div style="font-family:\'Playfair Display\',serif; font-size:1.1rem;'
                f'color:#2c1a0e; font-weight:600; margin-bottom:0.1rem;">{nombre}{stock_badge}</div>'
                f'{notas_html}{perfil_html}'
                f'<div style="display:flex; gap:6px; margin-top:0.5rem; flex-wrap:wrap;">'
                f'{precios_html}'
                f'</div>'
                f'</div>'
            )

        st.markdown("".join(bloques), unsafe_allow_html=True)

    else:
        st.markdown(
            """<div style="
                text-align:center; padding:2.5rem 1.5rem; margin-top:1rem;
                background:#ffffff; border:1px dashed #e0c9b4; border-radius:16px;
            ">
                <div style="font-size:2.2rem; margin-bottom:0.7rem;">🏷️</div>
                <div style="font-family:'Playfair Display',serif; font-size:1.05rem;
                    color:#2c1a0e; font-weight:600; margin-bottom:0.3rem;">
                    Elige una marca
                </div>
                <div style="font-size:0.83rem; color:#a07850;">
                    Selecciona para ver los perfumes disponibles
                </div>
            </div>""",
            unsafe_allow_html=True,
        )

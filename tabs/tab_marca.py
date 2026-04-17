import html
import pandas as pd
import streamlit as st
from components import mostrar_placeholder_vacio
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html, stock_barra_html


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
            stock_barra = stock_barra_html(row.get("Stock_ml", None))

            notas_html = (
                f"<div style='margin-top:0.45rem;'>"
                f"<span style='color:var(--c-primary-light); font-size:0.7rem; font-weight:700;"
                f"letter-spacing:0.14em; text-transform:uppercase;'>Notas</span>"
                f"<div style='color:var(--c-text-mid); font-size:0.92rem; line-height:1.55; margin-top:0.1rem;'>{notas}</div>"
                f"</div>"
                if notas else ""
            )
            perfil_html = (
                f"<div style='margin-top:0.35rem;'>"
                f"<span style='color:var(--c-gold); font-size:0.7rem; font-weight:700;"
                f"letter-spacing:0.14em; text-transform:uppercase;'>Perfil olfativo</span>"
                f"<div style='color:var(--c-text-mid); font-size:0.92rem; line-height:1.55; margin-top:0.1rem;'>{perfil}</div>"
                f"</div>"
                if perfil else ""
            )

            precios_html = ""
            for tamanio, columna in PRECIOS_COLUMNAS.items():
                precio = row.get(columna, "")
                tiene_precio = precio not in (0, "", None)
                precio_display = f"S/ {fmt_precio(precio)}" if tiene_precio else "—"
                valor_class = "chip-valor" if tiene_precio else "chip-valor sin-precio"
                tamanio_safe = html.escape(str(tamanio))
                precios_html += (
                    f'<div class="precio-chip">'
                    f'<span class="chip-label">{tamanio_safe}</span>'
                    f'<span class="{valor_class}">{precio_display}</span>'
                    f'</div>'
                )

            bloques.append(
                f'<div class="perfume-card">'
                f'<div class="marca">{marca_safe}</div>'
                f'<div class="nombre">{nombre}{stock_badge}</div>'
                f'{stock_barra}'
                f'{notas_html}{perfil_html}'
                f'<div style="display:flex; gap:8px; margin-top:0.7rem; width:100%;">'
                f'{precios_html}'
                f'</div>'
                f'</div>'
            )

        st.markdown("".join(bloques), unsafe_allow_html=True)

    else:
        mostrar_placeholder_vacio(
            "🏷️",
            "Elige una marca",
            "Selecciona para ver los perfumes disponibles",
        )

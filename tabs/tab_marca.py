import html
import pandas as pd
import streamlit as st
from components import mostrar_placeholder_vacio, notas_pills_html
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html, stock_barra_html


def _campo_valido(valor):
    return bool(valor) and str(valor).strip().lower() not in ("", "nan", "none")


@st.fragment
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
        tiene_ocasion = "ocasion" in df.columns
        tiene_estacion = "estacion" in df.columns
        tiene_hora = "hora" in df.columns
        tiene_palabras = "palabra_clave" in df.columns

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
            ocasion_val = row.get("ocasion", "") if tiene_ocasion else ""
            estacion_val = row.get("estacion", "") if tiene_estacion else ""
            hora_val = row.get("hora", "") if tiene_hora else ""
            palabras_val = row.get("palabra_clave", "") if tiene_palabras else ""

            nombre = html.escape(str(row.get("Nombre", "")))
            marca_safe = html.escape(str(row.get("Marca", "")))
            stock_badge = stock_badge_html(row.get("Stock_ml", None))
            stock_barra = stock_barra_html(row.get("Stock_ml", None))

            notas_html = (
                f"<div style='margin-top:0.45rem;'>"
                f"<span style='color:var(--c-primary-light); font-size:0.7rem; font-weight:700;"
                f"letter-spacing:0.14em; text-transform:uppercase;'>Notas</span>"
                f"{notas_pills_html(row.get('Notas', ''))}"
                f"</div>"
                if notas else ""
            )
            perfil_html = (
                f"<div style='margin-top:0.35rem;'>"
                f"<span style='color:var(--c-gold); font-size:0.7rem; font-weight:700;"
                f"letter-spacing:0.14em; text-transform:uppercase;'>Perfil olfativo</span>"
                f"{notas_pills_html(row.get('Perfil_Olfativo', ''), color_bg='#fdf8ee', color_border='#e8d5a8', color_text='#7a6020')}"
                f"</div>"
                if perfil else ""
            )
            _lbl = "font-size:0.65rem; letter-spacing:0.15em; text-transform:uppercase; font-weight:700; margin-bottom:0.1rem;"
            _extras = []
            if _campo_valido(ocasion_val):
                _extras.append((f"<div style='{_lbl} color:#4a7a5a;'>Ocasión</div>", notas_pills_html(ocasion_val, color_bg='#eef4f0', color_border='#a8c8b8', color_text='#2a5a3a')))
            if _campo_valido(estacion_val):
                _extras.append((f"<div style='{_lbl} color:#4a5a8a;'>Estación</div>", notas_pills_html(estacion_val, color_bg='#eceef8', color_border='#b0b8d8', color_text='#2a3a6a')))
            if _campo_valido(hora_val):
                _extras.append((f"<div style='{_lbl} color:#7a4a8a;'>Hora</div>", notas_pills_html(hora_val, color_bg='#f4eef8', color_border='#c8b0d8', color_text='#5a2a7a')))
            if _campo_valido(palabras_val):
                _extras.append((f"<div style='{_lbl} color:#6a5a4a;'>Palabras clave</div>", notas_pills_html(palabras_val, color_bg='#f4f0ec', color_border='#c8b8a8', color_text='#4a3a2a')))
            if _extras:
                _cells = "".join(f"<div style='min-width:0;'>{lbl}{pills}</div>" for lbl, pills in _extras)
                extras_html = (
                    f"<div style='margin-top:0.4rem; padding-top:0.4rem; border-top:1px solid #f0e4d8;"
                    f"display:grid; grid-template-columns:1fr 1fr; gap:0.2rem 0.6rem;'>{_cells}</div>"
                )
            else:
                extras_html = ""

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
                f'{notas_html}{perfil_html}{extras_html}'
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

import html
import streamlit as st

from components import separador
from config import PRECIOS_COLUMNAS, fmt_precio


@st.cache_data(ttl=120)
def _extraer_valores(serie):
    valores = set()
    for item in serie.dropna():
        for v in str(item).split(","):
            v_limpio = v.strip().lower().capitalize()
            if v_limpio:
                valores.add(v_limpio)
    return sorted(valores)


def _tiene_todos(valor_str, seleccionados):
    if not valor_str:
        return False
    valores = [v.strip().lower().capitalize() for v in str(valor_str).split(",")]
    return all(s in valores for s in seleccionados)


def mostrar_tab_notas(df):
    st.markdown("### 🎵 Buscar por Nota y Perfil")
    separador()

    tiene_notas = "Notas" in df.columns
    tiene_perfil = "Perfil_Olfativo" in df.columns

    if not tiene_notas and not tiene_perfil:
        st.warning("⚠️ Agrega las columnas **Notas** y **Perfil_Olfativo** en tu Google Sheets")
        return

    notas_ordenadas = _extraer_valores(df["Notas"]) if tiene_notas else []
    perfiles_ordenados = _extraer_valores(df["Perfil_Olfativo"]) if tiene_perfil else []

    col1, col2 = st.columns(2)

    with col1:
        if tiene_notas and notas_ordenadas:
            st.markdown("**🌸 Notas:**")
            notas_seleccionadas = st.multiselect(
                "notas",
                notas_ordenadas,
                placeholder="Ej: Vainilla, Pachuli...",
                label_visibility="collapsed"
            )
        else:
            notas_seleccionadas = []
            st.caption("Sin columna Notas")

    with col2:
        if tiene_perfil and perfiles_ordenados:
            st.markdown("**✨ Perfil Olfativo:**")
            perfiles_seleccionados = st.multiselect(
                "perfiles",
                perfiles_ordenados,
                placeholder="Ej: Floral, Oriental...",
                label_visibility="collapsed"
            )
        else:
            perfiles_seleccionados = []
            st.caption("Sin columna Perfil_Olfativo")

    if not notas_seleccionadas and not perfiles_seleccionados:
        st.markdown("")
        st.info("👆 Selecciona una nota o perfil olfativo para ver los perfumes")
        return

    df_filtrado = df

    if notas_seleccionadas:
        df_filtrado = df_filtrado[
            df_filtrado["Notas"].apply(lambda x: _tiene_todos(x, notas_seleccionadas))
        ]

    if perfiles_seleccionados:
        df_filtrado = df_filtrado[
            df_filtrado["Perfil_Olfativo"].apply(lambda x: _tiene_todos(x, perfiles_seleccionados))
        ]

    st.markdown("")

    if df_filtrado.empty:
        msg = []
        if notas_seleccionadas:
            msg.append(f"notas: **{', '.join(notas_seleccionadas)}**")
        if perfiles_seleccionados:
            msg.append(f"perfil: **{', '.join(perfiles_seleccionados)}**")
        st.markdown(
            f"""<div style="background:#fdf6f0; border:1px solid #ede0d4;
            border-left:3px solid #d69e2e; border-radius:10px;
            padding:1rem 1.2rem; color:#856404;">
            😔 No hay perfumes con {' y '.join(msg)}</div>""",
            unsafe_allow_html=True
        )
        return

    st.markdown(f"**{len(df_filtrado)} perfume(s) encontrado(s)**")
    st.markdown("")

    card_bloques = []
    for row in df_filtrado.to_dict("records"):
        notas_txt = row.get("Notas", "") if tiene_notas else ""
        perfil_txt = row.get("Perfil_Olfativo", "") if tiene_perfil else ""
        marca = html.escape(str(row.get("Marca", "")))
        nombre = html.escape(str(row.get("Nombre", "")))
        notas_txt = html.escape(str(notas_txt)) if notas_txt else ""
        perfil_txt = html.escape(str(perfil_txt)) if perfil_txt else ""
        notas_html = (
            f"<div style='font-size:0.82rem; color:#a07850; margin-top:0.3rem;'>🎵 {notas_txt}</div>"
            if notas_txt else ""
        )
        perfil_html = (
            f"<div style='font-size:0.82rem; color:#c8956c; margin-top:0.15rem;'>✨ {perfil_txt}</div>"
            if perfil_txt else ""
        )
        precios_html = ""
        n_cols = len(PRECIOS_COLUMNAS)
        col_width = f"{100 // n_cols}%"
        for tamanio, columna in PRECIOS_COLUMNAS.items():
            precio = row.get(columna, "")
            tamanio_safe = html.escape(str(tamanio))
            if precio not in (0, "", None):
                precios_html += (
                    f'<div style="width:{col_width}; padding:0 4px; box-sizing:border-box;">'
                    f'<div style="background:#ffffff; border:1px solid #ede0d4; border-radius:12px;'
                    f'padding:0.8rem 0.5rem; text-align:center; margin-bottom:0.4rem;">'
                    f'<div style="color:#a07850; font-size:0.9rem; letter-spacing:0.15em;'
                    f'text-transform:uppercase; font-weight:600; margin-bottom:0.3rem;">{tamanio_safe}</div>'
                    f'<div style="width:16px; height:1px; background:#ede0d4; margin:0 auto 0.3rem;"></div>'
                    f'<div style="color:#2c1a0e; font-family:\'Inter\',\'DM Sans\',sans-serif;'
                    f'font-size:1.1rem; font-weight:700; font-variant-numeric:tabular-nums;">'
                    f'S/ {fmt_precio(precio)}</div></div></div>'
                )
            else:
                precios_html += (
                    f'<div style="width:{col_width}; padding:0 4px; box-sizing:border-box;">'
                    f'<div style="background:#fdf6f0; border-radius:12px; padding:0.8rem 0.5rem;'
                    f'text-align:center; border:1px dashed #e0c9b4; margin-bottom:0.4rem;">'
                    f'<div style="color:#c8956c; font-size:0.9rem; text-transform:uppercase;'
                    f'letter-spacing:0.12em; margin-bottom:0.2rem;">{tamanio_safe}</div>'
                    f'<div style="color:#d4b896; font-size:0.78rem; font-style:italic;">sin precio</div>'
                    f'</div></div>'
                )
        card_bloques.append(
            f'<div class="perfume-card" style="margin-bottom:0.4rem;">'
            f'<div style="font-size:0.65rem; letter-spacing:0.2em; text-transform:uppercase;'
            f'color:#c8956c; font-weight:600; margin-bottom:0.25rem;">{marca}</div>'
            f'<div style="font-family:\'Playfair Display\',serif; font-size:1.15rem;'
            f'color:#2c1a0e; font-weight:600;">{nombre}</div>'
            f'{notas_html}{perfil_html}</div>'
            f'<div style="display:flex; margin-bottom:0.8rem;">{precios_html}</div>'
        )
    st.markdown("".join(card_bloques), unsafe_allow_html=True)
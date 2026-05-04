import html
import streamlit as st

from components import separador, mostrar_placeholder_vacio, notas_pills_html
from config import PRECIOS_COLUMNAS, fmt_precio, stock_badge_html, stock_barra_html


@st.cache_data(ttl=600)
def _extraer_valores(serie):
    valores = set()
    for item in serie.dropna():
        for v in str(item).split(","):
            v_limpio = v.strip().lower().capitalize()
            if v_limpio and v_limpio.lower() != "nan":
                valores.add(v_limpio)
    return sorted(valores)


def _tiene_todos(valor_str, seleccionados):
    if not valor_str or str(valor_str).strip().lower() in ("", "nan", "none"):
        return False
    valores = [v.strip().lower().capitalize() for v in str(valor_str).split(",")]
    return all(s in valores for s in seleccionados)


def _tiene_alguno(valor_str, seleccionados):
    if not valor_str or str(valor_str).strip().lower() in ("", "nan", "none"):
        return False
    valores = [v.strip().lower().capitalize() for v in str(valor_str).split(",")]
    return any(s in valores for s in seleccionados)


def _campo_valido(valor):
    return bool(valor) and str(valor).strip().lower() not in ("", "nan", "none")


@st.fragment
def mostrar_tab_notas(df):
    st.markdown("### 🎵 Buscar por Nota y Perfil")
    separador()

    tiene_notas = "Notas" in df.columns
    tiene_perfil = "Perfil_Olfativo" in df.columns
    tiene_ocasion = "ocasion" in df.columns
    tiene_estacion = "estacion" in df.columns
    tiene_hora = "hora" in df.columns
    tiene_palabras = "palabra_clave" in df.columns

    if not any([tiene_notas, tiene_perfil, tiene_ocasion, tiene_estacion, tiene_hora]):
        st.warning("⚠️ Agrega las columnas **Notas** y **Perfil_Olfativo** en tu Google Sheets")
        return

    notas_ordenadas = _extraer_valores(df["Notas"]) if tiene_notas else []
    perfiles_ordenados = _extraer_valores(df["Perfil_Olfativo"]) if tiene_perfil else []
    ocasiones_ordenadas = _extraer_valores(df["ocasion"]) if tiene_ocasion else []
    estaciones_ordenadas = _extraer_valores(df["estacion"]) if tiene_estacion else []
    horas_ordenadas = _extraer_valores(df["hora"]) if tiene_hora else []

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

    if any([ocasiones_ordenadas, estaciones_ordenadas, horas_ordenadas]):
        col3, col4, col5 = st.columns(3)
        with col3:
            if ocasiones_ordenadas:
                st.markdown("**🎉 Ocasión:**")
                ocasiones_seleccionadas = st.multiselect(
                    "ocasion",
                    ocasiones_ordenadas,
                    placeholder="Ej: Cita, Trabajo...",
                    label_visibility="collapsed"
                )
            else:
                ocasiones_seleccionadas = []
        with col4:
            if estaciones_ordenadas:
                st.markdown("**🌿 Estación:**")
                estaciones_seleccionadas = st.multiselect(
                    "estacion",
                    estaciones_ordenadas,
                    placeholder="Ej: Verano, Invierno...",
                    label_visibility="collapsed"
                )
            else:
                estaciones_seleccionadas = []
        with col5:
            if horas_ordenadas:
                st.markdown("**🌙 Hora:**")
                horas_seleccionadas = st.multiselect(
                    "hora",
                    horas_ordenadas,
                    placeholder="Día o Noche",
                    label_visibility="collapsed"
                )
            else:
                horas_seleccionadas = []
    else:
        ocasiones_seleccionadas = []
        estaciones_seleccionadas = []
        horas_seleccionadas = []

    hay_seleccion = bool(
        notas_seleccionadas or perfiles_seleccionados or
        ocasiones_seleccionadas or estaciones_seleccionadas or horas_seleccionadas
    )

    if hay_seleccion:
        modo_filtro = st.radio(
            "Modo",
            ["Todas", "Alguna"],
            index=0,
            horizontal=True,
            key="notas_modo",
            help="**Todas**: el perfume debe tener todas las seleccionadas · **Alguna**: basta con una coincidencia",
        )
    else:
        modo_filtro = "Todas"

    if not hay_seleccion:
        mostrar_placeholder_vacio(
            "🎵",
            "Elige una nota o perfil",
            "Selecciona para filtrar los perfumes por aroma",
        )
        return

    df_filtrado = df
    usar_sets = all(f"{c}_set" in df.columns for c in ["Notas", "Perfil_Olfativo", "ocasion", "estacion", "hora"] if c in df.columns)
    es_todas = modo_filtro == "Todas"

    def _aplicar_filtro(col_orig, sel):
        col_set = f"{col_orig}_set"
        s = frozenset(sel)
        if usar_sets and col_set in df_filtrado.columns:
            if es_todas:
                return df_filtrado[df_filtrado[col_set].apply(lambda tags: s.issubset(tags))]
            return df_filtrado[df_filtrado[col_set].apply(lambda tags: bool(tags & s))]
        filtrar = _tiene_todos if es_todas else _tiene_alguno
        return df_filtrado[df_filtrado[col_orig].apply(lambda x: filtrar(x, sel))]

    if notas_seleccionadas:
        df_filtrado = _aplicar_filtro("Notas", notas_seleccionadas)
    if perfiles_seleccionados:
        df_filtrado = _aplicar_filtro("Perfil_Olfativo", perfiles_seleccionados)
    if ocasiones_seleccionadas:
        df_filtrado = _aplicar_filtro("ocasion", ocasiones_seleccionadas)
    if estaciones_seleccionadas:
        df_filtrado = _aplicar_filtro("estacion", estaciones_seleccionadas)
    if horas_seleccionadas:
        df_filtrado = _aplicar_filtro("hora", horas_seleccionadas)

    st.markdown("")

    if df_filtrado.empty:
        msg = []
        if notas_seleccionadas:
            msg.append(f"notas: **{', '.join(notas_seleccionadas)}**")
        if perfiles_seleccionados:
            msg.append(f"perfil: **{', '.join(perfiles_seleccionados)}**")
        if ocasiones_seleccionadas:
            msg.append(f"ocasión: **{', '.join(ocasiones_seleccionadas)}**")
        if estaciones_seleccionadas:
            msg.append(f"estación: **{', '.join(estaciones_seleccionadas)}**")
        if horas_seleccionadas:
            msg.append(f"hora: **{', '.join(horas_seleccionadas)}**")
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
        ocasion_txt = row.get("ocasion", "") if tiene_ocasion else ""
        estacion_txt = row.get("estacion", "") if tiene_estacion else ""
        hora_txt = row.get("hora", "") if tiene_hora else ""
        palabras_txt = row.get("palabra_clave", "") if tiene_palabras else ""

        marca = html.escape(str(row.get("Marca", "")))
        nombre = html.escape(str(row.get("Nombre", "")))
        stock_badge = stock_badge_html(row.get("Stock_ml", None))
        stock_barra = stock_barra_html(row.get("Stock_ml", None))

        notas_html = (
            f"<div style='margin-top:0.35rem;'>"
            f"<span style='color:var(--c-primary-light); font-size:0.7rem; font-weight:700;"
            f"letter-spacing:0.14em; text-transform:uppercase;'>Notas</span>"
            f"{notas_pills_html(notas_txt)}"
            f"</div>"
            if _campo_valido(notas_txt) else ""
        )
        perfil_html = (
            f"<div style='margin-top:0.3rem;'>"
            f"<span style='color:var(--c-gold); font-size:0.7rem; font-weight:700;"
            f"letter-spacing:0.14em; text-transform:uppercase;'>Perfil olfativo</span>"
            f"{notas_pills_html(perfil_txt, color_bg='#fdf8ee', color_border='#e8d5a8', color_text='#7a6020')}"
            f"</div>"
            if _campo_valido(perfil_txt) else ""
        )
        _lbl = "font-size:0.65rem; letter-spacing:0.15em; text-transform:uppercase; font-weight:700; margin-bottom:0.1rem;"
        _extras = []
        if _campo_valido(ocasion_txt):
            _extras.append((f"<div style='{_lbl} color:#4a7a5a;'>Ocasión</div>", notas_pills_html(ocasion_txt, color_bg='#eef4f0', color_border='#a8c8b8', color_text='#2a5a3a')))
        if _campo_valido(estacion_txt):
            _extras.append((f"<div style='{_lbl} color:#4a5a8a;'>Estación</div>", notas_pills_html(estacion_txt, color_bg='#eceef8', color_border='#b0b8d8', color_text='#2a3a6a')))
        if _campo_valido(hora_txt):
            _extras.append((f"<div style='{_lbl} color:#7a4a8a;'>Hora</div>", notas_pills_html(hora_txt, color_bg='#f4eef8', color_border='#c8b0d8', color_text='#5a2a7a')))
        if _campo_valido(palabras_txt):
            _extras.append((f"<div style='{_lbl} color:#6a5a4a;'>Palabras clave</div>", notas_pills_html(palabras_txt, color_bg='#f4f0ec', color_border='#c8b8a8', color_text='#4a3a2a')))
        if _extras:
            _cells = "".join(f"<div style='min-width:0;'>{lbl}{pills}</div>" for lbl, pills in _extras)
            extras_html = (
                f"<div style='margin-top:0.4rem; padding-top:0.4rem; border-top:1px solid #f0e4d8;"
                f"display:grid; grid-template-columns:1fr 1fr; gap:0.2rem 0.6rem;'>{_cells}</div>"
            )
        else:
            extras_html = ""

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
            f'color:#2c1a0e; font-weight:600;">{nombre}{stock_badge}</div>'
            f'{stock_barra}'
            f'{notas_html}{perfil_html}{extras_html}</div>'
            f'<div style="display:flex; margin-bottom:0.8rem;">{precios_html}</div>'
        )
    st.markdown("".join(card_bloques), unsafe_allow_html=True)

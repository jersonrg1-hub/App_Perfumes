import html
import streamlit as st
from config import PRECIOS_COLUMNAS, fmt_precio


@st.cache_data
def _extraer_valores(df, columna):
    """Extrae valores únicos de una columna con valores separados por comas"""
    valores = set()
    for item in df[columna].dropna():
        for v in str(item).split(","):
            v_limpio = v.strip().lower().capitalize()
            if v_limpio:
                valores.add(v_limpio)
    return sorted(valores)


def _tiene_todos(valor_str, seleccionados):
    """Verifica si el string contiene todos los valores seleccionados"""
    if not valor_str:
        return False
    valores = [v.strip().lower().capitalize() for v in str(valor_str).split(",")]
    return all(s in valores for s in seleccionados)


def mostrar_tab_notas(df):
    st.markdown("### 🎵 Buscar por Nota y Perfil")
    st.markdown("---")

    tiene_notas = "Notas" in df.columns
    tiene_perfil = "Perfil_Olfativo" in df.columns

    if not tiene_notas and not tiene_perfil:
        st.warning("⚠️ Agrega las columnas **Notas** y **Perfil_Olfativo** en tu Google Sheets")
        return

    # ── Extraer valores únicos ────────────────────────────
    notas_ordenadas = _extraer_valores(df, "Notas") if tiene_notas else []
    perfiles_ordenados = _extraer_valores(df, "Perfil_Olfativo") if tiene_perfil else []

    # ── Filtros ───────────────────────────────────────────
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

    # ── Sin filtros activos ───────────────────────────────
    if not notas_seleccionadas and not perfiles_seleccionados:
        st.markdown("")
        st.info("👆 Selecciona una nota o perfil olfativo para ver los perfumes")
        return

    # ── Aplicar filtros ───────────────────────────────────
    df_filtrado = df

    if notas_seleccionadas:
        df_filtrado = df_filtrado[
            df_filtrado["Notas"].apply(
                lambda x: _tiene_todos(x, notas_seleccionadas)
            )
        ]

    if perfiles_seleccionados:
        df_filtrado = df_filtrado[
            df_filtrado["Perfil_Olfativo"].apply(
                lambda x: _tiene_todos(x, perfiles_seleccionados)
            )
        ]

    st.markdown("---")

    if df_filtrado.empty:
        msg = []
        if notas_seleccionadas:
            msg.append(f"notas: **{', '.join(notas_seleccionadas)}**")
        if perfiles_seleccionados:
            msg.append(f"perfil: **{', '.join(perfiles_seleccionados)}**")
        st.warning(f"😔 No hay perfumes con {' y '.join(msg)}")
        return

    st.markdown(f"**✨ {len(df_filtrado)} perfume(s) encontrado(s):**")
    st.markdown("")

    for row in df_filtrado.to_dict('records'):
        notas_txt = row.get('Notas', '') if tiene_notas else ''
        perfil_txt = row.get('Perfil_Olfativo', '') if tiene_perfil else ''

        marca = html.escape(str(row.get('Marca', '')))
        nombre = html.escape(str(row.get('Nombre', '')))
        notas_txt = html.escape(str(notas_txt)) if notas_txt else ''
        perfil_txt = html.escape(str(perfil_txt)) if perfil_txt else ''

        st.markdown(f"""
        <div style="
            background: white;
            border-left: 4px solid #c8956c;
            border-radius: 12px;
            padding: 1rem 1.5rem;
            margin: 0.5rem 0;
            box-shadow: 0 2px 8px rgba(160, 120, 80, 0.1);
        ">
            <div style="font-size:0.75rem; letter-spacing:0.1em; text-transform:uppercase; color:#a07850; font-weight:600;">{marca}</div>
            <div style="font-family:'Playfair Display',serif; font-size:1.2rem; color:#2c1a0e; font-weight:600; margin:0.2rem 0;">{nombre}</div>
            {"<div style='font-size:0.8rem; color:#a07850; margin-top:0.2rem;'>🎵 " + notas_txt + "</div>" if notas_txt else ""}
            {"<div style='font-size:0.8rem; color:#c8956c; margin-top:0.1rem;'>✨ " + perfil_txt + "</div>" if perfil_txt else ""}
        </div>
        """, unsafe_allow_html=True)

        cols = st.columns(len(PRECIOS_COLUMNAS))
        for i, (tamanio, columna) in enumerate(PRECIOS_COLUMNAS.items()):
            precio = row.get(columna, "")
            with cols[i]:
                if precio not in (0, "", None):
                    st.markdown(f"""
                    <div style="
                        background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
                        border-radius: 8px; padding: 0.6rem;
                        text-align: center; margin-bottom: 0.3rem;
                    ">
                        <div style="color:#e8c9a8; font-size:0.7rem; text-transform:uppercase;">{tamanio}</div>
                        <div style="color:white; font-size:1rem; font-weight:700;">S/ {fmt_precio(precio)}</div>
                    </div>
                    """, unsafe_allow_html=True)
                else:
                    st.markdown(f"""
                    <div style="
                        background: #f5ede6;
                        border-radius: 8px; padding: 0.6rem;
                        text-align: center; border: 1px dashed #e0c9b4;
                        margin-bottom: 0.3rem;
                    ">
                        <div style="color:#c8956c; font-size:0.7rem; text-transform:uppercase;">{tamanio}</div>
                        <div style="color:#bbb; font-size:0.8rem; font-style:italic;">Sin precio</div>
                    </div>
                    """, unsafe_allow_html=True)

        st.markdown("")
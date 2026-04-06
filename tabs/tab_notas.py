import html
import streamlit as st

from components import separador
from config import PRECIOS_COLUMNAS, fmt_precio

@st.cache_data(ttl=120)
def _extraer_valores(df, columna):
    valores = set()
    for item in df[columna].dropna():
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

    notas_ordenadas = _extraer_valores(df, "Notas") if tiene_notas else []
    perfiles_ordenados = _extraer_valores(df, "Perfil_Olfativo") if tiene_perfil else []

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

    st.markdown("")

    if df_filtrado.empty:
        msg = []
        if notas_seleccionadas:
            msg.append(f"notas: **{', '.join(notas_seleccionadas)}**")
        if perfiles_seleccionados:
            msg.append(f"perfil: **{', '.join(perfiles_seleccionados)}**")
        st.markdown(
            f"""<div style="background:#fff3cd; border-left:4px solid #d69e2e;
            border-radius:10px; padding:1rem 1.2rem; color:#856404;">
            😔 No hay perfumes con {' y '.join(msg)}</div>""",
            unsafe_allow_html=True
        )
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
            background: #fffdf9;
            border: none;
            border-top: 2px solid #c8956c;
            border-radius: 0 0 14px 14px;
            padding: 1.1rem 1.6rem 1.3rem;
            margin: 0.7rem 0;
            box-shadow: 0 2px 12px rgba(160,120,80,0.08);
        ">
            <div style="font-size:0.8rem; letter-spacing:0.1em; text-transform:uppercase; color:#a07850; font-weight:600;">{marca}</div>
            <div style="font-family:'Playfair Display',serif; font-size:1.35rem; color:#2c1a0e; font-weight:600; margin:0.2rem 0;">{nombre}</div>
            {"<div style='font-size:0.9rem; color:#a07850; margin-top:0.2rem;'>🎵 " + notas_txt + "</div>" if notas_txt else ""}
            {"<div style='font-size:0.9rem; color:#c8956c; margin-top:0.1rem;'>✨ " + perfil_txt + "</div>" if perfil_txt else ""}
        </div>
        """, unsafe_allow_html=True)

        cols = st.columns(len(PRECIOS_COLUMNAS))
        for i, (tamanio, columna) in enumerate(PRECIOS_COLUMNAS.items()):
            precio = row.get(columna, "")
            with cols[i]:
                if precio not in (0, "", None):
                    st.markdown(f"""
                    <div style="background:#1a0f08;border-radius:14px;padding:0.9rem 0.5rem 0.8rem;text-align:center;box-shadow:0 4px 14px rgba(26,15,8,0.28);margin-bottom:0.4rem;border-top:2px solid #c8956c;">
                        <div style="color:#c8956c;font-size:0.78rem;letter-spacing:0.18em;text-transform:uppercase;font-weight:500;margin-bottom:0.35rem;">{tamanio}</div>
                        <div style="width:20px;height:1px;background:#c8956c;opacity:0.4;margin:0 auto 0.35rem;"></div>
                        <div style="color:#f5e6d8;font-family:'Playfair Display',serif;font-size:1.3rem;font-weight:700;letter-spacing:-0.02em;">S/ {fmt_precio(precio)}</div>
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
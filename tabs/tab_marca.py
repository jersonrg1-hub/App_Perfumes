import streamlit as st
from config import PRECIOS_COLUMNAS, fmt_precio

def mostrar_tab_marca(df):
    col_marca, col_tamanio = st.columns(2)
    with col_marca:
        marcas = ["— Elige una marca —"] + sorted(df["Marca"].unique().tolist())
        marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
    with col_tamanio:
        tamanio = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

    if marca_seleccionada != "— Elige una marca —":
        df_filtrado = df[df["Marca"] == marca_seleccionada]
        columna = PRECIOS_COLUMNAS[tamanio]

        tiene_notas = "Notas" in df.columns
        tiene_perfil = "Perfil_Olfativo" in df.columns

        # ── Sin línea divisora y sin espacio extra ────────
        st.markdown(f"<div style='margin-top:0.8rem; margin-bottom:0.5rem; color:#a07850; font-size:0.85rem;'>✨ {len(df_filtrado)} perfume(s) — precios para {tamanio}</div>", unsafe_allow_html=True)

        for _, row in df_filtrado.iterrows():
            precio = row[columna]
            notas = str(row.get('Notas', '')) if tiene_notas else ''
            perfil = str(row.get('Perfil_Olfativo', '')) if tiene_perfil else ''

            st.markdown(f"""
            <div style="
                background: white;
                border-left: 4px solid #c8956c;
                border-radius: 12px;
                padding: 1rem 1.5rem;
                margin-bottom: 0.6rem;
                box-shadow: 0 2px 8px rgba(160, 120, 80, 0.1);
            ">
                <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                    <div>
                        <div style="font-family:'Playfair Display',serif; font-size:1.1rem; color:#2c1a0e; font-weight:600;">
                            🌸 {row['Nombre']}
                        </div>
                        {"<div style='color:#a07850; font-size:0.85rem; margin-top:0.2rem;'>🎵 " + notas + "</div>" if notas and notas != 'nan' else ""}
                        {"<div style='color:#c8956c; font-size:0.85rem; margin-top:0.1rem;'>✨ " + perfil + "</div>" if perfil and perfil != 'nan' else ""}
                    </div>
                    <div style="
                        background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
                        border-radius: 10px;
                        padding: 0.5rem 1rem;
                        text-align: center;
                        min-width: 90px;
                        flex-shrink: 0;
                        margin-left: 1rem;
                    ">
                        <div style="color:#e8c9a8; font-size:0.65rem; text-transform:uppercase; letter-spacing:0.08em;">{tamanio}</div>
                        <div style="color:white; font-family:'Playfair Display',serif; font-size:1.2rem; font-weight:700;">
                            {"S/ " + fmt_precio(precio) if precio else "—"}
                        </div>
                    </div>
                </div>
            </div>
            """, unsafe_allow_html=True)

    else:
        st.markdown("")
        st.info("👆 Selecciona una marca para ver sus perfumes")
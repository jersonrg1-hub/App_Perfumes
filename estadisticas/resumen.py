import html
from datetime import date

import streamlit as st
import pandas as pd

from components import separador
from config import fmt_precio, hoy_peru
from costos import costo_por_item
from pdf_generator import exportar_pdf_ventas_hoy, exportar_pdf_ventas_mes


def _metrica_card(titulo, valor):
    titulo_safe = html.escape(str(titulo))
    valor_safe = html.escape(str(valor))
    return f"""
    <div style="background:white; border-radius:12px; padding:1rem;
        text-align:center; border:1px solid #ede0d4;
        border-top:3px solid #c8956c;
        box-shadow:0 2px 8px rgba(200,149,108,0.08);">
        <div style="color:#a07850; font-size:0.68rem; text-transform:uppercase;
            font-weight:600; letter-spacing:0.1em; margin-bottom:0.3rem;">{titulo_safe}</div>
        <div style="color:#c8956c; font-size:1.7rem; font-weight:700;
            font-family:Inter,sans-serif;
            font-variant-numeric:tabular-nums;
            white-space:nowrap;">{valor_safe}</div>
    </div>
    """


@st.cache_data(ttl=120)
def _calcular_mas_vendidos(df_ventas, df_catalogo):
    if "ID_Perfume" not in df_ventas.columns:
        return pd.DataFrame()
    df = df_ventas.copy()
    df["ID_Perfume"] = df["ID_Perfume"].astype(str)
    mas_vendidos = (
        df.groupby("ID_Perfume")
        .size().reset_index(name="Cantidad")
        .sort_values("Cantidad", ascending=False).head(5)
    )
    return mas_vendidos.merge(
        df_catalogo[["ID_Perfume", "Nombre", "Marca"]].assign(
            ID_Perfume=df_catalogo["ID_Perfume"].astype(str)
        ),
        on="ID_Perfume", how="left"
    )


def mostrar_estadisticas(df_ventas, df_catalogo):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    df_ventas = df_ventas.copy()
    if df_ventas["Fecha"].dtype == object:
        df_ventas["Fecha"] = pd.to_datetime(
            df_ventas["Fecha"].astype(str).str.strip(),
            format="%Y-%m-%d", errors="coerce"
        )

    hoy = hoy_peru()
    ventas_hoy = df_ventas[df_ventas["Fecha"].dt.date == hoy]
    ventas_mes = df_ventas[
        (df_ventas["Fecha"].dt.month == hoy.month) &
        (df_ventas["Fecha"].dt.year == hoy.year)
    ]

    def _calcular_costo_df(df):
        if "Ml_Vendido" not in df.columns:
            return 0.0
        return df["Ml_Vendido"].apply(
            lambda ml: costo_por_item(int(ml)) if str(ml).isdigit() else 0.0
        ).sum()

    st.markdown("#### 📊 Resumen")
    total_hoy = ventas_hoy["Precio_Cobrado"].sum()
    total_mes = ventas_mes["Precio_Cobrado"].sum()
    costo_hoy = _calcular_costo_df(ventas_hoy)
    costo_mes = _calcular_costo_df(ventas_mes)
    ganancia_hoy = total_hoy - costo_hoy
    ganancia_mes = total_mes - costo_mes

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.markdown(_metrica_card("Ventas hoy", len(ventas_hoy)), unsafe_allow_html=True)
    with col2:
        st.markdown(_metrica_card("Total hoy", f"S/ {fmt_precio(total_hoy)}"), unsafe_allow_html=True)
    with col3:
        st.markdown(_metrica_card("Ventas mes", len(ventas_mes)), unsafe_allow_html=True)
    with col4:
        st.markdown(_metrica_card("Total mes", f"S/ {fmt_precio(total_mes)}"), unsafe_allow_html=True)

    st.markdown("")
    col5, col6, col7, col8 = st.columns(4)
    with col5:
        st.markdown(_metrica_card("Costo hoy", f"S/ {fmt_precio(costo_hoy)}"), unsafe_allow_html=True)
    with col6:
        st.markdown(_metrica_card("Ganancia hoy", f"S/ {fmt_precio(ganancia_hoy)}"), unsafe_allow_html=True)
    with col7:
        st.markdown(_metrica_card("Costo mes", f"S/ {fmt_precio(costo_mes)}"), unsafe_allow_html=True)
    with col8:
        st.markdown(_metrica_card("Ganancia mes", f"S/ {fmt_precio(ganancia_mes)}"), unsafe_allow_html=True)

    st.markdown("")
    col_pdf1, col_pdf2 = st.columns(2)
    with col_pdf1:
        if st.button("⬇️ PDF del día", key="generar_pdf_dia", use_container_width=True):
            pdf_bytes = exportar_pdf_ventas_hoy(df_ventas, df_catalogo)
            if pdf_bytes:
                st.download_button(
                    label="📥 Descargar PDF del día",
                    data=pdf_bytes,
                    file_name=f"ventas_{hoy_peru()}.pdf",
                    mime="application/pdf",
                    use_container_width=True,
                    key="dl_pdf_dia"
                )
            else:
                st.warning("⚠️ No hay ventas hoy")
    with col_pdf2:
        if st.button("⬇️ PDF del mes", key="generar_pdf_mes", use_container_width=True):
            pdf_bytes = exportar_pdf_ventas_mes(df_ventas, df_catalogo)
            if pdf_bytes:
                hoy_d = hoy_peru()
                st.download_button(
                    label="📥 Descargar PDF del mes",
                    data=pdf_bytes,
                    file_name=f"ventas_{hoy_d.year}_{hoy_d.month:02d}.pdf",
                    mime="application/pdf",
                    use_container_width=True,
                    key="dl_pdf_mes"
                )
            else:
                st.warning("⚠️ No hay ventas este mes")

    separador()
    st.markdown("#### 🏆 Perfumes más vendidos")

    if "ID_Perfume" in df_ventas.columns:
        mas_vendidos = _calcular_mas_vendidos(
            df_ventas[["ID_Perfume"]],
            df_catalogo[["ID_Perfume", "Nombre", "Marca"]]
        )
        for pos, row in enumerate(mas_vendidos.to_dict("records"), 1):
            nombre = html.escape(str(row.get("Nombre", "Desconocido")))
            marca  = html.escape(str(row.get("Marca", "")))
            cant   = int(row["Cantidad"])

            if pos == 1:
                rank_bg, rank_color = "#2c1a0e", "white"
            elif pos == 2:
                rank_bg, rank_color = "#a07850", "white"
            else:
                rank_bg, rank_color = "#f5ede6", "#a07850"

            st.markdown(f"""
            <div style="
                background:#ffffff; border:1px solid #ede0d4; border-radius:12px;
                padding:0.7rem 1rem; margin-bottom:0.4rem;
                display:flex; align-items:center; gap:0.9rem;
            ">
                <div style="
                    width:26px; height:26px; border-radius:50%;
                    background:{rank_bg}; color:{rank_color};
                    font-size:0.75rem; font-weight:700;
                    display:flex; align-items:center; justify-content:center;
                    flex-shrink:0;
                ">{pos}</div>
                <div style="flex:1; min-width:0;">
                    <div style="font-size:0.95rem; font-weight:600;
                        color:#2c1a0e; white-space:nowrap; overflow:hidden;
                        text-overflow:ellipsis;">🌸 {nombre}</div>
                    <div style="font-size:0.75rem; color:#a07850;">{marca}</div>
                </div>
                <div style="
                    background:#fdf6f0; border:1px solid #ede0d4;
                    border-radius:8px; padding:0.25rem 0.6rem;
                    font-family:'Inter','DM Sans',sans-serif;
                    font-size:0.85rem; font-weight:700; color:#2c1a0e;
                    flex-shrink:0;
                ">{cant}x</div>
            </div>
            """, unsafe_allow_html=True)

    st.markdown("")
    st.markdown("#### 📋 Historial completo")
    with st.expander("Ver todas las ventas"):
        cols_mostrar = [c for c in df_ventas.columns if c != "fila_sheet"]
        st.dataframe(
            df_ventas[cols_mostrar].sort_values("Fecha", ascending=False),
            use_container_width=True, hide_index=True
        )


import html
from datetime import date

import streamlit as st
import pandas as pd
from config import fmt_precio, hoy_peru
from pdf_generator import exportar_pdf_ventas_hoy


def _metrica_card(titulo, valor):
    titulo_safe = html.escape(str(titulo))
    valor_safe = html.escape(str(valor))
    return f"""
    <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
        <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">{titulo_safe}</div>
        <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">{valor_safe}</div>
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
        df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"].astype(str).str.strip(), errors="coerce")

    hoy = pd.Timestamp(hoy_peru())
    ventas_hoy = df_ventas[
        df_ventas["Fecha"].dt.normalize() == hoy.normalize()
    ]
    ventas_mes = df_ventas[
        (df_ventas["Fecha"].dt.month == hoy.month) &
        (df_ventas["Fecha"].dt.year == hoy.year)
    ]

    st.markdown("#### 📊 Resumen")
    col1, col2, col3, col4 = st.columns(4)
    total_hoy = ventas_hoy["Precio_Cobrado"].sum()
    total_mes = ventas_mes["Precio_Cobrado"].sum()

    with col1:
        st.markdown(_metrica_card("Ventas hoy", len(ventas_hoy)), unsafe_allow_html=True)
    with col2:
        st.markdown(_metrica_card("Total hoy", f"S/ {fmt_precio(total_hoy)}"), unsafe_allow_html=True)
    with col3:
        st.markdown(_metrica_card("Ventas mes", len(ventas_mes)), unsafe_allow_html=True)
    with col4:
        st.markdown(_metrica_card("Total mes", f"S/ {fmt_precio(total_mes)}"), unsafe_allow_html=True)

    st.markdown("")

    st.markdown("#### 🏆 Perfumes más vendidos")
    if "ID_Perfume" in df_ventas.columns:
        mas_vendidos = _calcular_mas_vendidos(df_ventas, df_catalogo)

        for row in mas_vendidos.to_dict('records'):
            col1, col2, col3 = st.columns([4, 2, 1])
            with col1:
                st.markdown(f"<span style='font-size:1.05rem; font-weight:700; color:#2c1a0e;'>🌸 {row.get('Nombre', 'Desconocido')}</span>", unsafe_allow_html=True)
            with col2:
                st.markdown(f"<span style='font-size:0.95rem; color:#a07850;'>{row.get('Marca', '')}</span>", unsafe_allow_html=True)
            with col3:
                st.markdown(f"<span style='font-size:1.05rem; font-weight:700; color:#c8956c;'>{row['Cantidad']}x</span>", unsafe_allow_html=True)
            st.markdown("<hr style='margin:0.3rem 0; border-color:#f0e0d0;'>", unsafe_allow_html=True)

    st.markdown("#### 📋 Historial completo")
    with st.expander("Ver todas las ventas"):
        st.dataframe(
            df_ventas.sort_values("Fecha", ascending=False),
            width='stretch', hide_index=True
        )

    st.markdown("---")
    st.markdown("#### 📄 Exportar ventas del día")
    if st.button("⬇️ Generar PDF del día", key="generar_pdf", width='stretch'):
        pdf_bytes = exportar_pdf_ventas_hoy(df_ventas, df_catalogo)
        if pdf_bytes:
            st.download_button(
                label="📥 Descargar PDF",
                data=pdf_bytes,
                file_name=f"ventas_{date.today()}.pdf",
                mime="application/pdf",
                width='stretch'
            )
        else:
            st.warning("⚠️ No hay ventas hoy para exportar")
import streamlit as st
import pandas as pd
from datetime import datetime, date

def cargar_ventas(cliente, sheet_name):
    hoja = cliente.open(sheet_name).worksheet("Ventas_Pendientes")
    datos = hoja.get_all_records()
    if not datos:
        return pd.DataFrame()
    return pd.DataFrame(datos)

def mostrar_estadisticas(df_ventas, df_catalogo):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    # Convertir fecha
    df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"], errors="coerce")
    df_ventas["Precio_Cobrado"] = pd.to_numeric(df_ventas["Precio_Cobrado"], errors="coerce")

    hoy = pd.Timestamp(date.today())
    mes_actual = hoy.month
    anio_actual = hoy.year

    ventas_hoy = df_ventas[df_ventas["Fecha"].dt.date == hoy.date()]
    ventas_mes = df_ventas[
        (df_ventas["Fecha"].dt.month == mes_actual) &
        (df_ventas["Fecha"].dt.year == anio_actual)
    ]

    # ── Métricas principales ──────────────────────────────
    st.markdown("#### 📊 Resumen")
    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.markdown(f"""
        <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">Ventas hoy</div>
            <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">{len(ventas_hoy)}</div>
        </div>
        """, unsafe_allow_html=True)

    with col2:
        total_hoy = ventas_hoy["Precio_Cobrado"].sum()
        st.markdown(f"""
        <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">Total hoy</div>
            <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">S/ {total_hoy:.1f}</div>
        </div>
        """, unsafe_allow_html=True)

    with col3:
        st.markdown(f"""
        <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">Ventas mes</div>
            <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">{len(ventas_mes)}</div>
        </div>
        """, unsafe_allow_html=True)

    with col4:
        total_mes = ventas_mes["Precio_Cobrado"].sum()
        st.markdown(f"""
        <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">Total mes</div>
            <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">S/ {total_mes:.1f}</div>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("")

    # ── Perfumes más vendidos ─────────────────────────────
    st.markdown("#### 🏆 Perfumes más vendidos")
    if "ID_Perfume" in df_ventas.columns:
        df_ventas["ID_Perfume"] = df_ventas["ID_Perfume"].astype(str)
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

        mas_vendidos = (
            df_ventas.groupby("ID_Perfume")
            .size()
            .reset_index(name="Cantidad")
            .sort_values("Cantidad", ascending=False)
            .head(5)
        )
        mas_vendidos = mas_vendidos.merge(
            df_catalogo[["ID_Perfume", "Nombre", "Marca"]],
            on="ID_Perfume", how="left"
        )

        for _, row in mas_vendidos.iterrows():
            col1, col2, col3 = st.columns([4, 2, 1])
            with col1:
                st.markdown(f"🌸 **{row.get('Nombre', 'Desconocido')}**")
            with col2:
                st.caption(str(row.get('Marca', '')))
            with col3:
                st.markdown(f"**{row['Cantidad']}x**")
            st.divider()

    # ── Historial completo ────────────────────────────────
    st.markdown("#### 📋 Historial completo")
    with st.expander("Ver todas las ventas"):
        st.dataframe(
            df_ventas.sort_values("Fecha", ascending=False),
            use_container_width=True,
            hide_index=True
        )
import streamlit as st
import pandas as pd
from datetime import date
from config import COL_ESTADO_NUM, fmt_precio
from data import marcar_entregado
from pdf_generator import exportar_pdf_ventas_hoy

def _metrica_card(titulo, valor):
    return f"""
    <div style="background:white; border-radius:12px; padding:1rem; text-align:center; border:1px solid #f0e0d0;">
        <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">{titulo}</div>
        <div style="color:#2c1a0e; font-size:1.8rem; font-weight:700;">{valor}</div>
    </div>
    """

def mostrar_estadisticas(df_ventas, df_catalogo):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    df_ventas = df_ventas.copy()
    df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"], errors="coerce")
    df_ventas["Precio_Cobrado"] = pd.to_numeric(df_ventas["Precio_Cobrado"], errors="coerce")

    hoy = pd.Timestamp(date.today())
    ventas_hoy = df_ventas[df_ventas["Fecha"].dt.date == hoy.date()]
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
        df_ventas["ID_Perfume"] = df_ventas["ID_Perfume"].astype(str)
        df_catalogo = df_catalogo.copy()
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

        mas_vendidos = (
            df_ventas.groupby("ID_Perfume")
            .size().reset_index(name="Cantidad")
            .sort_values("Cantidad", ascending=False).head(5)
        )
        mas_vendidos = mas_vendidos.merge(
            df_catalogo[["ID_Perfume", "Nombre", "Marca"]],
            on="ID_Perfume", how="left"
        )
        for _, row in mas_vendidos.iterrows():
            col1, col2, col3 = st.columns([4, 2, 1])
            with col1:
                st.markdown(f"🌸 **{row.get('Nombre','Desconocido')}**")
            with col2:
                st.caption(str(row.get('Marca', '')))
            with col3:
                st.markdown(f"**{row['Cantidad']}x**")
            st.divider()

    st.markdown("#### 📋 Historial completo")
    with st.expander("Ver todas las ventas"):
        st.dataframe(
            df_ventas.sort_values("Fecha", ascending=False),
            use_container_width=True, hide_index=True
        )

    st.markdown("---")
    st.markdown("#### 📄 Exportar ventas del día")
    if st.button("⬇️ Generar PDF del día", use_container_width=True):
        pdf_bytes = exportar_pdf_ventas_hoy(df_ventas, df_catalogo)
        if pdf_bytes:
            st.download_button(
                label="📥 Descargar PDF",
                data=pdf_bytes,
                file_name=f"ventas_{date.today()}.pdf",
                mime="application/pdf",
                use_container_width=True
            )
        else:
            st.warning("⚠️ No hay ventas hoy para exportar")

def mostrar_ventas_pendientes(df_ventas, df_catalogo=None):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas")
        return

    if "Estado" not in df_ventas.columns:
        st.warning("⚠️ Agrega la columna Estado en tu Sheets")
        return

    pendientes = df_ventas[df_ventas["Estado"] != "Entregado"]

    if pendientes.empty:
        st.success("✅ No hay ventas pendientes")
        return

    if df_catalogo is not None:
        df_catalogo = df_catalogo.copy()
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

    def get_nombre_perfume(id_perfume):
        if df_catalogo is None:
            return f"ID: {id_perfume}"
        match = df_catalogo[df_catalogo["ID_Perfume"] == str(id_perfume)]
        return match.iloc[0]["Nombre"] if not match.empty else f"ID: {id_perfume}"

    grupos = pendientes.groupby("ID_Compra")
    st.markdown(f"**{grupos.ngroups} compra(s) pendiente(s)**")

    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]
        total_compra = pd.to_numeric(grupo["Precio_Cobrado"], errors="coerce").sum()

        with st.expander(f"📦 {id_compra} — {primera.get('Comprador','')} | S/ {fmt_precio(total_compra)}"):
            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {primera.get('Fecha','')}")
                st.write(f"📱 **Celular:** {primera.get('Celular','')}")
                st.write(f"🚚 **Envío:** {primera.get('Tipo_Envio','')}")
            with col2:
                st.write(f"📍 **Dirección:** {primera.get('Direccion','')}")
                st.write(f"💳 **Pago:** {primera.get('Metodo_Pago','')}")

            st.markdown("**🛍️ Productos:**")
            for _, item in grupo.iterrows():
                nombre = get_nombre_perfume(item.get('ID_Perfume', ''))
                st.markdown(
                    f"- 🌸 **{nombre}** — "
                    f"{item.get('Ml_Vendido','')}ml "
                    f"| S/ {fmt_precio(item.get('Precio_Cobrado', 0))}"
                )

            if st.button("✅ Marcar como entregado", key=f"entregar_{id_compra}"):
                try:
                    for idx in grupo.index:
                        marcar_entregado(idx + 2, COL_ESTADO_NUM)
                    st.success("✅ Compra marcada como entregada")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error: {e}")
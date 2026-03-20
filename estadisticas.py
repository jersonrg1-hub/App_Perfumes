from fpdf import FPDF
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

    st.markdown("#### 📋 Historial completo")
    with st.expander("Ver todas las ventas"):
        st.dataframe(
            df_ventas.sort_values("Fecha", ascending=False),
            use_container_width=True,
            hide_index=True
        )

    # ── Exportar PDF ──────────────────────────────────────
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

def exportar_pdf_ventas_hoy(df_ventas, df_catalogo):
    try:
        hoy = date.today()
        df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"], errors="coerce")
        ventas_hoy = df_ventas[df_ventas["Fecha"].dt.date == hoy]

        if ventas_hoy.empty:
            return None

        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Helvetica", "B", 16)
        pdf.cell(0, 10, f"Ventas del dia - {hoy}", ln=True, align="C")
        pdf.ln(5)

        total_dia = 0
        for _, row in ventas_hoy.iterrows():
            pdf.set_font("Helvetica", "B", 11)
            pdf.cell(0, 8, f"ID: {row.get('ID_Compra','')} | {row.get('Comprador','')}", ln=True)
            pdf.set_font("Helvetica", size=10)
            pdf.cell(0, 6, f"Celular: {row.get('Celular','')} | Envio: {row.get('Tipo_Envio','')}", ln=True)
            pdf.cell(0, 6, f"Direccion: {row.get('Direccion','')}", ln=True)

            id_p = str(row.get("ID_Perfume", ""))
            df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)
            match = df_catalogo[df_catalogo["ID_Perfume"] == id_p]
            nombre_p = match.iloc[0]["Nombre"] if not match.empty else id_p

            precio = float(row.get("Precio_Cobrado", 0))
            pdf.cell(0, 6, f"Perfume: {nombre_p} {row.get('Ml_Vendido','')}ml | S/ {precio}", ln=True)
            pdf.cell(0, 4, f"Pago: {row.get('Metodo_Pago','')} | Estado: {row.get('Estado','')}", ln=True)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(3)
            total_dia += precio

        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, f"TOTAL DEL DIA: S/ {total_dia:.1f}", ln=True, align="R")

        return bytes(pdf.output())
    except Exception as e:
        st.error(f"Error generando PDF: {e}")
        return None

def mostrar_ventas_pendientes(df_ventas, cliente, sheet_name):
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

    st.markdown(f"**{len(pendientes)} venta(s) pendiente(s)**")
    st.markdown("")

    for idx, row in pendientes.iterrows():
        with st.expander(f"📦 {row.get('ID_Compra','')} — {row.get('Comprador','')}"):
            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {row.get('Fecha','')}")
                st.write(f"📱 **Celular:** {row.get('Celular','')}")
                st.write(f"🚚 **Envío:** {row.get('Tipo_Envio','')}")
            with col2:
                st.write(f"📍 **Dirección:** {row.get('Direccion','')}")
                st.write(f"💰 **Precio:** S/ {row.get('Precio_Cobrado','')}")
                st.write(f"💳 **Pago:** {row.get('Metodo_Pago','')}")

            if st.button("✅ Marcar como entregado", key=f"entregar_{idx}"):
                try:
                    hoja = cliente.open(sheet_name).worksheet("Ventas_Pendientes")
                    hoja.update_cell(idx + 2, 11, "Entregado")
                    st.success("✅ Marcado como entregado")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error: {e}")
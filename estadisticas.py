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

def mostrar_resumen_semanal(df_ventas, df_catalogo):
    """Muestra resumen de la semana actual y comparación de meses"""
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    df_ventas = df_ventas.copy()
    df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"], errors="coerce")
    df_ventas["Precio_Cobrado"] = pd.to_numeric(df_ventas["Precio_Cobrado"], errors="coerce")

    hoy = pd.Timestamp(date.today())

    # ── Semana actual (lunes a domingo) ───────────────────
    inicio_semana = hoy - pd.Timedelta(days=hoy.weekday())
    fin_semana = inicio_semana + pd.Timedelta(days=6)

    ventas_semana = df_ventas[
        (df_ventas["Fecha"].dt.date >= inicio_semana.date()) &
        (df_ventas["Fecha"].dt.date <= fin_semana.date())
    ]

    st.markdown("#### 📅 Resumen de esta semana")
    st.caption(f"{inicio_semana.strftime('%d/%m/%Y')} — {fin_semana.strftime('%d/%m/%Y')}")
    st.markdown("")

    col1, col2, col3 = st.columns(3)
    total_semana = ventas_semana["Precio_Cobrado"].sum()
    num_ventas = len(ventas_semana)

    with col1:
        st.markdown(_metrica_card("Ventas semana", num_ventas), unsafe_allow_html=True)
    with col2:
        st.markdown(_metrica_card("Total semana", f"S/ {fmt_precio(total_semana)}"), unsafe_allow_html=True)
    with col3:
        if num_ventas > 0:
            promedio = total_semana / num_ventas
            st.markdown(_metrica_card("Promedio", f"S/ {fmt_precio(promedio)}"), unsafe_allow_html=True)
        else:
            st.markdown(_metrica_card("Promedio", "S/ 0.00"), unsafe_allow_html=True)

    # Perfume más vendido esta semana
    if not ventas_semana.empty and "ID_Perfume" in ventas_semana.columns:
        st.markdown("")
        df_catalogo = df_catalogo.copy()
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)
        ventas_semana["ID_Perfume"] = ventas_semana["ID_Perfume"].astype(str)

        top = (
            ventas_semana.groupby("ID_Perfume")
            .size().reset_index(name="Cantidad")
            .sort_values("Cantidad", ascending=False)
            .iloc[0]
        )
        match = df_catalogo[df_catalogo["ID_Perfume"] == top["ID_Perfume"]]
        nombre_top = match.iloc[0]["Nombre"] if not match.empty else top["ID_Perfume"]

        st.markdown(f"""
        <div style="
            background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
            border-radius: 12px; padding: 1rem;
            text-align: center; margin: 0.5rem 0;
        ">
            <div style="color:#e8c9a8; font-size:0.75rem; text-transform:uppercase;">🏆 Más vendido esta semana</div>
            <div style="color:white; font-family:'Playfair Display',serif; font-size:1.4rem; font-weight:700;">{nombre_top}</div>
            <div style="color:#c8956c; font-size:0.85rem;">{top['Cantidad']} venta(s)</div>
        </div>
        """, unsafe_allow_html=True)
    else:
        st.info("Sin ventas esta semana aún")

    # ── Desglose por día de la semana ─────────────────────
    if not ventas_semana.empty:
        st.markdown("")
        st.markdown("**📊 Ventas por día:**")
        dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
        cols = st.columns(7)
        for i, dia in enumerate(dias):
            fecha_dia = inicio_semana + pd.Timedelta(days=i)
            ventas_dia = ventas_semana[ventas_semana["Fecha"].dt.date == fecha_dia.date()]
            total_dia = ventas_dia["Precio_Cobrado"].sum()
            es_hoy = fecha_dia.date() == hoy.date()
            with cols[i]:
                color = "#c8956c" if es_hoy else "#a07850"
                st.markdown(f"""
                <div style="text-align:center; padding:0.5rem 0.2rem;">
                    <div style="color:{color}; font-size:0.7rem; font-weight:600;">{dia}</div>
                    <div style="color:#2c1a0e; font-size:0.8rem; font-weight:700;">{len(ventas_dia)}</div>
                    <div style="color:#a07850; font-size:0.65rem;">S/{fmt_precio(total_dia)}</div>
                </div>
                """, unsafe_allow_html=True)

    st.markdown("---")

    # ── Comparación de meses ──────────────────────────────
    st.markdown("#### 📆 Comparar meses")

    meses_disponibles = sorted(
        df_ventas["Fecha"].dropna()
        .dt.to_period("M")
        .unique()
        .tolist()
    )
    opciones_meses = [str(m) for m in meses_disponibles]

    if len(opciones_meses) < 1:
        st.info("No hay suficientes datos para comparar")
        return

    col1, col2 = st.columns(2)
    with col1:
        mes1 = st.selectbox("📅 Mes 1", opciones_meses,
            index=len(opciones_meses)-1, key="mes1_comp")
    with col2:
        mes2 = st.selectbox("📅 Mes 2", opciones_meses,
            index=max(0, len(opciones_meses)-2), key="mes2_comp")

    def stats_mes(mes_str):
        periodo = pd.Period(mes_str, freq="M")
        df_mes = df_ventas[df_ventas["Fecha"].dt.to_period("M") == periodo]
        total = df_mes["Precio_Cobrado"].sum()
        num = len(df_mes)
        prom = total / num if num > 0 else 0
        return df_mes, total, num, prom

    df_m1, total_m1, num_m1, prom_m1 = stats_mes(mes1)
    df_m2, total_m2, num_m2, prom_m2 = stats_mes(mes2)

    st.markdown("")
    col1, col2 = st.columns(2)

    def col_mes(col, nombre_mes, total, num, prom):
        with col:
            st.markdown(f"**{nombre_mes}**")
            st.markdown(_metrica_card("Ventas", num), unsafe_allow_html=True)
            st.markdown("")
            st.markdown(_metrica_card("Total", f"S/ {fmt_precio(total)}"), unsafe_allow_html=True)
            st.markdown("")
            st.markdown(_metrica_card("Promedio", f"S/ {fmt_precio(prom)}"), unsafe_allow_html=True)

    col_mes(col1, mes1, total_m1, num_m1, prom_m1)
    col_mes(col2, mes2, total_m2, num_m2, prom_m2)

    # ── Diferencia entre meses ────────────────────────────
    if total_m1 > 0 and total_m2 > 0:
        st.markdown("")
        diferencia = total_m2 - total_m1
        porcentaje = ((total_m2 - total_m1) / total_m1) * 100
        color = "#2d7a4f" if diferencia >= 0 else "#e53e3e"
        simbolo = "📈" if diferencia >= 0 else "📉"
        st.markdown(f"""
        <div style="
            background: white;
            border-radius: 12px; padding: 1rem;
            text-align: center; border: 1px solid #f0e0d0;
            margin-top: 0.5rem;
        ">
            <div style="color:#a07850; font-size:0.75rem; text-transform:uppercase;">Diferencia</div>
            <div style="color:{color}; font-size:1.5rem; font-weight:700;">
                {simbolo} S/ {fmt_precio(abs(diferencia))} ({porcentaje:+.1f}%)
            </div>
            <div style="color:#a07850; font-size:0.8rem;">
                {mes2} vs {mes1}
            </div>
        </div>
        """, unsafe_allow_html=True)

def mostrar_tamanios_populares(df_ventas):
    """Muestra qué tamaños de decant se venden más"""
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    if "Ml_Vendido" not in df_ventas.columns:
        st.warning("⚠️ No se encontró la columna Ml_Vendido")
        return

    df_ventas = df_ventas.copy()
    df_ventas["Precio_Cobrado"] = pd.to_numeric(
        df_ventas["Precio_Cobrado"], errors="coerce"
    )

    conteo = (
        df_ventas.groupby("Ml_Vendido")
        .agg(
            Cantidad=("Ml_Vendido", "count"),
            Total=("Precio_Cobrado", "sum")
        )
        .reset_index()
        .sort_values("Cantidad", ascending=False)
    )

    total_ventas = conteo["Cantidad"].sum()

    st.markdown("#### 📏 Tamaños más vendidos")
    st.markdown("")

    for _, row in conteo.iterrows():
        ml = row["Ml_Vendido"]
        cantidad = row["Cantidad"]
        total = row["Total"]
        porcentaje = (cantidad / total_ventas * 100) if total_ventas > 0 else 0

        st.markdown(f"""
        <div style="
            background: white;
            border-radius: 12px;
            padding: 1rem 1.5rem;
            margin-bottom: 0.8rem;
            border: 1px solid #f0e0d0;
        ">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
                <div style="font-family:'Playfair Display',serif; font-size:1.1rem; color:#2c1a0e; font-weight:700;">
                    📦 {ml}ml
                </div>
                <div style="color:#a07850; font-size:0.9rem;">
                    {cantidad} venta(s) — S/ {fmt_precio(total)}
                </div>
            </div>
            <div style="background:#f5ede6; border-radius:8px; height:12px; overflow:hidden;">
                <div style="
                    background: linear-gradient(135deg, #2c1a0e, #c8956c);
                    height:100%;
                    width:{porcentaje:.1f}%;
                    border-radius:8px;
                    transition: width 0.5s ease;
                "></div>
            </div>
            <div style="color:#c8956c; font-size:0.8rem; margin-top:0.3rem; text-align:right;">
                {porcentaje:.1f}% del total
            </div>
        </div>
        """, unsafe_allow_html=True)
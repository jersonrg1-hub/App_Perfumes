import pandas as pd
import streamlit as st
from config import fmt_precio, hoy_peru
from data import cargar_ventas, limpiar_cache_ventas, limpiar_cache_catalogo
from estadisticas import (
    mostrar_estadisticas,
    mostrar_ventas_pendientes,
    mostrar_resumen_semanal,
    mostrar_tamanios_populares
)
from estadisticas.historial import mostrar_historial_ventas
from estadisticas.clientes import mostrar_clientes_frecuentes
from estadisticas.stock import mostrar_panel_stock
from estadisticas.graficos import mostrar_graficos
from estadisticas.historial_cotizaciones import mostrar_historial_cotizaciones
from estadisticas.rentabilidad import mostrar_rentabilidad
from estadisticas.backup import mostrar_backup


def _resumen_hoy_banner(df_ventas):
    try:
        df_v = df_ventas.copy()
        if "Estado" in df_v.columns:
            df_v = df_v[df_v["Estado"] == "Entregado"]
        if df_v.empty:
            return
        if df_v["Fecha"].dtype == object:
            df_v["Fecha"] = pd.to_datetime(
                df_v["Fecha"].astype(str).str.strip(), format="%Y-%m-%d", errors="coerce"
            )
        hoy = hoy_peru()
        ventas_hoy = df_v[df_v["Fecha"].dt.date == hoy]
        n_hoy = int(ventas_hoy["ID_Compra"].nunique()) if "ID_Compra" in ventas_hoy.columns else len(ventas_hoy)
        total_hoy = float(ventas_hoy["Precio_Cobrado"].sum()) if "Precio_Cobrado" in ventas_hoy.columns else 0.0

        n_pend = 0
        if "Estado" in df_ventas.columns and "ID_Compra" in df_ventas.columns:
            n_pend = int(df_ventas[~df_ventas["Estado"].isin(["Entregado", "Anulado"])]["ID_Compra"].nunique())

        pend_html = (
            f"<span style='background:rgba(245,158,11,0.3);color:#fcd34d;border-radius:6px;"
            f"padding:0.1rem 0.5rem;font-size:0.78rem;font-weight:700;margin-left:0.5rem;'>"
            f"📦 {n_pend} pendiente{'s' if n_pend != 1 else ''}</span>"
            if n_pend > 0 else ""
        )

        st.markdown(f"""
        <div style="background:linear-gradient(135deg,#2c1a0e 0%,#4a2e18 100%);
            border-radius:14px; padding:0.9rem 1.2rem; margin-bottom:1rem;
            display:flex; justify-content:space-between; align-items:center;">
            <div style="color:#f5e6d8; font-size:0.82rem; font-weight:700;
                text-transform:uppercase; letter-spacing:0.08em;">
                Hoy — {n_hoy} venta{'s' if n_hoy != 1 else ''}{pend_html}
            </div>
            <div style="color:#c8956c; font-family:'Inter',sans-serif; font-size:1.6rem;
                font-weight:800; font-variant-numeric:tabular-nums;">
                S/ {fmt_precio(total_hoy)}
            </div>
        </div>
        """, unsafe_allow_html=True)
    except Exception:
        pass


@st.fragment
def mostrar_tab_estadisticas(df):
    col_titulo, col_reload = st.columns([5, 1])
    with col_titulo:
        st.markdown("### 📊 Estadísticas de Ventas")
    with col_reload:
        st.markdown("<div style='padding-top:0.6rem;'></div>", unsafe_allow_html=True)
        if st.button("🔄 Recargar", key="reload", use_container_width=True,
                     help="Recargar datos desde Google Sheets"):
            limpiar_cache_ventas()
            limpiar_cache_catalogo()
            st.rerun(scope="app")

    try:
        with st.spinner("Cargando ventas..."):
            df_ventas = cargar_ventas()

        error_log = st.session_state.get("error_log", [])
        if df_ventas.empty and any("cargar_ventas" in entry for entry in error_log):
            st.warning(
                "⚠️ Los datos de ventas pueden estar incompletos — "
                "hubo un error al cargar. Presiona **Recargar** para intentar de nuevo."
            )

        _resumen_hoy_banner(df_ventas)

        subtab1, subtab2, subtab3, subtab4, subtab5 = st.tabs([
            "📊 Resumen",
            "📦 Pendientes",
            "📋 Historial",
            "👥 Clientes",
            "📈 Análisis",
        ])

        with subtab1:
            mostrar_estadisticas(df_ventas, df)

        with subtab2:
            mostrar_ventas_pendientes(df_ventas, df)

        with subtab3:
            seccion_hist = st.radio(
                "seccion_hist",
                ["📋 Historial", "📏 Tamaños", "📅 Semanal"],
                horizontal=True,
                label_visibility="collapsed",
                key="hist_radio",
            )
            st.markdown("")
            if seccion_hist == "📋 Historial":
                mostrar_historial_ventas(df_ventas, df)
            elif seccion_hist == "📏 Tamaños":
                mostrar_tamanios_populares(df_ventas)
            elif seccion_hist == "📅 Semanal":
                mostrar_resumen_semanal(df_ventas, df)

        with subtab4:
            seccion_clientes = st.radio(
                "seccion_clientes",
                ["👥 Clientes Frecuentes", "💰 Cotizaciones"],
                horizontal=True,
                label_visibility="collapsed",
                key="clientes_radio",
            )
            st.markdown("")
            if seccion_clientes == "👥 Clientes Frecuentes":
                mostrar_clientes_frecuentes(df_ventas, df)
            elif seccion_clientes == "💰 Cotizaciones":
                mostrar_historial_cotizaciones()

        with subtab5:
            seccion_analisis = st.radio(
                "seccion_analisis",
                ["📈 Gráficos", "🧪 Stock", "🏆 Rentabilidad", "💾 Backup"],
                horizontal=True,
                label_visibility="collapsed",
                key="analisis_radio",
            )
            st.markdown("")
            if seccion_analisis == "📈 Gráficos":
                mostrar_graficos(df_ventas)
            elif seccion_analisis == "🧪 Stock":
                mostrar_panel_stock(df)
            elif seccion_analisis == "🏆 Rentabilidad":
                mostrar_rentabilidad(df_ventas, df)
            elif seccion_analisis == "💾 Backup":
                mostrar_backup(df, df_ventas)

    except Exception as e:
        st.error(f"❌ Error cargando ventas: {e}")
        if st.session_state.get("error_log"):
            with st.expander("🔍 Log de errores"):
                for log in st.session_state["error_log"]:
                    st.code(log)
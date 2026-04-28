import streamlit as st
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


@st.fragment
def mostrar_tab_estadisticas(df):
    st.markdown("### 📊 Estadísticas de Ventas")

    if st.button("🔄 Recargar datos", key="reload"):
        limpiar_cache_ventas()
        limpiar_cache_catalogo()
        st.rerun(scope="app")

    st.markdown("---")
    try:
        with st.spinner("Cargando ventas..."):
            df_ventas = cargar_ventas()

        error_log = st.session_state.get("error_log", [])
        if df_ventas.empty and any("cargar_ventas" in entry for entry in error_log):
            st.warning(
                "⚠️ Los datos de ventas pueden estar incompletos — "
                "hubo un error al cargar. Presiona **Recargar datos** para intentar de nuevo."
            )

        subtab1, subtab2, subtab3, subtab4 = st.tabs([
            "📊 Resumen",
            "📦 Ventas",
            "👥 Clientes",
            "📈 Análisis",
        ])

        with subtab1:
            mostrar_estadisticas(df_ventas, df)

        with subtab2:
            seccion_ventas = st.radio(
                "seccion_ventas",
                ["📦 Pendientes", "📋 Historial", "📏 Tamaños", "📅 Semanal"],
                horizontal=True,
                label_visibility="collapsed",
                key="ventas_radio",
            )
            st.markdown("")
            if seccion_ventas == "📦 Pendientes":
                mostrar_ventas_pendientes(df_ventas, df)
            elif seccion_ventas == "📋 Historial":
                mostrar_historial_ventas(df_ventas, df)
            elif seccion_ventas == "📏 Tamaños":
                mostrar_tamanios_populares(df_ventas)
            elif seccion_ventas == "📅 Semanal":
                mostrar_resumen_semanal(df_ventas, df)

        with subtab3:
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

        with subtab4:
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
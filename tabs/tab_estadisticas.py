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


def mostrar_tab_estadisticas(df):
    st.markdown("### 📊 Estadísticas de Ventas")

    if st.button("🔄 Recargar datos", key="reload"):
        limpiar_cache_ventas()
        limpiar_cache_catalogo()
        st.rerun()

    st.markdown("---")
    try:
        with st.spinner("Cargando ventas..."):
            df_ventas = cargar_ventas()

        subtab1, subtab2, subtab3, subtab4, subtab5, subtab6, subtab7, subtab8 = st.tabs([
            "📊 Estadísticas",
            "📦 Pendientes",
            "📋 Historial",
            "👥 Clientes",
            "📈 Gráficos",
            "🧪 Stock",
            "📏 Tamaños",
            "📅 Semanal & Meses"
        ])
        with subtab1:
            mostrar_estadisticas(df_ventas, df)
        with subtab2:
            mostrar_ventas_pendientes(df_ventas, df)
        with subtab3:
            mostrar_historial_ventas(df_ventas, df)
        with subtab4:
            mostrar_clientes_frecuentes(df_ventas, df)
        with subtab5:
            mostrar_graficos(df_ventas)
        with subtab6:
            mostrar_panel_stock(df)
        with subtab7:
            mostrar_tamanios_populares(df_ventas)
        with subtab8:
            mostrar_resumen_semanal(df_ventas, df)

    except Exception as e:
        st.error(f"❌ Error cargando ventas: {e}")
        if st.session_state.get("error_log"):
            with st.expander("🔍 Log de errores"):
                for log in st.session_state["error_log"]:
                    st.code(log)
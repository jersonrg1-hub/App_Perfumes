import streamlit as st
from data import cargar_ventas, limpiar_cache_catalogo
from estadisticas import mostrar_estadisticas, mostrar_ventas_pendientes, mostrar_resumen_semanal

def mostrar_tab_estadisticas(df):
    st.markdown("### 📊 Estadísticas de Ventas")

    if st.button("🔄 Recargar datos", key="reload"):
        limpiar_cache_catalogo()
        st.rerun()

    st.markdown("---")
    try:
        df_ventas = cargar_ventas()
        subtab1, subtab2, subtab3 = st.tabs([
            "📊 Estadísticas",
            "📦 Pendientes",
            "📅 Semanal & Meses"
        ])
        with subtab1:
            mostrar_estadisticas(df_ventas, df)
        with subtab2:
            mostrar_ventas_pendientes(df_ventas, df)
        with subtab3:
            mostrar_resumen_semanal(df_ventas, df)
    except Exception as e:
        st.error(f"❌ Error cargando ventas: {e}")
        if st.session_state.get("error_log"):
            with st.expander("🔍 Log de errores"):
                for log in st.session_state["error_log"]:
                    st.code(log)
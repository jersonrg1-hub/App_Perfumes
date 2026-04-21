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


@st.fragment
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

        with st.expander("🔍 Diagnóstico de datos", expanded=False):
            from config import hoy_peru
            st.write(f"**Hoy (Peru):** `{hoy_peru()}`")
            st.write(f"**Filas cargadas:** `{len(df_ventas)}`")
            if not df_ventas.empty:
                st.write(f"**Columnas:** `{list(df_ventas.columns)}`")
                st.write(f"**Tipo columna Fecha:** `{df_ventas['Fecha'].dtype if 'Fecha' in df_ventas.columns else 'NO EXISTE'}`")
                if "Fecha" in df_ventas.columns:
                    st.write(f"**Primeras fechas:** `{df_ventas['Fecha'].head(4).tolist()}`")
            else:
                st.warning("⚠️ df_ventas está vacío")
            if st.session_state.get("error_log"):
                st.markdown("**Errores:**")
                for e in st.session_state["error_log"][-5:]:
                    st.code(e)

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
                ["📈 Gráficos", "🧪 Stock"],
                horizontal=True,
                label_visibility="collapsed",
                key="analisis_radio",
            )
            st.markdown("")
            if seccion_analisis == "📈 Gráficos":
                mostrar_graficos(df_ventas)
            elif seccion_analisis == "🧪 Stock":
                mostrar_panel_stock(df)

    except Exception as e:
        st.error(f"❌ Error cargando ventas: {e}")
        if st.session_state.get("error_log"):
            with st.expander("🔍 Log de errores"):
                for log in st.session_state["error_log"]:
                    st.code(log)
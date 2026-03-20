import streamlit as st
from styles import get_styles
from data import cargar_catalogo
from components import mostrar_encabezado
from errores import (
    mostrar_error_conexion,
    mostrar_error_datos_vacios,
    mostrar_error_columna,
    validar_dataframe
)
from auth import check_password, mostrar_login, cerrar_sesion
from tabs.tab_marca import mostrar_tab_marca
from tabs.tab_nombre import mostrar_tab_nombre
from tabs.tab_venta import mostrar_tab_venta
from tabs.tab_estadisticas import mostrar_tab_estadisticas
from tabs.tab_notas import mostrar_tab_notas

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")
st.markdown("""
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)
mostrar_encabezado()

try:
    df = cargar_catalogo()

    if df.empty:
        mostrar_error_datos_vacios()
        st.stop()

    columnas_faltantes = validar_dataframe(df)
    if columnas_faltantes:
        for col in columnas_faltantes:
            mostrar_error_columna(col)
        st.stop()

    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "🏷️  Por Marca",
        "🔍  Por Nombre",
        "🎵  Por Nota",
        "📝  Nueva Venta",
        "📊  Estadísticas",
        "🔒  Sesión"
    ])

    with tab1:
        mostrar_tab_marca(df)

    with tab2:
        mostrar_tab_nombre(df)

    with tab3:
        mostrar_tab_notas(df)

    with tab4:
        if check_password():
            mostrar_tab_venta(df)
        else:
            mostrar_login(key="tab4")

    with tab5:
        if check_password():
            cerrar_sesion(key="logout_tab5")
            mostrar_tab_estadisticas(df)
        else:
            mostrar_login(key="tab5")

    with tab6:
        if check_password():
            st.markdown("### 🔓 Sesión activa")
            st.success("✅ Estás autenticada")
            cerrar_sesion(key="logout_tab6")
        else:
            mostrar_login(key="tab6")

except Exception as e:
    mostrar_error_conexion()
    with st.expander("🔍 Ver detalle del error"):
        st.code(str(e))
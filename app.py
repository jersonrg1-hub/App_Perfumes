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
# Importamos las nuevas funciones de auth
from auth import inicializar_auth, login_seccion, check_auth, mostrar_boton_logout

from tabs.tab_marca import mostrar_tab_marca
from tabs.tab_nombre import mostrar_tab_nombre
from tabs.tab_venta import mostrar_tab_venta
from tabs.tab_estadisticas import mostrar_tab_estadisticas
from tabs.tab_notas import mostrar_tab_notas

# 1. Configuración de página
st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")

# 2. Inicializar estado de autenticación
inicializar_auth()

st.markdown("""
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)

# 3. Encabezado y Botón de Logout Global (en el Sidebar)
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

    # Definición de las Tabs
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "🏷️ Marca",
        "🔍 Nombre",
        "🎵 Notas",
        "📝 Venta",
        "📊 Estadísticas",
        "🔐 Sesión"
    ])

    with tab1:
        mostrar_tab_marca(df)

    with tab2:
        mostrar_tab_nombre(df)

    with tab3:
        mostrar_tab_notas(df)

    with tab4:
        # Usamos la nueva función login_seccion que maneja el formulario y el estado
        if login_seccion(key_suffix="venta"):
            mostrar_tab_venta(df)

    with tab5:
        if login_seccion(key_suffix="stats"):
            mostrar_tab_estadisticas(df)

    with tab6:
        if check_auth():
            st.success("### ✅ Sesión Activa")
            st.write("Tienes acceso a las secciones de administración (Ventas y Estadísticas).")
            # Botón adicional por si no mira el sidebar
            mostrar_boton_logout()
        else:
            st.info("### 🔒 Modo Invitado")
            st.write("Ingresa la contraseña para gestionar ventas e inventario.")
            login_seccion(key_suffix="tab_final")

except Exception as e:
    mostrar_error_conexion()
    with st.expander("🔍 Ver detalle del error"):
        st.code(str(e))
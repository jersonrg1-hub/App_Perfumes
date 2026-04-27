import streamlit as st
from styles import get_styles
from data import cargar_catalogo, cargar_ventas, cargar_cotizaciones, limpiar_cache_catalogo
from components import mostrar_encabezado
from errores import (
    mostrar_error_conexion,
    mostrar_error_datos_vacios,
    mostrar_error_columna,
    validar_dataframe,
)
from auth import inicializar_auth, login_seccion, check_auth, mostrar_boton_logout

from tabs.tab_marca import mostrar_tab_marca
from tabs.tab_nombre import mostrar_tab_nombre
from tabs.tab_venta import mostrar_tab_venta
from tabs.tab_estadisticas import mostrar_tab_estadisticas
from tabs.tab_notas import mostrar_tab_notas

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")

inicializar_auth()

st.markdown(
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    unsafe_allow_html=True,
)
# Fuentes no bloqueantes: preconnect + link en lugar de @import dentro de <style>
st.markdown("""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Lato:wght@300;400;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
""", unsafe_allow_html=True)
st.markdown(get_styles(), unsafe_allow_html=True)

st.markdown("""
<script>
(function() {
    var hiddenAt = null;
    var LIMITE_MS = 3 * 60 * 1000;
    document.addEventListener('visibilitychange', function() {
        if (document.hidden) {
            hiddenAt = Date.now();
        } else {
            if (hiddenAt !== null && (Date.now() - hiddenAt) > LIMITE_MS) {
                window.location.reload();
            }
            hiddenAt = null;
        }
    });
})();
</script>
""", unsafe_allow_html=True)

mostrar_encabezado()

try:
    df = cargar_catalogo()

    # Precalentar caches + calcular badge de pedidos pendientes
    _n_pend = 0
    try:
        _df_v = cargar_ventas()
        cargar_cotizaciones()
        if not _df_v.empty and "Estado" in _df_v.columns and "ID_Compra" in _df_v.columns:
            _n_pend = int(_df_v[~_df_v["Estado"].isin(["Entregado", "Anulado"])]["ID_Compra"].nunique())
    except Exception:
        pass

    if df.empty:
        mostrar_error_datos_vacios()
        if st.button("🔄 Reintentar", key="retry_empty"):
            limpiar_cache_catalogo()
            st.rerun()
        st.stop()

    columnas_faltantes = validar_dataframe(df)
    if columnas_faltantes:
        for col in columnas_faltantes:
            mostrar_error_columna(col)
        st.stop()

    _label_stats = f"📊 Estadísticas ({_n_pend})" if _n_pend > 0 else "📊 Estadísticas"
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "🏷️ Marca",
        "🔍 Nombre",
        "🎵 Notas",
        "📝 Venta",
        _label_stats,
        "🔐 Sesión",
    ])

    with tab1:
        mostrar_tab_marca(df)

    with tab2:
        mostrar_tab_nombre(df)

    with tab3:
        mostrar_tab_notas(df)

    with tab4:
        if check_auth():
            mostrar_tab_venta(df)
            mostrar_boton_logout(key_suffix="tab4")
        else:
            login_seccion(key_suffix="venta")

    with tab5:
        if check_auth():
            mostrar_tab_estadisticas(df)
            mostrar_boton_logout(key_suffix="tab5")
        else:
            login_seccion(key_suffix="stats")

    with tab6:
        if check_auth():
            st.success("### ✅ Sesión Activa")
            st.write("Tienes acceso a las secciones de administración (Ventas y Estadísticas).")
            mostrar_boton_logout(key_suffix="tab6")
        else:
            st.info("### 🔒 Modo Invitado")
            st.write("Ingresa la contraseña para gestionar ventas e inventario.")
            login_seccion(key_suffix="tab_final")

except ConnectionError:
    mostrar_error_conexion()
    if st.button("🔄 Reintentar conexión", key="retry_conn"):
        limpiar_cache_catalogo()
        st.rerun()

except Exception as e:
    mostrar_error_conexion()
    with st.expander("🔍 Ver detalle del error"):
        st.code(str(e))
    if st.button("🔄 Reintentar", key="retry_exc"):
        limpiar_cache_catalogo()
        st.rerun()

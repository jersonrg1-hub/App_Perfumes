import streamlit as st


def inicializar_auth():
    """Asegura que las variables de sesión existan al arrancar la app"""
    if "autenticado" not in st.session_state:
        st.session_state.autenticado = False
    if "intentos_login" not in st.session_state:
        st.session_state.intentos_login = 0


def login_seccion(key_suffix="default"):
    """
    Muestra la interfaz de login.
    Retorna True si el usuario acaba de autenticarse con éxito.
    """
    inicializar_auth()

    # Si ya está autenticado, no mostramos nada
    if st.session_state.autenticado:
        return True

    st.markdown("---")
    st.info("### 🔒 Acceso Restringido")
    st.caption("Esta sección contiene información sensible de costos o inventario.")

    # Lógica de bloqueo por intentos
    MAX_INTENTOS = 3
    if st.session_state.intentos_login >= MAX_INTENTOS:
        st.error(f"🚫 Acceso bloqueado tras {MAX_INTENTOS} intentos fallidos.")
        if st.button("🔄 Reintentar"):
            st.session_state.intentos_login = 0
            st.rerun()
        return False

    # Formulario de login
    with st.form(key=f"login_form_{key_suffix}"):
        password = st.text_input("Contraseña de Administrador", type="password")
        submit = st.form_submit_button("🔓 Desbloquear Sección", use_container_width=True)

        if submit:
            # Obtenemos la clave de los secrets de Streamlit
            app_password = st.secrets.get("APP_PASSWORD")

            if not app_password:
                st.warning("⚠️ Configuración incompleta: falta 'APP_PASSWORD' en secrets.")
                return False

            if password == app_password:
                st.session_state.autenticado = True
                st.session_state.intentos_login = 0
                st.success("✅ Acceso concedido")
                st.rerun()
            else:
                st.session_state.intentos_login += 1
                intentos_restantes = MAX_INTENTOS - st.session_state.intentos_login
                st.error(f"❌ Incorrecto. Intentos restantes: {intentos_restantes}")

    return False


def check_auth():
    """Función rápida para verificar si hay permiso"""
    return st.session_state.get("autenticado", False)


def mostrar_boton_logout():
    """Muestra un botón de logout sencillo y centrado"""
    if st.session_state.get("autenticado"):
        # Usamos columnas para que el botón no ocupe todo el ancho de la pantalla
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            if st.button("🔒 Cerrar Sesión de Admin", use_container_width=True):
                st.session_state.autenticado = False
                st.rerun()
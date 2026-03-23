import hmac
import streamlit as st


def inicializar_auth():
    if "autenticado" not in st.session_state:
        st.session_state.autenticado = False
    if "intentos_login" not in st.session_state:
        st.session_state.intentos_login = 0


def login_seccion(key_suffix="default"):
    inicializar_auth()

    if st.session_state.autenticado:
        return True

    st.markdown("---")
    st.info("### 🔒 Acceso Restringido")
    st.caption("Esta sección contiene información sensible de costos o inventario.")

    MAX_INTENTOS = 3  # ⚠️ Se resetea si el usuario recarga la página (F5)

    if st.session_state.intentos_login >= MAX_INTENTOS:
        st.error(f"🚫 Acceso bloqueado tras {MAX_INTENTOS} intentos fallidos.")
        if st.button("🔄 Reintentar"):
            st.session_state.intentos_login = 0
            st.rerun()
        return False

    with st.form(key=f"login_form_{key_suffix}"):
        password = st.text_input("Contraseña de Administrador", type="password")
        submit = st.form_submit_button("🔓 Desbloquear Sección", use_container_width=True)

        if submit:
            try:
                app_password = st.secrets["APP_PASSWORD"]
            except KeyError:
                st.warning("⚠️ Configuración incompleta: falta 'APP_PASSWORD' en secrets.")
                return False

            if hmac.compare_digest(password, app_password):
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
    return st.session_state.get("autenticado", False)


def mostrar_boton_logout():
    if st.session_state.get("autenticado"):
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            if st.button("🔒 Cerrar Sesión de Admin", use_container_width=True):
                st.session_state.autenticado = False
                st.session_state.intentos_login = 0
                st.rerun()
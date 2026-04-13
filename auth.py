import hmac
import time
import streamlit as st

MAX_INTENTOS = 3
BLOQUEO_SEGUNDOS = 60  # 1 minuto de bloqueo tras agotar intentos


def inicializar_auth():
    defaults = {
        "autenticado": False,
        "intentos_login": 0,
        "bloqueado_hasta": 0.0,
    }
    for k, v in defaults.items():
        if k not in st.session_state:
            st.session_state[k] = v


def _segundos_restantes():
    restantes = st.session_state.bloqueado_hasta - time.time()
    return max(0.0, restantes)


def login_seccion(key_suffix="default"):
    inicializar_auth()

    if st.session_state.autenticado:
        return True

    st.markdown("---")
    st.info("### 🔒 Acceso Restringido\nEsta sección contiene información sensible de costos o inventario.")

    # Bloqueo temporal
    seg = _segundos_restantes()
    if seg > 0:
        minutos = int(seg // 60)
        segundos = int(seg % 60)
        tiempo_txt = f"{minutos}m {segundos}s" if minutos else f"{segundos}s"
        st.error(f"🚫 Demasiados intentos fallidos. Espera **{tiempo_txt}** para volver a intentar.")
        if st.button("🔄 Verificar si ya pasó el tiempo", key=f"recheck_{key_suffix}"):
            st.rerun()
        return False

    intentos_restantes = MAX_INTENTOS - st.session_state.intentos_login
    if intentos_restantes < MAX_INTENTOS:
        st.caption(f"Intentos restantes: {intentos_restantes}")

    with st.form(key=f"login_form_{key_suffix}"):
        password = st.text_input(
            "Contraseña de Administrador",
            type="password",
            placeholder="Ingresa la contraseña",
        )
        submit = st.form_submit_button("🔓 Desbloquear", use_container_width=True)

        if submit:
            if not password:
                st.warning("Ingresa la contraseña.")
                return False

            try:
                app_password = st.secrets["APP_PASSWORD"]
            except KeyError:
                st.warning("⚠️ Configuración incompleta: falta 'APP_PASSWORD' en secrets.")
                return False

            if hmac.compare_digest(password, app_password):
                st.session_state.autenticado = True
                st.session_state.intentos_login = 0
                st.session_state.bloqueado_hasta = 0.0
                st.success("✅ Acceso concedido")
                st.rerun()
            else:
                st.session_state.intentos_login += 1
                restantes = MAX_INTENTOS - st.session_state.intentos_login
                if restantes <= 0:
                    st.session_state.bloqueado_hasta = time.time() + BLOQUEO_SEGUNDOS
                    st.error(f"🚫 Bloqueado por {BLOQUEO_SEGUNDOS // 60} minuto. Vuelve a intentar después.")
                else:
                    st.error(f"❌ Contraseña incorrecta. Intentos restantes: {restantes}")

    return False


def check_auth():
    return st.session_state.get("autenticado", False)


def mostrar_boton_logout(key_suffix="default"):
    if st.session_state.get("autenticado"):
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            if st.button("🔒 Cerrar Sesión", key=f"cerrar_sesion_{key_suffix}", use_container_width=True):
                st.session_state.autenticado = False
                st.session_state.intentos_login = 0
                st.session_state.bloqueado_hasta = 0.0
                st.rerun()

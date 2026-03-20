import streamlit as st

def check_password():
    if "autenticado" not in st.session_state:
        st.session_state.autenticado = False
    return st.session_state.autenticado

def mostrar_login(key="login"):
    st.markdown("---")
    st.markdown("### 🔒 Área Privada")
    st.markdown("Esta sección requiere contraseña")

    # ── Inicializar contador de intentos ──────────────────
    if "intentos_login" not in st.session_state:
        st.session_state.intentos_login = 0

    # ── Bloquear si demasiados intentos ───────────────────
    if st.session_state.intentos_login >= 3:
        st.error("🚫 Demasiados intentos fallidos. Recarga la página para intentar de nuevo.")
        return

    with st.form(f"form_login_{key}"):
        password = st.text_input(
            "Contraseña",
            type="password",
            placeholder="Ingresa la contraseña"
        )
        submitted = st.form_submit_button("🔓 Ingresar", use_container_width=True)

        if submitted:
            APP_PASSWORD = st.secrets.get("APP_PASSWORD", None)

            if not APP_PASSWORD:
                st.error("⚠️ Contraseña no configurada. Contacta al administrador.")
                return

            if password == APP_PASSWORD:
                st.session_state.autenticado = True
                st.session_state.intentos_login = 0
                st.rerun()
            else:
                st.session_state.intentos_login += 1
                intentos_restantes = 3 - st.session_state.intentos_login
                if intentos_restantes > 0:
                    st.error(f"❌ Contraseña incorrecta. {intentos_restantes} intento(s) restante(s)")
                else:
                    st.error("🚫 Has agotado todos los intentos. Recarga la página.")

def cerrar_sesion(key="logout"):
    if st.button("🔒 Cerrar sesión", key=key):
        st.session_state.autenticado = False
        st.session_state.intentos_login = 0
        st.rerun()
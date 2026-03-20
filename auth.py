import streamlit as st

def check_password():
    if "autenticado" not in st.session_state:
        st.session_state.autenticado = False
    return st.session_state.autenticado

def mostrar_login(key="login"):
    st.markdown("---")
    st.markdown("### 🔒 Área Privada")
    st.markdown("Esta sección requiere contraseña")

    with st.form(f"form_login_{key}"):
        password = st.text_input("Contraseña", type="password", placeholder="Ingresa la contraseña")
        submitted = st.form_submit_button("🔓 Ingresar", use_container_width=True)

        if submitted:
            if password == st.secrets.get("APP_PASSWORD", ""):
                st.session_state.autenticado = True
                st.rerun()
            else:
                st.error("❌ Contraseña incorrecta")

def cerrar_sesion(key="logout"):
    if st.button("🔒 Cerrar sesión", key=key):
        st.session_state.autenticado = False
        st.rerun()
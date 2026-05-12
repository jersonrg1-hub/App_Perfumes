"""
auth.py — UI de autenticación (Streamlit).

Decisión de arquitectura:
  - Lógica pura (hmac, intentos, bloqueo): backend/services/auth_service.py
  - Renderizado (formulario, botones, mensajes): este módulo (Streamlit)

Esto permite que FastAPI implemente su propio flujo de autenticación
(JWT, OAuth2) reutilizando auth_service.py sin depender de Streamlit.

Estado en: state.get_state()["auth"]
  - "autenticado"    : bool
  - "intentos"       : int
  - "bloqueado_hasta": float (timestamp)
"""
import streamlit as st
from state import get_state
from data import cargar_ventas
from backend.services.auth_service import (
    verificar_contrasena,
    segundos_restantes,
    calcular_bloqueo_hasta,
    MAX_INTENTOS,
    BLOQUEO_SEGUNDOS,
)


def inicializar_auth() -> None:
    """Garantiza que el sub-estado de auth exista. Idempotente."""
    get_state()


def login_seccion(key_suffix: str = "default") -> bool:
    """
    Renderiza el formulario de login.
    Retorna True si el usuario está autenticado, False en caso contrario.
    """
    state = get_state()
    auth = state["auth"]

    if auth["autenticado"]:
        return True

    st.markdown("---")
    st.info(
        "### 🔒 Acceso Restringido\n"
        "Esta sección contiene información sensible de costos o inventario."
    )

    seg = segundos_restantes(auth["bloqueado_hasta"])
    if seg > 0:
        minutos = int(seg // 60)
        segundos = int(seg % 60)
        tiempo_txt = f"{minutos}m {segundos}s" if minutos else f"{segundos}s"
        st.error(
            f"🚫 Demasiados intentos fallidos. "
            f"Espera **{tiempo_txt}** para volver a intentar."
        )
        if st.button("🔄 Verificar si ya pasó el tiempo", key=f"recheck_{key_suffix}"):
            st.rerun()
        return False

    intentos_usados = auth["intentos"]
    if intentos_usados > 0:
        st.caption(f"Intentos restantes: {MAX_INTENTOS - intentos_usados}")

    app_password = None
    try:
        app_password = st.secrets["APP_PASSWORD"]
    except (KeyError, FileNotFoundError):
        st.error(
            "⚠️ Error de configuración: no se encontró APP_PASSWORD en los secrets. "
            "Revisa la configuración en Streamlit Cloud."
        )
        return False

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

            if verificar_contrasena(password, app_password):
                auth["autenticado"] = True
                auth["intentos"] = 0
                auth["bloqueado_hasta"] = 0.0
                cargar_ventas()
                st.success("✅ Acceso concedido")
                st.rerun()
            else:
                auth["intentos"] += 1
                restantes = MAX_INTENTOS - auth["intentos"]
                if restantes <= 0:
                    auth["bloqueado_hasta"] = calcular_bloqueo_hasta()
                    st.error(
                        f"🚫 Bloqueado por {BLOQUEO_SEGUNDOS // 60} minuto. "
                        "Vuelve a intentar después."
                    )
                else:
                    st.error(
                        f"❌ Contraseña incorrecta. "
                        f"Intentos restantes: {restantes}"
                    )

    return False


def check_auth() -> bool:
    return get_state()["auth"]["autenticado"]


def mostrar_boton_logout(key_suffix: str = "default") -> None:
    state = get_state()
    auth = state["auth"]
    if auth["autenticado"]:
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            if st.button(
                "🔒 Cerrar Sesión",
                key=f"cerrar_sesion_{key_suffix}",
                use_container_width=True,
            ):
                auth["autenticado"] = False
                auth["intentos"] = 0
                auth["bloqueado_hasta"] = 0.0
                st.rerun()

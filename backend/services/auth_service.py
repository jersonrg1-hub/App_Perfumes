"""
backend/services/auth_service.py — Lógica pura de autenticación.

Sin dependencias de Streamlit. Puede usarse desde FastAPI con JWT,
OAuth2 o cualquier otro mecanismo de autenticación.

La UI de login (formulario, botones, mensajes) vive en auth.py (Streamlit).
Este módulo solo contiene la lógica verificable: hmac, intentos, bloqueo.
"""
import hmac
import time

MAX_INTENTOS: int = 3
BLOQUEO_SEGUNDOS: int = 60


def verificar_contrasena(password: str, correcta: str) -> bool:
    """Comparación en tiempo constante para prevenir timing attacks."""
    return hmac.compare_digest(password, correcta)


def segundos_restantes(bloqueado_hasta: float) -> float:
    """Retorna los segundos que faltan para que expire el bloqueo."""
    return max(0.0, bloqueado_hasta - time.time())


def calcular_bloqueo_hasta() -> float:
    """Retorna el timestamp hasta el que debe estar bloqueado el usuario."""
    return time.time() + BLOQUEO_SEGUNDOS


def esta_bloqueado(auth_state: dict) -> bool:
    """Retorna True si el usuario sigue en período de bloqueo."""
    return segundos_restantes(auth_state.get("bloqueado_hasta", 0.0)) > 0


def intentos_restantes(auth_state: dict) -> int:
    return max(0, MAX_INTENTOS - auth_state.get("intentos", 0))

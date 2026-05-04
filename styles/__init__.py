from styles.base import BASE
from styles.components import COMPONENTS
from styles.tabs import TABS
from styles.forms import FORMS
from styles.animations import ANIMATIONS
from styles.mobile import MOBILE

# Computed once at import time — never rebuilt on reruns
_STYLES = f"<style>{BASE}{COMPONENTS}{TABS}{FORMS}{ANIMATIONS}{MOBILE}</style>"


def get_styles() -> str:
    return _STYLES
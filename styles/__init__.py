from styles.base import BASE
from styles.components import COMPONENTS
from styles.tabs import TABS
from styles.forms import FORMS
from styles.animations import ANIMATIONS
from styles.mobile import MOBILE

def get_styles():
    return f"<style>{BASE}{COMPONENTS}{TABS}{FORMS}{ANIMATIONS}{MOBILE}</style>"
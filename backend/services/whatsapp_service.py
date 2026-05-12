"""
backend/services/whatsapp_service.py — Generación de URLs de WhatsApp.

Sin dependencias de Streamlit. Puede reutilizarse desde FastAPI para
generar links de confirmación en endpoints REST.

Fuente de verdad: extraído de components.py → generar_url_whatsapp().
"""
from datetime import datetime, timedelta
from urllib.parse import quote
from backend.core.config import TZ_PERU, fmt_precio

_DIAS = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
_MESES = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
]


def generar_url_whatsapp(
    id_compra: str,
    comprador: str,
    celular: str,
    direccion: str,
    tipo_envio: str,
    cesta: list[dict],
    total: float,
) -> str:
    """
    Genera la URL de WhatsApp con el comprobante de compra.
    Calcula fecha de envío estimada (mañana en TZ Lima).
    """
    manana = datetime.now(TZ_PERU).date() + timedelta(days=1)
    fecha_envio = f"{_DIAS[manana.weekday()]} {manana.day} de {_MESES[manana.month - 1]}"

    items_texto = "\n".join([
        f"  🌸 *{i['marca']}* · {i['perfume']} · {i['ml']}ml"
        if i.get("marca") else
        f"  🌸 {i['perfume']} · {i['ml']}ml"
        for i in cesta
    ])
    dir_linea = f"\n📍 *Dirección:* {direccion}" if direccion and direccion.strip() else ""

    mensaje = (
        f"🌸 *Perfuteca — Pedido {id_compra}*\n"
        f"────────────────────\n"
        f"👤 *Comprador:* {comprador}\n"
        f"📱 *Celular:* {celular}\n"
        f"🚚 *Envío:* {tipo_envio}"
        f"{dir_linea}\n"
        f"────────────────────\n"
        f"🛍️ *Tu pedido:*\n"
        f"{items_texto}\n"
        f"────────────────────\n"
        f"📦 Tu pedido estará siendo enviado el *{fecha_envio}*.\n\n"
        f"_¡Gracias por tu compra! 💛_"
    )
    return f"https://wa.me/?text={quote(mensaje)}"

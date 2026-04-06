import streamlit as st
from urllib.parse import quote
from config import fmt_precio


def mostrar_encabezado():
    st.markdown(
        '<div class="header-wrapper">'
        '<div class="header-ornamento">'
        '<div class="header-ornamento-dot"></div>'
        '<div class="header-ornamento-dot"></div>'
        '<div class="header-ornamento-dot"></div>'
        '</div>'
        '<div class="titulo-app">🌸 Perfuteca</div>'
        '<div class="subtitulo-app">Catálogo de Precios</div>'
        '<div class="header-linea">'
        '<span class="header-linea-symbol">✦ ✦ ✦</span>'
        '</div>'
        '</div>',
        unsafe_allow_html=True
    )


def generar_url_whatsapp(id_compra, comprador, celular, direccion, tipo_envio, cesta, total):
    items_texto = "\n".join([
        f"- {i.get('marca', '')} {i['perfume']} {i['ml']}ml → S/ {fmt_precio(i['precio'])}"
        if i.get('marca') else
        f"- {i['perfume']} {i['ml']}ml → S/ {fmt_precio(i['precio'])}"
        for i in cesta
    ])
    mensaje = (
        f"🌸 *RESUMEN DE VENTA {id_compra}*\n"
        f"━━━━━━━━━━━━━━━━\n"
        f"👤 *Comprador:* {comprador}\n"
        f"📱 *Celular:* {celular}\n"
        f"📍 *Dirección:* {direccion}\n"
        f"🚚 *Envío:* {tipo_envio}\n"
        f"━━━━━━━━━━━━━━━━\n"
        f"🛍️ *Productos:*\n"
        f"{items_texto}\n"
        f"━━━━━━━━━━━━━━━━\n"
        f"💰 *Total: S/ {fmt_precio(total)}*"
    )
    return f"https://wa.me/?text={quote(mensaje)}"


def separador(simbolo="✦", texto=""):
    contenido = f"{simbolo} {texto} {simbolo}" if texto else f"{simbolo} &nbsp; {simbolo} &nbsp; {simbolo}"
    linea_izq = "flex:1;height:0.5px;background:linear-gradient(to right,transparent,#c8956c);"
    linea_der = "flex:1;height:0.5px;background:linear-gradient(to left,transparent,#c8956c);"
    span_style = "color:#c8956c;font-size:0.75rem;letter-spacing:0.18em;font-family:Lato,sans-serif;font-weight:400;white-space:nowrap;"
    html = (
        f'<div style="display:flex;align-items:center;gap:12px;margin:1.2rem 0;opacity:0.7;">'
        f'<div style="{linea_izq}"></div>'
        f'<span style="{span_style}">{contenido}</span>'
        f'<div style="{linea_der}"></div>'
        f'</div>'
    )
    st.markdown(html, unsafe_allow_html=True)
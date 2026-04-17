import html as _html

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
        f"  🌸 *{i['marca']}* · {i['perfume']} · {i['ml']}ml · S/ {fmt_precio(i['precio'])}"
        if i.get('marca') else
        f"  🌸 {i['perfume']} · {i['ml']}ml · S/ {fmt_precio(i['precio'])}"
        for i in cesta
    ])
    dir_linea = f"\n📍 *Dirección:* {direccion}" if direccion and direccion.strip() else ""
    mensaje = (
        f"🌸 *Perfuteca — Comprobante {id_compra}*\n"
        f"────────────────────\n"
        f"👤 *Comprador:* {comprador}\n"
        f"📱 *Celular:* {celular}\n"
        f"🚚 *Envío:* {tipo_envio}"
        f"{dir_linea}\n"
        f"────────────────────\n"
        f"🛍️ *Productos:*\n"
        f"{items_texto}\n"
        f"────────────────────\n"
        f"💰 *Total: S/ {fmt_precio(total)}*\n\n"
        f"_¡Gracias por tu compra! 💛_"
    )
    return f"https://wa.me/?text={quote(mensaje)}"


def construir_catalogo_dict(df_catalogo):
    """Devuelve {str(ID_Perfume): Nombre} para lookup O(1) desde ventas."""
    if df_catalogo is None or df_catalogo.empty:
        return {}
    return dict(zip(df_catalogo["ID_Perfume"].astype(str), df_catalogo["Nombre"]))


def nombre_por_id(catalogo_dict, id_perfume):
    """Resuelve el nombre de un perfume a partir de su ID."""
    return catalogo_dict.get(str(id_perfume), f"ID: {id_perfume}")


def mostrar_placeholder_vacio(emoji, titulo, subtitulo):
    """Estado vacío estándar: ícono centrado + título + subtexto."""
    titulo_safe = _html.escape(str(titulo))
    subtitulo_safe = _html.escape(str(subtitulo))
    st.markdown(
        f"""<div style="
            text-align:center; padding:2.5rem 1.5rem; margin-top:1rem;
            background:#ffffff; border:1px dashed #e0c9b4; border-radius:16px;
        ">
            <div style="font-size:2.2rem; margin-bottom:0.7rem;">{emoji}</div>
            <div style="font-family:'Playfair Display',serif; font-size:1.05rem;
                color:#2c1a0e; font-weight:600; margin-bottom:0.3rem;">
                {titulo_safe}
            </div>
            <div style="font-size:0.83rem; color:#a07850;">
                {subtitulo_safe}
            </div>
        </div>""",
        unsafe_allow_html=True,
    )


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
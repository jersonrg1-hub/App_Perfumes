import html as html_lib
import streamlit as st
from pathlib import Path
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


def mostrar_perfume_card(marca, nombre, url_imagen=""):
    marca_safe = html_lib.escape(str(marca))
    nombre_safe = html_lib.escape(str(nombre))

    st.markdown(
        f'<div class="perfume-card">'
        f'<div class="marca">{marca_safe}</div>'
        f'<div class="nombre">{nombre_safe}</div>'
        f'</div>',
        unsafe_allow_html=True
    )

    if url_imagen:
        imagen_path = Path(__file__).parent / url_imagen
        if imagen_path.exists():
            with open(imagen_path, "rb") as f:
                st.image(f.read(), width=200)
        else:
            st.caption("📷 Imagen no disponible")


def mostrar_todos_precios(perfume, precios_columnas):
    if hasattr(perfume, 'to_dict'):
        perfume = perfume.to_dict()

    st.markdown("#### 💰 Precios por tamaño")
    cols = st.columns(len(precios_columnas))

    for i, (tamanio, columna) in enumerate(precios_columnas.items()):
        precio = perfume.get(columna, "")
        tamanio_safe = html_lib.escape(str(tamanio))

        with cols[i]:
            if precio not in (0, "", None):
                st.markdown(
                    f'<div class="precio-card" style="'
                    f'background:linear-gradient(135deg,#2c1a0e,#5c3a1e);'
                    f'border-radius:12px;padding:1.2rem 0.8rem;'
                    f'text-align:center;box-shadow:0 3px 12px rgba(44,26,14,0.25);'
                    f'margin-bottom:0.5rem;">'
                    f'<div style="color:#e8c9a8;font-size:0.85rem;letter-spacing:0.12em;'
                    f'text-transform:uppercase;margin-bottom:0.3rem;">{tamanio_safe}</div>'
                    f'<div style="color:white;font-family:\'Playfair Display\',serif;'
                    f'font-size:2rem;font-weight:700;line-height:1;">S/ {fmt_precio(precio)}</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )
            else:
                st.markdown(
                    f'<div style="background:#f5ede6;border-radius:12px;padding:1rem;'
                    f'text-align:center;border:1px dashed #e0c9b4;margin-bottom:0.5rem;">'
                    f'<div style="color:#c8956c;font-size:0.75rem;letter-spacing:0.1em;'
                    f'text-transform:uppercase;">{tamanio_safe}</div>'
                    f'<div class="sin-precio">Sin precio</div>'
                    f'</div>',
                    unsafe_allow_html=True
                )


def generar_url_whatsapp(id_compra, comprador, celular, direccion, tipo_envio, cesta, total):
    items_texto = "\n".join([
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
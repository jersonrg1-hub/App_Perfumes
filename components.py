import streamlit as st
from pathlib import Path
from config import fmt_precio

# Ruta base del proyecto para imágenes
BASE_DIR = Path(__file__).parent.parent

def mostrar_encabezado():
    st.markdown('<div class="titulo-app">🌸 Decants</div>', unsafe_allow_html=True)
    st.markdown('<div class="subtitulo-app">Catálogo de Precios</div>', unsafe_allow_html=True)

def mostrar_perfume_card(marca, nombre, url_imagen=""):
    st.markdown(f"""
    <div style="
        background: white;
        border-left: 4px solid #c8956c;
        border-radius: 12px;
        padding: 1.2rem 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 2px 12px rgba(160, 120, 80, 0.12);
    ">
        <div style="font-size:0.8rem; letter-spacing:0.12em; text-transform:uppercase; color:#a07850; font-weight:600; margin-bottom:0.2rem;">{marca}</div>
        <div style="font-family:'Playfair Display',serif; font-size:1.4rem; color:#2c1a0e; font-weight:600;">{nombre}</div>
    </div>
    """, unsafe_allow_html=True)

    if url_imagen:
        imagen_path = BASE_DIR / url_imagen
        if imagen_path.exists():
            st.image(str(imagen_path), width=200)
        else:
            st.caption("📷 Imagen no disponible")

def mostrar_todos_precios(perfume, precios_columnas):
    if hasattr(perfume, 'to_dict'):
        perfume = perfume.to_dict()

    st.markdown("#### 💰 Precios por tamaño")
    cols = st.columns(len(precios_columnas))

    for i, (tamanio, columna) in enumerate(precios_columnas.items()):
        precio = perfume.get(columna, "")
        with cols[i]:
            if precio:
                st.markdown(f"""
                <div style="
                    background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
                    border-radius: 12px;
                    padding: 1rem;
                    text-align: center;
                    box-shadow: 0 2px 10px rgba(44,26,14,0.2);
                    margin-bottom: 0.5rem;
                ">
                    <div style="color:#e8c9a8; font-size:0.75rem; letter-spacing:0.1em; text-transform:uppercase;">{tamanio}</div>
                    <div style="color:white; font-family:'Playfair Display',serif; font-size:1.4rem; font-weight:700;">S/ {fmt_precio(precio)}</div>
                </div>
                """, unsafe_allow_html=True)
            else:
                st.markdown(f"""
                <div style="
                    background: #f5ede6;
                    border-radius: 12px;
                    padding: 1rem;
                    text-align: center;
                    border: 1px dashed #e0c9b4;
                    margin-bottom: 0.5rem;
                ">
                    <div style="color:#c8956c; font-size:0.75rem; letter-spacing:0.1em; text-transform:uppercase;">{tamanio}</div>
                    <div style="color:#bbb; font-size:0.85rem; font-style:italic;">Sin precio</div>
                </div>
                """, unsafe_allow_html=True)

def generar_url_whatsapp(id_compra, comprador, celular, direccion, tipo_envio, cesta, total):
    items_texto = "%0A".join([
        f"- {i['perfume']} {i['ml']}ml → S/ {fmt_precio(i['precio'])}"
        for i in cesta
    ])
    mensaje = (
        f"🌸 *RESUMEN DE VENTA {id_compra}*%0A"
        f"━━━━━━━━━━━━━━━━%0A"
        f"👤 *Comprador:* {comprador}%0A"
        f"📱 *Celular:* {celular}%0A"
        f"📍 *Dirección:* {direccion}%0A"
        f"🚚 *Envío:* {tipo_envio}%0A"
        f"━━━━━━━━━━━━━━━━%0A"
        f"🛍️ *Productos:*%0A"
        f"{items_texto}%0A"
        f"━━━━━━━━━━━━━━━━%0A"
        f"💰 *Total: S/ {fmt_precio(total)}*"
    )
    return f"https://wa.me/?text={mensaje}"
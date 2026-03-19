import streamlit as st
from pathlib import Path

def mostrar_encabezado():
    st.markdown('<div class="titulo-app">🌸 Decants</div>', unsafe_allow_html=True)
    st.markdown('<div class="subtitulo-app">Catálogo de Precios</div>', unsafe_allow_html=True)

def mostrar_perfume_card(marca, nombre, url_imagen=""):
    st.markdown(f"""
    <div class="perfume-card">
        <div class="marca">{marca}</div>
        <div class="nombre">{nombre}</div>
    </div>
    """, unsafe_allow_html=True)

    if url_imagen:
        imagen_path = Path(url_imagen.strip())
        if imagen_path.exists():
            st.image(str(imagen_path), width=200)
        else:
            st.caption(f"📷 No encontrada: {imagen_path}")

def mostrar_precio_box(precio, tamanio):
    st.markdown(f"""
    <div class="precio-box">
        <div class="label">Precio de Venta</div>
        <div class="valor">S/ {precio}</div>
        <div class="tamanio">Decant de {tamanio}</div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_perfume_item(nombre, precio, url_imagen=""):
    if url_imagen:
        imagen_path = Path(url_imagen.strip())
        col1, col2, col3 = st.columns([1, 4, 2])
        with col1:
            if imagen_path.exists():
                st.image(str(imagen_path), width=55)
        with col2:
            st.markdown(f'<span class="pf-nombre">{nombre}</span>', unsafe_allow_html=True)
        with col3:
            if precio:
                st.markdown(f'<span class="pf-precio">S/ {precio}</span>', unsafe_allow_html=True)
            else:
                st.markdown('<span class="sin-precio">Sin precio</span>', unsafe_allow_html=True)
    else:
        if precio:
            st.markdown(f"""
            <div class="perfume-item">
                <span class="pf-nombre">{nombre}</span>
                <span class="pf-precio">S/ {precio}</span>
            </div>
            """, unsafe_allow_html=True)
        else:
            st.markdown(f"""
            <div class="perfume-item">
                <span class="pf-nombre">{nombre}</span>
                <span class="sin-precio">Sin precio</span>
            </div>
            """, unsafe_allow_html=True)

def mostrar_lista_marca(df_filtrado, columna, tamanio):
    st.markdown('<hr class="divider">', unsafe_allow_html=True)
    st.markdown(
        f'<div class="contador">✨ {len(df_filtrado)} perfume(s) encontrados — precios para {tamanio}</div>',
        unsafe_allow_html=True
    )
    for _, row in df_filtrado.iterrows():
        url_imagen = row.get("URL_imagen", "")
        mostrar_perfume_item(row["Nombre"], row[columna], url_imagen)
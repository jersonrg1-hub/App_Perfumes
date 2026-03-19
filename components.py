import streamlit as st

def mostrar_encabezado():
    st.markdown('<div class="titulo-app">🌸 Decants</div>', unsafe_allow_html=True)
    st.markdown('<div class="subtitulo-app">Catálogo de Precios</div>', unsafe_allow_html=True)

def mostrar_perfume_card(marca, nombre):
    st.markdown(f"""
    <div class="perfume-card">
        <div class="marca">{marca}</div>
        <div class="nombre">{nombre}</div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_precio_box(precio, tamanio):
    st.markdown(f"""
    <div class="precio-box">
        <div class="label">Precio de Venta</div>
        <div class="valor">S/ {precio}</div>
        <div class="tamanio">Decant de {tamanio}</div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_perfume_item(nombre, precio):
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
        mostrar_perfume_item(row["Nombre"], row[columna])
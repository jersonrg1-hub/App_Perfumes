import streamlit as st

def mostrar_error_conexion():
    st.markdown("""
    <div style="
        background: #fff5f5;
        border-left: 4px solid #e53e3e;
        border-radius: 12px;
        padding: 1.5rem;
        margin: 1rem 0;
    ">
        <div style="color:#e53e3e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ❌ Error de conexión con Google Sheets
        </div>
        <div style="color:#742a2a; font-size:0.9rem;">
            No se pudo conectar al catálogo. Posibles causas:
            <ul>
                <li>Sin conexión a internet</li>
                <li>Las credenciales de Google vencieron</li>
                <li>El nombre de la hoja cambió</li>
            </ul>
        </div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_error_datos_vacios():
    st.markdown("""
    <div style="
        background: #fffbeb;
        border-left: 4px solid #d69e2e;
        border-radius: 12px;
        padding: 1.5rem;
        margin: 1rem 0;
    ">
        <div style="color:#d69e2e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ⚠️ El catálogo está vacío
        </div>
        <div style="color:#744210; font-size:0.9rem;">
            La hoja de Google Sheets no tiene datos. 
            Verifica que la pestaña <strong>Catalogo</strong> tenga perfumes cargados.
        </div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_error_columna(columna):
    st.markdown(f"""
    <div style="
        background: #fff5f5;
        border-left: 4px solid #e53e3e;
        border-radius: 12px;
        padding: 1.5rem;
        margin: 1rem 0;
    ">
        <div style="color:#e53e3e; font-weight:700; font-size:1rem; margin-bottom:0.5rem;">
            ❌ Columna no encontrada: <code>{columna}</code>
        </div>
        <div style="color:#742a2a; font-size:0.9rem;">
            Verifica que tu Google Sheets tenga exactamente estas columnas:
            <br><br>
            <code>ID_Perfume | Marca | Nombre | Costo_Botella | Ml_Botella | Precio_2ml | Precio_3ml | Precio_5ml | Precio_10ml | URL_imagen</code>
        </div>
    </div>
    """, unsafe_allow_html=True)

def mostrar_sin_precio(nombre, tamanio):
    st.markdown(f"""
    <div style="
        background: #fffbeb;
        border-left: 4px solid #d69e2e;
        border-radius: 12px;
        padding: 1rem 1.5rem;
        margin: 1rem 0;
    ">
        <div style="color:#744210; font-size:0.9rem;">
            ⚠️ <strong>{nombre}</strong> no tiene precio para <strong>{tamanio}</strong>. 
            Agrégalo en tu Google Sheets.
        </div>
    </div>
    """, unsafe_allow_html=True)

def validar_dataframe(df):
    """Valida que el dataframe tenga las columnas necesarias"""
    columnas_requeridas = [
        "Marca", "Nombre", "Precio_2ml",
        "Precio_3ml", "Precio_5ml", "Precio_10ml"
    ]
    columnas_faltantes = [c for c in columnas_requeridas if c not in df.columns]
    return columnas_faltantes
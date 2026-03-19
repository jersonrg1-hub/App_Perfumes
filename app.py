import streamlit as st
import gspread
from google.oauth2.service_account import Credentials
import pandas as pd

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

st.set_page_config(
    page_title="Perfumes 🌸",
    page_icon="🌸",
    layout="centered"
)

# ── Estilos personalizados ─────────────────────────────────
st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;600;700&family=Lato:wght@300;400;600&display=swap');

    /* ── FORZAR FONDO CLARO ── */
    .stApp {
        background-color: #fdf6f0 !important;
    }

    section[data-testid="stSidebar"] {
        background-color: #f5e6d8 !important;
    }

    /* Forzar texto oscuro en selectbox */
    .stSelectbox div[data-baseweb="select"] {
        background-color: #ffffff !important;
        border-color: #e0c9b4 !important;
    }

    .stSelectbox div[data-baseweb="select"] span {
        color: #2c1a0e !important;
    }

    /* Fondo blanco en las pestañas */
    .stTabs [data-baseweb="tab-panel"] {
        background-color: #fdf6f0 !important;
    }

    /* Resto de tus estilos actuales... */

    html, body, [class*="css"] {
        font-family: 'Lato', sans-serif;
    }

    .main {
        background-color: #fdf6f0;
    }

    h1, h2, h3 {
        font-family: 'Playfair Display', serif !important;
        color: #2c1a0e !important;
    }

    /* Título principal */
    .titulo-app {
        font-family: 'Playfair Display', serif;
        font-size: 2.8rem;
        font-weight: 700;
        color: #2c1a0e;
        text-align: center;
        margin-bottom: 0.2rem;
    }

    .subtitulo-app {
        text-align: center;
        color: #a07850;
        font-size: 0.95rem;
        letter-spacing: 0.15em;
        text-transform: uppercase;
        margin-bottom: 2rem;
        font-weight: 300;
    }

    /* Tarjeta de perfume */
    .perfume-card {
        background: linear-gradient(135deg, #fff8f3, #fdeee4);
        border-left: 4px solid #c8956c;
        border-radius: 12px;
        padding: 1.2rem 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 2px 12px rgba(160, 120, 80, 0.12);
    }

    .perfume-card .marca {
        font-size: 0.8rem;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #a07850;
        font-weight: 600;
        margin-bottom: 0.2rem;
    }

    .perfume-card .nombre {
        font-family: 'Playfair Display', serif;
        font-size: 1.4rem;
        color: #2c1a0e;
        font-weight: 600;
    }

    /* Precio grande */
    .precio-box {
        background: linear-gradient(135deg, #2c1a0e, #5c3a1e);
        border-radius: 16px;
        padding: 1.8rem;
        text-align: center;
        margin: 1.5rem 0;
        box-shadow: 0 4px 20px rgba(44, 26, 14, 0.25);
    }

    .precio-box .label {
        color: #e8c9a8;
        font-size: 0.8rem;
        letter-spacing: 0.18em;
        text-transform: uppercase;
        margin-bottom: 0.4rem;
        font-weight: 300;
    }

    .precio-box .valor {
        color: #ffffff;
        font-family: 'Playfair Display', serif;
        font-size: 3rem;
        font-weight: 700;
        line-height: 1;
    }

    .precio-box .tamanio {
        color: #c8956c;
        font-size: 0.85rem;
        margin-top: 0.5rem;
        letter-spacing: 0.1em;
    }

    /* Lista de perfumes por marca */
    .perfume-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0.8rem 1rem;
        border-radius: 8px;
        margin-bottom: 0.5rem;
        background: white;
        border: 1px solid #f0e0d0;
        transition: all 0.2s;
    }

    .perfume-item:hover {
        background: #fff3eb;
        border-color: #c8956c;
    }

    .perfume-item .pf-nombre {
        color: #2c1a0e;
        font-weight: 600;
        font-size: 0.95rem;
    }

    .perfume-item .pf-precio {
        color: #c8956c;
        font-weight: 700;
        font-size: 1rem;
        font-family: 'Playfair Display', serif;
    }

    .sin-precio {
        color: #bbb;
        font-size: 0.85rem;
        font-style: italic;
    }

    /* Divisor elegante */
    .divider {
        border: none;
        border-top: 1px solid #e8d5c4;
        margin: 1.5rem 0;
    }

    /* Pestañas */
    .stTabs [data-baseweb="tab-list"] {
        background-color: #fdf6f0;
        border-radius: 10px;
        padding: 4px;
    }

    .stTabs [data-baseweb="tab"] {
        font-family: 'Lato', sans-serif;
        font-weight: 600;
        color: #a07850;
        letter-spacing: 0.05em;
    }

    .stTabs [aria-selected="true"] {
        background-color: #2c1a0e !important;
        color: white !important;
        border-radius: 8px;
    }

    /* Selectbox */
    .stSelectbox label {
        font-weight: 600;
        color: #2c1a0e !important;
        font-size: 0.85rem;
        letter-spacing: 0.05em;
        text-transform: uppercase;
    }

    /* Contador de resultados */
    .contador {
        font-size: 0.8rem;
        color: #a07850;
        margin-bottom: 1rem;
        font-style: italic;
    }
</style>
""", unsafe_allow_html=True)


@st.cache_data
def cargar_catalogo():
    creds = Credentials.from_service_account_info(
        st.secrets["gcp_service_account"], scopes=SCOPES
    )
    cliente = gspread.authorize(creds)
    hoja = cliente.open("PERFUMES PYTHON").worksheet("Catalogo")
    return pd.DataFrame(hoja.get_all_records())


PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "3 ml":  "Precio_3ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}

# ── Encabezado ─────────────────────────────────────────────
st.markdown('<div class="titulo-app">🌸 Decants</div>', unsafe_allow_html=True)
st.markdown('<div class="subtitulo-app">Catálogo de Precios</div>', unsafe_allow_html=True)

try:
    df = cargar_catalogo()

    tab1, tab2 = st.tabs(["🏷️  Por Marca", "🔍  Por Nombre"])

    # ════════════════════════════════════════════════════
    # PESTAÑA 1: Por marca
    # ════════════════════════════════════════════════════
    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            marcas = sorted(df["Marca"].unique().tolist())
            marca_seleccionada = st.selectbox("Marca", marcas, key="marca")
        with col2:
            tamanio1 = st.selectbox("Tamaño", list(PRECIOS_COLUMNAS.keys()), key="tamanio1")

        columna1 = PRECIOS_COLUMNAS[tamanio1]
        df_filtrado = df[df["Marca"] == marca_seleccionada]

        st.markdown('<hr class="divider">', unsafe_allow_html=True)
        st.markdown(
            f'<div class="contador">✨ {len(df_filtrado)} perfume(s) encontrados — precios para {tamanio1}</div>',
            unsafe_allow_html=True
        )

        for _, row in df_filtrado.iterrows():
            precio = row[columna1]
            if precio:
                st.markdown(f"""
                <div class="perfume-item">
                    <span class="pf-nombre">{row['Nombre']}</span>
                    <span class="pf-precio">S/ {precio}</span>
                </div>
                """, unsafe_allow_html=True)
            else:
                st.markdown(f"""
                <div class="perfume-item">
                    <span class="pf-nombre">{row['Nombre']}</span>
                    <span class="sin-precio">Sin precio</span>
                </div>
                """, unsafe_allow_html=True)

    # ════════════════════════════════════════════════════
    # PESTAÑA 2: Por nombre
    # ════════════════════════════════════════════════════
    with tab2:
        nombres = sorted(df["Nombre"].unique().tolist())
        nombre_seleccionado = st.selectbox("Perfume", nombres, key="nombre")

        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]

        st.markdown(f"""
        <div class="perfume-card">
            <div class="marca">{perfume['Marca']}</div>
            <div class="nombre">{perfume['Nombre']}</div>
        </div>
        """, unsafe_allow_html=True)

        tamanio2 = st.selectbox("Tamaño del decant", list(PRECIOS_COLUMNAS.keys()), key="tamanio2")

        columna2 = PRECIOS_COLUMNAS[tamanio2]
        precio2 = perfume[columna2]

        if precio2:
            st.markdown(f"""
            <div class="precio-box">
                <div class="label">Precio de Venta</div>
                <div class="valor">S/ {precio2}</div>
                <div class="tamanio">Decant de {tamanio2}</div>
            </div>
            """, unsafe_allow_html=True)
        else:
            st.warning("⚠️ Este perfume no tiene precio para ese tamaño.")

except Exception as e:
    st.error(f"❌ Error: {e}")
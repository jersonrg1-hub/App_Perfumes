import streamlit as st
import gspread
from google.oauth2.service_account import Credentials
import pandas as pd

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

st.set_page_config(page_title="Perfumes 🌸", page_icon="🌸", layout="centered")

@st.cache_data
def cargar_catalogo():
    creds = Credentials.from_service_account_info(
        st.secrets["gcp_service_account"], scopes=SCOPES
    )
    cliente = gspread.authorize(creds)
    hoja = cliente.open("PERFUMES PYTHON").worksheet("Catalogo")
    return pd.DataFrame(hoja.get_all_records())

st.title("🌸 Calculadora de Decants")

PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "3 ml":  "Precio_3ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}

try:
    df = cargar_catalogo()

    tab1, tab2 = st.tabs(["🏷️ Buscar por Marca", "🔍 Buscar por Nombre"])

    with tab1:
        marcas = sorted(df["Marca"].unique().tolist())
        marca_seleccionada = st.selectbox("Elige una marca:", marcas, key="marca")

        df_filtrado = df[df["Marca"] == marca_seleccionada]

        tamanio1 = st.selectbox(
            "📏 Tamaño del decant:",
            list(PRECIOS_COLUMNAS.keys()),
            key="tamanio1"
        )
        columna1 = PRECIOS_COLUMNAS[tamanio1]

        st.markdown(f"### Perfumes de {marca_seleccionada}")
        st.markdown(f"Precios para **{tamanio1}:**")
        st.markdown("---")

        for _, row in df_filtrado.iterrows():
            precio = row[columna1]
            if precio:
                st.write(f"✨ **{row['Nombre']}** → S/ {precio}")
            else:
                st.write(f"✨ **{row['Nombre']}** → Sin precio")

    with tab2:
        nombres = sorted(df["Nombre"].unique().tolist())
        nombre_seleccionado = st.selectbox(
            "Busca o elige un perfume:",
            nombres,
            key="nombre"
        )

        perfume = df[df["Nombre"] == nombre_seleccionado].iloc[0]

        st.markdown(f"**Marca:** {perfume['Marca']}")
        st.markdown("---")

        tamanio2 = st.selectbox(
            "📏 Tamaño del decant:",
            list(PRECIOS_COLUMNAS.keys()),
            key="tamanio2"
        )

        columna2 = PRECIOS_COLUMNAS[tamanio2]
        precio2 = perfume[columna2]

        st.markdown("---")
        st.metric("💰 Precio de Venta", f"S/ {precio2}")

except Exception as e:
    st.error(f"❌ Error: {e}")
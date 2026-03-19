import streamlit as st
import gspread
from google.oauth2.service_account import Credentials
import pandas as pd
from calculos import calcular_precio
from variables import TAMANIOS_ML, AJUSTES_PAGO

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

try:
    df = cargar_catalogo()

    # ── Selección de perfume ──────────────────────────────────
    nombres = df["Nombre"].sort_values().unique().tolist()
    seleccion = st.selectbox("🔍 Elige un perfume:", nombres)
    perfume = df[df["Nombre"] == seleccion].iloc[0]

    st.markdown(f"**Marca:** {perfume['Marca']} | "
                f"**Botella:** {perfume['Ml_Botella']} ml | "
                f"**Costo botella:** ${perfume['Costo_Botella']}")

    st.markdown("---")

    # ── Selección de tamaño y pago ────────────────────────────
    col1, col2 = st.columns(2)
    with col1:
        ml = st.selectbox("📏 Tamaño del decant:", TAMANIOS_ML, format_func=lambda x: f"{x} ml")
    with col2:
        medio_pago = st.selectbox("💳 Medio de pago:", list(AJUSTES_PAGO.keys()))

    ajuste = AJUSTES_PAGO[medio_pago]

    # ── Cálculo ───────────────────────────────────────────────
    resultado = calcular_precio(
        costo_botella=perfume["Costo_Botella"],
        ml_botella=perfume["Ml_Botella"],
        ml_seleccionado=ml,
        ajuste_pago=ajuste
    )

    st.markdown("---")

    # ── Precio final destacado ────────────────────────────────
    st.metric("💰 Precio de Venta", f"${resultado['precio_final']}")
    st.metric("📈 Ganancia Neta", f"${resultado['ganancia_neta']}")

    # ── Desglose opcional ─────────────────────────────────────
    with st.expander("🔍 Ver desglose de costos"):
        st.write(f"- Costo por ML: ${resultado['costo_ml']}")
        st.write(f"- ML usados (con {resultado['margen']} merma): {resultado['ml_con_merma']} ml")
        st.write(f"- Costo líquido: ${resultado['subtotal_liquido']}")
        st.write(f"- Costo vial {ml}ml: ${resultado['costo_vial']}")
        st.write(f"- Costo packaging: ${resultado['costo_packaging']}")
        st.write(f"- **Costo total producción: ${resultado['costo_total']}**")
        st.write(f"- Margen aplicado: {resultado['margen']} sobre venta")

except Exception as e:
    st.error(f"❌ Error: {e}")
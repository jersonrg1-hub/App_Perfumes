import streamlit as st
import gspread
from google.oauth2.service_account import Credentials
import pandas as pd
from config import SCOPES, SHEET_NAME, WORKSHEET_NAME

@st.cache_data
def cargar_catalogo():
    creds = Credentials.from_service_account_info(
        st.secrets["gcp_service_account"], scopes=SCOPES
    )
    cliente = gspread.authorize(creds)
    hoja = cliente.open(SHEET_NAME).worksheet(WORKSHEET_NAME)
    return pd.DataFrame(hoja.get_all_records())


def obtener_ultimo_id_compra():
    """Obtiene el último ID_Compra del Sheets y genera el siguiente"""
    try:
        creds = Credentials.from_service_account_info(
            st.secrets["gcp_service_account"], scopes=SCOPES
        )
        cliente = gspread.authorize(creds)
        hoja = cliente.open(SHEET_NAME).worksheet("Ventas_Pendientes")
        datos = hoja.get_all_records()
        if not datos:
            return "V001"
        ids = [row.get("ID_Compra", "") for row in datos if row.get("ID_Compra")]
        if not ids:
            return "V001"
        ultimo = sorted(ids)[-1]
        numero = int(ultimo[1:]) + 1
        return f"V{numero:03d}"
    except:
        return "V001"

def guardar_venta(datos):
    creds = Credentials.from_service_account_info(
        st.secrets["gcp_service_account"], scopes=SCOPES
    )
    cliente = gspread.authorize(creds)
    hoja = cliente.open(SHEET_NAME).worksheet("Ventas_Pendientes")
    hoja.append_row(datos)
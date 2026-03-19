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
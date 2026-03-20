import streamlit as st
import gspread
import pandas as pd
from google.oauth2.service_account import Credentials
from config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS
)

# ── Logger simple ──────────────────────────────────────────
def log_error(contexto, error):
    """Registra errores con contexto para facilitar debugging"""
    print(f"[ERROR] {contexto}: {str(error)}")
    st.session_state.setdefault("error_log", []).append(
        f"[{contexto}] {str(error)}"
    )

# ── Conexión central ───────────────────────────────────────
def get_cliente():
    """Retorna un cliente autenticado de Google Sheets"""
    try:
        creds = Credentials.from_service_account_info(
            st.secrets["gcp_service_account"], scopes=SCOPES
        )
        return gspread.authorize(creds)
    except Exception as e:
        log_error("get_cliente", e)
        raise

def get_hoja(worksheet_name):
    """Retorna una hoja específica del Google Sheet"""
    try:
        cliente = get_cliente()
        return cliente.open(SHEET_NAME).worksheet(worksheet_name)
    except Exception as e:
        log_error(f"get_hoja({worksheet_name})", e)
        raise

# ── Catálogo ───────────────────────────────────────────────
@st.cache_data(ttl=300)
def cargar_catalogo():
    """Carga el catálogo de perfumes con cache de 5 minutos"""
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        datos = hoja.get_all_records()
        return pd.DataFrame(datos)
    except Exception as e:
        log_error("cargar_catalogo", e)
        raise

def limpiar_cache_catalogo():
    """Limpia el cache para forzar recarga"""
    cargar_catalogo.clear()

# ── Ventas ─────────────────────────────────────────────────
def cargar_ventas():
    """Carga todas las ventas pendientes"""
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        datos = hoja.get_all_records()
        if not datos:
            return pd.DataFrame()
        return pd.DataFrame(datos)
    except Exception as e:
        log_error("cargar_ventas", e)
        raise

def guardar_venta(datos):
    """Guarda una fila de venta en Google Sheets"""
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        hoja.append_row(datos)
    except Exception as e:
        log_error("guardar_venta", e)
        raise

def marcar_entregado(fila_num, col_estado):
    """Marca una venta como entregada"""
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        hoja.update_cell(fila_num, col_estado, "Entregado")
    except Exception as e:
        log_error("marcar_entregado", e)
        raise

def obtener_ultimo_id_compra():
    """Genera el siguiente ID de compra correlativo"""
    try:
        df = cargar_ventas()
        if df.empty or "ID_Compra" not in df.columns:
            return "V001"
        ids = [r for r in df["ID_Compra"].tolist() if str(r).startswith("V")]
        if not ids:
            return "V001"
        ultimo = sorted(ids)[-1]
        numero = int(str(ultimo)[1:]) + 1
        return f"V{numero:03d}"
    except Exception as e:
        log_error("obtener_ultimo_id_compra", e)
        return "V001"
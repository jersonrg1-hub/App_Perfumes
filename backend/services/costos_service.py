"""
backend/services/costos_service.py — Cálculo de costos de producción.

Sin dependencias de Streamlit. Reutilizable desde FastAPI para calcular
rentabilidad, márgenes y costos en reportes y analytics.

Fuente de verdad: lo que antes era costos.py ahora vive aquí.
El costos.py raíz es un shim de compatibilidad que re-exporta desde aquí.
"""
import pandas as pd

# ── Constantes de costos (en Soles S/) ───────────────────────────────────────

COSTO_VIAL: dict[int, float] = {
    2:  1.00,
    3:  1.20,
    5:  1.50,
    10: 3.00,
}

# 4% de merma al extraer con jeringa/atomizador.
# Ej: venta de 10ml descuenta 10.4ml del stock.
MERMA_PCT: float = 0.04

# Costo fijo de empaque por item vendido:
# etiqueta (0.16) + jeringa (0.03) + adaptador (0.05) + teflón (0.02)
# + caja envío (0.68) + tarjeta (0.10) + sticker (0.40) + viruta (0.56)
# + espuma (0.05) + caramelo (0.25) + guantes (0.20)
# + cinta embalaje (0.03) + stretch film (0.07)
COSTO_EMPAQUE: float = 2.60


# ── Funciones de cálculo ──────────────────────────────────────────────────────

def costo_por_item(ml: int) -> float:
    """Costo de vial + empaque (sin contar el perfume en sí)."""
    return COSTO_VIAL.get(ml, 0.0) + COSTO_EMPAQUE


def costo_total_item(ml: int, costo_botella: float, ml_botella: float) -> float:
    """Costo total: vial + empaque + perfume proporcional."""
    costo_perf = (costo_botella / ml_botella * ml) if ml_botella > 0 else 0.0
    return costo_por_item(ml) + costo_perf


def construir_costo_ml_dict(df_catalogo: pd.DataFrame) -> dict[str, float]:
    """Retorna {str(ID_Perfume): costo_por_ml} para todos los perfumes."""
    if df_catalogo is None or df_catalogo.empty:
        return {}
    if not {"ID_Perfume", "Costo_Botella", "Ml_Botella"}.issubset(df_catalogo.columns):
        return {}
    df = df_catalogo[["ID_Perfume", "Costo_Botella", "Ml_Botella"]].copy()
    df["Costo_Botella"] = pd.to_numeric(df["Costo_Botella"], errors="coerce").fillna(0.0)
    df["Ml_Botella"] = pd.to_numeric(df["Ml_Botella"], errors="coerce").fillna(0.0)
    valid = df[df["Ml_Botella"] > 0]
    return dict(zip(
        valid["ID_Perfume"].astype(str),
        valid["Costo_Botella"] / valid["Ml_Botella"],
    ))


def calcular_costo_ventas_df(
    df: pd.DataFrame, df_catalogo: pd.DataFrame
) -> float:
    """Calcula el costo total de un DataFrame de ventas (vectorizado)."""
    if df.empty:
        return 0.0
    costo_ml_dict = construir_costo_ml_dict(df_catalogo)
    ml = pd.to_numeric(df["Ml_Vendido"], errors="coerce").fillna(0).astype(int)
    valid = (ml > 0).astype(float)
    costo_perf = df["ID_Perfume"].astype(str).map(costo_ml_dict).fillna(0.0) * ml
    costo_vial = ml.map(COSTO_VIAL).fillna(0.0)
    return float((costo_perf + costo_vial + valid * COSTO_EMPAQUE).sum())

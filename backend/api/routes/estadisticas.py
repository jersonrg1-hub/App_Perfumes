"""
backend/api/routes/estadisticas.py — Métricas pre-agregadas para el dashboard Flutter.
Un solo endpoint reemplaza el fetch de 500 ventas crudas desde el cliente.
TTL cache 5 min en memoria — stats no necesitan ser real-time.
"""
import threading
import time
from datetime import date, timedelta
from typing import Optional, List

import pandas as pd
from fastapi import APIRouter, Depends, Query

from backend.api.dependencies import get_repo, get_ventas_cached, verify_api_key
from backend.repositories.sheets_repository import SheetsRepository
from backend.core.config import hoy_peru  # retorna date directamente

router = APIRouter(dependencies=[Depends(verify_api_key)])

_cache_stats: Optional[dict] = None
_cache_ts: float = 0.0
_STATS_TTL = 300.0  # seconds
_stats_lock = threading.Lock()


def _invalidar_cache_stats() -> None:
    global _cache_stats, _cache_ts
    with _stats_lock:
        _cache_stats = None
        _cache_ts = 0.0


def _compute_resumen(df: pd.DataFrame, pendientes_count: int) -> dict:
    if df.empty:
        return _empty_resumen(pendientes_count)

    df = df.copy()
    df["_fecha"] = pd.to_datetime(df["Fecha"], errors="coerce").dt.date

    entregadas = df[df["Estado"].isin(["Entregado", "Pendiente"])]

    hoy: date = hoy_peru()  # retorna date, sin .date()

    hoy_df = entregadas[entregadas["_fecha"] == hoy]
    mes_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and d.year == hoy.year and d.month == hoy.month
    )]
    prev = (hoy.replace(day=1) - timedelta(days=1))
    mes_prev_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and d.year == prev.year and d.month == prev.month
    )]

    # Semanal (lunes a domingo de la semana actual)
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    semanal = []
    for i in range(7):
        dia = inicio_semana + timedelta(days=i)
        dia_df = entregadas[entregadas["_fecha"] == dia]
        semanal.append({
            "fecha": dia.isoformat(),
            "ordenes": int(dia_df["ID_Compra"].nunique()) if "ID_Compra" in dia_df.columns else 0,
            "total": float(dia_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in dia_df.columns else 0.0,
            "ml": int(dia_df["Ml_Vendido"].sum()) if "Ml_Vendido" in dia_df.columns else 0,
        })

    # Semana anterior para variación
    inicio_ant = inicio_semana - timedelta(days=7)
    fin_ant = inicio_semana - timedelta(days=1)
    sem_ant_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and inicio_ant <= d <= fin_ant
    )]

    # Tamaños del mes (no de todo el tiempo)
    tamanios = []
    if "Ml_Vendido" in mes_df.columns and not mes_df.empty:
        tam_group = (
            mes_df.groupby("Ml_Vendido")
            .agg(
                cantidad=("Precio_Cobrado", "count"),
                total=("Precio_Cobrado", "sum"),
            )
            .reset_index()
        )
        tamanios = [
            {"ml": int(r["Ml_Vendido"]), "cantidad": int(r["cantidad"]), "total": float(r["total"])}
            for _, r in tam_group.iterrows()
        ]

    # Top perfumes del mes
    top_perfumes = []
    if "ID_Perfume" in mes_df.columns and not mes_df.empty:
        top_group = (
            mes_df.groupby("ID_Perfume")
            .agg(
                total_ml=("Ml_Vendido", "sum"),
                total_soles=("Precio_Cobrado", "sum"),
                cantidad=("Precio_Cobrado", "count"),
            )
            .sort_values("total_ml", ascending=False)
            .head(10)
            .reset_index()
        )
        top_perfumes = [
            {
                "id_perfume": str(r["ID_Perfume"]),
                "total_ml": int(r["total_ml"]),
                "total_soles": float(r["total_soles"]),
                "cantidad": int(r["cantidad"]),
            }
            for _, r in top_group.iterrows()
        ]

    # Clientes top del mes
    clientes_top = []
    if "Celular" in mes_df.columns and not mes_df.empty:
        cli_group = (
            mes_df.groupby("Celular")
            .agg(
                ordenes=("ID_Compra", "nunique"),
                total=("Precio_Cobrado", "sum"),
            )
            .sort_values("total", ascending=False)
            .head(10)
            .reset_index()
        )
        clientes_top = [
            {
                "celular": str(r["Celular"]),
                "ordenes": int(r["ordenes"]),
                "total": float(r["total"]),
            }
            for _, r in cli_group.iterrows()
        ]

    sem_total_ant = float(sem_ant_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in sem_ant_df.columns else 0.0
    sem_total_act = sum(d["total"] for d in semanal)

    return {
        "hoy": {
            "ventas": int(hoy_df["ID_Compra"].nunique()) if "ID_Compra" in hoy_df.columns else 0,
            "total": float(hoy_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in hoy_df.columns else 0.0,
            "ml": int(hoy_df["Ml_Vendido"].sum()) if "Ml_Vendido" in hoy_df.columns else 0,
        },
        "mes": {
            "ventas": int(mes_df["ID_Compra"].nunique()) if "ID_Compra" in mes_df.columns else 0,
            "total": float(mes_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in mes_df.columns else 0.0,
            "ml": int(mes_df["Ml_Vendido"].sum()) if "Ml_Vendido" in mes_df.columns else 0,
        },
        "mes_pasado": {
            "ventas": int(mes_prev_df["ID_Compra"].nunique()) if "ID_Compra" in mes_prev_df.columns else 0,
            "total": float(mes_prev_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in mes_prev_df.columns else 0.0,
        },
        "pendientes": pendientes_count,
        "semanal": semanal,
        "semana_anterior_total": sem_total_ant,
        "variacion_semana_pct": (
            (sem_total_act - sem_total_ant) / sem_total_ant * 100
            if sem_total_ant > 0 else 0.0
        ),
        "tamanios": tamanios,
        "top_perfumes": top_perfumes,
        "clientes_top": clientes_top,
    }


def _empty_resumen(pendientes_count: int) -> dict:
    return {
        "hoy": {"ventas": 0, "total": 0.0, "ml": 0},
        "mes": {"ventas": 0, "total": 0.0, "ml": 0},
        "mes_pasado": {"ventas": 0, "total": 0.0},
        "pendientes": pendientes_count,
        "semanal": [],
        "semana_anterior_total": 0.0,
        "variacion_semana_pct": 0.0,
        "tamanios": [],
        "top_perfumes": [],
        "clientes_top": [],
    }


@router.get("/resumen", summary="Métricas pre-agregadas para dashboard Flutter")
def get_resumen(repo: SheetsRepository = Depends(get_repo)):
    """
    Reemplaza el fetch de 500 ventas crudas desde Flutter.
    Devuelve métricas pre-computadas: hoy, mes, semana, tamaños, top perfumes.
    Cache interno 5 min — invalida automáticamente al registrar una venta.
    """
    global _cache_stats, _cache_ts
    now = time.monotonic()
    with _stats_lock:
        if _cache_stats is not None and (now - _cache_ts) < _STATS_TTL:
            return _cache_stats

    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    # Pendientes count — unique orders, not items
    pendientes_count = 0
    if not df.empty and "Estado" in df.columns:
        pend_df = df[df["Estado"] == "Pendiente"]
        if "ID_Compra" in pend_df.columns:
            pendientes_count = int(pend_df["ID_Compra"].nunique())
        else:
            pendientes_count = len(pend_df)

    result = _compute_resumen(df, pendientes_count)
    with _stats_lock:
        _cache_stats = result
        _cache_ts = time.monotonic()
    return result


# ── Cache separado para clientes ─────────────────────────────────────────────

_cache_clientes: Optional[List[dict]] = None
_cache_clientes_ts: float = 0.0
_clientes_lock = threading.Lock()


def _invalidar_cache_clientes() -> None:
    global _cache_clientes, _cache_clientes_ts
    with _clientes_lock:
        _cache_clientes = None
        _cache_clientes_ts = 0.0


def _compute_clientes(df: pd.DataFrame) -> List[dict]:
    if df.empty:
        return []

    entregadas = df[df["Estado"] == "Entregado"].copy()
    todas      = df.copy()

    clientes = []
    for celular, group in todas.groupby("Celular"):
        if not celular:
            continue
        ent = entregadas[entregadas["Celular"] == celular]
        fechas = group["Fecha"].dropna().sort_values().tolist()
        direccion = ""
        non_empty = group[group["Direccion"].notna() & (group["Direccion"].str.strip() != "")]
        if not non_empty.empty:
            direccion = str(non_empty.iloc[-1]["Direccion"])

        clientes.append({
            "celular":        str(celular),
            "nombre":         str(group.iloc[0]["Comprador"]) if "Comprador" in group.columns else str(celular),
            "direccion":      direccion,
            "total_compras":  int(ent["ID_Compra"].nunique()) if "ID_Compra" in ent.columns else 0,
            "total_items":    len(ent),
            "total_gastado":  float(ent["Precio_Cobrado"].sum()) if "Precio_Cobrado" in ent.columns else 0.0,
            "primera_compra": str(fechas[0]) if fechas else None,
            "ultima_compra":  str(fechas[-1]) if fechas else None,
        })

    clientes.sort(key=lambda c: c["total_gastado"], reverse=True)
    return clientes


@router.get("/clientes", summary="Clientes agrupados con métricas — paginado")
def get_clientes(
    limit:  int           = Query(30, ge=1, le=100),
    offset: int           = Query(0, ge=0),
    q:      Optional[str] = Query(None, description="Buscar por nombre o celular"),
    repo:   SheetsRepository = Depends(get_repo),
):
    """
    Lista de clientes pre-agregada con paginación y búsqueda opcional.
    Sin historial de ventas por item — ese detalle lo maneja Flutter con ventasParaStatsProvider.
    Cache 5 min compartido con /resumen — se invalida al registrar venta.
    """
    global _cache_clientes, _cache_clientes_ts
    now = time.monotonic()
    with _clientes_lock:
        cached = _cache_clientes
        cached_ts = _cache_clientes_ts
    if cached is None or (now - cached_ts) >= _STATS_TTL:
        try:
            df = get_ventas_cached(repo)
        except Exception as e:
            from fastapi import HTTPException
            raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")
        computed = _compute_clientes(df)
        with _clientes_lock:
            _cache_clientes    = computed
            _cache_clientes_ts = time.monotonic()
        cached = computed

    resultado = cached
    if q:
        q_lower   = q.lower()
        resultado = [
            c for c in resultado
            if q_lower in c["nombre"].lower() or q_lower in c["celular"]
        ]

    total = len(resultado)
    return {
        "items":    resultado[offset: offset + limit],
        "total":    total,
        "limit":    limit,
        "offset":   offset,
        "has_more": (offset + limit) < total,
    }

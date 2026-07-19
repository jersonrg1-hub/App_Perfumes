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
from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import get_repo, get_ventas_cached, verify_api_key, paginate
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
    _invalidar_cache_historico()


def _compute_resumen(df: pd.DataFrame, pendientes_count: int) -> dict:
    if df.empty:
        return _empty_resumen(pendientes_count)

    df = df.copy()
    df["_fecha"] = pd.to_datetime(df["Fecha"], errors="coerce").dt.date

    entregadas = df[df["Estado"].isin(["Entregado", "Pendiente"])]

    hoy: date = hoy_peru()  # retorna date, sin .date()

    # Convertir _fecha a Timestamps una vez para comparaciones vectorizadas
    _fechas_ts = pd.to_datetime(entregadas["_fecha"], errors="coerce")
    _valid = _fechas_ts.notna()
    _fechas_date = pd.Series(_fechas_ts.dt.date, index=_fechas_ts.index)

    hoy_df = entregadas[_valid & (_fechas_date == hoy)]
    prev = hoy.replace(day=1) - timedelta(days=1)
    mes_df = entregadas[
        _valid & (_fechas_ts.dt.year == hoy.year) & (_fechas_ts.dt.month == hoy.month)
    ]
    mes_prev_df = entregadas[
        _valid & (_fechas_ts.dt.year == prev.year) & (_fechas_ts.dt.month == prev.month)
    ]

    # Semanal (lunes a domingo de la semana actual)
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    semanal = []
    for i in range(7):
        dia = inicio_semana + timedelta(days=i)
        dia_df = entregadas[_valid & (_fechas_date == dia)]
        semanal.append({
            "fecha": dia.isoformat(),
            "ordenes": int(dia_df["ID_Compra"].nunique()) if "ID_Compra" in dia_df.columns else 0,
            "total": float(dia_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in dia_df.columns else 0.0,
            "ml": int(dia_df["Ml_Vendido"].sum()) if "Ml_Vendido" in dia_df.columns else 0,
        })

    # Semana anterior para variación
    inicio_ant = inicio_semana - timedelta(days=7)
    fin_ant = inicio_semana - timedelta(days=1)
    sem_ant_df = entregadas[
        _valid & (_fechas_date >= inicio_ant) & (_fechas_date <= fin_ant)
    ]

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
            {"ml": int(r.Ml_Vendido), "cantidad": int(r.cantidad), "total": float(r.total)}
            for r in tam_group.itertuples(index=False)
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
                "id_perfume": str(r.ID_Perfume),
                "total_ml": int(r.total_ml),
                "total_soles": float(r.total_soles),
                "cantidad": int(r.cantidad),
            }
            for r in top_group.itertuples(index=False)
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
            {"celular": str(r.Celular), "ordenes": int(r.ordenes), "total": float(r.total)}
            for r in cli_group.itertuples(index=False)
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

    entregadas = df[df["Estado"] == "Entregado"]
    # Pre-agrupar entregadas por celular una sola vez — evita O(n_clientes × n_ventas)
    ent_por_cel = {cel: g for cel, g in entregadas.groupby("Celular")} if not entregadas.empty else {}

    clientes = []
    for celular, group in df.groupby("Celular"):
        if not celular:
            continue

        ent = ent_por_cel.get(celular, pd.DataFrame())
        fechas = group["Fecha"].dropna().sort_values().tolist()
        ultimo = group.iloc[-1]

        direccion = ""
        non_empty_dir = group[group["Direccion"].notna() & (group["Direccion"].str.strip() != "")]
        if not non_empty_dir.empty:
            direccion = str(non_empty_dir.iloc[-1]["Direccion"])

        distrito = ""
        if "Distrito" in group.columns:
            non_empty_dis = group[group["Distrito"].notna() & (group["Distrito"].astype(str).str.strip() != "")]
            if not non_empty_dis.empty:
                distrito = str(non_empty_dis.iloc[-1]["Distrito"])

        clientes.append({
            "celular":        str(celular),
            "nombre":         str(ultimo["Comprador"]) if "Comprador" in group.columns else str(celular),
            "direccion":      direccion,
            "distrito":       distrito,
            "total_compras":  int(ent["ID_Compra"].nunique()) if not ent.empty and "ID_Compra" in ent.columns else 0,
            "total_items":    len(ent),
            "total_gastado":  float(ent["Precio_Cobrado"].sum()) if not ent.empty and "Precio_Cobrado" in ent.columns else 0.0,
            "primera_compra": str(fechas[0]) if fechas else None,
            "ultima_compra":  str(fechas[-1]) if fechas else None,
        })

    clientes.sort(key=lambda c: c["total_gastado"], reverse=True)
    return clientes


@router.get("/clientes", summary="Clientes agrupados con métricas — paginado")
def get_clientes(
    limit:  int           = Query(30, ge=1, le=500),
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
        if _cache_clientes is None or (now - _cache_clientes_ts) >= _STATS_TTL:
            try:
                df = get_ventas_cached(repo)
            except Exception as e:
                raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")
            _cache_clientes    = _compute_clientes(df)
            _cache_clientes_ts = time.monotonic()
        cached = _cache_clientes

    resultado = cached
    if q:
        q_lower   = q.lower()
        resultado = [
            c for c in resultado
            if q_lower in c["nombre"].lower() or q_lower in c["celular"]
        ]

    return paginate(resultado, limit, offset)


# ── Cache separado para histórico ────────────────────────────────────────────
# Reemplaza ventasParaStatsProvider (getVentas(limit:500)) para historialGlobalProvider,
# mesesDisponiblesProvider y mesStatsMapProvider en Flutter. Agrega sobre el DataFrame
# completo de ventas — escala con 10k-100k registros, a diferencia del tope de 500.

_cache_historico:    Optional[dict] = None
_cache_historico_ts: float = 0.0
_historico_lock = threading.Lock()

_MESES_CORTOS = ["", "Ene", "Feb", "Mar", "Abr", "May", "Jun",
                 "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

_DISTRITO_ACENTOS = str.maketrans(
    "áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛñÑ",
    "aaaaaeeeeiiiiooooouuuuAAAAAEEEEIIIIOOOOOUUUUnn",
)


def _invalidar_cache_historico() -> None:
    global _cache_historico, _cache_historico_ts
    with _historico_lock:
        _cache_historico = None
        _cache_historico_ts = 0.0


def _normalizar_distrito(s: str) -> str:
    return s.strip().lower().translate(_DISTRITO_ACENTOS)


def _titlecase_distrito(s: str) -> str:
    return " ".join(w[:1].upper() + w[1:] for w in s.split(" ") if w)


def _tamanios_por_ml(df: pd.DataFrame) -> List[dict]:
    if df.empty or "Ml_Vendido" not in df.columns:
        return []
    g = (
        df.groupby("Ml_Vendido")
        .agg(cantidad=("Precio_Cobrado", "count"), total=("Precio_Cobrado", "sum"))
        .reset_index()
    )
    return [
        {"ml": int(r.Ml_Vendido), "cantidad": int(r.cantidad), "total": float(r.total)}
        for r in g.itertuples(index=False)
    ]


def _top_perfumes(df: pd.DataFrame, n: Optional[int] = None) -> List[dict]:
    if df.empty or "ID_Perfume" not in df.columns:
        return []
    g = (
        df.groupby("ID_Perfume")
        .agg(total_ml=("Ml_Vendido", "sum"), total_soles=("Precio_Cobrado", "sum"))
        .sort_values("total_ml", ascending=False)
    )
    if n is not None:
        g = g.head(n)
    g = g.reset_index()
    return [
        {"id_perfume": str(r.ID_Perfume), "total_ml": int(r.total_ml), "total_soles": float(r.total_soles)}
        for r in g.itertuples(index=False)
    ]


def _empty_historico() -> dict:
    return {
        "total_ventas":      0,
        "total_ingresos":    0.0,
        "total_ml":          0,
        "clientes_unicos":   0,
        "primera_venta":     None,
        "por_mes":           [],
        "mejor_mes_clave":   None,
        "promedio_mensual":  0.0,
        "top_perfumes":      [],
        "ranking_distritos": [],
        "tamanios_total":    [],
    }


def _compute_historico(df: pd.DataFrame) -> dict:
    if df.empty:
        return _empty_historico()

    entregadas = df[df["Estado"] != "Anulado"].copy()
    if entregadas.empty:
        return _empty_historico()

    entregadas["_fecha"] = pd.to_datetime(entregadas["Fecha"], errors="coerce")
    entregadas["_mes"]   = entregadas["_fecha"].dt.strftime("%Y-%m")

    fechas_validas = entregadas["_fecha"].dropna()

    por_mes = []
    for clave, grupo in entregadas.dropna(subset=["_mes"]).groupby("_mes"):
        year, month = clave.split("-")
        por_mes.append({
            "clave":        clave,
            "label":        f"{_MESES_CORTOS[int(month)]} {year}",
            "num_ordenes":  int(grupo["ID_Compra"].nunique()),
            "total":        float(grupo["Precio_Cobrado"].sum()),
            "total_ml":     int(grupo["Ml_Vendido"].sum()),
            "top_perfumes": _top_perfumes(grupo, n=10),
            "tamanios":     _tamanios_por_ml(grupo),
        })
    por_mes.sort(key=lambda m: m["clave"])

    ranking_distritos = []
    if "Distrito" in entregadas.columns:
        dist_rows = entregadas[
            entregadas["Distrito"].notna() & (entregadas["Distrito"].astype(str).str.strip() != "")
        ].copy()
        if not dist_rows.empty:
            dist_rows["distrito_norm"] = dist_rows["Distrito"].astype(str).map(_normalizar_distrito)
            g = (
                dist_rows.groupby("distrito_norm")
                .agg(pedidos=("ID_Compra", "nunique"), total_soles=("Precio_Cobrado", "sum"))
                .reset_index()
            )
            ranking_distritos = sorted(
                (
                    {
                        "nombre":      _titlecase_distrito(r.distrito_norm),
                        "pedidos":     int(r.pedidos),
                        "total_soles": float(r.total_soles),
                    }
                    for r in g.itertuples(index=False)
                ),
                key=lambda d: (-d["pedidos"], -d["total_soles"]),
            )

    return {
        "total_ventas":      int(entregadas["ID_Compra"].nunique()),
        "total_ingresos":    float(entregadas["Precio_Cobrado"].sum()),
        "total_ml":          int(entregadas["Ml_Vendido"].sum()),
        "clientes_unicos":   int(entregadas["Celular"].nunique()),
        "primera_venta":     fechas_validas.min().date().isoformat() if not fechas_validas.empty else None,
        "por_mes":           por_mes,
        "mejor_mes_clave":   max(por_mes, key=lambda m: m["total"])["clave"] if por_mes else None,
        "promedio_mensual":  (float(entregadas["Precio_Cobrado"].sum()) / len(por_mes)) if por_mes else 0.0,
        "top_perfumes":      _top_perfumes(entregadas),
        "ranking_distritos": ranking_distritos,
        "tamanios_total":    _tamanios_por_ml(entregadas),
    }


@router.get("/historico", summary="Históricos completos pre-agregados (sin tope de 500 ventas)")
def get_historico(repo: SheetsRepository = Depends(get_repo)):
    """
    Reemplaza ventasParaStatsProvider para historialGlobalProvider, mesesDisponiblesProvider
    y mesStatsMapProvider. Agrega sobre TODO el DataFrame de ventas (sin limit:500) —
    escala con 10k-100k registros. Cache interno 5 min, invalida junto con /resumen
    al registrar/actualizar una venta.
    """
    global _cache_historico, _cache_historico_ts
    now = time.monotonic()
    with _historico_lock:
        if _cache_historico is not None and (now - _cache_historico_ts) < _STATS_TTL:
            return _cache_historico

    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    result = _compute_historico(df)
    with _historico_lock:
        _cache_historico    = result
        _cache_historico_ts = time.monotonic()
    return result

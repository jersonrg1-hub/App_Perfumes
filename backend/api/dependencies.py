"""
backend/api/dependencies.py — Repositorio, cache y autenticación para FastAPI.

Responsabilidades:
  1. SheetsRepository singleton — una conexión a Google Sheets por proceso
  2. TTLCache — reduce llamadas a Sheets y protege contra rate limits (HTTP 429)
       catálogo: TTL 30 min   (cambia poco; es el más costoso de cargar)
       ventas:   TTL  2 min   (necesita estar fresco para despacho)
  3. Credenciales con fallback — Render usa env var; local usa credenciales.json
  4. verify_api_key — autenticación X-API-Key para endpoints sensibles
  5. df_to_json_list — serialización segura de DataFrames pandas a JSON

Diseño deliberado:
  - Cache vive AQUÍ, no en los routes (separación de responsabilidades)
  - Lock threading por si uvicorn usa thread pool en endpoints síncronos
  - invalidar_cache_* se llaman desde routes tras escrituras exitosas
"""
import json
import logging
import math
import os
import threading
from datetime import datetime
from functools import lru_cache
from pathlib import Path
from typing import Optional

import pandas as pd
from cachetools import TTLCache
from fastapi import HTTPException, Security
from fastapi.security import APIKeyHeader

from backend.repositories.sheets_repository import SheetsRepository

logger = logging.getLogger("perfuteca.api")


# ── Repositorio singleton ─────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def _crear_repositorio() -> SheetsRepository:
    """
    Una sola instancia de SheetsRepository por proceso uvicorn.
    lru_cache garantiza que la conexión gspread se reutiliza entre requests.

    Orden de búsqueda de credenciales:
      1. Variable de entorno GCP_SERVICE_ACCOUNT (Render, producción)
      2. Archivo credenciales.json en raíz del proyecto (desarrollo local)
    """
    creds_json = os.environ.get("GCP_SERVICE_ACCOUNT")

    if not creds_json:
        # Fallback para desarrollo local — nunca ejecutar en producción sin env var
        local = Path(__file__).resolve().parent.parent.parent / "credenciales.json"
        if local.exists():
            logger.warning(
                "GCP_SERVICE_ACCOUNT no configurado — "
                "usando credenciales.json local (solo desarrollo)"
            )
            creds_json = local.read_text(encoding="utf-8")
        else:
            raise RuntimeError(
                "Credenciales GCP no encontradas. "
                "Configura GCP_SERVICE_ACCOUNT en variables de entorno "
                "o coloca credenciales.json en la raíz del proyecto."
            )

    return SheetsRepository(json.loads(creds_json))


def get_repo() -> SheetsRepository:
    """Dependencia FastAPI: inyecta el repositorio singleton."""
    return _crear_repositorio()


# ── Cache TTL ─────────────────────────────────────────────────────────────────
# maxsize=1: solo guardamos el DataFrame completo (una entrada por cache).
# El lock protege de condiciones de carrera cuando uvicorn corre en thread pool.

_cache_catalogo: TTLCache = TTLCache(maxsize=1, ttl=1800)  # 30 min
_cache_ventas:   TTLCache = TTLCache(maxsize=1, ttl=120)   # 2 min
_lock = threading.Lock()
_K = "df"


def get_catalogo_cached(repo: SheetsRepository) -> pd.DataFrame:
    """
    Catálogo desde cache (TTL 30 min) o desde Google Sheets si expiró.
    Reduce hasta 60× las llamadas a Sheets durante una sesión normal.
    """
    with _lock:
        try:
            return _cache_catalogo[_K]
        except KeyError:
            df = repo.fetch_catalog()
            _cache_catalogo[_K] = df
            logger.debug("Cache catálogo recargado desde Sheets")
            return df


def get_ventas_cached(repo: SheetsRepository) -> pd.DataFrame:
    """Ventas desde cache (TTL 2 min) o desde Google Sheets si expiró."""
    with _lock:
        try:
            return _cache_ventas[_K]
        except KeyError:
            df = repo.fetch_sales()
            _cache_ventas[_K] = df
            logger.debug("Cache ventas recargado desde Sheets")
            return df


def invalidar_cache_catalogo() -> None:
    """Llamar tras cualquier operación que modifique stock del catálogo."""
    with _lock:
        _cache_catalogo.clear()
    logger.debug("Cache catálogo invalidado")


def invalidar_cache_ventas() -> None:
    """Llamar tras registrar o actualizar una venta."""
    with _lock:
        _cache_ventas.clear()
    logger.debug("Cache ventas invalidado")


# ── Autenticación X-API-Key ───────────────────────────────────────────────────

_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str = Security(_api_key_header)) -> None:
    """
    Protege endpoints sensibles con X-API-Key.

    Comportamiento según configuración:
      API_KEY configurada → exige el header exacto; 401 si falta o es incorrecta
      API_KEY no configurada → permite el request con warning en log
                               (útil durante desarrollo, NO recomendado en producción)

    Uso en un endpoint:
      @router.post("/", dependencies=[Depends(verify_api_key)])
      def mi_endpoint(): ...
    """
    expected = os.environ.get("API_KEY", "")
    if not expected:
        logger.warning(
            "API_KEY no configurada — endpoint accesible sin autenticación. "
            "Configura API_KEY en variables de entorno para producción."
        )
        return
    if not api_key or api_key != expected:
        raise HTTPException(
            status_code=401,
            detail="X-API-Key inválida o ausente",
            headers={"WWW-Authenticate": "ApiKey"},
        )


# ── Serialización de DataFrames ───────────────────────────────────────────────

def _serializar_valor(v):
    """Convierte un valor pandas a tipo JSON-serializable nativo."""
    if v is None or v is pd.NaT:
        return None
    if isinstance(v, pd.Timestamp):
        return v.isoformat()
    if isinstance(v, datetime):
        return v.isoformat()
    if isinstance(v, float) and math.isnan(v):
        return None
    if isinstance(v, frozenset):
        return sorted(v)
    return v


def df_to_json_list(
    df: pd.DataFrame,
    cols: Optional[list] = None,
) -> list[dict]:
    """
    DataFrame → lista de dicts JSON-serializable.
    cols: columnas a incluir (None = todas). Las que no existan se ignoran.
    """
    if cols is not None:
        df = df[[c for c in cols if c in df.columns]]
    records = df.to_dict("records")
    return [{k: _serializar_valor(v) for k, v in row.items()} for row in records]

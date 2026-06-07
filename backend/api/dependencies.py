"""
backend/api/dependencies.py — Repositorio, cache, auth y serialización para FastAPI.

Responsabilidades:
  1. SheetsRepository singleton  — una conexión a Google Sheets por proceso
  2. TTLCache                    — catálogo 30 min / ventas 2 min
  3. Credenciales con fallback   — GCP_SERVICE_ACCOUNT env var > credenciales.json local
  4. verify_api_key              — autenticación X-API-Key para endpoints sensibles
  5. df_to_json_list             — serialización segura DataFrame → JSON con snake_case

snake_case en respuestas:
  Las columnas de Google Sheets usan PascalCase (ID_Perfume, Precio_2ml...).
  Para Flutter/Dart, las respuestas usan snake_case (id_perfume, precio_2ml...).
  .lower() es suficiente: "ID_Perfume" → "id_perfume", "Precio_2ml" → "precio_2ml".
  Activar con snake=True en df_to_json_list().
"""
import hmac
import json
import logging
import math
import os
import re
import threading
import unicodedata
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

    Orden de búsqueda de credenciales:
      1. GCP_SERVICE_ACCOUNT (env var) — Render / producción
      2. credenciales.json en raíz del proyecto — solo desarrollo local
    """
    creds_json = os.environ.get("GCP_SERVICE_ACCOUNT")

    if not creds_json:
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

_cache_catalogo:     TTLCache = TTLCache(maxsize=1, ttl=1800)  # 30 min
_cache_ventas:       TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_cache_cotizaciones: TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_lock = threading.Lock()
_K = "df"


def get_catalogo_cached(repo: SheetsRepository) -> pd.DataFrame:
    """Catálogo desde cache (TTL 30 min) o recarga desde Sheets si expiró."""
    with _lock:
        try:
            return _cache_catalogo[_K]
        except KeyError:
            df = repo.fetch_catalog()
            _cache_catalogo[_K] = df
            logger.debug("Cache catalogo recargado desde Sheets")
            return df


def get_ventas_cached(repo: SheetsRepository) -> pd.DataFrame:
    """Ventas desde cache (TTL 5 min) o recarga desde Sheets si expiró."""
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
    logger.debug("Cache catalogo invalidado")


def invalidar_cache_ventas() -> None:
    """Llamar tras registrar o actualizar una venta."""
    with _lock:
        _cache_ventas.clear()
    logger.debug("Cache ventas invalidado")


def get_cotizaciones_cached(repo: SheetsRepository) -> pd.DataFrame:
    """Cotizaciones desde cache (TTL 5 min) o recarga desde Sheets si expiró."""
    with _lock:
        try:
            return _cache_cotizaciones[_K]
        except KeyError:
            df = repo.fetch_quotes()
            _cache_cotizaciones[_K] = df
            logger.debug("Cache cotizaciones recargado desde Sheets")
            return df


def invalidar_cache_cotizaciones() -> None:
    """Llamar tras guardar o actualizar una cotización."""
    with _lock:
        _cache_cotizaciones.clear()
    logger.debug("Cache cotizaciones invalidado")


# ── Índice de imágenes ────────────────────────────────────────────────────────
# Se construye una vez al arrancar leyendo el sistema de archivos.
# Mapea: "chanel/coco_noir" → "/imagenes/chanel/coco_noir.jpg"

_image_index: dict[str, str] = {}


def construir_image_index(base_dir: Path) -> None:
    """
    Recorre imagenes/ y construye un índice normalizado.
    Clave: "{marca_normalizada}/{nombre_normalizado}"
    Valor: URL relativa servida por FastAPI StaticFiles

    Normalización: minúsculas, espacios → _, caracteres especiales eliminados.
    """
    if not base_dir.exists():
        logger.warning("Directorio imagenes/ no encontrado — image_url siempre null")
        return

    extensiones = {".jpg", ".jpeg", ".png", ".webp"}
    for brand_dir in sorted(base_dir.iterdir()):
        if not brand_dir.is_dir():
            continue
        for img_file in sorted(brand_dir.iterdir()):
            if img_file.suffix.lower() in extensiones:
                clave = f"{brand_dir.name}/{img_file.stem}"
                _image_index[clave] = f"/imagenes/{brand_dir.name}/{img_file.name}"

    logger.info("Image index construido: %d imagenes indexadas", len(_image_index))


def _normalizar(texto: str) -> str:
    """Normaliza nombre/marca para buscar en el índice de imágenes."""
    # Quitar tildes: café→cafe, Tendré→Tendre, N°5→N5
    s = unicodedata.normalize("NFD", texto)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = s.replace("&", " ")          # "Dolce & Gabanna" → "dolce  gabanna"
    s = re.sub(r"[.,'°]", "", s)     # quitar puntuación y símbolo °
    s = s.replace("-", " ")
    s = re.sub(r"\s+", "_", s.strip())  # espacios múltiples → un solo _
    s = s.strip("_")
    return s


def get_image_url(marca: str, nombre: str) -> Optional[str]:
    """
    Retorna la URL de la imagen del perfume si existe en imagenes/.
    Usa matching progresivo para cubrir nombres con sufijos o palabras extra.

    Pasos:
      1. Coincidencia exacta normalizada
      2. Prefijo: el nombre empieza con el stem o viceversa (ej: "gabrielle_edp" ~ "gabrielle")
      3. Todas las palabras del stem están en las palabras del nombre
         (ej: "coral_fantasy" ~ "donna_born_in_roma_coral_fantasy")
      4. El stem es sufijo del nombre (ej: "imperatrice" ~ "linperatrice")
    """
    if not _image_index:
        return None

    marca_norm = _normalizar(marca)
    nombre_norm = _normalizar(nombre)

    # Paso 1: coincidencia exacta
    clave = f"{marca_norm}/{nombre_norm}"
    if clave in _image_index:
        return _image_index[clave]

    brand_prefix = f"{marca_norm}/"
    brand_keys = sorted(k for k in _image_index if k.startswith(brand_prefix))
    if not brand_keys:
        return None

    # Paso 2: prefijo
    for k in brand_keys:
        stem = k[len(brand_prefix):]
        if nombre_norm.startswith(stem) or stem.startswith(nombre_norm):
            return _image_index[k]

    # Paso 3: todas las palabras del stem presentes en el nombre
    nombre_words = set(nombre_norm.split("_"))
    for k in brand_keys:
        stem = k[len(brand_prefix):]
        stem_words = set(stem.split("_"))
        if stem_words and stem_words.issubset(nombre_words):
            return _image_index[k]

    # Paso 4: stem es sufijo del nombre (ej: l'inperatrice → imperatrice)
    for k in brand_keys:
        stem = k[len(brand_prefix):]
        if nombre_norm.endswith(stem):
            return _image_index[k]

    return None


# ── Autenticación X-API-Key ───────────────────────────────────────────────────

_api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str = Security(_api_key_header)) -> None:
    """
    Protege endpoints sensibles con X-API-Key.

    - API_KEY configurada → exige el header exacto; 401 si falta o es incorrecta
    - API_KEY no configurada → permite el request con warning (solo desarrollo)

    Uso: router = APIRouter(dependencies=[Depends(verify_api_key)])
    """
    expected = os.environ.get("API_KEY", "")
    if not expected:
        logger.warning(
            "API_KEY no configurada — endpoint sin autenticacion (solo desarrollo)"
        )
        return
    if not api_key or not hmac.compare_digest(api_key, expected):
        raise HTTPException(
            status_code=401,
            detail="X-API-Key invalida o ausente",
            headers={"WWW-Authenticate": "ApiKey"},
        )


# ── Serialización de DataFrames ───────────────────────────────────────────────

def _serializar_valor(v):
    """Convierte un valor pandas a tipo nativo JSON-serializable."""
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
    snake: bool = False,
) -> list[dict]:
    """
    DataFrame → lista de dicts JSON-serializable.

    cols:  columnas a incluir (None = todas). Las inexistentes se ignoran.
    snake: True → convierte claves a snake_case para Flutter.
           "ID_Perfume" → "id_perfume",  "Precio_2ml" → "precio_2ml"
           Implementación: str.lower() es suficiente para las columnas de este proyecto.
    """
    if cols is not None:
        df = df[[c for c in cols if c in df.columns]]
    records = df.to_dict("records")
    result = [{k: _serializar_valor(v) for k, v in row.items()} for row in records]
    if snake:
        result = [{k.lower(): v for k, v in row.items()} for row in result]
    return result

"""
backend/api/routes/catalogo.py — Endpoints del catálogo. Públicos, sin autenticación.

Cambios para Flutter:
  - Todas las respuestas en snake_case (snake=True en df_to_json_list)
  - GET / devuelve Paginated[PerfumeResponse] con limit/offset
  - Cada perfume incluye image_url (null si no hay imagen en imagenes/)
  - response_model declarado en todos los endpoints para docs precisos

Flujo de GET /buscar?q=noir:
  Depends(get_repo) → SheetsRepository singleton
    → get_catalogo_cached(repo)       ← cache 30 min
      → filtrar_catalogo(df, "noir")  ← lógica en services/ (sin HTTP)
        → _serializar_catalogo(df)    ← snake_case + image_url
          → Paginated[PerfumeResponse]
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import (
    get_repo,
    get_catalogo_cached,
    get_image_url,
    df_to_json_list,
)
from backend.api.models import PerfumeResponse, Paginated
from backend.repositories.sheets_repository import SheetsRepository
from backend.services.venta_service import filtrar_catalogo

router = APIRouter()

# Columnas a exponer — excluye internas: Nombre_lower, fila_sheet, Notas_set, etc.
_COLS = [
    "ID_Perfume", "Marca", "Nombre",
    "Precio_2ml", "Precio_5ml", "Precio_10ml",
    "Stock_ml", "Notas", "Perfil_Olfativo",
]


def _a_perfume_response(row: dict) -> dict:
    """
    Convierte una fila del catálogo (ya en snake_case) a dict con image_url.
    row llega con claves snake_case tras df_to_json_list(snake=True).
    """
    # ID_Perfume puede venir como int desde Sheets — PerfumeResponse requiere str
    if "id_perfume" in row and row["id_perfume"] is not None:
        row["id_perfume"] = str(row["id_perfume"])
    row["image_url"] = get_image_url(
        marca=str(row.get("marca") or ""),
        nombre=str(row.get("nombre") or ""),
    )
    return row


def _serializar_catalogo(df) -> list[dict]:
    """Serializa DataFrame de catálogo a lista con snake_case + image_url."""
    rows = df_to_json_list(df, cols=_COLS, snake=True)
    return [_a_perfume_response(r) for r in rows]


@router.get(
    "/",
    response_model=Paginated[PerfumeResponse],
    summary="Listar catálogo con paginación",
)
def listar_catalogo(
    limit: int = Query(100, ge=1, le=500, description="Items por página (máx 500)"),
    offset: int = Query(0, ge=0, description="Items a omitir desde el inicio"),
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Catálogo completo con paginación.

    Para Flutter:
    - Primera carga: GET /catalogo/?limit=100
    - Infinite scroll:  GET /catalogo/?limit=50&offset=50
    - Verificar has_more antes de cargar más
    - Cachear localmente en SQLite/SharedPreferences (TTL 30 min)
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catalogo: {e}")

    total = len(df)
    pagina = df.iloc[offset: offset + limit]
    return {
        "items": _serializar_catalogo(pagina),
        "total": total,
        "limit": limit,
        "offset": offset,
        "has_more": (offset + limit) < total,
    }


@router.get(
    "/marcas",
    response_model=list[str],
    summary="Listar marcas disponibles",
)
def listar_marcas(repo: SheetsRepository = Depends(get_repo)):
    """
    Marcas únicas ordenadas alfabéticamente, derivadas del catálogo cacheado.
    Para Flutter: poblar el dropdown de filtro de marcas.
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar marcas: {e}")
    return sorted(df["Marca"].dropna().unique().tolist())


@router.get(
    "/buscar",
    response_model=Paginated[PerfumeResponse],
    summary="Buscar perfumes por texto o marca",
)
def buscar_perfumes(
    q: str = Query("", description="Texto libre: nombre, marca o notas"),
    marca: Optional[str] = Query(None, description="Filtrar por marca exacta"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Misma lógica que Streamlit — reutiliza filtrar_catalogo() de services/.
    Catálogo desde cache, búsqueda rápida sobre columnas pre-computadas.

    Para Flutter: llamar al escribir en el buscador (debounce 300 ms).
    Ejemplo: GET /api/v1/catalogo/buscar?q=noir&marca=YSL
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catalogo: {e}")

    resultado = filtrar_catalogo(df, texto=q, marca=marca or "")
    total = len(resultado)
    pagina = resultado.iloc[offset: offset + limit]
    return {
        "items": _serializar_catalogo(pagina),
        "total": total,
        "limit": limit,
        "offset": offset,
        "has_more": (offset + limit) < total,
    }


@router.get(
    "/{id_perfume}",
    response_model=PerfumeResponse,
    summary="Detalle de un perfume por ID",
)
def obtener_perfume(
    id_perfume: str,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Un perfume por ID_Perfume. Incluye image_url si hay imagen disponible.
    Para Flutter: pantalla de detalle al tocar una tarjeta.
    Retorna 404 si el ID no existe.
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catalogo: {e}")

    fila = df[df["ID_Perfume"].astype(str) == str(id_perfume)]
    if fila.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Perfume '{id_perfume}' no encontrado en el catalogo",
        )

    return _serializar_catalogo(fila)[0]

"""
backend/api/routes/catalogo.py — Endpoints del catálogo de perfumes.

Endpoints públicos (sin autenticación):
  El catálogo es información de producto — sin datos sensibles del negocio.
  Flutter lo puede cachear localmente tras la primera carga.

Flujo de GET /buscar?q=noir&marca=YSL:
  Depends(get_repo) → SheetsRepository singleton
    → get_catalogo_cached(repo)  ← DataFrame desde cache TTL 30 min
      → filtrar_catalogo(df, "noir", "YSL")  ← lógica en services/
        → df_to_json_list(resultado)  ← serialización segura
          → FastAPI responde JSON

La lógica de filtrado vive en backend/services/venta_service.py, no aquí.
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import get_repo, get_catalogo_cached, df_to_json_list
from backend.repositories.sheets_repository import SheetsRepository
from backend.services.venta_service import filtrar_catalogo

router = APIRouter()

# Columnas públicas — excluye columnas internas:
# Nombre_lower, Marca_lower, Marca_limpia, Notas_set, fila_sheet, etc.
_COLS_PUBLICAS = [
    "ID_Perfume", "Marca", "Nombre",
    "Precio_2ml", "Precio_5ml", "Precio_10ml",
    "Stock_ml", "Notas", "Perfil_Olfativo",
]


@router.get("/", summary="Listar catálogo completo")
def listar_catalogo(repo: SheetsRepository = Depends(get_repo)):
    """
    Todos los perfumes con precios y stock actual.
    Respuesta desde cache (hasta 30 min de antigüedad).

    Para Flutter: carga inicial al abrir la app; cachear en SharedPreferences.
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catálogo: {e}")
    return df_to_json_list(df, cols=_COLS_PUBLICAS)


@router.get("/marcas", summary="Listar marcas disponibles")
def listar_marcas(repo: SheetsRepository = Depends(get_repo)):
    """
    Marcas únicas, ordenadas alfabéticamente.
    Se deriva del catálogo cacheado — sin llamada extra a Sheets.

    Para Flutter: dropdown de filtro de marcas.
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar marcas: {e}")
    return sorted(df["Marca"].dropna().unique().tolist())


@router.get("/buscar", summary="Buscar perfumes por texto o marca")
def buscar_perfumes(
    q: str = Query("", description="Texto libre: nombre, marca o notas"),
    marca: Optional[str] = Query(None, description="Filtrar por marca exacta"),
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Misma lógica de filtrado que Streamlit — reutiliza filtrar_catalogo() de services/.
    El catálogo se sirve desde cache, así que la búsqueda es rápida.

    Para Flutter: ejecutar al escribir (debounce ~300 ms en el cliente).
    Ejemplo: /api/v1/catalogo/buscar?q=noir&marca=YSL
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catálogo: {e}")

    resultado = filtrar_catalogo(df, texto=q, marca=marca or "")
    return df_to_json_list(resultado, cols=_COLS_PUBLICAS)


@router.get("/{id_perfume}", summary="Detalle de un perfume por ID")
def obtener_perfume(
    id_perfume: str,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Un perfume por ID_Perfume. 404 si no existe.

    Para Flutter: pantalla de detalle al tocar una tarjeta.
    Ejemplo: /api/v1/catalogo/12
    """
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catálogo: {e}")

    fila = df[df["ID_Perfume"].astype(str) == str(id_perfume)]
    if fila.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Perfume '{id_perfume}' no encontrado en el catálogo",
        )

    return df_to_json_list(fila, cols=_COLS_PUBLICAS)[0]

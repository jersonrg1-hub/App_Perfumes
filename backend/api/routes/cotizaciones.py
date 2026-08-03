"""
backend/api/routes/cotizaciones.py — Endpoints de cotizaciones (requieren X-API-Key).

La columna Estado en la hoja Cotizaciones ocupa la posicion 6
(columnas: ID_Cotizacion, Fecha, Celular, Items, Total, Estado).

Flujo de POST /cotizaciones/:
  CotizacionRequest (Pydantic valida)
    -> items = [item.model_dump() for item in body.items]
    -> items = aplicar_descuentos(items)        # precio efectivo por item.con_descuento
    -> total = calcular_total_cotizacion(items)  # el back es la fuente de verdad del total
    -> repo.save_quote(celular, items, total)
       -> genera ID correlativo (C001, C002...)
       -> guarda fila con estado "Enviado"
    -> retorna CotizacionRegistrada(id_cotizacion="C015")
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import (
    get_repo, verify_api_key, df_to_json_list,
    get_cotizaciones_cached, invalidar_cache_cotizaciones,
    paginate_df,
)
from backend.api.models import (
    CotizacionRequest,
    CotizacionRegistrada,
    CotizacionResponse,
    EstadoCotizacionUpdate,
    Paginated,
)
from backend.repositories.sheets_repository import SheetsRepository
from backend.services.cotizacion_service import aplicar_descuentos, calcular_total_cotizacion

router = APIRouter(dependencies=[Depends(verify_api_key)])

_COL_ESTADO_COT = 6  # posicion 1-indexed de "Estado" en hoja Cotizaciones
_ESTADOS_VALIDOS = {"Enviado", "Confirmado", "Anulado", "Aceptada"}


@router.get(
    "/",
    response_model=Paginated[CotizacionResponse],
    summary="Listar cotizaciones con paginacion",
)
def listar_cotizaciones(
    limit: int = Query(50, ge=1, le=500, description="Items por pagina"),
    offset: int = Query(0, ge=0, description="Items a omitir"),
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    fecha_desde: Optional[str] = Query(
        None, description="Filtrar Fecha >= valor (ISO yyyy-mm-dd)"
    ),
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Historial de cotizaciones paginado.
    Cada objeto incluye 'fila_sheet' para poder actualizar estado con PUT /{id}.

    Para Flutter: pantalla de historial de cotizaciones.
    Ejemplo: GET /api/v1/cotizaciones/?limit=20&offset=0&estado=Enviado
    Ejemplo: GET /api/v1/cotizaciones/?limit=100&fecha_desde=2026-06-26
    """
    try:
        df = get_cotizaciones_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar cotizaciones: {e}")

    if not df.empty and estado and "Estado" in df.columns:
        df = df[df["Estado"] == estado]

    if not df.empty and fecha_desde and "Fecha" in df.columns:
        df = df[df["Fecha"].astype(str) >= fecha_desde]

    if not df.empty and "Fecha" in df.columns:
        df = df.sort_values("Fecha", ascending=False, na_position="last")

    return paginate_df(df, _serializar_cotizaciones, limit, offset)


@router.get(
    "/cliente/{celular}",
    response_model=list[CotizacionResponse],
    summary="Cotizaciones de un cliente por celular",
)
def cotizaciones_por_cliente(
    celular: str,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Todas las cotizaciones de un cliente.
    Para Flutter: pantalla de historial del cliente.
    Ejemplo: GET /api/v1/cotizaciones/cliente/987654321
    """
    try:
        df = get_cotizaciones_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar cotizaciones: {e}")

    if df.empty or "Celular" not in df.columns:
        return []

    historial = df[df["Celular"].astype(str) == celular]
    return _serializar_cotizaciones(historial)


@router.post(
    "/",
    response_model=CotizacionRegistrada,
    summary="Guardar cotizacion",
)
def guardar_cotizacion(
    body: CotizacionRequest,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Guarda cotizacion y retorna el ID asignado (ej. 'C015').
    El descuento por item y el total se calculan en el backend, nunca se confia
    en un total enviado por el cliente.
    Para Flutter: boton "Enviar cotizacion" en la pantalla de busqueda.
    """
    items = aplicar_descuentos([item.model_dump() for item in body.items])
    total = calcular_total_cotizacion(items)
    try:
        id_cot = repo.save_quote(body.celular or "", items, total, alias=body.alias)
        invalidar_cache_cotizaciones()
        return CotizacionRegistrada(id_cotizacion=id_cot)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar cotizacion: {e}")


@router.put(
    "/{id_cotizacion}",
    summary="Actualizar estado de cotizacion",
)
def actualizar_estado_cotizacion(
    id_cotizacion: str,
    body: EstadoCotizacionUpdate,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Actualiza estado de una cotizacion (Confirmado / Anulado / Aceptado).
    El fila_sheet se resuelve internamente por ID.
    Para Flutter: boton de conversión a venta.
    """
    if body.nuevo_estado not in _ESTADOS_VALIDOS:
        raise HTTPException(
            status_code=422,
            detail=f"Estado invalido. Validos: {sorted(_ESTADOS_VALIDOS)}",
        )
    try:
        df = repo.fetch_quotes()  # fresco — necesita fila_sheet exacto
        filas = df[df["ID_Cotizacion"].astype(str) == id_cotizacion]["fila_sheet"]
        if filas.empty:
            raise HTTPException(status_code=404, detail="Cotización no encontrada")
        repo.update_quote_status(
            nuevo_estado=body.nuevo_estado,
            fila_sheet=int(filas.iloc[0]),
            col_estado=_COL_ESTADO_COT,
        )
        invalidar_cache_cotizaciones()
        return {"id_cotizacion": id_cotizacion, "estado": body.nuevo_estado}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar cotizacion: {e}")


# ── Serialización ─────────────────────────────────────────────────────────────

# Columnas fijas; la columna de perfumes se detecta dinámicamente
_COLS_FIJAS = ["ID_Cotizacion", "Fecha", "Celular", "Total", "Estado", "alias"]
# Posibles nombres de la columna de perfumes en distintas versiones de la hoja
_POSIBLES_COL_PERFUMES = ["Perfumes", "Items", "Perfume", "items"]


def _serializar_cotizaciones(df) -> list[dict]:
    """Serializa DataFrame de cotizaciones a lista snake_case."""
    col_perfumes = next((c for c in _POSIBLES_COL_PERFUMES if c in df.columns), None)
    cols = _COLS_FIJAS + ([col_perfumes] if col_perfumes else [])
    rows = df_to_json_list(df, cols=cols, snake=True)
    for row in rows:
        for campo in ("id_cotizacion", "celular"):
            if campo in row and row[campo] is not None:
                row[campo] = str(row[campo])
        # Normalizar cualquier variante del nombre a "items" para Flutter
        for clave in ("perfumes", "perfume"):
            if clave in row:
                row["items"] = row.pop(clave)
    return rows

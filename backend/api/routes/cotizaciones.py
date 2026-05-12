"""
backend/api/routes/cotizaciones.py — Endpoints de cotizaciones (requieren X-API-Key).

La columna Estado en la hoja Cotizaciones ocupa la posición 6
(columnas: ID_Cotizacion, Fecha, Celular, Items, Total, Estado).

Flujo de POST /cotizaciones/:
  CotizacionRequest (Pydantic valida)
    → items = [item.model_dump() for item in body.items]
    → repo.save_quote(celular, items, total)
       → genera ID correlativo (C001, C002...)
       → guarda fila con estado "Enviado"
    → retorna CotizacionRegistrada(id_cotizacion="C015")
"""
from fastapi import APIRouter, Depends, HTTPException

from backend.api.dependencies import get_repo, verify_api_key, df_to_json_list
from backend.api.models import (
    CotizacionRequest,
    CotizacionRegistrada,
    EstadoCotizacionUpdate,
)
from backend.repositories.sheets_repository import SheetsRepository

router = APIRouter(dependencies=[Depends(verify_api_key)])

_COL_ESTADO_COT = 6  # posición 1-indexed de "Estado" en hoja Cotizaciones
_ESTADOS_VALIDOS = {"Enviado", "Confirmado", "Anulado"}


@router.get("/", summary="Listar cotizaciones")
def listar_cotizaciones(repo: SheetsRepository = Depends(get_repo)):
    """
    Historial de cotizaciones.
    Cada objeto incluye 'fila_sheet' para poder actualizar estado.
    """
    try:
        df = repo.fetch_quotes()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar cotizaciones: {e}")
    return df_to_json_list(df)


@router.post("/", response_model=CotizacionRegistrada, summary="Guardar cotización")
def guardar_cotizacion(
    body: CotizacionRequest,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Guarda cotización y retorna el ID asignado (ej. 'C015').
    Para Flutter: botón "Enviar cotización" en la pantalla de búsqueda.
    """
    items = [item.model_dump() for item in body.items]
    try:
        id_cot = repo.save_quote(body.celular, items, body.total)
        return CotizacionRegistrada(id_cotizacion=id_cot)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar cotización: {e}")


@router.put("/{id_cotizacion}", summary="Actualizar estado de cotización")
def actualizar_estado_cotizacion(
    id_cotizacion: str,
    body: EstadoCotizacionUpdate,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Actualiza estado de una cotización (Confirmado / Anulado).
    fila_sheet es el campo 'fila_sheet' del objeto cotización al listarlo.
    """
    if body.nuevo_estado not in _ESTADOS_VALIDOS:
        raise HTTPException(
            status_code=422,
            detail=f"Estado inválido. Válidos: {sorted(_ESTADOS_VALIDOS)}",
        )
    try:
        repo.update_quote_status(
            nuevo_estado=body.nuevo_estado,
            fila_sheet=body.fila_sheet,
            col_estado=_COL_ESTADO_COT,
        )
        return {"id_cotizacion": id_cotizacion, "estado": body.nuevo_estado}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar cotización: {e}")

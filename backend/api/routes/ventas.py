"""
backend/api/routes/ventas.py — Endpoints de ventas (requieren X-API-Key).

Todos los endpoints están protegidos: ventas contienen datos de clientes
(nombre, celular, dirección) que no deben ser públicos.

Flujo de POST /ventas/:
  VentaRequest (Pydantic valida)
    → cesta  = [item.model_dump() for item in body.items]
    → cliente = body.model_dump(exclude={"items"})
    → repo.register_complete_sale(cesta, cliente, MERMA_PCT)
    → invalidar cache ventas + catálogo (el stock cambió)
    → retorna VentaRegistrada(id_compra="V042")

Cache:
  GET /         usa get_ventas_cached()   (TTL 2 min)
  GET /pendientes usa get_ventas_cached() (TTL 2 min)
  POST /        invalida cache ventas + catálogo
  PUT /{id}/estado invalida cache ventas
"""
from fastapi import APIRouter, Depends, HTTPException

from backend.api.dependencies import (
    get_repo,
    get_ventas_cached,
    invalidar_cache_catalogo,
    invalidar_cache_ventas,
    verify_api_key,
    df_to_json_list,
)
from backend.api.models import VentaRequest, VentaRegistrada, EstadoVentaUpdate
from backend.repositories.sheets_repository import SheetsRepository, StockUpdateError
from backend.services.costos_service import MERMA_PCT
from backend.core.config import COL_ESTADO_NUM

router = APIRouter(dependencies=[Depends(verify_api_key)])

_ESTADOS_VALIDOS = {"Pendiente", "Entregado", "Anulado"}


@router.get("/", summary="Listar todas las ventas")
def listar_ventas(repo: SheetsRepository = Depends(get_repo)):
    """
    Historial de ventas (excluye Anuladas).
    Respuesta desde cache (hasta 2 min de antigüedad).

    Cada objeto incluye 'fila_sheet' — Flutter debe guardarlo
    para poder actualizar el estado con PUT /{id}/estado.
    """
    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")
    return df_to_json_list(df)


@router.get("/pendientes", summary="Ventas pendientes de entrega")
def listar_pendientes(repo: SheetsRepository = Depends(get_repo)):
    """
    Solo ventas con Estado='Pendiente'.
    Para Flutter: pantalla de despacho / pedidos a entregar.
    """
    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    if df.empty or "Estado" not in df.columns:
        return []

    return df_to_json_list(df[df["Estado"] == "Pendiente"])


@router.post("/", response_model=VentaRegistrada, summary="Registrar venta completa")
def registrar_venta(body: VentaRequest, repo: SheetsRepository = Depends(get_repo)):
    """
    Registra venta de forma atómica:
    1. Genera ID correlativo (V001, V002...)
    2. Guarda una fila por item en Ventas_Pendientes
    3. Descuenta stock en Catálogo (con merma 4%)

    Si el stock falla (StockUpdateError) la venta queda guardada
    y se retorna con 'warning' para que Flutter lo muestre al usuario.

    Invalida cache de ventas y catálogo (el stock cambió).
    """
    cesta = [item.model_dump() for item in body.items]
    cliente = body.model_dump(exclude={"items"})

    try:
        id_compra = repo.register_complete_sale(cesta, cliente, MERMA_PCT)
        invalidar_cache_ventas()
        invalidar_cache_catalogo()
        return VentaRegistrada(id_compra=id_compra)
    except StockUpdateError as e:
        invalidar_cache_ventas()  # La venta se guardó aunque el stock falló
        return VentaRegistrada(
            id_compra=e.id_compra,
            warning="Venta guardada pero el stock no pudo actualizarse",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al registrar venta: {e}")


@router.put("/{id_venta}/estado", summary="Actualizar estado de una venta")
def actualizar_estado_venta(
    id_venta: str,
    body: EstadoVentaUpdate,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Cambia el estado de una venta (Entregado / Anulado).
    fila_sheet es el campo 'fila_sheet' del objeto venta al listarlo.
    Para Flutter: botón "Marcar entregado" en la lista de pendientes.
    """
    if body.nuevo_estado not in _ESTADOS_VALIDOS:
        raise HTTPException(
            status_code=422,
            detail=f"Estado inválido. Válidos: {sorted(_ESTADOS_VALIDOS)}",
        )
    try:
        repo.update_sales_multi_batch(
            [(body.fila_sheet, {COL_ESTADO_NUM: body.nuevo_estado})]
        )
        invalidar_cache_ventas()
        return {"id_venta": id_venta, "estado": body.nuevo_estado}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar estado: {e}")

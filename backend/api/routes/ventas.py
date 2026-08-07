"""
backend/api/routes/ventas.py — Endpoints de ventas. Todos protegidos con X-API-Key.

Nuevo en esta versión:
  GET /cliente/{celular}  — historial + datos del cliente para autocompletar checkout
  Paginación en GET /     — limit/offset para Flutter infinite scroll
  snake_case en responses — estándar Dart/Flutter

Flujo de POST /ventas/:
  VentaRequest (Pydantic valida body)
    → cesta  = [item.model_dump() for item in body.items]
    → cliente = body.model_dump(exclude={"items"})
    → repo.register_complete_sale(cesta, cliente, MERMA_PCT)
    → invalida cache ventas + catálogo (stock cambió)
    → retorna VentaRegistrada(id_compra="V042")
"""
import threading
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.api.dependencies import (
    get_repo,
    get_ventas_cached,
    get_catalogo_cached,
    invalidar_cache_catalogo,
    invalidar_cache_ventas,
    verify_api_key,
    df_to_json_list,
    paginate_df,
)
import logging
from backend.api.routes import estadisticas as _estadisticas_mod
from backend.api.models import (
    VentaRequest,
    VentaRegistrada,
    VentaResponse,
    EstadoVentaUpdate,
    ClientePrevioResponse,
    Paginated,
)
from backend.repositories.sheets_repository import SheetsRepository, StockUpdateError
from backend.services.costos_service import MERMA_PCT
from backend.core.config import COL_ESTADO_NUM

router = APIRouter(dependencies=[Depends(verify_api_key)])
logger = logging.getLogger("perfuteca.api")

_ESTADOS_VALIDOS  = {"Pendiente", "Entregado", "Anulado"}
_anulacion_lock   = threading.Lock()   # serializa check-update en anulaciones concurrentes


@router.get(
    "/",
    response_model=Paginated[VentaResponse],
    summary="Listar ventas con paginación",
)
def listar_ventas(
    limit: int = Query(50, ge=1, le=500, description="Items por página"),
    offset: int = Query(0, ge=0, description="Items a omitir"),
    estado: Optional[str] = Query(None, description="Filtrar por estado"),
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Historial de ventas paginado (excluye Anuladas).
    Cada objeto incluye 'fila_sheet' — Flutter lo guarda para PUT /{id}/estado.

    Para Flutter: pantalla de historial y estadísticas.
    Ejemplo: GET /api/v1/ventas/?limit=20&offset=0&estado=Pendiente
    """
    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    if not df.empty and estado and "Estado" in df.columns:
        df = df[df["Estado"] == estado]

    if not df.empty and "Fecha" in df.columns:
        df = df.sort_values(
            ["Fecha", "fila_sheet"], ascending=[False, False], na_position="last"
        )

    return paginate_df(df, lambda p: df_to_json_list(p, snake=True), limit, offset)


@router.get(
    "/pendientes",
    response_model=list[VentaResponse],
    summary="Ventas pendientes de entrega",
)
def listar_pendientes(repo: SheetsRepository = Depends(get_repo)):
    """
    Ventas con Estado='Pendiente'.
    Para Flutter: pantalla de despacho — lista de pedidos a entregar.
    """
    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    if df.empty or "Estado" not in df.columns:
        return []

    return df_to_json_list(df[df["Estado"] == "Pendiente"], snake=True)


@router.get(
    "/cliente/{celular}",
    summary="Historial y datos de un cliente por celular",
)
def ventas_por_cliente(
    celular: str,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Historial de compras de un cliente + datos para autocompletar el checkout.

    Para Flutter:
    - Autocompletar nombre, dirección y método al iniciar una venta
    - Pantalla "Mis compras" del cliente
    - Retorna resumen null si el cliente no tiene historial

    Ejemplo: GET /api/v1/ventas/cliente/987654321
    Response:
      {
        "resumen": {comprador, direccion, tipo_envio, metodo_pago, total_compras},
        "compras": [...lista de ventas del cliente...]
      }
    """
    try:
        df = get_ventas_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar ventas: {e}")

    if df.empty or "Celular" not in df.columns:
        return {"resumen": None, "compras": []}

    historial = df[df["Celular"].astype(str) == celular]

    if historial.empty:
        return {"resumen": None, "compras": []}

    ultimo = historial.iloc[-1]
    resumen = ClientePrevioResponse(
        comprador=str(ultimo.get("Comprador", "") or ""),
        direccion=str(ultimo.get("Direccion", "") or ""),
        distrito=str(ultimo.get("Distrito", "") or ""),
        tipo_envio=str(ultimo.get("Tipo_Envio", "") or ""),
        metodo_pago=str(ultimo.get("Metodo_Pago", "") or ""),
        total_compras=len(historial),
        alias=str(ultimo.get("alias", "") or "") or None,
    )

    return {
        "resumen": resumen.model_dump(),
        "compras": df_to_json_list(historial, snake=True),
    }


@router.post(
    "/",
    response_model=VentaRegistrada,
    summary="Registrar venta completa",
)
def registrar_venta(body: VentaRequest, repo: SheetsRepository = Depends(get_repo)):
    """
    Registra venta de forma atómica:
    1. Genera ID correlativo (V001, V002...)
    2. Guarda una fila por item en Ventas_Pendientes
    3. Descuenta stock en Catálogo (merma 4%)

    Si el stock falla (StockUpdateError) la venta queda guardada
    y se retorna con 'warning' para que Flutter lo muestre al usuario.
    Invalida cache de ventas y catálogo.
    """
    cesta = [item.model_dump() for item in body.items]
    cliente = body.model_dump(exclude={"items"})

    try:
        id_compra = repo.register_complete_sale(cesta, cliente, MERMA_PCT)
        invalidar_cache_ventas()
        invalidar_cache_catalogo()
        _estadisticas_mod._invalidar_cache_stats()
        _estadisticas_mod._invalidar_cache_clientes()
        return VentaRegistrada(id_compra=id_compra)
    except StockUpdateError as e:
        invalidar_cache_ventas()
        _estadisticas_mod._invalidar_cache_stats()
        _estadisticas_mod._invalidar_cache_clientes()
        return VentaRegistrada(
            id_compra=e.id_compra,
            warning="Venta guardada pero el stock no pudo actualizarse",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al registrar venta: {e}")


@router.put(
    "/{id_venta}/estado",
    summary="Actualizar estado de una venta",
)
def actualizar_estado_venta(
    id_venta: str,
    body: EstadoVentaUpdate,
    repo: SheetsRepository = Depends(get_repo),
):
    """
    Cambia el estado de una venta (Entregado / Anulado) — todas sus filas/items en 1 sola
    escritura batch a Sheets (en vez de 1 PUT + 1 escritura por fila).
    Al anular: actualiza Estado primero (operación primaria), luego repone stock
    (best-effort — si falla, Estado queda correcto y stock se puede corregir manualmente).
    Lock serializa anulaciones concurrentes para evitar doble-restock.
    """
    if body.nuevo_estado not in _ESTADOS_VALIDOS:
        raise HTTPException(
            status_code=422,
            detail=f"Estado invalido. Validos: {sorted(_ESTADOS_VALIDOS)}",
        )

    filas_para_restock: list[dict] = []

    if body.nuevo_estado == "Anulado":
        with _anulacion_lock:
            filas_actuales = [repo.get_sale_row(f) for f in body.filas_sheet]
            if any(f.get("Estado") == "Anulado" for f in filas_actuales):
                raise HTTPException(status_code=409, detail="La venta ya está anulada")

            try:
                repo.update_sales_multi_batch([
                    (fila, {COL_ESTADO_NUM: body.nuevo_estado})
                    for fila in body.filas_sheet
                ])
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Error al actualizar estado: {e}")

            invalidar_cache_ventas()
            _estadisticas_mod._invalidar_cache_stats()
            _estadisticas_mod._invalidar_cache_clientes()

            filas_para_restock = [
                f for f in filas_actuales if f.get("ID_Perfume") and f.get("Ml_Vendido")
            ]
    else:
        try:
            repo.update_sales_multi_batch([
                (fila, {COL_ESTADO_NUM: body.nuevo_estado})
                for fila in body.filas_sheet
            ])
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error al actualizar estado: {e}")

        invalidar_cache_ventas()
        _estadisticas_mod._invalidar_cache_stats()
        _estadisticas_mod._invalidar_cache_clientes()

    if filas_para_restock:
        try:
            df_cat = get_catalogo_cached(repo)
            items_anulados = [
                {"id_perfume": f["ID_Perfume"], "ml": f["Ml_Vendido"]}
                for f in filas_para_restock
            ]
            repo.restore_stock_batch(items_anulados, MERMA_PCT, df_catalogo=df_cat)
            invalidar_cache_catalogo()
        except Exception as e:
            logger.error(f"[anular_venta/restock] {type(e).__name__}: {e}")

    return {"id_venta": id_venta, "estado": body.nuevo_estado}

"""
backend/api/routes/ventas.py — Endpoints FastAPI para ventas.

Scaffold: descomentar e implementar cuando se active FastAPI.
La lógica de negocio ya existe en backend/services/venta_service.py
y el acceso a datos en backend/repositories/sheets_repository.py.

Endpoints sugeridos para Flutter:
  GET  /api/v1/ventas/              → listar_ventas()
  POST /api/v1/ventas/              → registrar_venta(body)
  GET  /api/v1/ventas/pendientes    → listar_pendientes()
  PUT  /api/v1/ventas/{id}/estado   → actualizar_estado(id, estado)
"""
# from fastapi import APIRouter, HTTPException
# from pydantic import BaseModel
# from backend.repositories.sheets_repository import SheetsRepository, StockUpdateError
# from backend.services.costos_service import MERMA_PCT
#
# router = APIRouter()
#
# class VentaRequest(BaseModel):
#     comprador: str
#     celular: str
#     direccion: str
#     tipo_envio: str
#     fecha: str
#     items: list[dict]  # lista de ItemCesta
#
# def _get_repo() -> SheetsRepository:
#     import os, json
#     creds = json.loads(os.environ["GCP_SERVICE_ACCOUNT"])
#     return SheetsRepository(creds)
#
# @router.get("/")
# async def listar_ventas():
#     return _get_repo().fetch_sales().to_dict("records")
#
# @router.post("/")
# async def registrar_venta(body: VentaRequest):
#     try:
#         id_compra = _get_repo().register_complete_sale(
#             cesta=body.items,
#             cliente=body.dict(exclude={"items"}),
#             merma_pct=MERMA_PCT,
#         )
#         return {"id_compra": id_compra}
#     except StockUpdateError as e:
#         return {"id_compra": e.id_compra, "warning": "Stock no actualizado"}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

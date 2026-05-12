"""
backend/api/routes/cotizaciones.py — Endpoints FastAPI para cotizaciones.

Scaffold: descomentar e implementar cuando se active FastAPI.

Endpoints sugeridos para Flutter:
  GET  /api/v1/cotizaciones/         → listar_cotizaciones()
  POST /api/v1/cotizaciones/         → guardar_cotizacion(body)
  PUT  /api/v1/cotizaciones/{id}     → actualizar_estado(id, estado)
"""
# from fastapi import APIRouter, HTTPException
# from pydantic import BaseModel
# from backend.repositories.sheets_repository import SheetsRepository
#
# router = APIRouter()
#
# class CotizacionRequest(BaseModel):
#     celular: str
#     items: list[dict]
#     total: float
#
# def _get_repo() -> SheetsRepository:
#     import os, json
#     creds = json.loads(os.environ["GCP_SERVICE_ACCOUNT"])
#     return SheetsRepository(creds)
#
# @router.get("/")
# async def listar_cotizaciones():
#     return _get_repo().fetch_quotes().to_dict("records")
#
# @router.post("/")
# async def guardar_cotizacion(body: CotizacionRequest):
#     id_cot = _get_repo().save_quote(body.celular, body.items, body.total)
#     return {"id_cotizacion": id_cot}

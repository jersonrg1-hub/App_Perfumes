"""
backend/api/routes/catalogo.py — Endpoints FastAPI para el catálogo.

Scaffold: descomentar e implementar cuando se active FastAPI.
La lógica de filtrado ya existe en backend/services/venta_service.py.

Endpoints sugeridos para Flutter:
  GET /api/v1/catalogo/          → listar_catalogo()
  GET /api/v1/catalogo/marcas    → listar_marcas()
  GET /api/v1/catalogo/buscar    → buscar_perfumes(q, marca)
  GET /api/v1/catalogo/{id}      → obtener_perfume(id)
"""
# from fastapi import APIRouter, HTTPException, Query
# from backend.repositories.sheets_repository import SheetsRepository
# from backend.services.venta_service import filtrar_catalogo
# from backend.core.config import COLUMNAS_REQUERIDAS
#
# router = APIRouter()
#
# def _get_repo() -> SheetsRepository:
#     import os, json
#     creds = json.loads(os.environ["GCP_SERVICE_ACCOUNT"])
#     return SheetsRepository(creds)
#
# @router.get("/")
# async def listar_catalogo():
#     df = _get_repo().fetch_catalog()
#     return df[COLUMNAS_REQUERIDAS + ["Stock_ml", "Notas", "Perfil_Olfativo"]].to_dict("records")
#
# @router.get("/marcas")
# async def listar_marcas():
#     df = _get_repo().fetch_catalog()
#     return sorted(df["Marca"].dropna().unique().tolist())
#
# @router.get("/buscar")
# async def buscar_perfumes(q: str = Query(""), marca: str | None = Query(None)):
#     df = _get_repo().fetch_catalog()
#     resultado = filtrar_catalogo(df, texto=q, marca=marca)
#     return resultado.to_dict("records")

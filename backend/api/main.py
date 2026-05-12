"""
backend/api/main.py — Aplicación FastAPI (scaffold para deploy en Render).

Estado actual: scaffold con endpoints placeholder (HTTP 501).
Activar cuando se decida migrar el backend de Streamlit a FastAPI.

Para activar en Render:
  1. Agregar 'fastapi' y 'uvicorn' a requirements.txt
  2. En Render: Start Command = "uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT"
  3. Variables de entorno: GCP_SERVICE_ACCOUNT (JSON como string), APP_PASSWORD

Luego Flutter consumirá estos endpoints en lugar de Streamlit.
"""
# from fastapi import FastAPI
# from backend.api.routes import catalogo, ventas, cotizaciones
#
# app = FastAPI(
#     title="Perfuteca API",
#     description="API REST — preparada para Flutter frontend",
#     version="0.1.0",
# )
#
# app.include_router(catalogo.router, prefix="/api/v1/catalogo", tags=["Catálogo"])
# app.include_router(ventas.router, prefix="/api/v1/ventas", tags=["Ventas"])
# app.include_router(cotizaciones.router, prefix="/api/v1/cotizaciones", tags=["Cotizaciones"])
#
# @app.get("/health")
# def health():
#     return {"status": "ok", "version": "0.1.0"}

# ── Descomentar para activar FastAPI ──────────────────────────────────────────
# Por ahora el archivo existe para documentar la arquitectura objetivo.
# La lógica de negocio ya está lista en backend/services/ y backend/repositories/.

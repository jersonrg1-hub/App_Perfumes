"""
backend/api/main.py — Aplicación FastAPI preparada para Flutter.

Capas de la request:
  Middleware (logging + timing)
    → Route Handler  (HTTP, validación)
      → Service      (lógica de negocio, pura Python)
        → Repository (Google Sheets, sin Streamlit)

Nuevos endpoints para Flutter:
  GET /api/v1/config   — opciones de la app (dropdowns Flutter sin hardcodear)
  GET /health          — estado con timestamp (para diagnosticar cold starts)
  /imagenes/*          — imágenes servidas como archivos estáticos

Ejecución local:
  uvicorn backend.api.main:app --reload

Deploy Render:
  uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1
"""
import logging
import os
import time
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from backend.api.routes import catalogo, ventas, cotizaciones
from backend.core.config import ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO, STOCK_CRITICO, STOCK_BAJO

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("perfuteca.api")

VERSION = "0.2.0"


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup:
    1. Construye el índice de imágenes (lectura de sistema de archivos, una sola vez)
    2. Inicializa SheetsRepository — falla rápido si GCP_SERVICE_ACCOUNT falta
    3. Advierte si API_KEY no está configurada
    """
    from backend.api.dependencies import get_repo, construir_image_index

    # Índice de imágenes
    imagenes_dir = Path("imagenes")
    construir_image_index(imagenes_dir)

    # Repositorio Google Sheets
    try:
        get_repo()
        logger.info("[OK] Repositorio Google Sheets listo")
    except RuntimeError as e:
        logger.error("[ERROR] Configuracion incompleta: %s", e)

    # Autenticación
    if not os.environ.get("API_KEY"):
        logger.warning("[WARN] API_KEY no configurada — endpoints sensibles sin autenticacion")
    else:
        logger.info("[OK] Autenticacion X-API-Key activa")

    yield
    logger.info("API detenida")


# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Perfuteca API",
    description=(
        "API REST para gestión de perfumería. "
        "Backend para Flutter — reutiliza services/ y repositories/."
    ),
    version=VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)


# ── Static files: imágenes de perfumes ───────────────────────────────────────
# Flutter puede mostrar imágenes con: Image.network("$baseUrl/imagenes/chanel/coco_noir.jpg")
# Solo se monta si el directorio existe (en local siempre; en Render también, está en el repo).
if Path("imagenes").exists():
    app.mount("/imagenes", StaticFiles(directory="imagenes"), name="imagenes")
    logger.info("Static files montados en /imagenes")


# ── Middleware: logging ───────────────────────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Registra método, ruta, status y tiempo de cada request."""
    start = time.perf_counter()
    response = await call_next(request)
    ms = (time.perf_counter() - start) * 1000
    logger.info(
        "%s %s -> %d (%.0fms)",
        request.method, request.url.path, response.status_code, ms,
    )
    return response


# ── Handler de errores no capturados ─────────────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(
        "Error no capturado: %s %s — %s",
        request.method, request.url.path, exc,
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "Error interno del servidor. Intente nuevamente."},
    )


# ── CORS ──────────────────────────────────────────────────────────────────────
_origins = [o.strip() for o in os.environ.get("CORS_ORIGINS", "*").split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(catalogo.router,     prefix="/api/v1/catalogo",     tags=["Catalogo"])
app.include_router(ventas.router,       prefix="/api/v1/ventas",       tags=["Ventas"])
app.include_router(cotizaciones.router, prefix="/api/v1/cotizaciones", tags=["Cotizaciones"])


# ── Endpoints del sistema ─────────────────────────────────────────────────────

@app.get("/health", tags=["Sistema"])
def health():
    """
    Health check para Render y Flutter.

    Flutter puede llamar este endpoint al arrancar para:
    - Verificar conectividad con el backend
    - Detectar cold starts (si tarda >5 seg, el servicio estaba dormido)
    - Mostrar versión de la API en la pantalla de configuración
    """
    return {
        "status": "ok",
        "version": VERSION,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/api/v1/config", tags=["Sistema"])
def get_config():
    """
    Configuración de la app para Flutter.

    Flutter llama este endpoint al arrancar para poblar dropdowns
    sin hardcodear opciones en el cliente.
    Si el backend actualiza las opciones, Flutter las recibe automáticamente.

    Ejemplo de uso en Flutter:
      final config = await api.getConfig();
      // Dropdown de métodos de pago:
      DropdownButton(items: config.metodosPago.map(...).toList())
    """
    return {
        "ml_opciones": ML_OPCIONES,
        "metodos_pago": METODOS_PAGO,
        "tipos_envio": TIPOS_ENVIO,
        "stock_critico_ml": STOCK_CRITICO,
        "stock_bajo_ml": STOCK_BAJO,
        "version": VERSION,
    }

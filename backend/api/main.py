"""
backend/api/main.py — Aplicación FastAPI para Perfumería.

Capas de la request:
  Middleware (logging + timing)
    → Route Handler (HTTP únicamente)
      → Service (lógica de negocio, sin HTTP)
        → Repository (Google Sheets, sin Streamlit)

Ejecución local:
  uvicorn backend.api.main:app --reload

Deploy en Render:
  Start Command: uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1
  Variables obligatorias: GCP_SERVICE_ACCOUNT, API_KEY
  Variables opcionales:   CORS_ORIGINS (default "*")
"""
import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.api.routes import catalogo, ventas, cotizaciones

# ── Logging ───────────────────────────────────────────────────────────────────
# Configurar UNA vez aquí; los demás módulos usan logging.getLogger(__name__).
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("perfuteca.api")


# ── Lifespan (startup / shutdown) ─────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup: valida configuración e inicializa el repositorio.
    Falla rápido si GCP_SERVICE_ACCOUNT no está configurado —
    mejor un error claro al arrancar que en el primer request de producción.
    """
    from backend.api.dependencies import get_repo
    try:
        get_repo()
        logger.info("[OK] Repositorio Google Sheets listo")
    except RuntimeError as e:
        # No detenemos el proceso: /health sigue respondiendo aunque falte config
        logger.error("[ERROR] Configuracion incompleta: %s", e)

    api_key = os.environ.get("API_KEY", "")
    if not api_key:
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
        "Reutiliza backend/services/ y backend/repositories/ — "
        "misma lógica de negocio que la app Streamlit."
    ),
    version="0.1.0",
    docs_url="/docs",    # Swagger UI: útil para probar endpoints manualmente
    redoc_url="/redoc",
    lifespan=lifespan,
)


# ── Middleware: logging de requests ───────────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Registra método, ruta, status code y tiempo de respuesta de cada request."""
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
    """Convierte excepciones no esperadas en JSON 500 consistente."""
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
# Flutter desde móvil no necesita CORS (no es browser), pero lo habilitamos
# por si se accede desde web o durante desarrollo.
_origins = [o.strip() for o in os.environ.get("CORS_ORIGINS", "*").split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(catalogo.router,     prefix="/api/v1/catalogo",     tags=["Catálogo"])
app.include_router(ventas.router,       prefix="/api/v1/ventas",       tags=["Ventas"])
app.include_router(cotizaciones.router, prefix="/api/v1/cotizaciones", tags=["Cotizaciones"])


@app.get("/health", tags=["Sistema"])
def health():
    """
    Health check para Render.
    Render llama a este endpoint cada ~30 s para mantener el servicio activo.
    Responde incluso si el repositorio no está disponible.
    """
    return {"status": "ok", "version": "0.1.0"}

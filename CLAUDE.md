# CLAUDE.md — Perfuteca Backend

FastAPI + Google Sheets (`gspread`). Frontend Flutter en `../perfuteca_flutter/`.

## Arquitectura

```
pythonProject/
├── backend/
│   ├── core/config.py              # Constantes, TZ Peru, helpers de formato
│   ├── models/                     # solo __init__.py (TypedDicts migrados a Pydantic)
│   ├── repositories/
│   │   └── sheets_repository.py   # SheetsRepository — toda la lógica gspread
│   ├── services/
│   │   ├── venta_service.py        # filtrar_catalogo, precio_catalogo
│   │   ├── costos_service.py       # MERMA_PCT, calcular_costo_ventas_df
│   │   ├── whatsapp_service.py     # generar_url_whatsapp()
│   │   └── pdf_service.py          # exportar_pdf_ventas_*()
│   ├── utils/
│   │   └── formatters.py           # construir_catalogo_dict, nombre_por_id
│   └── api/
│       ├── main.py                 # FastAPI app, CORS, GZip, logging, lifespan
│       ├── dependencies.py         # Singleton repo, TTLCache x3, auth X-API-Key, df_to_json
│       ├── models.py               # Pydantic: VentaRequest, CotizacionRequest, etc.
│       └── routes/
│           ├── catalogo.py         # GET /api/v1/catalogo/* — PÚBLICO
│           ├── ventas.py           # GET/POST/PUT /api/v1/ventas/* — X-API-Key
│           ├── cotizaciones.py     # GET/POST/PUT /api/v1/cotizaciones/* — X-API-Key
│           └── estadisticas.py     # GET /api/v1/estadisticas/* — X-API-Key
├── imagenes/                        # Fotos de perfumes por marca
├── render.yaml                      # Config deploy Render
├── DEPLOY_RENDER.md                 # Pasos de deploy con troubleshooting
└── requirements.txt
```

## Regla fundamental

`backend/` Python puro — sin `streamlit`/`st.*`. Todo importable desde FastAPI.

## Google Sheets

Spreadsheet: **"PERFUMES PYTHON"**

| Hoja | Propósito |
|---|---|
| `Catalogo` | `Marca`, `Nombre`, `ID_Perfume`, `Precio_2ml`, `Precio_5ml`, `Precio_10ml`, `Stock_ml` |
| `Ventas_Pendientes` | `ID_Compra`, `Fecha`, `Comprador`, `Celular`, `ID_Perfume`, `Ml_Vendido`, `Precio_Cobrado`, `Metodo_Pago`, `Tipo_Envio`, `Direccion`, `Distrito`, `Estado` |
| `Cotizaciones` | `ID_Cotizacion`, `Fecha`, `Celular`, `Items`, `Total`, `Estado` |

## Auth API

Endpoints protegidos requieren header `X-API-Key: <valor>`.
Catálogo es público (sin key).

## Variables de entorno

- `GCP_SERVICE_ACCOUNT` — JSON completo de credenciales Google
- `API_KEY` — clave para endpoints protegidos
- `CORS_ORIGINS` — default `*`

## Deploy Render

```
Start Command: uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1
```

## Constantes clave (`backend/core/config.py`)

```python
METODOS_PAGO         = ["Yape", "Plin", "Transferencia", "Tarjeta"]
TIPOS_ENVIO          = ["Shalom", "Motorizado", "Contraentrega"]
ML_OPCIONES          = [2, 5, 10]
ML_BASE_DISPENSACION = {2: 2.2, 5: 5.1}    # ml reales dispensados pre-merma
STOCK_CRITICO        = 10   # ml — badge rojo
STOCK_BAJO           = 20   # ml — badge amarillo
TZ_PERU = pytz.timezone("America/Lima")
```

## Estado de campos

- `Estado` ventas: `"Pendiente"` | `"Entregado"` | `"Anulado"` (anulados se filtran al cargar)
- `Estado` cotizaciones: `"Enviado"` | `"Confirmado"` | `"Anulado"` | `"Aceptada"`
- IDs compra: `V001`, `V002`...  — IDs cotización: `C001`, `C002`...

## Endpoints completos

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/health` | NO | Health check con versión y timestamp |
| GET | `/api/v1/config` | NO | Opciones app: ml_opciones, metodos_pago, tipos_envio, stock |
| GET | `/api/v1/catalogo/` | NO | Catálogo paginado con image_url |
| GET | `/api/v1/catalogo/marcas` | NO | Lista de marcas únicas |
| GET | `/api/v1/catalogo/buscar` | NO | Buscar por texto/marca |
| GET | `/api/v1/catalogo/{id}` | NO | Detalle de un perfume |
| GET | `/api/v1/ventas/` | X-API-Key | Lista ventas paginada (limit/offset/estado) |
| GET | `/api/v1/ventas/pendientes` | X-API-Key | Solo ventas con Estado=Pendiente |
| GET | `/api/v1/ventas/cliente/{celular}` | X-API-Key | Historial + datos cliente para autocompletar |
| POST | `/api/v1/ventas/` | X-API-Key | Registrar venta (invalida cache ventas + catálogo + stats) |
| PUT | `/api/v1/ventas/{id}/estado` | X-API-Key | Cambiar estado (usa fila_sheet del GET) |
| GET | `/api/v1/cotizaciones/` | X-API-Key | Lista cotizaciones paginada |
| GET | `/api/v1/cotizaciones/cliente/{celular}` | X-API-Key | Cotizaciones de un cliente |
| POST | `/api/v1/cotizaciones/` | X-API-Key | Guardar cotización (invalida cache cotizaciones) |
| PUT | `/api/v1/cotizaciones/{id}` | X-API-Key | Cambiar estado cotización |
| GET | `/api/v1/estadisticas/resumen` | X-API-Key | Métricas pre-agregadas (hoy, mes, semana, top perfumes) |
| GET | `/api/v1/estadisticas/clientes` | X-API-Key | Clientes agrupados con métricas, paginado |

## Cache (`dependencies.py` + `estadisticas.py`)

- Catálogo: TTL 30 min — invalida al registrar venta (stock cambia)
- Ventas: TTL 5 min (300 s) — invalida inmediato al POST/PUT venta via app
- Cotizaciones: TTL 5 min (300 s) — invalida inmediato al POST/PUT cotización; PUT usa `repo.fetch_quotes()` fresco para fila_sheet exacto
- Stats + Clientes (`estadisticas.py`): TTL 5 min — caché propio, invalida junto con ventas

## Stack

FastAPI + uvicorn · gspread + google-auth · fpdf2 · pytz(`America/Lima`) · tenacity · cachetools

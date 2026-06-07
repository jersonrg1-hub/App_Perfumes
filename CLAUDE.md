# CLAUDE.md — Perfuteca Backend

## Qué es este proyecto

Backend FastAPI para **Perfuteca**, app de gestión de una perfumería.
Consume datos de Google Sheets via `gspread`. Frontend: Flutter (en `perfuteca_flutter/`).

## Arquitectura

```
pythonProject/
├── backend/
│   ├── core/config.py              # Constantes, TZ Peru, helpers de formato
│   ├── models/schemas.py           # TypedDicts: ItemCesta, DatosCliente
│   ├── repositories/
│   │   └── sheets_repository.py   # SheetsRepository — toda la lógica gspread
│   ├── services/
│   │   ├── venta_service.py        # filtrar_catalogo, construir_item, validar_paso_cliente
│   │   ├── costos_service.py       # costo_total_item, MERMA_PCT, calcular_costo_ventas_df
│   │   ├── auth_service.py         # verificar_contrasena, segundos_restantes
│   │   ├── whatsapp_service.py     # generar_url_whatsapp()
│   │   └── pdf_service.py          # exportar_pdf_ventas_*()
│   ├── utils/
│   │   ├── validators.py           # validar_dataframe(), validar_celular()
│   │   └── formatters.py           # stock_badge_html, notas_pills_html, construir_catalogo_dict
│   └── api/
│       ├── main.py                 # FastAPI app, CORS, logging middleware, lifespan
│       ├── dependencies.py         # Singleton repo, TTLCache, auth X-API-Key, df_to_json
│       ├── models.py               # Pydantic: VentaRequest, CotizacionRequest, etc.
│       └── routes/
│           ├── catalogo.py         # GET /api/v1/catalogo/ — PÚBLICO
│           ├── ventas.py           # GET/POST/PUT /api/v1/ventas/ — X-API-Key
│           ├── cotizaciones.py     # GET/POST/PUT /api/v1/cotizaciones/ — X-API-Key
│           └── estadisticas.py     # GET /api/v1/estadisticas/ — X-API-Key
├── imagenes/                        # Fotos de perfumes por marca
├── render.yaml                      # Config deploy Render
├── DEPLOY_RENDER.md                 # Pasos de deploy con troubleshooting
└── requirements.txt
```

## Regla fundamental

`backend/` es Python puro — sin `streamlit`, sin `st.*`. Todo importable desde FastAPI directamente.

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
METODOS_PAGO  = ["Yape", "Plin", "Transferencia", "Tarjeta"]
TIPOS_ENVIO   = ["Shalom", "Motorizado"]
ML_OPCIONES          = [2, 5, 10]          # derivado de PRECIOS_COLUMNAS
ML_BASE_DISPENSACION = {2: 2.2, 5: 5.1}    # ml reales dispensados pre-merma (2ml→2.2ml, 5ml→5.1ml)
STOCK_CRITICO = 10   # ml — badge rojo
STOCK_BAJO    = 20   # ml — badge amarillo
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
| GET | `/api/v1/ventas/` | X-API-Key | Lista ventas paginada (limit/offset/estado) |
| GET | `/api/v1/ventas/pendientes` | X-API-Key | Solo ventas con Estado=Pendiente |
| GET | `/api/v1/ventas/cliente/{celular}` | X-API-Key | Historial + datos cliente para autocompletar |
| POST | `/api/v1/ventas/` | X-API-Key | Registrar venta (invalida cache ventas + catálogo + stats) |
| PUT | `/api/v1/ventas/{id}/estado` | X-API-Key | Cambiar estado (usa fila_sheet del GET) |
| GET | `/api/v1/cotizaciones/` | X-API-Key | Lista cotizaciones paginada |
| GET | `/api/v1/cotizaciones/cliente/{celular}` | X-API-Key | Cotizaciones de un cliente |
| POST | `/api/v1/cotizaciones/` | X-API-Key | Guardar cotización |
| PUT | `/api/v1/cotizaciones/{id}` | X-API-Key | Cambiar estado cotización |
| GET | `/api/v1/estadisticas/resumen` | X-API-Key | Métricas pre-agregadas (hoy, mes, semana, top perfumes) |

## Cache

- Catálogo: TTL 30 min (`dependencies.py`)
- Ventas: TTL 5 min (300 s) — invalida inmediato al POST/PUT venta via app
- Cotizaciones: TTL 5 min (300 s) — invalida inmediato al POST/PUT cotización via app; PUT usa `repo.fetch_quotes()` fresco para fila_sheet exacto
- Stats (`estadisticas.py`): TTL 5 min — caché local propio, invalida junto con ventas

## Repositorio git

- Remote: `https://github.com/jersonrg1-hub/App_Perfumes.git`
- Branch principal: `main`
- Operar siempre desde `pythonProject/`

## Stack

- **Backend**: FastAPI + uvicorn
- **Datos**: Google Sheets via gspread + google-auth
- **PDF**: fpdf2
- **Fechas/TZ**: pytz (`America/Lima`)
- **Retry**: tenacity
- **Frontend**: Flutter (`perfuteca_flutter/`)

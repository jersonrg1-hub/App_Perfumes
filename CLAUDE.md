# CLAUDE.md — Perfuteca Backend

FastAPI + Google Sheets (`gspread`). Frontend Flutter en `../perfuteca_flutter/`.

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

`backend/` Python puro — sin `streamlit`/`st.*`. Todo importable desde FastAPI.

## Google Sheets

Spreadsheet: **"PERFUMES PYTHON"**

| Hoja | Propósito |
|---|---|
| `Catalogo` | `Marca`, `Nombre`, `ID_Perfume`, `Precio_2ml`, `Precio_5ml`, `Precio_10ml`, `Stock_ml` |
| `Ventas_Pendientes` | `ID_Compra`, `Fecha`, `Comprador`, `Celular`, `ID_Perfume`, `Ml_Vendido`, `Precio_Cobrado`, `Metodo_Pago`, `Tipo_Envio`, `Direccion`, `Estado` |
| `Cotizaciones` | `ID_Cotizacion`, `Fecha`, `Celular`, `Items`, `Total`, `Estado` |

## Auth API

Endpoints protegidos requieren header `X-API-Key: <valor>`.
Catálogo es público (sin key).

## Variables de entorno

- `GCP_SERVICE_ACCOUNT` — JSON completo de credenciales Google
- `API_KEY` — clave para endpoints protegidos
- `CORS_ORIGINS` — default `*`

## Cache (TTLCache en `dependencies.py`)

- Catálogo: TTL 30 min
- Ventas: TTL 2 min

## Deploy Render

```
Start Command: uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1
```

## Constantes clave (`backend/core/config.py`)

```python
METODOS_PAGO = ["Yape", "Plin", "Transferencia", "Tarjeta"]
TIPOS_ENVIO  = ["Shalom", "Motorizado", "Contraentrega"]
STOCK_CRITICO = 5    # ml
STOCK_BAJO    = 15   # ml
TZ_PERU = pytz.timezone("America/Lima")
```

## Estado de campos

- `Estado` ventas: `"Pendiente"` | `"Entregado"` | `"Anulado"` (anulados se filtran al cargar)
- IDs compra: `V001`, `V002`...  — IDs cotización: `C001`, `C002`...

## Stack

FastAPI + uvicorn · gspread + google-auth · fpdf2 · pytz(`America/Lima`) · tenacity

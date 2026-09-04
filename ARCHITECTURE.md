# ARCHITECTURE.md — Perfuteca Backend

Detalle de estructura de carpetas y comportamiento de caché/escala. Referenciado desde CLAUDE.md — leer solo si se toca estructura de archivos o performance.

## Árbol de carpetas

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

## Cache

- Catálogo: TTL 30 min (`dependencies.py`)
- Ventas: TTL 5 min (300 s) — invalida inmediato al POST/PUT venta via app
- Cotizaciones: TTL 5 min (300 s) — invalida inmediato al POST/PUT cotización via app; PUT y conversión a venta usan `repo.fetch_quotes()` fresco (sin caché) para fila_sheet exacto
- Stats (`estadisticas.py`): TTL 5 min — caché local propio, invalida junto con ventas
- Caché es por-proceso (no Redis). Con `--workers 1` (ver Deploy Render) queda efectivamente compartido; si se sube a >1 worker, cada proceso cachea aparte y suben las llamadas a Sheets

## Escala

Probada OK hasta ~78 perfumes / 500 cotizaciones / 700 ventas — lecturas son 1 `get_all_records()` por hoja (batch, no loop). Único patrón O(N) real: anular venta con varias filas hace 1 llamada API por fila (`get_sale_row` en loop).

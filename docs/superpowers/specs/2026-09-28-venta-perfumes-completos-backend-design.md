# Venta de perfumes completos (frascos sellados) — Backend

## Objetivo

Permitir vender, además de los decants (2/5/10 ml), frascos completos sellados
de fábrica en tamaños libres (30, 50, 80, 90, 100, 150 ml, etc.), máximo 3
tamaños por perfume. Un "completo" es el mismo `ID_Perfume` que ya existe en
`Catalogo` — no es un producto aparte.

Alcance de este spec: **solo backend y modelo de datos en Sheets**. El UI de
Flutter para elegir un tamaño completo al armar una cotización/venta queda
para un spec siguiente.

## Decisiones de alcance (confirmadas con el usuario)

- Sin control de stock/cantidad de completos — solo precio. No hay unidades
  que descontar; se asume que se consiguen al vender.
- Tamaños libres por perfume (no un catálogo fijo de tamaños) — cada perfume
  puede tener hasta 3 tamaños completos, cada uno con su propio precio.
- Costeo/margen de completos en `costos_service.py` y estadísticas: fuera de
  alcance. Quedan sin costo calculado (costo = 0) hasta que se pida un spec
  de costeo para completos.
- UI de Flutter: fuera de alcance, spec aparte.

## Modelo de datos — Google Sheets

Nueva hoja **`Precios_Completos`** en el spreadsheet "PERFUMES PYTHON",
formato largo (una fila por tamaño):

| Columna | Tipo | Uso |
|---|---|---|
| `ID_Perfume` | texto/número | Clave real, igual que en `Catalogo`. Usada por el backend. |
| `Marca` | texto (fórmula `VLOOKUP`) | Solo referencia visual del usuario. Backend la ignora. |
| `Nombre` | texto (fórmula `VLOOKUP`) | Solo referencia visual del usuario. Backend la ignora. |
| `Ml` | número | Tamaño del frasco completo (sin la palabra "ml"). |
| `Precio` | número | Precio de venta del completo (sin "S/"). |

Un perfume sin completos simplemente no tiene filas en esta hoja. Ya creada
y verificada en el spreadsheet real (ver fila de ejemplo: ID 5, Burberry Her
edp, 50ml/100ml).

Filas con `ID_Perfume` vacío (arrastre de fórmulas más allá de los datos,
producen `#N/A` en Marca/Nombre) deben descartarse al leer.

## Backend (`pythonProject/backend`)

### Config (`backend/core/config.py`)

```python
WORKSHEET_PRECIOS_COMPLETOS = "Precios_Completos"
```

Regla para distinguir decant vs completo en cualquier punto del código:
`ml in ML_OPCIONES` (2, 5, 10) → decant; cualquier otro valor de `ml` →
completo. No se mantiene una lista de tamaños de completos en código porque
son libres por perfume.

### Repositorio (`backend/repositories/sheets_repository.py`)

Nuevo método:

```python
def fetch_precios_completos(self) -> pd.DataFrame:
    """Lee Precios_Completos. Columnas: ID_Perfume, Ml (int), Precio (float).
    Descarta filas con ID_Perfume vacío."""
```

Mismo patrón de reintento (`_ejecutar_con_reintento`) que el resto de fetches.

### Cache (`backend/api/dependencies.py`)

- Nuevo cache TTL 30 min para completos, **separado** del cache de
  `Catalogo` (mismo patrón que `get_catalogo_cached`, pero función/variable
  propia). Se mantiene separado para no tocar el schema del DataFrame de
  Catalogo que usan `update_stock_batch`, `_col_stock`, `COLUMNAS_REQUERIDAS`,
  etc. — cero riesgo de romper esa lógica existente.
- Expuesto como `dict[str, list[dict]]`: `{id_perfume: [{"ml": 50, "precio": 180.0}, ...]}`
  para lookup O(1) al serializar catálogo.
- `POST /catalogo/invalidar` invalida **ambos** caches (catálogo + completos).
  Es el mismo botón "reload" que ya usa Flutter en la pantalla de catálogo
  (`catalogo_provider.dart`) — con este cambio, ese botón también trae
  precios de completos actualizados desde Sheets, sin endpoint nuevo que
  llamar del lado Flutter.

### Modelos (`backend/api/models.py`)

```python
class CompletoPrecio(BaseModel):
    ml: int
    precio: float

class PerfumeResponse(BaseModel):
    ...
    completos: list[CompletoPrecio] = []
```

`ItemCestaAPI.ml` cambia de `Literal[2, 5, 10]` a `int` con validación de
rango (`gt=0, le=300`) — ya no hay una lista cerrada de tamaños válidos
porque los completos son libres por perfume. No se valida en el backend que
un `ml` puntual sea uno de los configurados para ese perfume específico —
Flutter solo va a ofrecer los tamaños que trae `completos` en el catálogo,
igual que hoy limita a 2/5/10.

### Serialización de catálogo (`backend/api/routes/catalogo.py`)

`_serializar_catalogo()` agrega `completos` a cada fila usando el dict
cacheado de precios completos, por `id_perfume`. Perfume sin completos →
`completos: []`. Viaja automáticamente en `GET /catalogo/`, `/buscar`,
`/{id_perfume}` — sin endpoint nuevo.

### Fix crítico — stock no debe tocarse por ítems completos

Sin este fix, vender o anular un completo (ej. 100ml) corrompería
`Stock_ml` del decant del mismo perfume, porque `_ml_con_merma()` no sabe
distinguir y aplicaría merma sobre un valor que no corresponde a ningún
pool de ml fraccionado.

Dos puntos a corregir, mismo criterio en ambos (`ml in ML_OPCIONES`):

1. **`SheetsRepository.register_complete_sale`** (venta nueva): antes de
   llamar `update_stock_batch(cesta, ...)`, filtrar `cesta` a solo ítems
   con `ml in ML_OPCIONES`. Los ítems completos se siguen guardando en
   `Ventas_Pendientes` igual que cualquier ítem (eso no cambia), solo se
   excluyen de la escritura de `Stock_ml`.

2. **`backend/api/routes/ventas.py`, anulación de venta** (~línea 316,
   construcción de `filas_para_restock`): mismo filtro antes de armar
   `items_anulados`, para que reponer stock al anular tampoco toque
   completos.

Sin este filtro en cualquiera de los dos puntos, el bug es silencioso: no
lanza error, simplemente corrompe `Stock_ml` de forma incorrecta.

### Sin cambios necesarios

- `cotizacion_service.py` (`construir_items_txt`, `calcular_total_cotizacion`,
  `aplicar_descuentos`) — ya genéricos por `ml`/`precio`, funcionan tal cual
  para cualquier tamaño.
- `COLUMNAS_VENTAS` / `Ml_Vendido` — columna genérica, ya acepta cualquier
  entero.
- `precio_catalogo()` en `venta_service.py` — no se usa para completos (esos
  vienen del dict de `Precios_Completos`, no de columnas `Precio_Xml`).

## Fuera de alcance (YAGNI, confirmado)

- Stock/cantidad de completos.
- Costeo y márgenes de completos en `costos_service.py` / estadísticas.
- UI Flutter para elegir tamaño completo (spec aparte).
- Validación backend de que un `ml` enviado corresponda exactamente a un
  tamaño configurado para ese perfume (se confía en que Flutter solo ofrece
  los tamaños válidos, igual que hoy con decants).

## Testing

- Backend: test unitario de `fetch_precios_completos` (filtra filas con
  `ID_Perfume` vacío), de la serialización de `completos` en
  `PerfumeResponse`, y — el más importante — que `update_stock_batch` /
  `restore_stock_batch` **no reciban** ítems con `ml` fuera de `ML_OPCIONES`
  (test de regresión para el fix crítico de stock).
- Verificar manualmente: invalidar catálogo tras editar un precio en
  `Precios_Completos` y confirmar que `GET /catalogo/{id}` refleja el nuevo
  valor en `completos`.

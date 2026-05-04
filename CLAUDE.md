# CLAUDE.md — Perfumería App

## Qué es este proyecto

App web de gestión para una **perfumería**, construida con **Streamlit** y desplegada como webapp.
Permite buscar perfumes por marca/nombre/notas olfativas, registrar ventas, gestionar pedidos pendientes,
ver estadísticas, generar cotizaciones y exportar reportes PDF.

## Stack tecnológico

- **Frontend/Backend**: Streamlit (Python)
- **Base de datos**: Google Sheets (via `gspread` + `google-auth`)
- **Credenciales**: `st.secrets` — archivo `.streamlit/secrets.toml` (no commitear)
- **PDF**: `fpdf2`
- **Gráficos**: `plotly`
- **Fechas/TZ**: `pytz`, zona horaria `America/Lima`
- **IDE**: PyCharm

## Estructura del proyecto

```
app.py                  # Punto de entrada — configura página, auth, carga df, renderiza tabs
auth.py                 # Login por contraseña (hmac), sesión en st.session_state
config.py               # Constantes globales, helpers de fecha/precio/stock, badges HTML
data.py                 # Capa de datos — gspread, cache @st.cache_data/@st.cache_resource
components.py           # Componentes reutilizables (encabezado, WhatsApp URL, separador)
styles.py               # Módulo de compatibilidad (re-exporta desde styles/)
errores.py              # Helpers para mostrar errores de conexión/datos/columnas
pdf_generator.py        # Exportación PDF de ventas del día con fpdf2
convertir.py            # Utilidades de conversión de datos

tabs/
  tab_marca.py          # Buscar por marca
  tab_nombre.py         # Buscar por nombre
  tab_notas.py          # Buscar por notas olfativas
  tab_venta.py          # Wizard 3 pasos: cliente → perfumes → confirmar
  tab_cotizacion.py     # Generar cotizaciones (dentro de tab_venta)
  tab_estadisticas.py   # Dashboard de estadísticas

estadisticas/
  resumen.py            # Resumen general del día/semana
  semanal.py            # Vista semanal
  historial.py          # Historial de ventas
  historial_cotizaciones.py
  pendientes.py         # Pedidos pendientes (marcar como entregado)
  clientes.py           # Análisis por cliente
  graficos.py           # Gráficos plotly
  stock.py              # Alertas de stock
  tamanios.py           # Ventas por tamaño (ml)

styles/
  base.py, components.py, forms.py, tabs.py, animations.py, mobile.py

imagenes/               # Fotos de perfumes (por marca)
```

## Google Sheets

Spreadsheet: **"PERFUMES PYTHON"**

| Hoja               | Propósito                                      |
|--------------------|------------------------------------------------|
| `Catalogo`         | Inventario — columnas: `Marca`, `Nombre`, `ID_Perfume`, `Precio_2ml`, `Precio_5ml`, `Precio_10ml`, `Stock_ml` |
| `Ventas_Pendientes`| Registro de ventas — columnas: `ID_Compra`, `Fecha`, `Comprador`, `Celular`, `ID_Perfume`, `Ml_Vendido`, `Precio_Cobrado`, `Metodo_Pago`, `Tipo_Envio`, `Direccion`, `Estado` |
| `Cotizaciones`     | Cotizaciones — columnas: `ID_Cotizacion`, `Fecha`, `Celular`, `Items`, `Total`, `Estado` |

## Cache y rendimiento

- `get_cliente()` / `get_spreadsheet()` → `@st.cache_resource` (singleton de conexión)
- `cargar_catalogo()` → `@st.cache_data(ttl=300)` — limpiar con `limpiar_cache_catalogo()`
- `cargar_ventas()` → `@st.cache_data(ttl=120)` — limpiar con `limpiar_cache_ventas()`
- `cargar_cotizaciones()` → `@st.cache_data(ttl=120)` — limpiar con `limpiar_cache_cotizaciones()`
- Las escrituras siempre usan `batch_update` y limpian el cache correspondiente

## Autenticación

- Login simple por contraseña en `st.secrets["APP_PASSWORD"]`
- Máximo 3 intentos, luego bloqueo
- Protege tabs "Venta" y "Estadísticas"
- Estado en `st.session_state.autenticado`

## Flujo de venta (wizard 3 pasos)

1. **Paso 1** — Datos del cliente (nombre, celular, dirección, envío, fecha)
   - Autocomplete si el celular ya tiene historial
2. **Paso 2** — Agregar perfumes a la cesta
   - Muestra precio y alerta de stock (crítico ≤5ml, bajo ≤15ml)
3. **Paso 3** — Confirmar y guardar
   - Guarda en Sheets, descuenta stock, genera URL de WhatsApp con comprobante

## Constantes importantes (config.py)

```python
PRECIOS_COLUMNAS = {"2 ml": "Precio_2ml", "5 ml": "Precio_5ml", "10 ml": "Precio_10ml"}
METODOS_PAGO = ["Yape", "Plin", "Transferencia", "Tarjeta"]   # Efectivo eliminado
TIPOS_ENVIO = ["Shalom", "Motorizado", "Contraentrega"]
STOCK_CRITICO = 5   # ml
STOCK_BAJO = 15     # ml
TZ_PERU = pytz.timezone("America/Lima")
```

## Sistema de diseño CSS

Los estilos se inyectan via `st.markdown(..., unsafe_allow_html=True)` desde `styles/` y se concatenan en `styles.py`.

### Archivos de estilos
| Archivo | Contenido |
|---|---|
| `styles/base.py` | Variables CSS (`:root`), tipografía, botones, alertas, animaciones |
| `styles/components.py` | `.perfume-card`, `.precio-chip`, `.precio-box`, `.perfume-item`, inputs, expanders |
| `styles/tabs.py` | Barra de tabs, pestaña activa/inactiva, panel de contenido |
| `styles/forms.py` | Estilos específicos de formularios |
| `styles/mobile.py` | Media queries responsive |

### Variables CSS clave (`:root` en `base.py`)
```css
--c-primary: #b8724a          /* terracota oscuro */
--c-primary-light: #c8956c    /* terracota principal */
--c-primary-pale: #f0ddd0     /* terracota suave (hover) */
--c-gold: #c9a96e             /* dorado (perfil olfativo) */
--c-bg: #faf4ed               /* fondo app */
--c-bg-card: #ffffff          /* fondo tarjetas */
--c-text: #1e1209             /* texto principal */
--c-text-mid: #4a2e18         /* texto secundario */
--c-text-muted: #8b6640       /* texto atenuado / labels */
--c-text-faint: #b89878       /* texto muy claro / sin precio */
--shadow-xs/sm/md/lg          /* escala de sombras */
--radius-sm/md/lg/xl          /* escala de radios (8/12/16/20px) */
```

### Componentes visuales clave
- **`.perfume-card`** — tarjeta con `border-left: 3px solid var(--c-primary-light)`, hover con elevación
- **`.precio-chip`** — chip de precio con `flex:1` para ocupar ancho completo; `.chip-label` (ml) + `.chip-valor` (precio)
- **`.precio-box`** — caja grande de precio en tab_nombre; usa `.separador-box` (línea dorada) y `.moneda` (S/)
- **`.titulo-app`** — degradado via `background-clip: text` (-webkit)

### Convenciones de notas/perfil olfativo
- Label **"Notas"**: `color: var(--c-primary-light)` (terracota), `font-size: 0.7rem`, `font-weight: 700`, uppercase
- Label **"Perfil olfativo"**: `color: var(--c-gold)` (dorado), misma tipografía que Notas
- Texto de ambos: `color: var(--c-text-mid)`, `font-size: 0.92rem` (tab_marca) / `0.88rem` (tab_nombre), sin cursiva

### Fuentes Google (cargadas en `app.py` o `base.py`)
- `Playfair Display` — títulos, nombres de perfumes, precios grandes
- `Lato` — cuerpo, labels, botones
- `Inter` — valores numéricos (`font-variant-numeric: tabular-nums`)

## Tema visual

Paleta terrosa/cálida (`.streamlit/config.toml`):
- `primaryColor`: `#c8956c` (terracota)
- `backgroundColor`: `#faf5f0`
- `textColor`: `#2c1a0e` (marrón oscuro)

## Repositorio git

- El código vive en `pythonProject/` que tiene su **propio `.git`** (repo anidado, no submodule)
- Remote: `https://github.com/jersonrg1-hub/App_Perfumes.git`
- Branch principal: `main`
- Para hacer commit/push, operar desde dentro de `pythonProject/`, no desde el directorio padre

## Trampas conocidas / lecciones aprendidas

### Streamlit
- `st.success("### Título")` y `st.info("### Título")` **no renderizan Markdown**; el `###` aparece literal.
  Solución: separar en `st.markdown("### Título")` + `st.success("Mensaje")`.
- El bloque `except Exception` genérico nunca debe llamar a `mostrar_error_conexion()` directamente;
  cualquier bug de código mostraría "Sin conexión" al usuario. Usar `st.error(f"Error: {type(e).__name__}")`.
- Los imports siempre al top del módulo, nunca dentro de bloques `except`.

### JavaScript inyectado en `app.py`
- **Guard global obligatorio**: cualquier `document.addEventListener` que se registre dentro de un loop
  de elementos (p.ej. filas de la cesta) debe estar protegido con `window.__miGuard` para no acumular
  listeners duplicados en cada re-render de Streamlit.
- **Estado en el DOM**: para que listeners globales accedan al estado de un elemento, exponerlo en el
  propio nodo (`row._snap`, `row._revealed`) en lugar de cerrar sobre variables locales que se pierden.
- Los MutationObservers del swipe ya usan `requestAnimationFrame` como debounce (`_swipeRAF`).

## Comandos útiles

```bash
# Ejecutar la app
streamlit run app.py

# Instalar dependencias
pip install -r requirements.txt
```

## Notas importantes

- `credenciales.json` y `.streamlit/secrets.toml` contienen claves privadas — NO commitear
- `fila_sheet` en el DataFrame de ventas guarda la fila real en Sheets (para batch_update)
- El campo `Estado` puede ser: `"Pendiente"`, `"Entregado"`, `"Anulado"` (los anulados se filtran al cargar)
- IDs de compra: formato `V001`, `V002`... — IDs de cotización: `C001`, `C002`...

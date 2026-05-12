# Deploy en Render — Perfuteca API

Pasos exactos para dejar la API funcionando en Render desde cero.

---

## Requisitos previos

- Cuenta en [render.com](https://render.com) (gratis)
- Repo en GitHub con el proyecto
- Archivo `credenciales.json` de Google Cloud (service account)

---

## Paso 1 — Preparar `GCP_SERVICE_ACCOUNT`

El archivo `credenciales.json` se pasa como variable de entorno en Render
(no se commitea al repo).

En tu terminal, convierte el archivo a una línea:

```bash
# Windows PowerShell
Get-Content credenciales.json -Raw

# Mac / Linux
cat credenciales.json
```

Copia todo el contenido (es un JSON de varias líneas). Lo pegarás en el Paso 4.

---

## Paso 2 — Crear API Key

Genera una clave secreta larga y aleatoria. Cualquiera de estas formas sirve:

```bash
# Python
python -c "import secrets; print(secrets.token_hex(32))"

# PowerShell
[System.Convert]::ToBase64String((1..32 | % { [byte](Get-Random -Max 256) }))
```

Guarda esta clave — la necesitarás en el Paso 4 y en tu app Flutter/celular.

---

## Paso 3 — Conectar repo en Render

1. Entra a [render.com/dashboard](https://dashboard.render.com)
2. Click **New +** → **Web Service**
3. Conecta tu cuenta de GitHub si no está conectada
4. Selecciona el repositorio del proyecto
5. Render detectará `render.yaml` automáticamente

Si no usa `render.yaml`, configura manualmente:
- **Environment:** Python
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1`
- **Health Check Path:** `/health`

---

## Paso 4 — Configurar variables de entorno

En Render → tu servicio → **Environment** → **Add Environment Variable**:

| Variable | Valor | Obligatoria |
|---|---|---|
| `GCP_SERVICE_ACCOUNT` | Contenido completo de `credenciales.json` (JSON en una línea) | ✅ Sí |
| `API_KEY` | Clave generada en Paso 2 (ej: `a3f9...`) | ✅ Sí |
| `CORS_ORIGINS` | `*` para desarrollo; URL de Flutter en producción | No |

> **Importante:** `GCP_SERVICE_ACCOUNT` debe ser el JSON completo, incluyendo
> las llaves `{` `}` y todos los campos. Render lo trata como string.

---

## Paso 5 — Hacer el primer deploy

1. Click **Deploy** en Render
2. Render ejecuta: `pip install -r requirements.txt`
3. Luego arranca: `uvicorn backend.api.main:app --host 0.0.0.0 --port $PORT --workers 1`
4. En los logs deberías ver:
   ```
   ✓ Repositorio Google Sheets listo
   ✓ Autenticación X-API-Key activa
   ```
5. La URL pública queda como: `https://perfuteca-api.onrender.com`

---

## Paso 6 — Verificar que funciona

```bash
# Health check (sin API Key)
curl https://perfuteca-api.onrender.com/health

# Respuesta esperada:
# {"status":"ok","version":"0.1.0"}

# Catálogo (sin API Key, endpoint público)
curl https://perfuteca-api.onrender.com/api/v1/catalogo/

# Endpoint protegido (con API Key)
curl -H "X-API-Key: TU_API_KEY_AQUI" \
     https://perfuteca-api.onrender.com/api/v1/ventas/pendientes
```

Swagger UI completo: `https://perfuteca-api.onrender.com/docs`

---

## Cómo usar desde el celular

Cualquier cliente HTTP funciona. En el navegador del celular:

```
https://perfuteca-api.onrender.com/docs
```

Desde allí puedes probar todos los endpoints interactivamente.
Para los endpoints con API Key, usa el botón 🔒 **Authorize** en Swagger.

---

## Comportamiento en free tier de Render

| Situación | Qué ocurre |
|---|---|
| **Inactividad >15 min** | El servicio se "duerme" — el primer request tarda 20-30 seg en despertar |
| **Uso normal** | Respuestas en 100-500 ms (desde caché) o 1-3 seg (carga de Sheets) |
| **Rate limit de Sheets** | La API reintenta automáticamente con backoff exponencial |
| **Memoria** | ~200-250 MB en uso normal — dentro del límite de 512 MB |

> Para evitar el cold start, puedes hacer un request periódico a `/health`
> desde tu celular cada 10-14 minutos, o usar un servicio como UptimeRobot (gratis).

---

## Deploys automáticos

Con `render.yaml` en el repo, cada `git push` a `main` hace deploy automático.

Para desactivarlo: Render → servicio → **Settings** → **Auto-Deploy** → Off.

---

## Variables de entorno para desarrollo local

Crea un archivo `.env` en la raíz del proyecto (no commitear):

```env
# .env — Solo para desarrollo local
API_KEY=cualquier-clave-para-pruebas
CORS_ORIGINS=*
# GCP_SERVICE_ACCOUNT no es necesario si tienes credenciales.json local
```

O simplemente exporta en tu terminal:

```bash
export API_KEY=mi-clave-local
uvicorn backend.api.main:app --reload
```

---

## Troubleshooting

**"Credenciales GCP no encontradas"**
→ Verifica que `GCP_SERVICE_ACCOUNT` está configurada en Render Environment.
→ El valor debe ser el JSON completo (incluidas las llaves `{}`).

**"Error al cargar catálogo: 429"**
→ Rate limit de Google Sheets API. El repositorio reintenta automáticamente.
→ Si persiste: el catálogo se cargará en el siguiente request (cache expirado).

**"X-API-Key inválida o ausente"**
→ Verifica que envías el header `X-API-Key: TU_CLAVE` en el request.
→ La clave debe coincidir exactamente con la variable `API_KEY` en Render.

**Cold start lento (20-30 seg)**
→ Normal en free tier. El servicio se duerme tras 15 min sin requests.
→ Solución: UptimeRobot gratuito haciendo ping a `/health` cada 14 min.

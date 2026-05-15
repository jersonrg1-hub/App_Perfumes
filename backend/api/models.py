"""
backend/api/models.py — Modelos Pydantic para la API REST.

Separación clara:
  REQUEST models  → validan lo que Flutter/cliente envía al servidor
  RESPONSE models → tipan lo que el servidor devuelve a Flutter

Convención de nombres en responses:
  snake_case en todos los campos — estándar Dart/Flutter.
  Los TypedDicts internos (backend/models/schemas.py) siguen siendo para uso interno.

Modelo de paginación:
  Todos los endpoints de lista devuelven Paginated[T] con metadata.
  Flutter puede implementar infinite scroll con has_more + offset.
"""
from typing import Generic, Optional, TypeVar
from pydantic import BaseModel, Field

T = TypeVar("T")


# ── Paginación genérica ───────────────────────────────────────────────────────

class Paginated(BaseModel, Generic[T]):
    """
    Respuesta paginada estándar para todos los endpoints de lista.

    Flutter usa:
      - items     → lista de objetos a renderizar
      - total     → total de registros (para "X perfumes encontrados")
      - has_more  → si hay más páginas (para infinite scroll)
      - offset    → posición actual (para la siguiente llamada: offset += limit)
    """
    items: list[T]
    total: int
    limit: int
    offset: int
    has_more: bool


# ── Catálogo — Responses ──────────────────────────────────────────────────────

class PerfumeResponse(BaseModel):
    """
    Perfume serializado para Flutter.
    Todos los campos en snake_case — Dart json_serializable los mapea directamente.
    image_url: URL relativa servida por FastAPI StaticFiles (/imagenes/...).
               None si no hay imagen disponible para ese perfume.
    """
    id_perfume: str
    marca: str
    nombre: str
    precio_2ml: Optional[float] = None
    precio_5ml: Optional[float] = None
    precio_10ml: Optional[float] = None
    stock_ml: Optional[float] = None
    notas: Optional[str] = None
    perfil_olfativo: Optional[str] = None
    image_url: Optional[str] = None
    ocasion: Optional[str] = None
    estacion: Optional[str] = None
    hora: Optional[str] = None


# ── Ventas — Responses ────────────────────────────────────────────────────────

class VentaResponse(BaseModel):
    """
    Venta individual para Flutter.
    fila_sheet es un detalle interno de Google Sheets — Flutter lo guarda
    y lo envía en PUT /{id}/estado para actualizar el estado.
    En una futura migración a PostgreSQL este campo desaparece.
    """
    id_compra: str
    fecha: Optional[str] = None
    comprador: str
    celular: str
    id_perfume: str
    ml_vendido: Optional[int] = None
    precio_cobrado: Optional[float] = None
    metodo_pago: Optional[str] = None
    tipo_envio: Optional[str] = None
    direccion: Optional[str] = None
    estado: Optional[str] = None
    fila_sheet: Optional[int] = None


class ClientePrevioResponse(BaseModel):
    """
    Datos del último pedido de un cliente, para autocompletar el checkout en Flutter.
    Flutter llama a GET /ventas/cliente/{celular} y pre-rellena el formulario.
    """
    comprador: str
    direccion: str
    tipo_envio: str
    metodo_pago: str
    total_compras: int


# ── Cotizaciones — Responses ──────────────────────────────────────────────────

class CotizacionResponse(BaseModel):
    """Cotización individual para Flutter."""
    id_cotizacion: str
    fecha: Optional[str] = None
    celular: str
    items: Optional[str] = None
    total: Optional[float] = None
    estado: Optional[str] = None
    fila_sheet: Optional[int] = None


# ── Config de la app ──────────────────────────────────────────────────────────

class AppConfig(BaseModel):
    """
    Configuración de la app para Flutter.
    Flutter llama a GET /api/v1/config al arrancar para poblar dropdowns
    sin hardcodear opciones en el cliente.
    """
    ml_opciones: list[int]
    metodos_pago: list[str]
    tipos_envio: list[str]
    stock_critico_ml: int
    stock_bajo_ml: int
    version: str


# ── Ventas — Requests ─────────────────────────────────────────────────────────

class ItemCestaAPI(BaseModel):
    """
    Item de cesta de compra.
    Campos coinciden con ItemCesta TypedDict — item.model_dump() se pasa directo
    a register_complete_sale() sin conversión adicional.
    """
    perfume: str
    marca: str
    id_perfume: str
    ml: int = Field(..., ge=1, description="Tamaño en ml: 2, 5 o 10")
    precio: float = Field(..., ge=0)
    metodo: str = Field(..., description="Yape | Plin | Transferencia | Tarjeta")


class VentaRequest(BaseModel):
    """
    Body de POST /ventas/.
    Campos del cliente coinciden con DatosCliente TypedDict.
    body.model_dump(exclude={'items'}) se pasa directo a register_complete_sale().
    """
    comprador: str = Field(..., min_length=1)
    celular: str = Field(
        ..., min_length=9, max_length=9, pattern=r"^\d{9}$",
        description="9 dígitos sin código de país (ej: 987654321)",
    )
    direccion: str = Field(..., min_length=1)
    tipo_envio: str = Field(..., description="Shalom | Motorizado | Contraentrega")
    fecha: str = Field(..., description="Fecha ISO: YYYY-MM-DD")
    items: list[ItemCestaAPI] = Field(..., min_length=1)


class VentaRegistrada(BaseModel):
    """Response de POST /ventas/."""
    id_compra: str
    warning: Optional[str] = None


class EstadoVentaUpdate(BaseModel):
    """Body para PUT /ventas/{id}/estado."""
    nuevo_estado: str = Field(..., description="Pendiente | Entregado | Anulado")
    fila_sheet: int = Field(..., ge=2, description="Campo fila_sheet del objeto venta")


# ── Cotizaciones — Requests ───────────────────────────────────────────────────

class CotizacionRequest(BaseModel):
    celular: str = Field(..., min_length=9, max_length=9, pattern=r"^\d{9}$")
    items: list[ItemCestaAPI] = Field(..., min_length=1)
    total: float = Field(..., ge=0)


class CotizacionRegistrada(BaseModel):
    id_cotizacion: str


class EstadoCotizacionUpdate(BaseModel):
    """Body para PUT /cotizaciones/{id}."""
    nuevo_estado: str = Field(..., description="Enviado | Confirmado | Anulado")
    fila_sheet: int = Field(..., ge=2)

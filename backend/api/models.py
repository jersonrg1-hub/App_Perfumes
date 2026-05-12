"""
backend/api/models.py — Modelos Pydantic para requests y responses de la API.

Propósito: validación de HTTP bodies y definición del contrato público de la API.

Separación de capas:
  HTTP body  → Pydantic (valida y deserializa)
  Pydantic   → .model_dump() → dict/list → Service / Repository

Los TypedDicts en backend/models/schemas.py son para uso interno del backend.
Estos modelos son la interfaz pública (lo que Flutter envía y recibe).
"""
from typing import Optional
from pydantic import BaseModel, Field


# ── Catálogo ──────────────────────────────────────────────────────────────────

class PerfumeDetalle(BaseModel):
    """Perfume con todos los campos públicos — pantalla de detalle en Flutter."""
    ID_Perfume: str
    Marca: str
    Nombre: str
    Precio_2ml: Optional[float] = None
    Precio_5ml: Optional[float] = None
    Precio_10ml: Optional[float] = None
    Stock_ml: Optional[float] = None
    Notas: Optional[str] = None
    Perfil_Olfativo: Optional[str] = None


# ── Ventas ────────────────────────────────────────────────────────────────────

class ItemCestaAPI(BaseModel):
    """
    Item de cesta de compra.

    Los campos coinciden exactamente con el TypedDict ItemCesta del backend,
    por lo que item.model_dump() puede pasarse directamente a register_complete_sale().
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

    Los campos del cliente (comprador, celular, etc.) coinciden con DatosCliente
    TypedDict del backend — body.model_dump(exclude={'items'}) se pasa directo
    a register_complete_sale() sin conversión adicional.
    """
    comprador: str = Field(..., min_length=1)
    celular: str = Field(
        ...,
        min_length=9,
        max_length=9,
        pattern=r"^\d{9}$",
        description="9 dígitos, sin código de país (ej: 987654321)",
    )
    direccion: str = Field(..., min_length=1)
    tipo_envio: str = Field(..., description="Shalom | Motorizado | Contraentrega")
    fecha: str = Field(..., description="Fecha ISO: YYYY-MM-DD")
    items: list[ItemCestaAPI] = Field(..., min_length=1)


class VentaRegistrada(BaseModel):
    """Response de POST /ventas/ — ID asignado y advertencia opcional."""
    id_compra: str
    warning: Optional[str] = None


class EstadoVentaUpdate(BaseModel):
    """
    Body para PUT /ventas/{id}/estado.

    fila_sheet es la fila real en Google Sheets.
    Flutter debe guardar este campo al obtener la lista de ventas,
    para poder actualizar el estado después.
    """
    nuevo_estado: str = Field(..., description="Pendiente | Entregado | Anulado")
    fila_sheet: int = Field(..., ge=2, description="Campo fila_sheet del objeto venta")


# ── Cotizaciones ──────────────────────────────────────────────────────────────

class CotizacionRequest(BaseModel):
    celular: str = Field(..., min_length=9, max_length=9, pattern=r"^\d{9}$")
    items: list[ItemCestaAPI] = Field(..., min_length=1)
    total: float = Field(..., ge=0)


class CotizacionRegistrada(BaseModel):
    id_cotizacion: str


class EstadoCotizacionUpdate(BaseModel):
    """
    Body para PUT /cotizaciones/{id}.

    fila_sheet es la fila real en Google Sheets (campo fila_sheet al listar).
    """
    nuevo_estado: str = Field(..., description="Enviado | Confirmado | Anulado")
    fila_sheet: int = Field(..., ge=2)

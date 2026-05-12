"""
backend/models/schemas.py — Modelos de datos de la aplicación.

Contiene los TypedDicts que definen la estructura de los datos de negocio.
Sin dependencias de Streamlit — reutilizable directamente en FastAPI.

Futuro: migrar a Pydantic BaseModel cuando se active el backend FastAPI,
para obtener validación automática en los endpoints REST.
"""
from typing import TypedDict


class ItemCesta(TypedDict):
    """Representa un perfume en la cesta de compra o cotización."""
    perfume: str
    marca: str
    id_perfume: str
    ml: int
    precio: float
    metodo: str


class DatosCliente(TypedDict):
    """Datos del comprador necesarios para registrar una venta."""
    comprador: str
    celular: str
    direccion: str
    tipo_envio: str
    fecha: str        # formato ISO: "YYYY-MM-DD"

"""
backend/repositories/sheets_repository.py — Acceso a Google Sheets sin Streamlit.

Decisión de arquitectura: toda la lógica de red (gspread) vive en esta clase.
No hay @st.cache_resource ni @st.cache_data aquí — esas son decisiones del
consumidor (Streamlit en frontend/streamlit/cache_adapters.py, FastAPI con
su propio cache, tests con mocks).

Uso desde Streamlit:  frontend/streamlit/cache_adapters.py
Uso desde FastAPI:    instanciar SheetsRepository con credenciales de os.environ
Uso desde tests:      instanciar con credenciales de fixture o mock

Logging: usa el módulo estándar 'logging' en lugar de st.session_state,
para que funcione igual en Streamlit, FastAPI y tests.
"""
import re
import logging
import gspread
import gspread.exceptions
import gspread.utils
import pandas as pd
from datetime import date as date_type, timedelta
from google.oauth2.service_account import Credentials
from tenacity import retry, wait_exponential, stop_after_attempt, retry_if_exception

from backend.core.config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS, WORKSHEET_COTIZACIONES,
    hoy_peru, fmt_precio, ML_BASE_DISPENSACION,
)
from backend.models.schemas import ItemCesta, DatosCliente

logger = logging.getLogger(__name__)


class StockUpdateError(Exception):
    """La venta se guardó correctamente pero el descuento de stock falló."""
    def __init__(self, id_compra: str, causa: Exception):
        self.id_compra = id_compra
        self.causa = causa
        super().__init__(str(causa))


class SheetsRepository:
    """
    Encapsula todo el acceso a datos de Google Sheets.

    Sin dependencias de Streamlit — puede usarse desde cualquier contexto
    (FastAPI, scripts, tests). El caching es responsabilidad del consumidor.

    Ejemplo de uso en FastAPI:
        import os, json
        from backend.repositories.sheets_repository import SheetsRepository
        creds = json.loads(os.environ["GCP_SERVICE_ACCOUNT"])
        repo = SheetsRepository(creds)
        df = repo.fetch_catalog()
    """

    def __init__(self, credentials_info: dict):
        self._credentials_info = credentials_info
        self._client: gspread.Client | None = None
        self._spreadsheet: gspread.Spreadsheet | None = None
        self._worksheets: dict[str, gspread.Worksheet] = {}

    # ── Conexión ──────────────────────────────────────────────────────────────

    def _get_client(self) -> gspread.Client:
        if self._client is None:
            creds = Credentials.from_service_account_info(
                self._credentials_info, scopes=SCOPES
            )
            self._client = gspread.authorize(creds)
        return self._client

    def _get_spreadsheet(self) -> gspread.Spreadsheet:
        if self._spreadsheet is None:
            self._spreadsheet = self._get_client().open(SHEET_NAME)
        return self._spreadsheet

    def _get_worksheet(self, name: str) -> gspread.Worksheet:
        if name not in self._worksheets:
            self._worksheets[name] = self._get_spreadsheet().worksheet(name)
        return self._worksheets[name]

    def invalidate_connection(self) -> None:
        """Fuerza reconexión en el próximo acceso (útil tras errores de red)."""
        self._client = None
        self._spreadsheet = None
        self._worksheets.clear()

    # ── Resiliencia ───────────────────────────────────────────────────────────

    @staticmethod
    def _es_rate_limit(exc: Exception) -> bool:
        return (
            isinstance(exc, gspread.exceptions.APIError)
            and getattr(getattr(exc, "response", None), "status_code", None) == 429
        )

    def _ejecutar_con_reintento(self, fn, contexto: str):
        """
        Envuelve fn() con resiliencia ante errores de la API de Google.
        - 429 Rate Limit: backoff exponencial (2s → 60s, 5 intentos)
        - Otros errores de API: reconecta y reintenta una vez
        """
        @retry(
            retry=retry_if_exception(self._es_rate_limit),
            wait=wait_exponential(multiplier=1, min=2, max=60),
            stop=stop_after_attempt(5),
            reraise=True,
        )
        def _intentar():
            return fn()

        try:
            return _intentar()
        except Exception as e:
            if self._es_rate_limit(e):
                logger.error(f"[{contexto}] Rate limit persistente tras 5 intentos")
                raise
            logger.warning(f"[{contexto}] {type(e).__name__} — reconectando y reintentando...")
            self.invalidate_connection()
            return fn()

    # ── Helpers internos ──────────────────────────────────────────────────────

    @staticmethod
    def _make_tag_set(valor_str) -> frozenset:
        """Normaliza un CSV de etiquetas a frozenset para filtrado O(1)."""
        if not valor_str or str(valor_str).strip().lower() in ("", "nan", "none"):
            return frozenset()
        return frozenset(
            v.strip().lower().capitalize()
            for v in str(valor_str).split(",")
            if v.strip()
        )

    @staticmethod
    def _parse_fecha(v):
        """Convierte serial numérico de Sheets o string a pd.Timestamp."""
        if v is None or v == "":
            return pd.NaT
        if isinstance(v, (int, float)):
            try:
                return pd.Timestamp(date_type(1899, 12, 30) + timedelta(days=int(v)))
            except Exception:
                return pd.NaT
        return pd.to_datetime(str(v).strip(), errors="coerce")

    @staticmethod
    def _extraer_ids_numericos(ids_col) -> list[int]:
        return [
            int(m.group(1))
            for id_val in ids_col
            if (m := re.search(r"(\d+)", str(id_val)))
        ]

    # ── Lecturas ──────────────────────────────────────────────────────────────

    def fetch_catalog(self) -> pd.DataFrame:
        """Carga el catálogo completo y lo enriquece con columnas pre-computadas."""
        def _fetch():
            return self._get_worksheet(WORKSHEET_CATALOGO).get_all_records(
                value_render_option="UNFORMATTED_VALUE"
            )

        datos = self._ejecutar_con_reintento(_fetch, "fetch_catalog")
        df = pd.DataFrame(datos)

        if not df.empty:
            df["fila_sheet"] = range(2, len(df) + 2)
            for col in ["precio", "costo", "ml_disponibles", "stock", "Stock_ml"]:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

            # Columnas pre-computadas para filtrado eficiente
            if "Nombre" in df.columns:
                df["Nombre_lower"] = df["Nombre"].str.lower().fillna("")
            if "Marca" in df.columns:
                df["Marca_lower"] = df["Marca"].str.lower().fillna("")
                df["Marca_limpia"] = df["Marca"].str.strip().str.strip("*").str.strip()

            for col in ["Notas", "Perfil_Olfativo", "ocasion", "estacion", "hora"]:
                if col in df.columns:
                    df[f"{col}_set"] = df[col].apply(self._make_tag_set)

        return df

    def fetch_sales(self) -> pd.DataFrame:
        """Carga ventas, parsea fechas y filtra anuladas."""
        def _fetch():
            return self._get_worksheet(WORKSHEET_VENTAS).get_all_records(
                value_render_option="UNFORMATTED_VALUE"
            )

        datos = self._ejecutar_con_reintento(_fetch, "fetch_sales")
        if not datos:
            return pd.DataFrame()

        df = pd.DataFrame(datos)

        if not df.empty:
            if "Fecha" in df.columns:
                df["Fecha"] = df["Fecha"].apply(self._parse_fecha)
            for col in ["Precio_Cobrado", "Ml_Vendido", "precio", "cantidad", "total", "ml"]:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)
            if "Celular" in df.columns:
                df["Celular"] = df["Celular"].astype(str)
            df["fila_sheet"] = range(2, len(df) + 2)
            if "Estado" in df.columns:
                df = df[df["Estado"] != "Anulado"].reset_index(drop=True)
                df["fila_sheet"] = df["fila_sheet"].astype(int)

        return df

    def fetch_quotes(self) -> pd.DataFrame:
        """Carga cotizaciones con fechas parseadas."""
        def _fetch():
            return self._get_worksheet(WORKSHEET_COTIZACIONES).get_all_records(
                value_render_option="UNFORMATTED_VALUE"
            )

        datos = self._ejecutar_con_reintento(_fetch, "fetch_quotes")
        if not datos:
            return pd.DataFrame()

        df = pd.DataFrame(datos)

        if not df.empty:
            df["fila_sheet"] = range(2, len(df) + 2)
            if "Fecha" in df.columns:
                df["Fecha"] = df["Fecha"].apply(self._parse_fecha)
            if "Total" in df.columns:
                df["Total"] = pd.to_numeric(df["Total"], errors="coerce").fillna(0)

        return df

    # ── IDs correlativos ──────────────────────────────────────────────────────

    def get_next_sale_id(self) -> str:
        def _fetch():
            return self._get_worksheet(WORKSHEET_VENTAS).col_values(1)[1:]  # skip header
        ids_col = self._ejecutar_con_reintento(_fetch, "get_next_sale_id")
        if not ids_col:
            return "V001"
        ids = self._extraer_ids_numericos(ids_col)
        if not ids:
            return "V001"
        siguiente = max(ids) + 1
        ids_set = set(ids)
        while siguiente in ids_set:
            siguiente += 1
        return f"V{siguiente:03d}"

    def get_next_quote_id(self) -> str:
        def _fetch():
            return self._get_worksheet(WORKSHEET_COTIZACIONES).col_values(1)[1:]  # skip header
        ids_col = self._ejecutar_con_reintento(_fetch, "get_next_quote_id")
        if not ids_col:
            return "C001"
        ids = self._extraer_ids_numericos(ids_col)
        if not ids:
            return "C001"
        return f"C{max(ids) + 1:03d}"

    # ── Escrituras ────────────────────────────────────────────────────────────

    def append_sale_rows(self, rows: list[list]) -> None:
        def _write():
            self._get_worksheet(WORKSHEET_VENTAS).append_rows(
                rows, value_input_option="USER_ENTERED"
            )
        self._ejecutar_con_reintento(_write, "append_sale_rows")

    def mark_sales_delivered_batch(self, filas: list[int], col_estado: int) -> None:
        peticiones = [
            {
                "range": gspread.utils.rowcol_to_a1(fila, col_estado),
                "values": [["Entregado"]],
            }
            for fila in filas
        ]
        def _write():
            self._get_worksheet(WORKSHEET_VENTAS).batch_update(peticiones)
        self._ejecutar_con_reintento(_write, "mark_sales_delivered_batch")

    def update_quote_status(
        self, nuevo_estado: str, fila_sheet: int, col_estado: int
    ) -> None:
        celda = gspread.utils.rowcol_to_a1(int(fila_sheet), col_estado)
        def _write():
            self._get_worksheet(WORKSHEET_COTIZACIONES).update(celda, [[nuevo_estado]])
        self._ejecutar_con_reintento(_write, "update_quote_status")

    def save_quote(self, celular: str, items: list[dict], total: float) -> str:
        """Guarda una cotización y retorna el ID asignado."""
        id_cotizacion = self.get_next_quote_id()
        items_txt = " | ".join(
            f"{i['perfume']} {i['ml']}ml S/{fmt_precio(i['precio'])}"
            for i in items
        )
        fila = [
            id_cotizacion,
            str(hoy_peru()),
            celular,
            items_txt,
            round(float(total), 2),
            "Enviado",
        ]
        def _write():
            self._get_worksheet(WORKSHEET_COTIZACIONES).append_rows(
                [fila], value_input_option="USER_ENTERED"
            )
        self._ejecutar_con_reintento(_write, "save_quote")
        return id_cotizacion

    def update_stock_batch(self, items_vendidos: list[dict], merma_pct: float) -> None:
        """
        Descuenta stock en batch considerando merma.

        Requiere que el catálogo ya esté cargado FRESCO (sin cache) para
        que fila_sheet sea exacto. El caller debe limpiar el cache antes de llamar.
        """
        df_cat = self.fetch_catalog()
        if df_cat.empty or "fila_sheet" not in df_cat.columns:
            raise ValueError("Catálogo vacío o sin fila_sheet")
        if not {"Stock_ml", "ID_Perfume"}.issubset(df_cat.columns):
            raise ValueError("Faltan columnas ID_Perfume o Stock_ml en Catalogo")

        sheet_cols = [c for c in df_cat.columns if c != "fila_sheet"]
        col_stock = sheet_cols.index("Stock_ml") + 1

        ml_por_id: dict[str, float] = {}
        for item in items_vendidos:
            id_perf = str(item["id_perfume"])
            ml_vendido = float(item["ml"])
            ml_base = ML_BASE_DISPENSACION.get(int(ml_vendido), ml_vendido)
            ml_con_merma = ml_base * (1 + merma_pct)
            ml_por_id[id_perf] = ml_por_id.get(id_perf, 0) + ml_con_merma

        peticiones = []
        for _, row in df_cat[df_cat["ID_Perfume"].astype(str).isin(ml_por_id)].iterrows():
            id_fila = str(row["ID_Perfume"])
            valor_actual = float(row["Stock_ml"]) if row["Stock_ml"] else 0.0
            ml_necesario = ml_por_id[id_fila]
            if valor_actual < ml_necesario:
                logger.warning(
                    f"Stock insuficiente ID {id_fila}: disponible={valor_actual}ml, "
                    f"vendido={ml_necesario}ml (incl. merma {merma_pct:.0%}) — fijando en 0"
                )
            nuevo_valor = max(0.0, valor_actual - ml_necesario)
            peticiones.append({
                "range": gspread.utils.rowcol_to_a1(int(row["fila_sheet"]), col_stock),
                "values": [[nuevo_valor]],
            })

        if peticiones:
            def _write():
                self._get_worksheet(WORKSHEET_CATALOGO).batch_update(peticiones)
            self._ejecutar_con_reintento(_write, "update_stock_batch")

    def update_sales_multi_batch(
        self, filas_cambios: list[tuple[int, dict[int, object]]]
    ) -> None:
        peticiones = [
            {
                "range": gspread.utils.rowcol_to_a1(int(fila_sheet), int(col_num)),
                "values": [[valor]],
            }
            for fila_sheet, cambios in filas_cambios
            for col_num, valor in cambios.items()
        ]
        if peticiones:
            def _write():
                self._get_worksheet(WORKSHEET_VENTAS).batch_update(
                    peticiones, value_input_option="USER_ENTERED"
                )
            self._ejecutar_con_reintento(_write, "update_sales_multi_batch")

    def register_complete_sale(
        self,
        cesta: list[dict],
        cliente: dict,
        merma_pct: float,
    ) -> str:
        """
        Operación atómica: genera ID, guarda filas y descuenta stock.

        Si el stock falla, propaga StockUpdateError con el id_compra ya
        guardado — la UI puede advertir sin perder la venta.
        """
        id_compra = self.get_next_sale_id()

        filas = [
            [
                id_compra,
                cliente["fecha"],
                cliente["comprador"].strip().title(),
                cliente["celular"],
                str(item["id_perfume"]),
                str(item["ml"]),
                round(float(item["precio"]), 2),
                item["metodo"],
                cliente["tipo_envio"],
                cliente["direccion"].strip().title(),
                (cliente.get("distrito") or "").strip().title(),
                "Pendiente",
            ]
            for item in cesta
        ]

        self.append_sale_rows(filas)

        try:
            self.update_stock_batch(cesta, merma_pct)
        except Exception as e:
            logger.error(f"[register_complete_sale/stock] {type(e).__name__}: {e}")
            raise StockUpdateError(id_compra, e)

        return id_compra

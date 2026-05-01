from fpdf import FPDF
import pandas as pd
from datetime import date
from config import fmt_precio


def _construir_pdf(df_ventas_filtrado, df_catalogo, titulo, subtitulo):
    """Genera el PDF para el DataFrame de ventas ya filtrado."""
    if df_ventas_filtrado.empty:
        return None

    df_catalogo = df_catalogo.copy()
    df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

    pdf = FPDF()
    pdf.set_margins(12, 12, 12)
    pdf.add_page()

    # Encabezado
    pdf.set_font("Helvetica", "B", 17)
    pdf.cell(0, 10, "Perfumeria", ln=True, align="C")
    pdf.set_font("Helvetica", "B", 13)
    pdf.cell(0, 7, titulo, ln=True, align="C")
    pdf.set_font("Helvetica", size=9)
    pdf.set_text_color(120, 100, 80)
    pdf.cell(0, 6, subtitulo, ln=True, align="C")
    pdf.set_text_color(0, 0, 0)
    pdf.ln(3)
    pdf.line(12, pdf.get_y(), 198, pdf.get_y())
    pdf.ln(4)

    # Resumen general
    total_general = df_ventas_filtrado["Precio_Cobrado"].apply(
        lambda x: float(x) if str(x).strip() not in ("", "nan") else 0.0
    ).sum()
    total_ventas = len(df_ventas_filtrado)

    pdf.set_fill_color(253, 246, 240)
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(90, 8, f"  Total de ventas: {total_ventas}", border=0, fill=True)
    pdf.cell(0, 8, f"Recaudado: S/ {fmt_precio(total_general)}", border=0, fill=True, ln=True)
    pdf.ln(3)

    # Resumen por método de pago
    if "Metodo_Pago" in df_ventas_filtrado.columns:
        df_temp = df_ventas_filtrado.copy()
        df_temp["Precio_Cobrado"] = pd.to_numeric(df_temp["Precio_Cobrado"], errors="coerce").fillna(0)
        por_metodo = (
            df_temp.groupby("Metodo_Pago")["Precio_Cobrado"]
            .agg(Cantidad="count", Total="sum")
            .reset_index()
            .sort_values("Total", ascending=False)
        )
        if not por_metodo.empty:
            pdf.set_font("Helvetica", "B", 9)
            pdf.set_text_color(120, 100, 80)
            pdf.cell(0, 6, "Resumen por metodo de pago:", ln=True)
            pdf.set_text_color(0, 0, 0)
            pdf.set_font("Helvetica", size=9)
            for _, r in por_metodo.iterrows():
                pdf.cell(60, 5, f"  {r['Metodo_Pago']}")
                pdf.cell(30, 5, f"{int(r['Cantidad'])} venta(s)")
                pdf.cell(0, 5, f"S/ {fmt_precio(r['Total'])}", ln=True)
            pdf.ln(2)

    pdf.line(12, pdf.get_y(), 198, pdf.get_y())
    pdf.ln(4)

    # Detalle de ventas agrupadas por ID de compra
    grupos = df_ventas_filtrado.groupby("ID_Compra", sort=False)
    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]
        pdf.set_font("Helvetica", "B", 10)
        fecha_val = primera.get("Fecha", "")
        fecha_str = str(fecha_val)
        try:
            fecha_str = pd.to_datetime(fecha_val).strftime("%d/%m/%Y")
        except Exception:
            pass
        pdf.cell(0, 7, f"Compra {id_compra}  |  {primera.get('Comprador', '')}  |  {fecha_str}", ln=True)

        pdf.set_font("Helvetica", size=9)
        pdf.cell(0, 5, f"Celular: {primera.get('Celular', '')}  |  Envio: {primera.get('Tipo_Envio', '')}  |  Estado: {primera.get('Estado', '')}", ln=True)
        if str(primera.get("Direccion", "")).strip():
            pdf.cell(0, 5, f"Direccion: {primera.get('Direccion', '')}", ln=True)

        subtotal = 0.0
        for _, item in grupo.iterrows():
            id_p = str(item.get("ID_Perfume", ""))
            match = df_catalogo[df_catalogo["ID_Perfume"] == id_p]
            nombre_p = match.iloc[0]["Nombre"] if not match.empty else id_p
            precio = float(item.get("Precio_Cobrado", 0) or 0)
            subtotal += precio
            pdf.cell(0, 5, f"  - {nombre_p}  {item.get('Ml_Vendido', '')}ml  |  {item.get('Metodo_Pago', '')}  |  S/ {fmt_precio(precio)}", ln=True)

        if len(grupo) > 1:
            pdf.set_font("Helvetica", "B", 9)
            pdf.cell(0, 5, f"  Subtotal: S/ {fmt_precio(subtotal)}", ln=True)

        pdf.set_draw_color(210, 190, 170)
        pdf.line(12, pdf.get_y() + 1, 198, pdf.get_y() + 1)
        pdf.set_draw_color(0, 0, 0)
        pdf.ln(4)

    # Total final
    pdf.ln(2)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 8, f"TOTAL: S/ {fmt_precio(total_general)}", ln=True, align="R")

    return bytes(pdf.output())


def exportar_pdf_ventas_hoy(df_ventas, df_catalogo):
    """Genera un PDF con las ventas del día actual."""
    hoy = date.today()
    df = df_ventas.copy()
    df["Fecha"] = pd.to_datetime(df["Fecha"], errors="coerce")
    filtrado = df[df["Fecha"].dt.date == hoy]
    return _construir_pdf(
        filtrado, df_catalogo,
        titulo=f"Ventas del dia - {hoy.strftime('%d/%m/%Y')}",
        subtitulo=f"Generado el {hoy.strftime('%d/%m/%Y')}"
    )


def exportar_pdf_ventas_mes(df_ventas, df_catalogo):
    """Genera un PDF con las ventas del mes actual."""
    hoy = date.today()
    df = df_ventas.copy()
    df["Fecha"] = pd.to_datetime(df["Fecha"], errors="coerce")
    filtrado = df[
        (df["Fecha"].dt.month == hoy.month) &
        (df["Fecha"].dt.year == hoy.year)
    ]
    meses = [
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ]
    nombre_mes = meses[hoy.month - 1].capitalize()
    return _construir_pdf(
        filtrado, df_catalogo,
        titulo=f"Ventas de {nombre_mes} {hoy.year}",
        subtitulo=f"Generado el {hoy.strftime('%d/%m/%Y')}"
    )


MESES_ES = [
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
]


def exportar_pdf_mes_especifico(df_ventas, df_catalogo, anio: int, mes: int):
    """Genera un PDF con las ventas de un mes y año específicos."""
    df = df_ventas.copy()
    df["Fecha"] = pd.to_datetime(df["Fecha"], errors="coerce")
    filtrado = df[(df["Fecha"].dt.month == mes) & (df["Fecha"].dt.year == anio)]
    nombre_mes = MESES_ES[mes - 1].capitalize()
    return _construir_pdf(
        filtrado, df_catalogo,
        titulo=f"Ventas de {nombre_mes} {anio}",
        subtitulo=f"Generado el {date.today().strftime('%d/%m/%Y')}"
    )

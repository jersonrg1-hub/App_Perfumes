from fpdf import FPDF
import pandas as pd
from datetime import date

def exportar_pdf_ventas_hoy(df_ventas, df_catalogo):
    """Genera un PDF con las ventas del día actual"""
    try:
        hoy = date.today()
        df_ventas = df_ventas.copy()
        df_ventas["Fecha"] = pd.to_datetime(df_ventas["Fecha"], errors="coerce")
        ventas_hoy = df_ventas[df_ventas["Fecha"].dt.date == hoy]

        if ventas_hoy.empty:
            return None

        # Preparar catálogo una sola vez antes del loop
        df_catalogo = df_catalogo.copy()
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Helvetica", "B", 16)
        pdf.cell(0, 10, f"Ventas del dia - {hoy}", ln=True, align="C")
        pdf.ln(5)

        total_dia = 0
        for _, row in ventas_hoy.iterrows():
            pdf.set_font("Helvetica", "B", 11)
            pdf.cell(0, 8, f"ID: {row.get('ID_Compra','')} | {row.get('Comprador','')}", ln=True)
            pdf.set_font("Helvetica", size=10)
            pdf.cell(0, 6, f"Celular: {row.get('Celular','')} | Envio: {row.get('Tipo_Envio','')}", ln=True)
            pdf.cell(0, 6, f"Direccion: {row.get('Direccion','')}", ln=True)

            id_p = str(row.get("ID_Perfume", ""))
            match = df_catalogo[df_catalogo["ID_Perfume"] == id_p]
            nombre_p = match.iloc[0]["Nombre"] if not match.empty else id_p

            precio = float(row.get("Precio_Cobrado", 0))
            pdf.cell(0, 6, f"Perfume: {nombre_p} {row.get('Ml_Vendido','')}ml | S/ {precio}", ln=True)
            pdf.cell(0, 4, f"Pago: {row.get('Metodo_Pago','')} | Estado: {row.get('Estado','')}", ln=True)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(3)
            total_dia += precio

        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, f"TOTAL DEL DIA: S/ {total_dia:.1f}", ln=True, align="R")
        return bytes(pdf.output())

    except Exception as e:
        return None
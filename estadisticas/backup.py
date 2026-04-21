import io
from datetime import datetime
import streamlit as st
import pandas as pd
from config import TZ_PERU
from components import separador


def _generar_excel(df_catalogo, df_ventas) -> bytes:
    buffer = io.BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        if not df_catalogo.empty:
            df_catalogo.to_excel(writer, sheet_name="Catalogo", index=False)
        if not df_ventas.empty:
            df_ventas.to_excel(writer, sheet_name="Ventas", index=False)
    return buffer.getvalue()


def mostrar_backup(df_catalogo, df_ventas):
    separador("💾 Backup de datos")

    ahora = datetime.now(TZ_PERU).strftime("%Y-%m-%d_%H-%M")
    nombre_archivo = f"perfumeria_backup_{ahora}.xlsx"

    st.markdown(
        """
        <div style="background:#f5ede6; border:1px solid #e8d5c4; border-radius:12px;
            padding:1rem 1.2rem; margin-bottom:1rem;">
            <div style="font-size:0.78rem; color:#4a2e18; line-height:1.6;">
                📋 El archivo Excel incluye dos hojas:<br>
                &nbsp;&nbsp;• <strong>Catalogo</strong> — todos tus perfumes con precios y costos<br>
                &nbsp;&nbsp;• <strong>Ventas</strong> — historial completo de ventas
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        try:
            excel_bytes = _generar_excel(df_catalogo, df_ventas)
            st.download_button(
                label="⬇️ Descargar Excel",
                data=excel_bytes,
                file_name=nombre_archivo,
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                use_container_width=True,
            )
        except Exception as e:
            st.error(f"❌ Error generando el backup: {e}")
            st.caption("Asegúrate de tener instalado **openpyxl**: `pip install openpyxl`")

    st.caption(f"El archivo se guardará como: `{nombre_archivo}`")

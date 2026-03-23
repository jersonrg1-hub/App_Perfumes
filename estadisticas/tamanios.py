import html
import streamlit as st
from config import fmt_precio


def mostrar_tamanios_populares(df_ventas):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas todavía")
        return

    if "Ml_Vendido" not in df_ventas.columns:
        st.warning("⚠️ No se encontró la columna Ml_Vendido")
        return

    conteo = (
        df_ventas.groupby("Ml_Vendido")
        .agg(Cantidad=("Ml_Vendido", "count"), Total=("Precio_Cobrado", "sum"))
        .reset_index()
        .sort_values("Cantidad", ascending=False)
    )

    total_ventas = conteo["Cantidad"].sum()

    st.markdown("#### 📏 Tamaños más vendidos")
    st.markdown("")

    for row in conteo.to_dict('records'):
        ml = row["Ml_Vendido"]
        cantidad = row["Cantidad"]
        total = row["Total"]
        porcentaje = (cantidad / total_ventas * 100) if total_ventas > 0 else 0

        ml_safe = html.escape(str(ml))

        st.markdown(f"""
        <div style="
            background: white; border-radius: 12px;
            padding: 1rem 1.5rem; margin-bottom: 0.8rem;
            border: 1px solid #f0e0d0;
        ">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;">
                <div style="font-family:'Playfair Display',serif; font-size:1.1rem; color:#2c1a0e; font-weight:700;">
                    📦 {ml_safe}ml
                </div>
                <div style="color:#a07850; font-size:0.9rem;">
                    {cantidad} venta(s) — S/ {fmt_precio(total)}
                </div>
            </div>
            <div style="background:#f5ede6; border-radius:8px; height:12px; overflow:hidden;">
                <div style="
                    background: linear-gradient(135deg, #2c1a0e, #c8956c);
                    height:100%; width:{porcentaje:.1f}%;
                    border-radius:8px;
                "></div>
            </div>
            <div style="color:#c8956c; font-size:0.8rem; margin-top:0.3rem; text-align:right;">
                {porcentaje:.1f}% del total
            </div>
        </div>
        """, unsafe_allow_html=True)
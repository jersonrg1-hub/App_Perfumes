import streamlit as st
import pandas as pd
from config import COL_ESTADO_NUM, fmt_precio
from data import marcar_entregado

def mostrar_ventas_pendientes(df_ventas, df_catalogo=None):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas")
        return

    if "Estado" not in df_ventas.columns:
        st.warning("⚠️ Agrega la columna Estado en tu Sheets")
        return

    pendientes = df_ventas[df_ventas["Estado"] != "Entregado"]

    if pendientes.empty:
        st.success("✅ No hay ventas pendientes")
        return

    if df_catalogo is not None:
        df_catalogo = df_catalogo.copy()
        df_catalogo["ID_Perfume"] = df_catalogo["ID_Perfume"].astype(str)

    def get_nombre_perfume(id_perfume):
        if df_catalogo is None:
            return f"ID: {id_perfume}"
        match = df_catalogo[df_catalogo["ID_Perfume"] == str(id_perfume)]
        return match.iloc[0]["Nombre"] if not match.empty else f"ID: {id_perfume}"

    grupos = pendientes.groupby("ID_Compra")
    st.markdown(f"**{grupos.ngroups} compra(s) pendiente(s)**")

    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]
        total_compra = pd.to_numeric(grupo["Precio_Cobrado"], errors="coerce").sum()

        with st.expander(f"📦 {id_compra} — {primera.get('Comprador','')} | S/ {fmt_precio(total_compra)}"):
            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {primera.get('Fecha','')}")
                st.write(f"📱 **Celular:** {primera.get('Celular','')}")
                st.write(f"🚚 **Envío:** {primera.get('Tipo_Envio','')}")
            with col2:
                st.write(f"📍 **Dirección:** {primera.get('Direccion','')}")
                st.write(f"💳 **Pago:** {primera.get('Metodo_Pago','')}")

            st.markdown("**🛍️ Productos:**")
            for _, item in grupo.iterrows():
                nombre = get_nombre_perfume(item.get('ID_Perfume', ''))
                st.markdown(
                    f"- 🌸 **{nombre}** — "
                    f"{item.get('Ml_Vendido','')}ml "
                    f"| S/ {fmt_precio(item.get('Precio_Cobrado', 0))}"
                )

            if st.button("✅ Marcar como entregado", key=f"entregar_{id_compra}"):
                try:
                    for idx in grupo.index:
                        marcar_entregado(idx + 2, COL_ESTADO_NUM)
                    st.success("✅ Compra marcada como entregada")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error: {e}")
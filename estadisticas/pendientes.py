import streamlit as st
from config import COL_ESTADO_NUM, fmt_precio, fmt_fecha
from data import marcar_pedido_entregado_batch


def mostrar_ventas_pendientes(df_ventas, df_catalogo=None):
    if df_ventas.empty:
        st.info("📭 No hay ventas registradas")
        return

    if "Estado" not in df_ventas.columns:
        st.warning("⚠️ Agrega la columna Estado en tu Sheets")
        return

    cols_requeridas = ["ID_Compra", "Precio_Cobrado", "ID_Perfume"]
    cols_faltantes = [c for c in cols_requeridas if c not in df_ventas.columns]
    if cols_faltantes:
        st.error(f"❌ Faltan columnas en la hoja de ventas: {', '.join(cols_faltantes)}")
        return

    pendientes = df_ventas[df_ventas["Estado"] != "Entregado"]

    if pendientes.empty:
        st.success("✅ No hay ventas pendientes")
        return

    def get_nombre_perfume(id_perfume):
        if df_catalogo is None:
            return f"ID: {id_perfume}"
        match = df_catalogo[df_catalogo["ID_Perfume"].astype(str) == str(id_perfume)]
        return match.iloc[0]["Nombre"] if not match.empty else f"ID: {id_perfume}"

    grupos = pendientes.groupby("ID_Compra")
    st.markdown(f"**{grupos.ngroups} compra(s) pendiente(s)**")

    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]

        total_compra = grupo["Precio_Cobrado"].sum()

        with st.expander(f"📦 {id_compra} — {primera.get('Comprador', '')} | S/ {fmt_precio(total_compra)}"):
            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {fmt_fecha(primera.get('Fecha', ''))}")
                st.write(f"📱 **Celular:** {primera.get('Celular', '')}")
                st.write(f"🚚 **Envío:** {primera.get('Tipo_Envio', '')}")
            with col2:
                st.write(f"📍 **Dirección:** {primera.get('Direccion', '')}")
                st.write(f"💳 **Pago:** {primera.get('Metodo_Pago', '')}")

            st.markdown("**🛍️ Productos:**")

            for _, item in grupo.iterrows():
                nombre = get_nombre_perfume(item.get('ID_Perfume', ''))
                st.markdown(
                    f"- 🌸 **{nombre}** — "
                    f"{item.get('Ml_Vendido', '')}ml "
                    f"| S/ {fmt_precio(item.get('Precio_Cobrado', 0))}"
                )

            if st.button("✅ Marcar como entregado", key=f"entregar_{id_compra}"):
                mensaje_estado = st.empty()
                mensaje_estado.info("🚀 Procesando entrega de inmediato...")

                try:
                    if "fila_sheet" in grupo.columns:
                        filas_a_actualizar = grupo["fila_sheet"].tolist()
                    else:
                        filas_a_actualizar = [idx + 2 for idx in grupo.index]

                    marcar_pedido_entregado_batch(filas_a_actualizar, COL_ESTADO_NUM)
                    mensaje_estado.success("✅ ¡Listo! Sincronizado correctamente.")
                    st.rerun()

                except Exception as e:
                    mensaje_estado.error(f"❌ Ocurrió un error: {e}")
import streamlit as st
from config import COL_ESTADO_NUM, COLUMNAS_VENTAS, METODOS_PAGO, fmt_precio, fmt_fecha
from data import marcar_pedido_entregado_batch, actualizar_venta_batch
from components import separador


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
        st.error(f"❌ Faltan columnas: {', '.join(cols_faltantes)}")
        return

    pendientes = df_ventas[~df_ventas["Estado"].isin(["Entregado", "Anulado"])].copy()

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

    COL_METODO = COLUMNAS_VENTAS.index("Metodo_Pago") + 1
    COL_ENVIO  = COLUMNAS_VENTAS.index("Tipo_Envio") + 1
    COL_DIR    = COLUMNAS_VENTAS.index("Direccion") + 1

    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]
        total_compra = grupo["Precio_Cobrado"].sum()
        estado_actual = str(primera.get("Estado", "Pendiente"))

        with st.expander(f"📦 {id_compra} — {primera.get('Comprador', '')} | S/ {fmt_precio(total_compra)}"):

            col1, col2 = st.columns(2)
            with col1:
                st.write(f"📅 **Fecha:** {fmt_fecha(primera.get('Fecha', ''))}")
                st.write(f"📱 **Celular:** {primera.get('Celular', '')}")
                st.write(f"🚚 **Envío:** {primera.get('Tipo_Envio', '')}")
            with col2:
                st.write(f"📍 **Dirección:** {primera.get('Direccion', '')}")
                st.write(f"💳 **Pago:** {primera.get('Metodo_Pago', '')}")

            st.markdown("")
            for _, item in grupo.iterrows():
                nombre = get_nombre_perfume(item.get("ID_Perfume", ""))
                st.markdown(f"&nbsp;&nbsp;&nbsp;&nbsp;🌸 {nombre} — {item.get('Ml_Vendido', '')}ml — S/ {fmt_precio(item.get('Precio_Cobrado', 0))}", unsafe_allow_html=True)

            separador()

            modo_key = f"modo_{id_compra}"
            if modo_key not in st.session_state:
                st.session_state[modo_key] = "normal"

            if st.session_state[modo_key] == "normal":
                col_ent, col_edit, col_anul = st.columns(3)

                with col_ent:
                    filas = grupo["fila_sheet"].tolist()
                    if st.button("✅ Marcar entregado", key=f"ent_{id_compra}", width="stretch"):
                        try:
                            marcar_pedido_entregado_batch(filas, COL_ESTADO_NUM)
                            st.success(f"✅ {id_compra} marcado como entregado")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")

                with col_edit:
                    if st.button("✏️ Editar", key=f"edit_{id_compra}", width="stretch"):
                        st.session_state[modo_key] = "editar"
                        st.rerun()

                with col_anul:
                    if st.button("🚫 Anular", key=f"anul_{id_compra}", width="stretch"):
                        st.session_state[modo_key] = "anular"
                        st.rerun()

            elif st.session_state[modo_key] == "editar":
                st.markdown("**✏️ Editar datos de la venta:**")

                metodo_actual = str(primera.get("Metodo_Pago", METODOS_PAGO[0]))
                idx_metodo = METODOS_PAGO.index(metodo_actual) if metodo_actual in METODOS_PAGO else 0

                nuevo_metodo = st.selectbox(
                    "💳 Método de pago",
                    METODOS_PAGO,
                    index=idx_metodo,
                    key=f"met_{id_compra}"
                )
                nueva_dir = st.text_input(
                    "📍 Dirección",
                    value=str(primera.get("Direccion", "")),
                    key=f"dir_{id_compra}"
                )
                nuevo_estado = st.selectbox(
                    "📋 Estado",
                    ["Pendiente", "En camino", "Entregado"],
                    index=["Pendiente", "En camino", "Entregado"].index(estado_actual)
                        if estado_actual in ["Pendiente", "En camino", "Entregado"] else 0,
                    key=f"est_{id_compra}"
                )

                col_g, col_c = st.columns(2)
                with col_g:
                    if st.button("💾 Guardar cambios", key=f"gua_{id_compra}", type="primary", width="stretch"):
                        try:
                            for fila in grupo["fila_sheet"].tolist():
                                actualizar_venta_batch(fila, {
                                    COL_METODO: nuevo_metodo,
                                    COL_DIR: nueva_dir,
                                    COL_ESTADO_NUM: nuevo_estado,
                                })
                            st.success("✅ Cambios guardados")
                            st.session_state[modo_key] = "normal"
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_c:
                    if st.button("Cancelar", key=f"can_{id_compra}", width="stretch"):
                        st.session_state[modo_key] = "normal"
                        st.rerun()

            elif st.session_state[modo_key] == "anular":
                st.warning(f"⚠️ ¿Seguro que quieres anular **{id_compra}**? Esta acción cambia el estado a Anulado en Sheets.")

                col_conf, col_canc = st.columns(2)
                with col_conf:
                    if st.button("🚫 Confirmar anulación", key=f"conf_{id_compra}", type="primary", width="stretch"):
                        try:
                            for fila in grupo["fila_sheet"].tolist():
                                actualizar_venta_batch(fila, {COL_ESTADO_NUM: "Anulado"})
                            st.session_state.pop(modo_key, None)
                            st.success(f"🚫 {id_compra} anulado")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_canc:
                    if st.button("Cancelar", key=f"canc_{id_compra}", width="stretch"):
                        st.session_state[modo_key] = "normal"
                        st.rerun()
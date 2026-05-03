import html
import streamlit as st
from urllib.parse import quote
from config import COL_ESTADO_NUM, COLUMNAS_VENTAS, METODOS_PAGO, fmt_precio, fmt_fecha
from data import marcar_pedido_entregado_batch, actualizar_ventas_multi_fila_batch
from components import separador, construir_catalogo_dict, nombre_por_id


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

    catalogo_dict = construir_catalogo_dict(df_catalogo)

    buscar = st.text_input(
        "🔍 Buscar", placeholder="Nombre o ID de compra...", key="pend_buscar"
    )
    if buscar:
        mask = (
            pendientes["Comprador"].astype(str).str.lower().str.contains(buscar.lower(), na=False, regex=False) |
            pendientes["ID_Compra"].astype(str).str.lower().str.contains(buscar.lower(), na=False, regex=False)
        )
        pendientes = pendientes[mask]

    grupos = pendientes.groupby("ID_Compra")
    st.markdown(f"**{grupos.ngroups} compra(s) pendiente(s)**")

    COL_METODO = COLUMNAS_VENTAS.index("Metodo_Pago") + 1
    COL_ENVIO  = COLUMNAS_VENTAS.index("Tipo_Envio") + 1
    COL_DIR    = COLUMNAS_VENTAS.index("Direccion") + 1

    _ESTADO_EMOJI = {"Pendiente": "🟡", "En camino": "🔵", "Entregado": "🟢", "Anulado": "🔴"}
    _ESTADO_COLOR = {
        "Pendiente": ("background:#fff7ed; border:1px solid #f59e0b; color:#92400e;",),
        "En camino": ("background:#eff6ff; border:1px solid #3b82f6; color:#1e40af;",),
        "Entregado": ("background:#ecfdf5; border:1px solid #10b981; color:#065f46;",),
        "Anulado":   ("background:#fff5f5; border:1px solid #ef4444; color:#7f1d1d;",),
    }

    for id_compra, grupo in grupos:
        primera = grupo.iloc[0]
        total_compra = grupo["Precio_Cobrado"].sum()
        estado_actual = str(primera.get("Estado", "Pendiente"))
        emoji_est = _ESTADO_EMOJI.get(estado_actual, "⚪")

        with st.expander(f"{emoji_est} {id_compra} — {primera.get('Comprador', '')} | S/ {fmt_precio(total_compra)}"):

            fecha_s   = html.escape(str(fmt_fecha(primera.get("Fecha", ""))))
            celular_s = html.escape(str(primera.get("Celular", "")))
            envio_s   = html.escape(str(primera.get("Tipo_Envio", "")))
            dir_s     = html.escape(str(primera.get("Direccion", "") or "—"))
            pago_s    = html.escape(str(primera.get("Metodo_Pago", "")))

            st.markdown(f"""
            <div style="background:#fdf6f0; border:1px solid #ede0d4; border-radius:12px;
                padding:0.85rem 1.1rem; margin-bottom:0.5rem;
                display:grid; grid-template-columns:1fr 1fr; gap:0.45rem;
                font-size:0.88rem; color:#2c1a0e;">
                <div><span style="color:#a07850; font-size:0.7rem; text-transform:uppercase;
                    font-weight:600; letter-spacing:0.08em;">📅 Fecha</span>
                    <br><strong>{fecha_s}</strong></div>
                <div><span style="color:#a07850; font-size:0.7rem; text-transform:uppercase;
                    font-weight:600; letter-spacing:0.08em;">📱 Celular</span>
                    <br><strong>{celular_s}</strong></div>
                <div><span style="color:#a07850; font-size:0.7rem; text-transform:uppercase;
                    font-weight:600; letter-spacing:0.08em;">🚚 Envío</span>
                    <br><strong>{envio_s}</strong></div>
                <div><span style="color:#a07850; font-size:0.7rem; text-transform:uppercase;
                    font-weight:600; letter-spacing:0.08em;">💳 Pago</span>
                    <br><strong>{pago_s}</strong></div>
                <div style="grid-column:1/-1;"><span style="color:#a07850; font-size:0.7rem;
                    text-transform:uppercase; font-weight:600; letter-spacing:0.08em;">📍 Dirección</span>
                    <br><strong>{dir_s}</strong></div>
            </div>
            """, unsafe_allow_html=True)

            items_html = "".join([
                f"<div style='display:flex; justify-content:space-between; align-items:center;"
                f"padding:0.4rem 0; border-bottom:1px solid #f5ede6; font-size:0.88rem;'>"
                f"<span style='color:#2c1a0e; font-weight:500;'>🌸 "
                f"{html.escape(str(nombre_por_id(catalogo_dict, it.get('ID_Perfume',''))))}"
                f" · {html.escape(str(it.get('Ml_Vendido','')))}ml</span>"
                f"<span style='font-weight:700; color:#c8956c; font-family:Inter,sans-serif;"
                f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(it.get('Precio_Cobrado', 0))}</span>"
                f"</div>"
                for it in grupo.to_dict("records")
            ])
            est_style = _ESTADO_COLOR.get(estado_actual, ("background:#f5f5f5; border:1px solid #ccc; color:#555;",))[0]
            st.markdown(
                f"<div style='display:inline-block; {est_style} border-radius:20px;"
                f"padding:0.2rem 0.75rem; font-size:0.72rem; font-weight:700;"
                f"letter-spacing:0.08em; text-transform:uppercase; margin-bottom:0.6rem;'>"
                f"{emoji_est} {html.escape(estado_actual)}</div>",
                unsafe_allow_html=True
            )
            st.markdown(
                f"<div style='background:white; border:1px solid #ede0d4; border-radius:12px;"
                f"padding:0.8rem 1.1rem; margin-bottom:0.5rem;'>"
                f"<div style='font-size:0.68rem; color:#a07850; text-transform:uppercase;"
                f"font-weight:600; letter-spacing:0.1em; margin-bottom:0.5rem;'>Perfumes</div>"
                f"{items_html}</div>",
                unsafe_allow_html=True
            )

            separador()

            items_lineas = "\n".join([
                f"  • {nombre_por_id(catalogo_dict, it.get('ID_Perfume',''))} "
                f"{it.get('Ml_Vendido','')}ml — S/ {fmt_precio(it.get('Precio_Cobrado',0))}"
                for it in grupo.to_dict("records")
            ])
            dir_linea = f"\n📍 *Dirección:* {dir_s}" if primera.get("Direccion") else ""
            msg_comunidad = (
                f"📦 *Pedido Nuevo — {html.escape(str(id_compra))}*\n"
                f"────────────────────\n"
                f"👤 *Cliente:* {html.escape(str(primera.get('Comprador','')))} \n"
                f"📱 *Celular:* {celular_s}\n"
                f"🚚 *Envío:* {envio_s}"
                f"{dir_linea}\n"
                f"────────────────────\n"
                f"🌸 *Perfumes:*\n{items_lineas}\n"
                f"────────────────────\n"
                f"💰 *Total: S/ {fmt_precio(total_compra)}*\n"
                f"💳 *Pago:* {pago_s}"
            )
            st.markdown(
                f'<a href="https://wa.me/?text={quote(msg_comunidad)}" target="_blank"'
                f' style="text-decoration:none;display:block;background:#128C7E;'
                f'color:white !important;padding:10px;border-radius:8px;'
                f'text-align:center;font-weight:700;font-size:0.85rem;margin-bottom:0.6rem;">'
                f'📲 Enviar pedido a comunidad</a>',
                unsafe_allow_html=True,
            )

            modo_key = f"modo_{id_compra}"
            if modo_key not in st.session_state:
                st.session_state[modo_key] = "normal"

            if st.session_state[modo_key] == "normal":
                col_ent, col_edit, col_anul = st.columns(3)
                with col_ent:
                    if st.button("✅ Marcar entregado", key=f"ent_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "confirmar_entrega"
                        st.rerun()
                with col_edit:
                    if st.button("✏️ Editar", key=f"edit_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "editar"
                        st.rerun()
                with col_anul:
                    if st.button("🚫 Anular", key=f"anul_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "anular"
                        st.rerun()

            elif st.session_state[modo_key] == "confirmar_entrega":
                st.success(f"¿Confirmas que **{id_compra}** fue entregado a **{primera.get('Comprador', '')}**?")
                col_si, col_no = st.columns(2)
                with col_si:
                    filas = grupo["fila_sheet"].tolist()
                    if st.button("✅ Sí, confirmar entrega", key=f"conf_ent_{id_compra}", type="primary", use_container_width=True):
                        try:
                            marcar_pedido_entregado_batch(filas, COL_ESTADO_NUM)
                            st.session_state.pop(modo_key, None)
                            st.toast(f"✅ {id_compra} marcado como entregado", icon="🟢")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_no:
                    if st.button("✖ Cancelar", key=f"canc_ent_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "normal"
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
                    if st.button("💾 Guardar cambios", key=f"gua_{id_compra}", type="primary", use_container_width=True):
                        try:
                            actualizar_ventas_multi_fila_batch([
                                (fila, {COL_METODO: nuevo_metodo, COL_DIR: nueva_dir, COL_ESTADO_NUM: nuevo_estado})
                                for fila in grupo["fila_sheet"].tolist()
                            ])
                            st.success("✅ Cambios guardados")
                            st.session_state[modo_key] = "normal"
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_c:
                    if st.button("Cancelar", key=f"can_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "normal"
                        st.rerun()

            elif st.session_state[modo_key] == "anular":
                st.warning(f"⚠️ ¿Seguro que quieres anular **{id_compra}**? Esta acción cambia el estado a Anulado en Sheets.")

                col_conf, col_canc = st.columns(2)
                with col_conf:
                    if st.button("🚫 Confirmar anulación", key=f"conf_{id_compra}", type="primary", use_container_width=True):
                        try:
                            actualizar_ventas_multi_fila_batch([
                                (fila, {COL_ESTADO_NUM: "Anulado"})
                                for fila in grupo["fila_sheet"].tolist()
                            ])
                            st.session_state.pop(modo_key, None)
                            st.toast(f"🚫 {id_compra} anulado", icon="🔴")
                            st.rerun()
                        except Exception as e:
                            st.error(f"Error: {e}")
                with col_canc:
                    if st.button("Cancelar", key=f"canc_{id_compra}", use_container_width=True):
                        st.session_state[modo_key] = "normal"
                        st.rerun()
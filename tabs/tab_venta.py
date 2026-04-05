import streamlit as st
from config import ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO, fmt_precio, hoy_peru
from data import guardar_venta, obtener_proximo_id, cargar_ventas, actualizar_stock_perfume
from components import generar_url_whatsapp
from tabs.tab_cotizacion import mostrar_seccion_cotizacion


@st.cache_data(ttl=120)
def _buscar_cliente(df_ventas, celular):
    if df_ventas.empty or "Celular" not in df_ventas.columns:
        return None
    coincidencias = df_ventas[df_ventas["Celular"].astype(str) == str(celular)]
    if coincidencias.empty:
        return None
    ultimo = coincidencias.iloc[-1]
    return {
        "nombre": str(ultimo.get("Comprador", "")),
        "direccion": str(ultimo.get("Direccion", "")),
        "metodo_pago": str(ultimo.get("Metodo_Pago", "")),
        "tipo_envio": str(ultimo.get("Tipo_Envio", "")),
    }


def mostrar_tab_venta(df):
    mostrar_seccion_cotizacion(df)

    st.markdown("### 📝 Registrar Nueva Venta")

    if "cesta" not in st.session_state:
        st.session_state.cesta = []
    if "autocomplete_aplicado" not in st.session_state:
        st.session_state.autocomplete_aplicado = False
    if "fecha_venta" not in st.session_state:
        st.session_state.fecha_venta = hoy_peru()

    if st.session_state.get("_autocomplete_pendiente"):
        datos = st.session_state._autocomplete_pendiente
        st.session_state.comp_in = datos["nombre"]
        st.session_state.dir_in  = datos["direccion"]
        if datos["metodo_pago"] in METODOS_PAGO:
            st.session_state.pago_sel = datos["metodo_pago"]
        if datos["tipo_envio"] in TIPOS_ENVIO:
            st.session_state.envio_sel = datos["tipo_envio"]
        st.session_state.autocomplete_aplicado = True
        st.session_state._autocomplete_pendiente = None

    nombres_opciones = ["— Elige un perfume —"] + sorted(df["Nombre"].dropna().unique().tolist())

    def resetear_formulario():
        st.session_state.cesta = []
        st.session_state.comp_in = ""
        st.session_state.cel_in = ""
        st.session_state.dir_in = ""
        st.session_state.perf_sel = nombres_opciones[0]
        st.session_state.ml_sel = ML_OPCIONES[0]
        st.session_state.pago_sel = METODOS_PAGO[0]
        st.session_state.envio_sel = TIPOS_ENVIO[0]
        st.session_state.fecha_venta = hoy_peru()
        st.session_state.autocomplete_aplicado = False

    if st.session_state.get("venta_guardada"):
        st.session_state.venta_guardada = False
        resetear_formulario()
        st.rerun()

    with st.container(border=True):
        st.markdown("#### 👤 Datos del Comprador")

        col_fecha, col_envio = st.columns(2)
        with col_fecha:
            fecha = st.date_input("📅 Fecha", format="DD/MM/YYYY", key="fecha_venta")
        with col_envio:
            tipo_envio = st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key="envio_sel")

        col_comp, col_cel = st.columns(2)
        with col_comp:
            comprador_raw = st.text_input("👤 Nombre", placeholder="Comprador", key="comp_in")
            comprador = comprador_raw.title() if comprador_raw else ""
        with col_cel:
            celular = st.text_input("📱 Celular", max_chars=9, key="cel_in")

        if len(celular) == 9 and not st.session_state.autocomplete_aplicado:
            df_ventas = cargar_ventas()
            cliente = _buscar_cliente(df_ventas, celular)

            if cliente and cliente["nombre"]:
                st.markdown(
                    f"""<div style="background:#f5ede6; border-left:4px solid #c8956c;
                    border-radius:8px; padding:0.7rem 1rem; margin:0.3rem 0;">
                    👤 Cliente conocido: <strong>{cliente['nombre']}</strong>
                    — {cliente['direccion'] or 'sin dirección guardada'}
                    </div>""",
                    unsafe_allow_html=True
                )
                if st.button(
                    f"✨ Autocompletar datos de {cliente['nombre']}",
                    key="btn_autocomplete",
                    width='stretch'
                ):
                    st.session_state._autocomplete_pendiente = cliente
                    st.rerun()

        if len(celular) != 9:
            st.session_state.autocomplete_aplicado = False

        direccion = st.text_input("📍 Dirección", placeholder="Distrito / Referencia", key="dir_in")

    st.markdown("#### 🛒 Agregar Perfume")
    perfume_venta = st.selectbox("🌸 Perfume", nombres_opciones, key="perf_sel")

    col_ml, col_pago = st.columns(2)
    with col_ml:
        ml_vendido = st.selectbox("📏 Tamaño", ML_OPCIONES, key="ml_sel")
    with col_pago:
        metodo_pago = st.selectbox("💳 Pago", METODOS_PAGO, key="pago_sel")

    if perfume_venta != nombres_opciones[0]:
        perfume_row = df[df["Nombre"] == perfume_venta].iloc[0]
        id_perfume = perfume_row["ID_Perfume"]
        columna_precio = f"Precio_{ml_vendido}ml"
        precio_item = perfume_row.get(columna_precio, 0)

        if precio_item not in (0, "", None):
            stock_actual = perfume_row.get("Stock_ml", None)
            if stock_actual not in (None, "", 0):
                stock_num = float(stock_actual)
                ml_num = float(ml_vendido)
                if stock_num < ml_num:
                    st.error(f"❌ Stock insuficiente — quedan {stock_num:.0f}ml y necesitas {ml_num:.0f}ml")
                elif stock_num <= 15:
                    st.warning(f"⚠️ Stock bajo — solo quedan {stock_num:.0f}ml disponibles")
                else:
                    st.success(f"Precio detectado: **S/ {fmt_precio(precio_item)}** · Stock: {stock_num:.0f}ml")
            else:
                st.success(f"Precio detectado: **S/ {fmt_precio(precio_item)}**")

            if st.button("➕ Agregar a la cesta", key=f"agregar_{perfume_venta}_{ml_vendido}", width='stretch'):
                if not comprador or len(celular) != 9:
                    st.error("⚠️ Completa Nombre y Celular (9 dígitos)")
                else:
                    st.session_state.cesta.append({
                        "perfume": perfume_venta, "id_perfume": id_perfume,
                        "ml": ml_vendido, "precio": precio_item, "metodo": metodo_pago
                    })
                    st.toast(f"Agregado: {perfume_venta}", icon="✅")
        else:
            st.warning("⚠️ Sin precio configurado")

    if st.session_state.cesta:
        st.divider()
        st.markdown(f"#### 🛍️ Resumen de Cesta ({len(st.session_state.cesta)} item(s))")

        for i, item in enumerate(st.session_state.cesta):
            c1, c2, c3 = st.columns([3, 1, 0.5])
            c1.write(f"🌸 {item['perfume']} ({item['ml']}ml)")
            c2.write(f"**S/ {fmt_precio(item['precio'])}**")
            if c3.button("🗑️", key=f"del_{i}"):
                st.session_state.cesta.pop(i)
                st.rerun()

        total = sum(float(i['precio']) for i in st.session_state.cesta)
        st.subheader(f"Total: S/ {fmt_precio(total)}")

        if st.button("✅ GUARDAR VENTA COMPLETA", key="guardar_venta", type="primary", width='stretch'):

            if not comprador or len(celular) != 9:
                st.error("⚠️ Completa Nombre y Celular (9 dígitos) antes de guardar")
                st.stop()

            try:
                with st.status("🚀 Procesando venta...", expanded=False) as status:
                    id_compra = obtener_proximo_id()

                    filas_para_google = []
                    for item in st.session_state.cesta:
                        filas_para_google.append([
                            id_compra, fecha.strftime("%Y-%m-%d"), comprador, celular,
                            str(item["id_perfume"]), str(item["ml"]),
                            round(float(item["precio"]), 2),
                            item["metodo"], tipo_envio, direccion, "Pendiente"
                        ])

                    guardar_venta(filas_para_google)

                    for item in st.session_state.cesta:
                        actualizar_stock_perfume(item["perfume"], float(item["ml"]))

                    status.update(label="✅ ¡Venta guardada!", state="complete")

                url_wa = generar_url_whatsapp(
                    id_compra, comprador, celular, direccion,
                    tipo_envio, st.session_state.cesta, total
                )

                st.balloons()

                st.markdown(f"""<a href="{url_wa}" target="_blank" style="text-decoration:none;">
                    <div style="background-color:#25D366; color:white; padding:15px; border-radius:10px;
                    text-align:center; font-weight:bold; margin-bottom:20px;">
                        📲 Enviar Comprobante por WhatsApp
                    </div></a>""", unsafe_allow_html=True)

                st.session_state.venta_guardada = True
                if st.button("🆕 Registrar otra venta", key="nueva_venta"):
                    resetear_formulario()
                    st.rerun()

            except Exception as e:
                st.error(f"Error al guardar: {e}")
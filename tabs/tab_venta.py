import streamlit as st
from config import PRECIOS_COLUMNAS, ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO, fmt_precio
from data import guardar_venta, obtener_proximo_id
from components import generar_url_whatsapp


def mostrar_tab_venta(df):
    st.markdown("### 📝 Registrar Nueva Venta")

    # --- Inicialización de Cesta y Formulario ---
    if "cesta" not in st.session_state:
        st.session_state.cesta = []

    # Función interna para limpiar todo después de la venta
    def resetear_formulario():
        st.session_state.cesta = []
        st.session_state.comp_in = ""
        st.session_state.cel_in = ""
        st.session_state.dir_in = ""
        st.session_state.perf_sel = "— Elige un perfume —"

    # ── Datos del comprador ───────────────────────────────
    with st.container(border=True):
        st.markdown("#### 👤 Datos del Comprador")
        col_fecha, col_envio = st.columns(2)
        with col_fecha:
            fecha = st.date_input("📅 Fecha", key="fecha_venta")
        with col_envio:
            tipo_envio = st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key="envio_sel")

        col_comp, col_cel = st.columns(2)
        with col_comp:
            comprador = st.text_input("👤 Nombre", placeholder="Comprador", key="comp_in")
        with col_cel:
            celular = st.text_input("📱 Celular", max_chars=9, key="cel_in")

        direccion = st.text_input("📍 Dirección", placeholder="Distrito / Referencia", key="dir_in")

    # ── Agregar perfume ───────────────────────────────────
    st.markdown("#### 🛒 Agregar Perfume")
    nombres_opciones = ["— Elige un perfume —"] + sorted(df["Nombre"].unique().tolist())
    perfume_venta = st.selectbox("🌸 Perfume", nombres_opciones, key="perf_sel")

    col_ml, col_pago = st.columns(2)
    with col_ml:
        ml_vendido = st.selectbox("📏 Tamaño", ML_OPCIONES, key="ml_sel")
    with col_pago:
        metodo_pago = st.selectbox("💳 Pago", METODOS_PAGO, key="pago_sel")

    if perfume_venta != "— Elige un perfume —":
        perfume_row = df[df["Nombre"] == perfume_venta].iloc[0]
        id_perfume = perfume_row["ID_Perfume"]
        columna_precio = f"Precio_{ml_vendido}ml"
        precio_item = perfume_row.get(columna_precio, 0)

        if precio_item:
            st.success(f"Precio detectado: **S/ {fmt_precio(precio_item)}**")

            if st.button("➕ Agregar a la cesta", use_container_width=True):
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

    # ── Cesta y Guardado ──────────────────────────────────
    if st.session_state.cesta:
        st.divider()
        st.markdown("#### 🛍️ Resumen de Cesta")

        for i, item in enumerate(st.session_state.cesta):
            c1, c2, c3 = st.columns([3, 1, 0.5])
            c1.write(f"🌸 {item['perfume']} ({item['ml']}ml)")
            c2.write(f"**S/ {fmt_precio(item['precio'])}**")
            if c3.button("🗑️", key=f"del_{i}"):
                st.session_state.cesta.pop(i)
                st.rerun()

        total = sum(float(i['precio']) for i in st.session_state.cesta)
        st.subheader(f"Total: S/ {fmt_precio(total)}")

        if st.button("✅ GUARDAR VENTA COMPLETA", type="primary", use_container_width=True):
            try:
                with st.status("🚀 Procesando venta...", expanded=False) as status:
                    id_compra = obtener_proximo_id()

                    filas_para_google = []
                    for item in st.session_state.cesta:
                        filas_para_google.append([
                            id_compra, str(fecha), comprador, celular,
                            str(item["id_perfume"]), str(item["ml"]),
                            fmt_precio(item["precio"]), item["metodo"],
                            tipo_envio, direccion, "Pendiente"
                        ])

                    guardar_venta(filas_para_google)
                    status.update(label="✅ ¡Venta guardada!", state="complete")

                # Generar link de WhatsApp
                url_wa = generar_url_whatsapp(id_compra, comprador, celular, direccion, tipo_envio,
                                              st.session_state.cesta, total)

                st.balloons()

                # Mostrar botón de WhatsApp
                st.markdown(f"""<a href="{url_wa}" target="_blank" style="text-decoration:none;">
                    <div style="background-color:#25D366; color:white; padding:15px; border-radius:10px; text-align:center; font-weight:bold; margin-bottom:20px;">
                        📲 Enviar Comprobante por WhatsApp
                    </div></a>""", unsafe_allow_html=True)

                # BOTÓN PARA NUEVA VENTA (Limpia los campos)
                if st.button("🆕 Registrar otra venta"):
                    resetear_formulario()
                    st.rerun()

            except Exception as e:
                st.error(f"Error al guardar: {e}")
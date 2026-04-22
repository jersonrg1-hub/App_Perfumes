import html
import streamlit as st
from config import ML_OPCIONES, METODOS_PAGO, TIPOS_ENVIO, fmt_precio, hoy_peru, STOCK_CRITICO, STOCK_BAJO
from costos import costo_total_item
from data import guardar_venta, obtener_proximo_id, cargar_ventas, actualizar_stock_perfumes_batch
from components import generar_url_whatsapp, separador
from tabs.tab_cotizacion import mostrar_seccion_cotizacion


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


def _items_cesta_html(cesta):
    return "".join([
        f"<div style='display:flex; justify-content:space-between; align-items:center;"
        f"padding:0.45rem 0; border-bottom:1px solid #f5ede6; font-size:0.88rem;'>"
        f"<div><span style='color:#2c1a0e; font-weight:600;'>🌸 {html.escape(str(i['perfume']))}</span>"
        f"<span style='color:#a07850; font-size:0.78rem;'> · {html.escape(str(i['ml']))}ml · {html.escape(str(i['metodo']))}</span></div>"
        f"<span style='font-family:Inter,DM Sans,sans-serif; font-weight:700; color:#2c1a0e;"
        f"font-variant-numeric:tabular-nums;'>S/ {fmt_precio(i['precio'])}</span></div>"
        for i in cesta
    ])


def _card_stock(precio_item, stock_val, ml_vendido):
    """Muestra el badge de stock + precio según el nivel disponible."""
    if stock_val not in (None, "", 0):
        stock_num = float(stock_val)
        if stock_num < float(ml_vendido):
            st.error(f"❌ Stock insuficiente — quedan {stock_num:.0f}ml · necesitas {float(ml_vendido):.0f}ml")
            return
        if stock_num <= STOCK_CRITICO:
            bg, border, txt, num = "#fee2e2", "#dc2626", "#991b1b", "#7f1d1d"
            label = f"🔴 Stock crítico — solo {stock_num:.0f}ml"
        elif stock_num <= STOCK_BAJO:
            bg, border, txt, num = "#fef9c3", "#ca8a04", "#854d0e", "#713f12"
            label = f"🟡 Stock bajo — {stock_num:.0f}ml"
        else:
            bg, border, txt, num = "#dcfce7", "#16a34a", "#166534", "#14532d"
            label = f"🟢 Stock: {stock_num:.0f}ml disponibles"
        st.markdown(
            f"""<div style="background:{bg}; border-left:4px solid {border}; border-radius:10px;
            padding:0.8rem 1.2rem; display:flex; justify-content:space-between; align-items:center;">
            <span style="color:{txt}; font-weight:600;">{label}</span>
            <span style="color:{num}; font-family:'Inter',sans-serif; font-size:1.6rem;
            font-weight:800; font-variant-numeric:tabular-nums;">S/ {fmt_precio(precio_item)}</span>
            </div>""", unsafe_allow_html=True
        )
    else:
        st.markdown(
            f"""<div style="background:#dcfce7; border-left:4px solid #16a34a; border-radius:10px;
            padding:0.8rem 1.2rem; text-align:right;">
            <span style="color:#14532d; font-family:'Inter',sans-serif; font-size:1.6rem;
            font-weight:800; font-variant-numeric:tabular-nums;">S/ {fmt_precio(precio_item)}</span>
            </div>""", unsafe_allow_html=True
        )


def _barra_progreso(paso_actual):
    pasos = ["Cliente", "Perfumes", "Confirmar"]

    col1, col2, col3, col4, col5 = st.columns([2, 1, 2, 1, 2])
    columnas_pasos = [col1, col3, col5]
    columnas_conectores = [col2, col4]

    for i, (col, nombre) in enumerate(zip(columnas_pasos, pasos), 1):
        if i < paso_actual:
            circulo_bg = "#2c1a0e"
            circulo_color = "white"
            texto_color = "#2c1a0e"
            contenido = "✓"
        elif i == paso_actual:
            circulo_bg = "#c8956c"
            circulo_color = "white"
            texto_color = "#c8956c"
            contenido = str(i)
        else:
            circulo_bg = "#ede0d4"
            circulo_color = "#a07850"
            texto_color = "#a07850"
            contenido = str(i)

        with col:
            st.markdown(
                f"""<div style="display:flex; flex-direction:column;
                    align-items:center; gap:4px; padding:0.5rem 0;">
                    <div style="width:28px; height:28px; border-radius:50%;
                        background:{circulo_bg}; color:{circulo_color};
                        display:flex; align-items:center; justify-content:center;
                        font-size:0.8rem; font-weight:700;">{contenido}</div>
                    <div class="wiz-step-label" style="font-size:0.7rem; font-weight:600; color:{texto_color};
                        text-transform:uppercase; letter-spacing:0.08em;
                        text-align:center;">{nombre}</div>
                </div>""",
                unsafe_allow_html=True
            )

    for j, col in enumerate(columnas_conectores):
        linea_color = "#2c1a0e" if (j + 1) < paso_actual else "#ede0d4"
        with col:
            st.markdown(
                f"""<div style="height:28px; display:flex; align-items:center;
                    padding-top:0.5rem;">
                    <div style="flex:1; height:1px; background:{linea_color};"></div>
                </div>""",
                unsafe_allow_html=True
            )

    st.markdown("")


def _paso_1_cliente(df):
    st.markdown("#### 👤 Datos del comprador")

    fecha = st.date_input("📅 Fecha", format="DD/MM/YYYY", key="fecha_venta")
    tipo_envio = st.selectbox("🚚 Tipo de Envío", TIPOS_ENVIO, key="envio_sel")
    comprador_raw = st.text_input("👤 Nombre", placeholder="Comprador", key="comp_in")
    comprador = comprador_raw.title() if comprador_raw else ""
    celular = st.text_input("📱 Celular", max_chars=9, key="cel_in")

    if len(celular) == 9 and celular.isdigit():
        ultimo_cel = st.session_state.get("autocomplete_celular", "")
        if celular != ultimo_cel:
            st.session_state.autocomplete_aplicado = False
        if not st.session_state.get("autocomplete_aplicado"):
            df_ventas = cargar_ventas()
            cliente = _buscar_cliente(df_ventas, celular)
            if cliente and cliente["nombre"]:
                st.session_state._autocomplete_pendiente = cliente
                st.session_state.autocomplete_aplicado = True
                st.session_state.autocomplete_celular = celular
                st.rerun()
    else:
        st.session_state.autocomplete_aplicado = False
        st.session_state.autocomplete_celular = ""

    direccion = st.text_input("📍 Dirección", placeholder="Distrito / Referencia", key="dir_in")

    st.markdown("")
    col_btn, _ = st.columns([1, 2])
    with col_btn:
        if st.button("Siguiente →", key="paso1_siguiente", type="primary", use_container_width=True):
            requiere_direccion = tipo_envio != "Contraentrega"
            if not comprador or len(celular) != 9 or not celular.isdigit():
                st.error("⚠️ Completa Nombre y Celular (9 dígitos numéricos)")
            elif requiere_direccion and not direccion.strip():
                st.error(f"⚠️ La dirección es requerida para envío por {tipo_envio}")
            else:
                st.session_state.wiz_paso = 2
                st.session_state.wiz_fecha = fecha
                st.session_state.wiz_comprador = comprador
                st.session_state.wiz_celular = celular
                st.session_state.wiz_direccion = direccion
                st.session_state.wiz_tipo_envio = tipo_envio
                st.rerun()


def _paso_2_perfumes(df):
    if st.session_state.cesta:
        total_actual = sum(float(i["precio"]) for i in st.session_state.cesta)
        n = len(st.session_state.cesta)
        st.markdown(f"""
        <div style="background:linear-gradient(135deg,#2c1a0e 0%,#4a2e18 100%);
            border-radius:12px; padding:0.75rem 1.2rem; margin-bottom:0.8rem;
            display:flex; justify-content:space-between; align-items:center;">
            <div style="color:#f5e6d8; font-size:0.85rem; font-weight:600;">
                🛍️ {n} item{'s' if n != 1 else ''} en cesta
            </div>
            <div style="color:#c8956c; font-family:'Inter',sans-serif; font-size:1.25rem;
                font-weight:800; font-variant-numeric:tabular-nums;">S/ {fmt_precio(total_actual)}</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("#### 🛒 Agregar perfumes")

    _k = st.session_state.get("perf_sel_count", 0)
    marcas_opciones = sorted(df["Marca"].dropna().unique().tolist())
    marca_filtro = st.selectbox(
        "🏷️ Marca (opcional)",
        marcas_opciones,
        index=None,
        placeholder="— Todas las marcas —",
        key=f"marca_filtro_venta_{_k}",
    )
    df_perfumes = df[df["Marca"] == marca_filtro] if marca_filtro else df
    nombres_opciones = sorted(df_perfumes["Nombre"].dropna().unique().tolist())
    perfume_venta = st.selectbox("🌸 Perfume", nombres_opciones, index=None, placeholder="— Elige un perfume —", key=f"perf_sel_{_k}")

    ml_vendido = st.selectbox("📏 Tamaño", ML_OPCIONES, key="ml_sel")
    metodo_pago = st.selectbox("💳 Pago", METODOS_PAGO, key="pago_sel")

    if perfume_venta is not None:
        _matches = df[df["Nombre"] == perfume_venta]
        if _matches.empty:
            st.warning("⚠️ Perfume no encontrado. Recarga los datos.")
            return
        perfume_row = _matches.iloc[0]
        id_perfume = perfume_row["ID_Perfume"]
        columna_precio = f"Precio_{ml_vendido}ml"
        precio_item = perfume_row.get(columna_precio, 0)

        if precio_item not in (0, "", None):
            _card_stock(precio_item, perfume_row.get("Stock_ml", None), ml_vendido)

            try:
                cb = float(perfume_row.get("Costo_Botella") or 0)
                mb = float(perfume_row.get("Ml_Botella") or 0)
                costo_est = costo_total_item(ml_vendido, cb, mb)
                gan_est = float(precio_item) - costo_est
                st.markdown(
                    f"<div style='font-size:0.78rem; color:#6b7280; margin:0.3rem 0 0.5rem;'>"
                    f"💸 Costo estimado: <b>S/ {fmt_precio(costo_est)}</b>"
                    f"&nbsp;&nbsp;|&nbsp;&nbsp;💰 Ganancia: <b style='color:#16a34a'>S/ {fmt_precio(gan_est)}</b>"
                    f"</div>",
                    unsafe_allow_html=True
                )
            except Exception:
                pass

            precio_final = st.number_input(
                "💰 Precio final",
                min_value=0.0,
                value=float(precio_item),
                step=0.5,
                format="%.2f",
                key=f"precio_edit_{perfume_venta}_{ml_vendido}",
            )
            if st.button("➕ Agregar a la cesta", key=f"agregar_{perfume_venta}_{ml_vendido}", use_container_width=True):
                st.session_state.cesta.append({
                    "perfume": perfume_venta,
                    "marca": str(perfume_row.get("Marca", "")),
                    "id_perfume": id_perfume,
                    "ml": ml_vendido, "precio": precio_final, "metodo": metodo_pago
                })
                st.toast(f"Agregado: {perfume_venta}", icon="✅")
                st.session_state.perf_sel_count += 1
                st.rerun()
        else:
            st.warning("⚠️ Sin precio configurado")

    if st.session_state.cesta:
        separador()
        st.markdown(f"**🛍️ Cesta — {len(st.session_state.cesta)} item(s)**")
        st.markdown("")

        for i, item in enumerate(st.session_state.cesta):
            nombre_item = html.escape(str(item["perfume"]))
            metodo_item = html.escape(str(item["metodo"]))
            col_item, col_del = st.columns([10, 1])
            with col_item:
                st.markdown(
                    f"""<div style="
                        background:#ffffff; border:1px solid #ede0d4;
                        border-radius:10px; padding:0.65rem 1rem;
                        display:flex; justify-content:space-between; align-items:center;
                    ">
                        <div>
                            <div style="font-size:0.9rem; font-weight:600; color:#2c1a0e;">
                                🌸 {nombre_item} · {item['ml']}ml
                            </div>
                            <div style="font-size:0.75rem; color:#a07850; margin-top:2px;">
                                {metodo_item}
                            </div>
                        </div>
                        <div style="
                            font-family:'Inter','DM Sans',sans-serif;
                            font-size:1rem; font-weight:700; color:#2c1a0e;
                            font-variant-numeric:tabular-nums;
                        ">S/ {fmt_precio(item['precio'])}</div>
                    </div>""",
                    unsafe_allow_html=True
                )
            with col_del:
                st.markdown("<div style='padding-top:4px;'>", unsafe_allow_html=True)
                if st.button("🗑️", key=f"del_{i}"):
                    st.session_state.cesta.pop(i)
                    st.rerun()

        total = sum(float(i["precio"]) for i in st.session_state.cesta)
        st.markdown(
            f"""<div style="
                background:#fdf6f0; border:1px solid #ede0d4;
                border-radius:10px; padding:0.65rem 1.2rem;
                display:flex; justify-content:space-between; align-items:center;
                margin-top:0.3rem;
            ">
                <div style="font-size:0.8rem; font-weight:600; color:#a07850;
                    text-transform:uppercase; letter-spacing:0.08em;">Total</div>
                <div style="font-family:'Inter','DM Sans',sans-serif;
                    font-size:1.2rem; font-weight:700; color:#2c1a0e;
                    font-variant-numeric:tabular-nums;">S/ {fmt_precio(total)}</div>
            </div>""",
            unsafe_allow_html=True
        )

    st.markdown("")
    col_ant, col_sig = st.columns(2)
    with col_ant:
        if st.button("← Volver", key="paso2_volver", use_container_width=True):
            st.session_state.wiz_paso = 1
            st.rerun()
    with col_sig:
        if st.button("Siguiente →", key="paso2_siguiente", type="primary", use_container_width=True):
            if not st.session_state.cesta:
                st.error("⚠️ Agrega al menos un perfume")
            else:
                st.session_state.wiz_paso = 3
                st.rerun()


def _paso_3_confirmar():
    st.markdown("#### ✅ Confirmar venta")

    comprador  = html.escape(str(st.session_state.wiz_comprador))
    celular    = html.escape(str(st.session_state.wiz_celular))
    direccion  = html.escape(str(st.session_state.wiz_direccion or "—"))
    tipo_envio = html.escape(str(st.session_state.wiz_tipo_envio))
    fecha_str  = st.session_state.wiz_fecha.strftime("%d/%m/%Y")

    st.markdown(f"""
    <div style="background:#ffffff; border:1px solid #ede0d4; border-radius:12px;
        padding:1rem 1.2rem; margin-bottom:0.8rem;">
        <div style="font-size:0.68rem; color:#a07850; text-transform:uppercase;
            font-weight:600; letter-spacing:0.1em; margin-bottom:0.6rem;">Datos del comprador</div>
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:0.5rem;
            font-size:0.88rem; color:#2c1a0e;">
            <div><span style="color:#a07850; font-size:0.75rem;">👤 Nombre</span>
                <br><strong>{comprador}</strong></div>
            <div><span style="color:#a07850; font-size:0.75rem;">📱 Celular</span>
                <br><strong>{celular}</strong></div>
            <div><span style="color:#a07850; font-size:0.75rem;">📅 Fecha</span>
                <br><strong>{fecha_str}</strong></div>
            <div><span style="color:#a07850; font-size:0.75rem;">🚚 Envío</span>
                <br><strong>{tipo_envio}</strong></div>
            <div style="grid-column:1/-1;">
                <span style="color:#a07850; font-size:0.75rem;">📍 Dirección</span>
                <br><strong>{direccion}</strong></div>
        </div>
    </div>
    """, unsafe_allow_html=True)

    total = sum(float(i["precio"]) for i in st.session_state.cesta)
    items_html = _items_cesta_html(st.session_state.cesta)

    st.markdown(f"""
    <div style="background:#ffffff; border:1px solid #ede0d4; border-radius:12px;
        padding:1rem 1.2rem; margin-bottom:0.8rem;">
        <div style="font-size:0.68rem; color:#a07850; text-transform:uppercase;
            font-weight:600; letter-spacing:0.1em; margin-bottom:0.5rem;">Perfumes</div>
        {items_html}
        <div style="display:flex; justify-content:space-between; align-items:center;
            margin-top:0.6rem; padding-top:0.5rem; border-top:1px solid #ede0d4;">
            <span style="font-size:0.8rem; font-weight:600; color:#a07850;
                text-transform:uppercase; letter-spacing:0.08em;">Total</span>
            <span style="font-family:'Inter','DM Sans',sans-serif; font-size:1.15rem;
                font-weight:700; color:#2c1a0e; font-variant-numeric:tabular-nums;">
                S/ {fmt_precio(total)}</span>
        </div>
    </div>
    """, unsafe_allow_html=True)

    col_ant, col_guar = st.columns(2)
    with col_ant:
        if st.button("← Volver", key="paso3_volver", use_container_width=True):
            st.session_state.wiz_paso = 2
            st.rerun()
    with col_guar:
        if st.button("✅ Guardar venta", key="guardar_venta", type="primary", use_container_width=True):
            try:
                with st.status("🚀 Procesando...", expanded=False) as status:
                    id_compra = obtener_proximo_id()
                    filas = []
                    for item in st.session_state.cesta:
                        filas.append([
                            id_compra,
                            st.session_state.wiz_fecha.strftime("%Y-%m-%d"),
                            st.session_state.wiz_comprador,
                            st.session_state.wiz_celular,
                            str(item["id_perfume"]), str(item["ml"]),
                            round(float(item["precio"]), 2),
                            item["metodo"],
                            st.session_state.wiz_tipo_envio,
                            st.session_state.wiz_direccion,
                            "Pendiente"
                        ])
                    guardar_venta(filas)
                    status.update(label="✅ ¡Venta guardada!", state="complete")

                try:
                    actualizar_stock_perfumes_batch(st.session_state.cesta)
                except Exception as e_stock:
                    st.warning(
                        f"⚠️ Venta guardada ({id_compra}), pero el stock no pudo actualizarse. "
                        f"Corrígelo manualmente en el catálogo. ({type(e_stock).__name__})"
                    )

                url_wa = generar_url_whatsapp(
                    id_compra, st.session_state.wiz_comprador,
                    st.session_state.wiz_celular, st.session_state.wiz_direccion,
                    st.session_state.wiz_tipo_envio, st.session_state.cesta, total
                )
                st.session_state.venta_guardada = True
                st.session_state.wiz_url_wa = url_wa
                st.session_state.wiz_id_compra = id_compra
                st.session_state.wiz_total = total
                st.toast(f"✅ Venta {id_compra} guardada correctamente", icon="🌸")
                st.balloons()
                st.rerun()
            except Exception as e:
                st.error(f"Error al guardar: {e}")


def _mostrar_venta_guardada():
    st.success("✅ ¡Venta guardada correctamente!")

    id_compra  = html.escape(str(st.session_state.get("wiz_id_compra", "")))
    comprador  = html.escape(str(st.session_state.get("wiz_comprador", "")))
    celular    = html.escape(str(st.session_state.get("wiz_celular", "")))
    direccion  = html.escape(str(st.session_state.get("wiz_direccion", "") or "—"))
    tipo_envio = html.escape(str(st.session_state.get("wiz_tipo_envio", "")))
    wiz_fecha  = st.session_state.get("wiz_fecha")
    fecha_str  = wiz_fecha.strftime("%d/%m/%Y") if hasattr(wiz_fecha, "strftime") else str(wiz_fecha or "—")
    total      = st.session_state.get("wiz_total", 0)
    cesta      = st.session_state.get("cesta", [])

    items_html = _items_cesta_html(cesta)
    st.markdown(
        f"""<div style="background:white; border:1px solid #ede0d4; border-radius:14px;
            padding:1.2rem 1.4rem; margin-bottom:1rem;">
            <div style="display:flex; justify-content:space-between; align-items:center;
                margin-bottom:1rem; padding-bottom:0.8rem; border-bottom:1px solid #ede0d4;">
                <div>
                    <div style="font-size:0.68rem; color:#a07850; text-transform:uppercase;
                        font-weight:600; letter-spacing:0.1em; margin-bottom:2px;">Compra</div>
                    <div style="font-family:'Inter','DM Sans',sans-serif; font-size:1.4rem;
                        font-weight:700; color:#2c1a0e;">{id_compra}</div>
                </div>
                <div style="text-align:right;">
                    <div style="font-size:0.68rem; color:#a07850; text-transform:uppercase;
                        font-weight:600; margin-bottom:2px;">Total</div>
                    <div style="font-family:'Inter','DM Sans',sans-serif; font-size:1.4rem;
                        font-weight:700; color:#c8956c; font-variant-numeric:tabular-nums;">
                        S/ {fmt_precio(total)}</div>
                </div>
            </div>
            <div style="display:grid; grid-template-columns:1fr 1fr; gap:0.5rem;
                margin-bottom:1rem; font-size:0.88rem;">
                <div><span style="color:#a07850; font-size:0.75rem;">👤 Comprador</span>
                    <br><strong style="color:#2c1a0e;">{comprador}</strong></div>
                <div><span style="color:#a07850; font-size:0.75rem;">📱 Celular</span>
                    <br><strong style="color:#2c1a0e;">{celular}</strong></div>
                <div><span style="color:#a07850; font-size:0.75rem;">📅 Fecha</span>
                    <br><strong style="color:#2c1a0e;">{fecha_str}</strong></div>
                <div><span style="color:#a07850; font-size:0.75rem;">🚚 Envío</span>
                    <br><strong style="color:#2c1a0e;">{tipo_envio}</strong></div>
                <div style="grid-column:1/-1;">
                    <span style="color:#a07850; font-size:0.75rem;">📍 Dirección</span>
                    <br><strong style="color:#2c1a0e;">{direccion}</strong></div>
            </div>
            <div style="font-size:0.68rem; color:#a07850; text-transform:uppercase;
                font-weight:600; letter-spacing:0.1em; margin-bottom:0.4rem;">Perfumes</div>
            {items_html}
            <div style="display:flex; justify-content:space-between; align-items:center;
                margin-top:0.7rem; padding-top:0.5rem; border-top:1px solid #ede0d4;">
                <span style="font-size:0.8rem; font-weight:600; color:#a07850;
                    text-transform:uppercase; letter-spacing:0.08em;">Total</span>
                <span style="font-family:'Inter','DM Sans',sans-serif; font-size:1.15rem;
                    font-weight:700; color:#c8956c; font-variant-numeric:tabular-nums;">
                    S/ {fmt_precio(total)}</span>
            </div>
        </div>""",
        unsafe_allow_html=True
    )

    url_wa = st.session_state.get("wiz_url_wa", "")
    if url_wa:
        st.markdown(
            f"""<a href="{url_wa}" target="_blank" style="text-decoration:none;">
            <div style="background:#25D366; color:white; padding:14px; border-radius:10px;
            text-align:center; font-weight:700; margin-bottom:0.8rem; font-size:1rem;">
                📲 Enviar Comprobante por WhatsApp
            </div></a>""", unsafe_allow_html=True
        )

    if st.button("🆕 Registrar otra venta", key="nueva_venta", use_container_width=True):
        _resetear_wizard()
        st.rerun()


def _resetear_wizard():
    st.session_state.wiz_paso = 1
    st.session_state.cesta = []
    st.session_state.autocomplete_aplicado = False
    st.session_state.venta_guardada = False
    for key in ["comp_in", "cel_in", "dir_in"]:
        st.session_state[key] = ""
    for key in ["ml_sel", "pago_sel", "envio_sel"]:
        if key in st.session_state:
            del st.session_state[key]
    st.session_state.perf_sel_count = 0
    st.session_state.fecha_venta = hoy_peru()
    st.session_state.wiz_comprador = ""
    st.session_state.wiz_celular = ""
    st.session_state.wiz_direccion = ""


@st.fragment
def mostrar_tab_venta(df):
    st.markdown("### 📝 Registrar Nueva Venta")

    if "cesta" not in st.session_state:
        st.session_state.cesta = []
    if "wiz_paso" not in st.session_state:
        st.session_state.wiz_paso = 1
    if "autocomplete_aplicado" not in st.session_state:
        st.session_state.autocomplete_aplicado = False
    if "fecha_venta" not in st.session_state:
        st.session_state.fecha_venta = hoy_peru()
    if "perf_sel_count" not in st.session_state:
        st.session_state.perf_sel_count = 0

    if st.session_state.get("_autocomplete_pendiente"):
        datos = st.session_state._autocomplete_pendiente
        st.session_state.comp_in = datos["nombre"]
        st.session_state.dir_in = datos["direccion"]
        if datos["metodo_pago"] in METODOS_PAGO:
            st.session_state.pago_sel = datos["metodo_pago"]
        if datos["tipo_envio"] in TIPOS_ENVIO:
            st.session_state.envio_sel = datos["tipo_envio"]
        st.session_state.autocomplete_aplicado = True
        st.toast(f"✨ Datos de {datos['nombre']} cargados", icon="👤")
        st.session_state._autocomplete_pendiente = None

    if st.session_state.get("venta_guardada") and st.session_state.wiz_paso == 3:
        _mostrar_venta_guardada()
        return

    _barra_progreso(st.session_state.wiz_paso)

    if st.session_state.wiz_paso == 1:
        _paso_1_cliente(df)
    elif st.session_state.wiz_paso == 2:
        _paso_2_perfumes(df)
    elif st.session_state.wiz_paso == 3:
        _paso_3_confirmar()

    if st.session_state.wiz_paso == 1 and not st.session_state.get("venta_guardada"):
        separador()
        mostrar_seccion_cotizacion(df)
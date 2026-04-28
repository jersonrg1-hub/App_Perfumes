import html
import re
import streamlit as st
from urllib.parse import quote
from config import fmt_precio, ML_OPCIONES, STOCK_CRITICO, STOCK_BAJO, ItemCesta
from costos import costo_total_item
from data import guardar_cotizacion

COSTO_DELIVERY = 10.0


def _limpiar_celular(raw: str) -> str:
    """Extrae los 9 dígitos del celular desde formatos como +51 987 654 321 o 987654321."""
    digits = re.sub(r'\D', '', raw)
    if digits.startswith('51') and len(digits) == 11:
        digits = digits[2:]
    return digits


def _limpiar_marca(marca: str) -> str:
    return marca.strip().strip('*').strip()


def _card_precio_cot(precio_catalogo, stock_val):
    """Tarjeta de stock + precio, igual estilo que la de venta."""
    try:
        stock_num = float(stock_val) if stock_val not in (None, "", 0) else None
    except (TypeError, ValueError):
        stock_num = None

    if stock_num is not None:
        if stock_num <= STOCK_CRITICO:
            bg, border, txt, num = "#fee2e2", "#dc2626", "#991b1b", "#7f1d1d"
            label = f"🔴 Stock crítico — solo {stock_num:.0f}ml"
        elif stock_num <= STOCK_BAJO:
            bg, border, txt, num = "#fef9c3", "#ca8a04", "#854d0e", "#713f12"
            label = f"🟡 Stock bajo — {stock_num:.0f}ml"
        else:
            bg, border, txt, num = "#dcfce7", "#16a34a", "#166534", "#14532d"
            label = f"🟢 Stock: {stock_num:.0f}ml disponibles"
    else:
        bg, border, txt, num = "#dcfce7", "#16a34a", "#166534", "#14532d"
        label = "🟢 Disponible"

    st.markdown(
        f"""<div style="background:{bg}; border-left:4px solid {border}; border-radius:10px;
        padding:0.8rem 1.2rem; display:flex; justify-content:space-between; align-items:center;
        margin-bottom:0.4rem;">
        <span style="color:{txt}; font-weight:600;">{label}</span>
        <span style="color:{num}; font-family:'Inter',sans-serif; font-size:1.6rem;
        font-weight:800; font-variant-numeric:tabular-nums;">S/ {fmt_precio(precio_catalogo)}</span>
        </div>""",
        unsafe_allow_html=True,
    )


def _generar_mensaje_cotizacion(
    celular: str, cesta_cotizacion: list[ItemCesta], con_delivery: bool = False
) -> str:
    total = sum(float(i["precio"]) for i in cesta_cotizacion)

    lineas = []
    for i in cesta_cotizacion:
        precio_orig = i.get("precio_original")
        precio_final = float(i["precio"])
        marca = i.get("marca", "")

        if precio_orig is not None and round(float(precio_orig), 2) != round(precio_final, 2):
            precio_txt = f"~S/ {fmt_precio(precio_orig)}~ *S/ {fmt_precio(precio_final)}*"
        else:
            precio_txt = f"S/ {fmt_precio(precio_final)}"

        if marca:
            lineas.append(f"  🌸 *{marca}* · {i['perfume']} · {i['ml']}ml · {precio_txt}")
        else:
            lineas.append(f"  🌸 {i['perfume']} · {i['ml']}ml · {precio_txt}")

    items = "\n".join(lineas)

    delivery_line = ""
    total_final = total
    if con_delivery:
        total_final = total + COSTO_DELIVERY
        delivery_line = f"🛵 *Delivery: S/ {fmt_precio(COSTO_DELIVERY)}*\n"

    mensaje = (
        f"🌸 *Perfuteca — Cotización*\n"
        f"────────────────────\n"
        f"📋 *Perfumes disponibles:*\n"
        f"{items}\n"
        f"────────────────────\n"
        f"{delivery_line}"
        f"💰 *Total: S/ {fmt_precio(total_final)}*\n\n"
        f"_¿Te interesa alguno? Con gusto te lo reservo 😊_"
    )
    return f"https://wa.me/51{celular}?text={quote(mensaje)}"


def mostrar_seccion_cotizacion(df):

    if "cesta_cotizacion" not in st.session_state:
        st.session_state.cesta_cotizacion = []
    if "cotizacion_enviada" not in st.session_state:
        st.session_state.cotizacion_enviada = False

    with st.expander("💰 Enviar Cotización por WhatsApp", expanded=False):

        celular_raw = st.text_input(
            "📱 Celular del cliente",
            placeholder="987654321 o +51 987 654 321",
            key="cel_cotizacion"
        )
        celular_cot = _limpiar_celular(celular_raw)

        st.markdown("#### 🛒 Armar cotización")

        marcas_opciones = sorted(
            _limpiar_marca(m) for m in df["Marca"].dropna().unique()
            if str(m).strip()
        )
        marca_cot = st.selectbox(
            "🏷️ Marca (opcional)",
            marcas_opciones,
            index=None,
            placeholder="— Todas las marcas —",
            key="marca_cot_sel",
        )

        if marca_cot:
            df_cot = df[df["Marca"].apply(lambda x: _limpiar_marca(str(x))) == marca_cot]
        else:
            df_cot = df

        nombres_opciones = ["— Elige un perfume —"] + sorted(
            df_cot["Nombre"].dropna().unique().tolist()
        )
        perfume_cot = st.selectbox("🌸 Perfume", nombres_opciones, key="perf_cot_sel")
        ml_cot = st.selectbox("📏 Tamaño", ML_OPCIONES, key="ml_cot_sel")

        if perfume_cot != nombres_opciones[0]:
            _matches = df[df["Nombre"] == perfume_cot]
            if _matches.empty:
                st.warning("⚠️ No se encontró ese perfume en el catálogo.")
                return
            perfume_row = _matches.iloc[0]
            columna_precio = f"Precio_{ml_cot}ml"
            precio_catalogo = perfume_row.get(columna_precio, 0)

            if precio_catalogo not in (0, "", None):
                _card_precio_cot(precio_catalogo, perfume_row.get("Stock_ml"))

                try:
                    cb = float(perfume_row.get("Costo_Botella") or 0)
                    mb = float(perfume_row.get("Ml_Botella") or 0)
                    costo_est = costo_total_item(ml_cot, cb, mb)
                    gan_est = float(precio_catalogo) - costo_est
                    st.markdown(
                        f"<div style='font-size:0.78rem; color:#6b7280; margin:0.3rem 0 0.5rem;'>"
                        f"💸 Costo estimado: <b>S/ {fmt_precio(costo_est)}</b>"
                        f"&nbsp;&nbsp;|&nbsp;&nbsp;💰 Ganancia: <b style='color:#16a34a'>S/ {fmt_precio(gan_est)}</b>"
                        f"</div>",
                        unsafe_allow_html=True
                    )
                except Exception:
                    pass

                precio_final_cot = st.number_input(
                    "💰 Precio final",
                    min_value=0.0,
                    value=float(precio_catalogo),
                    step=0.5,
                    format="%.2f",
                    key=f"precio_cot_{perfume_cot}_{ml_cot}",
                )

                if st.button("➕ Agregar a la cotización", key=f"add_cot_{perfume_cot}_{ml_cot}", use_container_width=True):
                    marca_limpia = _limpiar_marca(str(perfume_row.get("Marca", "")))
                    st.session_state.cesta_cotizacion.append({
                        "perfume":         perfume_cot,
                        "marca":           marca_limpia,
                        "ml":              ml_cot,
                        "precio":          precio_final_cot,
                        "precio_original": float(precio_catalogo),
                    })
                    st.session_state.cotizacion_enviada = False
                    st.toast(f"Agregado: {perfume_cot}", icon="✅")
            else:
                st.warning("⚠️ Sin precio para ese tamaño")

        if st.session_state.cesta_cotizacion:
            st.markdown("---")
            st.markdown("**📋 Cotización:**")

            for i, item in enumerate(st.session_state.cesta_cotizacion):
                c1, c2, c3 = st.columns([3, 1, 0.5])
                c1.write(f"🌸 {item['perfume']} ({item['ml']}ml)")
                c2.write(f"**S/ {fmt_precio(item['precio'])}**")
                if c3.button("🗑️", key=f"del_cot_{i}"):
                    st.session_state.cesta_cotizacion.pop(i)
                    st.session_state.cotizacion_enviada = False
                    st.rerun()

            total_cot = sum(float(i["precio"]) for i in st.session_state.cesta_cotizacion)

            con_delivery = st.checkbox(
                f"🛵 Con delivery (+S/ {fmt_precio(COSTO_DELIVERY)})",
                key="delivery_cot"
            )

            if con_delivery:
                st.markdown(
                    f"<div style='font-size:0.9rem; color:#6b7280;'>"
                    f"Perfumes: <b>S/ {fmt_precio(total_cot)}</b> &nbsp;+&nbsp; "
                    f"Delivery: <b>S/ {fmt_precio(COSTO_DELIVERY)}</b>"
                    f"</div>",
                    unsafe_allow_html=True
                )
                st.markdown(f"**Total con delivery: S/ {fmt_precio(total_cot + COSTO_DELIVERY)}**")
            else:
                st.markdown(f"**Total: S/ {fmt_precio(total_cot)}**")

            col_wa, col_limpiar = st.columns([2, 1])

            with col_wa:
                if len(celular_cot) == 9 and celular_cot.isdigit():
                    url_wa = _generar_mensaje_cotizacion(
                        celular_cot,
                        st.session_state.cesta_cotizacion,
                        con_delivery=con_delivery,
                    )

                    if not st.session_state.cotizacion_enviada:
                        if st.button(
                            "💾 Guardar cotización",
                            key="enviar_cotizacion",
                            type="primary",
                            use_container_width=True
                        ):
                            try:
                                id_cot = guardar_cotizacion(
                                    celular_cot,
                                    st.session_state.cesta_cotizacion,
                                    total_cot  # sin delivery — no es ganancia
                                )
                                st.session_state.cotizacion_enviada = True
                                st.session_state.ultimo_id_cotizacion = id_cot
                                st.session_state.url_wa_guardada = url_wa
                                st.rerun()
                            except Exception as e:
                                st.error(f"❌ Error al guardar: {e}")

                    if st.session_state.cotizacion_enviada:
                        id_mostrar = html.escape(str(st.session_state.get("ultimo_id_cotizacion", "")))
                        url_guardada = st.session_state.get("url_wa_guardada", url_wa)
                        st.markdown(
                            f"<div style='color:#38a169; font-weight:600; margin-bottom:0.5rem;'>"
                            f"✅ Cotización {id_mostrar} guardada</div>",
                            unsafe_allow_html=True
                        )
                        st.markdown(
                            f"""<a href="{url_guardada}" target="_blank" style="text-decoration:none;">
                            <div style="background:#25D366; color:white; padding:14px;
                            border-radius:10px; text-align:center; font-weight:700;
                            font-size:1rem;">
                                📲 Abrir WhatsApp y enviar
                            </div></a>""",
                            unsafe_allow_html=True
                        )
                else:
                    st.info("📱 Ingresa el celular para enviar")

            with col_limpiar:
                st.markdown("<br>", unsafe_allow_html=True)
                if not st.session_state.cotizacion_enviada:
                    if st.button("🗑️ Limpiar", key="limpiar_cotizacion", use_container_width=True):
                        st.session_state.cesta_cotizacion = []
                        st.session_state.cotizacion_enviada = False
                        st.session_state.url_wa_guardada = None
                        st.rerun()
                else:
                    if st.button("🆕 Nueva cotización", key="nueva_cotizacion", use_container_width=True):
                        st.session_state.cesta_cotizacion = []
                        st.session_state.cotizacion_enviada = False
                        st.session_state.url_wa_guardada = None
                        for k in ["cel_cotizacion", "marca_cot_sel", "perf_cot_sel", "ml_cot_sel", "delivery_cot"]:
                            st.session_state.pop(k, None)
                        st.rerun()

        else:
            st.caption("Agrega perfumes para armar la cotización")

    st.markdown("")

"""
tabs/tab_cotizacion.py — Sección de cotizaciones por WhatsApp.

Estado: state.get_state()["cotizacion"] — sin claves sueltas en session_state.
Items de la cesta con UUID para eliminación sin bugs de index-shift.
Widget keys fijos: cot_cel, cot_marca, cot_perf, cot_ml, cot_precio, cot_delivery.
"""
import html
import uuid
import re
import streamlit as st
from urllib.parse import quote

from config import fmt_precio, ML_OPCIONES, STOCK_CRITICO, STOCK_BAJO
from costos import costo_total_item
from data import guardar_cotizacion
from state import get_state, reset_cotizacion

COSTO_DELIVERY = 10.0

# Claves de widgets del formulario de cotización
_COT_WIDGET_KEYS = ("cot_cel", "cot_marca", "cot_perf", "cot_ml",
                    "cot_delivery", "cot_precio")


def _limpiar_celular(raw: str) -> str:
    """Extrae 9 dígitos del celular desde formatos como +51 987 654 321."""
    digits = re.sub(r'\D', '', raw)
    if digits.startswith('51') and len(digits) == 11:
        digits = digits[2:]
    return digits


def _limpiar_marca(marca: str) -> str:
    return marca.strip().strip('*').strip()


def _construir_item_cot(perfume_cot: str, marca_limpia: str, ml_cot: str,
                        precio_final: float, precio_catalogo: float) -> dict:
    """Crea un item de cotización con UUID para eliminación segura."""
    return {
        "id": str(uuid.uuid4()),
        "perfume": perfume_cot,
        "marca": marca_limpia,
        "ml": ml_cot,
        "precio": round(float(precio_final), 2),
        "precio_original": round(float(precio_catalogo), 2),
    }


def _card_precio_cot(precio_catalogo: float, stock_val) -> None:
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
        f"""<div style="background:{bg};border-left:4px solid {border};border-radius:10px;
        padding:0.8rem 1.2rem;display:flex;justify-content:space-between;align-items:center;
        margin-bottom:0.4rem;">
        <span style="color:{txt};font-weight:600;">{label}</span>
        <span style="color:{num};font-family:'Inter',sans-serif;font-size:1.6rem;
        font-weight:800;font-variant-numeric:tabular-nums;">
        S/ {fmt_precio(precio_catalogo)}</span>
        </div>""",
        unsafe_allow_html=True,
    )


def _generar_url_wa(celular: str, cesta: list, con_delivery: bool = False) -> str:
    total = sum(float(i["precio"]) for i in cesta)
    bloques = []
    for idx, i in enumerate(cesta, 1):
        precio_orig = i.get("precio_original")
        precio_final = float(i["precio"])
        nombre_completo = f"{i.get('marca', '')} {i.get('perfume', '')}".strip()

        if precio_orig is not None and round(float(precio_orig), 2) != round(precio_final, 2):
            precio_txt = f"~S/ {fmt_precio(precio_orig)}~ ➜ *S/ {fmt_precio(precio_final)}* 🏷️"
        else:
            precio_txt = f"💰 *S/ {fmt_precio(precio_final)}*"

        bloques.append(
            f"*{idx}.* 🌸 *{nombre_completo}*\n"
            f"     📏 {i.get('ml', '')}ml  ·  {precio_txt}"
        )

    sep = "────────────────────"
    delivery_line = ""
    total_final = total
    if con_delivery:
        total_final = total + COSTO_DELIVERY
        delivery_line = f"🛵 Delivery: +S/ {fmt_precio(COSTO_DELIVERY)}\n"

    mensaje = (
        f"✨ *Tu cotización — Perfuteca* ✨\n{sep}\n\n"
        f"{chr(10).join(bloques)}\n\n"
        f"{sep}\n{delivery_line}"
        f"💰 *Total: S/ {fmt_precio(total_final)}*\n{sep}\n\n"
        f"_¿Los separamos para ti? Escríbeme y los aparto_ 😊"
    )
    return f"https://wa.me/51{celular}?text={quote(mensaje)}"


def mostrar_seccion_cotizacion(df) -> None:
    """
    Sección de cotización por WhatsApp integrada en el tab de venta.
    Estado centralizado en state["cotizacion"].
    Items con UUID — eliminación por referencia, no por índice.
    """
    state = get_state()
    cot = state["cotizacion"]

    with st.expander("💰 Enviar Cotización por WhatsApp", expanded=True):

        # Celular
        celular_raw = st.text_input(
            "📱 Celular del cliente",
            placeholder="987654321 o +51 987 654 321",
            key="cot_cel",
        )
        celular_cot = _limpiar_celular(celular_raw)

        st.markdown("#### 🛒 Armar cotización")

        # Filtro por marca — usa Marca_limpia pre-computada en cargar_catalogo()
        _col_marca = "Marca_limpia" if "Marca_limpia" in df.columns else "Marca"
        marcas_opciones = sorted(df[_col_marca].dropna().unique().tolist())
        st.selectbox(
            "🏷️ Marca (opcional)", marcas_opciones,
            index=None, placeholder="— Todas las marcas —",
            key="cot_marca",
        )
        marca_cot = st.session_state.get("cot_marca")

        df_cot = df[df[_col_marca] == marca_cot] if marca_cot else df

        # Selector de perfume
        nombres_opciones = ["— Elige un perfume —"] + sorted(
            df_cot["Nombre"].dropna().unique().tolist()
        )
        st.selectbox("🌸 Perfume", nombres_opciones, key="cot_perf")
        perfume_cot = st.session_state.get("cot_perf", nombres_opciones[0])

        st.selectbox("📏 Tamaño", ML_OPCIONES, key="cot_ml")
        ml_cot = st.session_state.get("cot_ml", ML_OPCIONES[0])

        # Panel de precio y stock para el perfume seleccionado
        if perfume_cot and perfume_cot != nombres_opciones[0]:
            _matches = df[df["Nombre"] == perfume_cot]
            if not _matches.empty:
                perfume_row = _matches.iloc[0]
                columna_precio = f"Precio_{ml_cot}ml"
                precio_cat = perfume_row.get(columna_precio, 0)

                if precio_cat not in (0, "", None):
                    _card_precio_cot(precio_cat, perfume_row.get("Stock_ml"))

                    try:
                        cb = float(perfume_row.get("Costo_Botella") or 0)
                        mb = float(perfume_row.get("Ml_Botella") or 0)
                        costo_est = costo_total_item(ml_cot, cb, mb)
                        gan_est = float(precio_cat) - costo_est
                        st.markdown(
                            f"<div style='font-size:0.78rem;color:#6b7280;"
                            f"margin:0.3rem 0 0.5rem;'>"
                            f"💸 Costo estimado: <b>S/ {fmt_precio(costo_est)}</b>"
                            f"&nbsp;&nbsp;|&nbsp;&nbsp;"
                            f"💰 Ganancia: <b style='color:#16a34a'>"
                            f"S/ {fmt_precio(gan_est)}</b></div>",
                            unsafe_allow_html=True,
                        )
                    except Exception:
                        pass

                    # Purgar cot_precio si el usuario cambia perfume o ml sin agregar,
                    # para que value=precio_cat se aplique correctamente.
                    _cot_key = f"{perfume_cot}|{ml_cot}"
                    if cot.get("_last_precio_key") != _cot_key:
                        cot["_last_precio_key"] = _cot_key
                        st.session_state.pop("cot_precio", None)

                    st.number_input(
                        "💰 Precio final",
                        min_value=0.0,
                        value=float(precio_cat),
                        step=0.5,
                        format="%.2f",
                        key="cot_precio",
                    )
                    precio_final_cot = st.session_state.get("cot_precio", float(precio_cat))

                    if st.button("➕ Agregar a la cotización",
                                 key="cot_agregar", use_container_width=True):
                        marca_limpia = _limpiar_marca(str(perfume_row.get("Marca", "")))
                        item = _construir_item_cot(
                            perfume_cot, marca_limpia, ml_cot,
                            precio_final_cot, float(precio_cat),
                        )
                        cot["cesta"].append(item)
                        cot["guardada"] = False
                        st.toast(f"Agregado: {perfume_cot}", icon="✅")
                        # Resetear selector de perfume y precio para siguiente item
                        for k in ("cot_perf", "cot_precio"):
                            st.session_state.pop(k, None)
                        st.rerun()
                else:
                    st.warning("⚠️ Sin precio para ese tamaño")

        # ── Cesta de cotización ───────────────────────────────────────────────
        if cot["cesta"]:
            st.markdown("---")
            st.markdown("**📋 Cotización:**")

            for item in cot["cesta"]:
                c1, c2, c3 = st.columns([3, 1, 1])
                c1.write(f"🌸 {item['perfume']} ({item['ml']}ml)")
                c2.write(f"**S/ {fmt_precio(item['precio'])}**")
                # Eliminación por UUID — sin index-shift al borrar
                if c3.button("🗑️", key=f"cot_del_{item['id']}", use_container_width=True):
                    cot["cesta"] = [x for x in cot["cesta"] if x["id"] != item["id"]]
                    cot["guardada"] = False
                    st.rerun()

            total_cot = sum(float(i["precio"]) for i in cot["cesta"])

            st.checkbox(
                f"🛵 Con delivery (+S/ {fmt_precio(COSTO_DELIVERY)})",
                key="cot_delivery",
            )
            con_delivery = st.session_state.get("cot_delivery", False)

            if con_delivery:
                st.markdown(
                    f"<div style='font-size:0.9rem;color:#6b7280;'>"
                    f"Perfumes: <b>S/ {fmt_precio(total_cot)}</b>"
                    f" &nbsp;+&nbsp; Delivery: <b>S/ {fmt_precio(COSTO_DELIVERY)}</b>"
                    f"</div>",
                    unsafe_allow_html=True,
                )
                st.markdown(
                    f"**Total con delivery: S/ {fmt_precio(total_cot + COSTO_DELIVERY)}**"
                )
            else:
                st.markdown(f"**Total: S/ {fmt_precio(total_cot)}**")

            col_wa, col_limpiar = st.columns([2, 1])

            with col_wa:
                if len(celular_cot) == 9 and celular_cot.isdigit():
                    url_wa = _generar_url_wa(
                        celular_cot, cot["cesta"], con_delivery=con_delivery
                    )

                    if not cot["guardada"]:
                        if st.button("💾 Guardar cotización", key="cot_guardar",
                                     type="primary", use_container_width=True):
                            try:
                                id_cot = guardar_cotizacion(
                                    celular_cot, cot["cesta"], total_cot
                                )
                                cot["guardada"] = True
                                cot["id"]       = id_cot
                                cot["url_wa"]   = url_wa
                                cot["celular"]  = celular_cot
                                st.rerun()
                            except Exception as e:
                                st.error(f"❌ Error al guardar: {e}")

                    if cot["guardada"]:
                        id_mostrar = html.escape(str(cot.get("id", "")))
                        url_guardada = cot.get("url_wa", url_wa)
                        st.markdown(
                            f"<div style='color:#38a169;font-weight:600;"
                            f"margin-bottom:0.5rem;'>"
                            f"✅ Cotización {id_mostrar} guardada</div>",
                            unsafe_allow_html=True,
                        )
                        st.markdown(
                            f"""<a href="{url_guardada}" target="_blank"
                            style="text-decoration:none;">
                            <div style="background:#25D366;color:white;padding:14px;
                            border-radius:10px;text-align:center;font-weight:700;
                            font-size:1rem;">📲 Abrir WhatsApp y enviar</div></a>""",
                            unsafe_allow_html=True,
                        )
                else:
                    st.info("📱 Ingresa el celular para enviar")

            with col_limpiar:
                st.markdown("<br>", unsafe_allow_html=True)
                lbl = "🆕 Nueva cotización" if cot["guardada"] else "🗑️ Limpiar"
                if st.button(lbl, key="cot_limpiar", use_container_width=True):
                    reset_cotizacion()
                    st.rerun()

        else:
            st.caption("Agrega perfumes para armar la cotización")

    st.markdown("")
